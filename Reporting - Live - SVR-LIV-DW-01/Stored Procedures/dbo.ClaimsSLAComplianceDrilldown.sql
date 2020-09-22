SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-09-15
-- Description:	New report for Claims SLA Compliance drilldown
-- =============================================

CREATE PROCEDURE [dbo].[ClaimsSLAComplianceDrilldown]
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
	--DECLARE  @Team AS VARCHAR(MAX) = 'Casualty Birmingham'
	--,@Name AS VARCHAR(MAX) = '3156'
	--,@StartDate AS DATE = NULL --'2020-02-24'
	--,@EndDate AS DATE = NULL --'2020-08-24'
	--,@PresentPosition AS VARCHAR(MAX) = 'Claim and costs concluded but recovery outstanding|Claim and costs outstanding|Claim concluded but costs outstanding|Missing'            
	----,@ClientGroup AS VARCHAR(MAX)  = 'McKesson UK'
	--,@Status AS VARCHAR (30) = 'Open'


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
	IF OBJECT_ID('tempdb..#Name') IS NOT NULL   DROP TABLE #Name
	IF OBJECT_ID('tempdb..#ClientGroup') IS NOT NULL   DROP TABLE #ClientGroup
	IF OBJECT_ID('tempdb..#PresentPosition') IS NOT NULL   DROP TABLE #PresentPosition
	IF OBJECT_ID('tempdb..#Status') IS NOT NULL   DROP TABLE #Status
	IF OBJECT_ID('tempdb..#ClientReportDates') IS NOT NULL DROP TABLE #ClientReportDates

	SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit('|', @Team)
	SELECT ListValue  INTO #Name FROM 	dbo.udt_TallySplit('|', @Name)
	SELECT ListValue  INTO #ClientGroup FROM 	dbo.udt_TallySplit('|', @ClientGroup)
	SELECT ListValue  INTO #PresentPosition FROM 	dbo.udt_TallySplit('|', @PresentPosition)
	SELECT ListValue  INTO #Status FROM 	dbo.udt_TallySplit('|', @Status)



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
	, dim_matter_header_current.master_client_code + '-' +
		dim_matter_header_current.master_matter_number					AS [MS Reference]
	, matter_description AS [Matter Description]
	, name AS [Matter Owner]
	, hierarchylevel4hist AS [Team]
	, hierarchylevel3hist AS [Department]
	, CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS [Status]
	, dim_detail_core_details.present_position AS [Present Position]
	, date_opened_case_management AS [Date Opened]
	, date_closed_case_management AS [Date Closed]
	, CASE 
		WHEN do_clients_require_an_initial_report = 'No' OR
						RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN
			NULL
		WHEN date_initial_report_sent IS NULL AND 
				dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS  DATE), #ClientReportDates.initial_report_due) BETWEEN 0 AND 5 THEN
			'Initial Report Due In 5 Working Days'
		ELSE
			NULL
	  END										AS [Count Initial Report Due In 5 Working Days]
	, CASE 
		WHEN do_clients_require_an_initial_report = 'No' OR 
						RTRIM(dim_detail_core_details.present_position) IN (
																		'Final bill due - claim and costs concluded',
																		'Final bill sent - unpaid',
																		'To be closed/minor balances to be clear'            
																	) THEN 
			NULL
		WHEN dim_detail_core_details.date_initial_report_sent IS NULL 
			AND #ClientReportDates.initial_report_due < CAST(GETDATE() AS DATE) THEN
			'Initial Report Is Overdue/Blank'
		ELSE 
			NULL
	  END										AS [Count Initial Report Is Overdue]
	, CASE 
		WHEN dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS DATE), #ClientReportDates.date_subsequent_report_due) BETWEEN 0 AND 10 THEN
			'Subsequent Report Due in 10 Working Days'
		ELSE 
			NULL
	  END				AS [Subsequent Report Due in 10 Working Days]
	, CASE 
		WHEN #ClientReportDates.date_subsequent_report_due < CAST(GETDATE() AS DATE) THEN
			'Subsequent Report is Overdue/Blank'
		ELSE 
			NULL
	  END				AS [Subsequent Report is Overdue]

FROM red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
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
	LEFT OUTER JOIN #ClientReportDates
		ON #ClientReportDates.master_client_code = dim_matter_header_current.master_client_code AND #ClientReportDates.master_matter_number = dim_matter_header_current.master_matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
WHERE 
	reporting_exclusions=0
	AND hierarchylevel2hist='Legal Ops - Claims'
	AND (date_closed_case_management IS NULL 
		OR date_closed_case_management>='2017-01-01')
	AND ((dim_matter_header_current.date_opened_case_management >= @StartDate OR @StartDate IS NULL) AND  dim_matter_header_current.date_opened_case_management<=  @EndDate  OR @EndDate IS NULL) 
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
		'W17369-25', '113147-2543', '113147-2592', '451638-3592', '451638-3667', '451638-3751', 'W23663-1', 'W23671-1', 'W23696-1'
		)
	AND (CASE 
			WHEN do_clients_require_an_initial_report = 'No' OR
							RTRIM(dim_detail_core_details.present_position) IN (
																			'Final bill due - claim and costs concluded',
																			'Final bill sent - unpaid',
																			'To be closed/minor balances to be clear'            
																		) THEN
				NULL
			WHEN date_initial_report_sent IS NULL AND 
					dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS  DATE), #ClientReportDates.initial_report_due) BETWEEN 0 AND 5 THEN
				'Initial Report Due In 5 Working Days'
			ELSE
				NULL
		  END IS NOT NULL OR
          CASE 
          		WHEN do_clients_require_an_initial_report = 'No' OR 
          						RTRIM(dim_detail_core_details.present_position) IN (
          																		'Final bill due - claim and costs concluded',
          																		'Final bill sent - unpaid',
          																		'To be closed/minor balances to be clear'            
          																	) THEN 
          			NULL
          		WHEN dim_detail_core_details.date_initial_report_sent IS NULL 
          			AND #ClientReportDates.initial_report_due < CAST(GETDATE() AS DATE) THEN
          			'Initial Report Is Overdue/Blank'
          		ELSE 
          			NULL
          END IS NOT NULL OR
          CASE 
          		WHEN dbo.ReturnElapsedDaysExcludingBankHolidays(CAST(GETDATE() AS DATE), #ClientReportDates.date_subsequent_report_due) BETWEEN 0 AND 10 THEN
          			'Subsequent Report Due in 10 Working Days'
          		ELSE 
          			NULL
		  END IS NOT NULL OR
		  CASE 
		  		WHEN #ClientReportDates.date_subsequent_report_due < CAST(GETDATE() AS DATE) THEN
		  			'Subsequent Report is Overdue/Blank'
		  		ELSE 
		  			NULL
		  END IS NOT NULL
		)
      

END

GO
