SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Emily Smith
-- Create date: 2019-10-28
-- Description:	New report for Claims SLA Compliance
-- =============================================
-- ===========================================================================================================================
-- Changed SP to populate Reporting.dbo.ClaimsSLAComplianceTable instead, to speed up the report rather than running it live
-- ===========================================================================================================================

CREATE PROCEDURE [dbo].[ClaimsSLACompliance]

AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('Reporting.dbo.ClaimsSLAComplianceTable') IS NOT NULL DROP TABLE  Reporting.dbo.ClaimsSLAComplianceTable

	IF OBJECT_ID('tempdb..#FICProcess') IS NOT NULL DROP TABLE #FICProcess
	IF OBJECT_ID('tempdb..#ClientReportDates') IS NOT NULL DROP TABLE #ClientReportDates

	SELECT fileID, tskDesc, tskDue, tskCompleted 
	INTO #FICProcess
	FROM MS_Prod.dbo.dbTasks
	WHERE (tskDesc LIKE 'FIC Process'
	OR tskDesc LIKE '%ADM: Complete fraud indicator checklist%')
	AND tskActive=1;


--=========================================================================================================================================================================================================================================================================
-- table to deal with lengthy client report date logics
--=========================================================================================================================================================================================================================================================================

	SELECT 
		dim_matter_header_current.master_client_code
		, dim_matter_header_current.master_matter_number
		, CASE 
			WHEN dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers IS NOT NULL THEN 
				[dbo].[AddWorkDaysToDate](CAST(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10))
			WHEN date_initial_report_due IS NULL THEN 
				[dbo].[AddWorkDaysToDate](CAST(date_opened_case_management AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10)) 
			ELSE 
				date_initial_report_due 
			END						AS [initial_report_due]
		,  CASE 
			WHEN do_clients_require_an_initial_report = 'No' THEN
				NULL
			WHEN RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN
				NULL
			WHEN dim_detail_core_details.date_initial_report_sent IS NULL AND dim_detail_core_details.date_subsequent_sla_report_sent IS NULL THEN
				NULL
			WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NOT NULL THEN 
				CASE 
					-- Needing to make sure future date is a weekday
					WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)) = 'Saturday' THEN
						DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)+2
					WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)) = 'Sunday' THEN
						DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)+1
					ELSE 
						DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)
				END
			WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NULL THEN
				CASE 
					-- Needing to make sure future date is a weekday
					WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)) = 'Saturday' THEN
						DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)+2
					WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)) = 'Sunday' THEN
						DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)+1
					ELSE 
						DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)
				END
			ELSE 
				NULL
			END									AS [date_subsequent_report_due]
	INTO #ClientReportDates
	FROM red_dw.dbo.fact_dimension_main
		LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
			ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
			ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
			ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
			ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
				AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
		LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days AS days 
			ON days.master_fact_key = fact_dimension_main.master_fact_key
		LEFT OUTER JOIN Reporting.dbo.ClientSLAs 
			ON [Client Name]=client_name COLLATE DATABASE_DEFAULT
	WHERE 
		reporting_exclusions = 0
		AND hierarchylevel2hist = 'Legal Ops - Claims'
		AND (date_closed_case_management IS NULL 
			OR date_closed_case_management >= '2017-01-01')
					
--=========================================================================================================================================================================================================================================================================
--=========================================================================================================================================================================================================================================================================


SELECT 
	client_name AS [Client Name]
	, dim_matter_header_current.client_group_name
	, dim_matter_header_current.master_client_code
	, dim_matter_header_current.master_matter_number
	, dim_matter_header_current.client_code AS [Client Code]
	, dim_matter_header_current.matter_number AS [Matter Number]
	, matter_description AS [Matter Description]
	, name AS [Matter Owner]
	, dim_matter_header_current.fee_earner_code
	, hierarchylevel4hist AS [Team]
	, hierarchylevel3hist AS [Department]
	, CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS [Status]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number			 AS [Mattersphere Weightmans Reference]
	, dim_detail_core_details.present_position AS [Present Position]
	, date_opened_case_management AS [Date Opened]
	, date_closed_case_management AS [Date Closed]
	, date_instructions_received AS [Date Instructions Received]
	, CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END AS [Days to File Opened from Date Instructions Received]
	, date_initial_report_sent AS [Date Initial Report Sent]
	, do_clients_require_an_initial_report AS [Do Clients Require an Initial Report?]
	, dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers] AS [Date Receipt of File Papers]
	, [ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an Extension?]
	, #ClientReportDates.initial_report_due				AS [Date Initial Report Due (if extended)]
	, dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent) AS [Days to Send Intial Report]
	, CASE WHEN do_clients_require_an_initial_report = 'No' THEN NULL
		WHEN date_initial_report_sent IS NOT NULL THEN NULL
		WHEN date_initial_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(CASE WHEN grpageas_motor_date_of_receipt_of_clients_file_of_papers> date_opened_case_management THEN grpageas_motor_date_of_receipt_of_clients_file_of_papers ELSE date_opened_case_management END , GETDATE())
		WHEN date_initial_report_sent IS NULL AND dbo.ReturnElapsedDaysExcludingBankHolidays(CASE WHEN grpageas_motor_date_of_receipt_of_clients_file_of_papers> date_opened_case_management THEN grpageas_motor_date_of_receipt_of_clients_file_of_papers ELSE date_opened_case_management END , GETDATE())<[Initial Report SLA (days)] THEN 'Not yet due'
		ELSE NULL END AS [Days without Initial Report]
	, date_subsequent_sla_report_sent AS [Date Subsequent SLA Report Sent]
	, CASE 
		WHEN do_clients_require_an_initial_report = 'No' OR
						RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN
			NULL
		WHEN date_subsequent_sla_report_sent IS NULL THEN 
			dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, GETDATE())
		WHEN date_subsequent_sla_report_sent IS NOT NULL THEN 
			dbo.ReturnElapsedDaysExcludingBankHolidays(date_subsequent_sla_report_sent, GETDATE())
		ELSE
			NULL
	  END				AS [Days without Subsequent Report]
	, 1					AS [Number of Files]
	,CASE WHEN dim_detail_core_details.date_initial_report_sent IS NULL THEN NULL ELSE days.days_to_first_report_lifecycle END AS avglifecycle 
	, days.days_to_first_report_lifecycle
	,dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud?]
	,FICProcess.tskDue
	,FICProcess.tskCompleted
	,FICProcess.tskDesc
	--Client SLA's
	, [File Opening SLA (days)]
	, ISNULL(ClientSLAs.[File Opening SLA (days)], 2)		AS [File Opening SLA hidden on report for highlighting]
	, [Initial Report SLA (days)]
	, ISNULL(ClientSLAs.[Initial Report SLA (days)], 10)	AS [Initial Report SLA hidden on report for highlighting]
	, ClientSLAs.[Update Report SLA]
	, ClientSLAs.[Update Report SLA (working days)]
	, ISNULL(ClientSLAs.[Update Report SLA (working days)], 63)		AS [Update Report SLA hidden on report for highlighting]
	, CASE 
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END) <0 THEN 
				'Transparent'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END) <= ISNULL([File Opening SLA (days)], 2) THEN 
				'LimeGreen'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END) > ISNULL([File Opening SLA (days)], 2) THEN 
				'Red'
			ELSE 
				'Transparent' 
	  END					AS [File Opening RAG]
	, CASE 
			WHEN date_initial_report_sent IS NULL AND 
				dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS  DATE), #ClientReportDates.initial_report_due) BETWEEN 0 AND 5 THEN
				'Orange'
			WHEN (days.days_to_first_report_lifecycle) < 0 THEN 
				'Transparent'
			WHEN (days.days_to_first_report_lifecycle) <= ISNULL([Initial Report SLA (days)], 10) THEN 
				'LimeGreen'
			WHEN (days.days_to_first_report_lifecycle) > ISNULL([Initial Report SLA (days)], 10) THEN 
				'Red'
			ELSE 
				'Transparent' 
		END					AS [NEW Initial Report RAG]
	, CASE 
		WHEN dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS DATE), #ClientReportDates.date_subsequent_report_due) BETWEEN 0 AND 10 THEN
			'Orange'
		WHEN (CASE 
					WHEN do_clients_require_an_initial_report = 'No' OR
									RTRIM(dim_detail_core_details.present_position) IN (
																					'Final bill due - claim and costs concluded',
																					'Final bill sent - unpaid',
																					'To be closed/minor balances to be clear'            
																				) THEN
						NULL
					WHEN date_subsequent_sla_report_sent IS NULL THEN 
						dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, GETDATE())
					WHEN date_subsequent_sla_report_sent IS NOT NULL THEN 
						dbo.ReturnElapsedDaysExcludingBankHolidays(date_subsequent_sla_report_sent, GETDATE())
					ELSE
						NULL
				END) < 0 THEN
			'Transparent'
		WHEN #ClientReportDates.date_subsequent_report_due < CAST(GETDATE() AS DATE) THEN 
			'Red'
		WHEN #ClientReportDates.date_subsequent_report_due IS NULL THEN
			'Transparent'
		ELSE
			'LimeGreen'
	  END								 AS RagWithouthSub
	,referral_reason
	, dim_detail_core_details.delegated
	, CASE 
		WHEN do_clients_require_an_initial_report = 'No' OR
						RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN
			0
		WHEN date_initial_report_sent IS NULL AND 
				dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS  DATE), #ClientReportDates.initial_report_due) BETWEEN 0 AND 5 THEN
			1
		ELSE 
			0
	  END										AS [Count Initial Report Due In 5 Working Days]
	, CASE 
		WHEN do_clients_require_an_initial_report = 'No' OR 
						RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN 
			0
		WHEN dim_detail_core_details.date_initial_report_sent IS NULL 
			AND #ClientReportDates.initial_report_due < CAST(GETDATE() AS DATE) THEN
			1
		ELSE 
			0
	  END										AS [Count Initial Report Is Overdue]
	, #ClientReportDates.date_subsequent_report_due			AS [Date Subsequent Report Due]
	, CASE 
		WHEN dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS DATE), #ClientReportDates.date_subsequent_report_due) BETWEEN 0 AND 10 THEN
			1
		ELSE 
			0
	  END				AS [Subsequent Report Due in 10 Working Days]
	, CASE 
		WHEN #ClientReportDates.date_subsequent_report_due < CAST(GETDATE() AS DATE) THEN
			1
		ELSE 
			0
	  END				AS [Subsequent Report is Overdue]

INTO Reporting.dbo.ClaimsSLAComplianceTable
FROM red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days AS days 
		ON days.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN #FICProcess FICProcess 
		ON FICProcess.fileID = ms_fileid
	LEFT OUTER JOIN Reporting.dbo.ClientSLAs 
		ON [Client Name]=client_name COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN #ClientReportDates
		ON #ClientReportDates.master_client_code = dim_matter_header_current.master_client_code AND #ClientReportDates.master_matter_number = dim_matter_header_current.master_matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
WHERE 
	reporting_exclusions=0
	AND hierarchylevel2hist='Legal Ops - Claims'
	AND (date_closed_case_management IS NULL 
		OR date_closed_case_management>='2017-01-01')
	AND (dim_detail_outcome.outcome_of_case IS NULL OR RTRIM(LOWER(dim_detail_outcome.outcome_of_case)) <> 'exclude from reports')
	AND (dim_detail_client.zurich_data_admin_exclude_from_reports IS NULL OR RTRIM(LOWER(dim_detail_client.zurich_data_admin_exclude_from_reports)) <> 'yes')
	AND (dim_detail_core_details.referral_reason IS NULL OR RTRIM(LOWER(dim_detail_core_details.referral_reason)) <> 'in house')
	AND dim_matter_header_current.dim_matter_worktype_key <> 609 --Secondments worktype key
	-- clause to exclude "General File" matters
	AND dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number NOT IN (
		'10015-3', 'M1001-7699', '94212-1', 'N12105-238', 'TR00023-61', 'A1001-6044', 'M1001-24582', '2443L-9', 'W15531-506', 'N1001-12300', 
		'N1001-12469', '113147-999', '125409T-21', '732022-2', 'N1001-14159', '754485-1', '516358-8', 'W15373-1858', '9008076-900285', '451638-999', 
		'738632-3', '451638-204', '451638-208', '901838-1', '451638-236', 'N1001-7080', '113147-448', '113147-1036', '451638-1120', 'W16551-1', '13994-7', 
		'A2002-14012', 'W18337-2', 'M00001-11111288', '659-8', 'W18791-1', '113147-1749', '468733-8', '113147-1823', 'TR00023-1001', '610426-135', 
		'N1001-16961', '662257-2', 'W19835-1', '113147-2016', 'W15508-229', '10466-103', 'W18762-5', 'W15414-23', 'W20163-69', 'N1001-17768', '720451-1029', 
		'W17369-25', '113147-2543', '113147-2592', '451638-3592', '451638-3667', '451638-3751', 'W23663-1', 'W23671-1', 'W23696-1', 'TR00023-999', 'TR00010-999',
		'N1001-8667', 'N1001-9879', 'N1001-13752', 'N1001-7817', 'R1001-5933', '739845-99', 'W15572-721', '748359-999', 'W15434-166', '9008076-900999', '1328-227',
		'TR00010-35', 'N1001-13754', '739845-999', '732022-13', '452904-1021', '113147-3466', 'W19702-17'
		)
END

GO
