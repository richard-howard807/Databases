SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[NHSRevenueCasesCreatedPre2018]

AS 

BEGIN

SELECT master_client_code + '-' + master_matter_number AS [Mattersphere Ref]
,matter_owner_full_name AS [Matter Owner]
,dim_matter_worktype.work_type_name AS [Matter Type]
,defendant_trust AS [Trust]
,branch_name AS [Office]
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
,fact_finance_summary.[damages_reserve]
,outcome_of_case AS [Outcome]
,dim_detail_core_details.present_position AS [Present Position]
,dim_detail_core_details.referral_reason AS [Referral Reason]
,dim_detail_health.[nhs_scheme] AS [Scheme]
,dim_detail_health.[nhs_instruction_type] AS [Instruction Type]
,Revenue.FeesTotal AS [Revenue Billed]
,TotalRevenue AS TotalRevenueCheck
,defence_costs_billed_composite
,Revenue.LastBillDateComp AS [Last Bill Date]
,		   CASE WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
THEN 'Clinical'

WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
THEN 'Non-Clinical'
WHEN dim_detail_health.nhs_scheme = 'LOT 3 work' THEN 'Other' END AS [NHS Matter Type],


CASE WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) = 0 THEN '£0'


 WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) BETWEEN 1 AND 50000 THEN '£1-£50,000'


 WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) BETWEEN 50001 AND 250000 THEN '£50,001-£250,000'

 WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) BETWEEN 250001 AND 500000 THEN '£250,001-£500,000'

 WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) BETWEEN 500001 AND 1000000 THEN '£500,001-£1,000,000'

 WHEN dim_detail_health.nhs_scheme IN
(
'CNSGP',
'CNST',
'DH CL',
'ELS',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'Inquest Funding                                             ',
'Inquest funding'
)
AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) > 1000000 THEN '£1,000,001+'





WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve) = 0 THEN '£0'



 

WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)BETWEEN 1 AND 5001 THEN '£1-£5,001'


  

WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)BETWEEN 5001 AND 10000 THEN '£5,001-£10,000'

 WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)BETWEEN 10001 AND 25000 THEN '£10,0001-£25,0001'

  WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)BETWEEN 25001 AND 50001 THEN '£25,001-£50,001'

   WHEN 

dim_detail_health.nhs_scheme IN
(
'DH Liab',
'LTPS',
'PES'
)
 AND COALESCE(fact_finance_summary.damages_paid,fact_finance_summary.damages_reserve)> 50001 THEN '£50,0001+'


 END  AS [NHSR Tranche] 
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
 ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON dim_matter_header_current.client_code= fact_finance_summary.client_code
 AND red_dw.dbo.dim_matter_header_current.matter_number=fact_finance_summary.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
 ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_matter_header_current.client_code= dim_client_involvement.client_code
 AND red_dw.dbo.dim_matter_header_current.matter_number=dim_client_involvement.matter_number
LEFT OUTER JOIN (
SELECT dim_matter_header_current.dim_matter_header_curr_key
,MAX(dim_bill_date.bill_date) AS LastBillDateComp
,SUM(bill_total) - SUM(vat) AS [TotalBilled]
,SUM(fees_total) AS FeesTotal
FROM red_dw.dbo.fact_bill_matter_detail_summary
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = fact_bill_matter_detail_summary.client_code
 AND dim_matter_header_current.matter_number = fact_bill_matter_detail_summary.matter_number
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill_matter_detail_summary.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_matter_detail_summary.dim_bill_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE work_type_group='NHSLA'
AND bill_reversed=0
GROUP BY dim_matter_header_current.dim_matter_header_curr_key
) AS Revenue
ON Revenue.dim_matter_header_curr_key = dim_detail_court.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT dim_detail_core_details.dim_matter_header_curr_key
,SUM(time_charge_value) AS TotalRevenue
,SUM(CASE WHEN time_activity_code NOT LIKE 'CB%' THEN time_charge_value ELSE 0 END) AS [Revenue Exc CB]
,SUM(CASE WHEN time_activity_code NOT LIKE 'CB%' AND CONVERT(DATE,transaction_calendar_date,103)>=CONVERT(DATE,ISNULL(date_proceedings_issued,date_opened_case_management),103) THEN time_charge_value ELSE 0 END) AS [Revenue Recorded on/after Issue Ex CB]
,SUM(CASE WHEN time_activity_code NOT LIKE 'CB%' AND CONVERT(DATE,transaction_calendar_date,103)<=CONVERT(DATE,date_claim_concluded,103) THEN time_charge_value ELSE 0 END)AS [Revenue Recordered up to Concluded]
,SUM(CASE WHEN time_activity_code NOT LIKE 'CB%' AND CONVERT(DATE,transaction_calendar_date,103) >=CONVERT(DATE,ISNULL(date_proceedings_issued,date_opened_case_management),103) AND  CONVERT(DATE,transaction_calendar_date,103)<=CONVERT(DATE,date_claim_concluded,103) THEN time_charge_value ELSE 0 END)AS [Revenue Recorded between issue and concluded]

FROM red_dw.dbo.fact_bill_billed_time_activity
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_billed_time_activity.dim_bill_key
INNER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_transaction_date
 ON dim_transaction_date.dim_transaction_date_key = fact_bill_billed_time_activity.dim_transaction_date_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE work_type_group='NHSLA'

AND bill_reversed=0
GROUP BY dim_detail_core_details.dim_matter_header_curr_key
) AS RevenueWithDates
 ON RevenueWithDates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN 
(
SELECT dim_matter_header_current.dim_matter_header_curr_key
,SUM(bill_total_excl_vat) AS DisbAmount
,SUM(CASE WHEN  CONVERT(DATE,transaction_calendar_date,103)>=CONVERT(DATE,ISNULL(date_proceedings_issued,date_opened_case_management),103) THEN bill_total_excl_vat ELSE 0 END) AS [Disbs Recorded on/after Issue]
,SUM(CASE WHEN  CONVERT(DATE,transaction_calendar_date,103)<=CONVERT(DATE,date_claim_concluded,103) THEN bill_total_excl_vat ELSE 0 END)AS [Disbs Recordered up to Concluded]
,SUM(CASE WHEN  CONVERT(DATE,transaction_calendar_date,103)>=CONVERT(DATE,ISNULL(date_proceedings_issued,date_opened_case_management),103) AND  CONVERT(DATE,transaction_calendar_date,103)<=CONVERT(DATE,date_claim_concluded,103) THEN bill_total_excl_vat ELSE 0 END)AS [Disbs between issue and concluded]

FROM red_dw.dbo.fact_bill_detail WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current 
 ON client_code_bill_item=dim_matter_header_current.client_code
 AND matter_number_bill_item=dim_matter_header_current.matter_number
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill WITH(NOLOCK)
 ON dim_bill.dim_bill_key = fact_bill_detail.dim_bill_key
INNER JOIN red_dw.dbo.fact_bill WITH(NOLOCK)
 ON fact_bill.dim_bill_key = fact_bill_detail.dim_bill_key
INNER JOIN red_dw.dbo.dim_transaction_date
 ON dim_transaction_date.dim_transaction_date_key = fact_bill_detail.dim_transaction_date_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
 ON dim_bill_date.dim_bill_date_key = fact_bill_detail.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_cost_type ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
WHERE work_type_group='NHSLA'
AND  fact_bill_detail.charge_type='disbursements'
AND bill_reversed=0
GROUP BY dim_matter_header_current.dim_matter_header_curr_key
)  AS Disbs
ON Disbs.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key


WHERE work_type_group='NHSLA'
AND master_client_code='N1001'
AND ISNULL(dim_detail_health.nhs_scheme,'') NOT IN
(
'DH Liab',
'LTPS',
'PES',
'ELSGP',
'ELSGP (MDDUS)',
'ELSGP (MPS)',
'CNSGP'
)
AND date_opened_case_management<'2018-01-01'
AND master_client_code <>'30645'

END
GO
