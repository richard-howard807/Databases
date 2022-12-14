SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[UniversityOfCumbriaWIPAndRevenue]

AS

BEGIN
SELECT master_client_code + '-'+master_matter_number AS [Reference]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
,name AS [Matter Owner]
,hierarchylevel4hist AS [Team]
,ISNULL(LifetimeWIP.LifetimeWIP,0) AS LifetimeWIP
,ISNULL(LifetimeWIP.[Lifetime WIP Amount],0) AS [Lifetime WIP Amount]
,ISNULL(WIP.WIP,0) AS WIP
,ISNULL(WIP.[WIP Amount],0) AS [WIP Amount]
,ISNULL(RevenueBilled.BillHrs,0) AS [Hrs Billed]
,ISNULL(RevenueBilled.Revenue,0) AS [Revenue Billed]
,BOA.BOA_Total AS [Billed on Account]
,ISNULL(TransferedTime.[Hrs Transferred],0) AS [Hrs Transferred] 
,ISNULL(TransferedTime.[Funds Transferred],0) AS [Funds Transferred]
,work_type_name AS [Matter Type]
,matter_category
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN 
(
SELECT dim_matter_header_curr_key, SUM(mins.bill_total_excl_vat) BOA_Total

FROM red_dw.dbo.fact_bill_detail mins
WHERE dim_bill_charge_type_key = 1
AND mins.bill_total > 0
AND client_code = '00243439'
AND mins.dim_bill_key NOT IN (SELECT dim_bill_key FROM red_dw.dbo.dim_bill WHERE bill_reversed = 1)
GROUP BY dim_matter_header_curr_key
) AS BOA
 ON  BOA.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 

LEFT OUTER JOIN (SELECT dim_matter_header_curr_key,SUM(minutes_recorded)/60 AS WIP
,SUM(time_charge_value) AS [WIP Amount]
FROM red_dw.dbo.fact_all_time_activity  WHERE dim_bill_key=0 AND isactive=1
GROUP BY dim_matter_header_curr_key) AS WIP
 ON WIP.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN (SELECT dim_matter_header_curr_key,SUM(minutes_recorded)/60 AS LifetimeWIP
,SUM(time_charge_value) AS [Lifetime WIP Amount]
FROM red_dw.dbo.fact_all_time_activity  WHERE isactive=1
GROUP BY dim_matter_header_curr_key) AS LifetimeWIP
 ON LifetimeWIP.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN
(
SELECT fact_bill_billed_time_activity.dim_matter_header_curr_key
,SUM(BillHrs) AS BillHrs
,SUM(BillAmt) AS Revenue
FROM  red_dw.dbo.fact_bill_billed_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
ON dim_bill_date.dim_bill_date_key = fact_bill_billed_time_activity.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_bill WITH(NOLOCK)
ON dim_bill.dim_bill_key = fact_bill_billed_time_activity.dim_bill_key
        LEFT OUTER JOIN TE_3E_Prod.dbo.TimeBill WITH(NOLOCK)
            ON TimeCard = fact_bill_billed_time_activity.transaction_sequence_number
               AND TimeBill.timebillindex = fact_bill_billed_time_activity.timebillindex
			LEFT OUTER JOIN  TE_3E_Prod.dbo.Timecard WITH(NOLOCK)
			 ON TimeCard=TimeCard.timeindex
	WHERE master_client_code='243439'
AND bill_reversed=0
GROUP BY fact_bill_billed_time_activity.dim_matter_header_curr_key
) AS RevenueBilled
 ON  RevenueBilled.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT 
dim_orig_matter_header_curr_key AS dim_matter_header_curr_key
,original_client_code AS [Original Client]
,original_matter_number AS [Original Matter]
,SUM(minutes_recorded)/60 AS [Hrs Transferred]
,SUM(time_charge_value)  AS [Funds Transferred]
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
WHERE master_client_code='243439' AND master_matter_number='194'
AND dim_bill_key<>0
AND isactive=1
GROUP BY dim_orig_matter_header_curr_key
,original_client_code,
         original_matter_number
) AS TransferedTime
 ON  TransferedTime.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE master_client_code='243439'
AND date_opened_case_management>='2021-10-01'

--AND master_matter_number='183'
AND reporting_exclusions=0

ORDER BY date_opened_case_management DESC

END
GO
