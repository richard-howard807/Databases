SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Max Taylor
-- Create date: 2021-03-30
-- Ticket:		#92483
-- Description:	Initial Create 
-- =============================================
CREATE PROCEDURE [dbo].[Fraud_FraudListingReport]

(
 @OpenClosed AS VARCHAR(10),
 @worktypegroup AS VARCHAR(MAX), 
 @clientgroup AS VARCHAR(MAX) , 
 @department AS VARCHAR(MAX) 
)

AS 

DROP TABLE IF EXISTS #worktypegroup
DROP TABLE IF EXISTS #clientgroup
DROP TABLE IF EXISTS #Department 

--Testing
--DECLARE @OpenClosed AS VARCHAR(10) = 'Closed',
--@worktypegroup AS VARCHAR(MAX) = 'Disease', 
--@clientgroup AS VARCHAR(MAX) = 'pwc', 
--@department AS VARCHAR(MAX) = ''

SELECT udt_TallySplit.ListValue  INTO #worktypegroup FROM 	dbo.udt_TallySplit(',', @worktypegroup)
SELECT udt_TallySplit.ListValue  INTO #clientgroup FROM 	dbo.udt_TallySplit(',', @clientgroup)
SELECT udt_TallySplit.ListValue  INTO #Department FROM 	dbo.udt_TallySplit(',', @department)

SELECT 

[Client/Matter Number]	                 = dim_matter_header_current.master_client_code+'/'+ master_matter_number,
[Matter Description]	                 = matter_description,
[Date Opened]		                     = dim_matter_header_current.date_opened_case_management ,
[Financial year opened]                  = (SELECT fin_year FROM red_dw..dim_date WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)),		
[Date Closed]		                     = dim_matter_header_current.date_closed_case_management, 
[Case Manager]		                     = dim_fed_hierarchy_history.[name], 
[Work Type]                              = dim_matter_worktype.[work_type_name], 		
[Insurer Client Ref]  	                 = dim_client_involvement.[insurerclient_reference], 	
[Insured Client Ref]	                 = dim_client_involvement.insuredclient_reference,
[Present position]		                 = dim_detail_core_details.[present_position],
[Referral reason]   	                 = dim_detail_core_details.[referral_reason],
[Proceedings issued?]	                 = dim_detail_core_details.[proceedings_issued],
[Track]	              	                 = dim_detail_core_details.[track],
[Suspicion of fraud?]                    = dim_detail_core_details.[suspicion_of_fraud],
[fraud_type_motor]		                 = dim_detail_fraud.[fraud_type_motor],
[fraud_type_casualty]                    = dim_detail_fraud.[fraud_type_casualty],
[fraud_type_disease]	                 = dim_detail_fraud.[fraud_type_disease],
[Fee Arrangement]                        = fact_detail_paid_detail.[output_wip_contingent_wip],
[Incident date] 	                     = dim_detail_core_details.[incident_date],
[Injury Type]	                         = dim_detail_core_details.[injury_type],
[Claimant Solicitor]                     = dim_detail_claim.[dst_claimant_solicitor_firm],
[Damages Reserve (gross)]                = fact_finance_summary.[damages_reserve],
[Claimant's Costs Reserve (gross)]	     = fact_detail_reserve_detail.[current_indemnity_reserve],
[Defence Costs Reserve (gross)]	    	 = fact_finance_summary.[defence_costs_reserve],
[Outcome]	                             = dim_detail_outcome.[outcome_of_case],
[Date Claim Concluded]	                 = dim_detail_outcome.[date_claim_concluded],
[Damages Paid by Client]                 = fact_finance_summary.[damages_paid],
[Date Costs Settled]                     = dim_detail_outcome.date_costs_settled,
[Claimant's Costs Paid by Client]	     = fact_finance_summary.[claimants_costs_paid],
[Detailed Assessment Costs Paid]		 = fact_finance_summary.[detailed_assessment_costs_paid],
[Costs Paid to Other Defendant]		     = fact_finance_summary.[other_defendants_costs_paid],
[Total Recovery]		                 = fact_finance_summary.[total_recovery],
[Total Billed]		                     = fact_bill_detail_summary.bill_total,
[Revenue]		                         = fact_finance_summary.[defence_costs_billed],
[Disbursements Billed]		             = fact_bill_detail_summary.disbursements_billed_exc_vat,
[VAT]		                             = fact_finance_summary.vat_billed,
[Date of Last Bill]		                 = fact_bill_matter.last_bill_date,
[WIP]		                             = fact_finance_summary.wip ,
[Unbilled Disbursements]		         = fact_finance_summary.disbursement_balance,
[Open/Closed]                            = CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END,
[Work Type Group]                        = work_type_group, 
[Client Group Name]                      = dim_client.client_group_name,
[Department]                             = hierarchylevel3hist

FROM red_dw.dbo.fact_dimension_main
JOIN red_dw.dbo.dim_matter_header_current	
	ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
	ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
JOIN red_dw.dbo.dim_matter_worktype
	ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
JOIN red_dw.dbo.dim_client_involvement
	ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
JOIN red_dw.dbo.dim_detail_core_details 
	ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
JOIN red_dw.dbo.dim_detail_fraud
	ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
JOIN red_dw.dbo.fact_finance_summary 
	ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
JOIN red_dw.dbo.fact_detail_paid_detail
	ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
JOIN red_dw.dbo.dim_detail_claim
	ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
JOIN red_dw.dbo.dim_detail_outcome
	ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
JOIN red_dw.dbo.fact_detail_reserve_detail
	ON fact_detail_reserve_detail.master_fact_key = fact_detail_paid_detail.master_fact_key
JOIN red_dw.dbo.fact_bill_detail_summary
	ON fact_bill_detail_summary.master_fact_key = fact_detail_paid_detail.master_fact_key
JOIN red_dw.dbo.fact_bill_matter
	ON fact_bill_matter.master_fact_key = fact_bill_detail_summary.master_fact_key
JOIN red_dw.dbo.dim_client
	ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
JOIN #clientgroup
	ON RTRIM(#clientgroup.ListValue) COLLATE DATABASE_DEFAULT = RTRIM(dim_client.client_group_name)
JOIN #worktypegroup 
	ON RTRIM(#worktypegroup.ListValue) COLLATE DATABASE_DEFAULT = RTRIM(work_type_group)
JOIN #Department 
	ON RTRIM(#Department.ListValue) COLLATE DATABASE_DEFAULT = RTRIM(hierarchylevel3hist)


  

WHERE 1 =1 
AND dim_detail_core_details.[suspicion_of_fraud] = 'Yes'
AND (dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management >'2019-05-01') --  open or closed after 1 May 2019 

/*Filters via Parameters*/
--Open/Closed/All 
AND @OpenClosed = CASE WHEN @OpenClosed = 'All' THEN 'All' ELSE  CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END END




ORDER BY dim_matter_header_current.client_code, dim_matter_header_current.matter_number
GO
