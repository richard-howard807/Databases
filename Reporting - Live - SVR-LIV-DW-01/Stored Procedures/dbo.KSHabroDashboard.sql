SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[KSHabroDashboard]

AS 

BEGIN

SELECT dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
, (
           SELECT fin_year
           FROM red_dw..dim_date WITH(NOLOCK)
           WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)
       ) AS [Fin Year Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
,(
           SELECT fin_year
           FROM red_dw..dim_date WITH(NOLOCK)
           WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_closed_case_management AS DATE)
 ) AS [Fin Year Closed]
,RTRIM(master_client_code)+'-'+RTRIM(master_matter_number) AS [Mattersphere Weightmans Reference]
,NULL AS [KD Hasbro ?]
,matter_description AS [Matter Description]
,name AS [Case Manager]
,hierarchylevel4hist AS [Team]
,hierarchylevel3 AS [Department]
,work_type_name AS [Work Type]
,client_name AS [Client Name]
,dim_matter_header_current.fixed_fee_amount AS [Fixed Fee Amount]
,fee_arrangement AS [Fee Arrangement]
,total_amount_bill_non_comp AS [Total Bill Amount - Composite (IncVAT )]
,defence_costs_billed_composite AS [Revenue Costs Billed]
,disbursements_billed AS [Disbursements Billed ]
,vat_non_comp AS [VAT Billed]
,wip AS [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled Disbursements]
,revenue_estimate_net_of_vat AS [Revenue Estimate net of VAT]
,disbursements_estimate_net_of_vat AS [Disbursements net of VAT]
,CASE
           WHEN (fact_matter_summary_current.last_bill_date) = '1753-01-01' THEN
               NULL
           ELSE
               fact_matter_summary_current.last_bill_date
       END AS [Last Bill Date]
,fact_bill_matter.last_bill_date AS [Last Bill Date Composite]
,(
           SELECT fin_year
           FROM red_dw..dim_date
           WHERE dim_date.calendar_date = CAST(fact_bill_matter.last_bill_date AS DATE)
       ) AS [Fin Year Of Last Bill]
,fact_matter_summary_current.[last_time_transaction_date] AS [Date of Last Time Posting]
,(
           SELECT fin_year
           FROM red_dw..dim_date
           WHERE dim_date.calendar_date = CAST(fact_matter_summary_current.[last_time_transaction_date] AS DATE)
       ) AS [Fin Year Of Last Time Posting]
 FROM red_dw.dbo.dim_matter_header_current
 INNER JOIN red_dw.dbo.dim_matter_worktype
  ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT JOIN red_dw.dbo.fact_bill_matter
 ON fact_bill_matter.client_code = dim_matter_header_current.client_code
 AND fact_bill_matter.matter_number = dim_matter_header_current.matter_number
WHERE client_group_code='00000124'
AND reporting_exclusions=0


END 
GO
