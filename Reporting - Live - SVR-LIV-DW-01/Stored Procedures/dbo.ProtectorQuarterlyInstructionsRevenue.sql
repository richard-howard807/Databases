SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ProtectorQuarterlyInstructionsRevenue]

AS 

BEGIN 
SELECT dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
, (
           SELECT fin_year
           FROM red_dw..dim_date WITH(NOLOCK)
           WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)
) AS [Fin Year Opened]
,(
           SELECT fin_quarter_no
           FROM red_dw..dim_date WITH(NOLOCK)
           WHERE dim_date.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)
)  AS [Quarter Opened]
,dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
,RTRIM([master_client_code]) + '-' + [master_matter_number] AS [Weightmans Reference]
,matter_description AS [Matter Description]
,name AS [Matter Owner]
,hierarchylevel4hist AS [Team]
,work_type_name AS [Matter Type]
,work_type_group AS [Matter Type Group]
,client_name AS [Client Name]
,dim_detail_core_details.[present_position] AS [Present Position]
,dim_detail_core_details.[date_instructions_received] AS [Date Instructions Received]
,dim_detail_core_details.[referral_reason] AS [Referral Reason]
,dim_detail_core_details.[injury_type] AS [Description of Injury]
,dim_detail_core_details.[incident_date] AS [Incident Date]
,fact_finance_summary.[damages_reserve] AS [Damages Reserve Current ]
,fact_detail_reserve_detail.[current_indemnity_reserve] AS [Claimant Costs Reserve Current ]
,fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve Current]
,dim_detail_outcome.[outcome_of_case] AS [Outcome of Case]
,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
,fact_finance_summary.[damages_paid] AS [Damages Paid by Client ]
,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
,fact_finance_summary.[claimants_costs_paid] AS [Total third party costs paid]
,Financials.[Total Billed] AS [Total Bill Amount - Composite (IncVAT )]
,Financials.[Revenue Billed] AS [Revenue Costs Billed]
,Financials.[Disbursements Billed] AS [Disbursements Billed]
,Financials.[Vat Billed] AS [VAT Billed]
,Financials.LastBillDate AS [Last Bill Date Composite]
,last_time_transaction_date AS [Date of Last Time Posting]
,[Revenue Q1 2020/2021]
,[Revenue Q2 2020/2021]
,[Revenue Q3 2020/2021]
,[Revenue Q4 2020/2021]
,[Revenue Q1 2021/2022]
,[Revenue Q2 2021/2022]
,[Revenue Q3 2021/2022]
,[Revenue Q4 2021/2022]
FROM dbo.ProtectorMatters
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = ProtectorMatters.dim_matter_header_curr_key
LEFT OUTER	 JOIN red_dw.dbo.dim_fed_hierarchy_history ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(

 SELECT fact_bill.dim_matter_header_curr_key,MAX(bill_date) AS LastBillDate
 ,SUM(bill_total) AS [Total Billed]
 ,SUM(fees_total) AS [Revenue Billed]
 ,SUM(paid_disbursements) + SUM(unpaid_disbursements) AS [Disbursements Billed]
 ,SUM(vat_amount) AS [Vat Billed]
 ,SUM(CASE WHEN bill_fin_year='2021' AND bill_fin_quarter_no=1 THEN fees_total ELSE 0 END) AS [Revenue Q1 2020/2021]
 ,SUM(CASE WHEN bill_fin_year='2021' AND bill_fin_quarter_no=2 THEN fees_total ELSE 0 END) AS [Revenue Q2 2020/2021]
 ,SUM(CASE WHEN bill_fin_year='2021' AND bill_fin_quarter_no=3 THEN fees_total ELSE 0 END) AS [Revenue Q3 2020/2021]
 ,SUM(CASE WHEN bill_fin_year='2021' AND bill_fin_quarter_no=4 THEN fees_total ELSE 0 END) AS [Revenue Q4 2020/2021]
 ,SUM(CASE WHEN bill_fin_year='2022' AND bill_fin_quarter_no=1 THEN fees_total ELSE 0 END) AS [Revenue Q1 2021/2022]
 ,SUM(CASE WHEN bill_fin_year='2022' AND bill_fin_quarter_no=2 THEN fees_total ELSE 0 END) AS [Revenue Q2 2021/2022]
 ,SUM(CASE WHEN bill_fin_year='2022' AND bill_fin_quarter_no=3 THEN fees_total ELSE 0 END) AS [Revenue Q3 2021/2022]
 ,SUM(CASE WHEN bill_fin_year='2022' AND bill_fin_quarter_no=4 THEN fees_total ELSE 0 END) AS [Revenue Q4 2021/2022]
 FROM red_dw.dbo.fact_bill
 INNER JOIN red_dw.dbo.dim_matter_header_current
  ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
INNER JOIN dbo.ProtectorMatters ON ProtectorMatters.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 INNER JOIN red_dw.dbo.dim_bill
  ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
WHERE bill_reversed=0
GROUP BY fact_bill.dim_matter_header_curr_key
) AS Financials
 ON Financials.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current 
 ON  fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 END 
GO
