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

SELECT 
	 hierarchylevel2hist AS [Division]
	, hierarchylevel3hist AS [Department]
	, hierarchylevel4hist AS [Team]
	, name AS [Name]
	, remaining_fte_working_days_year AS [Annual Working Days]
	, totalentitlementdays AS [Annual Holiday Allowance]
	, ISNULL([HolidaysTaken].durationholidaydays,0) AS [Holidays Taken to Date]
	, ISNULL(totalentitlementdays,0)-ISNULL([HolidaysTaken].durationholidaydays,0) AS [Annual Holiday Remaining]
	, MonthlyHolidays.fin_quarter AS [Quarter]
	, MonthlyHolidays.fin_period AS [Month]
	, fin_month_no AS [Month No]
	, MonthlyHolidays.durationholidaydays AS [Holidays Taken in Month]
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

LEFT OUTER JOIN (SELECT employeeid, SUM(durationdays) AS durationdays , SUM(durationholidaydays) AS durationholidaydays
				FROM red_dw.dbo.fact_employee_attendance
				WHERE  entitlement_year=(SELECT DISTINCT fin_year 
										FROM red_dw.dbo.dim_date
										WHERE current_fin_year='Current')
						AND category='Holiday'
						AND startdate<=GETDATE()
				GROUP BY employeeid) AS [HolidaysTaken]
ON [HolidaysTaken].employeeid = dim_employee.employeeid

LEFT OUTER JOIN red_dw.dbo.fact_employee_days_fte 
ON fact_employee_days_fte.employeeid = dim_employee.employeeid
AND fin_month=(SELECT MIN(fin_month)
				FROM red_dw.dbo.dim_date
				WHERE current_fin_year='Current')


LEFT OUTER JOIN (SELECT dim_employee.employeeid, SUM(Dates.[Trading Days]) [Trading Days]
				FROM red_dw.dbo.dim_employee
				CROSS APPLY (	SELECT dim_date.calendar_date, CASE WHEN trading_day_flag='Y' AND dim_date.holiday_flag = 'N' THEN 1 ELSE 0 END AS [Trading Days]
					-- select *
					FROM red_dw.dbo.dim_date
					WHERE current_fin_year='Current'
					AND calendar_date<=(SELECT calendar_date FROM red_dw.dbo.dim_date
										WHERE current_cal_day='Current')  ) Dates 
				WHERE Dates.calendar_date > dim_employee.employeestartdate
				-- AND dim_employee.employeeid IN ('13E3D529-2BD9-4C6F-9471-58A303D7A946', '7DE27206-711E-47C1-A214-D40A46EEFD1B')
				GROUP BY dim_employee.employeeid ) AS [TradingHours] ON TradingHours.employeeid = dim_employee.employeeid

LEFT OUTER JOIN (SELECT * FROM
(SELECT employeeid, attendancekey, category, SUM(durationdays) days, MIN(startdate) startdate, MAX(startdate) enddate
				FROM red_dw.dbo.fact_employee_attendance
				WHERE  entitlement_year=(SELECT DISTINCT fin_year 
											FROM red_dw.dbo.dim_date
											WHERE current_fin_year='Current')
											AND durationdays<>0
											AND startdate<=GETDATE()
											AND ISNULL(category,'')<>'Holiday'
											--AND employeeid='19AB983F-4D45-49AC-9155-B9BCA6B36D2F'
						GROUP BY employeeid, attendancekey,
                                 category
								 ) AS [CurrentAbsence]
								 WHERE CAST(GETDATE()-1 AS date) BETWEEN [CurrentAbsence].startdate AND ISNULL([CurrentAbsence].enddate,GETDATE()+1) 
								 OR CAST(GETDATE() AS date) BETWEEN [CurrentAbsence].startdate AND ISNULL([CurrentAbsence].enddate,GETDATE()+1)) AS Absence ON Absence.employeeid = dim_employee.employeeid 

LEFT OUTER JOIN (SELECT employeeid, fin_year,dim_date.fin_period, dim_date.fin_quarter,dim_date.fin_month_no, SUM(durationholidaydays) AS durationholidaydays
FROM red_dw.dbo.fact_employee_attendance
LEFT OUTER JOIN red_dw.dbo.dim_date
ON dim_date.calendar_date=fact_employee_attendance.startdate
WHERE  entitlement_year=(SELECT DISTINCT fin_year 
						FROM red_dw.dbo.dim_date
						WHERE current_fin_year='Current')
						AND category='Holiday'
						AND startdate<=GETDATE()
						--AND fact_employee_attendance.employeeid='D1F10526-0E8B-41C9-9C20-934675B81DA3'
				GROUP BY employeeid, dim_date.fin_year,dim_date.fin_period, dim_date.fin_quarter, dim_date.fin_month_no) AS [MonthlyHolidays]
				ON MonthlyHolidays.employeeid = dim_employee.employeeid

WHERE leaver=0
AND red_dw.dbo.dim_employee.deleted_from_cascade <> 1 --added due to report bring back deleted emp
AND red_dw.dbo.dim_employee.employeestartdate <= GETDATE() -- bring in new starters 
AND MonthlyHolidays.fin_year='2021'
--AND name ='Emily Smith'


END
GO
