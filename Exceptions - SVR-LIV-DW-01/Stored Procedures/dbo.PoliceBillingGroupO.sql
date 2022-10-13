SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[PoliceBillingGroupO]
AS 

BEGIN
SELECT master_client_code +'.'+ master_matter_number AS [Client/matter number]
,client_name AS [client name]
,matter_description AS [matter description]
,matter_owner_full_name AS [matter owner]
,billing_group AS [billing group]
,date_opened_case_management AS [date opened]
,date_closed_case_management AS [date closed]
,dim_matter_worktype.work_type_name AS [matter type]
,revenue_estimate_net_of_vat
,disbursements_estimate_net_of_vat
,defence_costs_billed_composite AS [revenue billed (net of VAT)]
,disbursements_billed AS [disbursements billed (net of VAT)]
,total_amount_bill_non_comp AS [total billed]
,wip AS [wip]
,disbursement_balance AS [unbilled disbursements]

FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE master_client_code='451638'
AND billing_group='O'

END 
GO
