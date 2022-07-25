SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-03-31
-- Description:	Ticket #141487 Tracks PaperLite post on Catalina claims. This is for an internal report to check for outstanding doc tasks
-- =============================================

CREATE PROCEDURE [dbo].[catalina_post_tracker_internal]

AS
BEGIN

DROP TABLE IF EXISTS #catalina_matters
DROP TABLE IF EXISTS #catalina_docs
DROP TABLE IF EXISTS #doc_journey


--================================================================================================================
-- Find all Catalina matters
--================================================================================================================
SELECT DISTINCT
	dim_matter_header_current.ms_fileid
	, dim_matter_header_current.master_client_code + '.' + dim_matter_header_current.master_matter_number AS ms_ref
	, dim_matter_header_current.dim_matter_header_curr_key
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
							, dim_child_detail.is_this_a_catalina_claim_no
						FROM red_dw.dbo.dim_parent_detail
							INNER JOIN red_dw.dbo.dim_child_detail
								ON dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
						WHERE
							dim_child_detail.is_this_a_catalina_claim_no = 'Yes'
					) AS pre_lit_catalina
		ON pre_lit_catalina.client_code = dim_matter_header_current.client_code
			AND pre_lit_catalina.matter_number = dim_matter_header_current.matter_number
WHERE 1 = 1
	AND (
		dim_matter_header_current.master_client_code = 'W25984'
		OR	
		pre_lit_catalina.is_this_a_catalina_claim_no = 'Yes'
		OR
        dim_detail_client.is_there_a_catalina_claim_number_on_this_claim = 'Yes'
		)
	AND dim_matter_header_current.master_matter_number <> '0'


--================================================================================================================
-- Get documents and assigned document tasks on Catalina matters
--================================================================================================================
SELECT DISTINCT
	#catalina_matters.ms_fileid
	, dbDocument.docID
	, CAST(dbDocument.Created AS DATE)		AS doc_allocated_date	
	, CAST(dbTasks.tskCompleted	AS DATE)	AS doc_completion_date
	, dbTasks.tskActive
	, dbDocument.docDesc
	, dbTasks.tskDesc
	, dbTasks.tskType
	, dbDocument.docType		
	, dbDocument.docExtension
INTO #catalina_docs
FROM #catalina_matters
	INNER JOIN MS_Prod.config.dbDocument WITH(NOLOCK)
		ON dbDocument.fileID = #catalina_matters.ms_fileid
	INNER JOIN MS_Prod..dbTasks WITH(NOLOCK)
		ON dbDocument.docID = dbTasks.docID
WHERE 1 = 1
	AND CAST(dbDocument.Created AS DATE) >= '2022-03-14'
	AND dbDocument.docDeleted = 0
	AND dbDocument.docDirection = 1
	AND dbTasks.tskComplete = 0
	AND (dbTasks.tskType = 'PAPERLITE' OR dbTasks.tskType = 'EMAILRECEIPT')
	AND dbDocument.docID <> 41818290 --deleted document doesn't need to be shown on report
	


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
						WHERE
							ISNULL(RecentAuditLog.filter8, '') <> ''
							AND RecentAuditLog.event = 'Route to MatterSphere complete'
							AND CAST(RecentAuditLog.event_time AS DATE) >= '2022-03-14'
						) AS doc_id
				ON RecentAuditLog.job_id = doc_id.job_id

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
						WHERE
							ISNULL(ArchiveAuditLog.filter8, '') <> ''
							AND ArchiveAuditLog.event = 'Route to MatterSphere complete'
							AND CAST(ArchiveAuditLog.event_time AS DATE) >= '2022-03-14'
						)	AS doc_id
				ON ArchiveAuditLog.job_id = doc_id.job_id
	) AS all_data
WHERE
	all_data.rw_num = 1
ORDER BY
all_data.event_time 


--================================================================================================================
-- Main query to populate snapshot table
--================================================================================================================
SELECT 
	#catalina_matters.ms_ref				AS [Mattersphere Reference]
	, #catalina_docs.docID
	, dim_matter_header_current.matter_owner_full_name		AS [Matter Owner]
	, CAST(COALESCE(#doc_journey.event_time, #catalina_docs.doc_allocated_date) AS DATE)		AS [Document Received Date]
	, #catalina_docs.doc_allocated_date				AS [Document Allocated Date]
	, DATEDIFF(DAY, CAST(COALESCE(#doc_journey.event_time, #catalina_docs.doc_allocated_date) AS DATE), CAST(GETDATE() AS DATE)) 				AS [Days Post Outstanding]
	, #catalina_docs.tskActive
	, #catalina_docs.docDesc			AS [Document Description]
	, #catalina_docs.tskDesc			AS [Task Description]
	, #catalina_docs.docExtension	AS [Document Type]
	,dim_detail_claim.[lead_or_follow] AS [Lead/Follow] 
FROM #catalina_docs
	LEFT OUTER JOIN #doc_journey
		ON CAST(#catalina_docs.docID AS NVARCHAR) = #doc_journey.ms_doc_id
	INNER JOIN #catalina_matters
		ON #catalina_matters.ms_fileid = #catalina_docs.ms_fileid
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = #catalina_matters.dim_matter_header_curr_key
	LEFT JOIN red_dw.dbo.dim_detail_claim
	ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE 1 = 1
	
END
GO
