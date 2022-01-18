SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-01-17
-- Description:	Tracks PaperLite post on Catalina claims. Created a snapshot table due to nature of the report
-- =============================================

CREATE PROCEDURE [dbo].[catalina_post_tracker]

AS
BEGIN


DROP TABLE IF EXISTS #catalina_matters
DROP TABLE IF EXISTS #catalina_docs
DROP TABLE IF EXISTS #doc_journey
DROP TABLE IF EXISTS #report_week
	
--================================================================================================================
-- Sets the dates to run the import for 
--================================================================================================================
SELECT 
	CAST(week_dates.start_of_week AS DATE) AS start_of_week
	, week_dates.cal_week_in_year
	, week_dates.cal_year
	, ROW_NUMBER() OVER(ORDER BY week_dates.start_of_week)	AS week_number
INTO #report_week
FROM (	
		SELECT DISTINCT
			dim_date.cal_year
			, dim_date.cal_week_in_year
			, FIRST_VALUE(dim_date.calendar_date) OVER(PARTITION BY dim_date.cal_year, dim_date.cal_week_in_year ORDER BY dim_date.cal_year, dim_date.cal_week_in_year) AS start_of_week
		FROM red_dw.dbo.dim_date
		WHERE
			dim_date.calendar_date >= CAST(YEAR(GETDATE()) AS VARCHAR) + '-01-16'
			AND dim_date.calendar_date < CAST(YEAR(GETDATE()) + 1 AS VARCHAR) + '-01-15'
	) AS week_dates

DECLARE @report_week AS DATE = (
								SELECT DISTINCT
									#report_week.start_of_week
								FROM #report_week 
								WHERE
									#report_week.cal_week_in_year = (SELECT DISTINCT dim_date.cal_week_in_year FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = CAST(GETDATE() AS DATE))
								)
DECLARE @report_week_no AS INT = (
								SELECT DISTINCT
									#report_week.week_number
								FROM #report_week 
								WHERE
									#report_week.cal_week_in_year = (SELECT DISTINCT dim_date.cal_week_in_year FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = CAST(GETDATE() AS DATE))
								)
DECLARE @previous_report_week AS INT = (
										SELECT DISTINCT TOP 1
											dim_date.cal_week_in_year
										FROM red_dw.dbo.dim_date
										WHERE
											dim_date.calendar_date BETWEEN DATEADD(DAY, -7, @report_week) AND @report_week
										)

--SELECT @report_week, @report_week_no, @previous_report_week

--================================================================================================================
-- Find all Catalina matters
--================================================================================================================
SELECT DISTINCT
	dim_matter_header_current.ms_fileid
	, dim_matter_header_current.master_client_code + '.' + dim_matter_header_current.master_matter_number AS ms_ref
	, COALESCE(pre_lit_catalina.catalina_claim_ref, dim_client_involvement.insurerclient_reference) AS catalina_claim_ref
INTO #catalina_matters
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.client_code = dim_matter_header_current.client_code
			AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN (
						SELECT DISTINCT
							dim_child_detail.client_code
							, dim_child_detail.matter_number
							, catalina_claim_number
							, STRING_AGG(CAST(dim_parent_detail.zurich_rsa_claim_number AS NVARCHAR(MAX)), ', ')		AS catalina_claim_ref
						FROM red_dw.dbo.dim_parent_detail
							INNER JOIN red_dw.dbo.dim_child_detail
								ON dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
						WHERE
							dim_child_detail.catalina_claim_number = 'Yes'
						GROUP BY
							dim_child_detail.client_code
							, dim_child_detail.matter_number
							, catalina_claim_number
					) AS pre_lit_catalina
		ON pre_lit_catalina.client_code = dim_matter_header_current.client_code
			AND pre_lit_catalina.matter_number = dim_matter_header_current.matter_number
WHERE 1 = 1
	AND (
		dim_matter_header_current.master_client_code = 'W25984'
		OR	
		pre_lit_catalina.catalina_claim_number = 'Yes'
		OR
        dim_detail_client.is_there_a_catalina_claim_number_on_this_claim = 'Yes'
		)
	AND dim_matter_header_current.master_matter_number <> '0'


--================================================================================================================
-- Get get documents and assigned document tasks on Catalina matters
--================================================================================================================
SELECT
	doc_tasks.ms_fileid
	, doc_tasks.docID
	, doc_tasks.doc_allocated_date
	, doc_tasks.tskActive
	, doc_tasks.docDesc
	, doc_tasks.tskDesc
	, IIF(MAX(ISNULL(doc_tasks.doc_completion_date, '9999-12-31')) = '9999-12-31', NULL, MAX(ISNULL(doc_tasks.doc_completion_date, '9999-12-31')))		AS doc_completion_date
INTO #catalina_docs
FROM (
		SELECT DISTINCT
			#catalina_matters.ms_fileid
			, dbDocument.docID
			, CAST(dbDocument.Created AS DATE)		AS doc_allocated_date	
			, CAST(dbTasks.tskCompleted	AS DATE)	AS doc_completion_date
			, dbTasks.tskActive
			, dbDocument.docDesc
			, dbTasks.tskDesc
		FROM #catalina_matters
			INNER JOIN MS_Prod.config.dbDocument WITH(NOLOCK)
				ON dbDocument.fileID = #catalina_matters.ms_fileid
			INNER JOIN MS_Prod..dbTasks WITH(NOLOCK)
				ON dbDocument.docID = dbTasks.docID
		WHERE 1 = 1
			AND CAST(dbDocument.Created AS DATE) >= '2022-01-10'
			AND dbDocument.docDeleted = 0
			AND dbDocument.docDirection = 1
			AND dbDocument.docType <> 'EMAIL'
			--AND dbTasks.tskActive = 1
			--AND dbDocument.docID = 37788742
	) AS doc_tasks
GROUP BY
	doc_tasks.ms_fileid
	, doc_tasks.docID
	, doc_tasks.doc_allocated_date
	, doc_tasks.tskActive
	, doc_tasks.docDesc
	, doc_tasks.tskDesc

--================================================================================================================
-- Get document receipt date from PaperRiver
--================================================================================================================
SELECT  *
INTO #doc_journey
FROM (
SELECT DISTINCT
	RecentAuditLog.event_time
	, RecentAuditLog.job_id
	, RecentAuditLog.event
	, doc_id.filter8			AS ms_doc_id
	, ROW_NUMBER() OVER(PARTITION BY RecentAuditLog.job_id ORDER BY RecentAuditLog.event_time) AS rw_num
--SELECT DISTINCT RecentAuditLog.event
FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog]
	INNER JOIN (
				SELECT 
					RecentAuditLog.job_id
					, RecentAuditLog.filter8
				--SELECT *
				FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog]
					--INNER JOIN #catalina_docs
					--	ON RecentAuditLog.filter8 = CAST(#catalina_docs.docID AS NVARCHAR) 
				WHERE
					ISNULL(RecentAuditLog.filter8, '') <> ''
					AND RecentAuditLog.event = 'Route to MatterSphere complete'
					AND CAST(RecentAuditLog.event_time AS DATE) >= '2022-01-10'
					--AND RecentAuditLog.job_id = '203570'
					--AND filter8 = '37864891'
				) AS doc_id
		ON RecentAuditLog.job_id = doc_id.job_id
WHERE 1 = 1
	--AND CAST(RecentAuditLog.event_time AS DATE) >= '2022-01-10'
	--AND RecentAuditLog.job_id = '203570'
--AND doc_id.filter8 = '37867009'

UNION

SELECT DISTINCT
	ArchiveAuditLog.event_time
	, ArchiveAuditLog.job_id
	, ArchiveAuditLog.event
	, doc_id.filter8		AS ms_doc_id
	, ROW_NUMBER() OVER(PARTITION BY ArchiveAuditLog.job_id ORDER BY ArchiveAuditLog.event_time)		AS rw_num
FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[ArchiveAuditLog]
	INNER JOIN (
				SELECT DISTINCT
					ArchiveAuditLog.job_id
					, ArchiveAuditLog.filter8
				FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[ArchiveAuditLog]
					--INNER JOIN #catalina_docs
					--	ON ArchiveAuditLog.filter8 = CAST(#catalina_docs.docID AS NVARCHAR)
				WHERE
					ISNULL(ArchiveAuditLog.filter8, '') <> ''
					AND ArchiveAuditLog.event = 'Route to MatterSphere complete'
					AND CAST(ArchiveAuditLog.event_time AS DATE) >= '2022-01-10'
				)	AS doc_id
		ON ArchiveAuditLog.job_id = doc_id.job_id
WHERE 1 = 1
	--AND CAST(ArchiveAuditLog.event_time AS DATE) >= '2022-01-10'
) AS all_data
WHERE
	all_data.rw_num = 1
	AND CAST(all_data.event_time AS DATE) >= '2022-01-10'
ORDER BY
all_data.event_time 



--================================================================================================================
-- Main query to populate snapshot table
--================================================================================================================
INSERT INTO dbo.catalina_post_snapshot
(
    ms_ref,
    catalina_claim_ref,
    docID,
    doc_received_date,
    doc_allocated_date,
    doc_completion_date,
    outstanding_count,
    response_time,
    prior_weeks_response_time,
    days_post_outstanding,
    tskActive,
    docDesc,
    tskDesc,
    report_week,
    report_week_no,
    report_tab,
    post_split_by_age,
    outstanding_post
)
SELECT 
	*
	, CASE
		WHEN all_data.days_post_outstanding IS NULL THEN	
			NULL	
		WHEN all_data.days_post_outstanding < 30 THEN 
			'tab 1.1'
		ELSE
			'tab 1.2'
	  END					AS report_tab
	, CASE
		WHEN all_data.outstanding_count = 1 THEN
			CASE
				WHEN all_data.response_time <= 30 THEN
					'<=30'
				WHEN all_data.response_time <= 60 THEN
					'31 to 60'
				WHEN all_data.response_time <= 90 THEN
					'61 to 90'
				ELSE
					'>90'
			END
		ELSE
			NULL
	  END						AS post_split_by_age
	, CASE
		WHEN all_data.days_post_outstanding IS NULL THEN
			NULL
		WHEN all_data.days_post_outstanding <= 15 THEN
			'<=15'
		WHEN all_data.days_post_outstanding < 30 THEN
			'>15'
		WHEN all_data.days_post_outstanding <= 40 THEN	
			'30 to 40'
		WHEN all_data.days_post_outstanding <= 60 THEN
			'41 to 60'
		ELSE
			'>60'
	  END						AS outstanding_post
FROM (	
		SELECT 
			#catalina_matters.ms_ref
			, #catalina_matters.catalina_claim_ref
			, #catalina_docs.docID
			, CAST(#doc_journey.event_time AS DATE)		AS doc_received_date
			, #catalina_docs.doc_allocated_date		
			, #catalina_docs.doc_completion_date
			, IIF(#catalina_docs.doc_completion_date IS NULL, 1, 0)		AS outstanding_count
			, dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(#doc_journey.event_time AS DATE), ISNULL(#catalina_docs.doc_completion_date, CAST(GETDATE() AS DATE)))		AS response_time
			, CASE	
				WHEN dim_date.cal_week_in_year = @previous_report_week THEN
					dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(#doc_journey.event_time AS DATE), ISNULL(#catalina_docs.doc_completion_date, CAST(GETDATE() AS DATE)))
				ELSE
					NULL
			  END				AS prior_weeks_response_time
			, CASE
				WHEN #catalina_docs.doc_completion_date IS NULL THEN
					--calendar days
					DATEDIFF(DAY, CAST(#doc_journey.event_time AS DATE), CAST(GETDATE() AS DATE)) 
				ELSE
					NULL
			  END								AS days_post_outstanding
			, #catalina_docs.tskActive
			, #catalina_docs.docDesc
			, #catalina_docs.tskDesc
			, @report_week			AS report_week
			, @report_week_no		AS report_week_no
		FROM #doc_journey
			INNER JOIN #catalina_docs
				ON #doc_journey.ms_doc_id = CAST(#catalina_docs.docID AS NVARCHAR)
			INNER JOIN #catalina_matters
				ON #catalina_matters.ms_fileid = #catalina_docs.ms_fileid
			LEFT OUTER JOIN red_dw.dbo.dim_date
				ON dim_date.calendar_date = #catalina_docs.doc_completion_date
		WHERE 1 = 1
			--AND #catalina_docs.doc_completion_date < @report_week
			--AND #catalina_docs.doc_allocated_date < '2021-12-01'
			AND CAST(#doc_journey.event_time AS DATE) < @report_week
	) AS all_data
WHERE
	all_data.outstanding_count = 1
	OR 
	all_data.prior_weeks_response_time IS NOT NULL

END



--SELECT *
--FROM dbo.catalina_post_snapshot

GO
