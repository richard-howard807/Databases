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
--,@Name AS VARCHAR(MAX) = ''
--	,@StartDate AS DATE = '2019-01-01'
--	,@EndDate AS DATE = '2019-07-24'
--	,@PresentPosition AS VARCHAR(MAX) = 'Claim and costs outstanding,To be closed/minor balances to be clear, Missing, Claim concluded but costs outstanding'
--	,@ClientGroup AS VARCHAR(MAX)  = ''
--	,@Status AS VARCHAR (30) = 'Closed'


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
	IF OBJECT_ID('tempdb..#Name') IS NOT NULL   DROP TABLE #Name
	IF OBJECT_ID('tempdb..#ClientGroup') IS NOT NULL   DROP TABLE #ClientGroup
	IF OBJECT_ID('tempdb..#PresentPosition') IS NOT NULL   DROP TABLE #PresentPosition
	IF OBJECT_ID('tempdb..#Status') IS NOT NULL   DROP TABLE #Status

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
	AND tskActive=1

SELECT client_name AS [Client Name]
	, dim_matter_header_current.client_code AS [Client Code]
	, dim_matter_header_current.matter_number AS [Matter Number]
	, matter_description AS [Matter Description]
	, name AS [Matter Owner]
	, hierarchylevel4hist AS [Team]
	, hierarchylevel3hist AS [Department]
	, CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS [Status]
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
	, date_initial_report_due AS [Date Initial Report Due (if extended)]
	, dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent) AS [Days to Send Intial Report]
	--, CASE WHEN date_initial_report_due IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, GETDATE()) ELSE NULL END AS [Days without Initial Report]
	, CASE WHEN do_clients_require_an_initial_report = 'No' THEN NULL
		WHEN date_initial_report_sent IS NOT NULL THEN NULL
		WHEN date_initial_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, GETDATE())
		WHEN date_initial_report_sent IS NULL AND dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, GETDATE())<[Initial Report SLA (days)] THEN 'Not yet due'
		ELSE NULL END AS [Days without Initial Report]
	, date_subsequent_sla_report_sent AS [Date Subsequent SLA Report Sent]
	, dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent) AS [Days to Send Subsequent Report]
	, CASE WHEN date_subsequent_sla_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, GETDATE()) ELSE NULL END AS [Days without Subsequent Report]
	, 1 AS [Number of Files]
	,days.days_to_first_report_lifecycle
	,dim_detail_core_details.suspicion_of_fraud AS [Suspicion of Fraud?]
	,FICProcess.tskDue
	,FICProcess.tskCompleted
	,FICProcess.tskDesc
	--Client SLA's
	, [File Opening SLA (days)]
	, [Initial Report SLA (days)]
	, [Update Report SLA (days)]
	, [Update Report SLA]
	, CASE WHEN date_instructions_received IS NULL THEN 'Amber'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END)<0 THEN 'Amber'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END)<=[File Opening SLA (days)] THEN 'LimeGreen'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END)>[File Opening SLA (days)] THEN 'Red'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END)<=2 THEN 'LimeGreen'
			WHEN (CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END)>2 THEN 'Red'
			ELSE 'Transparent' END [File Opening RAG]
	, CASE WHEN date_initial_report_sent IS NULL THEN 'Amber'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent))<0 THEN 'Orange'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent))<=[Initial Report SLA (days)] THEN 'LimeGreen'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent))>[Initial Report SLA (days)] THEN 'Red'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent))<=10 THEN 'LimeGreen'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent))>10 THEN 'Red'
			ELSE 'Transparent' END [Initial Report RAG]
	, CASE WHEN days.days_to_first_report_lifecycle IS NULL THEN 'Amber'
			WHEN (days.days_to_first_report_lifecycle)<0 THEN 'Orange'
			WHEN (days.days_to_first_report_lifecycle)<=[Initial Report SLA (days)] THEN 'LimeGreen'
			WHEN (days.days_to_first_report_lifecycle)>[Initial Report SLA (days)] THEN 'Red'
			WHEN (days.days_to_first_report_lifecycle)<=10 THEN 'LimeGreen'
			WHEN (days.days_to_first_report_lifecycle)>10 THEN 'Red'
			ELSE 'Transparent' END [NEW Initial Report RAG]
	, CASE WHEN date_subsequent_sla_report_sent IS NULL THEN 'Amber'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent))<0 THEN 'Orange'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent))<=[Update Report SLA (days)] THEN 'LimeGreen'
			WHEN (dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent))>[Update Report SLA (days)] THEN 'Red'
			ELSE 'Transparent' END [Update Report RAG]
,referral_reason
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days AS days 
ON days.master_fact_key = fact_dimension_main.master_fact_key
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #Name AS Name ON Name.ListValue COLLATE DATABASE_DEFAULT = name COLLATE DATABASE_DEFAULT
INNER JOIN #ClientGroup AS ClientGroup ON dim_matter_header_current.client_group_name=ClientGroup.ListValue COLLATE DATABASE_DEFAULT
INNER JOIN #PresentPosition AS Position ON RTRIM(Position.ListValue) COLLATE DATABASE_DEFAULT = dim_detail_core_details.present_position COLLATE DATABASE_DEFAULT
INNER JOIN #Status AS [Status] ON RTRIM([Status].ListValue)  = (CASE WHEN dim_matter_header_current.date_closed_case_management  IS NULL THEN 'Open' ELSE 'Closed' END) COLLATE DATABASE_DEFAULT

LEFT OUTER JOIN #FICProcess FICProcess ON FICProcess.fileID = ms_fileid
--INNER JOIN #Status ON #Status.ListValue = CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END

LEFT OUTER JOIN Reporting.dbo.ClientSLAs ON [Client Name]=client_name COLLATE DATABASE_DEFAULT

WHERE reporting_exclusions=0
AND hierarchylevel2hist='Legal Ops - Claims'
AND (date_closed_case_management IS NULL 
	OR date_closed_case_management>='2017-01-01')

--AND CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate and @EndDate
AND ((dim_matter_header_current.date_opened_case_management >= @StartDate OR @StartDate IS NULL) AND  dim_matter_header_current.date_opened_case_management<=  @EndDate  OR @EndDate IS NULL) 


END
GO
