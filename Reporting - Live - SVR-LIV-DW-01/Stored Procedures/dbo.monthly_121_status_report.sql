SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		J.Robinson
-- Create date: 2015/02/16
-- Description:	Optimal 1:1 Status Report, ticket 84095
-- exec [SolvingDisputes].[Monthly1_1StatusReportV2] '201808','Legal Ops - LTA','EPI','EPI Liverpool'
-- ====================================================================================
-- LD 20181005 - excluded employees that hadn't started before the end of the month.
-- LD 20191024 - rewritten to point to svr-liv-dw-01 instead of SQL2008SVR
-- =============================================
CREATE PROCEDURE [dbo].[monthly_121_status_report]

	(
		@CalendarMonth VARCHAR(32)
		,@Division AS VARCHAR(MAX)
		,@Department AS VARCHAR(MAX)
		,@Team AS VARCHAR(MAX)
	)

AS

	-- For Testing purposes
	--DECLARE 	@CalendarMonth VARCHAR(32) = '201909'
	--	,@Division AS VARCHAR(MAX) = 'Legal Ops - Claims'
	--	,@Department AS VARCHAR(MAX) = 'Large Loss'
	--	,@Team AS VARCHAR(MAX) = 'Large Loss Midlands|Large Loss London|Large Loss Liverpool'
	
	
	DECLARE @StartDate  DATE = (SELECT MIN(calendar_date) FROM red_dw.dbo.dim_date WHERE cal_month=@CalendarMonth)
	DECLARE @EndDate  DATE = (SELECT MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE cal_month=@CalendarMonth)

       
	DROP TABLE IF EXISTS #Division
	DROP TABLE IF EXISTS #Department
	DROP TABLE IF EXISTS #Team

	SELECT value ListValue  INTO #Division FROM 	STRING_SPLIT(@Division,'|')
	SELECT value ListValue  INTO #Department FROM 	STRING_SPLIT(@Department,'|')
	SELECT value ListValue  INTO #Team FROM STRING_SPLIT(@Team,'|') 

	-- top bit tested:  below is being rewritten in Main Select Monthly

BEGIN

SELECT 
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
	,AllData.managementroleud
	,AllData.managementrole2ud
	,AllData.jobtitle
	,EmployeeStartDate 
FROM 
(

SELECT  employee_hierarchy.name [employee_name]
		,employee.employeeid
		,CASE WHEN (ISNULL(OneToOne.[meeting_count],0)= 0 OR Excluded.ExcludeCount >= 0.5) THEN 0 ELSE 1 END  AS OneToOneFlag
		,1 AS EmpCount
		,CASE WHEN employee_jobs.managementroleud IN ('Team Manager','Team Leader','Sector Lead','HoSD','Director' ) 
					OR employee_jobs.jobtitle IN ('Administration Assistant','Partner' ,'Legal Secretary','Head of Compliance','Trainee','Consultant','Legal Director')
					OR employee_jobs.levelidud IN ( 'Legal Support','Employed Consultant')
				  	OR DATEDIFF(MONTH,employee.employeestartdate,GETDATE())<=1 -- Employee has to have worked here for more than a month
			  THEN 1 ELSE 0 
		 END AS management_exclusions
		,employee_hierarchy.hierarchylevel2hist AS division
		,employee_hierarchy.hierarchylevel3hist AS department
		,employee_hierarchy.hierarchylevel4hist AS team
		,employee_jobs.locationidud				AS office
		,Excluded.ExcludeCount
		,employee_jobs.managementroleud 
		,employee_jobs.managementrole2ud 
		,employee_jobs.jobtitle 
		,employee.employeestartdate
				
FROM [red_dw].[dbo].[ds_sh_employee] employee
INNER JOIN [red_dw].[dbo].[load_cascade_employee_jobs] employee_jobs ON employee.employeeid = employee_jobs.employeeid AND employee_jobs.sys_activejob = 1 AND employee.dss_current_flag = 'Y'
INNER JOIN [red_dw].[dbo].[dim_fed_hierarchy_history] employee_hierarchy ON UPPER(employee.employeeid) = employee_hierarchy.employeeid AND employee_hierarchy.activeud = 1 AND employee_hierarchy.dss_current_flag='Y'
LEFT JOIN (SELECT 
                   ed.employeeid
				  ,1 AS [meeting_count] 
				  ,ROW_NUMBER() OVER(PARTITION BY ed.employeeid ORDER BY ed.dateofmeetingud)RowNo
		   FROM red_dw.[dbo].[ds_sh_employee_one_to_one_meetings_client] ed 
		   LEFT JOIN red_dw.dbo.dim_date dc ON CAST(ed.dateofmeetingud AS DATE)=CAST(dc.calendar_date AS DATE)
		   WHERE dc.cal_month = @CalendarMonth
		  ) OneToOne ON employee.employeeid=OneToOne.employeeid AND RowNo=1



LEFT JOIN (SELECT data1.employeeid, SUM(ExcludeCount) AS ExcludeCount
		   
		   FROM (SELECT DISTINCT  eat.employeeid
		       
					,CASE WHEN eat.startdate < @StartDate AND category IN ('Sickness','Secondment') AND eat.enddate >= @StartDate 
						THEN CAST(DATEDIFF(DAY,@StartDate,enddate) AS DECIMAL(10,2)) / CAST(DATEDIFF(DAY,@StartDate,@EndDate) AS DECIMAL(10,2))
					 
					  WHEN eat.startdate >= @StartDate AND category IN ('Sickness','Secondment') AND eat.enddate >= @StartDate
						THEN CAST(DATEDIFF(DAY,startdate,enddate) AS DECIMAL(10,2)) / CAST(DATEDIFF(DAY,@StartDate,@EndDate) AS DECIMAL(10,2))
			          WHEN ((eat.category ='Maternity' OR [type] ='Maternity') AND eat.enddate >=@StartDate) THEN 1 ELSE 0 END AS ExcludeCount
									
				  FROM red_dw.[dbo].[ds_sh_employee_attendance] eat  
				
				 
				  WHERE (	(startdate <=@StartDate AND enddate >=@EndDate OR enddate BETWEEN @StartDate AND @EndDate)
						  AND category IN ('Sickness','Secondment')
					  )
	
				  OR
					  (		( ( [type]='Maternity' AND eat.enddate >=@StartDate AND eat.startdate <= @EndDate)
							  )
					  )
				   )data1
		   GROUP BY EmployeeId
		  )Excluded ON employee.employeeid = Excluded.employeeid
		  		  
WHERE employee.leaver = 0  AND LOWER(employee_jobs.jobtitle)  NOT  LIKE '%trainee%'

AND employee.employeestartdate <= @EndDate

) AS AllData
 INNER JOIN #Division AS Division ON Division.ListValue COLLATE DATABASE_DEFAULT = Division COLLATE DATABASE_DEFAULT
 INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = Department COLLATE DATABASE_DEFAULT
 INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = AllData.Team COLLATE DATABASE_DEFAULT

WHERE EmployeeStartDate NOT BETWEEN @StartDate AND @EndDate
ORDER BY AllData.employee_name

END



		   
GO
