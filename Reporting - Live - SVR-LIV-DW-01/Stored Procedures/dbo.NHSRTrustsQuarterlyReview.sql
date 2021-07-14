SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-09-02
-- Ticket:		#68460
-- Description:	New report for NHSR Trusts Quarterly Review
-- Update: MT as per 92701 added [Risk Management Recommendations] 
-- =============================================
CREATE PROCEDURE [dbo].[NHSRTrustsQuarterlyReview]
(
		@def_trust AS VARCHAR(MAX)
		, @nhs_specialty AS VARCHAR(MAX)
		, @instruction_type AS VARCHAR(MAX)
		, @referral_reason AS VARCHAR(MAX)	
)
AS

BEGIN

-- For testing
--==============================================================================================================================================
--DECLARE @def_trust AS VARCHAR(MAX) = 'Missing|Derbyshire Healthcare NHS Foundation Trust|University Hospitals of North Midlands NHS Trust' 
--		, @nhs_specialty AS VARCHAR(MAX) = 'Ambulance|Anaesthesia|Antenatal Clinic|Audiological Medicine|Cardiology|Casualty / A & E|Chemical Pathology|Community Medicine/ Public Health|Community Midwifery|Dentistry|Dermatology|District Nursing|Gastroenterology|General Medicine|General Surgery|Genito-Urinary Medicine|Geriatric Medicine|Gynaecology|Haematology|Histopathology|Infectious Diseases|Intensive Care Medicine|Microbiology/ Virology|Missing|NHS Direct Services|Neurology|Neurosurgery|Non-Clinical Staff|Non-obstetric claim|Not Specified|Obstetrics|Obstetrics / Gynaecology|Oncology|Opthalmology|Oral & Maxillo Facial Surgery|Orthopaedic Surgery|Other|Otorhinolaryngology/ ENT|Paediatrics|Palliative Medicine|Pharmacy|Physiotherapy|Plastic Surgery|Podiatry|Psychiatry/ Mental Health|Radiology|Rehabilitation|Renal Medicine|Respiratory Medicine/ Thoracic Medic|Rheumatology|Surgical Speciality - Other|Unknown|Urology|Vascular Surgery' 
--		, @instruction_type AS VARCHAR(MAX) = 'Clinical - Non DA|EL/PL DA|Expert Report - Limited|Schedule 1'
--		, @referral_reason AS VARCHAR(MAX) = 'advice only|costs dispute|criminal representation|dispute on liability|dispute on liability and quantum|dispute on quantum|hse prosecution|infant approval|inquest|intel only|missing|nomination only|pre-action disclosure|recovery'

--==========================================================================================================================================================================================
-- Parameter queries
--==========================================================================================================================================================================================
--SELECT DISTINCT RTRIM(dim_detail_claim.defendant_trust), ISNULL(RTRIM(dim_detail_claim.defendant_trust), 'Missing') AS [def_trust]
--FROM red_dw.dbo.dim_detail_claim
--ORDER BY
--	def_trust

--SELECT DISTINCT ISNULL(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(dim_detail_health.nhs_speciality, CHAR(10), CHAR(32)),CHAR(13), CHAR(32)),CHAR(160), CHAR(32)),CHAR(9),CHAR(32)))), 'Missing')  AS [specialty]
--FROM red_dw.dbo.dim_detail_health
--ORDER BY
--	specialty

--SELECT DISTINCT ISNULL(CASE WHEN dim_detail_health.nhs_instruction_type = '' THEN 'Missing' ELSE RTRIM(dim_detail_health.nhs_instruction_type) END, 'Missing') AS [inst_type]
--FROM red_dw.dbo.dim_detail_health
--ORDER BY
--	inst_type

--SELECT DISTINCT ISNULL(CASE WHEN LOWER(dim_detail_core_details.referral_reason) = '' THEN 'missing' ELSE LOWER(RTRIM(dim_detail_core_details.referral_reason)) END, 'missing') AS [ref_reason]
--FROM red_dw.dbo.dim_detail_core_details 
--ORDER BY 
--	ref_reason
--============================================================================================================================================================================================

DECLARE @nDate AS DATETIME = (SELECT MIN(dim_date.calendar_date) FROM red_dw..dim_date WHERE dim_date.fin_year = (SELECT fin_year - 3 FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = CAST(GETDATE() AS DATE)))
DECLARE @last_year AS DATE = DATEADD(MONTH, -11, GETDATE()+1)-DAY(GETDATE())

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#defendant_trust') IS NOT NULL   DROP TABLE #defendant_trust
IF OBJECT_ID('tempdb..#specialty') IS NOT NULL   DROP TABLE #specialty
IF OBJECT_ID('tempdb..#instruction_type') IS NOT NULL   DROP TABLE #instruction_type
IF OBJECT_ID('tempdb..#referral_reason') IS NOT NULL   DROP TABLE #referral_reason
IF OBJECT_ID('tempdb..#rag_status') IS NOT NULL DROP TABLE #rag_status
IF OBJECT_ID('tempdb..#witness_list_table') IS NOT NULL	 DROP TABLE #witness_list_table
IF OBJECT_ID('tempdb..#key_date_list_table') IS NOT NULL	 DROP TABLE #key_date_list_table
               

SELECT udt_TallySplit.ListValue  INTO #defendant_trust FROM 	dbo.udt_TallySplit('|', @def_trust)
SELECT udt_TallySplit.ListValue  INTO #specialty FROM 	dbo.udt_TallySplit('|', @nhs_specialty)
SELECT udt_TallySplit.ListValue  INTO #instruction_type FROM 	dbo.udt_TallySplit('|', @instruction_type)
SELECT udt_TallySplit.ListValue  INTO #referral_reason FROM 	dbo.udt_TallySplit('|', @referral_reason)


--==============================================================================================================================================================
-- RAG table
--==============================================================================================================================================================

SELECT 
	dim_matter_header_current.client_code
	, dim_matter_header_current.matter_number
	, --(CASE WHEN key_date_rag.rag = 'orange' THEN 'amber' ELSE key_date_rag.rag END) + ' - ' + 
		CAST(FORMAT(key_date_rag.date_due, 'd', 'en-gb') AS VARCHAR(10)) + ' -' + key_date_rag.task_desccription		AS [key_date_rag_trigger]
	, CASE	
		WHEN dim_detail_court.date_of_trial >= GETDATE() AND DATEADD(MONTH, -6, dim_detail_court.date_of_trial) <= GETDATE() OR 
			trial_key_date.trial_date >= GETDATE() AND DATEADD(MONTH, -6, trial_key_date.trial_date) <= GETDATE() THEN
			'' + CAST(FORMAT(COALESCE(trial_key_date.trial_date, dim_detail_court.date_of_trial), 'd', 'en-gb') AS VARCHAR(10)) + ' - trial date in 6 months'
	  END				AS [trial_date_rag_trigger]
	, CASE
		WHEN dim_detail_court.date_of_first_day_of_trial_window >= GETDATE() AND DATEADD(MONTH, -6, dim_detail_court.date_of_first_day_of_trial_window) <= GETDATE() THEN
			'' + CAST(FORMAT(dim_detail_court.date_of_first_day_of_trial_window, 'd', 'en-gb') AS VARCHAR(10)) + ' -  trial window in 6 months'
	  END				AS [trial_window_rag_trigger]
	, CASE
		WHEN RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes' AND RTRIM(dim_detail_health.nhs_any_publicity) = 'Yes' THEN
			' proceedings yes/publicity yes'
	  END				AS [proceedings_publicity_rag_trigger]
	, CASE
		WHEN RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes' AND RTRIM(dim_detail_health.nhs_claim_novel_contentious_repercussive) = 'Yes' THEN
			' proceedings yes/repercussive yes'
	  END				AS [proceedings_repercussive_rag_trigger]
	, CASE
		WHEN RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes' AND RTRIM(dim_detail_health.nhs_liability) = 'No' THEN
			' proceedings yes/liability no'
	  END				AS [proceedings_liability_rag_trigger]
	, CASE
		WHEN ISNULL(RTRIM(dim_detail_core_details.proceedings_issued), 'No') = 'No' AND RTRIM(dim_detail_health.nhs_any_publicity) = 'Yes' THEN
			' proceedinds no/publicity yes'
	  END				AS [no_proceedings_publicity_rag_trigger]
	, CASE
		WHEN ISNULL(RTRIM(dim_detail_core_details.proceedings_issued), 'No') = 'No' AND RTRIM(dim_detail_health.nhs_claim_novel_contentious_repercussive) = 'Yes' THEN
			' proceedings no/repercussive yes'
	  END				AS [no_proceedings_repercussive_rag_trigger]
	, CASE
		WHEN ISNULL(RTRIM(dim_detail_core_details.proceedings_issued), 'No') = 'No' AND RTRIM(dim_detail_health.nhs_liability) = 'No' THEN
			' proceedings no/liability no'
	  END				AS [no_proceedings_liability_rag_trigger]
	, CASE	
		WHEN key_date_rag.rag = 'red' THEN
			'Red'
		WHEN dim_detail_court.date_of_trial >= GETDATE() AND DATEADD(MONTH, -6, dim_detail_court.date_of_trial) <= GETDATE() OR 
			trial_key_date.trial_date >= GETDATE() AND DATEADD(MONTH, -6, trial_key_date.trial_date) <= GETDATE() THEN
			'Red'
		WHEN dim_detail_court.date_of_first_day_of_trial_window >= GETDATE() AND DATEADD(MONTH, -6, dim_detail_court.date_of_first_day_of_trial_window) <= GETDATE() THEN
			'Red'
		WHEN RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes' AND RTRIM(dim_detail_health.nhs_any_publicity) = 'Yes' THEN
			'Red'
		WHEN RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes' AND RTRIM(dim_detail_health.nhs_claim_novel_contentious_repercussive) = 'Yes' THEN
			'Red'
		WHEN RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes' AND RTRIM(dim_detail_health.nhs_liability) = 'No' THEN
			'Red'
		WHEN key_date_rag.rag = 'orange' THEN 
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
INTO #rag_status
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN	red_dw.dbo.dim_detail_health
		ON dim_detail_health.client_code = dim_matter_header_current.client_code
			AND dim_detail_health.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_court
		ON dim_detail_court.client_code = dim_matter_header_current.client_code
			AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
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
							, ROW_NUMBER() OVER(PARTITION BY dim_tasks.client_code, dim_tasks.matter_number ORDER BY dim_date.calendar_date) AS [xorder]
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
			) AS key_date_rag
		ON key_date_rag.client_code = dim_matter_header_current.client_code
			AND key_date_rag.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN (
					SELECT 
						dim_matter_header_current.dim_matter_header_curr_key
						, CAST(dim_key_dates.key_date AS DATE)	AS trial_date
					FROM red_dw.dbo.dim_key_dates
						INNER JOIN red_dw.dbo.dim_matter_header_current
							ON  dim_matter_header_current.dim_matter_header_curr_key = dim_key_dates.dim_matter_header_curr_key
					WHERE
						dim_matter_header_current.master_client_code = 'N1001'
						AND dim_key_dates.type = 'TRIAL'
						AND CAST(dim_key_dates.key_date AS DATE) >= CAST(GETDATE() AS DATE)
						AND CAST(dim_key_dates.key_date AS DATE) <= CAST(DATEADD(MONTH, 6, GETDATE()) AS DATE)
						AND dim_key_dates.is_active = 1
					) AS trial_key_date
		ON trial_key_date.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.master_client_code = 'N1001'
	AND dim_matter_header_current.ms_only = 1
	AND (dim_matter_header_current.date_closed_practice_management IS NULL OR dim_matter_header_current.date_closed_practice_management > @nDate)
	AND (key_date_rag.xorder IS NULL OR key_date_rag.xorder = 1)
	--AND dim_detail_core_details.present_position = 'Claim and costs outstanding'


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
-- key date list 
--==============================================================================================================================================================
SELECT DISTINCT
	a.client_code
	, a.matter_number
	, SUBSTRING(c.key_date_list, 1, LEN(c.key_date_list)-1)		AS key_date_list
INTO #key_date_list_table	
FROM (
		SELECT 
			dim_tasks.client_code
			, dim_tasks.matter_number
			, CAST(FORMAT(dim_date.calendar_date, 'd', 'en-gb') AS VARCHAR(10))  + ' - ' + RTRIM(dim_tasks.task_desccription) AS [key_date_type]
		FROM red_dw.dbo.fact_tasks
			INNER JOIN red_dw.dbo.dim_tasks
				ON dim_tasks.dim_tasks_key = fact_tasks.dim_tasks_key
			INNER JOIN red_dw.dbo.dim_date
				ON fact_tasks.dim_task_due_date_key = dim_date.dim_date_key
		WHERE
			dim_tasks.client_code = 'N1001'
			AND RTRIM(dim_tasks.task_type_description) = 'Key Date'
			AND dim_date.calendar_date >= GETDATE()
			AND LOWER(dim_tasks.task_desccription) LIKE '%today%'
			AND LOWER(dim_tasks.task_desccription) NOT LIKE '%cru expiry%'
			AND LOWER(dim_tasks.task_desccription) NOT LIKE '%nhsla solicitor''s report due - today%'
			AND LOWER(dim_tasks.task_desccription) NOT LIKE '%report to client due - today%'
	) AS a
	CROSS APPLY
	(
		--SELECT CONVERT(VARCHAR(255), LTRIM(RTRIM(b.forename)) + ' ' + LTRIM(RTRIM(b.name))) + ', '
		SELECT 
			CAST(FORMAT(dim_date.calendar_date, 'd', 'en-gb') AS VARCHAR(10))  + ' - ' + RTRIM(dim_tasks.task_desccription) + ', '
		FROM red_dw.dbo.fact_tasks AS b
			INNER JOIN red_dw.dbo.dim_tasks
				ON dim_tasks.dim_tasks_key = b.dim_tasks_key
			INNER JOIN red_dw.dbo.dim_date
				ON b.dim_task_due_date_key = dim_date.dim_date_key
		WHERE
			dim_tasks.client_code = 'N1001'
			AND RTRIM(dim_tasks.task_type_description) = 'Key Date'
			AND dim_date.calendar_date >= GETDATE()
			AND a.client_code = b.client_code
			AND a.matter_number = b.matter_number
			AND LOWER(dim_tasks.task_desccription) LIKE '%today%'
			AND LOWER(dim_tasks.task_desccription) NOT LIKE '%cru expiry%'
			AND LOWER(dim_tasks.task_desccription) NOT LIKE '%nhsla solicitor''s report due - today%'
			AND LOWER(dim_tasks.task_desccription) NOT LIKE '%report to client due - today%'
		ORDER BY
			dim_date.calendar_date
		FOR XML PATH('')
	) c (key_date_list)

--==============================================================================================================================================================
--==============================================================================================================================================================



SELECT 
	CASE
		WHEN #rag_status.[Risk Rating] = 'Red' THEN
			'1 - red'
		WHEN #rag_status.[Risk Rating] = 'Orange' THEN
			'2 - amber'
		ELSE
			'3 - green'
	END				AS [risk_rating_order]
	, #rag_status.[Risk Rating]							AS [Risk Rating]
	, #rag_status.trial_date_rag_trigger		AS [rag_trigger_1]
	, #rag_status.trial_window_rag_trigger		AS [rag_trigger_2]
	, #rag_status.proceedings_publicity_rag_trigger	AS [rag_trigger_3]
	, #rag_status.proceedings_repercussive_rag_trigger	AS [rag_trigger_4]
	, #rag_status.proceedings_liability_rag_trigger		AS [rag_trigger_5]
	, RTRIM(#rag_status.key_date_rag_trigger)			AS [rag_trigger_6]
	, #rag_status.no_proceedings_publicity_rag_trigger	AS [rag_trigger_7]
	, #rag_status.no_proceedings_repercussive_rag_trigger	AS [rag_trigger_8]
	, #rag_status.no_proceedings_liability_rag_trigger		AS [rag_trigger_9]
	, dim_detail_claim.defendant_trust			AS [Trust]
	, dim_client_involvement.insuredclient_reference		AS [Trust Ref]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number	AS [Panel Ref]
	, dim_matter_header_current.matter_owner_full_name		AS [Panel Case Handler]
	--, dim_client_involvement.insurerclient_reference		AS [NHSR Ref]
	--, dim_detail_core_details.clients_claims_handler_surname_forename		AS [NHSR Case Handler]
	--, dim_detail_health.nhs_scheme		AS [Scheme]
	, dim_detail_health.nhs_instruction_type		AS [Instruction Type]
	,CASE 
		WHEN nhs_instruction_type IN 
		('CFF 50 (Non-PA)','CFF 50 (PA)','Clinical - Delegated, FF','Clinical - Non DA - FF'
		,'EL/PL - old delegated matters','EL/PL DA','NCFF 25') THEN 
			'Delegated authority'
		WHEN nhs_instruction_type IN 
		('Breast screenings - group action','C&W Group Action','C-Difficile','CFF 100 (Non-PA)','CFF 100 (PA)'
		,'CFF 250 (Non-PA)','CFF 250 (PA)','Clinical - Non DA','Clinical - Non DA (ENS)','Derbyshire Healthcare Group Action'
		,'DPA/Defamation etc','East Lancs Group Action','East Sussex Group Action','EL/PL Non DA','ELS - Non DA','HIV Recall Group'
		,'Manchester bombings','Mediation - capped fee','Mid Staffs Group Action','MTW Group Action','OSINT - Sch 2 - HR'
		,'RG - UHNM Group Action','SME Group Action','SV - Group action','TB Group Midlands Partnership','UHNS Group Action'
		,'Worcester Group Action','WWL - Data Breach group action') THEN 
			'Direct instruction'
		WHEN nhs_instruction_type IN ('Inquest - C','Inquest - NC','Inquests') THEN 
			'Inquest'
		WHEN nhs_instruction_type IN ('EL/PL - PADs','Expert Report - Limited','Expert Report + LoR - Limited','Full Investigation - Limited'
		,'GPI - Advice','Inquest - associated claim','ISS 250','ISS 250 Advisory','ISS Plus','ISS Plus Advisory'
		,'Letter of Response - Limited','Lot 3 work','OSINT - Sch 1 FF','OSINT - Sch 2 - FF','OSINT & Claims Validation'
		,'OSINT & Fraud (returned to NHS Protocol)','OSINT (advice)','Schedule 1','Schedule 2','Schedule 3'
		,'Schedule 4','Schedule 4 (ENS)','Schedule 5 (ENS)') THEN 
			'Limited instructions'
		WHEN nhs_instruction_type IN ('Other') THEN 
			'Other'
	  END			AS NewInstructionType
	, dim_claimant_thirdparty_involvement.claimant_name			AS [Claimant Name]
	, dim_detail_core_details.injury_type		AS [Injury Type]
	, CAST(dim_detail_core_details.incident_date AS DATE)		AS [Incident Date]
	, dim_detail_core_details.brief_details_of_claim			AS [Brief Details of Claim]
	, #witness_list_table.witness_list		AS [Witnesses]
	--, dim_detail_health.nhs_speciality					AS [Speciality]
	, CASE
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') THEN
			dim_matter_worktype.work_type_name
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') THEN 
			dim_detail_health.nhs_speciality	
	  END		AS [Speciality]
	--, dim_detail_health.nhs_estimated_financial_year_of_settlement			AS [EYS]
	, dim_detail_health.nhs_probability				AS [Probability]
	--, ''		AS [Any Investigation, Complaint, Safeguarding Involvement]
	, dim_detail_health.nhs_any_publicity			AS [Any Publicity]
	, dim_detail_health.nhs_claim_novel_contentious_repercussive		AS [Novel, Contentious or Repercussive]
	, dim_detail_core_details.is_there_an_issue_on_liability		AS [Is There an Issue on Liability?]
	--, dim_detail_health.nhs_liability				AS [Liability Position]
	--, dim_detail_core_details.proceedings_issued		AS [Proceedings Issued?]
	--, CAST(dim_detail_core_details.date_proceedings_issued AS DATE)		AS [Date Proceedings Issued]
	--, CAST(dim_detail_core_details.date_instructions_received AS DATE)		AS [Date Instructions Received]
	--, dim_detail_core_details.referral_reason			AS [Referral Reason]
	, dim_detail_core_details.present_position		AS [Present Position]
	, fact_finance_summary.damages_reserve		AS [Damages Reserve]
	, fact_finance_summary.total_reserve		AS [Total Reserve]
	--, ''		AS [Offers]
	--, COALESCE(dim_claimant_thirdparty_involvement.claimantsols_name, dim_claimant_thirdparty_involvement.claimantrep_name)		AS [Claimant Solicitors]
	, #key_date_list_table.key_date_list			AS [Key Dates Approaching]
	--, CAST(dim_detail_court.date_of_trial AS DATE)			AS [Date of Trial]
	--, CAST(dim_detail_court.date_of_first_day_of_trial_window AS DATE)		AS [First Day of Trial Window]
	--, CAST(dim_detail_court.date_end_of_trial_window AS DATE)			AS [End of Trial Window]
	, dim_detail_health.nhs_claim_status		AS [Status of Claim]
	--, ''		AS [Strategy/Risks]
	--, ''		AS [Safety and Learning]
	--, ''		AS [Actions for the Trust to Address and Deadline]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)		AS [Date Claim Concluded]
	--, dim_detail_outcome.outcome_of_case			AS [Outcome of Case]
	--, CAST(dim_detail_health.zurichnhs_date_final_bill_sent_to_client AS DATE)		AS [Date Final Bill Sent]
	--, CAST(dim_matter_header_current.date_opened_practice_management AS date)		AS [Date Opened]
	, dim_detail_core_details.associated_matter_numbers			AS [Associated Matter Numbers]
		, CASE
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') THEN --non-clinical
			CASE 
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) = 0 THEN
					'1 - ncl'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 0.01 AND 5000 THEN
					'2 - ncl'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 5001 AND 10000 THEN
					'3 - ncl'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 10001 AND 25000 THEN
					'4 - ncl'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 25001 AND 50000 THEN
					'5 - ncl'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) > 50000 THEN
					'6 - ncl'
				ELSE
					'7 - ncl'
			END 
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') THEN	--clinical
			CASE 
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) = 0 THEN
					'1 - cl'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 0.01 AND 50000 THEN
					'2 - cl'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 50001 AND 250000 THEN
					'3 - cl'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 250001 AND 500000 THEN
					'4 - cl'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 500001 AND 1000000 THEN
					'5 - cl'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) > 1000000 THEN
					'6 - cl'
				ELSE
					'7 - cl'
			END
	END							AS [Damages Tranche Order]
	, CASE
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') THEN --non-clinical
			CASE 
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) = 0 THEN
					'£0'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 0.01 AND 5000 THEN
					'£1 - £5,000'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 5001 AND 10000 THEN
					'£5,001 - £10,000'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 10001 AND 25000 THEN
					'£10,001 - £25,000'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 25001 AND 50000 THEN
					'£25,001 - £50000'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) > 50000 THEN
					'£50,001+'
				ELSE
					'Non-clinical N/A'
			END 
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') THEN	--clinical
			CASE 
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) = 0 THEN
					'£0'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 0.01 AND 50000 THEN
					'£1 - £50,000'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 50001 AND 250000 THEN
					'£50,001 - £250,000'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 250001 AND 500000 THEN
					'£250,001 - £500,000'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 500001 AND 1000000 THEN
					'£500,001 - £1,000,000'
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) > 1000000 THEN
					'£1,000,001+'
				ELSE 
					'Clinical N/A'
			END
	END							AS [Damages Tranche]
	, CASE
		--non-clinical
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') AND dim_detail_core_details.present_position = 'Claim and costs outstanding' THEN 
			1
		ELSE
			0
	  END							AS [Non-Clinical]
	, CASE
		--clinical
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') 
		AND dim_detail_core_details.present_position = 'Claim and costs outstanding' THEN
			1
		ELSE	
			0
	  END							AS [Clinical]

	,[Risk Management Recommendations] = CASE WHEN dim_detail_health.[nhs_risk_management_factor] IS NULL THEN 'N/A'
	                                          WHEN dim_detail_health.[nhs_risk_management_factor] IS NOT NULL THEN dim_detail_health.[nhs_risk_management_recommendations] END -- Added 20210319 - MT
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
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
	LEFT OUTER JOIN #rag_status
		ON #rag_status.client_code = dim_matter_header_current.client_code
	 		AND #rag_status.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN #witness_list_table
		ON #witness_list_table.client_code = dim_matter_header_current.client_code
			AND	#witness_list_table.matter_number = dim_matter_header_current.matter_number
	INNER JOIN #defendant_trust
		ON (CASE WHEN RTRIM(dim_detail_claim.defendant_trust) IS NULL THEN 'Missing' ELSE RTRIM(dim_detail_claim.defendant_trust) END) = #defendant_trust.ListValue COLLATE DATABASE_DEFAULT 
	INNER JOIN #specialty
		--lengthy ltrim(rtrim(replace())) to account for extra chars not dealt with just with a trim		
		ON (CASE WHEN dim_detail_health.nhs_speciality IS NULL THEN 'Missing' ELSE LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(dim_detail_health.nhs_speciality, CHAR(10), CHAR(32)),CHAR(13), CHAR(32)),CHAR(160), CHAR(32)),CHAR(9),CHAR(32))))  END) = #specialty.ListValue COLLATE DATABASE_DEFAULT
	INNER JOIN #instruction_type
		ON RTRIM(#instruction_type.ListValue) COLLATE DATABASE_DEFAULT = ISNULL(CASE WHEN dim_detail_health.nhs_instruction_type = '' THEN 'Missing' ELSE RTRIM(dim_detail_health.nhs_instruction_type) END, 'Missing')
	INNER JOIN #referral_reason
		ON RTRIM(#referral_reason.ListValue) COLLATE DATABASE_DEFAULT = ISNULL(CASE WHEN LOWER(dim_detail_core_details.referral_reason) = '' THEN 'missing' ELSE LOWER(RTRIM(dim_detail_core_details.referral_reason)) END, 'missing')
	LEFT OUTER JOIN #key_date_list_table
		ON #key_date_list_table.client_code = dim_matter_header_current.client_code
			AND #key_date_list_table.matter_number = dim_matter_header_current.matter_number
WHERE
	dim_matter_header_current.master_client_code = 'N1001'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_matter_header_current.ms_only = 1
	--AND dim_detail_core_details.present_position = 'Claim and costs outstanding'
ORDER BY	
	risk_rating_order
	, [Claimant Name]

END


GO
