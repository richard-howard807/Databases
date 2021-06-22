SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
	/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2021-01-29
Description:		Zurich Large Loss Tableau Dashboard
Current Version:	Initial Create
====================================================

====================================================

*/
CREATE PROCEDURE [dbo].[ZurichLargeLoss]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
	 
	 IF OBJECT_ID('tempdb..#ClientReportDates') IS NOT NULL DROP TABLE #ClientReportDates
	 IF OBJECT_ID('tempdb..#MainData') IS NOT NULL DROP TABLE #MainData

SELECT 
  dim_matter_header_current.master_client_code
 ,dim_matter_header_current.master_matter_number
 ,dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers
 ,ClientSLAs.[Initial Report SLA (days)]
 --LOGIC for Initial Report Due
, CASE 
	WHEN dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers IS NOT NULL 
	THEN [dbo].[AddWorkDaysToDate](CAST(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10))
	WHEN date_initial_report_due IS NULL 
	THEN [dbo].[AddWorkDaysToDate](CAST(dim_matter_header_current.date_opened_case_management AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10)) 
	ELSE date_initial_report_due 
	END	AS [initial_report_due]
  	, [dbo].[ReturnElapsedDaysExcludingBankHolidays] (COALESCE(grpageas_motor_date_of_receipt_of_clients_file_of_papers,date_instructions_received,dim_matter_header_current.date_opened_case_management),date_initial_report_sent) AS [Days to send initial report (working days)]
--Logic for Subsequent Report Due (Date)
, CASE 
	WHEN do_clients_require_an_initial_report = 'No' 
	THEN NULL
	WHEN RTRIM(dim_detail_core_details.present_position) 
	IN ('Final bill due - claim and costs concluded',
		'Final bill sent - unpaid',
		'To be closed/minor balances to be clear') 
	THEN NULL
	WHEN dim_detail_core_details.date_initial_report_sent IS NULL AND dim_detail_core_details.date_subsequent_sla_report_sent IS NULL 
	THEN NULL
	WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NOT NULL 
	THEN CASE 
		-- Needing to make sure future date is a weekday
		WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)) = 'Saturday' THEN
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)+2
		WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)) = 'Sunday' THEN
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)+1
		ELSE 
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)
	END
	WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NULL 
	THEN CASE 
		 --Needing to make sure future date is a weekday
		WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)) = 'Saturday' THEN
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)+2
		WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)) = 'Sunday' THEN
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)+1
		ELSE 
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)
	END
	ELSE NULL
	END	AS [date_subsequent_report_due]
	,date_subsequent_sla_report_sent AS [Date Subsequent SLA Report Sent]

INTO #ClientReportDates

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
		AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days AS days ON days.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN Reporting.dbo.ClientSLAs ON [Client Name]=client_name COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key

WHERE 
	reporting_exclusions = 0
	AND  dim_client.client_group_name='Zurich'
	AND hierarchylevel3hist = 'Large Loss'
	--AND date_opened_case_management >= '2019-01-01'
	--AND hierarchylevel2hist = 'Legal Ops - Claims'
	AND (date_claim_concluded IS NULL 
	OR date_claim_concluded >= '2019-01-01')
	AND red_dw.dbo.dim_detail_core_details.will_total_gross_reserve_on_the_claim_exceed_500000 = 'Yes' 
	--AND dim_client.client_code = 'Z1001' AND dim_matter_header_current.matter_number = '00079750'
					
--=========================================================================================================================================================================================================================================================================
--=========================================================================================================================================================================================================================================================================


SELECT 
	dim_client.client_name AS [Client Name]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS [Mattersphere Weightmans Reference]
	, name AS [Matter Owner]
	, [dbo].[ReturnElapsedDaysExcludingBankHolidays](COALESCE(#ClientReportDates.grpageas_motor_date_of_receipt_of_clients_file_of_papers,date_instructions_received,dim_matter_header_current.date_opened_case_management),date_initial_report_sent) AS [Days to send initial report (working days)]
	, dim_detail_core_details.date_initial_report_sent
	, date_instructions_received AS [Date Instructions Received]
, CASE
	WHEN  [Days to send initial report (working days)] >10 THEN 'SLA Not Met' 	--10 WORKING DAYS IS THE ZURICH SLA
	WHEN do_clients_require_an_initial_report = 'No' THEN 'Report Not Required'
	WHEN dim_detail_core_details.date_initial_report_sent IS NULL THEN 'No Date' --NOT GOT A DATE = 3
	ELSE 'SLA Met'
	END	AS [Initial Report SLA Status]
	, dim_detail_core_details.present_position AS [Present Position]
	--, CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END AS [Days to File Opened from Date Instructions Received]
	, do_clients_require_an_initial_report AS [Do Clients Require an Initial Report?]
	, dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers] AS [Date Receipt of File Papers]
	, [ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an Extension?]
	--, CASE WHEN do_clients_require_an_initial_report = 'No' THEN NULL
	--	WHEN date_initial_report_sent IS NOT NULL THEN NULL
	--	WHEN date_initial_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(CASE WHEN grpageas_motor_date_of_receipt_of_clients_file_of_papers> date_opened_case_management THEN grpageas_motor_date_of_receipt_of_clients_file_of_papers ELSE date_opened_case_management END , GETDATE())
	--	WHEN date_initial_report_sent IS NULL AND dbo.ReturnElapsedDaysExcludingBankHolidays(CASE WHEN grpageas_motor_date_of_receipt_of_clients_file_of_papers> date_opened_case_management THEN grpageas_motor_date_of_receipt_of_clients_file_of_papers ELSE date_opened_case_management END , GETDATE())<[Initial Report SLA (days)] THEN 'Not yet due'
	--	ELSE NULL END AS [Days without Initial Report]
	, date_subsequent_sla_report_sent AS [Date Subsequent SLA Report Sent]
	,  #ClientReportDates.[date_subsequent_report_due]
	, CASE
	--WHEN red_dw.dbo.dim_detail_core_details.date_subsequent_sla_report_sent IS NULL AND #ClientReportDates.date_subsequent_report_due IS null THEN 0 -- no date
	WHEN #ClientReportDates.date_subsequent_report_due IS NOT NULL AND date_subsequent_sla_report_sent IS NULL THEN 3
		WHEN #ClientReportDates.date_subsequent_report_due < dim_detail_core_details.date_subsequent_sla_report_sent THEN
			1
		ELSE 
			0
	  END	AS [Subsequent Report is Overdue]
	  	, [dbo].[ReturnElapsedDaysExcludingBankHolidays](#ClientReportDates.date_subsequent_report_due,date_subsequent_sla_report_sent) AS [Days to send Subsequent report (working days)]
	  , DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, ISNULL(dim_detail_outcome.date_claim_concluded, dim_matter_header_current.date_closed_case_management)) AS [Lifecycle (date opened to date concluded)]
	  , red_dw.dbo.dim_detail_core_details.referral_reason AS [Referral Reason]
	  , red_dw.dbo.dim_date.calendar_date
	  ,red_dw.dbo.dim_date.current_fin_year
	,dim_detail_outcome.date_claim_concluded
 ,CASE WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) >= CAST(DATEADD(YEAR, -1, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE)
	AND CAST(dim_matter_header_current.date_opened_case_management AS DATE)<= CAST(DATEADD(YEAR, -1,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME)) AS DATE) THEN 'prioryear'
	WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) >= CAST(DATEADD(YEAR, 0, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE) and
	CAST(dim_matter_header_current.date_opened_case_management AS DATE)<= CAST(DATEADD(YEAR, 0,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME))AS DATE) then 'currentyear' ELSE NULL END [YearFilter] 
	,dim_matter_header_current.date_opened_case_management
,CASE WHEN CAST(date_claim_concluded AS DATE) >= CAST(DATEADD(YEAR, -1, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE)
	AND CAST(date_claim_concluded AS DATE)<= CAST(DATEADD(YEAR, -1,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME)) AS DATE) THEN 'prioryear'
	WHEN CAST(date_claim_concluded AS DATE) >= CAST(DATEADD(YEAR, 0, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE) and
	CAST(date_claim_concluded AS DATE)<= CAST(DATEADD(YEAR, 0,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME))AS DATE) then 'currentyear' ELSE NULL END [YearFilterConcluded] 
,CASE WHEN CAST(date_costs_settled AS DATE) >= CAST(DATEADD(YEAR, -1, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE)
	AND CAST(date_costs_settled AS DATE)<= CAST(DATEADD(YEAR, -1,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME)) AS DATE) THEN 'prioryear'
	WHEN CAST(date_costs_settled AS DATE) >= CAST(DATEADD(YEAR, 0, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE) and
	CAST(date_costs_settled AS DATE)<= CAST(DATEADD(YEAR, 0,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME))AS DATE) then 'currentyear' ELSE NULL END [YearFilterCostSettled] 

	,CASE WHEN CAST(fact_matter_summary_current.last_bill_date AS DATE) >= CAST(DATEADD(YEAR, -1, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE)
	AND CAST(fact_matter_summary_current.last_bill_date AS DATE)<= CAST(DATEADD(YEAR, -1,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME)) AS DATE) THEN 'prioryear'
	WHEN CAST(fact_matter_summary_current.last_bill_date AS DATE) >= CAST(DATEADD(YEAR, 0, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE) and
	CAST(fact_matter_summary_current.last_bill_date AS DATE)<= CAST(DATEADD(YEAR, 0,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME))AS DATE) then 'currentyear' ELSE NULL END [YearFilterDateofLastBill] 

 ,CASE WHEN dim_matter_header_current.reporting_exclusions=0
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_matter_header_current.date_opened_case_management >= '2019-01-01'
		AND LOWER(referral_reason) LIKE '%dispute%'
		AND suspicion_of_fraud ='No'
		--AND work_type_group IN ('EL','PL All','Motor','Disease') 
		AND (DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management, GETDATE())>=14 OR totalpointscalc IS NOT null)
		THEN 1 ELSE 0 END AS [Number of Matters]
		, CASE WHEN totalpointscalc IS NOT NULL THEN 1 ELSE 0 END AS [countscore]
	,red_dw.dbo.fact_finance_summary.damages_paid
	,red_dw.dbo.fact_finance_summary.total_damages_and_tp_costs_reserve
	,red_dw.dbo.fact_finance_summary.total_tp_costs_paid
	,red_dw.dbo.fact_finance_summary.defence_costs_billed
	,CASE WHEN fact_finance_summary.damages_paid IS NULL OR fact_finance_summary.total_tp_costs_paid IS NULL THEN NULL ELSE ISNULL(damages_paid,0)-ISNULL(total_tp_costs_paid,0) END AS [Damages - Costs Paid]
	,red_dw.dbo.dim_matter_header_current.final_bill_flag
	,fact_finance_summary.total_reserve
	,red_dw.dbo.fact_finance_summary.total_tp_costs_paid + red_dw.dbo.fact_finance_summary.damages_paid + red_dw.dbo.fact_finance_summary.defence_costs_billed	 AS  [Total Paid] 
	,red_dw.dbo.fact_finance_summary.total_recovery
	,(ISNULL(red_dw.dbo.fact_finance_summary.total_tp_costs_paid,0) + ISNULL(red_dw.dbo.fact_finance_summary.damages_paid,0) + ISNULL(red_dw.dbo.fact_finance_summary.defence_costs_billed,0))-ISNULL(red_dw.dbo.fact_finance_summary.total_recovery,0) AS Savings
	,dim_matter_worktype.work_type_group AS [Matter Type Group]
	,dim_detail_client.zurich_date_introductory_call
	,dim_detail_core_details.zurich_introductory_call
	,dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers
	,( SELECT MAX(v)FROM(VALUES(dim_matter_header_current.date_opened_case_management), (dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers)) AS value(v)) AS MaxValue
	,CASE WHEN dim_detail_client.zurich_date_introductory_call IS NULL THEN 1 ELSE 0 END AS CountPhoneCallNotComplete
	,fact_finance_summary.claimants_costs_paid
	,total_amount_billed
	,CAST(dim_matter_header_current.date_closed_case_management AS DATE) AS [Date Closed]
	, CASE 
	WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL  
	THEN 1
	WHEN RTRIM(dim_detail_core_details.present_position) 
	IN ('Final bill due - claim and costs concluded',
		'Final bill sent - unpaid',
		'To be closed/minor balances to be clear') 
	THEN 1
	ELSE 0
	END AS FILTER
	,dim_detail_outcome.repudiation_outcome
	, ISNULL(damages_paid,0) + ISNULL(claimants_costs_paid,0)	+ ISNULL(total_amount_billed,0) -ISNULL(vat_billed,0)   AS [Indemnity Spend]
	,vat_billed

INTO #MainData
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
	AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days AS days ON days.master_fact_key = fact_dimension_main.master_fact_key
--LEFT OUTER JOIN #FICProcess FICProcess ON FICProcess.fileID = ms_fileid
LEFT OUTER JOIN Reporting.dbo.ClientSLAs ON [Client Name]=client_name COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN #ClientReportDates ON #ClientReportDates.master_client_code = dim_matter_header_current.master_client_code AND #ClientReportDates.master_matter_number = dim_matter_header_current.master_matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_date	ON 	dim_open_case_management_date_key	 = dim_date.dim_date_key
LEFT OUTER JOIN red_dw.dbo.ds_sh_ms_udficmotor ON ds_sh_ms_udficmotor.fileid = dim_matter_header_current.ms_fileid
LEFT OUTER JOIN red_dw.dbo.ds_sh_ms_udficcommon ON 	 ds_sh_ms_udficmotor.fileid = ds_sh_ms_udficcommon.fileid
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key




WHERE 
	reporting_exclusions=0
	AND  dim_client.client_group_name='Zurich'
	AND hierarchylevel3hist = 'Large Loss'
	--AND date_opened_case_management >= '2019-02-01'
	AND (date_claim_concluded IS NULL 
	OR date_claim_concluded>='2019-02-01')
	AND (dim_detail_outcome.outcome_of_case IS NULL OR RTRIM(LOWER(dim_detail_outcome.outcome_of_case)) <> 'exclude from reports')
	--AND (dim_detail_client.zurich_data_admin_exclude_from_reports IS NULL OR RTRIM(LOWER(dim_detail_client.zurich_data_admin_exclude_from_reports)) <> 'yes')
	--AND red_dw.dbo.dim_detail_core_details.will_total_gross_reserve_on_the_claim_exceed_500000 = 'Yes'
	AND	  fact_finance_summary.damages_reserve >=150000 
	--AND dim_matter_header_current.master_client_code = 'Z1001' AND dim_matter_header_current.master_matter_number = '15025'

SELECT 
[Client Name]
, [Mattersphere Weightmans Reference]
, [Matter Owner]
, [Days to send initial report (working days)]
, date_initial_report_sent
, [Date Instructions Received]
, [Initial Report SLA Status]
, [Present Position]
, [Do Clients Require an Initial Report?]
, [Date Receipt of File Papers]
, [Have we had an Extension?]
, [Date Subsequent SLA Report Sent]
, [date_subsequent_report_due]
, [Subsequent Report is Overdue]
, [Days to send Subsequent report (working days)]
, [Lifecycle (date opened to date concluded)]
, [Referral Reason]
, calendar_date
, current_fin_year
, date_claim_concluded
, [YearFilter] 
, [YearFilterConcluded] 
, [YearFilterCostSettled]
, [YearFilterDateofLastBill] 
, [Number of Matters]
, [countscore]
, damages_paid
, total_damages_and_tp_costs_reserve
, total_tp_costs_paid
, defence_costs_billed
, [Damages - Costs Paid]
, final_bill_flag
, (total_reserve	-Savings)/total_reserve	AS [Total Reserve %]
, [Total Paid] 
, total_recovery
, Savings
, total_reserve
, [Matter Type Group]
, DATEDIFF(DAY,  MaxValue ,zurich_date_introductory_call ) AS [Days between Date Opened and phone call date or receipt of client file of papers (whichever is later) ] 
, zurich_date_introductory_call
--, zurich_introductory_call
, grpageas_motor_date_of_receipt_of_clients_file_of_papers
, #MainData.date_opened_case_management
, CountPhoneCallNotComplete
, claimants_costs_paid
, total_amount_billed	- vat_billed  AS [total_amount_billed]
, [Date Closed]
, FILTER AS [Filter Date of Last Bill]
, repudiation_outcome
, [Indemnity Spend]
,vat_billed

FROM #MainData

   END

 
GO
