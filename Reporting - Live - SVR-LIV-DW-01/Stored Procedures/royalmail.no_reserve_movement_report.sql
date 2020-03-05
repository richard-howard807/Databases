SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:	Lucy Dickinson
-- Date:	11/08/2017
-- Description: Webby ticket 251220
--				Please include all live matters opened under client group "Royal Mail" where Instruction Type is "Insurance" 
--				where the DWH field "Total Reserve Net" has not changed in the last 3 months	
-- =============================================



CREATE PROCEDURE [royalmail].[no_reserve_movement_report]
(
	@nDate DATE
)
AS
 
-- For testing purposes

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--DECLARE @nDate DATE = DATEADD(dd,-1,GETDATE())

DECLARE @nDateCurr DATE = @nDate 
DECLARE @nDatePrev DATE = DATEADD(M,-3,@nDateCurr)
DECLARE @nDateCurrInt INT = CAST(FORMAT(@nDateCurr,'yyyyMMdd') AS INT)
DECLARE @nDatePrevInt INT = CAST(FORMAT(@nDatePrev,'yyyyMMdd') AS INT)

PRINT @nDateCurrInt
PRINT @nDatePrevInt


SELECT 
	fact.master_client_code
	,matter.master_matter_number
	,instruction.instruction_type 
	,matter.client_code [client_number]
	,matter.matter_number [matter_number]
	,matter_description
	,matter_owner_full_name [matter_handler]
	,hierarchylevel4 [team]
	,matter.date_opened_case_management [date_opened]
	,work_type_name
	,core.present_position
	,finance.total_reserve_net
	,solicitor_total_current_reserve solicitor_total_current_reserve_tra098_and_ftr087 
	,finance.total_damages_and_tp_costs_reserve --TRA076 + TRA080
	,finance.other_defendants_costs_reserve 
	,finance.defence_costs_reserve
	,outcome.outcome_of_case
	,finance.damages_paid
	,outcome.date_claim_concluded
	,finance.claimants_costs_paid
	,outcome.date_costs_settled
    ,summary.last_time_transaction_date 
	,@nDateCurr [current_date]
	,@nDatePrev [previous_date]
	,finance_curr.total_reserve_net [current_total_reserve_value]
	,finance_prev.total_reserve_net [previous_total_reserve_value]
	,CASE WHEN ISNULL(finance_curr.total_reserve_net,0) <> ISNULL(finance_prev.total_reserve_net,0) THEN 'Yes' ELSE 'No' END [reserve_updated] 
    
FROM red_dw.dbo.fact_dimension_main fact
INNER JOIN red_dw.dbo.fact_finance_summary finance ON finance.master_fact_key = fact.master_fact_key 
INNER JOIN red_dw.dbo.fact_matter_summary_current summary ON summary.dim_matter_header_curr_key = fact.dim_matter_header_curr_key 
INNER JOIN red_dw.dbo.fact_detail_reserve_detail reserve ON reserve.master_fact_key = fact.master_fact_key
INNER JOIN red_dw.dbo.dim_matter_header_current matter ON matter.dim_matter_header_curr_key = fact.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history feeearner   ON fact.dim_fed_hierarchy_history_key  = feeearner.dim_fed_hierarchy_history_key --and c.dss_current_flag = 'Y'
INNER JOIN red_dw.dbo.dim_client client ON client.dim_client_key = fact.dim_client_key
INNER JOIN red_dw.dbo.dim_matter_worktype worktype ON worktype.dim_matter_worktype_key = matter.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = fact.dim_detail_core_detail_key 
INNER JOIN red_dw.dbo.dim_instruction_type instruction ON instruction.dim_instruction_type_key = matter.dim_instruction_type_key
INNER JOIN red_dw.dbo.dim_detail_claim claim ON claim.dim_detail_claim_key = fact.dim_detail_claim_key
INNER JOIN red_dw.dbo.dim_detail_outcome outcome ON outcome.dim_detail_outcome_key = fact.dim_detail_outcome_key

-- join to the datastore so that we can exclude files with reserve movements within the last 3 months
INNER JOIN (SELECT client_code, matter_number,total_reserve_net FROM red_dw.dbo.fact_finance_summary_daily WHERE dim_transaction_date_key = @nDateCurrInt) finance_curr ON finance_curr.client_code = client.client_code AND finance_curr.matter_number = matter.matter_number 
LEFT OUTER JOIN (SELECT client_code, matter_number,total_reserve_net FROM red_dw.dbo.fact_finance_summary_daily WHERE dim_transaction_date_key = @nDatePrevInt) finance_prev ON finance_prev.client_code = client.client_code AND finance_prev.matter_number = matter.matter_number 

WHERE matter.master_client_code = 'R1001'
AND instruction.instruction_type = 'Insurance'
AND matter.date_closed_case_management IS NULL
AND matter.reporting_exclusions=0 
AND matter.date_opened_case_management <= @nDatePrev 

ORDER  BY matter.client_code, matter.matter_number





GO
