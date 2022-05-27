SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2021-11-15
-- Ticket:		ad-hoc
-- Description:	Tracks employees attendance into the office
-- =============================================
CREATE PROCEDURE [dbo].[EmployeeAvgAttendance]
(
		@start_date AS INT
		, @end_date AS INT
		, @office AS NVARCHAR(MAX)
		, @category AS NVARCHAR(MAX)
)
AS

BEGIN


--testing
--DECLARE @start_date AS INT = 202108
--		, @end_date AS INT = 202111
--		, @office AS NVARCHAR(MAX) = 'Liverpool'
--DECLARE @category AS NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(all_data.category AS NVARCHAR(MAX)), '|') FROM (SELECT DISTINCT fact_employee_attendance.category AS category FROM red_dw.dbo.fact_employee_attendance UNION SELECT 'Working From Home') AS all_data)


DECLARE	@start_cal_date AS DATE = (SELECT MIN(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.cal_month = @start_date)
DECLARE @end_cal_date AS DATE = (SELECT MAX(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.cal_month = @end_date)


IF OBJECT_ID('tempdb..#office') IS NOT NULL DROP TABLE #office
IF OBJECT_ID('tempdb..#employee_dates') IS NOT NULL DROP TABLE #employee_dates
IF OBJECT_ID('tempdb..#category') IS NOT NULL DROP TABLE #category

SELECT udt_TallySplit.ListValue  INTO #office FROM dbo.udt_TallySplit('|', @office)
SELECT udt_TallySplit.ListValue  INTO #category FROM dbo.udt_TallySplit('|', @category)



SELECT 
	employees.*
	, dim_date.calendar_date
	, dim_date.cal_day_in_week
	, dim_date.cal_week_in_year
	, dim_date.cal_month
	, dim_date.cal_month_name
	, dim_date.cal_quarter
	, dim_date.cal_year
INTO #employee_dates
FROM red_dw.dbo.dim_date
CROSS APPLY
	(
		SELECT
			dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
			, dim_employee.employeeid
			, dim_fed_hierarchy_history.name		AS employee_name
			, dim_employee.locationidud			AS office
			, dim_fed_hierarchy_history.hierarchylevel2hist		AS division
			, dim_fed_hierarchy_history.hierarchylevel3hist		AS department
			, dim_fed_hierarchy_history.hierarchylevel4hist		AS team
			, dim_employee.employeestartdate
			, dim_employee.leftdate
			, dim_fed_hierarchy_history.leaver
		FROM red_dw.dbo.dim_employee
			INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
					AND dim_fed_hierarchy_history.activeud = 1
						AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
			INNER JOIN #office on #office.ListValue = dim_employee.locationidud collate database_default
		WHERE
			dim_employee.deleted_from_cascade = 0
			AND dim_fed_hierarchy_history.windowsusername IS NOT null 
			AND ISNULL(previous_firm,'')<>'RadcliffesLeBrasseur' -- added requested by Debbie holmes
	) AS employees
WHERE 1 = 1
	AND dim_date.calendar_date <= CAST(GETDATE() AS DATE)
	AND dim_date.trading_day_flag = 'Y'
	AND dim_date.holiday_flag = 'N'
	AND dim_date.calendar_date BETWEEN @start_cal_date AND @end_cal_date
	AND employees.employeestartdate <= dim_date.calendar_date
	
--	AND employees.leaver = 0




SELECT
       avg_data.office
     , avg_data.calendar_date
	 ,  DATEPART(WEEKDAY, avg_data.calendar_date) day_order
     , avg_data.cal_day_in_week
     , avg_data.cal_week_in_year
     , avg_data.cal_month
     , avg_data.cal_month_name
     , avg_data.cal_quarter
     , avg_data.cal_year
     , avg_data.category
     , SUM(avg_data.OfficeCount) OfficeCount
FROM (
		SELECT 
		
		   #employee_dates.employeeid
		  , #employee_dates.office
		  , #employee_dates.calendar_date
		  , #employee_dates.cal_day_in_week
		  , #employee_dates.cal_week_in_year
		  , #employee_dates.cal_month
		  , #employee_dates.cal_month_name
		  , #employee_dates.cal_quarter
		  , #employee_dates.cal_year

			, ISNULL(fact_employee_attendance.category, 'Working From Home')			AS category

			, CASE
				WHEN ISNULL(fact_employee_attendance.category, 'Working From Home') IN ('In Office') THEN
					1
				ELSE
					0
			  END							AS OfficeCount
	
		FROM #employee_dates
			LEFT OUTER JOIN red_dw.dbo.fact_employee_attendance
				ON fact_employee_attendance.employeeid = #employee_dates.employeeid
					AND fact_employee_attendance.startdate = #employee_dates.calendar_date
						AND fact_employee_attendance.attendancekey <> 'Dummy'
			INNER JOIN #category
				ON ISNULL(fact_employee_attendance.category, 'Working From Home') COLLATE DATABASE_DEFAULT = #category.ListValue
		WHERE fact_employee_attendance.category = 'In Office' 
	) avg_data
GROUP BY avg_data.office
       , avg_data.calendar_date
       , avg_data.cal_day_in_week
       , avg_data.cal_week_in_year
       , avg_data.cal_month
       , avg_data.cal_month_name
       , avg_data.cal_quarter
       , avg_data.cal_year
       , avg_data.category


END 


GO
