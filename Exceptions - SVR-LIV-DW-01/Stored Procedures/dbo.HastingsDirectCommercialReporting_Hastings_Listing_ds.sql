SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[HastingsDirectCommercialReporting_Hastings_Listing_ds]

AS

SELECT 

[Supplier Reference]
,[Case Description] = matter_description
,[Supplier Handler]	
,[Hastings Handler] = 	dim_detail_core_details.[clients_claims_handler_surname_forename]
,[Referral Reason] = 	dim_detail_core_details.[referral_reason]
,[Present Position] = 	dim_detail_core_details.[present_position]
,[Claim Status] =	dim_detail_claim.[hastings_claim_status]
,[Litigated] = 	dim_detail_core_details.[proceedings_issued]
,[Date Litigated] = 	dim_detail_court.[date_proceedings_issued]
,[Liability Position] = 	dim_detail_claim.[hastings_liability_position]
,[Fault Rating] = 	dim_detail_claim.[hastings_fault_rating]
,[Fault Liability %] = 	dim_detail_core_details.[hastings_fault_liability_percent]
,[Fundamental Dishonesty] = 	dim_detail_claim.[hastings_fundamental_dishonesty]
,[Damages reserve (current)] =	fact_finance_summary.[damages_reserve]
,[Claimant's cost reserve (current)] = 	fact_detail_reserve_detail.[claimant_costs_reserve_current]
,[Defence cost reserve (current)]   =	fact_finance_summary.[defence_costs_reserve]
,[Target Settlement Date]	= dim_detail_core_details.[target_settlement_date]
,[Date Claim Concluded] = 	dim_detail_outcome.[date_claim_concluded]
,[Date claimant's costs received]	= dim_detail_outcome.[date_claimants_costs_received]
,[Date Costs Settled]	= dim_detail_outcome.[date_costs_settled]



,[Current Damages Reserve DELETE BEFORE SENDING - Update] = 
ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved], 0)

,[Total Settlement - Update] = CASE WHEN 
 dim_detail_outcome.[date_claim_concluded] IS NOT NULL THEN 
ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0) END


,[Damages Settlement Saving £ - Update] =  CASE 

WHEN fact_detail_cost_budgeting.[hastings_claimant_schedule_value] > 0 
AND dim_detail_outcome.[date_claim_concluded] IS NOT NULL
 THEN fact_detail_cost_budgeting.[hastings_claimant_schedule_value] - 
 (
ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
+ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
+ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
+ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
+ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
+ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
)

WHEN ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0) = 0
AND dim_detail_outcome.[date_claim_concluded] IS NOT NULL
THEN NULL
 END

 ,fact_detail_cost_budgeting.[hastings_claimant_schedule_value] 

,[Damages Settlement Saving (percent) - Update] = NULL --
--CASE 
--WHEN fact_detail_cost_budgeting.[hastings_claimant_schedule_value] > 0 
--AND dim_detail_outcome.[date_claim_concluded] IS NOT NULL
-- THEN (ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value],0) - 
-- (
--ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
--+ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
--+ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
--+ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
--+ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
--+ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
--)) 

--WHEN ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0) = 0
--AND dim_detail_outcome.[date_claim_concluded] IS NOT NULL
--THEN 
-- (
--ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
--+ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
--+ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
--+ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
--+ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
--+ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
--)
---
--(
--ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved], 0)
--+ISNULL(fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved], 0)
--+ISNULL(fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved], 0)
--+ISNULL(fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved], 0)
--+ISNULL(fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved], 0)
--+ISNULL(fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved], 0)
--)
-- END  / ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value],0)


,[Total Costs of Claim Presented - Update] = 

CASE WHEN dim_detail_outcome.[date_costs_settled] is NOT NULL	
  AND fact_detail_cost_budgeting.[hastings_claimant_schedule_value] > 0 
  THEN 
  ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0)
  + ISNULL(fact_finance_summary.[tp_total_costs_claimed], 0)
  WHEN dim_detail_outcome.[date_costs_settled] is NOT NULL	
  AND ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0) = 0 
  THEN (
  ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved], 0) 
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved], 0)
+ ISNULL(fact_finance_summary.[tp_total_costs_claimed], 0)
) END

,[Total Claim Costs Savings  £ - Update] =    -- error with underlying value being tbc 
CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL 
     AND fact_detail_cost_budgeting.[hastings_claimant_schedule_value]  > 0 
	     THEN (
ISNULL(CAST(fact_detail_cost_budgeting.[hastings_claimant_schedule_value] AS INT), 0)
+ ISNULL(fact_finance_summary.[tp_total_costs_claimed], 0))

		 - 
 (
  ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
+ ISNULL(fact_finance_summary.[claimants_costs_paid], 0)
)
 WHEN ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0) = 0 
 AND dim_detail_outcome.[date_costs_settled] IS NOT NULL 
 THEN 
 (
ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved], 0)
+ISNULL(fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved], 0)
+ ISNULL(fact_finance_summary.[tp_total_costs_claimed], 0)

) 
-
(
  ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
+ ISNULL(fact_finance_summary.[claimants_costs_paid], 0)
)


END

, [Total Claim Costs Savings (percent) - Update] = NULL --
--CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL 
--     AND fact_detail_cost_budgeting.[hastings_claimant_schedule_value]  > 0 
--	     THEN (
--((ISNULL(CAST(fact_detail_cost_budgeting.[hastings_claimant_schedule_value] AS INT), 0)
--+ ISNULL(fact_finance_summary.[tp_total_costs_claimed], 0)))
-- - 
-- (
--  ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
--+ ISNULL(fact_finance_summary.[claimants_costs_paid], 0)
--)) / (ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value],0)+ISNULL(fact_finance_summary.[tp_total_costs_claimed], 0))

--WHEN ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0) = 0 
-- AND dim_detail_outcome.[date_costs_settled] IS NOT NULL 
-- THEN 
-- ((
--ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved], 0)
--+ISNULL(fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved], 0)
--+ ISNULL(fact_finance_summary.[tp_total_costs_claimed], 0)
--)
---
--(
--  ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
--+ ISNULL(fact_finance_summary.[claimants_costs_paid], 0)
--) ) 
--/ (
--ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved], 0)
--+ISNULL(fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved], 0)
--+ ISNULL(fact_finance_summary.[tp_total_costs_claimed], 0)
--)

--END

,[Total Claim Cost - Update] = 
CASE WHEN dim_detail_client.[hastings_closure_date] IS NOT NULL THEN [Total Claim Cost] END -- Need to check logic

, [Total Claim Savings (money) - Update] = 
CASE WHEN dim_detail_client.[hastings_closure_date]  IS NOT NULL      -- THEN [Total Claim Savings (money)]
     AND  fact_detail_cost_budgeting.[hastings_claimant_schedule_value] > 0 
	 THEN (ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0) 
	    + ISNULL(fact_finance_summary.[tp_total_costs_claimed] ,0) 
		-- + 3e Costs and Billed
		) - 

		(
ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
+ ISNULL(fact_finance_summary.[claimants_costs_paid], 0)
--+ 3E costs and disbs billed
		)

WHEN  ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0) = 0
AND dim_detail_client.[hastings_closure_date]  IS NOT NULL
THEN 
(
ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved], 0)
+ ISNULL(fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved], 0)
+ ISNULL(fact_finance_summary.[tp_total_costs_claimed] , 0)
--3E costs and disbs billed
)
- 

		(
ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
+ ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
+ ISNULL(fact_finance_summary.[claimants_costs_paid], 0)
--+ 3E costs and disbs billed
		)

		END

, [Total Claim Savings (percent) - Update] = NULL --
--CASE 
--WHEN dim_detail_client.[hastings_closure_date]  IS NOT NULL      -- THEN [Total Claim Savings (money)]
--     AND  fact_detail_cost_budgeting.[hastings_claimant_schedule_value] > 0 

--THEN ISNULL(((ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0) 
--	    + ISNULL(fact_finance_summary.[tp_total_costs_claimed] ,0)
--		--+ 3E costs and disbs billed
--		) 
--		- 
--(
--ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
--+ ISNULL(fact_finance_summary.[claimants_costs_paid], 0)
----+ 3E costs and disbs billed
--		)),0) 
--/ ISNULL((ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0) 
--	    + ISNULL(fact_finance_summary.[tp_total_costs_claimed] ,0)
--		--+ ISNULL(fact_finance_summary.total_amount_billed,0)
--		),0)

--WHEN  ISNULL(fact_detail_cost_budgeting.[hastings_claimant_schedule_value], 0) = 0
--AND dim_detail_client.[hastings_closure_date]  IS NOT NULL
--THEN 
--ISNULL(((
--ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved], 0)
--+ ISNULL(fact_finance_summary.[tp_total_costs_claimed] , 0)
----3E costs and disbs billed
--)
--- 
--(
--ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_general_damages_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_hire_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_loe_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_other_specials_to_be_paid], 0)
--+ ISNULL(fact_detail_paid_detail.[hastings_total_treatment_to_be_paid], 0)
--+ ISNULL(fact_finance_summary.[claimants_costs_paid], 0)
----+ 3E costs and disbs billed
--) ),0)
--/ (ISNULL(ISNULL(fact_detail_cost_budgeting.[hastings_total_damages_costs_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_general_damages_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_hire_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_loe_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_other_specials_to_be_reserved], 0)
--+ ISNULL(fact_detail_cost_budgeting.[hastings_total_treatment_to_be_reserved], 0)
--+ ISNULL(fact_finance_summary.[tp_total_costs_claimed] , 0),0)
----+ ISNULL(fact_finance_summary.total_amount_billed,0)
--)

--END





FROM Reporting.dbo.hastings_listing_table
JOIN red_dw.dbo.dim_matter_header_current
ON master_client_code + '-' + master_matter_number = [Supplier Reference]
JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_detail_cost_budgeting
ON fact_detail_cost_budgeting.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_detail_client
ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT JOIN red_dw.dbo.fact_detail_reserve_detail
ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key


WHERE
	hastings_listing_table.[Supplier Reference] <> '4908-19'

	--AND hastings_listing_table.[Supplier Reference] = '4908-27'

	ORDER BY date_opened_case_management
GO
