SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Emily Smith
-- Create date: 2019-10-28
-- Description:	New report for Claims SLA Compliance
-- =============================================

CREATE PROCEDURE [dbo].[ClaimsSLACompliance]
	(
	@Team AS VARCHAR(MAX) 
	,@Name AS VARCHAR(MAX)
	,@StartDate AS DATE
	,@EndDate AS DATE
	,@ClientGroup AS VARCHAR(MAX) 
	,@Status AS VARCHAR(MAX) 
	,@PresentPosition AS VARCHAR(MAX) 
	
)
AS
BEGIN

	--For testing purposes
	--===========================================================
	--DECLARE  @Team AS VARCHAR(MAX) = 'Motor Management'
	--,@Name AS VARCHAR(MAX) = '1856'
	--,@StartDate AS DATE = '2020-02-17'
	--,@EndDate AS DATE = '2020-08-17'
	--,@PresentPosition AS VARCHAR(MAX) = 'Claim and costs concluded but recovery outstanding|Claim and costs outstanding|Claim concluded but costs outstanding|Final bill due - claim and costs concluded|Final bill sent - unpaid|Missing|To be closed/minor balances to be clear'            
	--,@ClientGroup AS VARCHAR(MAX)  = 'None'
	--,@Status AS VARCHAR (30) = 'Open|Closed'


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
	IF OBJECT_ID('tempdb..#Name') IS NOT NULL   DROP TABLE #Name
	IF OBJECT_ID('tempdb..#ClientGroup') IS NOT NULL   DROP TABLE #ClientGroup
	IF OBJECT_ID('tempdb..#PresentPosition') IS NOT NULL   DROP TABLE #PresentPosition
	IF OBJECT_ID('tempdb..#Status') IS NOT NULL   DROP TABLE #Status
	IF OBJECT_ID('tempdb..#FICProcess') IS NOT NULL DROP TABLE #FICProcess
	IF OBJECT_ID('tempdb..#ClientReportDates') IS NOT NULL DROP TABLE #ClientReportDates

	SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit('|', @Team)
	SELECT ListValue  INTO #Name FROM 	dbo.udt_TallySplit('|', @Name)
	SELECT ListValue  INTO #ClientGroup FROM 	dbo.udt_TallySplit('|', @ClientGroup)
	SELECT ListValue  INTO #PresentPosition FROM 	dbo.udt_TallySplit('|', @PresentPosition)
	SELECT ListValue  INTO #Status FROM 	dbo.udt_TallySplit('|', @Status)


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
			WHEN date_initial_report_due IS NULL THEN 
				[dbo].[AddWorkDaysToDate](CAST(date_opened_case_management AS DATE),10) 
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
					WHEN DATENAME(wk, DATEADD(MONTH, 3, dim_detail_core_details.date_subsequent_sla_report_sent)) = 'Saturday' THEN
						DATEADD(MONTH, 3, dim_detail_core_details.date_subsequent_sla_report_sent)+2
					WHEN DATENAME(wk, DATEADD(MONTH, 3, dim_detail_core_details.date_subsequent_sla_report_sent)) = 'Sunday' THEN
						DATEADD(MONTH, 3, dim_detail_core_details.date_subsequent_sla_report_sent)+1
					ELSE 
						DATEADD(MONTH, 3, dim_detail_core_details.date_subsequent_sla_report_sent)
				END
			WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NULL THEN
				CASE 
					-- Needing to make sure future date is a weekday
					WHEN DATENAME(wk, DATEADD(MONTH, 3, dim_detail_core_details.date_initial_report_sent)) = 'Saturday' THEN
						DATEADD(MONTH, 3, dim_detail_core_details.date_initial_report_sent)+2
					WHEN DATENAME(wk, DATEADD(MONTH, 3, dim_detail_core_details.date_initial_report_sent)) = 'Sunday' THEN
						DATEADD(MONTH, 3, dim_detail_core_details.date_initial_report_sent)+1
					ELSE 
						DATEADD(MONTH, 3, dim_detail_core_details.date_initial_report_sent)
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
		INNER JOIN #Team AS Team 
			ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
		INNER JOIN #Name AS Name 
			ON Name.ListValue COLLATE DATABASE_DEFAULT = fee_earner_code COLLATE DATABASE_DEFAULT
		INNER JOIN #ClientGroup AS ClientGroup 
			ON ISNULL(CASE WHEN dim_matter_header_current.client_group_name = '' THEN 'None' ELSE dim_matter_header_current.client_group_name END,'None')=ClientGroup.ListValue COLLATE DATABASE_DEFAULT
		INNER JOIN #PresentPosition AS Position 
			ON RTRIM(Position.ListValue) COLLATE DATABASE_DEFAULT = ISNULL(dim_detail_core_details.present_position,'Missing') COLLATE DATABASE_DEFAULT
		INNER JOIN #Status AS [Status] 
			ON RTRIM([Status].ListValue)  = (CASE WHEN dim_matter_header_current.date_closed_case_management  IS NULL THEN 'Open' ELSE 'Closed' END) COLLATE DATABASE_DEFAULT
		LEFT OUTER JOIN Reporting.dbo.ClientSLAs 
			ON [Client Name]=client_name COLLATE DATABASE_DEFAULT
	WHERE 
		reporting_exclusions = 0
		AND hierarchylevel2hist = 'Legal Ops - Claims'
		AND (date_closed_case_management IS NULL 
			OR date_closed_case_management >= '2017-01-01')
		AND ((dim_matter_header_current.date_opened_case_management >= @StartDate OR @StartDate IS NULL) AND  dim_matter_header_current.date_opened_case_management <= @EndDate OR @EndDate IS NULL) 
					
--=========================================================================================================================================================================================================================================================================
--=========================================================================================================================================================================================================================================================================


SELECT 
	client_name AS [Client Name]
	, dim_matter_header_current.master_client_code
	, dim_matter_header_current.master_matter_number
	, dim_matter_header_current.client_code AS [Client Code]
	, dim_matter_header_current.matter_number AS [Matter Number]
	, matter_description AS [Matter Description]
	, name AS [Matter Owner]
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
	--, receipt_of_instructions AS [Date Receipt of File Papers]
	, dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers] AS [Date Receipt of File Papers]
	, [ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an Extension?]
	, #ClientReportDates.initial_report_due				AS [Date Initial Report Due (if extended)]
	, dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent) AS [Days to Send Intial Report]
	--, CASE WHEN date_initial_report_due IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, GETDATE()) ELSE NULL END AS [Days without Initial Report]
	, CASE WHEN do_clients_require_an_initial_report = 'No' THEN NULL
	--WHEN dim_detail_core_details.delegated='Yes' THEN NULL
		WHEN date_initial_report_sent IS NOT NULL THEN NULL
		WHEN date_initial_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(CASE WHEN grpageas_motor_date_of_receipt_of_clients_file_of_papers> date_opened_case_management THEN grpageas_motor_date_of_receipt_of_clients_file_of_papers ELSE date_opened_case_management END , GETDATE())
		WHEN date_initial_report_sent IS NULL AND dbo.ReturnElapsedDaysExcludingBankHolidays(CASE WHEN grpageas_motor_date_of_receipt_of_clients_file_of_papers> date_opened_case_management THEN grpageas_motor_date_of_receipt_of_clients_file_of_papers ELSE date_opened_case_management END , GETDATE())<[Initial Report SLA (days)] THEN 'Not yet due'
		ELSE NULL END AS [Days without Initial Report]
	, date_subsequent_sla_report_sent AS [Date Subsequent SLA Report Sent]
	--, dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent) AS [Days to Send Subsequent Report]

	, CASE 
		WHEN do_clients_require_an_initial_report = 'No' AND
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
--	, CASE WHEN ISNULL(do_clients_require_an_initial_report,'Yes')='No' THEN NULL 
--	WHEN date_subsequent_sla_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, GETDATE()) 
--	WHEN date_subsequent_sla_report_sent IS NOT NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_subsequent_sla_report_sent, GETDATE()) 
--	WHEN date_claim_concluded IS NOT NULL THEN NULL
--	WHEN date_costs_settled IS NOT NULL THEN NULL

--ELSE NULL END AS [Days without Subsequent Report]
	, 1					AS [Number of Files]
	,CASE WHEN dim_detail_core_details.date_initial_report_sent IS NULL THEN NULL ELSE days.days_to_first_report_lifecycle END AS avglifecycle 
	, days.days_to_first_report_lifecycle
	,dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud?]
	,FICProcess.tskDue
	,FICProcess.tskCompleted
	,FICProcess.tskDesc
	--Client SLA's
	, [File Opening SLA (days)]
	, [Initial Report SLA (days)]
	, [Update Report SLA (days)]
	, [Update Report SLA]
	, CASE WHEN date_instructions_received IS NULL THEN 
				'Amber'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END)<0 THEN 
				'Amber'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END)<=[File Opening SLA (days)] THEN 
				'LimeGreen'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END)>[File Opening SLA (days)] THEN 
				'Red'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END)<=2 THEN 
				'LimeGreen'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END)>2 THEN 
				'Red'
			ELSE 
				'Transparent' 
	  END					AS [File Opening RAG]
	, CASE WHEN date_initial_report_sent IS NULL THEN 
				'Amber'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent))<0 THEN 
				'Orange'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent))<=[Initial Report SLA (days)] THEN 
				'LimeGreen'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent))>[Initial Report SLA (days)] THEN 
				'Red'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent))<=10 THEN 
				'LimeGreen'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent))>10 THEN 
				'Red'
			ELSE 
				'Transparent' 
		END				AS [Initial Report RAG]
	, CASE 
			WHEN date_initial_report_sent IS NULL AND 
				dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS  DATE), #ClientReportDates.initial_report_due) BETWEEN 0 AND 5 THEN
				'Orange'
			WHEN days.days_to_first_report_lifecycle IS NULL THEN 
				'Amber'
			WHEN (days.days_to_first_report_lifecycle)<0 THEN 
				'Transparent'
			WHEN (days.days_to_first_report_lifecycle)<=[Initial Report SLA (days)] THEN 
				'LimeGreen'
			WHEN (days.days_to_first_report_lifecycle)>[Initial Report SLA (days)] THEN 
				'Red'
			WHEN (days.days_to_first_report_lifecycle)<=10 THEN 
				'LimeGreen'
			WHEN (days.days_to_first_report_lifecycle)>10 THEN 
				'Red'
			ELSE 
				'Transparent' 
		END					AS [NEW Initial Report RAG]
				
	--, CASE WHEN date_subsequent_sla_report_sent IS NULL THEN 'Amber'
	--		WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent))<0 THEN 'Orange'
	--		WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent))<=[Update Report SLA (days)] THEN 'LimeGreen'
	--		WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent))>[Update Report SLA (days)] THEN 'Red'
	--		WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent))>63 THEN 'Red'
	--		WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent))<=63 THEN 'LimeGreen'
	--		ELSE 'Transparent' END [Update Report RAG]

	,CASE WHEN ISNULL(do_clients_require_an_initial_report,'Yes')='No' THEN 
			'Transparent'
		WHEN RTRIM(dim_detail_core_details.present_position) IN (
																	'Final bill due - claim and costs concluded',
																	'Final bill sent - unpaid',
																	'To be closed/minor balances to be clear'            
																) THEN 
			'Transparent'
		WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NULL AND 
				dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS DATE), #ClientReportDates.date_subsequent_report_due) BETWEEN 0 AND 10 THEN
			'Orange'
		WHEN (CASE WHEN date_subsequent_sla_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, GETDATE()) 
					WHEN date_subsequent_sla_report_sent IS NOT NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_subsequent_sla_report_sent, GETDATE()) 
					WHEN date_claim_concluded IS NOT NULL THEN NULL
					ELSE NULL END) BETWEEN 0 AND 53 THEN
			'Limegreen'
		 WHEN (CASE WHEN date_subsequent_sla_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, GETDATE()) 
					WHEN date_subsequent_sla_report_sent IS NOT NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_subsequent_sla_report_sent, GETDATE()) 
					WHEN date_claim_concluded IS NOT NULL THEN NULL
					ELSE NULL END) BETWEEN 54 AND 63 THEN 
			'Amber'
		WHEN (CASE WHEN date_subsequent_sla_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, GETDATE()) 
					WHEN date_subsequent_sla_report_sent IS NOT NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_subsequent_sla_report_sent, GETDATE()) 
					WHEN date_claim_concluded IS NOT NULL THEN NULL
					ELSE NULL END)<0 THEN 
			'Transparent' 

		WHEN (CASE WHEN date_subsequent_sla_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, GETDATE()) 
					WHEN date_subsequent_sla_report_sent IS NOT NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_subsequent_sla_report_sent, GETDATE()) 
					WHEN date_claim_concluded IS NOT NULL THEN NULL
					ELSE NULL END) IS NULL THEN 
			'Transparent' 
		ELSE 
			'Red'
		END								 AS RagWithouthSub
	,referral_reason
	,  CASE 
		WHEN date_initial_report_sent IS NULL AND ISNULL(do_clients_require_an_initial_report,'Yes')='Yes' 
			AND #ClientReportDates.initial_report_due < GETDATE()-1 THEN 
			1 
		ELSE 
			0 
	  END				AS NoBlankInitial

	, CASE 
		WHEN (date_subsequent_sla_report_sent IS NULL AND ISNULL(do_clients_require_an_initial_report,'Yes')='Yes' AND GETDATE() > DATEADD(DAY, 90, dim_matter_header_current.date_opened_case_management))  THEN 
			1
		ELSE 
			0 
	  END				 AS NoBlankSub
	, dim_detail_core_details.delegated
	, CASE 
		WHEN do_clients_require_an_initial_report = 'No' AND
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
		WHEN do_clients_require_an_initial_report = 'No' AND
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
		WHEN do_clients_require_an_initial_report = 'No' AND
						RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN
			0
		WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NULL AND 
				dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS DATE), #ClientReportDates.date_subsequent_report_due) BETWEEN 0 AND 10 THEN
			1
		ELSE 
			0
	  END				AS [Subsequent Report Due in 10 Working Days]
	, CASE 
		WHEN do_clients_require_an_initial_report = 'No' AND
						RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN 
			0
		WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NULL 
			AND #ClientReportDates.date_subsequent_report_due < CAST(GETDATE() AS DATE) THEN
			1
		ELSE 
			0
	  END				AS [Subsequent Report is Overdue]


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
	INNER JOIN #Team AS Team 
		ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
	INNER JOIN #Name AS Name 
		ON Name.ListValue COLLATE DATABASE_DEFAULT = fee_earner_code COLLATE DATABASE_DEFAULT
	INNER JOIN #ClientGroup AS ClientGroup 
		ON ISNULL(CASE WHEN dim_matter_header_current.client_group_name = '' THEN 'None' ELSE dim_matter_header_current.client_group_name END,'None')=ClientGroup.ListValue COLLATE DATABASE_DEFAULT
	INNER JOIN #PresentPosition AS Position 
		ON RTRIM(Position.ListValue) COLLATE DATABASE_DEFAULT = ISNULL(dim_detail_core_details.present_position,'Missing') COLLATE DATABASE_DEFAULT
	INNER JOIN #Status AS [Status] 
		ON RTRIM([Status].ListValue)  = (CASE WHEN dim_matter_header_current.date_closed_case_management  IS NULL THEN 'Open' ELSE 'Closed' END) COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN #FICProcess FICProcess 
		ON FICProcess.fileID = ms_fileid
	LEFT OUTER JOIN Reporting.dbo.ClientSLAs 
		ON [Client Name]=client_name COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN #ClientReportDates
		ON #ClientReportDates.master_client_code = dim_matter_header_current.master_client_code AND #ClientReportDates.master_matter_number = dim_matter_header_current.master_matter_number

WHERE 
	reporting_exclusions=0
	AND hierarchylevel2hist='Legal Ops - Claims'
	AND (date_closed_case_management IS NULL 
		OR date_closed_case_management>='2017-01-01')
	AND ((dim_matter_header_current.date_opened_case_management >= @StartDate OR @StartDate IS NULL) AND  dim_matter_header_current.date_opened_case_management<=  @EndDate  OR @EndDate IS NULL) 


END



GO
