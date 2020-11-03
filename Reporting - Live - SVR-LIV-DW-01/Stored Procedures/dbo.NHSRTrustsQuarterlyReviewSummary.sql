SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-10-16
-- Ticket:		#68460
-- Description:	To deal with the Summary tables on NHSR Trusts Quarterly Review report, summary doesn't need @start_date & @end_date that NHSRTrustsQuarterlyReview uses
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
               

SELECT udt_TallySplit.ListValue  INTO #defendant_trust FROM 	dbo.udt_TallySplit('|', @def_trust)
SELECT udt_TallySplit.ListValue  INTO #specialty FROM 	dbo.udt_TallySplit('|', @nhs_specialty)
SELECT udt_TallySplit.ListValue  INTO #instruction_type FROM 	dbo.udt_TallySplit('|', @instruction_type)
SELECT udt_TallySplit.ListValue  INTO #referral_reason FROM 	dbo.udt_TallySplit('|', @referral_reason)

SELECT 
	dim_detail_claim.defendant_trust			AS [Trust]
	, dim_client_involvement.insuredclient_reference		AS [Trust Ref]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number	AS [Panel Ref]
	, dim_claimant_thirdparty_involvement.claimant_name			AS [Claimant Name]
	, dim_detail_core_details.injury_type					AS [Injury Type]
	, CAST(dim_detail_core_details.incident_date AS DATE)			AS [Incident Date]
	, dim_detail_core_details.brief_details_of_claim			AS [Brief Details of Claim]
	, dim_detail_outcome.reason_for_settlement					AS [Reason For Settlement]
	, dim_detail_health.nhs_instruction_type		AS [Instruction Type]
	, dim_detail_health.nhs_speciality					AS [Speciality]
	, dim_detail_core_details.referral_reason		AS [Referral Reason]
	, fact_finance_summary.damages_paid				AS [Damages Paid]
	, dim_detail_health.nhs_scheme					AS [NHS Scheme]
	, CASE
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') THEN 
			'Non-Clinical'
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') THEN
			'Clinical'
	  END					AS [Clinical/Non-Clinical]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)		AS [Date Claim Concluded]
	, LEFT(DATENAME(MONTH, dim_detail_outcome.date_claim_concluded), 3) + '-' + FORMAT(dim_detail_outcome.date_claim_concluded, 'yy')	AS [chart_date_claim_concluded]
	, CASE
		--non-clinical
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') AND dim_detail_outcome.date_claim_concluded BETWEEN @last_year AND CAST(GETDATE() AS DATE) THEN 
			1
		ELSE
			0
	  END							AS [Non-Clinical]
	, CASE
		--clinical
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') 
		AND dim_detail_outcome.date_claim_concluded BETWEEN @last_year AND CAST(GETDATE() AS DATE) THEN
			1
		ELSE	
			0
	  END							AS [Clinical]
	, CASE
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') THEN --non-clinical
			CASE 
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) = 0 THEN
					1
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 0.01 AND 5000 THEN
					2
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 5001 AND 10000 THEN
					3
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 10001 AND 25000 THEN
					4
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 25001 AND 50000 THEN
					5
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) > 50000 THEN
					6
			END 
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') THEN	--clinical
			CASE 
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) = 0 THEN
					1
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 0.01 AND 50000 THEN
					2
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 50001 AND 250000 THEN
					3
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 250001 AND 500000 THEN
					4
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) BETWEEN 500001 AND 1000000 THEN
					5
				WHEN COALESCE(fact_finance_summary.damages_paid, fact_finance_summary.damages_reserve) > 1000000 THEN
					6
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
			END
	END							AS [Damages Tranche]
	, CASE
		--non-clinical
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'PES', 'LTPS') AND dim_detail_outcome.date_claim_concluded BETWEEN @last_year AND CAST(GETDATE() AS DATE) THEN 
			fact_finance_summary.damages_paid		
		ELSE
			0
	  END				AS [Non-Clinical Damages Paid Past 12 Months]
	, CASE
		--clinical
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'ELS', 'DH CL', 'CNSGP', 'ELSGP', 'Inquest funding', 'Inquest Funding') 
		AND dim_detail_outcome.date_claim_concluded BETWEEN @last_year AND CAST(GETDATE() AS DATE) THEN
					fact_finance_summary.damages_paid		
		ELSE
			0
	  END				AS [Clinical Damages Paid Past 12 Months]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
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
WHERE
	dim_matter_header_current.master_client_code = 'N1001'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_detail_outcome.date_claim_concluded >= @last_year
	AND dim_matter_header_current.ms_only = 1

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
	, dim_date.calendar_date
	, LEFT(DATENAME(MONTH, dim_date.calendar_date), 3) + '-' + FORMAT(dim_date.calendar_date, 'yy')
	, 0
	, 0
	, NULL
	, NULL
	, NULL
	, NULL
FROM red_dw.dbo.dim_date
WHERE
	dim_date.calendar_date BETWEEN @last_year AND GETDATE()

END

GO
