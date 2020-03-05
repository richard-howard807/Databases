SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[CapitaBillingProjectReport]
AS
BEGIN
SELECT 
ms_fileid
,dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter]
,matter_description AS [Matter Description]
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
,wip AS [WIP]
,ISNULL(WIPNonCosts,0) AS WIPNonCosts
,red_dw.dbo.dim_matter_header_current.present_position AS [Present Position]
,dim_matter_header_current.fixed_fee AS [Fixed Fee]
,fee_arrangement
,disbursement_balance
,dim_matter_header_current.fixed_fee_amount
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT client_code,matter_number,MAX(bill_date) AS LastBillDate
FROM red_dw.dbo.dim_bill
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_bill_key = dim_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
WHERE client_code IN ('W15373','00046253')
AND fees_total <>0
AND dim_bill.bill_number <>'PURGE'
AND bill_reversed=0
GROUP BY client_code,matter_number) AS LastBillNonDisbBill
 ON LastBillNonDisbBill.client_code = dim_matter_header_current.client_code
 AND LastBillNonDisbBill.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT client_code AS WipClient,matter_number AS WipMatter,SUM(time_charge_value) AS WIPNonCosts
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
WHERE client_code='W15373'
AND fed_code NOT IN ('3662','1713','3401','4456','3113','4878','4941','4846','2033','1924','4493','4204')
AND dim_bill_key=0
GROUP BY client_code,matter_number) AS WIPNonCosts
 ON dim_matter_header_current.client_code=WIPNonCosts.WipClient
 AND dim_matter_header_current.matter_number=WIPNonCosts.WipMatter

WHERE dim_matter_header_current.client_code IN('W15373','00046253')
AND date_closed_practice_management IS NULL
AND ISNULL(present_position,'')<>'Claim concluded but costs outstanding'
AND 
(
ISNULL(fee_arrangement,'') <>'Fixed Fee/Fee Quote/Capped Fee'
--OR (fee_arrangement='Fixed Fee/Fee Quote/Capped Fee' AND ISNULL(present_position,'')='Final bill due - claim and costs concluded')
)                                                 
AND (ISNULL(WIPNonCosts,0)>=1550 OR disbursement_balance>=500)
--AND (CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
--DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
--END)>=90



UNION


SELECT 
ms_fileid
,dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter]
,matter_description AS [Matter Description]
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
,ISNULL(WIPNonCosts,0) AS WIPNonCosts
,WIPNonCosts
,red_dw.dbo.dim_matter_header_current.present_position AS [Present Position]
,dim_matter_header_current.fixed_fee AS [Fixed Fee]
,fee_arrangement
,disbursement_balance
,dim_matter_header_current.fixed_fee_amount
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT client_code,matter_number,MAX(bill_date) AS LastBillDate
FROM red_dw.dbo.dim_bill
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_bill_key = dim_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
WHERE client_code='W15373'

AND dim_bill.bill_number <>'PURGE'
AND bill_reversed=0
GROUP BY client_code,matter_number
) AS LastBillNonDisbBill
 ON LastBillNonDisbBill.client_code = dim_matter_header_current.client_code
 AND LastBillNonDisbBill.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT client_code AS WipClient,matter_number AS WipMatter,SUM(time_charge_value) AS WIPNonCosts
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
WHERE client_code='W15373'
AND fed_code NOT IN ('3662','1713','3401','4456','3113','4878','4941','4846','2033','1924','4493','4204')
AND dim_bill_key=0
GROUP BY client_code,matter_number) AS WIPNonCosts
 ON dim_matter_header_current.client_code=WIPNonCosts.WipClient
 AND dim_matter_header_current.matter_number=WIPNonCosts.WipMatter
WHERE dim_matter_header_current.client_code='W15373'
AND date_closed_practice_management IS NULL
AND ISNULL(fee_arrangement,'') ='Fixed Fee/Fee Quote/Capped Fee'
AND ISNULL(present_position,'')='Final bill due - claim and costs concluded'
AND (ISNULL(WIPNonCosts,0) >0 OR disbursement_balance>0)





END
GO
