SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ZurichTotalReserveMovement]  --EXEC ZurichTotalReserveMovement '2017-10-31'
(
@CurrentMonth AS DATETIME
)
AS
BEGIN

DECLARE @PreviousMonth AS DATETIME 

SET @PreviousMonth= DATEADD(DAY,-1,DATEADD(MONTH,-1,DATEADD(DAY,1,@CurrentMonth)))

PRINT @PreviousMonth
PRINT @CurrentMonth


SELECT 
a.client_code AS [Client number] 
,a.matter_number AS [Matter number] 
,a.matter_description AS[matter description] 
,insurerclient_reference AS[Zurich reference]
,PMTotalReserve AS[Total reserve - previous month end] 
,CMTotalReserve AS[Total reserve -current month end] 
,ISNULL(CMTotalReserve,0) - ISNULL(PMTotalReserve,0)  AS[Reserve movement]
,CMTransactionDate
,PMTransactionDate
,client_group_name
,referral_reason
,c.present_position
,outcome_of_case
,date_claim_concluded
,damages_paid
,date_costs_settled
,claimants_costs_paid
,total_amount_billed
,f.damages_reserve
,f.defence_costs_reserve
,claimant_costs_reserve_current
,f.other_defendants_costs_reserve
,f.total_reserve
FROM red_dw.dbo.dim_matter_header_current AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.fact_dimension_main AS b WITH (NOLOCK) 
 ON a.dim_matter_header_curr_key=b.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_detail_core_details AS c WITH (NOLOCK)
 ON b.dim_detail_core_detail_key=c.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_outcome AS d WITH (NOLOCK)
 ON b.dim_detail_core_detail_key=d.dim_detail_outcome_key 
LEFT JOIN red_dw.dbo.fact_finance_summary AS e WITH (NOLOCK)
 ON b.master_fact_key=e.master_fact_key
LEFT JOIN red_dw.dbo.fact_detail_reserve_detail AS f WITH (NOLOCK)
 ON b.master_fact_key=f.master_fact_key
 
 

 
LEFT OUTER JOIN (SELECT master_fact_key,total_reserve_net AS CMTotalReserve,transaction_date AS CMTransactionDate
FROM red_dw.dbo.fact_finance_summary_daily WITH (NOLOCK)
WHERE CONVERT(DATE,transaction_date,103)=@CurrentMonth ) AS CM
 ON b.master_fact_key=CM.master_fact_key
LEFT OUTER JOIN (SELECT master_fact_key,total_reserve_net AS PMTotalReserve,transaction_date AS PMTransactionDate
FROM red_dw.dbo.fact_finance_summary_daily WITH (NOLOCK)
WHERE CONVERT(DATE,transaction_date,103)=@PreviousMonth ) AS PM
 ON b.master_fact_key=PM.master_fact_key
LEFT OUTER JOIN (SELECT client_code,matter_number,insurerclient_reference FROM red_dw.dbo.dim_client_involvement WITH (NOLOCK) ) AS ref
 ON a.client_code=ref.client_code AND a.matter_number=ref.matter_number
WHERE client_group_code='00000001'
AND UPPER(referral_reason) LIKE '%DISP%'
AND date_closed_practice_management IS NULL

ORDER BY a.client_code,a.matter_number


END

GO
