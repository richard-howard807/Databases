SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [dbo].[AIGBillingProjectReport]
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
,red_dw.dbo.dim_matter_header_current.present_position AS [Present Position]
,dim_matter_header_current.fixed_fee AS [Fixed Fee]
,red_dw.dbo.dim_matter_header_current.fee_arrangement
,dim_matter_header_current.fixed_fee_amount
,Proforma.[Proforma Status]
,Proforma.[Proforma Elapsed Days]
,[Proforma].[Proforma Date]
,dim_detail_client.[aig_litigation_number]
,fact_detail_cost_budgeting.[aigtotalbudgetfixedfee]
,fact_detail_cost_budgeting.[aigtotalbudgethourlyrate]
,fact_detail_cost_budgeting.[aig_costs_practice_area_only_budget]
,dim_detail_core_details.[is_insured_vat_registered]
,ISNULL(total_amount_billed,0) - ISNULL(vat_billed,0) AS [Total Billed]
, ISNULL(vat_billed,0) AS TotalVat
,disbursement_balance AS [UnbilledDisbs]
,aig_rates_assigned_in_ascent
,         CONCAT_WS(',',
             CASE WHEN dim_detail_client.aig_litigation_number IS NULL
                       OR dim_detail_client.aig_litigation_number = '' THEN
                      'No LIT Number'
             END ,
			 CASE WHEN dim_detail_client.aig_rates_assigned_in_ascent='LIT not in ASCENT' THEN 'LIT not in ASCENT' END,

CASE WHEN dim_detail_client.aig_rates_assigned_in_ascent IN 
(
'FRAUDC - Fraud Hourly','AUTOCO - Motor Hourly'
,'CASUAM - Casualty Major Loss'
,'CASUAC - Casualty Hourly'
,'AUTOML - Motor Major Loss'
,'HLTHCR - Healthcare Hourly'
,'ENVIRC - Environmental Hourly'
,'ENVIRM - Environmental Hourly'
,'RECVCA - Recovery'
,'AUTOEX - Motor Hourly'
) AND ISNULL(dim_matter_header_current.fixed_fee,'')<>'Hourly' 
AND ISNULL(referral_reason,'')<>'Costs dispute'
THEN 'Incorrect fee scale' END,

CASE WHEN dim_detail_client.aig_rates_assigned_in_ascent IN 
(
'AUTOCA - Motor Fixed Fee'
,'CASUCA - Casualty Fixed Fee'
,'CASUMA - Casualty Fixed Fee'

) 
AND ISNULL(dim_matter_header_current.fixed_fee,'')<>'Fixed Fee' 
AND ISNULL(referral_reason,'')<>'Costs dispute'
THEN 'Incorrect fee scale' END,
             CASE WHEN dim_detail_client.aig_litigation_number LIKE 'LIT-%'
                       AND dim_detail_client.aig_litigation_number <> 'LIT-16777 UKSC'
                       AND ISNULL(fact_detail_cost_budgeting.[aig_fixed_fee_budget_fees],0) = 0 
                       AND ISNULL(fact_detail_cost_budgeting.[aig_costs_practice_area_only_budget],0) =0 
                       AND ISNULL(fact_detail_cost_budgeting.[aigtotalbudgethourlyrate],0) = 0 
					   AND ISNULL(lead_budget_details.budget_approved,'') = ''
					   AND ISNULL(lead_budget_details.total_budget_uploaded,0) = 0
                       AND ISNULL(lead_budget_details.date_budget_uploaded,'') ='' 
					  					   
					   THEN
                      'No budget figures'
             END,
             CASE WHEN ISNULL(dim_detail_client.has_budget_been_approved, '') = 'Rejected' THEN
                      'Rejected Budget'
             END,
             CASE WHEN ISNULL(dim_detail_client.has_budget_been_approved, '') = 'No' THEN
                      'Awaiting budget approval'
             END
			 --,
    --         CASE WHEN ISNULL(dim_detail_client.aig_litigation_number, '') LIKE '%[*]LIT-%' THEN
    --                  'Incorrect fee scale'
    --         END,
    --         CASE WHEN ISNULL(dim_detail_client.aig_litigation_number, '') LIKE '%[#]LIT-%' THEN
    --                  'LIT not on Collaborati'
    --         END
	) 
			 
			 [exception]



FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
LEFT JOIN red_dw.dbo.fact_detail_cost_budgeting
 ON fact_detail_cost_budgeting.client_code = dim_matter_header_current.client_code
 AND fact_detail_cost_budgeting.matter_number = dim_matter_header_current.matter_number
LEFT JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
  LEFT OUTER JOIN  (
				SELECT dim_detail_client.aig_litigation_number
					,MAX(dim_detail_client.date_budget_uploaded) date_budget_uploaded
					,MAX(cost_budgeting.total_budget_uploaded) total_budget_uploaded
					,MAX(dim_detail_client.has_budget_been_approved) budget_approved
				FROM red_dw.dbo.fact_dimension_main main
				INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.dim_matter_header_curr_key = main.dim_matter_header_curr_key
				INNER JOIN red_dw.dbo.dim_detail_client dim_detail_client ON dim_detail_client.dim_detail_client_key = main.dim_detail_client_key
				INNER JOIN red_dw.dbo.fact_detail_cost_budgeting cost_budgeting ON cost_budgeting.master_fact_key = main.master_fact_key

				WHERE 1=1
					--AND dim_detail_client.aig_litigation_number = 'LIT-21253'
					AND header.client_group_code = '00000013'
					AND header.reporting_exclusions <> 1
					AND UPPER(dim_detail_client.aig_litigation_number) LIKE '%LIT%'
					AND dim_detail_client.aig_litigation_number <> 'No LIT'
					AND dim_detail_client.aig_litigation_number IS NOT NULL 
				GROUP BY dim_detail_client.aig_litigation_number
						) lead_budget_details ON lead_budget_details.aig_litigation_number = dim_detail_client.aig_litigation_number

 
 
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
WHERE client_code='A2002'
AND fees_total <>0
AND dim_bill.bill_number <>'PURGE'
AND bill_reversed=0
GROUP BY client_code,matter_number) AS LastBillNonDisbBill
 ON LastBillNonDisbBill.client_code = dim_matter_header_current.client_code
 AND LastBillNonDisbBill.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code='A2002'
AND date_opened_case_management>='2019-02-01'
AND date_closed_practice_management IS NULL
AND 
(
ISNULL(dim_matter_header_current.fee_arrangement,'') <>'Fixed Fee/Fee Quote/Capped Fee'
OR (dim_matter_header_current.fee_arrangement='Fixed Fee/Fee Quote/Capped Fee' AND ISNULL(red_dw.dbo.dim_detail_core_details.present_position,'')='Final bill due - claim and costs concluded')
)                                                 
AND wip>=500
AND (CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END)>=90

ORDER BY (CASE WHEN LastBillNonDisbBill.LastBillDate IS NULL THEN DATEDIFF(DAY,date_opened_case_management,GETDATE()) ELSE 
DATEDIFF(DAY,LastBillNonDisbBill.LastBillDate,GETDATE())
END)
END

GO
