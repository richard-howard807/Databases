SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-06-18
-- Description:	New report to track holidays and contractual hours, 61548
-- =============================================


CREATE PROCEDURE [dbo].[HolidayTracker] 
	
	@Division VARCHAR(MAX)
	, @Department varchar(MAX)
	, @Team varchar(MAX)
	, @Individual varchar(MAX)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Division') IS NOT NULL   DROP TABLE #Division
	IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
	IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
	IF OBJECT_ID('tempdb..#Individual') IS NOT NULL   DROP TABLE #Individual

			CREATE TABLE #Division 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Division
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Division) 

		CREATE TABLE #Department 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Department
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Department) 

	CREATE TABLE #Team 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Team
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Team) 

	CREATE TABLE #Individual 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Individual
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Individual) 


SELECT name AS [Name]
	, hierarchylevel2hist AS [Division]
	, hierarchylevel3hist AS [Department]
	, hierarchylevel4hist AS [Team]
	, normalworkingday AS [Contractual hours per day]
	, totalentitlementdays AS [Annual Holiday Allowance]
	, remaining_fte_working_days_year AS [Annual Working Days]
	, durationholidaydays AS [Holidays Taken to Date]
	, [Trading Days] AS [Working Days to Date]
	, [ChargeableHours] AS [Chargeable Hours]
	, CASE WHEN ContractedHours.ContractedHours>0 THEN (ChargeableHours.ChargeableHours/ContractedHours.ContractedHours) END AS [Utilisation %]
	, Absence.days AS [Absent days]
	, Absence.category AS [Absence]
	, Absence.startdate AS [Absence Start Date]
	, Absence.enddate AS [Absence End Date]

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

LEFT OUTER JOIN (SELECT employeeid, SUM(minutes_recorded)/60 AS [ChargeableHours]
				FROM red_dw.dbo.fact_billable_time_activity
				INNER JOIN red_dw.dbo.dim_date
				ON dim_date_key=dim_orig_posting_date_key
				AND fin_year=(SELECT DISTINCT fin_year 
							FROM red_dw.dbo.dim_date
							WHERE current_fin_year='Current')
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_billable_time_activity.dim_fed_hierarchy_history_key
				WHERE minutes_recorded<>0
				GROUP BY employeeid) AS [ChargeableHours] ON ChargeableHours.employeeid = dim_employee.employeeid

LEFT OUTER JOIN (SELECT employeeid, SUM(contracted_hours_in_month) AS [ContractedHours] 
				FROM  red_dw.dbo.fact_budget_activity
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_budget_activity.dim_fed_hierarchy_history_key
				WHERE financial_budget_year=(SELECT DISTINCT fin_year 
											FROM red_dw.dbo.dim_date
											WHERE current_fin_year='Current')
				GROUP BY employeeid) AS [ContractedHours] ON ContractedHours.employeeid = dim_employee.employeeid

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

LEFT OUTER JOIN (SELECT employeeid, attendancekey, category, SUM(durationdays) days, MIN(startdate) startdate, MAX(startdate) enddate
				FROM red_dw.dbo.fact_employee_attendance
				WHERE  entitlement_year=(SELECT DISTINCT fin_year 
											FROM red_dw.dbo.dim_date
											WHERE current_fin_year='Current')
											AND durationdays<>0
											AND startdate<=GETDATE()
						GROUP BY employeeid, attendancekey,
                                 category) AS Absence ON Absence.employeeid = dim_employee.employeeid 

	INNER JOIN #Division AS Division ON Division.ListValue = hierarchylevel2hist 
	INNER JOIN #Department AS Department ON Department.ListValue = hierarchylevel3hist 
	INNER JOIN #Team AS Team ON Team.ListValue = hierarchylevel4hist 
	INNER JOIN #Individual AS Individual ON Individual.ListValue = name


WHERE leaver=0
 --AND dim_employee.employeeid='2E5E49EA-A167-4E47-AEF9-C77B72A08ABF'

ORDER BY name, Absence.startdate
END
GO
