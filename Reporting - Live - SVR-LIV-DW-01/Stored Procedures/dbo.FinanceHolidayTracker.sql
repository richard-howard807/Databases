SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-02-15
-- Description:	#88687, new report holiday tracker report for finance 
-- =============================================
CREATE PROCEDURE [dbo].[FinanceHolidayTracker] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#MonthlyHolidays') IS NOT NULL DROP TABLE #MonthlyHolidays;
IF OBJECT_ID('tempdb..#HolidaysTaken') IS NOT NULL DROP TABLE #HolidaysTaken;
IF OBJECT_ID('tempdb..#HolidaysBooked') IS NOT NULL DROP TABLE #HolidaysBooked;

(SELECT employeeid, fin_year,dim_date.fin_period, dim_date.fin_quarter,dim_date.fin_month_no, SUM(durationholidaydays) AS durationholidaydays
INTO #MonthlyHolidays
FROM red_dw.dbo.fact_employee_attendance
LEFT OUTER JOIN red_dw.dbo.dim_date
ON dim_date.calendar_date=fact_employee_attendance.startdate
WHERE  entitlement_year=(SELECT DISTINCT fin_year 
						FROM red_dw.dbo.dim_date
						WHERE current_fin_year='Current')
						AND category='Holiday'
						AND startdate<=GETDATE()
						--AND fact_employee_attendance.employeeid='D1F10526-0E8B-41C9-9C20-934675B81DA3'
				GROUP BY employeeid, dim_date.fin_year,dim_date.fin_period, dim_date.fin_quarter, dim_date.fin_month_no) 

(SELECT employeeid, SUM(durationdays) AS durationdays , SUM(durationholidaydays) AS durationholidaydays
INTO #HolidaysTaken
FROM red_dw.dbo.fact_employee_attendance
WHERE  entitlement_year=(SELECT DISTINCT fin_year 
						FROM red_dw.dbo.dim_date
						WHERE current_fin_year='Current')
AND category='Holiday'
AND startdate<=GETDATE()
GROUP BY employeeid) 

(SELECT employeeid, SUM(durationdays) AS durationdays , SUM(durationholidaydays) AS durationholidaydays
INTO #HolidaysBooked
FROM red_dw.dbo.fact_employee_attendance
WHERE  entitlement_year=(SELECT DISTINCT fin_year 
						FROM red_dw.dbo.dim_date
						WHERE current_fin_year='Current')
AND category='Holiday'
AND startdate>GETDATE()
GROUP BY employeeid) 

SELECT 
	 hierarchylevel2hist AS [Division]
	, hierarchylevel3hist AS [Department]
	, hierarchylevel4hist AS [Team]
	, name AS [Name]
	, remaining_fte_working_days_year AS [Annual Working Days]
	, totalentitlementdays AS [Annual Holiday Allowance]
	, ISNULL(#HolidaysBooked.durationholidaydays,0) AS [Holidays Booked yet to be Taken]
	, ISNULL(#HolidaysTaken.durationholidaydays,0) AS [Holidays Taken to Date]
	, ISNULL(#HolidaysBooked.durationholidaydays,0)+ISNULL(#HolidaysTaken.durationholidaydays,0) AS [Holidays Booked]
	, ISNULL(totalentitlementdays,0)-ISNULL(#HolidaysTaken.durationholidaydays,0) AS [Annual Holidays Remaining]
	, ISNULL(totalentitlementdays,0)-(ISNULL(#HolidaysBooked.durationholidaydays,0)+ISNULL(#HolidaysTaken.durationholidaydays,0) ) AS [Annual Holidays yet to be Booked]
	, #MonthlyHolidays.fin_quarter AS [Quarter]
	, #MonthlyHolidays.fin_period AS [Month]
	, fin_month_no AS [Month No]
	, #MonthlyHolidays.durationholidaydays AS [Holidays Taken in Month]
	, dim_employee.employeeid

FROM red_dw.dbo.dim_employee

LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
AND dim_fed_hierarchy_history.dss_current_flag='Y'
AND activeud=1

LEFT OUTER JOIN red_dw.dbo.fact_employee_attendance_entitlement_year
ON fact_employee_attendance_entitlement_year.employeeid = dim_employee.employeeid
AND dim_attendance_date_key=(SELECT MIN(dim_date_key) [YearStartDate] 
							FROM red_dw.dbo.dim_date
							WHERE current_fin_year='Current')

LEFT OUTER JOIN red_dw.dbo.ds_sh_employee_jobs
ON ds_sh_employee_jobs.employeeid = dim_employee.employeeid
AND ds_sh_employee_jobs.dss_current_flag='Y'
AND sys_activejob=1

LEFT OUTER JOIN red_dw.dbo.fact_employee_days_fte 
ON fact_employee_days_fte.employeeid = dim_employee.employeeid
AND fin_month=(SELECT MIN(fin_month)
				FROM red_dw.dbo.dim_date
				WHERE current_fin_year='Current')

LEFT OUTER JOIN #HolidaysTaken ON #HolidaysTaken.employeeid = dim_employee.employeeid 
LEFT OUTER JOIN #MonthlyHolidays ON #MonthlyHolidays.employeeid = dim_employee.employeeid
LEFT OUTER JOIN #HolidaysBooked ON #HolidaysBooked.employeeid = dim_employee.employeeid

WHERE leaver=0
AND red_dw.dbo.dim_employee.deleted_from_cascade <> 1 --added due to report bring back deleted emp
AND red_dw.dbo.dim_employee.employeestartdate <= GETDATE() -- bring in new starters 
AND #MonthlyHolidays.fin_year='2021'
--AND name ='Emily Smith'


END
GO
