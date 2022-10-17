SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--2019-08-07 ES added Casualty Liverpool 2 requested by JB 
--2020-01-13 ES added Casualty Birmingham requested by JB
--2020-05-04 JB removed team filter due to the new hierarchy change of team names. Added in filter to include Legal Ops - Claims only, ticket #57448 
--2021-05-07 OK currently only brings in claims, changed to bring in LTA & Claims 
--2021-09-03 ES #101252, amended fee arrangment logic to look at dim_detail_finance.[output_wip_fee_arrangement]
--2021-09-23 JB #115357 added @client_code so sproc can be used for new Gallagher Bassestt Billing Project Report, and any other that are needed in future
--2022-01-20 MT New Catalina report based on ZurichBillingProjectReport
--2022-10-14 MT Additional filter as per JB 173273

CREATE PROCEDURE [dbo].[CatalinaBillingProjectReport]
(
	@client_code AS NVARCHAR(8)
)
AS

--Testing
--DECLARE @client_code AS NVARCHAR(8) = 'W25984'

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
--,[Filter_Flag] = CASE WHEN  dim_detail_outcome.date_costs_settled  IS NOT NULL THEN 1 
 --     WHEN  date_claim_concluded IS NOT NULL AND TRIM(outcome_of_case) IN ('Discontinued - Indemnified by third party', 'Discontinued - indemnified by third party','Discontinued - indemnified by 3rd party' , 'Discontinued - Pre-Lit', 'Discontinued  - pre-lit', 'Discontinued - pre-lit','Discontinued - post lit with no costs order', 'Discontinued - post-lit with no costs order', 'Exclude from Reports', 'Exclude from reports', 'Lost at Trial', 'Lost at trial', 'Lost at trial (damages exceed claimant''s P36 offer)','Struck Out' ,'Struck out','Won At Trial','Won at Trial','Won at trial','discontinued - pre-lit'  , 'exclude from reports'   , 'struck out','won at trial'                                 ) THEN 1 
--	        ELSE 0 END


FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

 LEFT JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
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
WHERE client_code=@client_code
AND fees_total <>0
AND dim_bill.bill_number <>'PURGE'
AND bill_reversed=0
GROUP BY client_code,matter_number) AS LastBillNonDisbBill
 ON LastBillNonDisbBill.client_code = dim_matter_header_current.client_code
 AND LastBillNonDisbBill.matter_number = dim_matter_header_current.matter_number

 LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
 ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE dim_matter_header_current.client_code=@client_code
AND date_opened_case_management>='2019-02-01'
--AND dim_matter_header_current.matter_number NOT IN ('00079227')
AND dim_fed_hierarchy_history.hierarchylevel2hist IN
(
N'Legal Ops - Claims',
N'Legal Ops - LTA'
)

AND date_closed_practice_management IS NULL
AND date_opened_case_management >='2019-02-01'

AND CASE WHEN ISNULL(TRIM(fee_arrangement),'') <>'Fixed Fee/Fee Quote/Capped Fee' THEN 1 
                   WHEN TRIM(fee_arrangement)='Fixed Fee/Fee Quote/Capped Fee' AND ISNULL(TRIM(present_position),'')='Final bill due - claim and costs concluded' THEN 1 
ELSE 0 END = 1
                                                
AND wip>=500
AND (CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END)>=90


AND 
/* Additional filter as per JB 173273*/
CASE WHEN  dim_detail_outcome.date_costs_settled  IS NOT NULL THEN 1 
      WHEN  date_claim_concluded IS NOT NULL AND TRIM(outcome_of_case) IN ('Discontinued - Indemnified by third party', 'Discontinued - indemnified by third party','Discontinued - indemnified by 3rd party' , 'Discontinued - Pre-Lit', 'Discontinued  - pre-lit', 'Discontinued - pre-lit','Discontinued - post lit with no costs order', 'Discontinued - post-lit with no costs order', 'Exclude from Reports', 'Exclude from reports', 'Lost at Trial', 'Lost at trial', 'Lost at trial (damages exceed claimant''s P36 offer)','Struck Out' ,'Struck out','Won At Trial','Won at Trial','Won at trial','discontinued - pre-lit'  , 'exclude from reports'   , 'struck out','won at trial'                                 ) THEN 1 
	        ELSE 0 END = 1 






ORDER BY (CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END)




END

GO
