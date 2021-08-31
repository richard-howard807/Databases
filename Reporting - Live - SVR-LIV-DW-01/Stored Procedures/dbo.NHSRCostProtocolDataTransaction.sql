SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[NHSRCostProtocolDataTransaction]
(
@StartDate AS DATE
,@EndDate AS DATE
)

AS 

BEGIN

--DECLARE 
--@StartDate AS DATE = '2021-08-01'
--,@EndDate AS DATE = '2021-08-28'

SELECT master_client_code + '-' +master_matter_number AS [Client/Matter]
,claimant_name AS Claimant
,dim_fed_hierarchy_history.name AS [Matter Owner]
,dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
,time_activity_code AS [Activity Code]
,transaction_calendar_date AS [Transaction Date]
,narrative_unformattedtext AS Narrative
,minutes_recorded AS [Minutes Recorded]
,minutes_recorded / 60 AS [Hours Recorded]
,hourly_charge_rate AS [Charge Rate]
,time_charge_value AS [WIP Value]
,red_dw.dbo.fact_all_time_activity.transaction_sequence_number AS [Transaction ID]
,feeearner.name  AS TransactionFeeEarner

FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_matter_header_current 
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_all_time_narrative
 ON dim_all_time_narrative.dim_all_time_narrative_key = fact_all_time_activity.dim_all_time_narrative_key
INNER JOIN red_dw.dbo.dim_transaction_date
 ON dim_transaction_date.dim_transaction_date_key = fact_all_time_activity.dim_transaction_date_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
 LEFT JOIN  red_dw.dbo.dim_fed_hierarchy_history feeearner 
 ON red_dw.dbo.dim_matter_header_current.fee_earner_code = feeearner.fed_code AND feeearner.activeud = 1 AND feeearner.dss_current_flag = 'Y'
 WHERE master_client_code='N1001'
AND time_activity_code IN ('CB10','CB11','CB12','CB13')
AND isactive=1
AND dim_bill_key=0
AND CONVERT(DATE,transaction_calendar_date,103) BETWEEN @StartDate AND @EndDate

END
GO
