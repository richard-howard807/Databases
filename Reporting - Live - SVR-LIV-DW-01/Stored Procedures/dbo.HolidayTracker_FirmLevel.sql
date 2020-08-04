SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 2020-07-24
-- Description:	New report to track holidays at firm level, #65712
-- =============================================
--EXECUTE [dbo].[HolidayTracker_FirmLevel]  'Business Services', 'Data Services', 'Business Analytics', 'Orlagh Kelly, Julie Loughlin'
--EXECUTE [dbo].[HolidayTracker_FirmLevel] 'Business Services, Client Relationships, Legal Ops - Claims, Legal Ops - LTA','Business Change, Business Services Management, Casualty, Claims Management,Client Management,Corp-Comm,Data Services,Disease,EPI,Facilities,Finance,Glasgow,Healthcare,Information Systems,LTA Management,Large Loss, Litigation,Marketing,Motor,Newcastle,People and Knowledge,Real Estate,Regulatory,Risk and Compliance'



CREATE PROCEDURE [dbo].[HolidayTracker_FirmLevel] 
	
	@Division VARCHAR(MAX) --= 'Business Services'
, @Department varchar(MAX) -- = 'Data Services'
	--, @Team varchar(MAX)--= 'Business Analytics'
	--, @Individual varchar(MAX) -- 'Julie Loughlin'


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Division') IS NOT NULL   DROP TABLE #Division
	IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
	IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
	--IF OBJECT_ID('tempdb..#Individual') IS NOT NULL   DROP TABLE #Individual

			CREATE TABLE #Division 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Division
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Division) 

		CREATE TABLE #Department 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Department
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Department) 

	--CREATE TABLE #Team 
	--( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	--INSERT INTO #Team
	--SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Team) 

	--CREATE TABLE #Individual 
	--( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	--INSERT INTO #Individual
	--SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Individual) 


SELECT name AS [Name]
	, hierarchylevel2hist AS [Division]
	, hierarchylevel3hist AS [Department]
	, hierarchylevel4hist AS [Team]
	, normalworkingday AS [Contractual hours per day]
	, dim_employee.jobtitle
	, totalentitlementdays AS [Annual Holiday Allowance]
	, remaining_fte_working_days_year AS [Annual Working Days]
	, ISNULL([HolidaysTaken].durationholidaydays,0) AS [Holidays Taken to Date]
	, ISNULL(HolidaysTakenBeforeNov2020.HolidaysTakenbefore1stNov2020,0)-ISNULL([HolidaysTaken].durationholidaydays,0) AS [Holidays Booked before November 2020]
	, ISNULL(HolidaysTakenAfterNov2020.HolidaysTakenafter31stOct2020,0) AS [Holidays Booked on or after 1st November 2020]
	, ISNULL(totalentitlementdays,0)-ISNULL(HolidaysTakenBeforeNov2020.HolidaysTakenbefore1stNov2020,0)-ISNULL(HolidaysTakenAfterNov2020.HolidaysTakenafter31stOct2020,0) AS [Holidays yet to Take]
	, [Trading Days] AS [Working Days to Date]
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

-----Holidays Booked before Nov 2020
LEFT OUTER JOIN
				(SELECT  employeeid, SUM(durationdays) AS durationdays , SUM(durationholidaydays) AS HolidaysTakenbefore1stNov2020
				FROM red_dw.dbo.fact_employee_attendance

				WHERE  entitlement_year=(SELECT DISTINCT fin_year 
										FROM red_dw.dbo.dim_date
										WHERE current_fin_year='Current')
						AND category='Holiday'
						AND startdate<='2020-10-31'
						--AND employeeid  = 'A990411E-CEA8-424C-A421-C45A04F9392B'
				GROUP BY employeeid) AS HolidaysTakenBeforeNov2020

ON HolidaysTakenBeforeNov2020.employeeid = dim_employee.employeeid


-------------------------------------------------------------------------------------------------------------------------
--Holidays Booked after Oct 2020

LEFT OUTER JOIN
				(SELECT  employeeid, SUM(durationdays) AS durationdays , SUM(durationholidaydays) AS HolidaysTakenafter31stOct2020
				FROM red_dw.dbo.fact_employee_attendance

				WHERE  entitlement_year=(SELECT DISTINCT fin_year 
										FROM red_dw.dbo.dim_date
										WHERE current_fin_year='Current')
						AND category='Holiday'
						AND startdate>'2020-10-31'
						--AND employeeid  = 'A990411E-CEA8-424C-A421-C45A04F9392B'
				GROUP BY employeeid) AS HolidaysTakenAfterNov2020
ON HolidaysTakenAfterNov2020.employeeid = dim_employee.employeeid
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


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

	INNER JOIN #Division AS Division ON Division.ListValue = hierarchylevel2hist 
	INNER JOIN #Department AS Department ON Department.ListValue = hierarchylevel3hist 
	--INNER JOIN #Team AS Team ON Team.ListValue = REPLACE(hierarchylevel4hist,',','')
	--INNER JOIN #Individual AS Individual ON Individual.ListValue = name


WHERE leaver=0
AND red_dw.dbo.dim_employee.deleted_from_cascade <> 1 --added due to report bring back deleted emp
AND red_dw.dbo.dim_employee.employeestartdate <= GETDATE() -- bring in new starters 
--AND CASE WHEN ContractedHours.ContractedHours>0 THEN (ChargeableHours.ChargeableHours/ContractedHours.ContractedHours) END>0
 --AND dim_employee.employeeid='19AB983F-4D45-49AC-9155-B9BCA6B36D2F'

ORDER BY name
END
GO
