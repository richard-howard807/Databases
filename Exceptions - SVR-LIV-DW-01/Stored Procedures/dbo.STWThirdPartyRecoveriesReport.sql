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
,dim_detail_claim.[stw_principal_3rd_party] AS [Principal 3rd Party]
,dim_detail_claim.[stw_damager] AS [Damager]
,dim_detail_incident.[sap_code] AS [SAP Order number]
,dim_detail_claim.[stw_invoice_number] AS [Invoice Number - Legacy Claims]
,dim_detail_client.[subsidiary] AS [Subsidiary]
,dim_detail_claim.[stw_county_or_division]  AS [County/ Division]  -- udMICoreSTW.cboCountyDiv--
,CASE WHEN dim_detail_claim.[stw_county_or_division] = 'Central' THEN 'Birmingham'
WHEN dim_detail_claim.[stw_county_or_division] = 'Central East' THEN 'Coventry'
WHEN dim_detail_claim.[stw_county_or_division] = 'Central West' THEN 'Wolverhampton'
WHEN dim_detail_claim.[stw_county_or_division] = 'Chester' THEN 'Chester'
WHEN dim_detail_claim.[stw_county_or_division] = 'Derbyshire' THEN 'Derbyshire'
WHEN dim_detail_claim.[stw_county_or_division] = 'Leicestershire' THEN 'Leicester'
WHEN dim_detail_claim.[stw_county_or_division] = 'Nottinghamshire' THEN 'Nottingham'
WHEN dim_detail_claim.[stw_county_or_division] = 'Powys' THEN 'Newtown'
WHEN dim_detail_claim.[stw_county_or_division] = 'Shropshire' THEN 'Telford'
WHEN dim_detail_claim.[stw_county_or_division] = 'Staffordshire' THEN 'Stafford'
WHEN dim_detail_claim.[stw_county_or_division] = 'Warwickshire' THEN 'Warwick'
WHEN dim_detail_claim.[stw_county_or_division] = 'Worcestershire/Gloucestershire' THEN 'Gloucester'
WHEN dim_detail_claim.[stw_county_or_division] = 'Wrexham' THEN 'Wrexham'
WHEN dim_detail_claim.[stw_county_or_division] = 'Severn Trent Green Power' THEN 'Chipping Norton'
ELSE dim_detail_claim.[stw_county_or_division] END AS [City]

,dim_detail_claim.[stw_waste_or_water] AS [Water/Waste]
,dim_detail_claim.[stw_damaged_infrastructure] AS [Damaged Infrastructure] --udMICoreSTW.cboDamagedInfr--
,red_dw.dbo.datetimelocal(dim_detail_claim.[stw_date_complete_pack_received]) AS [Date Complete Pack Received]
,fact_detail_reserve_detail.[recovery_reserve] AS [ST Claim Costs submitted]
,fact_detail_recovery_detail.[stw_realistic_expected_recovery_amount] AS [Realistic expected recovery amount]
,dim_detail_claim.[stw_current_position] AS [Present position ] --udMICoreSTW.cboCurrentPos
,dim_detail_claim.[stw_liability_position] AS [Liability Position] --udMICoreSTW.cboLiabPos 
,dim_detail_claim.[stw_reason_for_denying_liability] AS [Reason for denying liability] --udMICoreSTW.cboReasDenyLiab
,dim_detail_claim.[stw_agreement_or_complete_date] AS [TP Agreement date / date completed]
,CASE WHEN dim_detail_claim.[stw_agreement_or_complete_date] IS NULL THEN 'Ongoing' ELSE 'Concluded' END AS [Status]
,fact_detail_recovery_detail.[stw_total_amount_recovered] AS [Costs Recovered]
,dim_detail_claim.[stw_reason_for_reduced_recovery] AS [Reason for Reduced Recovery] --udMICoreSTW.cboReasRedRec
,fact_detail_claim.[stw_instalment_payments_per_month] AS [Instalment Payments per month]
,client_account_balance_of_matter AS [Client account balance]
,defence_costs_billed AS [Revenue Billed]
,disbursements_billed AS [Disbursements Billed]
,vat_billed AS [Vat Billed]
,NULL AS [Fee Amount payable to Coreclaims - Legacy cases - Net VAT]
,fact_detail_recovery_detail.[stw_total_amount_recovered]*0.1425 AS [Fee Amount deducted by Coreclaims - New cases - Net VAT]
,ISNULL(fact_detail_recovery_detail.[stw_total_amount_recovered],0) - ISNULL(defence_costs_billed,0) AS [Net amount recovered]
,CASE WHEN LastBill.LastNonDisbBill='2022-07-04' THEN '2022-06-30' ELSE LastBill.LastNonDisbBill END AS [Fee billing month and year]
--,CASE WHEN date_claim_concluded IS NOT NULL THEN 
--DATEDIFF(DAY, date_instructions_received,red_dw.dbo.datetimelocal(dim_detail_claim.[stw_agreement_or_complete_date]))
--ELSE DATEDIFF(DAY, date_instructions_received,CONVERT(DATE, DATEADD(d, -( DAY(GETDATE()) ), GETDATE()))) END AS [Elapsed days]
--,CASE WHEN date_claim_concluded IS NOT NULL THEN 
--DATEDIFF(DAY, red_dw.dbo.datetimelocal(dim_detail_claim.[stw_date_complete_pack_received]),red_dw.dbo.datetimelocal(dim_detail_claim.[stw_agreement_or_complete_date]))
--WHEN dim_detail_claim.[stw_agreement_or_complete_date] IS NULL THEN   DATEDIFF(DAY, red_dw.dbo.datetimelocal(dim_detail_claim.[stw_date_complete_pack_received]),GETDATE()) END 
,CASE WHEN dim_detail_claim.[stw_agreement_or_complete_date] is NOT NULL
THEN DATEDIFF(DAY, dim_detail_claim.[stw_date_complete_pack_received], dim_detail_claim.[stw_agreement_or_complete_date])
WHEN dim_detail_claim.[stw_agreement_or_complete_date] is NULL
THEN DATEDIFF(DAY,dim_detail_claim.[stw_date_complete_pack_received] ,CONVERT(DATE,GETDATE(),103))
END 
AS [Elapsed days]
,time.hours_recorded AS [Hours Recorded]
,wip AS [WIP]
,disbursement_balance AS [Unbilled Disbursements]
,dim_detail_core_details.[date_letter_of_claim]
, CASE dim_detail_claim.[stw_work_type] WHEN 'Third Party Recoveries' THEN 'STW TP Recoveries' ELSE 'STW DG Transfer' END AS page_name

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
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
 ON fact_detail_recovery_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
ON fact_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN (SELECT dim_matter_header_curr_key, SUM(fact_chargeable_time_activity.minutes_recorded)/60 hours_recorded 
FROM red_dw.dbo.fact_chargeable_time_activity
GROUP BY fact_chargeable_time_activity.dim_matter_header_curr_key) AS time
ON time.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
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
AND  dim_detail_claim.[stw_work_type] IN ('Third Party Recoveries', 'DG Transfer')

ORDER BY master_matter_number

END


GO
