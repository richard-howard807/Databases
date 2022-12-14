SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-02-15
-- Description:	#88687, new report holiday tracker report for finance 
-- =============================================

--Exec [dbo].[FinanceHolidayTracker] '8','2021'
CREATE PROCEDURE [dbo].[FinanceHolidayTracker]
	
(
 @Month INT
 ,@Year INT
 --,@MaxDate INT
 )

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--DECLARE @Month INT =9
--,@Year INT =2021
DECLARE @MaxDate  INT =(SELECT MIN(dim_date_key) 
				FROM red_dw.dbo.dim_date
				WHERE fin_year=@Year
				AND fin_month_no=@Month) 


IF OBJECT_ID('tempdb..#MonthlyHolidays') IS NOT NULL DROP TABLE #MonthlyHolidays;
IF OBJECT_ID('tempdb..#HolidaysTaken') IS NOT NULL DROP TABLE #HolidaysTaken;
IF OBJECT_ID('tempdb..#HolidaysBooked') IS NOT NULL DROP TABLE #HolidaysBooked;

(SELECT employeeid, fin_year,dim_date.fin_period, dim_date.fin_quarter,dim_date.fin_month_no
, SUM(durationholidaydays) AS taken
INTO #MonthlyHolidays
FROM red_dw.dbo.fact_employee_attendance
INNER JOIN red_dw.dbo.dim_date
ON dim_date.calendar_date=fact_employee_attendance.startdate
AND dim_date.fin_year=@Year 
AND dim_date.fin_month_no<=@Month

--WHERE --category IN ('Holiday') AND 
--fact_employee_attendance.employeeid='E1A7FD11-DDCC-406D-9CFF-B4C36167A4BF'
						--AND fact_employee_attendance.employeeid='D1F10526-0E8B-41C9-9C20-934675B81DA3'
				GROUP BY employeeid, dim_date.fin_year,dim_date.fin_period, dim_date.fin_quarter, dim_date.fin_month_no) 

--(SELECT employeeid, SUM(durationdays) AS durationdays , SUM(durationholidaydays) AS durationholidaydays
--INTO #HolidaysTaken
--FROM red_dw.dbo.fact_employee_attendance
--WHERE  entitlement_year=(SELECT DISTINCT fin_year 
--						FROM red_dw.dbo.dim_date
--						WHERE current_fin_year='Current')
--AND category='Holiday'
--AND startdate<=GETDATE()
--GROUP BY employeeid) 

(SELECT employeeid, SUM(durationdays) AS durationdays , SUM(durationholidaydays) AS durationholidaydays
INTO #HolidaysBooked
FROM red_dw.dbo.fact_employee_attendance
WHERE  entitlement_year=@Year
AND category='Holiday'
AND startdate>GETDATE()
GROUP BY employeeid) 

SELECT 
	 hierarchylevel2hist AS [Division]
	, hierarchylevel3hist AS [Department]
	, hierarchylevel4hist AS [Team]
	, dim_fed_hierarchy_history.display_name AS [Name]
	, remaining_fte_working_days_year AS [Annual Working Days]
	, CASE WHEN ROW_NUMBER() OVER (PARTITION BY name ORDER BY #MonthlyHolidays.fin_month_no)=1 THEN totalentitlementdays ELSE 0 END AS [Annual Holiday Allowance]
	, #MonthlyHolidays.taken AS [Holidays Taken in Month]
	, CASE WHEN ROW_NUMBER() OVER (PARTITION BY name ORDER BY #MonthlyHolidays.fin_month_no)=1 THEN ISNULL(#HolidaysBooked.durationholidaydays,0) ELSE 0 END AS [Current Booked]
	, #MonthlyHolidays.fin_quarter AS [Quarter]
	, #MonthlyHolidays.fin_period AS [Month]
	, #MonthlyHolidays.fin_month_no AS [Month No]
	, #MonthlyHolidays.fin_year AS [Year]
	, dim_employee.employeeid
	, ROW_NUMBER() OVER (PARTITION BY name ORDER BY #MonthlyHolidays.fin_month_no) AS [Row]
	, dim_employee.leaverlastworkdate
	, leavers_date.fin_month_no
	, leavers_date.fin_year
	, leavers_date.fin_month
	

FROM red_dw.dbo.dim_employee

LEFT OUTER JOIN red_dw.dbo.dim_date AS [leavers_date]
ON dim_employee.leaverlastworkdate=[leavers_date].calendar_date 

LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
AND dim_fed_hierarchy_history.dss_current_flag='Y'
AND activeud=1

LEFT OUTER JOIN red_dw.dbo.fact_employee_attendance_entitlement_year
ON fact_employee_attendance_entitlement_year.employeeid = dim_employee.employeeid
AND dim_attendance_date_key=(SELECT MIN(dim_date_key) [YearStartDate] 
							FROM red_dw.dbo.dim_date
							WHERE dim_date.fin_year=@Year
							)

LEFT OUTER JOIN red_dw.dbo.ds_sh_employee_jobs
ON ds_sh_employee_jobs.employeeid = dim_employee.employeeid
AND ds_sh_employee_jobs.dss_current_flag='Y'
AND sys_activejob=1

LEFT OUTER JOIN red_dw.dbo.fact_employee_days_fte 
ON fact_employee_days_fte.employeeid = dim_employee.employeeid
AND fact_employee_days_fte.fin_month=(SELECT MIN(fin_month)
				FROM red_dw.dbo.dim_date
				WHERE fin_year=@Year
				)

--LEFT OUTER JOIN #HolidaysTaken ON #HolidaysTaken.employeeid = dim_employee.employeeid 
LEFT OUTER JOIN #MonthlyHolidays ON #MonthlyHolidays.employeeid = dim_employee.employeeid
LEFT OUTER JOIN #HolidaysBooked ON #HolidaysBooked.employeeid = dim_employee.employeeid

WHERE 
--leaver=0
--includes leavers in the previous year if they left this year
 --((dim_employee.leaverlastworkdate<= GETDATE() AND YEAR(dim_employee.leaverlastworkdate)<>@Year) OR dim_employee.leaverlastworkdate IS NULL OR dim_employee.leaverlastworkdate>GETDATE())
--AND 
red_dw.dbo.dim_employee.deleted_from_cascade <> 1 --added due to report bring back deleted emp
AND red_dw.dbo.dim_employee.employeestartdate <= GETDATE() -- bring in new starters 
--AND #MonthlyHolidays.fin_month_no IS NOT NULL 

AND (leavers_date.dim_date_key>=@MaxDate
--leavers_date.fin_month>=@Year+''+@Month
--(leavers_date.fin_month_no>=@Month
--AND leavers_date.fin_year>=@Year) 
OR dim_employee.leaverlastworkdate IS NULL)

--AND name ='Sharon Grugel'
AND name IS NOT NULL 

END

GO
