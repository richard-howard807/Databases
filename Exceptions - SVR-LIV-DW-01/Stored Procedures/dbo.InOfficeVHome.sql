SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Boner
-- Create date: 14/11/2022
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InOfficeVHome]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DROP TABLE IF EXISTS #time_recorded
DROP TABLE IF EXISTS #employee_dates
DROP TABLE IF EXISTS #emp_work_days_count

SELECT 
	fact_chargeable_time_activity.dim_fed_hierarchy_history_key
	, dim_date.calendar_date			AS worked_date
	, SUM(fact_chargeable_time_activity.minutes_recorded)/60		AS recorded_time
INTO #time_recorded
FROM red_dw.dbo.fact_chargeable_time_activity
	INNER JOIN red_dw.dbo.dim_date
		ON fact_chargeable_time_activity.dim_transaction_date_key = dim_date.dim_date_key
WHERE 1 = 1
	AND dim_date.calendar_date BETWEEN '2021-05-01' AND CAST(GETDATE() AS DATE)
GROUP BY
	fact_chargeable_time_activity.dim_fed_hierarchy_history_key
	, dim_date.calendar_date


/* Passes aren't working
(
39C1827E-CE60-4AC7-892B-BF0EA4D67F88		--Charles Gallagher
, 3F4AA0BB-A19B-45D1-A2DD-4795CE6ED5D6		--Edwina Farrell
, 21FB7AA7-D8D3-4F89-9E0F-BE6002934A56		--Kristian Campbell-Drummond
, 23878BFB-5EE2-4974-B7E6-79F5D6CB17C0		--Jo Burns
, 76CD55E2-BE0A-4DE1-9859-CC833EE30DF2		--Joanne Ojelade
)
*/



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
		WHERE
			dim_employee.deleted_from_cascade = 0
			AND dim_fed_hierarchy_history.windowsusername IS NOT null			
	        and isnull(dim_employee.leftdate, '20990101') >= '2021-05-01'
			--AND ISNULL(previous_firm,'')<>'RadcliffesLeBrasseur' -- added requested by Debbie holmes 
	) AS employees
WHERE 1 = 1
	AND dim_date.calendar_date <= CAST(GETDATE() AS DATE)
	AND dim_date.trading_day_flag = 'Y'
	AND dim_date.holiday_flag = 'N'
	AND dim_date.calendar_date BETWEEN '2021-05-01' AND CAST(GETDATE() AS DATE)
	AND employees.employeestartdate <= dim_date.calendar_date
	--AND employees.leaver = 0



SELECT 
	#employee_dates.*
	, ISNULL(fact_employee_attendance.category, 'Working From Home')		AS category
	, IIF(fact_employee_attendance.category = 'In Office', 1, 0)	AS in_office_count
	, IIF(fact_employee_attendance.category IS NULL, 1, 0)		AS wfh_count
	, 1			AS work_days_count
	, #time_recorded.recorded_time
	, CASE
		WHEN #employee_dates.employeeid IN (
											'39C1827E-CE60-4AC7-892B-BF0EA4D67F88'		--Charles Gallagher
											, '3F4AA0BB-A19B-45D1-A2DD-4795CE6ED5D6'		--Edwina Farrell
											, '21FB7AA7-D8D3-4F89-9E0F-BE6002934A56'		--Kristian Campbell-Drummond
											, '23878BFB-5EE2-4974-B7E6-79F5D6CB17C0'		--Jo Burns
											, '76CD55E2-BE0A-4DE1-9859-CC833EE30DF2'		--Joanne Ojelade
											) THEN
			'Pass is not working'
		ELSE
			NULL
	  END											AS pass_not_working_flag
--SELECT DISTINCT fact_employee_attendance.category
FROM #employee_dates
	LEFT OUTER JOIN red_dw.dbo.fact_employee_attendance
		ON fact_employee_attendance.employeeid = #employee_dates.employeeid
			AND fact_employee_attendance.startdate = #employee_dates.calendar_date
				AND fact_employee_attendance.attendancekey <> 'Dummy'
	INNER JOIN #time_recorded
		ON #time_recorded.dim_fed_hierarchy_history_key = #employee_dates.dim_fed_hierarchy_history_key
			AND #employee_dates.calendar_date = #time_recorded.worked_date
WHERE 1 = 1
	AND ISNULL(fact_employee_attendance.category, 'Working From Home') IN ('In Office', 'Working From Home')

END
GO
