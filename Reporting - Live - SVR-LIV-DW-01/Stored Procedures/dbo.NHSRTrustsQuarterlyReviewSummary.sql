SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-10-16
-- Ticket:		#68460
-- Description:	To deal with the Summary tables on NHSR Trusts Quarterly Review report, summary doesn't need @start_date & @end_date that NHSRTrustsQuarterlyReview uses
-- Update: MT as per 92701 added [Risk Management Recommendations] 
-- Update: JL as per ticket #122283 have rejigged the where. Added in case statement and "AND/OR" conditions to determine the correct order to evaluate the where in as was not bring back the correct matters. Also added distinct to start as the #specialty join was duplicating matters
-- =============================================
CREATE PROCEDURE [dbo].[NHSRTrustsQuarterlyReviewSummary]
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
--DECLARE @def_trust AS VARCHAR(MAX) = 'forWrightington, Wigan & Leigh NHS Foundation Trust'
--	, @nhs_specialty AS VARCHAR(MAX) = 'Ambulance|Anaesthesia|Antenatal Clinic|Audiological Medicine|Cardiology|Casualty / A & E|Chemical Pathology|Community Medicine/ Public Health|Community Midwifery|Dentistry|Dermatology|District Nursing|Gastroenterology|General Medicine|General Surgery|Genito-Urinary Medicine|Geriatric Medicine|Gynaecology|Haematology|Histopathology|Infectious Diseases|Intensive Care Medicine|Microbiology/ Virology|Missing|NHS Direct Services|Neurology|Neurosurgery|Non-Clinical Staff|Non-obstetric claim|Not Specified|Obstetrics|Obstetrics / Gynaecology|Oncology|Opthalmology|Oral & Maxillo Facial Surgery|Orthopaedic Surgery|Other|Otorhinolaryngology/ ENT|Paediatrics|Palliative Medicine|Pharmacy|Physiotherapy|Plastic Surgery|Podiatry|Psychiatry/ Mental Health|Radiology|Rehabilitation|Renal Medicine|Respiratory Medicine/ Thoracic Medic|Rheumatology|Surgical Speciality - Other|Unknown|Urology|Vascular Surgery' 
--	, @instruction_type AS VARCHAR(MAX) = 'ISS Plus|Expert Report + LoR - Limited|2022: LIQ100|Schedule 5 (ENS)|HIV Recall Group|Letter of Response - Limited|2022: CDI|Mediation - capped fee|Inquests|CFF 250 (PA)|2022: C500|Full Investigation - Limited|2022: SCH5|OSINT - Sch 1 FF|CFF 250 (Non-PA)|2022: NCDI|OSINT & Claims Validation|EL/PL - old delegated matters|GPI - Advice|ISS 250 Advisory|CFF 50 (PA)|CFF 50 (Non-PA)|Clinical - Non DA - FF|Inquest - NC|Expert Report - Limited|2022: LI250|2022: C500+|Clinical - Non DA|EL/PL DA|OSINT - Sch 2 - FF|EL/PL Non DA|2022: C100|EL/PL - PADs|Breast screenings - group action|2022: INQ NC|DPA/Defamation etc|Worcester Group Action|MTW Group Action|Mid Staffs Group Action|UHNS Group Action|C&W Group Action|2022: AOS|Lot 3 work|2022: LI100|2022: CDI (ENS)|C-Difficile|East Lancs Group Action|Clinical - Delegated, FF|Schedule 3|Clinical - Non DA (ENS)|2022: C250|2022: INC C|Schedule 4|ELS - Non DA|Other|East Sussex Group Action|NCFF 25|CFF 100 (Non-PA)|TB Group Midlands Partnership|Inquest - C|RG - UHNM Group Action|ISS 250|Schedule 4 (ENS)|Sodium Valproate claims|Derbyshire Healthcare Group Action|2022: NC100|Schedule 1|CFF 100 (PA)|Inquest - associated claim|ISS Plus Advisory|OSINT - Sch 2 - HR|Buckinghamshire Data Breach - Group Action|2022: INQ AC|Schedule 2|Missing|2022: LI250+'
--	, @referral_reason AS VARCHAR(MAX) = 'advice only|costs dispute|criminal representation|dispute on liability|dispute on liability and quantum|dispute on quantum|hse prosecution|in house|infant approval|inquest|intel only|missing|nomination only|pre-action disclosure|recovery'

--==========================================================================================================================================================================================
-- Parameter queries
--==========================================================================================================================================================================================
--SELECT DISTINCT RTRIM(dim_detail_claim.defendant_trust), ISNULL(RTRIM(dim_detail_claim.defendant_trust), 'Missing') AS [def_trust]
--FROM red_dw.dbo.dim_detail_claim
--ORDER BY
--	def_trust

--SELECT STRING_AGG(CAST(specialty.specialty AS NVARCHAR(MAX)),'|') AS all_specialties
--FROM (
--SELECT DISTINCT ISNULL(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(dim_detail_health.nhs_speciality, CHAR(10), CHAR(32)),CHAR(13), CHAR(32)),CHAR(160), CHAR(32)),CHAR(9),CHAR(32)))), 'Missing')  AS [specialty]
--FROM red_dw.dbo.dim_detail_health
--) AS specialty

--SELECT STRING_AGG(CAST(instruction_type.inst_type AS NVARCHAR(MAX)), '|')	AS  all_inst_types
--FROM (
--SELECT DISTINCT ISNULL(CASE WHEN dim_detail_health.nhs_instruction_type = '' THEN 'Missing' ELSE RTRIM(dim_detail_health.nhs_instruction_type) END, 'Missing') AS [inst_type]
--FROM red_dw.dbo.dim_detail_health
--) AS instruction_type

--SELECT STRING_AGG(CAST(referral_reason.ref_reason AS NVARCHAR(MAX)), '|')	AS all_ref_reasons
--FROM (
--SELECT DISTINCT ISNULL(CASE WHEN LOWER(dim_detail_core_details.referral_reason) = '' THEN 'missing' ELSE LOWER(RTRIM(dim_detail_core_details.referral_reason)) END, 'missing') AS [ref_reason]
--FROM red_dw.dbo.dim_detail_core_details 
--) AS referral_reason

--============================================================================================================================================================================================

DECLARE @nDate AS DATETIME = (SELECT MIN(dim_date.calendar_date) FROM red_dw..dim_date WHERE dim_date.fin_year = (SELECT fin_year - 3 FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = CAST(GETDATE() AS DATE)))
DECLARE @last_year AS DATE = DATEADD(MONTH, -11, GETDATE()+1)-DAY(GETDATE())


--SELECT @last_year

-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#defendant_trust') IS NOT NULL   DROP TABLE #defendant_trust
IF OBJECT_ID('tempdb..#specialty') IS NOT NULL   DROP TABLE #specialty
IF OBJECT_ID('tempdb..#instruction_type') IS NOT NULL   DROP TABLE #instruction_type
IF OBJECT_ID('tempdb..#referral_reason') IS NOT NULL   DROP TABLE #referral_reason
               

SELECT udt_TallySplit.ListValue  INTO #defendant_trust FROM 	dbo.udt_TallySplit('|', @def_trust)
SELECT udt_TallySplit.ListValue  INTO #specialty FROM 	dbo.udt_TallySplit('|', @nhs_specialty)
SELECT udt_TallySplit.ListValue  INTO #instruction_type FROM 	dbo.udt_TallySplit('|', @instruction_type)
SELECT udt_TallySplit.ListValue  INTO #referral_reason FROM 	dbo.udt_TallySplit('|', @referral_reason)

SELECT 	 distinct	 --JL Added 30-11-2021 #122283
	dim_detail_claim.defendant_trust			AS [Trust]
	, dim_client_involvement.insuredclient_reference		AS [Trust Ref]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number	AS [Panel Ref]
	, dim_matter_header_current.matter_owner_full_name	AS [Panel Case Handler]
	, dim_claimant_thirdparty_involvement.claimant_name			AS [Claimant Name]
	, dim_detail_core_details.injury_type					AS [Injury Type]
	, CAST(dim_detail_core_details.incident_date AS DATE)			AS [Incident Date]
	, dim_detail_core_details.brief_details_of_claim			AS [Brief Details of Claim]
	, dim_detail_outcome.reason_for_settlement					AS [Reason For Settlement]
	, dim_detail_health.nhs_instruction_type		AS [Instruction Type]
	--, dim_detail_health.nhs_speciality					AS [Speciality]
	, CASE
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') THEN
			dim_matter_worktype.work_type_name
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') THEN 
			dim_detail_health.nhs_speciality	
	  END											AS [Speciality]
	, dim_detail_core_details.referral_reason		AS [Referral Reason]


	 --,CASE WHEN nhs_instruction_type IN ('EL/PL - PADs','Expert Report - Limited','Expert Report + LoR - Limited','Full Investigation - Limited'
		--,'GPI - Advice','Inquest - associated claim','ISS 250','ISS 250 Advisory','ISS Plus','ISS Plus Advisory'
		--,'Letter of Response - Limited','Lot 3 work','OSINT - Sch 1 FF','OSINT - Sch 2 - FF','OSINT & Claims Validation'
		--,'OSINT & Fraud (returned to NHS Protocol)','OSINT (advice)','Schedule 1','Schedule 2','Schedule 3'
		--,'Schedule 4','Schedule 4 (ENS)','Schedule 5 (ENS)') THEN 
		--	00 ELSE fact_finance_summary.damages_paid	END AS [Damages Paid]
	, fact_finance_summary.damages_paid			AS [Damages Paid]


	, dim_detail_health.nhs_scheme					AS [NHS Scheme]
	, CASE
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS', 'LTPS') THEN 
			'Non-Clinical'
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') THEN
			'Clinical'
	  END					AS [Clinical/Non-Clinical]
	, ISNULL(CAST(dim_detail_outcome.date_claim_concluded AS DATE),dim_detail_health.zurichnhs_date_final_bill_sent_to_client)		AS [Date Claim Concluded]
	, LEFT(DATENAME(MONTH, ISNULL(CAST(dim_detail_outcome.date_claim_concluded AS DATE),dim_detail_health.zurichnhs_date_final_bill_sent_to_client)), 3) + '-' + FORMAT(ISNULL(CAST(dim_detail_outcome.date_claim_concluded AS DATE),dim_detail_health.zurichnhs_date_final_bill_sent_to_client), 'yy')	AS [chart_date_claim_concluded]
	, CASE
		--non-clinical
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') AND ISNULL(CAST(dim_detail_outcome.date_claim_concluded AS DATE),dim_detail_health.zurichnhs_date_final_bill_sent_to_client) BETWEEN @last_year AND CAST(GETDATE() AS DATE) THEN 
			1
		ELSE
			0
	  END							AS [Non-Clinical]
	, CASE
		--clinical
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') 
		AND ISNULL(CAST(dim_detail_outcome.date_claim_concluded AS DATE),dim_detail_health.zurichnhs_date_final_bill_sent_to_client) BETWEEN @last_year AND CAST(GETDATE() AS DATE) THEN
			1
		ELSE	
			0
	  END							AS [Clinical]
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
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') AND ISNULL(CAST(dim_detail_outcome.date_claim_concluded AS DATE),dim_detail_health.zurichnhs_date_final_bill_sent_to_client) BETWEEN @last_year AND CAST(GETDATE() AS DATE) THEN 
			fact_finance_summary.damages_paid		
		ELSE
			0
	  END				AS [Non-Clinical Damages Paid Past 12 Months]
	, CASE
		--clinical
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') 
		AND ISNULL(CAST(dim_detail_outcome.date_claim_concluded AS DATE),dim_detail_health.zurichnhs_date_final_bill_sent_to_client) BETWEEN @last_year AND CAST(GETDATE() AS DATE) THEN
					fact_finance_summary.damages_paid		
		ELSE
			0
	  END				AS [Clinical Damages Paid Past 12 Months]

	,[Risk Management Recommendations] = CASE WHEN dim_detail_health.nhs_risk_management_recommendations IS NOT NULL THEN dim_detail_health.nhs_risk_management_recommendations
											  WHEN dim_detail_health.[nhs_risk_management_factor] IS NULL THEN 'N/A'
	                                          WHEN dim_detail_health.[nhs_risk_management_factor] IS NOT NULL THEN dim_detail_health.[nhs_risk_management_recommendations] END -- Added 20210319 - MT
	,dim_detail_health.[nhs_risk_management_factor]	--Added 20211122 - JL
	,	CASE 
		WHEN nhs_instruction_type IN 
		('CFF 50 (Non-PA)','CFF 50 (PA)','Clinical - Delegated, FF','Clinical - Non DA - FF'
		,'EL/PL - old delegated matters','EL/PL DA','NCFF 25','2022: C100','2022: MOJ IA','2022: MOJ S3','2022: NC100') THEN 
			'Delegated authority'
		WHEN nhs_instruction_type IN 
		('Breast screenings - group action','C&W Group Action','C-Difficile','CFF 100 (Non-PA)','CFF 100 (PA)'
		,'CFF 250 (Non-PA)','CFF 250 (PA)','Clinical - Non DA','Clinical - Non DA (ENS)','Derbyshire Healthcare Group Action'
		,'DPA/Defamation etc','East Lancs Group Action','East Sussex Group Action','EL/PL Non DA','ELS - Non DA','HIV Recall Group'
		,'Manchester bombings','Mediation - capped fee','Mid Staffs Group Action','MTW Group Action','OSINT - Sch 2 - HR'
		,'RG - UHNM Group Action','SME Group Action','SV - Group action','TB Group Midlands Partnership','UHNS Group Action'
		,'Worcester Group Action','WWL - Data Breach group action','2022: C250','2022: C500','2022: C500+','2022: CDI','2022: CDI (ENS)','2022: NC250','2022: NC250+','2022: NCDI','2022: Sodium Valproate','MED: 2022','Sodium Valproate claims','Buckinghamshire Data Breach - Group Action') THEN 
			'Direct instruction'
		WHEN nhs_instruction_type IN ('Inquest - C','Inquest - NC','Inquests','2022: INC C',
'2022: INQ NC') THEN 
			'Inquest'
		WHEN nhs_instruction_type IN ('EL/PL - PADs','Expert Report - Limited','Expert Report + LoR - Limited','Full Investigation - Limited'
		,'GPI - Advice','Inquest - associated claim','ISS 250','ISS 250 Advisory','ISS Plus','ISS Plus Advisory'
		,'Letter of Response - Limited','Lot 3 work','OSINT - Sch 1 FF','OSINT - Sch 2 - FF','OSINT & Claims Validation'
		,'OSINT & Fraud (returned to NHS Protocol)','OSINT (advice)','Schedule 1','Schedule 2','Schedule 3'
		,'Schedule 4','Schedule 4 (ENS)','Schedule 5 (ENS)',
		'2022: AOS','2022: INQ AC','2022: LI250','2022: LI250+','2022: LIQ100','2022: LIQ250','2022: LIQ250+','2022: PAD','2022: SCH5','2022: LI100')
		 THEN 
			'Limited instructions'
		WHEN nhs_instruction_type IN ('Other') THEN 
			'Other'
	  END			AS NewInstructionType --Added 20211122 - JL
	  ,	dim_detail_health.zurichnhs_date_final_bill_sent_to_client


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
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key

	INNER JOIN #defendant_trust
		ON (CASE WHEN RTRIM(dim_detail_claim.defendant_trust) IS NULL THEN 'Missing' ELSE RTRIM(dim_detail_claim.defendant_trust) END) = #defendant_trust.ListValue COLLATE DATABASE_DEFAULT 
	INNER JOIN #specialty
		--lengthy ltrim(rtrim(replace())) to account for extra chars not dealt with just with a trim		
		ON (CASE WHEN dim_detail_health.nhs_speciality IS NULL THEN 'Missing' ELSE LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(dim_detail_health.nhs_speciality, CHAR(10), CHAR(32)),CHAR(13), CHAR(32)),CHAR(160), CHAR(32)),CHAR(9),CHAR(32))))  END) = #specialty.ListValue COLLATE DATABASE_DEFAULT
	INNER JOIN #instruction_type
		ON RTRIM(#instruction_type.ListValue) COLLATE DATABASE_DEFAULT = ISNULL(CASE WHEN dim_detail_health.nhs_instruction_type = '' THEN 'Missing' ELSE RTRIM(dim_detail_health.nhs_instruction_type) END, 'Missing')
	INNER JOIN #referral_reason
		ON RTRIM(#referral_reason.ListValue) COLLATE DATABASE_DEFAULT = ISNULL(CASE WHEN LOWER(dim_detail_core_details.referral_reason) = '' THEN 'missing' ELSE LOWER(RTRIM(dim_detail_core_details.referral_reason)) END, 'missing')
		LEFT OUTER JOIN red_dw.dbo.dim_instruction_type WITH(NOLOCK)
 ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key


WHERE
	dim_matter_header_current.master_client_code = 'N1001'	
	--AND dim_detail_health.matter_number = '00020596'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND ISNULL(RTRIM(LOWER(dim_detail_outcome.outcome_of_case)), '') <> 'exclude from reports'
	and(CASE WHEN nhs_instruction_type IN ('EL/PL - PADs','Expert Report - Limited','Expert Report + LoR - Limited','Full Investigation - Limited'
		,'GPI - Advice','Inquest - associated claim','ISS 250','ISS 250 Advisory','ISS Plus','ISS Plus Advisory'
		,'Letter of Response - Limited','Lot 3 work','OSINT - Sch 1 FF','OSINT - Sch 2 - FF','OSINT & Claims Validation'
		,'OSINT & Fraud (returned to NHS Protocol)','OSINT (advice)','Schedule 1','Schedule 2','Schedule 3'
		,'Schedule 4','Schedule 4 (ENS)','Schedule 5 (ENS)') THEN 
			1 ELSE 0 END  = 1 AND 	  dim_detail_health.zurichnhs_date_final_bill_sent_to_client >=@last_year) --JL Added 30-11-2021 #122283
			OR (dim_detail_outcome.date_claim_concluded >= @last_year )	  --JL Added 30-11-2021 #122283
			AND	dim_matter_header_current.master_client_code = 'N1001'				 
			AND dim_matter_header_current.reporting_exclusions = 0
				AND dim_matter_header_current.ms_only = 1
			AND ISNULL(RTRIM(LOWER(dim_detail_outcome.outcome_of_case)), '') <> 'exclude from reports'	
			 





/*
Chart in the report wasnt generating all months (or at all) if there was no closures in month/year for selected trust
The below union ensures data is populated for each month in past 12 months
*/

UNION

SELECT
	NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, dim_date.calendar_date
	, LEFT(DATENAME(MONTH, dim_date.calendar_date), 3) + '-' + FORMAT(dim_date.calendar_date, 'yy')
	, 0
	, 0
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
	, NULL
FROM red_dw.dbo.dim_date
WHERE
	dim_date.calendar_date BETWEEN @last_year AND GETDATE()

END



			
			

 
GO
