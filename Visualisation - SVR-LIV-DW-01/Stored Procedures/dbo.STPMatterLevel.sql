SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-09-28
-- Description:	#156744, new data source at matter level for see the possibilty dashboard
-- =============================================
CREATE PROCEDURE [dbo].[STPMatterLevel] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [MS Client/Matter Reference]
	,COALESCE(dim_matter_header_current.client_group_name, dim_matter_header_current.client_name) AS [Client Group/Client Name]
	,dim_matter_header_current.matter_owner_full_name AS [Case Manager]
	,dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	,dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
	,dim_matter_header_current.date_opened_case_management AS [Date Opened]
	,dim_matter_header_current.date_closed_case_management AS [Date Closed]
	,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
	,dim_matter_worktype.work_type_name AS [Matter Type]
	,dim_matter_worktype.work_type_group AS [Matter Group]
	,dim_detail_core_details.[present_position] AS [Present Position]
	,dim_detail_core_details.[track] AS [Track]
	,fact_finance_summary.[damages_reserve] AS [Damages Reserve]
	,dim_detail_core_details.[do_clients_require_an_initial_report] AS [Do clients require an initial report?]
	,dim_detail_core_details.[date_initial_report_sent] AS [Date of initial report]
	,dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers] AS [Date of receipt of client's file of papers]
	,dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report] AS [Extension for initial report]
	,dim_detail_core_details.[date_initial_report_due] AS [Date initial report due]
	,dim_detail_core_details.[date_subsequent_sla_report_sent] AS [Date of subsequent report (penultimate entry)]
	,dim_detail_outcome.[ll00_settlement_basis] AS [Date of subsequent report (most recent entry)]
	,dim_detail_core_details.[date_the_closure_report_sent] AS [Date of closure report]
	,dim_detail_claim.[axa_claim_strategy] AS [Claims strategy]
	,NULL AS [Date claims strategy MI field completed]
	,dim_detail_core_details.[anticipated_settlement_date] AS [Anticipated settlement date]
	,dim_detail_outcome.[outcome_of_case] AS [Outcome]
	,NULL AS [Date outcome MI field completed]
	,dim_detail_outcome.[reason_for_settlement] AS [Reason for settlement]
	,NULL AS [Reason for successful outcome]
	,fact_finance_summary.[damages_paid] AS [Damages Paid]
	,fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] AS [Damages Paid (100%)]
	,fact_finance_summary.[tp_total_costs_claimed] AS [Claimant's Costs Claimed]
	,fact_detail_paid_detail.[tp_total_costs_claimed_all_parties] AS [Claimant's Costs Claimed (100%)]
	,fact_finance_summary.[claimants_costs_paid] AS [Claimant's Costs Paid]
	,fact_finance_summary.[claimants_total_costs_paid_by_all_parties] AS [Claimant's Costs Paid (100%)]
	,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
	,NULL AS [Total Billed exc. VAT]
	,NULL AS [Last bill date (MS) (include composite)]
	,NULL AS [No. of red entries in MS action list]
	,NULL AS [No. of red entries in MS action list over 5 days old]
 
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'') <>'Exclude from reports'
AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'

END
GO
