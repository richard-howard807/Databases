SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		J.Bonner
-- Create date: 2020/06/15
-- Description:	#59161 new 1-1 report to include data from new 1-1 form, LTA still using old 1-1 form
-- ====================================================================================

CREATE PROCEDURE [dbo].[new_monthly_121_status_report]

	(
		@CalendarMonth VARCHAR(32)
		,@Division AS VARCHAR(MAX)
		,@Department AS VARCHAR(MAX)
		,@Team AS VARCHAR(MAX)
	)

AS

	-- For Testing purposes
	--DECLARE @CalendarMonth VARCHAR(32) = '202006'
	--	,@Division AS VARCHAR(MAX) = 'Legal Ops - Claims'
	--	,@Department AS VARCHAR(MAX) = 'Casualty|Claims Management|Disease|Healthcare|Large Loss|Motor'
	--	,@Team AS VARCHAR(MAX) = 'Risk Pool|North West Healthcare 2|North West Healthcare 1|Niche Costs|Motor North and Midlands|Motor Manchester|Motor Management|Motor Mainstream|Motor Liverpool and Birmingham|Motor Liverpool|Motor Fraud|Motor Credit Hire|London Healthcare|Large Loss Midlands|Large Loss Manchester and Leeds|Large Loss Manchester 2|Large Loss Management|Large Loss London|Large Loss Liverpool 2|Large Loss Liverpool 1|Large Loss Liverpool|Healthcare Management|Fraud and Credit Hire Liverpool|Disease Midlands 2|Disease Midlands 1 and South|Disease Management|Disease Liverpool 3|Disease Liverpool 2|Disease Liverpool 1|Disease Leicester|Disease Birmingham 4|Disease Birmingham 3|Disease Birmingham 2 and London|Disease Birmingham 1|Clinical London|Clinical Liverpool and Manchester|Clinical Birmingham|Claims Management|Casualty Manchester|Casualty Management|Casualty London|Casualty Liverpool and Glasgow|Casualty Liverpool 2|Casualty Liverpool 1|Casualty Leicester|Casualty Glasgow|Casualty Birmingham 2|Casualty Birmingham 1|Casualty Birmingham|Birmingham Healthcare 2|Birmingham Healthcare 1'
	
	
	DECLARE @StartDate  DATE = (SELECT MIN(calendar_date) FROM red_dw.dbo.dim_date WHERE cal_month=@CalendarMonth)
	DECLARE @EndDate  DATE = (SELECT MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE cal_month=@CalendarMonth)

       
	DROP TABLE IF EXISTS #Division
	DROP TABLE IF EXISTS #Department
	DROP TABLE IF EXISTS #Team
	DROP TABLE IF EXISTS #old_form
	DROP TABLE IF EXISTS #new_form

	SELECT value ListValue  INTO #Division FROM 	STRING_SPLIT(@Division,'|')
	SELECT value ListValue  INTO #Department FROM 	STRING_SPLIT(@Department,'|')
	SELECT value ListValue  INTO #Team FROM STRING_SPLIT(@Team,'|') 


BEGIN


--========================================================================================================================
-- Legal Ops - LTA query as not using new form yet and 1-1's done before new form came in for Legal Ops - Claims (June 20?)
--========================================================================================================================

	SELECT DISTINCT
		AllData.employee_name
		,AllData.employeeid
		,OneToOneFlag
		,1 AS EmpCount
		,management_exclusions
		,AllData.division
		,AllData.department 
		,AllData.team
		,AllData.office
		,ExcludeCount
		,AllData.management_role_one
		,AllData.management_role_two
		,AllData.jobtitle
		,AllData.employeestartdate 
	INTO #old_form
	FROM (
			SELECT red_dw.dbo.dim_fed_hierarchy_history.name [employee_name]
					,red_dw.dbo.dim_employee.employeeid
					,CASE WHEN (ISNULL(OneToOne.[meeting_count],0)= 0 OR Excluded.ExcludeCount >= 0.5) THEN 0 ELSE 1 END  AS OneToOneFlag
					,1 AS EmpCount
					,CASE WHEN dim_fed_hierarchy_history.management_role_one IN ('Team Manager','Team Leader','Sector Lead','HoSD','Director' ) 
								OR red_dw.dbo.dim_employee.jobtitle IN ('Administration Assistant','Partner' ,'Legal Secretary','Head of Compliance','Trainee','Consultant','Legal Director')
								OR red_dw.dbo.dim_employee.levelidud IN ( 'Legal Support','Employed Consultant')
				  				OR DATEDIFF(MONTH,red_dw.dbo.dim_employee.employeestartdate,GETDATE())<=1 -- Employee has to have worked here for more than a month
							THEN 1 ELSE 0 
						END AS management_exclusions
					,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel2hist					AS division
					,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel3hist					AS department
					,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4hist					AS team
					,dim_employee.locationidud													AS office
					,Excluded.ExcludeCount
					,dim_fed_hierarchy_history.management_role_one
					,dim_fed_hierarchy_history.management_role_two
					,dim_employee.jobtitle
					,red_dw.dbo.dim_employee.employeestartdate
				
			FROM red_dw.dbo.dim_employee
				INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
					ON UPPER(red_dw.dbo.dim_employee.employeeid) = red_dw.dbo.dim_fed_hierarchy_history.employeeid 
						AND red_dw.dbo.dim_fed_hierarchy_history.activeud = 1 AND red_dw.dbo.dim_fed_hierarchy_history.dss_current_flag='Y'
				LEFT JOIN (
							SELECT 
								ed.employeeid
								,1 AS [meeting_count] 
								,ROW_NUMBER() OVER(PARTITION BY ed.employeeid ORDER BY ed.dateofmeetingud)RowNo
							FROM red_dw.[dbo].[ds_sh_employee_one_to_one_meetings_client] ed 
							LEFT JOIN red_dw.dbo.dim_date dc 
								ON CAST(ed.dateofmeetingud AS DATE)=CAST(dc.calendar_date AS DATE)
							WHERE dc.cal_month = @CalendarMonth
						) OneToOne 
					ON red_dw.dbo.dim_employee.employeeid= OneToOne.employeeid AND RowNo=1
				LEFT OUTER JOIN (
									SELECT 
										fact_employee_attendance.employeeid
										, SUM(fact_employee_attendance.durationdays) / CAST(DATEDIFF(DAY, @StartDate, @EndDate) + 1 AS DECIMAL(10, 2)) [ExcludeCount]
									FROM red_dw.dbo.fact_employee_attendance
									WHERE 
										fact_employee_attendance.startdate BETWEEN @StartDate AND @EndDate
										AND fact_employee_attendance.category IN ('Furlough', 'Sickness', 'Maternity', 'Paternity')
									GROUP BY employeeid 

								)				AS [Excluded] 
					ON red_dw.dbo.dim_employee.employeeid = Excluded.employeeid
		  		  
				WHERE 
					(red_dw.dbo.dim_employee.leftdate IS NULL OR red_dw.dbo.dim_employee.leftdate > GETDATE()) 
					AND LOWER(red_dw.dbo.dim_employee.jobtitle)  NOT  LIKE '%trainee%'
					AND red_dw.dbo.dim_employee.employeestartdate <= @EndDate
		)			AS [AllData]
 
	 INNER JOIN #Division AS Division ON Division.ListValue COLLATE DATABASE_DEFAULT = Division COLLATE DATABASE_DEFAULT
	 INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = Department COLLATE DATABASE_DEFAULT
	 INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = AllData.Team COLLATE DATABASE_DEFAULT

	WHERE 
		AllData.employeestartdate NOT BETWEEN @StartDate AND @EndDate
		AND (@Division = 'Legal Ops - LTA' OR (@Division = 'Legal Ops - Claims' AND @CalendarMonth < '202006'))
	ORDER BY 
		AllData.employee_name




--========================================================================================================================
-- Legal Ops - Claims from June 20 onwards with new 1-1 form
--========================================================================================================================

	SELECT DISTINCT
		AllData.employee_name
		,AllData.employeeid
		,OneToOneFlag
		,1 AS EmpCount
		,management_exclusions
		,AllData.division 
		,AllData.department 
		,AllData.team
		,AllData.office
		,ExcludeCount
		,AllData.management_role_one
		,AllData.management_role_two
		,AllData.jobtitle
		,AllData.employeestartdate 
	INTO #new_form
	FROM (
			SELECT red_dw.dbo.dim_fed_hierarchy_history.name [employee_name]
					,red_dw.dbo.dim_employee.employeeid
					,CASE WHEN (ISNULL(OneToOne.Status, 'Outstanding')= 'Outstanding' OR Excluded.ExcludeCount >= 0.5) THEN 0 ELSE 1 END  AS OneToOneFlag
					, OneToOne.Status
					,1 AS EmpCount
					,CASE WHEN dim_fed_hierarchy_history.management_role_one IN ('Team Manager','Team Leader','Sector Lead','HoSD','Director' ) 
								OR red_dw.dbo.dim_employee.jobtitle IN ('Administration Assistant','Partner' ,'Legal Secretary','Head of Compliance','Trainee','Consultant','Legal Director')
								OR red_dw.dbo.dim_employee.levelidud IN ( 'Legal Support','Employed Consultant')
				  				OR DATEDIFF(MONTH,red_dw.dbo.dim_employee.employeestartdate,GETDATE())<=1 -- Employee has to have worked here for more than a month
							THEN 1 ELSE 0 
						END AS management_exclusions
					,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel2hist					AS division
					,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel3hist					AS department
					,red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4hist					AS team
					,dim_employee.locationidud													AS office
					,Excluded.ExcludeCount
					,dim_fed_hierarchy_history.management_role_one
					,dim_fed_hierarchy_history.management_role_two
					,dim_employee.jobtitle
					,red_dw.dbo.dim_employee.employeestartdate	
			FROM red_dw.dbo.dim_employee
				INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
					ON UPPER(red_dw.dbo.dim_employee.employeeid) = red_dw.dbo.dim_fed_hierarchy_history.employeeid 
						AND red_dw.dbo.dim_fed_hierarchy_history.activeud = 1 AND red_dw.dbo.dim_fed_hierarchy_history.dss_current_flag='Y'
				LEFT OUTER JOIN (
									SELECT 
										Detail.UserId
										, 1							AS [meeting_count]
										, CASE 
											WHEN Status.StatusDescription IN ('Pending Approval', 'In Progress', 'Deleted') THEN
												'Outstanding'
											ELSE 
												Status.StatusDescription
										  END										AS [Status]
										, CAST(Response.DataAsOf AS DATE)			AS [DataAsOf]
										, CAST(Detail.CompletedDateTime AS DATE)	AS [CompletedDateTime]
										, ROW_NUMBER() OVER(PARTITION BY Detail.UserId ORDER BY Status.StatusDescription)	AS [row_no]
									FROM [SVR-LIV-SQL-02].[O2O].[form].[Response]
										INNER JOIN [SVR-LIV-SQL-02].[O2O].[form].[Detail]
											ON Detail.FormId = Response.FormId
										INNER JOIN [SVR-LIV-SQL-02].[O2O].[form].[Status]
											ON Status.StatusId = Detail.StatusId
										INNER JOIN red_dw.dbo.dim_date
											ON Response.DataAsOf = dim_date.calendar_date
									WHERE 
										dim_date.cal_month = @CalendarMonth
								) AS OneToOne 
					ON dim_fed_hierarchy_history.windowsusername COLLATE DATABASE_DEFAULT = OneToOne.UserId COLLATE DATABASE_DEFAULT AND OneToOne.row_no = 1
				LEFT OUTER JOIN (
									SELECT 
										fact_employee_attendance.employeeid
										, SUM(fact_employee_attendance.durationdays) / CAST(DATEDIFF(DAY, @StartDate, @EndDate) + 1 AS DECIMAL(10, 2)) [ExcludeCount]
									FROM red_dw.dbo.fact_employee_attendance
									WHERE 
										fact_employee_attendance.startdate BETWEEN @StartDate AND @EndDate
										AND fact_employee_attendance.category IN ('Furlough', 'Sickness', 'Maternity', 'Paternity')
									GROUP BY employeeid 

								)				AS [Excluded] 
					ON red_dw.dbo.dim_employee.employeeid = Excluded.employeeid
		  		  
				WHERE 
					(red_dw.dbo.dim_employee.leftdate IS NULL OR red_dw.dbo.dim_employee.leftdate > GETDATE()) 
					AND LOWER(red_dw.dbo.dim_employee.jobtitle)  NOT  LIKE '%trainee%'
					AND red_dw.dbo.dim_employee.employeestartdate <= @EndDate
		)			AS [AllData]
 
	 INNER JOIN #Division AS Division ON Division.ListValue COLLATE DATABASE_DEFAULT = Division COLLATE DATABASE_DEFAULT
	 INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = Department COLLATE DATABASE_DEFAULT
	 INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = AllData.Team COLLATE DATABASE_DEFAULT

	WHERE 
		AllData.employeestartdate NOT BETWEEN @StartDate AND @EndDate
		AND (@Division = 'Legal Ops - Claims' AND @CalendarMonth >= '202006')
	ORDER BY 
		AllData.employee_name



--==================================================================================================================================================
-- Union of old_form & new_form tables
--==================================================================================================================================================
SELECT *
FROM #old_form

UNION ALL

SELECT *
FROM #new_form

END



		   
GO
