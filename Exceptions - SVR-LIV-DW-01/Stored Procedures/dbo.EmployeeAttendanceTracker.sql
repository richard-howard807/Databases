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
CREATE PROCEDURE [dbo].[EmployeeAttendanceTracker]
(
		@start_date AS INT
		, @end_date AS INT
		, @division AS NVARCHAR(MAX)
		, @department AS NVARCHAR(MAX)	
		, @team AS NVARCHAR(MAX)
		, @employee_id AS NVARCHAR(MAX)
		, @category AS NVARCHAR(MAX)
		, @jobrole AS NVARCHAR(MAX)
)
AS

BEGIN


--testing
--DECLARE @start_date AS INT = 202204
--		, @end_date AS INT = 202206
--		, @division AS NVARCHAR(MAX) = 'Business Services'
--		, @department AS NVARCHAR(MAX) = 'Data Services'
--		, @team AS NVARCHAR(MAX) = 'BI Development'
--		, @employee_id AS NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(dim_fed_hierarchy_history.employeeid AS NVARCHAR(MAX)), '|') FROM red_dw.dbo.dim_fed_hierarchy_history WHERE	dim_fed_hierarchy_history.activeud = 1	AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Data Services' AND dim_fed_hierarchy_history.leaver = 0 AND dim_fed_hierarchy_history.windowsusername IS NOT NULL) 
--		, @category AS NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(all_data.category AS NVARCHAR(MAX)), '|') FROM (SELECT DISTINCT fact_employee_attendance.category AS category FROM red_dw.dbo.fact_employee_attendance UNION SELECT 'Working From Home') AS all_data)
--		, @jobrole AS NVARCHAR(MAX) = (
--										SELECT STRING_AGG(CAST(job_title_data.jobrole AS NVARCHAR(MAX)), '|')
--										FROM (
--												SELECT DISTINCT
--													dim_employee.levelidud jobrole
--												--SELECT *
--												FROM red_dw.dbo.dim_fed_hierarchy_history
--													INNER JOIN red_dw.dbo.dim_employee
--														ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
--												WHERE
--													dim_fed_hierarchy_history.activeud = 1
--													AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
--													AND dim_employee.deleted_from_cascade = 0
--													AND dim_fed_hierarchy_history.leaver = 0
--													AND dim_fed_hierarchy_history.windowsusername IS NOT NULL
--											) AS job_title_data
--										)


DECLARE	@start_cal_date AS DATE = (SELECT MIN(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.cal_month = @start_date)
DECLARE @end_cal_date AS DATE = (SELECT MAX(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.cal_month = @end_date)

-- Pre COVID comparison periods
DECLARE	@precovid_start_cal_date AS DATE = (SELECT MIN(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.cal_month = iif(right(@start_date,2) in ('01','02'), '2020' + cast(right(@start_date,2) as varchar(2)), '2019' + cast(right(@start_date,2) as varchar(2))))
DECLARE @precovid_end_cal_date AS DATE = (SELECT MAX(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.cal_month = iif(right(@end_date,2) in ('01','02'), '2020' + cast(right(@end_date,2) as varchar(2)), '2019' + cast(right(@end_date,2) as varchar(2))))

print @precovid_start_cal_date
print @precovid_end_cal_date

IF OBJECT_ID('tempdb..#employee_dates') IS NOT NULL DROP TABLE #employee_dates
IF OBJECT_ID('tempdb..#pre_covid_employee_dates') IS NOT NULL DROP TABLE #pre_covid_employee_dates
IF OBJECT_ID('tempdb..#division') IS NOT NULL DROP TABLE #division
IF OBJECT_ID('tempdb..#department') IS NOT NULL DROP TABLE #department
IF OBJECT_ID('tempdb..#team') IS NOT NULL DROP TABLE #team
IF OBJECT_ID('tempdb..#employee_id') IS NOT NULL DROP TABLE #employee_id
IF OBJECT_ID('tempdb..#category') IS NOT NULL DROP TABLE #category
IF OBJECT_ID('tempdb..#jobrole') IS NOT NULL DROP TABLE #jobrole
IF OBJECT_ID('tempdb..#office_days_filter') IS NOT NULL DROP TABLE #office_days_filter

SELECT udt_TallySplit.ListValue  INTO #division FROM dbo.udt_TallySplit('|', @division)
SELECT udt_TallySplit.ListValue  INTO #department FROM dbo.udt_TallySplit('|', @department)
SELECT udt_TallySplit.ListValue  INTO #team FROM dbo.udt_TallySplit('|', @team)
SELECT udt_TallySplit.ListValue  INTO #employee_id FROM	dbo.udt_TallySplit('|', @employee_id)
SELECT udt_TallySplit.ListValue  INTO #category FROM dbo.udt_TallySplit('|', @category)
SELECT udt_TallySplit.ListValue  INTO #jobrole FROM dbo.udt_TallySplit('|', @jobrole)


SELECT 
	employees.*
	, dim_date.calendar_date
	, dim_date.cal_day_in_week
	, dim_date.cal_week_in_year
	, dim_date.cal_month
	, dim_date.cal_month_name
	, dim_date.cal_quarter
	, dim_date.cal_year
	, dim_date.cal_day_in_month
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
			, dim_employee.levelidud job_role
		FROM red_dw.dbo.dim_employee
			INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
					AND dim_fed_hierarchy_history.activeud = 1
						AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
			INNER JOIN #division
				ON dim_fed_hierarchy_history.hierarchylevel2hist COLLATE DATABASE_DEFAULT = #division.ListValue
			INNER JOIN #department
				ON dim_fed_hierarchy_history.hierarchylevel3hist COLLATE DATABASE_DEFAULT = #department.ListValue
			INNER JOIN #team
				ON dim_fed_hierarchy_history.hierarchylevel4hist COLLATE DATABASE_DEFAULT = #team.ListValue
			INNER JOIN #employee_id
				ON dim_employee.employeeid COLLATE DATABASE_DEFAULT = #employee_id.ListValue
			inner join #jobrole 
					ON dim_employee.levelidud COLLATE DATABASE_DEFAULT = #jobrole.ListValue 
		WHERE
			dim_employee.deleted_from_cascade = 0
			AND dim_fed_hierarchy_history.windowsusername IS NOT null			
	        and isnull(dim_employee.leftdate, '20990101') >= getdate()
			AND ISNULL(previous_firm,'')<>'RadcliffesLeBrasseur' -- added requested by Debbie holmes 
	) AS employees
WHERE 1 = 1
	AND dim_date.calendar_date <= CAST(GETDATE() AS DATE)
	AND dim_date.trading_day_flag = 'Y'
	AND dim_date.holiday_flag = 'N'
	AND dim_date.calendar_date BETWEEN @start_cal_date AND @end_cal_date
	AND employees.employeestartdate <= dim_date.calendar_date
	AND employees.leaver = 0


SELECT 
	employees.*
	, dim_date.calendar_date
	, dim_date.cal_day_in_week
	, dim_date.cal_week_in_year
	, dim_date.cal_month
	, dim_date.cal_month_name
	, dim_date.cal_quarter
	, dim_date.cal_year
	, dim_date.cal_day_in_month
INTO #pre_covid_employee_dates
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
			INNER JOIN #division
				ON dim_fed_hierarchy_history.hierarchylevel2hist COLLATE DATABASE_DEFAULT = #division.ListValue
			INNER JOIN #department
				ON dim_fed_hierarchy_history.hierarchylevel3hist COLLATE DATABASE_DEFAULT = #department.ListValue
			INNER JOIN #team
				ON dim_fed_hierarchy_history.hierarchylevel4hist COLLATE DATABASE_DEFAULT = #team.ListValue
			INNER JOIN #employee_id
				ON dim_employee.employeeid COLLATE DATABASE_DEFAULT = #employee_id.ListValue
		   	inner join #jobrole 
					ON dim_employee.levelidud COLLATE DATABASE_DEFAULT = #jobrole.ListValue 
		WHERE
			dim_employee.deleted_from_cascade = 0
			AND dim_fed_hierarchy_history.windowsusername IS NOT null
			and isnull(dim_employee.leftdate, '20990101') >= getdate()
            AND ISNULL(previous_firm,'')<>'RadcliffesLeBrasseur' -- added requested by Debbie holmes 
	) AS employees
WHERE 1 = 1
	AND dim_date.calendar_date <= CAST(GETDATE() AS DATE)
	AND dim_date.trading_day_flag = 'Y'
	AND dim_date.holiday_flag = 'N'
	AND dim_date.calendar_date BETWEEN @precovid_start_cal_date AND @precovid_end_cal_date
	AND employees.employeestartdate <= dim_date.calendar_date
	AND employees.leaver = 0

/*
#152397 table to find amount of days spent in the office for months in date range
For summary table in report to show when employee has been in the office less than 5 days in the month
*/
SELECT 
	#employee_dates.employeeid
	, #employee_dates.cal_month
	, SUM(IIF(fact_employee_attendance.category = 'In Office', 1, 0))		AS days_in_office_per_month
	, SUM(IIF(ISNULL(fact_employee_attendance.category, 'Working From Home') IN ('In Office', 'Working From Home'), 1, 0))		AS worked_days
	, total_working_days.total_working_days				AS total_working_days 
INTO #office_days_filter
FROM #employee_dates
LEFT OUTER JOIN red_dw.dbo.fact_employee_attendance
		ON fact_employee_attendance.employeeid = #employee_dates.employeeid
			AND fact_employee_attendance.startdate = #employee_dates.calendar_date
				AND fact_employee_attendance.attendancekey <> 'Dummy'
INNER JOIN (--This join deals with the total working days in the months selected incl the current month 
			SELECT 
				dim_date.cal_month
				, COUNT(*)	AS total_working_days
			FROM red_dw.dbo.dim_date
			WHERE 1 = 1
				AND dim_date.trading_day_flag = 'Y'
				AND dim_date.holiday_flag = 'N'
				AND dim_date.calendar_date BETWEEN @start_cal_date AND @end_cal_date
			GROUP BY
				dim_date.cal_month
			) AS total_working_days
	ON total_working_days.cal_month = #employee_dates.cal_month
GROUP BY
	#employee_dates.employeeid
	, #employee_dates.cal_month
	, total_working_days.total_working_days





SELECT 
	#employee_dates.*
	, ISNULL(fact_employee_attendance.category, 'Working From Home')			AS category
	, CASE
		WHEN ISNULL(fact_employee_attendance.category, 'Working From Home') IN ('In Office') THEN
			1
		ELSE
			0
	  END							AS OfficeCount
	, CASE
		WHEN ISNULL(fact_employee_attendance.category, 'Working From Home') IN ('In Office', 'Working From Home') THEN
			1
		ELSE
			0
	  END							AS working_day
	, 1 AS day_count
	, #office_days_filter.days_in_office_per_month			AS under_5_days_filter
	, #office_days_filter.worked_days
	, #office_days_filter.total_working_days
	, pre_covid.pre_covid_period
	, pre_covid.pre_covid_office_count
	, pre_covid.pre_covid_working_day

FROM #employee_dates
	LEFT OUTER JOIN red_dw.dbo.fact_employee_attendance
		ON fact_employee_attendance.employeeid = #employee_dates.employeeid
			AND fact_employee_attendance.startdate = #employee_dates.calendar_date
				AND fact_employee_attendance.attendancekey <> 'Dummy'
	INNER JOIN #category
		ON ISNULL(fact_employee_attendance.category, 'Working From Home') COLLATE DATABASE_DEFAULT = #category.ListValue

		
-- pre covid comparison data
	LEFT OUTER JOIN (
			SELECT pre_covid_data.cal_month_name + '-' + CAST(pre_covid_data.cal_year AS VARCHAR(4)) pre_covid_period, pre_covid_data.cal_month_name,
			pre_covid_data.employeeid, 
			SUM(pre_covid_data.OfficeCount) pre_covid_office_count, SUM(pre_covid_data.working_day) pre_covid_working_day, 
						(SELECT MAX(dim_date.cal_day_in_month) FROM red_dw..dim_date WHERE dim_date.cal_month_name = pre_covid_data.cal_month_name AND dim_date.trading_day_flag = 'Y' AND dim_date.holiday_desc IS NULL
													AND dim_date.calendar_date BETWEEN @start_cal_date AND @end_cal_date AND dim_date.calendar_date <= CAST(GETDATE() AS DATE)) first_day_in_month
				FROM (
					SELECT #pre_covid_employee_dates.*,
					CASE WHEN ISNULL(fact_employee_attendance.category, 'Working From Home') IN ('In Office') THEN 1
					ELSE 0  END OfficeCount,
					CASE WHEN ISNULL(fact_employee_attendance.category, 'Working From Home') IN ('In Office', 'Working From Home') THEN 1
					ELSE 0 END AS working_day
				
					FROM #pre_covid_employee_dates 
						LEFT OUTER JOIN red_dw.dbo.fact_employee_attendance
							ON fact_employee_attendance.employeeid = #pre_covid_employee_dates.employeeid
								AND fact_employee_attendance.startdate = #pre_covid_employee_dates.calendar_date
									AND fact_employee_attendance.attendancekey <> 'Dummy'
						INNER JOIN #category
							ON ISNULL(fact_employee_attendance.category, 'Working From Home') COLLATE DATABASE_DEFAULT = #category.ListValue
					) pre_covid_data
				GROUP BY pre_covid_data.cal_month_name + '-' + CAST(pre_covid_data.cal_year AS VARCHAR(4))
                       , pre_covid_data.employeeid, pre_covid_data.cal_month_name, pre_covid_data.cal_month
				) pre_covid ON pre_covid.employeeid = #employee_dates.employeeid AND pre_covid.cal_month_name = #employee_dates.cal_month_name 
								AND pre_covid.first_day_in_month = #employee_dates.cal_day_in_month
	LEFT OUTER JOIN #office_days_filter
		ON #office_days_filter.employeeid = #employee_dates.employeeid
			AND #office_days_filter.cal_month = #employee_dates.cal_month
ORDER BY employee_name, calendar_date


END 


GO
