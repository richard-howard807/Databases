SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [dbo].[ClaimsManagementReportSnapshot] 
	
	
AS
BEGIN


DECLARE @Period AS NVARCHAR(MAX)
SET @Period=(SELECT bill_fin_period FROM red_dw.dbo.dim_bill_date
WHERE bill_date =DATEADD(MONTH,0,CONVERT(DATE,GETDATE(),103)))

DECLARE @FinYear AS INT
DECLARE @FinMonth AS INT

SET @FinMonth=(SELECT  DISTINCT  bill_fin_month_no FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

SET @FinYear=(SELECT DISTINCT  bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

PRINT @FinYear
PRINT @FinMonth


DECLARE @StartDate AS DATE
DECLARE @EndDate AS DATE

SET @StartDate=(SELECT MIN(calendar_date) AS StartDate FROM red_dw.dbo.dim_date WHERE fin_year=@FinYear)
SET @EndDate=(SELECT MAX(calendar_date) AS StartDate FROM red_dw.dbo.dim_date WHERE fin_year=@FinYear)


DELETE FROM dbo.ClaimsManagementReportSnapshotTable WHERE FinYear=@FinYear AND FinMonth=@FinMonth



INSERT INTO dbo.ClaimsManagementReportSnapshotTable
(
employeeid
,[Name]
	,[Division]
	,[Department]
	,[Team]
	,[Contractual hours per day]
	,[Annual Holiday Allowance]
	,[Annual Working Days]
	,[Holidays Taken to Date]
	,[Holidays yet to Take]
	,[Working Days to Date]

	,[Chargeable Hours]
	,[AVGChargeableHours]
	,[ChargeableHoursMTD]
	,[Utilisation %]
	,SicknessDays
	,OtherDays
	,MonthlyContribution
	,YTDContribution
	,[Chargeable hours target]
	,[Revenue target]
	,YTDTargetHrs
	,YTDTargetRevenue
	,[Chargeable hours target Annual]
	,[Revenue target Annual]
	,FinMonth
	,FinYear
	,[Period]
	,fed_code
	,MaternityDays
)


SELECT dim_employee.employeeid
,name AS [Name]
	, hierarchylevel2hist AS [Division]
	, hierarchylevel3hist AS [Department]
	, hierarchylevel4hist AS [Team]
	, normalworkingday AS [Contractual hours per day]
	, totalentitlementdays AS [Annual Holiday Allowance]
	, remaining_fte_working_days_year AS [Annual Working Days]
	, durationholidaydays AS [Holidays Taken to Date]
	, ISNULL(totalentitlementdays,0)-ISNULL(durationholidaydays,0) AS [Holidays yet to Take]
	, [Trading Days] * red_dw.dbo.fact_employee_days_fte.fte AS [Working Days to Date]

	, [ChargeableHours] AS [Chargeable Hours]
	, [AVGChargeableHours]
	, [ChargeableHoursMTD]
	, CASE WHEN ContractedHours.ContractedHours>0 THEN (ChargeableHours.ChargeableHours/ContractedHours.ContractedHours) END AS [Utilisation %]
	,Absenses.SicknessDays
	,Absenses.OtherDays
	,CASE WHEN Contrib.MTDContribution IS NULL THEN 0 ELSE Contrib.MTDContribution END AS MonthlyContribution
	,CASE WHEN YTDContribution IS NULL THEN 0 ELSE YTDContribution END AS YTDContribution
	,TeamTargetsMTD.[Chargeable hours target]
	,TeamTargetsMTD.[Revenue target]
	,TeamTargetsYTD.[Chargeable hours target] AS YTDTargetHrs
	,TeamTargetsYTD.[Revenue target] AS YTDTargetRevenue
	,[TeamTargetsAnnual].[Chargeable hours target Annual]
	,TeamTargetsAnnual.[Revenue target Annual]
	,@FinMonth AS FinMonth
	,@FinYear AS FinYear
	,@Period AS [Period]
	,dim_fed_hierarchy_history.fed_code
	,Maternity.MaternityDays
FROM red_dw.dbo.dim_employee WITH(NOLOCK)
INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
AND dim_fed_hierarchy_history.dss_current_flag='Y'
AND activeud=1

LEFT OUTER JOIN red_dw.dbo.fact_employee_attendance_entitlement_year WITH(NOLOCK)
ON fact_employee_attendance_entitlement_year.employeeid = dim_employee.employeeid
AND dim_attendance_date_key=(SELECT MIN(dim_date_key) [YearStartDate] 
							FROM red_dw.dbo.dim_date
							WHERE current_fin_year='Current')

LEFT OUTER JOIN red_dw.dbo.ds_sh_employee_jobs WITH(NOLOCK)
ON ds_sh_employee_jobs.employeeid = dim_employee.employeeid
AND ds_sh_employee_jobs.dss_current_flag='Y'
AND sys_activejob=1

LEFT OUTER JOIN (SELECT 
					ds_sh_employee_attendance_dates.employeeid
					, SUM(ds_sh_employee_attendance_dates.durationdays)		AS durationholidaydays
				--SELECT ds_sh_employee_attendance_dates.*
				FROM red_dw.dbo.ds_sh_employee_attendance_dates WITH(NOLOCK)
					INNER JOIN red_dw.dbo.dim_date WITH(NOLOCK)
						ON ds_sh_employee_attendance_dates.startdate = dim_date.calendar_date	
				WHERE 1 = 1
					--AND ds_sh_employee_attendance_dates.employeeid = 'C4413681-7195-4364-AA6F-B6A1DA22A127'
					--AND dim_fed_hierarchy_history.hierarchylevel4hist = 'North West Healthcare 2'
					AND dim_date.current_fin_year = 'Current'
					AND ds_sh_employee_attendance_dates.startdate < GETDATE()
					AND ds_sh_employee_attendance_dates.type = 'Holiday'
					AND ds_sh_employee_attendance_dates.deleted_flag = 'N'
				GROUP BY	
					ds_sh_employee_attendance_dates.employeeid) AS [HolidaysTaken]
ON [HolidaysTaken].employeeid = dim_employee.employeeid

LEFT OUTER JOIN red_dw.dbo.fact_employee_days_fte  WITH(NOLOCK)
ON fact_employee_days_fte.employeeid = dim_employee.employeeid
AND fin_month=(SELECT MIN(fin_month)
				FROM red_dw.dbo.dim_date
				WHERE current_fin_year='Current')

LEFT OUTER JOIN (SELECT employeeid, SUM(minutes_recorded)/60 AS [ChargeableHours]
, AVG(minutes_recorded)/60 AS [AVGChargeableHours]
,SUM(CASE WHEN fin_month_no=@FinMonth THEN minutes_recorded ELSE 0 END)/60 AS [ChargeableHoursMTD]
				FROM red_dw.dbo.fact_billable_time_activity WITH(NOLOCK)
				INNER JOIN red_dw.dbo.dim_date WITH(NOLOCK)
				ON dim_date_key=dim_orig_posting_date_key
				AND fin_year=(SELECT DISTINCT fin_year 
							FROM red_dw.dbo.dim_date WITH(NOLOCK)
							WHERE current_fin_year='Current')
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_billable_time_activity.dim_fed_hierarchy_history_key
				WHERE minutes_recorded<>0
				GROUP BY employeeid) AS [ChargeableHours] ON ChargeableHours.employeeid = dim_employee.employeeid

INNER JOIN (SELECT employeeid, SUM(contracted_hours_in_month) AS [ContractedHours] 
				FROM  red_dw.dbo.fact_budget_activity WITH(NOLOCK)
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_budget_activity.dim_fed_hierarchy_history_key
				WHERE financial_budget_year=(SELECT DISTINCT fin_year 
											FROM red_dw.dbo.dim_date WITH(NOLOCK)
											WHERE current_fin_year='Current')
				GROUP BY employeeid) AS [ContractedHours] ON ContractedHours.employeeid = dim_employee.employeeid

LEFT OUTER JOIN (SELECT dim_employee.employeeid, SUM(Dates.[Trading Days]) [Trading Days]
				FROM red_dw.dbo.dim_employee WITH(NOLOCK)
				CROSS APPLY (	SELECT dim_date.calendar_date, CASE WHEN trading_day_flag='Y' AND dim_date.holiday_flag = 'N' THEN 1 ELSE 0 END AS [Trading Days]
					-- select *
					FROM red_dw.dbo.dim_date WITH(NOLOCK)
					WHERE current_fin_year='Current'
					AND calendar_date<=(SELECT calendar_date FROM red_dw.dbo.dim_date WITH(NOLOCK)
										WHERE current_cal_day='Current')  ) Dates 
				WHERE Dates.calendar_date > dim_employee.employeestartdate
				-- AND dim_employee.employeeid IN ('13E3D529-2BD9-4C6F-9471-58A303D7A946', '7DE27206-711E-47C1-A214-D40A46EEFD1B')
				GROUP BY dim_employee.employeeid ) AS [TradingHours] ON TradingHours.employeeid = dim_employee.employeeid
LEFT OUTER JOIN 
(
SELECT employeeid, SUM(minutes_recorded)/60 AS [ChargeableHoursYTD]
				FROM red_dw.dbo.fact_billable_time_activity WITH(NOLOCK)
				INNER JOIN red_dw.dbo.dim_date WITH(NOLOCK)
				ON dim_date_key=dim_orig_posting_date_key
				
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_billable_time_activity.dim_fed_hierarchy_history_key
				WHERE minutes_recorded<>0
				AND fin_year=@FinYear
				AND fin_month_no<=@FinMonth
				GROUP BY employeeid
) AS YTDChargeable
 ON YTDChargeable.employeeid = dim_employee.employeeid

LEFT OUTER JOIN 
(
SELECT CurrentAbsence.employeeid,SUM(CASE WHEN CurrentAbsence.category='Sickness' THEN CurrentAbsence.days ELSE 0 END) AS SicknessDays
,SUM(CASE WHEN ISNULL(CurrentAbsence.category,'') NOT IN ('Maternity','Sickness') THEN CurrentAbsence.days ELSE 0 END) AS OtherDays
FROM
(SELECT employeeid, attendancekey, category, SUM(durationdays) days, MIN(startdate) startdate, MAX(startdate) enddate
				FROM red_dw.dbo.fact_employee_attendance WITH(NOLOCK)
				WHERE  entitlement_year=(SELECT DISTINCT fin_year 
											FROM red_dw.dbo.dim_date WITH(NOLOCK)
											WHERE current_fin_year='Current')
											AND durationdays<>0
											AND startdate<=GETDATE()
											AND ISNULL(category,'')<>'Holiday'
											--AND employeeid='19AB983F-4D45-49AC-9155-B9BCA6B36D2F'
											AND CONVERT(DATE,startdate,103) BETWEEN @StartDate AND @EndDate
											AND CONVERT(DATE,startdate,103) NOT IN (SELECT CONVERT(DATE,calendar_date,103) FROM red_dw.dbo.dim_date WHERE trading_day_flag='Y' OR holiday_flag='Y')

						GROUP BY employeeid, attendancekey,
                                 category
								 ) AS [CurrentAbsence]
								 GROUP BY CurrentAbsence.employeeid
) AS Absenses 
 ON Absenses.employeeid = dim_employee.employeeid

LEFT OUTER JOIN 
(
SELECT fact_budget_activity.dim_fed_hierarchy_history_key
,SUM(fed_level_contribution_value) AS YTDContribution
,SUM(CASE WHEN financial_budget_month=@FinMonth THEN fed_level_contribution_value ELSE 0 END) AS MTDContribution
FROM red_dw.dbo.fact_budget_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_budget_activity.dim_fed_hierarchy_history_key
WHERE financial_budget_year=@FinYear
AND fed_level_contribution_value IS NOT NULL
GROUP BY fact_budget_activity.dim_fed_hierarchy_history_key
) AS Contrib
ON  Contrib.dim_fed_hierarchy_history_key = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
LEFT OUTER JOIN 
(
SELECT hierarchylevel4hist AS Team
,SUM(team_level_budget_value_hours) AS [Chargeable hours target]
,SUM(team_level_budget_value) AS [Revenue target]
FROM red_dw.dbo.fact_budget_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_budget_date WITH(NOLOCK)
 ON dim_budget_date.dim_budget_date_key = fact_budget_activity.dim_budget_date_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_budget_activity.dim_fed_hierarchy_history_key
WHERE budget_fin_month_no=@FinMonth
AND budget_fin_year=@FinYear
GROUP BY hierarchylevel4hist

) AS TeamTargetsMTD
 ON hierarchylevel4hist=TeamTargetsMTD.Team COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT hierarchylevel4hist AS Team
,SUM(team_level_budget_value_hours) AS [Chargeable hours target]
,SUM(team_level_budget_value) AS [Revenue target]
FROM red_dw.dbo.fact_budget_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_budget_date WITH(NOLOCK)
 ON dim_budget_date.dim_budget_date_key = fact_budget_activity.dim_budget_date_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_budget_activity.dim_fed_hierarchy_history_key
WHERE budget_fin_month_no<=@FinMonth
AND budget_fin_year=@FinYear
GROUP BY hierarchylevel4hist

) AS TeamTargetsYTD
 ON hierarchylevel4hist=TeamTargetsYTD.Team COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT hierarchylevel4hist AS Team
,SUM(team_level_budget_value_hours) AS [Chargeable hours target Annual]
,SUM(team_level_budget_value) AS [Revenue target Annual]
FROM red_dw.dbo.fact_budget_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_budget_date WITH(NOLOCK)
 ON dim_budget_date.dim_budget_date_key = fact_budget_activity.dim_budget_date_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_budget_activity.dim_fed_hierarchy_history_key
WHERE budget_fin_year=@FinYear
GROUP BY hierarchylevel4hist

) AS TeamTargetsAnnual
 ON hierarchylevel4hist=TeamTargetsAnnual.Team COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT CurrentAbsence.employeeid,SUM(CurrentAbsence.days) AS MaternityDays
FROM
(SELECT employeeid, attendancekey, category, SUM(durationdays) days, MIN(startdate) startdate, MAX(startdate) enddate
				FROM red_dw.dbo.fact_employee_attendance WITH(NOLOCK)
				WHERE  entitlement_year=(SELECT DISTINCT fin_year 
											FROM red_dw.dbo.dim_date WITH(NOLOCK)
											WHERE current_fin_year='Current')
											AND durationdays<>0
											--AND startdate<=GETDATE()
											--AND ISNULL(category,'')='Maternity'
											--AND employeeid='19AB983F-4D45-49AC-9155-B9BCA6B36D2F'
											--AND CONVERT(DATE,startdate,103) BETWEEN @StartDate AND @EndDate
											AND CONVERT(DATE,startdate,103) NOT IN (SELECT CONVERT(DATE,calendar_date,103) FROM red_dw.dbo.dim_date WHERE trading_day_flag='Y' OR holiday_flag='Y')
AND category='Maternity'
						GROUP BY employeeid, attendancekey,
                                 category
								 ) AS [CurrentAbsence]
								 GROUP BY CurrentAbsence.employeeid
) AS Maternity 
 ON Maternity.employeeid = dim_employee.employeeid
WHERE leaver=0
AND hierarchylevel2hist='Legal Ops - Claims'
AND normalworkingday <>0


ORDER BY name
END
GO
