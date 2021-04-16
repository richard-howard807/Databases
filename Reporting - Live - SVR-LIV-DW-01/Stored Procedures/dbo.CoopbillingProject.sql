SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[CoopbillingProject]

AS 

BEGIN 

SELECT RTRIM(dim_matter_header_current.client_code) AS [Client]
,RTRIM(dim_matter_header_current.matter_number) AS [Matter]
, RTRIM(dim_matter_header_current.master_client_code) +'-'+ RTRIM(dim_matter_header_current.master_matter_number) AS [Client/Matter Number]
,RTRIM(matter_description) AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,name AS [Matter Owner]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,LastBillDate AS [Date of Last Non Revered/Non DisbOnly Bill]
,DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE()) AS [Elapsed from Last Bill]
,DATEDIFF(DAY,date_opened_case_management,GETDATE()) AS [Elapsed fromDate Opened]
,CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END  AS ElapsedDays
,CostsSplit.TotalWIP AS [WIP]
,CostsSplit.CostsTime
,ISNULL(CostsSplit.TotalWIP,0) - ISNULL(CostsSplit.CostsTime,0) AS NonCosts
,RTRIM(red_dw.dbo.dim_matter_header_current.present_position) AS [Present Position]
,dim_matter_header_current.fixed_fee AS [Fixed Fee]
,RTRIM(fee_arrangement) AS fee_arrangement
,dim_matter_header_current.fixed_fee_amount
--,dim_matter_header_current.fixed_fee_amount
--,Proforma.[Proforma Status]
--,Proforma.[Proforma Elapsed Days]
--,[Proforma].[Proforma Date]
,CASE WHEN LastBillDate BETWEEN DATEADD(mm, DATEDIFF(mm, 0, GETDATE()), 0)  AND DATEADD (dd, -1, DATEADD(mm, DATEDIFF(mm, 0, GETDATE()) + 1, 0)) 
THEN 'red' ELSE 'green' END AS color
,client_reference
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
--LEFT OUTER  JOIN 
--(
--SELECT fileID AS ms_fileid
--,profstatus.[description]  AS  [Proforma Status]
--,DATEDIFF(DAY,prof.ProfDate,GETDATE()) AS [Proforma Elapsed Days]
--,prof.ProfDate AS [Proforma Date]
--FROM   [TE_3E_Prod].[dbo].TRE_WfHistoryHdr AS WfHistoryHdr
--       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfHistory AS WfHistory ON WfHistoryHdr.WfID  =  WfHistory.TRE_WfHistoryHdr 
--       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfRuleSet AS WFRuleSet ON WfHistory.TRE_WfRuleSet = WFRuleSet.Code
--       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfAction AS WfAction   ON WFRuleSet.TRE_WfAction =  WfAction.Code
       
--	   INNER JOIN [TE_3E_Prod].[dbo].[ProfMaster] prof ON WfHistory.joinid = prof.profmasterid  
--          LEFT JOIN [TE_3E_Prod].[dbo].[ProfStatus] profstatus ON profstatus.code = prof.profstatus
--          LEFT JOIN [TE_3E_Prod].[dbo].[Matter] matter ON matter.mattindex = prof.leadmatter
--          LEFT JOIN [TE_3E_Prod].[dbo].[Client] client ON matter.client = client.clientindex
--		  LEFT JOIN MS_Prod.config.dbFile ON matter.MattIndex=fileExtLinkID

	
--WHERE WfHistory.CompletedDate IS NULL  
--              AND WfHistory.IsHide  =  0
--              AND prof.InvMaster IS NULL
--) AS Proforma
-- ON Proforma.ms_fileid = dim_matter_header_current.ms_fileid
LEFT OUTER JOIN (SELECT fact_bill.client_code,fact_bill.matter_number,MAX(bill_date) AS LastBillDate
FROM red_dw.dbo.dim_bill
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_bill_key = dim_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
WHERE master_client_code IN ('C1001','W24438')
AND fees_total <>0
AND dim_bill.bill_number <>'PURGE'
AND bill_reversed=0
GROUP BY fact_bill.client_code,fact_bill.matter_number) AS LastBillNonDisbBill
 ON LastBillNonDisbBill.client_code = dim_matter_header_current.client_code
 AND LastBillNonDisbBill.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
SELECT fact_all_time_activity.client_code,fact_all_time_activity.matter_number
,SUM(time_charge_value) AS TotalWIP
,SUM(CASE WHEN cost_handler=1 THEN time_charge_value ELSE 0 END) AS CostsTime
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_all_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
WHERE master_client_code IN ('C1001','W24438')
AND dim_bill_key=0
AND isactive=1

GROUP BY fact_all_time_activity.client_code,fact_all_time_activity.matter_number
) AS CostsSplit
 ON CostsSplit.client_code = dim_matter_header_current.client_code
 AND CostsSplit.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number

WHERE master_client_code IN ('C1001','W24438')
AND wip>=100
AND  (CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END)>=30
AND ISNULL(fee_arrangement,'')<>'Fixed Fee/Fee Quote/Capped Fee'
AND ISNULL(fixed_fee,'')<>'Fixed Fee'
AND ISNULL(RTRIM(red_dw.dbo.dim_matter_header_current.present_position),'')<>'To be closed/minor balances to be clear'

END
GO
