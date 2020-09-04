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
--DECLARE @start_date AS DATE = '2020-04-01'
--		, @end_date AS DATE = '2020-08-31'
--		, @def_trust AS VARCHAR(MAX) = 'Missing|5 Boroughs Partnership NHS Foundation Trust|Aintree University Hospital NHS Foundation Trust|Airedale NHS Foundation Trust|Barking, Havering and Redbridge University Hospitals NHS|Barking, Havering and Redbridge University Hospitals NHS Tru|Barnet and Chase Farm NHS Foundation Trust|Barnet, Enfield and Haringey Mental Health NHS Trust|Barnsley Hospital NHS Foundation Trust|Barts Health NHS Trust|Basildon and Thurrock University Hospitals NHS FND Trust|Basildon and Thurrock University Hospitals NHS Foundation Tr|Birmingham Community Healthcare NHS Trust|Birmingham Cross City Clinical Commissioning Group|Birmingham South Central Clinical Commissioning Group|Birmingham and Solihull Mental Health NHS Foundation Trust|Black Country Partnership NHS Foundation Trust|Blackpool Teaching Hospitals NHS Foundation Trust|Bolton NHS Foundation Trust|Bolton Primary Care Trust|Bradford Teaching Hospitals NHS Foundation Trust|Bridgewater Community Healthcare NHS Foundation Trust|Brighton and Sussex University Hospitals NHS Trust|Bromley Clinical Commissioning Group|Buckinghamshire Healthcare NHS Trust|Burton Hospitals NHS Foundation Trust|Bury Clinical Commissioning Group|Calderdale and Huddersfield NHS Foundation Trust|Calderstones Partnership NHS Foundation Trust|Camden and Islington NHS Foundation Trust|Central London Community Healthcare NHS Trust|Central Manchester University Hospitals NHS Foundation Trust|Central and North West London NHS Foundation Trust|Chelsea & Westminster Hospital NHS Foundation Trust|Cheshire and Wirral Partnership NHS Foundation Trust|Chesterfield Royal Hospital NHS Foundation Trust|Countess of Chester Hospital NHS Foundation Trust|County Durham and Darlington NHS Trust|Coventry and Warwickshire Partnership NHS Trust|Cumbria Partnership NHS Foundation Trust|Department of Health|Derbyshire Healthcare NHS Foundation Trust|Doncaster and Bassetlaw Hospitals NHS Foundation Trust|Dorset County Hospital NHS Foundation Trust|Dorset HealthCare University NHS Foundation Trust|Dudley & Walsall Mental Health Partnership Trust|Dudley Clinical Commissioning Group|Dudley Group NHS Foundation Trust (The)|Dudley Group of Hospitals NHS Foundation Trust (The)|Dudley Primary Care Trust|Ealing Hospital NHS Trust|East Cheshire NHS Trust|East Kent Hospitals University NHS Foundation Trust|East Lancashire Hospitals NHS Trust|East Midlands Ambulance Service NHS Trust|East Sussex Healthcare NHS Trust|East and North Hertfordshire NHS Trust|East of England Ambulance NHS Trust|Epsom and St Helier University Hospitals NHS Trust|Frimley Health NHS Foundation Trust|Gateshead Health NHS Foundation Trust|George Eliot Hospital NHS Trust|Great Ormond Street Hospital for Children NHS FND Trust|Great Ormond Street Hospital for Children NHS Foundation Tru|Great Western Hospitals NHS Foundation Trust|Greater Manchester West Mental Health NHS Foundation Trust|Hampshire Hospitals NHS Foundation Trust|Haringey Clinical Commissioning Group|Health Protection Agency|Heart Of England NHS Foundation Trust|Heart of England NHS Foundation Trust|Herefordshire Primary Care Trust|Heywood, Middleton & Rochdale Primary Care Trust|Homerton University Hospital NHS Foundation Trust|Hounslow and Richmond Community NHS Trust|Humber NHS Foundation Trust|Imperial College Healthcare NHS Trust|James Paget University Hospitals NHS Foundation Trust|Knowsley Clinical Commissioning Group|Lancashire Care NHS Foundation Trust|Lancashire Teaching Hospitals NHS Foundation Trust|Leeds Teaching Hospitals NHS Trust|Leeds and York Partnership NHS Foundation Trust|Leicester City Primary Care Trust|Leicestershire Partnership NHS Trust|Lewisham and Greenwich NHS Trust|Liverpool Clinical Commissioning Group|Liverpool Community Health Trust|Liverpool Heart and Chest Hospital NHS Foundation|London Ambulance Service NHS Trust|London North West Healthcare NHS Trust|Luton and Dunstable University Hospital NHS Foundation Trust|Maidstone and Tunbridge Wells NHS Trust|Manchester Mental Health and Social Care Trust|Manchester University NHS Foundation Trust|Mersey Care NHS Foundation Trust|Mersey Care NHS Trust|Mid Staffordshire Hospital NHS Foundation Trust|Mid-Essex Primary Care Trust|Midlands Partnership NHS Trust|Milton Keynes Hospital NHS Foundation Trust|Moorfields Eye Hospital NHS Foundation Trust|N/A - GPI matter|NHS Blood and Transplant|NHS Commissioning Board Authority|NHS Direct|NHS England|Newcastle-Upon-Tyne Hospitals NHS Foundation Trust|Norfolk & Suffolk NHS Foundation Trust|North Cumbria University Hospitals NHS Trust|North East Essex Clinical Commissioning Group|North East Essex Primary Care Trust|North East London NHS Foundation Trust|North Essex Partnership NHS Foundation Trust|North Middlesex University Hospital NHS Trust|North West Ambulance NHS Trust|North/South/Central Manchester Clinical Commissioning Group|Nottingham University Hospitals NHS Trust|Other|Oxford Radcliiffe Hospitals NHS Trust|Oxford University Hospitals NHS Trust|Oxfordshire Clinical Commissioning Group|Oxleas NHS Foundation Trust|Pennine Acute Hospitals NHS Trust (The)|Pennine Care NHS Foundation Trust|Peterborough and Stamford Hospitals NHS Foundation Trust|Poole Hospital NHS Foundation Trust|Portsmouth Hospitals NHS Trust|Princess Alexandra Hospital NHS Trust|Queen Victoria Hospital NHS Foundation Trust|Redditch and Bromsgrove Clinical Commissioning Group|Royal Brompton and Harefield NHS Foundation Trust|Royal Cornwall Hospitals NHS Trust|Royal Free London NHS Foundation Trust|Royal Liverpool & Broadgreen University Hosp NHS Trust (The)|Royal Liverpool and Broadgreen University Hospitals NHS Trus|Royal Surrey County Hospital NHS Foundation Trust|Salford Royal NHS Foundation Trust|Sandwell & West Birmingham Hospitals NHS Trust|Secretary of State for Health|Sheffield Health and Social Care NHS Foundation Trust|Sheffield Teaching Hospitals NHS Foundation Trust|Shrewsbury and Telford Hospital NHS Trust|South Central Ambulance Service NHS Foundation Trust|South Essex Partnership University NHS Foundation Trust|South London & Maudsley NHS Foundation Trust|South Staffordshire & Shropshire Healthcare NHS FND Trust|South Staffordshire & Shropshire Healthcare NHS Foundation T|South Warwickshire Clinical Commissioning Group|South Western Ambulance Service NHS Foundation Trust|Southend University Hospital NHS Foundation Trust|Southern Health NHS Foundation Trust|Southport and Ormskirk Hospital NHS Trust|Southwark Clinical Commissioning Group|St Helens & Knowsley Teaching Hospitals NHS Trust|St Helens and Knowsley Hospitals NHS Trust|Staffordshire & Stoke-on-Trent Partnership NHS Trust|Stockport NHS Foundation Trust|Surrey & Borders Partnership NHS Foundation Trust|Surrey Primary Care Trust|Surrey and Sussex Healthcare NHS Trust|Sussex Partnership NHS Foundation Trust|Tameside And Glossop Clinical Commissioning Group|Tameside Hospital NHS Foundation Trust|Tameside and Glossop Integrated Care NHS Foundation Trust|Tavistock and Portman NHS Foundation Trust|Tees Esk & Wear Valleys NHS Trust|The Christie NHS Foundation Trust|The Clatterbridge Cancer Centre NHS Foundation Trust|The Hillingdon Hospitals NHS Foundation Trust|The Royal Berkshire NHS Foundation Trust|The Royal Bournemouth and Christchurch Hospitals NHS Foundat|The Royal Marsden NHS Foundation Trust|The Royal Orthopaedic Hospital NHS Foundation Trust|The Royal Wolverhampton NHS Trust|The Walton Centre NHS Foundation Trust|Torbay & Southern Devon Health & Care NHS Trust|United Lincolnshire Hospitals NHS Trust|University College London Hospitals NHS Foundation Trust|University Hospital Of North Staffordshire NHS Trust|University Hospital Of South Manchester NHS Foundation Trust|University Hospitals Birmingham NHS Foundation Trust|University Hospitals Bristol NHS Foundation Trust|University Hospitals Coventry and Warwickshire NHS Trust|University Hospitals Derby and Burton NHS Foundation Trust|University Hospitals Of Leicester NHS Trust|University Hospitals Of Morecambe Bay NHS Foundation Trust|University Hospitals of North Midlands NHS Trust|Walsall Healthcare NHS Trust|Warrington & Halton Hospitals NHS Foundation Trust|Warrington Clinical Commissioning Group|Warwickshire Primary Care Trust|West Hertfordshire Hospitals NHS Trust|West London Mental Health NHS Trust|West Middlesex University Hospital NHS Trust|West Midlands Ambulance Service NHS Trust|Western Sussex Hospitals NHS Foundation Trust|Wiltshire Clinical Commissioning Group|Wirral Clinical Commissioning Group|Wirral Community NHS Trust|Wirral University Teaching Hospital NHS Foundation Trust|Wolverhampton City Clinical Commissioning Group|Worcestershire Acute Hospitals NHS Trust|Worcestershire Health and Care NHS Trust|Wrightington, Wigan & Leigh NHS Foundation Trust|Wye Valley NHS Trust|York Teaching Hospital NHS Foundation Trust|Yorkshire Ambulance Service NHS Trust' 
--		, @nhs_specialty AS VARCHAR(MAX) = 'Ambulance|Anaesthesia|Antenatal Clinic|Audiological Medicine|Cardiology|Casualty / A & E|Chemical Pathology|Community Medicine/ Public Health|Community Midwifery|Dentistry|Dermatology|District Nursing|Gastroenterology|General Medicine|General Surgery|Genito-Urinary Medicine|Geriatric Medicine|Gynaecology|Haematology|Histopathology|Infectious Diseases|Intensive Care Medicine|Microbiology/ Virology|Missing|NHS Direct Services|Neurology|Neurosurgery|Non-Clinical Staff|Non-obstetric claim|Not Specified|Obstetrics|Obstetrics / Gynaecology|Oncology|Opthalmology|Oral & Maxillo Facial Surgery|Orthopaedic Surgery|Other|Otorhinolaryngology/ ENT|Paediatrics|Palliative Medicine|Pharmacy|Physiotherapy|Plastic Surgery|Podiatry|Psychiatry/ Mental Health|Radiology|Rehabilitation|Renal Medicine|Respiratory Medicine/ Thoracic Medic|Rheumatology|Surgical Speciality - Other|Unknown|Urology|Vascular Surgery' 
--		, @instruction_type AS VARCHAR(MAX) = 'Breast screenings - group action|C&W Group Action|C-Difficile|CFF 100 (Non-PA)|CFF 100 (PA)|CFF 250 (Non-PA)|CFF 250 (PA)|CFF 50 (Non-PA)|CFF 50 (PA)|Clinical - Delegated, FF|Clinical - Non DA|Clinical - Non DA (ENS)|Clinical - Non DA - FF|DPA/Defamation etc|Derbyshire Healthcare Group Action|EL/PL - PADs|EL/PL - old delegated matters|EL/PL DA|EL/PL Non DA|ELS - Non DA|East Lancs Group Action|East Sussex Group Action|Expert Report + LoR - Limited|Expert Report - Limited|Full Investigation - Limited|HIV Recall Group|ISS 250|ISS 250 Advisory|Inquest - C|Inquest - NC|Inquest - associated claim|Inquests|Letter of Response - Limited|Lot 3 work|MTW Group Action|Mediation - capped fee|Mid Staffs Group Action|Missing|NCFF 25|OSINT & Claims Validation|OSINT - Sch 1 FF|OSINT - Sch 2 - FF|OSINT - Sch 2 - HR|Other|RG - UHNM Group Action|Schedule 1|Schedule 2|Schedule 3|Schedule 4|Schedule 4 (ENS)|Schedule 5 (ENS)|TB Group Midlands Partnership|UHNS Group Action|Worcester Group Action'
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
	, CASE	
		WHEN key_date_rag.rag = 'red' THEN
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
WHERE
	dim_matter_header_current.master_client_code = 'N1001'
	AND (dim_matter_header_current.date_closed_practice_management IS NULL OR dim_matter_header_current.date_closed_practice_management > @nDate)


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
		FOR XML PATH('')
	) c (key_date_list)

--==============================================================================================================================================================
--==============================================================================================================================================================



SELECT 
	#rag_status.[Risk Rating]							AS [Risk Rating]
	, dim_detail_claim.defendant_trust			AS [Trust]
	, dim_client_involvement.insuredclient_reference		AS [Trust Ref]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number	AS [Panel Ref]
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
	, #key_date_list_table.key_date_list			AS [Key Dates Approaching]
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
	AND (dim_detail_health.zurichnhs_date_final_bill_sent_to_client IS NULL OR dim_detail_health.zurichnhs_date_final_bill_sent_to_client BETWEEN @start_date AND @end_date)
	AND (dim_matter_header_current.date_closed_practice_management IS NULL OR dim_matter_header_current.date_closed_practice_management > @nDate)

ORDER BY	
	dim_matter_header_current.date_opened_practice_management	

END




GO
