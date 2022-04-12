SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[STWThirdPartyRecoveriesReport]
AS 
BEGIN 
SELECT master_client_code + '-' + master_matter_number AS [Weightmans Reference]
,matter_owner_full_name AS [Core Claims Adjuster]
,dim_detail_core_details.[date_instructions_received] AS [Date Received]
,dim_detail_core_details.incident_date AS [Date of Damage or Date or Discovery]
,txtPrinc3rdP AS [Principal 3rd Party]
,txtDamager AS [Damager]
,dim_detail_incident.[sap_code] AS [SAP Order number]
,txtInvoiceNum AS [Invoice Number - Legacy Claims]
,dim_detail_client.[subsidiary] AS [Subsidiary]
,cboCountyDiv AS [County/ Division]
,dim_detail_claim.[stw_waste_or_water] AS [Water/Waste]
,cboDamagedInfr AS [Damaged Infrastructure]
,dteCompPackRec AS [Date Complete Pack Received]
,fact_detail_reserve_detail.[recovery_reserve] AS [ST Claim Costs submitted]
,curRealExpecRec AS [Realistic expected recovery amount]
,cboCurrentPos AS [Present position ]
,cboLiabPos AS [Liability Position]
,cboReasDenyLiab AS [Reason for denying liability]
,dteTPAgreeComp AS [TP Agreement date / date completed]
,curTotAmountRec AS [Costs Recovered]
,cboReasRedRec AS [Reason for Reduced Recovery]
,curInstalPayPM AS [Instalment Payments per month]
,client_account_balance_of_matter AS [Client account balance]
,defence_costs_billed AS [Revenue Billed]
,disbursements_billed AS [Disbursements Billed]
,vat_billed AS [Vat Billed]
,NULL AS [Fee Amount payable to Coreclaims - Legacy cases - Net VAT]
,curTotAmountRec*0.1425 AS [Fee Amount deducted by Coreclaims - New cases - Net VAT]
,ISNULL(curTotAmountRec,0) - ISNULL(defence_costs_billed,0) AS [Net amount recovered]
,LastBill.LastNonDisbBill AS [Fee billing month and year]
,CASE WHEN date_claim_concluded IS NOT NULL THEN 
DATEDIFF(DAY, date_instructions_received,dteTPAgreeComp)
ELSE DATEDIFF(DAY, date_instructions_received,CONVERT(DATE, DATEADD(d, -( DAY(GETDATE()) ), GETDATE()))) END AS [Elapsed days]
,wip AS [WIP]
,disbursement_balance AS [Unbilled Disbursements]
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_incident
 ON dim_detail_incident.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN MS_Prod.dbo.udMICoreSTW
 ON ms_fileid=udMICoreSTW.fileID
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN (SELECT dim_matter_header_current.dim_matter_header_curr_key,MAX(bill_date) AS LastNonDisbBill
FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
WHERE master_client_code='257248'
AND bill_reversed=0
AND fact_bill.bill_number <>'PURGE'
AND fees_total>0
GROUP BY dim_matter_header_current.dim_matter_header_curr_key) AS LastBill
 ON LastBill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE master_client_code='257248'
AND  dim_detail_claim.[stw_work_type] ='Third Party Recoveries'

END


GO
