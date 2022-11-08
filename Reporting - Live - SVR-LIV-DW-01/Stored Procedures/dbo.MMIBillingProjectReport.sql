SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[MMIBillingProjectReport]

AS


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
,red_dw.dbo.dim_matter_header_current.present_position AS [Present Position]
,dim_matter_header_current.fixed_fee 
,fee_arrangement
,dim_detail_finance.[output_wip_fee_arrangement] AS [Fixed Fee]
,dim_matter_header_current.fixed_fee_amount
,Proforma.[Proforma Status]
,Proforma.[Proforma Elapsed Days]
,[Proforma].[Proforma Date]
,dim_detail_outcome.date_costs_settled 
,outcome_of_case
,date_claim_concluded
,delegated 


/* •	Casualty (regardless of DA or non-DA) – when WIP hits £500
plus 90 days have passed since i) file open date or ii) 
last bill date, excluding credit and re-bill. */
,[Filter] = CASE WHEN 
hierarchylevel3hist = 'Casualty'  
AND wip >= 500
AND CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END > 90 THEN 1 
/*•	Casualty (regardless of DA or non-DA) – 
when present position is changed to ‘final bill due’
, no minimum WIP value. */
  WHEN 
hierarchylevel3hist = 'Casualty' 
AND present_position LIKE 'Final bill due%' THEN 1 

/*•	Disease DA files – 5 days since file opening, regardless of WIP value. */
 WHEN 
hierarchylevel3hist = 'Disease' 
AND TRIM(delegated) = 'Y' 
AND DATEDIFF(DAY,date_opened_case_management,GETDATE()) > 5 THEN 1 

/*•	Disease non-DA files - when WIP hits £500 plus 90 days have passed since i) file open date or ii) last bill date, 
excluding credit and re-bill.*/
 WHEN 
hierarchylevel3hist = 'Disease' 
AND TRIM(delegated) = 'N'         
AND wip >= 500
AND CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END > 90 THEN 1 

ELSE 0 END
,work_type_name

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 LEFT JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
 LEFT JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 LEFT JOIN red_dw.dbo.dim_instruction_type
 ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key

LEFT OUTER  JOIN 
(
SELECT fileID AS ms_fileid
,profstatus.[description]  AS  [Proforma Status]
,DATEDIFF(DAY,prof.ProfDate,GETDATE()) AS [Proforma Elapsed Days]
,prof.ProfDate AS [Proforma Date]
FROM   [TE_3E_Prod].[dbo].TRE_WfHistoryHdr AS WfHistoryHdr
       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfHistory AS WfHistory ON WfHistoryHdr.WfID  =  WfHistory.TRE_WfHistoryHdr 
       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfRuleSet AS WFRuleSet ON WfHistory.TRE_WfRuleSet = WFRuleSet.Code
       INNER JOIN [TE_3E_Prod].[dbo].TRE_WfAction AS WfAction   ON WFRuleSet.TRE_WfAction =  WfAction.Code
       
	   INNER JOIN [TE_3E_Prod].[dbo].[ProfMaster] prof ON WfHistory.joinid = prof.profmasterid  
          LEFT JOIN [TE_3E_Prod].[dbo].[ProfStatus] profstatus ON profstatus.code = prof.profstatus
          LEFT JOIN [TE_3E_Prod].[dbo].[Matter] matter ON matter.mattindex = prof.leadmatter
          LEFT JOIN [TE_3E_Prod].[dbo].[Client] client ON matter.client = client.clientindex
		  LEFT JOIN MS_Prod.config.dbFile ON matter.MattIndex=fileExtLinkID

	
WHERE WfHistory.CompletedDate IS NULL  
              AND WfHistory.IsHide  =  0
              AND prof.InvMaster IS NULL
) AS Proforma
 ON Proforma.ms_fileid = dim_matter_header_current.ms_fileid
LEFT OUTER JOIN (SELECT client_code,matter_number,MAX(bill_date) AS LastBillDate
FROM red_dw.dbo.dim_bill
INNER JOIN red_dw.dbo.fact_bill
 ON fact_bill.dim_bill_key = dim_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
WHERE TRIM(client_code)='M00001'
AND fees_total <>0
AND dim_bill.bill_number <>'PURGE'
AND bill_reversed=0
GROUP BY client_code,matter_number) AS LastBillNonDisbBill
 ON LastBillNonDisbBill.client_code = dim_matter_header_current.client_code
 AND LastBillNonDisbBill.matter_number = dim_matter_header_current.matter_number

 LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
 ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE TRIM(dim_matter_header_current.client_code)='M00001'
AND date_opened_case_management>='2019-02-01'
--AND dim_matter_header_current.matter_number NOT IN ('00079227')
AND dim_fed_hierarchy_history.hierarchylevel2hist IN
(
N'Legal Ops - Claims',
N'Legal Ops - LTA'
)

AND date_closed_practice_management IS NULL
AND date_opened_case_management >='2019-02-01'

AND 

CASE WHEN 
hierarchylevel3hist = 'Casualty'  
AND wip >= 500
AND CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END > 90 THEN 1 
  WHEN 
hierarchylevel3hist = 'Casualty' 
AND present_position LIKE 'Final bill due%' THEN 1 
 WHEN 
hierarchylevel3hist = 'Disease' 
AND TRIM(delegated) = 'Y' 
AND DATEDIFF(DAY,date_opened_case_management,GETDATE()) > 5 THEN 1 
 WHEN 
hierarchylevel3hist = 'Disease' 
AND TRIM(delegated) = 'N'         
AND wip >= 500
AND CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END > 90 THEN 1 

ELSE 0 END = 1 






ORDER BY (CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END)





GO
