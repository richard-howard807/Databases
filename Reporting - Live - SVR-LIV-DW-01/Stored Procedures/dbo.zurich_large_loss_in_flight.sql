SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*  
=============================================  
Author:   Jamie Bonner  
Create date: 2021-03-19  
Description: #92731 Zurich Large Loss report to review in flight matters  
Update : 93105 - Added large_loss_hundred_perc_current_dam_res_total as per below 
=============================================  
*/  
  
CREATE PROCEDURE [dbo].[zurich_large_loss_in_flight]  
AS  
  
BEGIN  
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
SET NOCOUNT ON;  
  
SELECT   
 dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number AS [Client/Matter Number]  
 , dim_matter_header_current.matter_description  AS [Matter Description]  
 , CONVERT(DATE, dim_matter_header_current.date_opened_practice_management, 103)  AS [Date Opened]  
 , CONVERT(DATE, dim_matter_header_current.date_closed_practice_management, 103)  AS [Date Closed]  
 , dim_fed_hierarchy_history.name   AS [Case Manager]  
 , dim_matter_worktype.work_type_name   AS [Work Type]  
 , dim_client_involvement.insurerclient_name   AS [Insurer]  
 , dim_client_involvement.insurerclient_reference  AS [Insurer Client Ref]  
 , dim_client_involvement.insuredclient_name   AS [Insured]  
 , dim_client_involvement.insuredclient_reference  AS [Insured Client Ref]  
 , dim_detail_core_details.present_position  AS [Present Position]  
 , dim_detail_core_details.referral_reason  AS [Referral Reason]  
 , dim_detail_core_details.proceedings_issued  AS [Proceedings Issued]  
 , CONVERT(DATE, dim_detail_core_details.incident_date, 103)  AS [Incident Date]  
 , dim_detail_core_details.injury_type_code + ' - ' + dim_detail_core_details.injury_type   AS [Injury Type]  
 , dim_detail_claim.dst_claimant_solicitor_firm  AS [Claimant Solicitor]  
 , large_loss_hundred_perc_current_dam_res_total    AS [100% Reserve Value]  --Swapped out fact_detail_reserve_detail.large_loss_hundred_perc_reserve_total -MT 20210323
 , fact_detail_reserve_detail.damages_reserve   AS [Damages Reserve (Gross)]  
 , fact_detail_reserve_detail.current_indemnity_reserve AS [Claimant's Costs Reserve (Gross)]  
 , fact_finance_summary.defence_costs_reserve   AS [Defence Costs Reserve (Gross)]  
 , fact_detail_reserve_detail.other_defendants_costs_reserve  AS [Other Defendants Costs Reserve (Gross)]  
 , dim_detail_outcome.outcome_of_case   AS [Outcome]  
 , CONVERT(DATE, dim_detail_outcome.date_claim_concluded, 103)  AS [Date Claim Concluded]  
 , fact_finance_summary.damages_interims    AS [Interim Damages Paid (Post Instruction)]  
 , fact_finance_summary.damages_paid   AS [Damages Paid by Client]  
 , CONVERT(DATE, dim_detail_outcome.date_costs_settled, 103)  AS [Date Costs Settled]  
 , fact_detail_paid_detail.interim_costs_payments   AS [Interim Claimant's Costs Paid (Post Instruction)]  
 , fact_finance_summary.claimants_costs_paid   AS [Claimant's Costs Paid by Client]  
 , fact_finance_summary.detailed_assessment_costs_paid  AS [Detailed Assessment Costs Paid]  
 , fact_finance_summary.other_defendants_costs_paid  AS [Costs Paid to Other Defendant]  
 , fact_finance_summary.total_amount_billed   AS [Total Billed]  
 , fact_finance_summary.defence_costs_billed   AS [Revenue]  
 , fact_finance_summary.disbursements_billed  AS [Disbursements Billed]  
 , fact_finance_summary.vat_billed   AS [VAT]  
 , CONVERT(DATE, fact_bill_matter.last_bill_date, 103)  AS [Date of Last Bill]   
 , fact_finance_summary.wip  
 , fact_finance_summary.disbursement_balance   AS [Unbilled Disbursements]  
 
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
WHERE 1 = 1  
 AND dim_matter_header_current.master_client_code = 'Z1001'  
 AND dim_matter_header_current.reporting_exclusions = 0  
 AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Large Loss'  
 AND (LTRIM(RTRIM(LOWER(dim_detail_core_details.present_position))) = 'claim and costs outstanding' OR  
  LTRIM(RTRIM(LOWER(dim_detail_core_details.present_position))) = 'claim concluded but costs outstanding')  
 AND fact_detail_reserve_detail.large_loss_hundred_perc_reserve_total >= 1000000  
  
END   
GO
