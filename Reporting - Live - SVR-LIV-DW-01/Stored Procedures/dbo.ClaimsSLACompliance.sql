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
	,@Status AS VARCHAR(10) 
	,@PresentPosition AS VARCHAR(MAX) 
	
)
AS
BEGIN

	--For testing purposes
	--===========================================================
	--DECLARE  @Team AS VARCHAR(MAX) = 'Motor Management'
	--,@Name AS VARCHAR(MAX) = ''
	--,@StartDate AS DATE = '2019-01-01'
	--,@EndDate AS DATE = '2019-07-24'
	--,@PresentPosition AS VARCHAR(MAX) = 'Claim and costs outstanding,To be closed/minor balances to be clear, Missing, Claim concluded but costs outstanding'
	--,@ClientGroup AS VARCHAR(MAX)  = '
	--,@Status AS VARCHAR (30) = 'Closed'


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
	, dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) AS [Days to File Opened from Date Instructions Received]
	, date_initial_report_sent AS [Date Initial Report Sent]
	, do_clients_require_an_initial_report AS [Do Clients Require an Initial Report?]
	, receipt_of_instructions AS [Date Receipt of File Papers]
	, [ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an Extension?]
	, date_initial_report_due AS [Date Initial Report Due (if extended)]
	, dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, date_initial_report_sent) AS [Days to Send Intial Report]
	, CASE WHEN date_initial_report_due IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, GETDATE()) ELSE NULL END AS [Days without Initial Report]
	, date_subsequent_sla_report_sent AS [Date Subsequent SLA Report Sent]
	, dbo.ReturnElapsedDaysExcludingBankHolidays(date_initial_report_sent, date_subsequent_sla_report_sent) AS [Days to Send Subsequent Report]
	, CASE WHEN date_subsequent_sla_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(date_opened_case_management, GETDATE()) ELSE NULL END AS [Days without Subsequent Report]
	, 1 AS [Number of Files]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #Name AS Name ON Name.ListValue COLLATE DATABASE_DEFAULT = name COLLATE DATABASE_DEFAULT
INNER JOIN #ClientGroup AS ClientGroup ON dim_matter_header_current.client_group_name=ClientGroup.ListValue COLLATE DATABASE_DEFAULT
INNER JOIN #PresentPosition AS Position ON RTRIM(Position.ListValue) COLLATE DATABASE_DEFAULT = dim_detail_core_details.present_position COLLATE DATABASE_DEFAULT
INNER JOIN #Status AS [Status] ON RTRIM([Status].ListValue)  = (CASE WHEN dim_matter_header_current.date_closed_case_management  IS NULL THEN 'Open' ELSE 'Closed' END) COLLATE DATABASE_DEFAULT
--INNER JOIN #Status ON #Status.ListValue = CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END
WHERE reporting_exclusions=0
AND hierarchylevel2hist='Legal Ops - Claims'
AND (date_closed_case_management IS NULL 
	OR date_closed_case_management>='2017-01-01')

--AND CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate and @EndDate
AND ((dim_matter_header_current.date_opened_case_management >= @StartDate OR @StartDate IS NULL) AND  dim_matter_header_current.date_opened_case_management<=  @EndDate  OR @EndDate IS NULL) 


END
GO
