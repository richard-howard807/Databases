SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		J.Bonner
-- Create date: 2020/06/15
-- Description:	#59161 new 1-1 report to include data from new 1-1 form, LTA still using old 1-1 form
-- ====================================================================================

CREATE PROCEDURE [dbo].[new_monthly_121_status_report_v1]

	(
		@CalendarMonth VARCHAR(32)
		,@Division AS VARCHAR(MAX)
		,@Department AS VARCHAR(MAX)
		,@Team AS VARCHAR(MAX)
	)

AS

	
--DECLARE @CalendarMonth VARCHAR(32) = '202006'
--		,@Division AS VARCHAR(MAX) = 'Legal Ops - Claims'
--		--,@Department AS VARCHAR(MAX) = 'Healthcare'
--		,@Department AS VARCHAR(MAX) = 'Casualty|Claims Management|Disease|Healthcare|Large Loss|Motor'
--		,@Team AS VARCHAR(MAX) = 'Risk Pool|North West Healthcare 2|North West Healthcare 1|Niche Costs|Motor North and Midlands|Motor Manchester|Motor Management|Motor Mainstream|Motor Liverpool and Birmingham|Motor Liverpool|Motor Fraud|Motor Credit Hire|London Healthcare|Large Loss Midlands|Large Loss Manchester and Leeds|Large Loss Manchester 2|Large Loss Management|Large Loss London|Large Loss Liverpool 2|Large Loss Liverpool 1|Large Loss Liverpool|Healthcare Management|Fraud and Credit Hire Liverpool|Disease Midlands 2|Disease Midlands 1 and South|Disease Management|Disease Liverpool 3|Disease Liverpool 2|Disease Liverpool 1|Disease Leicester|Disease Birmingham 4|Disease Birmingham 3|Disease Birmingham 2 and London|Disease Birmingham 1|Clinical London|Clinical Liverpool and Manchester|Clinical Birmingham|Claims Management|Casualty Manchester|Casualty Management|Casualty London|Casualty Liverpool and Glasgow|Casualty Liverpool 2|Casualty Liverpool 1|Casualty Leicester|Casualty Glasgow|Casualty Birmingham 2|Casualty Birmingham 1|Casualty Birmingham|Birmingham Healthcare 2|Birmingham Healthcare 1'
--		--,@Team AS VARCHAR(MAX) = 'North West Healthcare 2|North West Healthcare 1|London Healthcare|Healthcare Management|Birmingham Healthcare 2|Birmingham Healthcare 1'

	
	DECLARE @StartDate  DATE = (SELECT MIN(calendar_date) FROM red_dw.dbo.dim_date WHERE cal_month=@CalendarMonth)
	DECLARE @EndDate  DATE = (SELECT MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE cal_month=@CalendarMonth)

       
	DROP TABLE IF EXISTS #Division
	DROP TABLE IF EXISTS #Department
	DROP TABLE IF EXISTS #Team

	DROP TABLE IF EXISTS #Cascade121
	DROP TABLE IF EXISTS #Employees
	DROP TABLE IF EXISTS #webapp121
	DROP TABLE IF EXISTS #Distinct121s

	SELECT value ListValue  INTO #Division FROM STRING_SPLIT(@Division,'|')
	SELECT value ListValue  INTO #Department FROM STRING_SPLIT(@Department,'|')
	SELECT value ListValue  INTO #Team FROM STRING_SPLIT(@Team,'|') 


--BEGIN



--========================================================================================================================
-- Get list of completed forms from Cascade
--========================================================================================================================

SELECT 
	ed.employeeid
	,1 AS [meeting_count] 
	,ROW_NUMBER() OVER(PARTITION BY ed.employeeid ORDER BY ed.dateofmeetingud) RowNo,
	dim_fed_hierarchy_history.hierarchylevel2hist,
	dim_fed_hierarchy_history.hierarchylevel3hist,
	dim_fed_hierarchy_history.hierarchylevel4hist
INTO #Cascade121
FROM red_dw.[dbo].[ds_sh_employee_one_to_one_meetings_client] ed 
LEFT JOIN red_dw.dbo.dim_date dc ON CAST(ed.dateofmeetingud AS DATE)=CAST(dc.calendar_date AS DATE)
INNER JOIN red_dw..dim_fed_hierarchy_history ON dim_fed_hierarchy_history.employeeid = ed.employeeid 
			AND CAST(ed.dateofmeetingud AS DATE) BETWEEN dim_fed_hierarchy_history.dss_start_date AND dim_fed_hierarchy_history.dss_end_date
WHERE dc.cal_month = @CalendarMonth


--========================================================================================================================
-- Get list of completed forms from 121 Web App
--========================================================================================================================


SELECT dim_employee.employeeid,
       1 AS [meeting_count],      
       ROW_NUMBER() OVER (PARTITION BY Detail.UserId ORDER BY Status.StatusDescription) AS [row_no],
	   	dim_fed_hierarchy_history.hierarchylevel2hist,
		dim_fed_hierarchy_history.hierarchylevel3hist,
		dim_fed_hierarchy_history.hierarchylevel4hist
INTO #webapp121
FROM [SVR-LIV-SQL-02].[O2O].[form].[Response]
INNER JOIN [SVR-LIV-SQL-02].[O2O].[form].[Detail] ON Detail.FormId = Response.FormId
INNER JOIN [SVR-LIV-SQL-02].[O2O].[form].[Status] ON Status.StatusId = Detail.StatusId
INNER JOIN red_dw.dbo.dim_date ON Response.DataAsOf = dim_date.calendar_date
INNER JOIN red_dw..dim_employee ON dim_employee.windowsusername = Detail.UserId COLLATE Latin1_General_BIN
INNER JOIN red_dw..dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key AND dim_fed_hierarchy_history.activeud = 1
			AND Response.DataAsOf BETWEEN dim_fed_hierarchy_history.dss_start_date AND dim_fed_hierarchy_history.dss_end_date
WHERE Status.StatusDescription = 'Completed'
-- Motor were using the new form in May 20 as the test department. Healthcare started using new form towards the end of May 20, created separate table for them
-- As form was being used earlier to test we have decided to include these as completed numbers where very low for March/April
AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
AND ( 
		(	dim_fed_hierarchy_history.hierarchylevel3hist IN ('Motor', 'Healthcare') and CAST(Response.DataAsOf AS DATE) >= '20200301' )
	OR 
		(	CAST(Response.DataAsOf AS DATE) >= '20200501')
	)
AND dim_date.cal_month = @CalendarMonth


--========================================================================================================================
-- Get list of distinct one 2 one forms
--========================================================================================================================
						
	SELECT *
		INTO #Distinct121s
	FROM (
			SELECT *, ROW_NUMBER() OVER (PARTITION BY employeeid ORDER BY employeeid) New_Row_No
			FROM (
						SELECT *, 'Cascade' system
						FROM #Cascade121 
						WHERE RowNo = 1

						UNION ALL

						SELECT *, 'WebApp'
						FROM #webapp121
						WHERE #webapp121.row_no = 1
				) x
		) DISTINCTLIST
	WHERE DISTINCTLIST.New_Row_No = 1


--========================================================================================================================
-- Build Employees 
--========================================================================================================================


SELECT red_dw.dbo.dim_fed_hierarchy_history.name [employee_name]
		,red_dw.dbo.dim_employee.employeeid	
		,1 AS EmpCount
		,CASE WHEN dim_fed_hierarchy_history.management_role_one IN ('Team Manager','Team Leader','Sector Lead','HoSD','Director' ) 
					OR red_dw.dbo.dim_employee.jobtitle IN ('Administration Assistant','Partner' ,'Legal Secretary','Head of Compliance','Trainee','Consultant','Legal Director')
					OR red_dw.dbo.dim_employee.levelidud IN ( 'Legal Support','Employed Consultant')
					OR dim_fed_hierarchy_history.hierarchylevel3hist LIKE '%Management%'
				  	OR DATEDIFF(MONTH, red_dw.dbo.dim_employee.employeestartdate, GETDATE()) <= 1 -- Employee has to have worked here for more than a month
				THEN 1 ELSE 0 
			END AS management_exclusions
		,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel2hist				AS division
		,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel3hist					AS department
		,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4hist					AS team
		,dim_employee.locationidud													AS office
		,Excluded.ExcludeCount
		,dim_fed_hierarchy_history.management_role_one
		,dim_fed_hierarchy_history.management_role_two
		,dim_employee.jobtitle
		,red_dw.dbo.dim_employee.employeestartdate
INTO #Employees
-- select *
FROM red_dw.dbo.dim_employee
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON UPPER(red_dw.dbo.dim_employee.employeeid) = red_dw.dbo.dim_fed_hierarchy_history.employeeid 
													AND red_dw.dbo.dim_fed_hierarchy_history.activeud = 1 AND red_dw.dbo.dim_fed_hierarchy_history.dss_current_flag='Y'
LEFT OUTER JOIN (SELECT fact_employee_attendance.employeeid
							, SUM(fact_employee_attendance.durationdays) / CAST(DATEDIFF(DAY, @StartDate, @EndDate) + 1 AS DECIMAL(10, 2)) [ExcludeCount]
				 FROM red_dw.dbo.fact_employee_attendance
				 WHERE fact_employee_attendance.startdate BETWEEN @StartDate AND @EndDate
						AND fact_employee_attendance.category <> 'Holiday'
				 GROUP BY employeeid)	AS [Excluded]  	ON red_dw.dbo.dim_employee.employeeid = Excluded.employeeid 	

INNER JOIN #Division AS Division ON Division.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel2hist COLLATE DATABASE_DEFAULT
INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel4hist COLLATE DATABASE_DEFAULT

WHERE 	(red_dw.dbo.dim_employee.leftdate IS NULL OR red_dw.dbo.dim_employee.leftdate > GETDATE()) 
		AND ISNULL(dim_fed_hierarchy_history.leaver, 0) = 0
		AND LOWER(red_dw.dbo.dim_employee.jobtitle) NOT LIKE '%trainee%'
		AND red_dw.dbo.dim_employee.employeestartdate <= @StartDate
		AND ISNULL(Excluded.ExcludeCount,0) < 0.5
		AND DATEDIFF(d,dim_employee.employeestartdate, @StartDate) > 15 -- over half of month in work 
		AND dim_fed_hierarchy_history.hierarchylevel2hist IN ('Legal Ops - LTA','Legal Ops - Claims')
		AND deleted_from_cascade = 0
--	AND dim_fed_hierarchy_history.name = 'Susan Carville'


--========================================================================================================================
-- Build Report Data 
--========================================================================================================================



SELECT DISTINCT #Employees.employee_name
		,#Employees.employeeid
		,ISNULL(#Distinct121s.meeting_count,0) OneToOneFlag
		,1 AS EmpCount
		,management_exclusions
		,#Employees.division
		,#Employees.department 
		,#Employees.team
		,#Employees.office
		,ExcludeCount
		,#Employees.management_role_one
		,#Employees.management_role_two
		,#Employees.jobtitle
		,#Employees.employeestartdate , #Distinct121s.system
FROM #Employees
LEFT OUTER JOIN #Distinct121s ON #Distinct121s.employeeid = #Employees.employeeid
WHERE ISNULL(#Employees.management_exclusions,0) = 0
GO
