SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [nhs].[NHSRKPISuiteHourlyRate] -- EXEC [nhs].[NHSRKPISuiteHourlyRate] '2019-09-01','2019-09-30'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT CASE WHEN insurerclient_reference IS NULL THEN client_reference ELSE insurerclient_reference END  AS [NHSR Ref]
,RTRIM(master_client_code) + '-' + RTRIM(master_matter_number)  [Panel ref]
,dim_claimant_thirdparty_involvement.claimant_name [Claimant name]
,matter_owner_full_name AS [Matter Owner]
,name [Lawyer name]
,jobtitle [Lawyer Grade]
,dim_detail_health.[nhs_type_of_instruction_billing] [Type of instruction]
,fact_bill_billed_time_activity.minutes_recorded /60 [Hours billed]
,BillHrs AS HrsBilled
,WorkHrs AS HrsWorks
,RevenueBilled [Total profit costs billed on case]
,DisbursementsBilled [Disbursement billed on case]
--,fact_bill_billed_time_activity.time_charge_value [Total profit costs billed on case]
--,disbursements_billed [Disbursement billed on case]
,narrative [description of task]
,fee_arrangement
,fact_bill_billed_time_activity.transaction_sequence_number AS transaction_sequence_number
,ROW_NUMBER() OVER (PARTITION BY dim_all_time_narrative.transaction_sequence_number ORDER BY fact_bill_billed_time_activity.dim_gl_date_key DESC) AS LatestRecord
,bill_number
,isactive

FROM  red_dw.dbo.fact_bill_billed_time_activity
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_billed_time_activity.dim_bill_key
INNER JOIN  red_dw.dbo.fact_all_time_activity
 ON fact_bill_billed_time_activity.transaction_sequence_number=fact_all_time_activity.transaction_sequence_number
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill_billed_time_activity.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
--INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_all_time_narrative
 ON fact_all_time_activity.dim_all_time_narrative_key=dim_all_time_narrative.dim_all_time_narrative_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
 ON dim_detail_health.client_code = dim_matter_header_current.client_code
 AND dim_detail_health.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
SELECT dim_matter_header_current.client_code,dim_matter_header_current.matter_number,SUM(fees_total) AS RevenueBilled
,SUM(hard_costs) + SUM(soft_costs) AS DisbursementsBilled
  FROM red_dw.dbo.fact_bill_matter_detail
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = fact_bill_matter_detail.client_code
 AND dim_matter_header_current.matter_number = fact_bill_matter_detail.matter_number
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_matter_detail.dim_bill_key
WHERE master_client_code='N1001'
AND bill_date BETWEEN @StartDate  AND @EndDate
AND bill_reversed=0
GROUP BY dim_matter_header_current.client_code,dim_matter_header_current.matter_number
) AS TotalBilled
  ON dim_matter_header_current.client_code=TotalBilled.client_code
  AND dim_matter_header_current.matter_number=TotalBilled.matter_number
LEFT OUTER JOIN TE_3E_Prod.dbo.TimeBill
 ON TimeCard=fact_bill_billed_time_activity.transaction_sequence_number
 AND TimeBill.TimeBillIndex = fact_bill_billed_time_activity.timebillindex -- added in 01.10.19
WHERE master_client_code='N1001'
AND bill_date BETWEEN @StartDate  AND @EndDate
--AND fact_bill_billed_time_activity.minutes_recorded>=120
AND BillHrs>=2
AND fact_bill_billed_time_activity.time_charge_value>0
AND fee_arrangement='Hourly rate'
AND bill_reversed=0
AND isactive=1

ORDER BY dim_matter_header_current.client_code,dim_matter_header_current.matter_number
END
GO
