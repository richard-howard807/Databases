SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-12-09
-- Description:	NHSR insights dashboard, claimant behaviour
-- =============================================

-- =============================================
CREATE PROCEDURE [nhs].[NHSR_KYO]
	
AS
BEGIN

	SET NOCOUNT ON;

SELECT date_opened_case_management AS [Date Case Opened]
		, date_closed_case_management AS [Date Case Closed]
		, RTRIM(dim_matter_header_current.master_client_code)+'-'+dim_matter_header_current.master_matter_number AS [Mattersphere Weightmans Reference]
		, matter_description AS [Matter Description]
		, matter_owner_full_name AS [Case Manager]
		, hierarchylevel3hist AS [Department]
		, dim_matter_worktype.work_type_group AS [Matter Type Group]
		, 'All' AS [Client]
		, dim_detail_previous_details.proceedings_issued AS [Proceedings Issued]
		, dim_detail_court.date_proceedings_issued AS [Date Proceedings Issued]
		, dim_detail_core_details.track AS [Track]
		, suspicion_of_fraud AS [Suspicion of Fraud]
		, dim_detail_core_details.referral_reason AS [Referral Reason]
		, credit_hire AS [Credit Hire]
		, incident_date AS [Incident Date]
		, CASE WHEN ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'Irwin Mitchell%' THEN 'Irwin Mitchell LLP'
			WHEN ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'Thompsons%' THEN 'Thompsons LLP'
			WHEN ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'Slater and Gordon%' THEN 'Slater Gordon Solutions Legal'
			WHEN ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'Slater & Gordon%' THEN 'Slater Gordon Solutions Legal'
			WHEN ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'Slater Gordon%' THEN 'Slater Gordon Solutions Legal'
			ELSE ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) end AS [Claimant's Solicitor]
		, dim_detail_claim.dst_insured_client_name AS [Insured Client Name]
		, dim_agents_involvement.localauthority_name AS [Local Authority]
		, outcome_of_case AS [Outcome of Case]
		, dim_detail_outcome.[repudiation_outcome] [Repudiation - outcome]
		, dim_detail_court.court_location AS [Court]
		, date_claim_concluded AS [Date Claim Concluded]
		, damages_paid AS [Damages Paid by Client]
		, date_costs_settled AS [Date Costs Settled]
		, total_tp_costs_paid AS [Total Third Party Costs Paid]
		, fact_detail_claim.[claimant_sols_total_costs_sols_claimed] AS [Costs Claimed]
		, ISNULL(fact_finance_summary.damages_paid,0) + ISNULL(fact_finance_summary.total_tp_costs_paid,0) + ISNULL(fact_finance_summary.total_amount_billed,0) AS [Total Claim Spend]
		, CASE WHEN fact_finance_summary.damages_paid IS NULL OR fact_finance_summary.total_tp_costs_paid IS NULL THEN NULL ELSE ISNULL(damages_paid,0)-ISNULL(total_tp_costs_paid,0) END AS [Damages - Costs Paid]
		, DATEDIFF(DAY, incident_date, dim_detail_court.date_proceedings_issued) AS [Days to Issue]
		, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded) AS [Elapsed Days (Damages)]
		, DATEDIFF(DAY, dim_detail_core_details.incident_date, dim_detail_core_details.date_instructions_received) AS [Elapsed Days to Instructions]
		, 1 AS [Number of Records]
		, CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2018-01-01' THEN 0
			WHEN date_claim_concluded<'2018-01-01'  THEN 0
			ELSE 1 END AS [Date Filter]
		, dim_detail_core_details.covid_reason_desc AS [Covid Reason]
		, fact_finance_summary.damages_reserve AS [Damages Reserve]
		, CASE WHEN fact_finance_summary.damages_paid = 0 THEN '£0'
			WHEN fact_finance_summary.damages_paid BETWEEN 1 AND 5001 THEN '£1-£5,001'
			WHEN fact_finance_summary.damages_paid BETWEEN 5001 AND 10000 THEN '£5,001-£10,000'
			WHEN fact_finance_summary.damages_paid BETWEEN 10001 AND 25000 THEN '£10,0001-£25,0001'
			WHEN fact_finance_summary.damages_paid BETWEEN 25001 AND 50001 THEN '£25,001-£50,001'
			WHEN fact_finance_summary.damages_paid > 50001 THEN '£50,0001+'
			END AS [Damages Banding]
		, dim_matter_worktype.work_type_name AS [Matter Type]
		, CASE WHEN dim_detail_health.nhs_scheme IN ('CNSGP','CNST','DH CL','ELS','ELSGP','ELSGP (MDDUS)','ELSGP (MPS)','Inquest Funding                                             ','Inquest funding') THEN 'Clinical'
                WHEN dim_detail_health.nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'Risk'
	     END AS [Scheme]
		, DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, ISNULL(dim_detail_outcome.date_claim_concluded, dim_matter_header_current.date_closed_case_management)) AS [Lifecycle (date opened to date concluded)]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_previous_details
ON dim_detail_previous_details.dim_detail_previous_details_key = fact_dimension_main.dim_detail_previous_details_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_department
ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement
ON dim_agents_involvement.dim_agents_involvement_key = fact_dimension_main.dim_agents_involvement_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key

WHERE hierarchylevel2hist='Legal Ops - Claims'
--AND hierarchylevel3hist IN ('Motor','Large Loss','Casualty','Disease')
AND work_type_group IN ('PL All','EL')
AND CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2018-01-01' THEN 0
			WHEN date_claim_concluded<'2018-01-01'  THEN 0
			ELSE 1 END=1
AND reporting_exclusions=0
AND NOT (LOWER(RTRIM(ISNULL(outcome_of_case,''))) IN ('exclude from reports','returned to client'))
AND dim_matter_header_current.client_group_name <> 'MIB'
AND client_group_name<>'NHS Resolution'
AND NOT dim_matter_worktype.work_type_name LIKE 'PL - Pol%'
AND dim_detail_core_details.referral_reason LIKE 'Dispute%'


UNION


SELECT date_opened_case_management AS [Date Case Opened]
		, date_closed_case_management AS [Date Case Closed]
		, RTRIM(dim_matter_header_current.master_client_code)+'-'+dim_matter_header_current.master_matter_number AS [Mattersphere Weightmans Reference]
		, matter_description AS [Matter Description]
		, matter_owner_full_name AS [Case Manager]
		, hierarchylevel3hist AS [Department]
		, dim_matter_worktype.work_type_group AS [Matter Type Group]
		, 'NHSR' AS [Client]
		, dim_detail_previous_details.proceedings_issued AS [Proceedings Issued]
		, dim_detail_court.date_proceedings_issued AS [Date Proceedings Issued]
		, dim_detail_core_details.track AS [Track]
		, suspicion_of_fraud AS [Suspicion of Fraud]
		, dim_detail_core_details.referral_reason AS [Referral Reason]
		, credit_hire AS [Credit Hire]
		, incident_date AS [Incident Date]
		, CASE WHEN ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'Irwin Mitchell%' THEN 'Irwin Mitchell LLP'
			WHEN ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'Thompsons%' THEN 'Thompsons LLP'
			WHEN ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'Slater and Gordon%' THEN 'Slater Gordon Solutions Legal'
			WHEN ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'Slater & Gordon%' THEN 'Slater Gordon Solutions Legal'
			WHEN ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) LIKE 'Slater Gordon%' THEN 'Slater Gordon Solutions Legal'
			ELSE ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name) end AS [Claimant's Solicitor]
		, dim_detail_claim.dst_insured_client_name AS [Insured Client Name]
		, dim_agents_involvement.localauthority_name AS [Local Authority]
		, outcome_of_case AS [Outcome of Case]
		, dim_detail_outcome.[repudiation_outcome] [Repudiation - outcome]
		, dim_detail_court.court_location AS [Court]
		, date_claim_concluded AS [Date Claim Concluded]
		, damages_paid AS [Damages Paid by Client]
		, date_costs_settled AS [Date Costs Settled]
		, total_tp_costs_paid AS [Total Third Party Costs Paid]
		, fact_detail_claim.[claimant_sols_total_costs_sols_claimed] AS [Costs Claimed]
		, ISNULL(fact_finance_summary.damages_paid,0) + ISNULL(fact_finance_summary.total_tp_costs_paid,0) + ISNULL(fact_finance_summary.total_amount_billed,0) AS [Total Claim Spend]
		, CASE WHEN fact_finance_summary.damages_paid IS NULL OR fact_finance_summary.total_tp_costs_paid IS NULL THEN NULL ELSE ISNULL(damages_paid,0)-ISNULL(total_tp_costs_paid,0) END AS [Damages - Costs Paid]
		, DATEDIFF(DAY, incident_date, dim_detail_court.date_proceedings_issued) AS [Days to Issue]
		, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded) AS [Elapsed Days (Damages)]
		, DATEDIFF(DAY, dim_detail_core_details.incident_date, dim_detail_core_details.date_instructions_received) AS [Elapsed Days to Instructions]
		, 1 AS [Number of Records]
		, CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2018-01-01' THEN 0
			WHEN date_claim_concluded<'2018-01-01'  THEN 0
			ELSE 1 END AS [Date Filter]
		, dim_detail_core_details.covid_reason_desc AS [Covid Reason]
		, fact_finance_summary.damages_reserve AS [Damages Reserve]

, CASE WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) = 0 THEN '£0'


 WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) BETWEEN 1 AND 50000 THEN '£1-£50,000'


 WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) BETWEEN 50001 AND 250000 THEN '£50,001-£250,000'

 WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) BETWEEN 500001 AND 1000000 THEN '£500,001-£1,000,000'

 WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) > 1000000 THEN '£1,000,001+'





WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) = 0 THEN '£0'



 

WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)BETWEEN 1 AND 5001 THEN '£1-£5,001'


  

WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)BETWEEN 5001 AND 10000 THEN '£5,001-£10,000'

 WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)BETWEEN 10001 AND 25000 THEN '£10,0001-£25,0001'

  WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)BETWEEN 25001 AND 50001 THEN '£25,001-£50,001'

   WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND coalesce(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)> 50001 THEN '£50,0001+'


 END AS [Damages Banding]

		, dim_matter_worktype.work_type_name AS [Matter Type]
		, CASE WHEN dim_detail_health.nhs_scheme IN ('CNSGP','CNST','DH CL','ELS','ELSGP','ELSGP (MDDUS)','ELSGP (MPS)','Inquest Funding                                             ','Inquest funding') THEN 'Clinical'
                WHEN dim_detail_health.nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'Risk'
	     END AS [Scheme]
		, DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, ISNULL(dim_detail_outcome.date_claim_concluded, dim_matter_header_current.date_closed_case_management)) AS [Lifecycle (date opened to date concluded)]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_previous_details
ON dim_detail_previous_details.dim_detail_previous_details_key = fact_dimension_main.dim_detail_previous_details_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_department
ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT OUTER JOIN red_dw.dbo.dim_agents_involvement
ON dim_agents_involvement.dim_agents_involvement_key = fact_dimension_main.dim_agents_involvement_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key

WHERE hierarchylevel2hist='Legal Ops - Claims'
--AND hierarchylevel3hist IN ('Motor','Large Loss','Casualty','Disease')
AND work_type_group IN ('PL All','EL','NHSLA')
AND CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2018-01-01' THEN 0
			WHEN date_claim_concluded<'2018-01-01'  THEN 0
			ELSE 1 END=1
AND reporting_exclusions=0
AND NOT (LOWER(RTRIM(ISNULL(outcome_of_case,''))) IN ('exclude from reports','returned to client'))
AND client_group_name='NHS Resolution'
AND NOT dim_matter_worktype.work_type_name LIKE 'PL - Pol%'
AND dim_detail_core_details.referral_reason LIKE 'Dispute%'

END
GO
