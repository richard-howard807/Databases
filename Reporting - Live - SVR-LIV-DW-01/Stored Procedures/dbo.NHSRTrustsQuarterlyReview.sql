SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-09-02
-- Ticket:		#68460
-- Description:	New report for NHSR Trusts Quarterly Review
-- =============================================

CREATE PROCEDURE [dbo].[NHSRTrustsQuarterlyReview]
(
	@start_date AS DATE
		, @end_date AS DATE
		, @def_trust AS VARCHAR(MAX)
		, @nhs_specialty AS VARCHAR(MAX)
		, @instruction_type AS VARCHAR(MAX)
		, @referral_reason AS VARCHAR(MAX)
)
AS
BEGIN

-- For testing
--==============================================================================================================================================
--DECLARE @start_date AS DATE = '2020-02-01'
--		, @end_date AS DATE = GETDATE()
--		, @def_trust AS VARCHAR(MAX) = 'University Hospitals of North Midlands NHS Trust|Chelsea & Westminster Hospital NHS Foundation Trust'
--		, @nhs_specialty AS VARCHAR(MAX) = 'Orthopaedic Surgery|Casualty / A & E|Obstetrics|Psychiatry/ Mental Health|Other'
--		, @instruction_type AS VARCHAR(MAX) = 'Schedule 1|Clinical - Non DA|EL/PL Non DA|NCFF 25|Inquest - associated claim|EL/PL - PADs'
--		, @referral_reason AS VARCHAR(MAX) = 'Dispute on liability and quantum|Advice only'



--SELECT DISTINCT ISNULL(RTRIM(dim_detail_claim.defendant_trust), ' Missing') AS [def_trust]
--FROM red_dw.dbo.dim_detail_claim
--ORDER BY
--	def_trust

--SELECT DISTINCT ISNULL(RTRIM(dim_detail_health.nhs_speciality), ' Missing') AS [specialty]
--FROM red_dw.dbo.dim_detail_health
--ORDER BY
--	specialty

--SELECT DISTINCT ISNULL(CASE WHEN dim_detail_health.nhs_instruction_type = '' THEN ' Missing' ELSE RTRIM(dim_detail_health.nhs_instruction_type) END, ' Missing') AS [inst_type]
--FROM red_dw.dbo.dim_detail_health
--ORDER BY
--	inst_type

--SELECT DISTINCT ISNULL(CASE WHEN LOWER(dim_detail_core_details.referral_reason) = '' THEN ' missing' ELSE LOWER(dim_detail_core_details.referral_reason) END, ' missing') AS [ref_reason]
--FROM red_dw.dbo.dim_detail_core_details 
--ORDER BY 
--	ref_reason
--============================================================================================================================================================================================



-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#defendant_trust') IS NOT NULL   DROP TABLE #defendant_trust
IF OBJECT_ID('tempdb..#specialty') IS NOT NULL   DROP TABLE #specialty
IF OBJECT_ID('tempdb..#instruction_type') IS NOT NULL   DROP TABLE #instruction_type
IF OBJECT_ID('tempdb..#referral_reason') IS NOT NULL   DROP TABLE #referral_reason
IF OBJECT_ID('tempdb..#nhs_key_dates') IS NOT NULL DROP TABLE #nhs_key_dates
IF OBJECT_ID('tempdb..#witness_list_table') IS NOT NULL	 DROP TABLE #witness_list_table
               

SELECT udt_TallySplit.ListValue  INTO #defendant_trust FROM 	dbo.udt_TallySplit('|', @def_trust)
SELECT udt_TallySplit.ListValue  INTO #specialty FROM 	dbo.udt_TallySplit('|', @nhs_specialty)
SELECT udt_TallySplit.ListValue  INTO #instruction_type FROM 	dbo.udt_TallySplit('|', @instruction_type)
SELECT udt_TallySplit.ListValue  INTO #referral_reason FROM 	dbo.udt_TallySplit('|', @referral_reason)

--==============================================================================================================================================================
-- key dates table
--==============================================================================================================================================================
SELECT 
	keydates.client_code
	, keydates.matter_number
	, CAST(FORMAT(keydates.date_due, 'd', 'en-gb') AS VARCHAR(10))  + ' - ' + RTRIM(keydates.task_desccription) 		AS key_date_info
	, keydates.key_date_rag
INTO #nhs_key_dates
FROM (
		SELECT 
			dim_tasks.client_code
			, dim_tasks.matter_number
			, ROW_NUMBER() OVER (PARTITION BY dim_tasks.client_code, dim_tasks.matter_number ORDER BY dim_date.calendar_date) AS [xorder]
			, dim_tasks.task_code
			, dim_tasks.task_type_description
			, dim_tasks.task_desccription
			, CAST(dim_date.calendar_date AS DATE)			AS [date_due]
			, rag_status.rag				AS [key_date_rag]
		FROM red_dw.dbo.fact_tasks
			INNER JOIN red_dw.dbo.dim_tasks
				ON dim_tasks.dim_tasks_key = fact_tasks.dim_tasks_key
			INNER JOIN red_dw.dbo.dim_date
				ON fact_tasks.dim_task_due_date_key = dim_date.dim_date_key
			LEFT OUTER JOIN (
								SELECT 
									dim_tasks.client_code
									, dim_tasks.matter_number
									, dim_tasks.task_code
									, dim_tasks.task_type_description
									, dim_tasks.task_desccription
									, CAST(dim_date.calendar_date AS DATE)			AS [date_due]
									, CASE	
										WHEN ((LOWER(dim_tasks.task_desccription) LIKE '%mediation%' OR LOWER(dim_tasks.task_desccription) LIKE '%joint settlement%' OR LOWER(dim_tasks.task_desccription) LIKE '%pre-inquest%') 
											AND LOWER(dim_tasks.task_desccription) LIKE '%today%') AND DATEADD(MONTH, -3, dim_date.calendar_date) <= GETDATE() THEN
											'red'
										WHEN ((LOWER(dim_tasks.task_desccription) LIKE '%infant approval%' OR LOWER(dim_tasks.task_desccription) LIKE '%inquest date%' OR LOWER(dim_tasks.task_desccription) LIKE '%application hearing%') 
											AND LOWER(dim_tasks.task_desccription) LIKE '%today%') AND DATEADD(MONTH, -6, dim_date.calendar_date) <= GETDATE() THEN
											'red'
										WHEN (LOWER(dim_tasks.task_desccription) LIKE '%conference%' AND LOWER(dim_tasks.task_desccription) LIKE '%today%') AND DATEADD(MONTH, -3, dim_date.calendar_date) <= GETDATE() THEN
											'orange'
									  END	AS [rag]
								FROM red_dw.dbo.fact_tasks
									INNER JOIN red_dw.dbo.dim_tasks
										ON dim_tasks.dim_tasks_key = fact_tasks.dim_tasks_key
									INNER JOIN red_dw.dbo.dim_date
										ON fact_tasks.dim_task_due_date_key = dim_date.dim_date_key
								WHERE
									dim_tasks.client_code = 'N1001'
									AND RTRIM(dim_tasks.task_type_description) = 'Key Date'
									AND dim_date.calendar_date >= GETDATE()
									AND CASE	
													WHEN ((LOWER(dim_tasks.task_desccription) LIKE '%mediation%' OR LOWER(dim_tasks.task_desccription) LIKE '%joint settlement%' OR LOWER(dim_tasks.task_desccription) LIKE '%pre-inquest%') 
														AND LOWER(dim_tasks.task_desccription) LIKE '%today%') AND DATEADD(MONTH, -3, dim_date.calendar_date) <= GETDATE() THEN
														'red'
													WHEN ((LOWER(dim_tasks.task_desccription) LIKE '%infant approval%' OR LOWER(dim_tasks.task_desccription) LIKE '%inquest date%' OR LOWER(dim_tasks.task_desccription) LIKE '%application hearing%') 
														AND LOWER(dim_tasks.task_desccription) LIKE '%today%') AND DATEADD(MONTH, -6, dim_date.calendar_date) <= GETDATE() THEN
														'red'
													WHEN (LOWER(dim_tasks.task_desccription) LIKE '%conference%' AND LOWER(dim_tasks.task_desccription) LIKE '%today%') AND DATEADD(MONTH, -3, dim_date.calendar_date) <= GETDATE() THEN
														'orange'
												  END IS NOT NULL
							) AS rag_status
				ON rag_status.client_code = dim_tasks.client_code
					AND	rag_status.matter_number = dim_tasks.matter_number
		WHERE
			dim_tasks.client_code = 'N1001'
			AND RTRIM(dim_tasks.task_type_description) = 'Key Date'
			AND dim_date.calendar_date >= GETDATE()
			
	) AS keydates
WHERE
	keydates.xorder = 1

--==============================================================================================================================================================
-- Witness associates combined
--==============================================================================================================================================================
SELECT DISTINCT
	a.client_code
	, a.matter_number
	, SUBSTRING(c.witness_list, 1, LEN(c.witness_list)-1)		AS witness_list
INTO #witness_list_table	
FROM (
		SELECT 
			dim_involvement_full.client_code
			, dim_involvement_full.matter_number
			, LTRIM(RTRIM(dim_involvement_full.forename)) + ' ' + LTRIM(RTRIM(dim_involvement_full.name))		AS [witness_name]
		FROM red_dw.dbo.dim_involvement_full
		WHERE
			dim_involvement_full.client_code = 'N1001'
			AND dim_involvement_full.capacity_description = 'Witness'
			AND RTRIM(dim_involvement_full.forename) + ' ' + RTRIM(dim_involvement_full.name) IS NOT NULL
	) AS a
	CROSS APPLY
	(
		SELECT CONVERT(VARCHAR(255), LTRIM(RTRIM(b.forename)) + ' ' + LTRIM(RTRIM(b.name))) + ', '
		FROM red_dw.dbo.dim_involvement_full AS b
		WHERE
			b.client_code = 'N1001'
			AND b.capacity_description = 'Witness'
			AND RTRIM(b.forename) + ' ' + RTRIM(b.name) IS NOT NULL
			AND a.client_code = b.client_code
			AND a.matter_number = b.matter_number
		FOR XML PATH('')
	) c (witness_list)
--==============================================================================================================================================================
--==============================================================================================================================================================



SELECT 
	CASE	
		WHEN #nhs_key_dates.key_date_rag = 'red' THEN
			'Red'
		WHEN dim_detail_court.date_of_trial >= GETDATE() AND DATEADD(MONTH, -6, dim_detail_court.date_of_trial) <= GETDATE() THEN
			'Red'
		WHEN dim_detail_court.date_of_first_day_of_trial_window >= GETDATE() AND DATEADD(MONTH, -6, dim_detail_court.date_of_first_day_of_trial_window) <= GETDATE() THEN
			'Red'
		WHEN RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes' AND RTRIM(dim_detail_health.nhs_any_publicity) = 'Yes' THEN
			'Red'
		WHEN RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes' AND RTRIM(dim_detail_health.nhs_claim_novel_contentious_repercussive) = 'Yes' THEN
			'Red'
		WHEN RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes' AND RTRIM(dim_detail_health.nhs_liability) = 'No' THEN
			'Red'
		WHEN #nhs_key_dates.key_date_rag = 'orange' THEN 
			'Orange'
		WHEN ISNULL(RTRIM(dim_detail_core_details.proceedings_issued), 'No') = 'No' AND RTRIM(dim_detail_health.nhs_any_publicity) = 'Yes' THEN
			'Orange'
		WHEN ISNULL(RTRIM(dim_detail_core_details.proceedings_issued), 'No') = 'No' AND RTRIM(dim_detail_health.nhs_claim_novel_contentious_repercussive) = 'Yes' THEN
			'Orange'
		WHEN ISNULL(RTRIM(dim_detail_core_details.proceedings_issued), 'No') = 'No' AND RTRIM(dim_detail_health.nhs_liability) = 'No' THEN
			'Orange'
		ELSE
			'LimeGreen'
	END									AS [Risk Rating]
	, dim_detail_claim.defendant_trust			AS [Trust]
	, dim_client_involvement.insuredclient_reference		AS [Trust Ref]
	, dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number	AS [Panel Ref]
	, dim_matter_header_current.matter_owner_full_name		AS [Panel Case Handler]
	, dim_client_involvement.insurerclient_reference		AS [NHSR Ref]
	, dim_detail_core_details.clients_claims_handler_surname_forename		AS [NHSR Case Handler]
	, dim_detail_health.nhs_scheme		AS [Scheme]
	, dim_detail_health.nhs_instruction_type		AS [Instruction Type]
	, dim_claimant_thirdparty_involvement.claimant_name			AS [Claimant Name]
	, dim_detail_core_details.injury_type		AS [Injury Type]
	, CAST(dim_detail_core_details.incident_date AS DATE)		AS [Incident Date]
	, dim_detail_core_details.brief_details_of_claim			AS [Brief Details of Claim]
	, #witness_list_table.witness_list		AS [Witnesses]
	, dim_detail_health.nhs_speciality					AS [Specialty]
	, dim_detail_health.nhs_estimated_financial_year_of_settlement			AS [EYS]
	, dim_detail_health.nhs_probability				AS [Probability]
	, ''		AS [Any Investigation, Complaint, Safeguarding Involvement]
	, dim_detail_health.nhs_any_publicity			AS [Any Publicity]
	, dim_detail_health.nhs_claim_novel_contentious_repercussive		AS [Novel, Contentious or Reprecussive]
	, dim_detail_core_details.is_there_an_issue_on_liability		AS [Is There an Issue on Liability?]
	, dim_detail_health.nhs_liability				AS [Liability Position]
	, dim_detail_core_details.proceedings_issued		AS [Proceedings Issued?]
	, CAST(dim_detail_core_details.date_proceedings_issued AS DATE)		AS [Date Proceedings Issued]
	, CAST(dim_detail_core_details.date_instructions_received AS DATE)		AS [Date Instructions Received]
	, dim_detail_core_details.referral_reason			AS [Referral Reason]
	, dim_detail_core_details.present_position		AS [Present Position]
	, fact_finance_summary.damages_reserve		AS [Damages Reserve]
	, ''		AS [Offers]
	, COALESCE(dim_claimant_thirdparty_involvement.claimantsols_name, dim_claimant_thirdparty_involvement.claimantrep_name)		AS [Claimant Solicitors]
	, #nhs_key_dates.key_date_info			AS [Key Dates Approaching]
	, CAST(dim_detail_court.date_of_trial AS DATE)			AS [Date of Trial]
	, CAST(dim_detail_court.date_of_first_day_of_trial_window AS DATE)		AS [First Day of Trial Window]
	, CAST(dim_detail_court.date_end_of_trial_window AS DATE)			AS [End of Trial Window]
	, ''		AS [Status of Claim]
	, ''		AS [Strategy/Risks]
	, ''		AS [Safety and Learning]
	, ''		AS [Actions for the Trust to Address and Deadline]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)		AS [Date Claim Concluded]
	, dim_detail_outcome.outcome_of_case			AS [Outcome of Case]
	, dim_detail_health.nhs_damages_tranche			AS [Damages Tranch]
	, dim_detail_health.nhs_stage_of_settlement		AS [Stage of Settlement]
	, fact_finance_summary.damages_paid		AS [Damages Paid]
	, CAST(dim_detail_health.zurichnhs_date_final_bill_sent_to_client AS DATE)		AS [Date Final Bill Sent]
	, CAST(dim_matter_header_current.date_opened_practice_management AS date)		AS [Date Opened]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
	LEFT OUTER JOIN	red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_court
		ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN #nhs_key_dates
		ON #nhs_key_dates.client_code = dim_matter_header_current.client_code
			AND #nhs_key_dates.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN #witness_list_table
		ON #witness_list_table.client_code = dim_matter_header_current.client_code
			AND	#witness_list_table.matter_number = dim_matter_header_current.matter_number
	INNER JOIN #defendant_trust
		ON RTRIM(#defendant_trust.ListValue) COLLATE DATABASE_DEFAULT = ISNULL(RTRIM(dim_detail_claim.defendant_trust), ' Missing')
	INNER JOIN #specialty
		ON RTRIM(#specialty.ListValue) COLLATE DATABASE_DEFAULT = ISNULL(RTRIM(dim_detail_health.nhs_speciality), ' Missing')
	INNER JOIN #instruction_type
		ON RTRIM(#instruction_type.ListValue) COLLATE DATABASE_DEFAULT = ISNULL(CASE WHEN dim_detail_health.nhs_instruction_type = '' THEN ' Missing' ELSE RTRIM(dim_detail_health.nhs_instruction_type) END, ' Missing')
	INNER JOIN #referral_reason
		ON RTRIM(#referral_reason.ListValue) COLLATE DATABASE_DEFAULT = ISNULL(CASE WHEN LOWER(dim_detail_core_details.referral_reason) = '' THEN ' missing' ELSE LOWER(dim_detail_core_details.referral_reason) END, ' missing')
WHERE
	dim_matter_header_current.master_client_code = 'N1001'
	AND (
		(dim_matter_header_current.date_opened_practice_management BETWEEN @start_date AND @end_date)
		OR (dim_matter_header_current.date_opened_practice_management < @start_date 
				AND (dim_detail_health.zurichnhs_date_final_bill_sent_to_client BETWEEN @start_date AND @end_date))
		)
ORDER BY	
	dim_matter_header_current.date_opened_practice_management	

END
GO
