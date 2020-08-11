SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-08-10
-- Description:	#67543, Zurich round table data for dashboard and report 
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
		, hierarchylevel3hist AS [Department]
		, CASE WHEN client_group_name='Zurich' THEN 'Zurich' ELSE 'All' END AS [Client]
		, dim_detail_previous_details.proceedings_issued AS [Proceedings Issued]
		, dim_detail_court.date_proceedings_issued AS [Date Proceedings Issued]
		, dim_detail_core_details.track AS [Track]
		, suspicion_of_fraud AS [Suspicion of Fraud]
		, incident_date AS [Incident Date]
		, dst_claimant_solicitor_firm AS [Claimant's Solicitor]
		, outcome_of_case AS [Outcome of Case]
		, date_claim_concluded AS [Date Claim Concluded]
		, damages_paid AS [Damages Paid by Client]
		, date_costs_settled AS [Date Costs Settled]
		, total_tp_costs_paid AS [Total Third Party Costs Paid]
		, DATEDIFF(DAY, incident_date, dim_detail_court.date_proceedings_issued) AS [Days to Issue]
		, 1 AS [Number of Records]

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

WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel3hist IN ('Motor','Large Loss','Casualty','Disease')
AND date_opened_case_management>='2017-01-01'
AND reporting_exclusions=0
AND NOT (LOWER(RTRIM(ISNULL(outcome_of_case,''))) IN ('exclude from reports','returned to client'))

END
GO
