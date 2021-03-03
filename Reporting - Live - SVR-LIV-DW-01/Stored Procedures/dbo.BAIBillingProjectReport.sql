SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE PROCEDURE [dbo].[BAIBillingProjectReport]
AS
BEGIN
SELECT dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter]
, dim_matter_header_current.master_client_code +'-'+ dim_matter_header_current.master_matter_number AS [Client/Matter Number]
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
,disbursement_balance AS [Disbursement Balance]
,red_dw.dbo.dim_matter_header_current.present_position AS [Present Position]
,dim_matter_header_current.fixed_fee AS [Fixed Fee]
,fee_arrangement
,dim_matter_header_current.fixed_fee_amount
,Proforma.[Proforma Status]
,Proforma.[Proforma Elapsed Days]
,[Proforma].[Proforma Date]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.fact_finance_summary WITH(NOLOCK)
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER  JOIN 
(
SELECT fileID AS ms_fileid
,profstatus.[description]  AS  [Proforma Status]
,DATEDIFF(DAY,prof.ProfDate,GETDATE()) AS [Proforma Elapsed Days]
,prof.ProfDate AS [Proforma Date]
FROM   [TE_3E_Prod].[dbo].TRE_WfHistoryHdr AS WfHistoryHdr WITH(NOLOCK)
       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfHistory AS WfHistory WITH(NOLOCK) ON WfHistoryHdr.WfID  =  WfHistory.TRE_WfHistoryHdr 
       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfRuleSet AS WFRuleSet WITH(NOLOCK) ON WfHistory.TRE_WfRuleSet = WFRuleSet.Code
       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfAction AS WfAction WITH(NOLOCK)   ON WFRuleSet.TRE_WfAction =  WfAction.Code
       
	   INNER JOIN [TE_3E_Prod].[dbo].[ProfMaster] prof WITH(NOLOCK) ON WfHistory.joinid = prof.profmasterid  
          LEFT JOIN [TE_3E_Prod].[dbo].[ProfStatus] profstatus WITH(NOLOCK) ON profstatus.code = prof.profstatus
          LEFT JOIN [TE_3E_Prod].[dbo].[Matter] matter WITH(NOLOCK) ON matter.mattindex = prof.leadmatter
          LEFT JOIN [TE_3E_Prod].[dbo].[Client] client WITH(NOLOCK) ON matter.client = client.clientindex
		  LEFT JOIN MS_Prod.config.dbFile WITH(NOLOCK) ON matter.MattIndex=fileExtLinkID

	
WHERE WfHistory.CompletedDate IS NULL  
              AND WfHistory.IsHide  =  0
              AND prof.InvMaster IS NULL
) AS Proforma
 ON Proforma.ms_fileid = dim_matter_header_current.ms_fileid
LEFT OUTER JOIN (SELECT fact_bill.client_code,fact_bill.matter_number,MAX(bill_date) AS LastBillDate
FROM red_dw.dbo.dim_bill WITH(NOLOCK)
INNER JOIN red_dw.dbo.fact_bill WITH(NOLOCK)
 ON fact_bill.dim_bill_key = dim_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON  dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
 INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
WHERE master_client_code='W15349'
AND fees_total <>0
AND dim_bill.bill_number <>'PURGE'
AND bill_reversed=0
GROUP BY fact_bill.client_code,fact_bill.matter_number) AS LastBillNonDisbBill
 ON LastBillNonDisbBill.client_code = dim_matter_header_current.client_code
 AND LastBillNonDisbBill.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT client_code AS WipClient,matter_number AS WipMatter,SUM(time_charge_value) AS WIPNonCosts
FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_all_time_activity.dim_fed_hierarchy_history_key
WHERE client_code='W15349'
AND fed_code NOT IN ('3662','1713','3401','4456','3113','4878','4941','4846','2033','1924','4493','4204')
AND dim_bill_key=0
GROUP BY client_code,matter_number) AS WIPNonCosts
 ON dim_matter_header_current.client_code=WIPNonCosts.WipClient
 AND dim_matter_header_current.matter_number=WIPNonCosts.WipMatter

WHERE dim_matter_header_current.master_client_code='W15349'
AND date_closed_practice_management IS NULL
                                                 
AND 
(
(wip>=500
AND (CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END)>=90)
OR disbursement_balance>500
)

ORDER BY (CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END)
END

GO
