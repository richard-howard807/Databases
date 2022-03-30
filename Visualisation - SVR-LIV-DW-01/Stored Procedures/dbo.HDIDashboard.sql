SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--USE Visualisation  
/*  
=============================================  
Author:   Julie Loughlin  
Create date: 2022-03-21  
Description: HDI report to drive the HDI dashboard
=============================================  
*/  
  
CREATE PROCEDURE [dbo].[HDIDashboard]  
AS  
  
BEGIN  
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
SET NOCOUNT ON;  
  
SELECT   
 dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number AS [Client/Matter Number]  
 , dim_matter_header_current.matter_description  AS [Matter Description]  
 , CONVERT(DATE, dim_matter_header_current.date_opened_practice_management, 103)  AS [Date Opened]  
 , CONVERT(DATE, dim_matter_header_current.date_closed_practice_management, 103)  AS [Date Closed] 
 , dim_detail_core_details.present_position  AS [Present Position]
 , dim_detail_core_details.referral_reason  AS [Referral Reason] 
 , dim_fed_hierarchy_history.name   AS [Case Manager]  
 , dim_matter_worktype.work_type_name   AS [Work Type]  
 , dim_client_involvement.insurerclient_reference  AS [Insurer Client Ref]  
 , dim_client_involvement.insuredclient_name   AS [Insured]  
 , dim_client_involvement.insuredclient_reference  AS [Insured Client Ref]  
 , dim_detail_core_details.proceedings_issued  AS [Proceedings Issued]  
 , CONVERT(DATE, dim_detail_core_details.incident_date, 103)  AS [Incident Date]  
 , dim_detail_claim.dst_claimant_solicitor_firm  AS [Claimant Solicitor]  
 , fact_detail_reserve_detail.damages_reserve   AS [Damages Reserve (Gross)]  
 , fact_detail_reserve_detail.claimant_costs_reserve_current AS [Claimant's Costs Reserve (Gross)]  
 , fact_finance_summary.defence_costs_reserve   AS [Defence Costs Reserve (Gross)]  
 , fact_detail_reserve_detail.other_defendants_costs_reserve  AS [Other Defendants Costs Reserve (Gross)]  
 , dim_detail_outcome.outcome_of_case   AS [Outcome]  
 , CONVERT(DATE, dim_detail_outcome.date_claim_concluded, 103)  AS [Date Claim Concluded]  
, fact_finance_summary.damages_paid   AS [Damages Paid by Client]  
 , CONVERT(DATE, dim_detail_outcome.date_costs_settled, 103)  AS [Date Costs Settled]  
 , fact_finance_summary.claimants_costs_paid   AS [Claimant's Costs Paid by Client]  
 , fact_finance_summary.total_amount_billed   AS [Total Billed]  
 , fact_finance_summary.defence_costs_billed   AS [Revenue]  
 , fact_finance_summary.disbursements_billed  AS [Disbursements Billed]  
 --, fact_finance_summary.vat_billed   AS [VAT]  
 , CONVERT(DATE, fact_bill_matter.last_bill_date, 103)  AS [Date of Last Bill]
 , work_type_group
 , hierarchylevel4hist as [Team]
 , hierarchylevel3hist as Department
 , hierarchylevel2hist as Division
 , dim_detail_core_details.date_instructions_received
 ,dim_detail_outcome.outcome_of_case

 
FROM red_dw.dbo.fact_dimension_main   
 INNER JOIN red_dw.dbo.dim_matter_header_current  
  ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
  
 LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype  
  ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
  
 INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  
  ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
  
 LEFT OUTER JOIN red_dw.dbo.dim_client_involvement  
  ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
  
 LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details  
  ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
  
 LEFT OUTER JOIN red_dw.dbo.dim_detail_claim  
  ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
  
 LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome  
  ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
  
 LEFT OUTER JOIN red_dw.dbo.fact_finance_summary  
  ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
  
 LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail  
  ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
  
 LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail  
  ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
  
 LEFT OUTER JOIN red_dw.dbo.fact_bill_matter  
  ON fact_bill_matter.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key


  

WHERE
 dim_matter_header_current.client_code = '00001328'  
 AND dim_matter_header_current.reporting_exclusions = 0  
 AND  ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from Reports'
AND dim_matter_header_current.matter_number <> 'ML'
END   
GO
