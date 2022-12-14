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
-- 2018/08/14 commented out duplicate columns
====================================================

*/
CREATE PROCEDURE [dbo].[ZurichLargeLoss]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
	 
	 IF OBJECT_ID('tempdb..#ClientReportDates') IS NOT NULL DROP TABLE #ClientReportDates

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
	THEN [dbo].[AddWorkDaysToDate](CAST(date_opened_case_management AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10)) 
	ELSE date_initial_report_due 
	END	AS [initial_report_due]
  	, [dbo].[ReturnElapsedDaysExcludingBankHolidays] (COALESCE(grpageas_motor_date_of_receipt_of_clients_file_of_papers,date_instructions_received,date_opened_case_management),date_initial_report_sent) AS [Days to send initial report (working days)]
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
	AND date_opened_case_management >= '2019-05-01'
	--AND hierarchylevel2hist = 'Legal Ops - Claims'
	AND (date_closed_case_management IS NULL 
	OR date_closed_case_management >= '2019-05-01')
	--AND dim_client.client_code = 'Z1001' AND dim_matter_header_current.matter_number = '00079750'
					
--=========================================================================================================================================================================================================================================================================
--=========================================================================================================================================================================================================================================================================


SELECT 
	dim_client.client_name AS [Client Name]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS [Mattersphere Weightmans Reference]
	, name AS [Matter Owner]
	, [dbo].[ReturnElapsedDaysExcludingBankHolidays](COALESCE(#ClientReportDates.grpageas_motor_date_of_receipt_of_clients_file_of_papers,date_instructions_received,date_opened_case_management),date_initial_report_sent) AS [Days to send initial report (working days)]
	, dim_detail_core_details.date_initial_report_sent
	, date_instructions_received AS [Date Instructions Received]
, CASE
	WHEN  [Days to send initial report (working days)] >10 THEN 'SLA Not Met' 	--10 WORKING DAYS IS THE ZURICH SLA
	WHEN do_clients_require_an_initial_report = 'No' THEN 'Report Not Required'
	WHEN dim_detail_core_details.date_initial_report_sent IS NULL THEN 'No Date' --NOT GOT A DATE = 3
	ELSE 'SLA Met'
	END	AS [Initial Report SLA Status]
	, CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS [Status]
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
	  , DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, ISNULL(dim_detail_outcome.date_claim_concluded, dim_matter_header_current.date_closed_case_management)) AS [Lifecycle (date opened to date concluded)]
	  , red_dw.dbo.dim_detail_core_details.referral_reason AS [Referral Reason]
	  , red_dw.dbo.dim_date.calendar_date
	  ,red_dw.dbo.dim_date.current_fin_year



--INTO Reporting.dbo.ClaimsSLAComplianceTable
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
WHERE 
	reporting_exclusions=0
	AND  dim_client.client_group_name='Zurich'
	AND hierarchylevel3hist = 'Large Loss'
	AND date_opened_case_management >= '2019-05-01'
	AND (date_closed_case_management IS NULL 
	OR date_closed_case_management>='2019-05-01')
	AND (dim_detail_outcome.outcome_of_case IS NULL OR RTRIM(LOWER(dim_detail_outcome.outcome_of_case)) <> 'exclude from reports')
	AND (dim_detail_client.zurich_data_admin_exclude_from_reports IS NULL OR RTRIM(LOWER(dim_detail_client.zurich_data_admin_exclude_from_reports)) <> 'yes')



   END
GO
