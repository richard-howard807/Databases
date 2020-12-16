SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-12-09
-- Description:	#81365, Zurich insights dashboard, claimant behaviour
-- =============================================

-- =============================================
CREATE PROCEDURE [zurich].[ZurichInsights]
	
AS
BEGIN

	SET NOCOUNT ON;

SELECT date_opened_case_management AS [Date Case Opened]
		, date_closed_case_management AS [Date Case Closed]
		, RTRIM(dim_matter_header_current.master_client_code)+'-'+dim_matter_header_current.master_matter_number AS [Mattersphere Weightmans Reference]
		, matter_description AS [Matter Description]
		, matter_owner_full_name AS [Case Manager]
		, CASE WHEN hierarchylevel3hist='Casualty' AND work_type_name LIKE 'PL - Pol% ' OR work_type_name LIKE '%Police%' THEN 'Police'
			WHEN hierarchylevel3hist='Casualty' THEN 'Casualty and Local Gov'
			ELSE hierarchylevel3hist END AS [Department]
		, dim_matter_worktype.work_type_group AS [Matter Type Group]
		, 'All' AS [Client]
		, dim_detail_previous_details.proceedings_issued AS [Proceedings Issued]
		, dim_detail_court.date_proceedings_issued AS [Date Proceedings Issued]
		, dim_detail_core_details.track AS [Track]
		, suspicion_of_fraud AS [Suspicion of Fraud]
		, credit_hire AS [Credit Hire]
		, incident_date AS [Incident Date]
		, ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantrep_name) AS [Claimant's Solicitor]
		, dim_detail_claim.dst_insured_client_name AS [Insured Client Name]
		, dim_agents_involvement.localauthority_name AS [Local Authority]
		, outcome_of_case AS [Outcome of Case]
		, dim_detail_outcome.[repudiation_outcome] [Repudiation - outcome]
		, dim_detail_court.court_location AS [Court]
		, date_claim_concluded AS [Date Claim Concluded]
		, damages_paid AS [Damages Paid by Client]
		, date_costs_settled AS [Date Costs Settled]
		, total_tp_costs_paid AS [Total Third Party Costs Paid]
		, CASE WHEN fact_finance_summary.damages_paid IS NULL OR fact_finance_summary.total_tp_costs_paid IS NULL THEN NULL ELSE ISNULL(damages_paid,0)-ISNULL(total_tp_costs_paid,0) END AS [Damages - Costs Paid]
		, DATEDIFF(DAY, incident_date, dim_detail_court.date_proceedings_issued) AS [Days to Issue]
		, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded) AS [Elapsed Days (Damages)]
		, DATEDIFF(DAY, dim_detail_core_details.incident_date, dim_detail_core_details.date_instructions_received) AS [Elapsed Days to Instructions]
		, CASE WHEN dim_detail_health.nhs_scheme IN ('CNST','ELS','DH CL') THEN 'Clinical'
                WHEN dim_detail_health.nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'Risk'
	     END AS [NHS Scheme]
		, 1 AS [Number of Records]
		, CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2018-01-01' THEN 0
			WHEN date_claim_concluded<'2018-01-01'  THEN 0
			ELSE 1 END AS [Date Filter]
		, dim_detail_core_details.covid_reason_desc AS [Covid Reason]
		, CASE WHEN dim_detail_core_details.[zurich_is_the_instruction_a_customer_nomination]='Yes' THEN 'Y'
			 WHEN dim_detail_core_details.[zurich_is_the_instruction_a_customer_nomination]='No' THEN 'N' 
			 ELSE dim_detail_core_details.[zurich_is_the_instruction_a_customer_nomination] END AS [Nomination]
		, CASE WHEN fact_finance_summary.damages_paid BETWEEN 0 AND 25000 THEN '0-25,000'
			WHEN fact_finance_summary.damages_paid BETWEEN 25000 AND 50000 THEN '25,000-50,000'
			WHEN fact_finance_summary.damages_paid BETWEEN 50000 AND 100000 THEN '50,000-100,000'
			WHEN fact_finance_summary.damages_paid > 100000 THEN '100,000+'
			END AS [Damages Banding]
		, dim_matter_worktype.work_type_name AS [Matter Type]
		, CASE WHEN dim_matter_worktype.work_type_name LIKE 'EL - Manual Handling%' THEN 'EL - Manual Handling'
			WHEN dim_matter_worktype.work_type_name LIKE 'EL - Assault%' THEN 'EL - Assault'
			WHEN dim_matter_worktype.work_type_name LIKE 'EL -%' THEN 'EL - Other'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - Hways%' THEN 'PL - Hways'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - SS%' THEN 'PL - SS'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - School%' THEN 'PL - School'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - Care Homes%' THEN 'PL - Care Homes'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - Education%' THEN 'PL - Education'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - OL%' THEN 'PL - OL'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - Housing%' THEN 'PL - Housing'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - %' THEN 'PL - Other'
			WHEN dim_matter_worktype.work_type_name LIKE 'PPO Administration%' THEN 'PL - Other'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - Prop Damage%' THEN 'PL - Prop Damage'
			WHEN dim_matter_worktype.work_type_name LIKE 'OI -%' THEN 'OI'
			WHEN dim_matter_worktype.work_type_name LIKE 'Motor - %' THEN 'Motor'
			ELSE 'Other' END AS [Claim Type]

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

WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel3hist IN ('Motor','Large Loss','Casualty','Disease')
AND CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2018-01-01' THEN 0
			WHEN date_claim_concluded<'2018-01-01'  THEN 0
			ELSE 1 END=1
AND reporting_exclusions=0
AND NOT (LOWER(RTRIM(ISNULL(outcome_of_case,''))) IN ('exclude from reports','returned to client'))
AND dim_matter_header_current.client_group_name <> 'MIB'
--AND client_group_name<>'Zurich'


UNION

SELECT date_opened_case_management AS [Date Case Opened]
		, date_closed_case_management AS [Date Case Closed]
		, RTRIM(dim_matter_header_current.master_client_code)+'-'+dim_matter_header_current.master_matter_number AS [Mattersphere Weightmans Reference]
		, matter_description AS [Matter Description]
		, matter_owner_full_name AS [Case Manager]
		, CASE WHEN hierarchylevel3hist='Casualty' AND work_type_name LIKE 'PL - Pol% ' OR work_type_name LIKE '%Police%' THEN 'Police'
			WHEN hierarchylevel3hist='Casualty' THEN 'Casualty and Local Gov'
			ELSE hierarchylevel3hist END AS [Department]
		, dim_matter_worktype.work_type_group AS [Matter Type Group]
		, 'Zurich' AS [Client]
		, dim_detail_previous_details.proceedings_issued AS [Proceedings Issued]
		, dim_detail_court.date_proceedings_issued AS [Date Proceedings Issued]
		, dim_detail_core_details.track AS [Track]
		, suspicion_of_fraud AS [Suspicion of Fraud]
		, credit_hire AS [Credit Hire]
		, incident_date AS [Incident Date]
		, ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantrep_name) AS [Claimant's Solicitor]
		, dim_detail_claim.dst_insured_client_name AS [Insured Client Name]
		, dim_agents_involvement.localauthority_name AS [Local Authority]
		, outcome_of_case AS [Outcome of Case]
		, dim_detail_outcome.[repudiation_outcome] [Repudiation - outcome]
		, dim_detail_court.court_location AS [Court]
		, date_claim_concluded AS [Date Claim Concluded]
		, damages_paid AS [Damages Paid by Client]
		, date_costs_settled AS [Date Costs Settled]
		, total_tp_costs_paid AS [Total Third Party Costs Paid]
		, CASE WHEN fact_finance_summary.damages_paid IS NULL OR fact_finance_summary.total_tp_costs_paid IS NULL THEN NULL ELSE ISNULL(damages_paid,0)-ISNULL(total_tp_costs_paid,0) END AS [Damages - Costs Paid]
		, DATEDIFF(DAY, incident_date, dim_detail_court.date_proceedings_issued) AS [Days to Issue]
		, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded) AS [Elapsed Days (Damages)]
		, DATEDIFF(DAY, dim_detail_core_details.incident_date, dim_detail_core_details.date_instructions_received) AS [Elapsed Days to Instructions]
		, CASE WHEN dim_detail_health.nhs_scheme IN ('CNST','ELS','DH CL') THEN 'Clinical'
                WHEN dim_detail_health.nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'Risk'
	     END AS [NHS Scheme]
		, 1 AS [Number of Records]
		, CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2018-01-01' THEN 0
			WHEN date_claim_concluded<'2018-01-01'  THEN 0
			ELSE 1 END AS [Date Filter]
		, dim_detail_core_details.covid_reason_desc AS [Covid Reason]
		, CASE WHEN dim_detail_core_details.[zurich_is_the_instruction_a_customer_nomination]='Yes' THEN 'Y'
			 WHEN dim_detail_core_details.[zurich_is_the_instruction_a_customer_nomination]='No' THEN 'N' 
			 ELSE dim_detail_core_details.[zurich_is_the_instruction_a_customer_nomination] END AS [Nomination]
		, CASE WHEN fact_finance_summary.damages_paid BETWEEN 0 AND 25000 THEN '0-25,000'
			WHEN fact_finance_summary.damages_paid BETWEEN 25000 AND 50000 THEN '25,000-50,000'
			WHEN fact_finance_summary.damages_paid BETWEEN 50000 AND 100000 THEN '50,000-100,000'
			WHEN fact_finance_summary.damages_paid > 100000 THEN '100,000+'
			END AS [Damages Banding]
		, dim_matter_worktype.work_type_name AS [Matter Type]
		, CASE WHEN dim_matter_worktype.work_type_name LIKE 'EL - Manual Handling%' THEN 'EL - Manual Handling'
			WHEN dim_matter_worktype.work_type_name LIKE 'EL - Assault%' THEN 'EL - Assault'
			WHEN dim_matter_worktype.work_type_name LIKE 'EL -%' THEN 'EL - Other'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - Hways%' THEN 'PL - Hways'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - SS%' THEN 'PL - SS'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - School%' THEN 'PL - School'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - Care Homes%' THEN 'PL - Care Homes'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - Education%' THEN 'PL - Education'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - OL%' THEN 'PL - OL'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - Housing%' THEN 'PL - Housing'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - %' THEN 'PL - Other'
			WHEN dim_matter_worktype.work_type_name LIKE 'PPO Administration%' THEN 'PL - Other'
			WHEN dim_matter_worktype.work_type_name LIKE 'PL - Prop Damage%' THEN 'PL - Prop Damage'
			WHEN dim_matter_worktype.work_type_name LIKE 'OI -%' THEN 'OI'
			WHEN dim_matter_worktype.work_type_name LIKE 'Motor - %' THEN 'Motor'
			ELSE 'Other' END AS [Claim Type]

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

WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel3hist IN ('Motor','Large Loss','Casualty','Disease')
AND CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2018-01-01' THEN 0
			WHEN date_claim_concluded<'2018-01-01'  THEN 0
			ELSE 1 END=1
AND reporting_exclusions=0
AND NOT (LOWER(RTRIM(ISNULL(outcome_of_case,''))) IN ('exclude from reports','returned to client'))
AND client_group_name='Zurich'

END
GO
