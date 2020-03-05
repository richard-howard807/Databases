SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[CoopTotalReserveMovement]  --EXEC CoopTotalReserveMovement '2017-10-31'
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
,insurerclient_reference AS[Coop reference]

,PMTotalReserve AS[Total reserve - previous month end] 
,CMTotalReserve AS[Total reserve -current month end] 
,ISNULL(CMTotalReserve,0) - ISNULL(PMTotalReserve,0)  AS[Total Reserve movement]

,PMDamagesReserve AS[Damages Reserve - previous month end] 
,CMDamagesReserve AS[Damages Reserve -current month end] 
,ISNULL(CMDamagesReserve,0) - ISNULL(PMDamagesReserve,0)  AS[Damages Reserve movement]

,PMDefenceCostReserve AS[Defence Cost Reserve - previous month end] 
,CMDefenceCostReserve AS[Defence Cost Reserve -current month end] 
,ISNULL(CMDefenceCostReserve,0) - ISNULL(PMDefenceCostReserve,0)  AS[Defence Cost Reserve movement]

,PMCostReserve AS[Claimants Cost Reserve - previous month end] 
,CMCostReserve AS[Claimants Cost Reserve -current month end] 
,ISNULL(CMCostReserve,0) - ISNULL(PMCostReserve,0)  AS[Claimants Cost Reserve movement]

,CMTransactionDate
,PMTransactionDate
,CASE 
WHEN ISNULL(CMTotalReserve,0) - ISNULL(PMTotalReserve,0) <> 0 THEN 1 
WHEN ISNULL(CMDamagesReserve,0) - ISNULL(PMDamagesReserve,0) <>0 THEN 1
WHEN ISNULL(CMDefenceCostReserve,0) - ISNULL(PMDefenceCostReserve,0) <>0 THEN 1
WHEN ISNULL(CMCostReserve,0) - ISNULL(PMCostReserve,0)<>0 THEN 1
WHEN PMTotalReserve IS NULL AND CMTotalReserve IS NOT NULL THEN 2
WHEN PMDamagesReserve IS NULL AND CMDamagesReserve IS NOT NULL THEN 2
WHEN PMDefenceCostReserve IS NULL AND CMDefenceCostReserve IS NOT NULL THEN 2
WHEN PMCostReserve IS NULL  AND CMCostReserve IS NOT NULL THEN 2
ELSE 0 END AS ReportFilter
,c.[coop_client_branch]
FROM red_dw.dbo.dim_matter_header_current AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.fact_dimension_main AS b WITH (NOLOCK) 
 ON a.dim_matter_header_curr_key=b.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_detail_core_details AS c WITH (NOLOCK)
 ON b.dim_detail_core_detail_key=c.dim_detail_core_detail_key
--LEFT JOIN red_dw.dbo.dim_detail_outcome AS d WITH (NOLOCK)
-- ON b.dim_detail_core_detail_key=d.dim_detail_outcome_key 
--LEFT JOIN red_dw.dbo.fact_finance_summary AS e WITH (NOLOCK)
-- ON b.master_fact_key=e.master_fact_key
--LEFT JOIN red_dw.dbo.fact_detail_reserve_detail AS f WITH (NOLOCK)
-- ON b.master_fact_key=f.master_fact_key
 
 

 
LEFT OUTER JOIN (SELECT master_fact_key
,damages_reserve AS CMDamagesReserve
,defence_costs_reserve AS CMDefenceCostReserve
,tp_costs_reserve AS CMCostReserve
,total_reserve AS CMTotalReserve
,transaction_date AS CMTransactionDate
FROM red_dw.dbo.fact_finance_summary_daily WITH (NOLOCK)
WHERE CONVERT(DATE,transaction_date,103)=@CurrentMonth ) AS CM
 ON b.master_fact_key=CM.master_fact_key
LEFT OUTER JOIN (SELECT master_fact_key
,damages_reserve AS PMDamagesReserve
,defence_costs_reserve AS PMDefenceCostReserve
,tp_costs_reserve AS PMCostReserve
,total_reserve AS PMTotalReserve
,transaction_date AS PMTransactionDate
FROM red_dw.dbo.fact_finance_summary_daily WITH (NOLOCK)
WHERE CONVERT(DATE,transaction_date,103)=@PreviousMonth ) AS PM
 ON b.master_fact_key=PM.master_fact_key
LEFT OUTER JOIN (SELECT client_code,matter_number,insurerclient_reference FROM red_dw.dbo.dim_client_involvement WITH (NOLOCK) ) AS ref
 ON a.client_code=ref.client_code AND a.matter_number=ref.matter_number
WHERE client_group_code='00000004'
AND date_closed_practice_management IS NULL
AND a.matter_number <>'ML'
AND ISNULL(c.[coop_client_branch],'') <>'MLT'

ORDER BY a.client_code,a.matter_number


END


GO
