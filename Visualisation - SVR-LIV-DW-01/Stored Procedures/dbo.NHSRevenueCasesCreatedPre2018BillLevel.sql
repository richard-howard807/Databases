SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[NHSRevenueCasesCreatedPre2018BillLevel]

AS 

BEGIN
SELECT master_client_code + '-' + master_matter_number AS [Mattersphere Ref]
,matter_owner_full_name AS [Matter Owner]
,dim_matter_worktype.work_type_name AS [Matter Type]
,defendant_trust AS [Trust]
,branch_name AS [Office]
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
,fact_finance_summary.[damages_reserve] AS [Damages Reserve]
,outcome_of_case AS [Outcome]
,dim_detail_core_details.present_position AS [Present Position]
,dim_detail_core_details.referral_reason AS [Referral Reason]
,dim_detail_health.[nhs_scheme] AS [Scheme]
,dim_detail_health.[nhs_instruction_type] AS [Instruction Type]
,dim_bill_date.bill_date AS [Bill Date]
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


 END AS [NHSR Tranche] 
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
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
 ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.client_code = dim_matter_header_current.client_code
AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
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
AND bill_reversed=0
AND date_opened_case_management<'2018-01-01'
AND master_client_code <>'30645'
GROUP BY master_client_code + '-' + master_matter_number,
         matter_owner_full_name,
         work_type_name,
         defendant_trust,
         branch_name,
         date_opened_case_management,
         date_closed_case_management,
         damages_reserve,
         outcome_of_case,
         dim_detail_core_details.present_position,
         dim_detail_core_details.referral_reason,
         nhs_scheme,
         nhs_instruction_type,
         dim_bill_date.bill_date
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
WHEN dim_detail_health.nhs_scheme = 'LOT 3 work' THEN 'Other' END ,


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


 END

		 END
GO
