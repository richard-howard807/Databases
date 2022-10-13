SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[NHSRCostProtocolDataMatter]
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS 

BEGIN

SELECT master_client_code + '-' +master_matter_number AS [Client/Matter]
,dim_claimant_thirdparty_involvement.claimant_name AS Claimant
,name AS [Matter Owner]
,hierarchylevel4hist AS [Team]
,dim_detail_health.[nhs_instruction_type] AS [Instruction Type]
,dim_detail_outcome.[date_claimants_costs_received] AS [Date costs received]
,dim_detail_outcome.[date_costs_settled] AS [Date costs settled]
,fact_finance_summary.[tp_total_costs_claimed] AS [Claimant's costs claimed]
,dim_detail_health.[nhs_who_dealt_with_costs] AS [Who dealt with costs]

,CBTime.CB10 /60 AS [Total Hours - CB10 (unbilled)]
,CBTime.CB11 /60 AS [Total Hours - CB11 (unbilled)]
,CBTime.CB12 /60 AS [Total Hours - CB12 (unbilled)]
,CBTime.CB13 /60 AS [Total Hours - CB13 (unbilled)]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN
(
SELECT  dim_matter_header_current.dim_matter_header_curr_key
,SUM(time_charge_value) AS CBAllTimeBilled
,SUM(CASE WHEN time_activity_code='CB10' THEN minutes_recorded ELSE 0 END) AS CB10
,SUM(CASE WHEN time_activity_code='CB11' THEN minutes_recorded ELSE 0 END) AS CB11
,SUM(CASE WHEN time_activity_code='CB12' THEN minutes_recorded ELSE 0 END) AS CB12
,SUM(CASE WHEN time_activity_code='CB13' THEN minutes_recorded ELSE 0 END) AS CB13
FROM red_dw.dbo.fact_all_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current  WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_all_time_narrative WITH(NOLOCK)
 ON dim_all_time_narrative.dim_all_time_narrative_key = fact_all_time_activity.dim_all_time_narrative_key
INNER JOIN red_dw.dbo.dim_transaction_date WITH(NOLOCK)
 ON dim_transaction_date.dim_transaction_date_key = fact_all_time_activity.dim_transaction_date_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
 WHERE master_client_code='N1001'
AND time_activity_code IN ('CB10','CB11','CB12','CB13')
AND isactive=1
AND dim_bill_key=0
AND CONVERT(DATE,transaction_calendar_date,103) BETWEEN @StartDate AND @EndDate
GROUP BY dim_matter_header_current.dim_matter_header_curr_key
) AS CBTime
 ON CBTime.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement WITH(NOLOCK)
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_health WITH(NOLOCK)
 ON dim_detail_health.client_code = dim_matter_header_current.client_code
 AND dim_detail_health.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH(NOLOCK)
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH(NOLOCK)
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
 
WHERE master_client_code='N1001'




END
GO
