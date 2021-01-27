SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MotorProsecutions] --EXEC dbo.MotorProsecutions '2020-05-01','2021-01-26'
(
@StartDate AS DATE
,@EndDate AS DATE
)--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2021-05-01'
--SET @EndDate='2021-12-31'

AS 

BEGIN 
SELECT 
ISNULL(CASE WHEN client_group_name='' THEN NULL ELSE client_group_name END,client_name) AS [Client Group]
,client_name AS [Client Name]
,master_client_code + '-'+ master_matter_number AS [MatterSphere Ref]
,matter_description AS [Matter Description]
,work_type_name AS [Matter Type]
,matter_owner_full_name AS [Case Manager]
,hierarchylevel4hist AS [Team]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Closed]
,defence_costs_billed AS [Revenue]
,wip AS WIP
,last_time_transaction_date AS [Date of Last Time Posting]
,CASE WHEN dim_matter_header_current.date_opened_case_management BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS NewInstructionsCurrent
,CASE WHEN dim_matter_header_current.date_opened_case_management BETWEEN DATEADD(YEAR,-1,@StartDate) AND DATEADD(YEAR,-1,@EndDate) THEN 1 ELSE 0 END AS NewInstructionsPrevious
,RevenueCurrent.RevenueCurrent
,RevenuePrev.RevenuePrevious
,WIPCurrent.WIPCurrent
,WIPPrevious.WIPPrevious
,last_bill_date AS [Date Last Bill]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
SELECT fact_bill.dim_matter_header_curr_key
,SUM(fees_total) AS RevenueCurrent
FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON  dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE work_type_name='Motoring prosecutions'
AND reporting_exclusions=0
AND bill_date BETWEEN @StartDate AND @EndDate
GROUP BY fact_bill.dim_matter_header_curr_key
) AS RevenueCurrent
 ON RevenueCurrent.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT fact_bill.dim_matter_header_curr_key
,SUM(fees_total) AS RevenuePrevious
FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON  dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE work_type_name='Motoring prosecutions'
AND reporting_exclusions=0
AND bill_date BETWEEN DATEADD(YEAR,-1,@StartDate) AND DATEADD(YEAR,-1,@EndDate)
GROUP BY fact_bill.dim_matter_header_curr_key
) AS RevenuePrev
 ON RevenuePrev.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT client AS client_code,matter AS matter_number,SUM(wip_value) AS WIPCurrent FROM red_dw.dbo.fact_wip_daily
WHERE CONVERT(DATE,wip_date,103)=CASE WHEN @EndDate<CONVERT(DATE,GETDATE(),103) THEN @EndDate ELSE CONVERT(DATE,GETDATE()-1,103) END
GROUP BY client,matter
) AS WIPCurrent
ON WIPCurrent.client_code = dim_matter_header_current.client_code
AND WIPCurrent.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
SELECT client AS client_code,matter AS matter_number,SUM(wip_value) AS WIPPrevious FROM red_dw.dbo.fact_wip_daily
WHERE CONVERT(DATE,wip_date,103)=DATEADD(YEAR,-1,@EndDate)
GROUP BY client,matter
) AS WIPPrevious
ON WIPPrevious.client_code = dim_matter_header_current.client_code
AND WIPPrevious.matter_number = dim_matter_header_current.matter_number
WHERE work_type_name='Motoring prosecutions'
AND reporting_exclusions=0

END 
GO
