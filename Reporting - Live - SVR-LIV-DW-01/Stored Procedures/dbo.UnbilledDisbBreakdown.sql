SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--=========================================================================================================
-- ES - 20190815 - amended days banding to use getdate rather than the end of the current month
-- ES - 20201216 - #82500, added logic to exclude non billable disbursements
--=========================================================================================================


CREATE PROCEDURE [dbo].[UnbilledDisbBreakdown]
(
 @finMonth AS VARCHAR(10)
)
AS
BEGIN

/* JB - ticket 43211 - added Team and Division (shows split between Claims and LTA) columns */
SELECT 
a.client_code AS [Client]
   , REPLACE(LTRIM(REPLACE(RTRIM(a.client_code), '0', ' ')), ' ', '0') + '-'
    + REPLACE(LTRIM(REPLACE(RTRIM(a.matter_number), '0', ' ')), ' ', '0') AS [3E Ref]
,client_name AS [Client Name]
,a.matter_number AS [Matter]
,a.costindex AS [Cost Index]
,dim_fed_hierarchy_history.name AS [Fee Earner]
,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4 AS [Team]
,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel2hist AS [Division]
,a.total_unbilled_disbursements AS [Amount]
,red_dw.dbo.dim_payee.name AS [Payee]
,a.workdate AS [Date]
,a.costype_description AS [Disbursement Type]
--,CASE WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) BETWEEN 0 AND 30 THEN '0-30 Days'
--WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) BETWEEN 31 AND 90 THEN '31-90 Days'
--WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) > 90 THEN '90 + Days' END  AS [Days_Banding]
,CASE WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 0 AND 30 THEN '0-30 Days'
WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 31 AND 90 THEN '31-90 Days'
WHEN DATEDIFF(DAY,a.workdate,GETDATE()) > 90 THEN '90 + Days' END  AS [Days_Banding]

--,CASE WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) BETWEEN 0 AND 30 THEN -1
--WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) BETWEEN 31 AND 90 THEN 2
--WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) > 90 THEN 30 END AS [Dim Days Banding Key]

FROM red_dw.dbo.fact_disbursements_detail_monthly AS a
INNER JOIN red_dw.dbo.dim_transaction_date AS b
 ON a.dim_transaction_date_key=b.dim_transaction_date_key

INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON a.client_code=dim_matter_header_current.client_code
 AND a.matter_number=dim_matter_header_current.matter_number 
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK) 
 ON dim_matter_header_current.fee_earner_code=fed_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_payee
 ON dim_payee.dim_payee_key = a.dim_payee_key
 LEFT OUTER JOIN red_dw.dbo.ds_sh_3e_costcard
 ON ds_sh_3e_costcard.costindex = a.costindex

 WHERE dim_bill_key=0
AND total_unbilled_disbursements <> 0
--AND reporting_exclusions=0
AND b.transaction_fin_month=202108
AND a.invnumber  IS NULL 
AND ds_sh_3e_costcard.isnb=0
--AND a.client_code='EMP5104'
--AND a.matter_number='00000002'

END
GO
