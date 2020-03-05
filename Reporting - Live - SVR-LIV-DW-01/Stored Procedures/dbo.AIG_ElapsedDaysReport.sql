SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2017-11-21
Description:		New report to look at elapsed days for AIG matters - ticket 273396
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [dbo].[AIG_ElapsedDaysReport] --@StartDate = '2017-11-01', @EndDate = '2017-11-30'
(
@StartDate as date,
@EndDATE as date
)



AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT  
RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
, fact_dimension_main.client_code
, fact_dimension_main.matter_number
, dim_fed_hierarchy_history.name AS [Fee Earner]
, dim_fed_hierarchy_history.[hierarchylevel3hist] AS [Department]
, dim_fed_hierarchy_history.[hierarchylevel4hist] AS [Team]
, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
, dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
, detail_outcome.date_claim_concluded
, detail_outcome.date_costs_settled
, client_name
, client_group_name
, matter_description
, matter_owner_full_name
, receipts.receipt_date as [LastReceiptDate]
, billdate.bill_date [LastBillDate]
, dim_instruction_type.instruction_type AS [Instruction Type]
, dim_detail_client.aig_litigation_number
, core_details.date_instructions_received AS [Date Instructions Received]
, datepart(YEAR,dim_matter_header_current.date_closed_case_management) YearClosed
, datepart(MONTH,dim_matter_header_current.date_closed_case_management) MonthClosed
,CASE WHEN DATEPART(mm,dim_matter_header_current.date_closed_case_management)<=3 THEN 'Qtr1'
	WHEN DATEPART(mm,dim_matter_header_current.date_closed_case_management)<=6 THEN 'Qtr2'
	WHEN DATEPART(mm,dim_matter_header_current.date_closed_case_management)<=9 THEN 'Qtr3'
	WHEN DATEPART(mm,dim_matter_header_current.date_closed_case_management)<=12 THEN 'Qtr4'
	ELSE NULL END AS [Calendar Quarter Closed]
,CAST(dim_closed_case_management_date.closed_case_management_fin_year - 1 as varchar) + '/' + CAST(dim_closed_case_management_date.closed_case_management_fin_year as varchar) AS [Financial Year Closed] 
, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_matter_header_current.date_opened_case_management, dim_matter_header_current.date_closed_case_management) AS [Elapsed Days Open date to Closed date]
, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_matter_header_current.date_opened_case_management, detail_outcome.date_claim_concluded) AS [Elapsed Days Open date to Claim Concluded date]
, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays](dim_matter_header_current.date_opened_case_management, detail_outcome.date_costs_settled) AS [Elapsed Days Open date to Costs Settled date]
, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays](billdate.bill_date, dim_matter_header_current.date_closed_case_management) AS [Elapsed Days Last Bill to Closed date]
, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays]((receipts.receipt_date), dim_matter_header_current.date_closed_case_management) AS [Elapsed Days Last Payment to Closed date]
, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays]((billdate.bill_date), (receipts.receipt_date)) AS [Elapsed Days Last Bill to Last Payment]
, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays](detail_outcome.date_claim_concluded, (billdate.bill_date)) AS [Elapsed Days date Claim Concluded to Last Bill date]
, [Reporting].[dbo].[ReturnElapsedDaysExcludingBankHolidays](detail_outcome.date_costs_settled, (billdate.bill_date)) AS [Elapsed Days date Claim Settled to Last Bill date]


FROM red_dw..fact_dimension_main 
INNER join red_dw..dim_matter_header_current on fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key 
AND  (dim_matter_header_current.date_closed_case_management >='20140101' OR dim_matter_header_current.date_closed_case_management IS NULL)
AND dim_matter_header_current.matter_number<>'ML'
AND dim_matter_header_current.reporting_exclusions=0
left outer join red_dw..dim_fed_hierarchy_history on dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code and dim_fed_hierarchy_history.dss_current_flag = 'Y'
left outer join red_dw.[dbo].[dim_instruction_type] ON [dim_instruction_type].[dim_instruction_type_key]=dim_matter_header_current.dim_instruction_type_key
left outer join red_dw.dbo.dim_detail_client AS dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
left outer join red_dw.dbo.dim_closed_case_management_date  ON dim_closed_case_management_date.calendar_date = dim_matter_header_current.date_closed_case_management
inner join red_dw.dbo.dim_detail_outcome AS detail_outcome ON detail_outcome.dim_detail_outcome_key=fact_dimension_main .dim_detail_outcome_key
AND ISNULL(detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
left outer join red_dw.dbo.dim_detail_core_details AS core_details ON core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
left outer join 
       (
       SELECT master_fact_key,max(bill_date) AS bill_date FROM red_dw..fact_bill_matter_detail
          WHERE fact_bill_matter_detail.bill_number <> 'PURGE'
       GROUP BY master_fact_key      
       ) AS billdate
ON fact_dimension_main.master_fact_key = billdate.master_fact_key
left outer join 
       (
       SELECT dim_matter_header_curr_key,max(receipt_date) AS receipt_date FROM red_dw..fact_bill_receipts
       GROUP BY dim_matter_header_curr_key       
       ) AS receipts
ON fact_dimension_main.dim_matter_header_curr_key = receipts.dim_matter_header_curr_key 

WHERE 

fact_dimension_main.client_code IN ('00006864','00006865','00006868','00006876','00006866','00364317','00006861','A2002')
and ((dim_matter_header_current.date_closed_case_management >= @StartDate OR @StartDate is null) and  dim_matter_header_current.date_closed_case_management <=  @EndDate  OR @EndDate is null) 




END

GO
