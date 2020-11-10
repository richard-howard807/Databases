SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-08-10
-- Description:	#67543, Zurich round table data for dashboard and report 
-- =============================================
-- 20201106 ES #78099, added claimant representative to claimant sols logic
-- =============================================
CREATE PROCEDURE [zurich].[RoundTableData]
	
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
		, work_type_name AS [Claim Type]
		, 'All' AS [Client]
		, dim_detail_previous_details.proceedings_issued AS [Proceedings Issued]
		, dim_detail_court.date_proceedings_issued AS [Date Proceedings Issued]
		, dim_detail_core_details.track AS [Track]
		, suspicion_of_fraud AS [Suspicion of Fraud]
		, credit_hire AS [Credit Hire]
		, incident_date AS [Incident Date]
		, ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantrep_name) AS [Claimant's Solicitor]
		, outcome_of_case AS [Outcome of Case]
		, date_claim_concluded AS [Date Claim Concluded]
		, damages_paid AS [Damages Paid by Client]
		, date_costs_settled AS [Date Costs Settled]
		, total_tp_costs_paid AS [Total Third Party Costs Paid]
		, DATEDIFF(DAY, incident_date, dim_detail_court.date_proceedings_issued) AS [Days to Issue]
		, CASE WHEN dim_detail_health.nhs_scheme IN ('CNST','ELS','DH CL') THEN 'Clinical'
                WHEN dim_detail_health.nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'Risk'
	     END AS [NHS Scheme]
		, 1 AS [Number of Records]
		, CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2017-01-01' THEN 0
			WHEN date_claim_concluded<'2017-01-01'  THEN 0
			ELSE 1 END AS [Date Filter]

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

WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel3hist IN ('Motor','Large Loss','Casualty','Disease')
AND CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2017-01-01' THEN 0
			WHEN date_claim_concluded<'2017-01-01'  THEN 0
			ELSE 1 END=1
AND reporting_exclusions=0
AND NOT (LOWER(RTRIM(ISNULL(outcome_of_case,''))) IN ('exclude from reports','returned to client'))

UNION

SELECT date_opened_case_management AS [Date Case Opened]
		, date_closed_case_management AS [Date Case Closed]
		, RTRIM(dim_matter_header_current.master_client_code)+'-'+dim_matter_header_current.master_matter_number AS [Mattersphere Weightmans Reference]
		, matter_description AS [Matter Description]
		, matter_owner_full_name AS [Case Manager]
		, CASE WHEN hierarchylevel3hist='Casualty' AND work_type_name LIKE 'PL - Pol% ' OR work_type_name LIKE '%Police%' THEN 'Police'
			WHEN hierarchylevel3hist='Casualty' THEN 'Casualty and Local Gov'
			ELSE hierarchylevel3hist END AS [Department]
		, work_type_name AS [Claim Type]
		, 'Zurich' AS [Client]
		, dim_detail_previous_details.proceedings_issued AS [Proceedings Issued]
		, dim_detail_court.date_proceedings_issued AS [Date Proceedings Issued]
		, dim_detail_core_details.track AS [Track]
		, suspicion_of_fraud AS [Suspicion of Fraud]
		, credit_hire AS [Credit Hire]
		, incident_date AS [Incident Date]
		, ISNULL(dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantrep_name) AS [Claimant's Solicitor]
		, outcome_of_case AS [Outcome of Case]
		, date_claim_concluded AS [Date Claim Concluded]
		, damages_paid AS [Damages Paid by Client]
		, date_costs_settled AS [Date Costs Settled]
		, total_tp_costs_paid AS [Total Third Party Costs Paid]
		, DATEDIFF(DAY, incident_date, dim_detail_court.date_proceedings_issued) AS [Days to Issue]
		, CASE WHEN dim_detail_health.nhs_scheme IN ('CNST','ELS','DH CL') THEN 'Clinical'
                WHEN dim_detail_health.nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'Risk'
	     END AS [NHS Scheme]
		, 1 AS [Number of Records]
		, CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2017-01-01' THEN 0
			WHEN date_claim_concluded<'2017-01-01'  THEN 0
			ELSE 1 END AS [Date Filter]

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

WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel3hist IN ('Motor','Large Loss','Casualty','Disease')
AND CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2017-01-01' THEN 0
			WHEN date_claim_concluded<'2017-01-01'  THEN 0
			ELSE 1 END=1
AND reporting_exclusions=0
AND NOT (LOWER(RTRIM(ISNULL(outcome_of_case,''))) IN ('exclude from reports','returned to client'))
AND client_group_name='Zurich'

END
GO
