SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-09-13
-- Description:	Data for Risk and Complaince to keep track of audits created on audit comply
-- =============================================
-- JB 05-10-2021 - changed exclude flag and reason to 20% rather than 80% as per Hillary Stephenson's request. Also added min_quarter_month and max_quarter_month columns for final audit quarter column
CREATE PROCEDURE [audit].[ACInternalAudits]

( @Template AS NVARCHAR(MAX)
, @AuditYear AS NVARCHAR(50)
)
as


--DECLARE @Template AS NVARCHAR(MAX)
--, @AuditYear AS NVARCHAR(50)
--SET @Template='Claims Audit'
--SET @AuditYear='2021/2022'


DROP TABLE IF EXISTS #Template
drop table if exists #Audits
drop table if exists #EmployeeDates
drop table if exists #exclude_data

SELECT ListValue  INTO #Template  FROM Reporting.dbo.[udt_TallySplit]('|', @Template)


	
		SELECT  pvt3.employeeid
			, name AS [Auditee Name]
			, auditeekey AS [Auditee key]
			, pvt3.auditee_emp_key
			, CASE WHEN position LIKE '%1%' THEN 1
			WHEN position LIKE '%2%' THEN 2
			WHEN position LIKE '%3%' THEN 3 END AS [Auditee Poistion]
			, [Client Code]
			, [Matter Number]
			, [Date]
			, [Status]
			, [Template]
			, [Auditor]
			, pvt3.fin_quarter
			, pvt3.fin_quarter_no
			, pvt3.fin_year
			into #Audits
		FROM (SELECT auditor.employeeid
				, dim_ac_audits.auditee_1_name AS [Auditee Name 1]
				, dim_ac_audits.dim_auditee1_hierarchy_history_key AS [Auditee Key 1]
				, audite1.employeeid Auditee_Emp_key_1
				, dim_ac_audits.auditee_2_name AS [Auditee Name 2]
				, dim_ac_audits.dim_auditee2_hierarchy_history_key AS [Auditee Key 2]
				, audite2.employeeid Auditee_Emp_key_2
				, dim_ac_audits.auditee_3_name AS [Auditee Name 3]
				, dim_ac_audits.dim_auditee3_hierarchy_history_key AS [Auditee Key 3]
				, audite3.employeeid Auditee_Emp_key_3
				, dim_ac_audits.client_code AS [Client Code]
				, dim_ac_audits.matter_number AS [Matter Number]
				, dim_ac_audits.completed_at AS [Date]
				, dim_ac_audits.status AS [Status]
				, dim_ac_audit_type.name AS [Template]
				, auditor.name AS [Auditor]
				, dim_date.fin_quarter
				, dim_date.fin_quarter_no
				, dim_date.fin_year

				--	SELECT * from red_dw..dim_date
				from red_dw.dbo.dim_ac_audits
				LEFT OUTER JOIN red_dw.dbo.dim_ac_audit_type
				ON dim_ac_audit_type.dim_ac_audit_type_key = dim_ac_audits.dim_ac_audit_type_key
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS [auditor]
				ON auditor.dim_fed_hierarchy_history_key=dim_ac_audits.dim_auditor_fed_hierarchy_history_key

				INNER JOIN #Template AS Template ON Template.ListValue COLLATE DATABASE_DEFAULT =  dim_ac_audit_type.name COLLATE DATABASE_DEFAULT
				inner join red_dw..dim_date on dim_date.dim_date_key = dim_ac_audits.dim_completed_date_key

				inner join red_dw..dim_fed_hierarchy_history audite1 on audite1.dim_fed_hierarchy_history_key = dim_ac_audits.dim_auditee1_hierarchy_history_key
				left outer join red_dw..dim_fed_hierarchy_history audite2 on audite2.dim_fed_hierarchy_history_key = dim_ac_audits.dim_auditee2_hierarchy_history_key				
				left outer join red_dw..dim_fed_hierarchy_history audite3 on audite3.dim_fed_hierarchy_history_key = dim_ac_audits.dim_auditee3_hierarchy_history_key

				WHERE dim_ac_audits.created_at >='2021-09-01'
				and dim_ac_audits.dim_auditee1_hierarchy_history_key <> 0 
		) src

		UNPIVOT (name FOR position IN ([Auditee Name 1], [Auditee Name 2], [Auditee Name 3]))pvt1
		UNPIVOT (auditeekey FOR akey IN ([Auditee Key 1], [Auditee Key 2], [Auditee Key 3]))pvt2
		UNPIVOT (auditee_emp_key FOR empkey IN ([Auditee_Emp_key_1], [Auditee_Emp_key_2], [Auditee_Emp_key_3]))pvt3


		WHERE  RIGHT(akey,1)=RIGHT(position,1)
		and  RIGHT(empkey,1)=RIGHT(position,1)
		

select
	employees.employeeid, CAST(dim_date.fin_year -1 AS varchar(4))+'/'+CAST(dim_date.fin_year as varchar(4)) audit_year,
	dim_date.calendar_date, dim_date.fin_quarter, employees.employeestartdate, employees.employeestartdate_fin_year, employees.leftdate,
	employees.Name, employees.Department, employees.Team, employees.Division,
	case when employeestartdate >= dateadd(month, -3, dim_date.calendar_date) then 1
	when leftdate < dim_date.calendar_date then 2
	end as exclude
	, dim_date.fin_quarter_no
	, quarter_name.min_quarter_month
	, quarter_name.max_quarter_month
into #EmployeeDates
from red_dw.dbo.dim_date
INNER JOIN (SELECT DISTINCT
				dim_date.fin_quarter_no
				, dim_date.fin_quarter
				, dim_date.fin_year
				, FIRST_VALUE(dim_date.fin_month_name) OVER(PARTITION BY dim_date.fin_year, dim_date.fin_quarter, dim_date.fin_quarter_no ORDER BY dim_date.fin_quarter_no, dim_date.fin_month_no) AS min_quarter_month
				, LAST_VALUE(dim_date.fin_month_name) OVER(PARTITION BY dim_date.fin_year, dim_date.fin_quarter, dim_date.fin_quarter_no ORDER BY dim_date.fin_quarter_no) AS max_quarter_month
			FROM red_dw.dbo.dim_date) quarter_name on quarter_name.fin_quarter = dim_date.fin_quarter
cross apply (select distinct dim_employee.employeeid, dim_employee.employeestartdate, start_year.fin_year AS employeestartdate_fin_year, dim_employee.leftdate
				, name AS [Name]
				, dim_fed_hierarchy_history.hierarchylevel2hist AS [Division]
				, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
				, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
			from red_dw.dbo.dim_employee
			LEFT OUTER JOIN red_dw.dbo.dim_date AS start_year ON start_year.calendar_date = CAST(dim_employee.employeestartdate AS DATE)
			left outer join red_dw.dbo.dim_date on cast(dim_employee.leftdate as date) = dim_date.calendar_date
			LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
				AND dim_fed_hierarchy_history.dss_current_flag='Y'
				AND dim_fed_hierarchy_history.activeud=1
				where dim_employee.deleted_from_cascade = 0
				and dim_employee.classification = 'Casehandler'
				AND dim_fed_hierarchy_history.hierarchylevel2hist IN ('Legal Ops - Claims', 'Legal Ops - LTA')
				--and dim_employee.employeeid = '855920FD-6007-49F0-B1A5-0B391B2176FD'
				and isnull(dim_date.fin_year, '2099') >= (select distinct fin_year from red_dw.dbo.dim_date where CAST(dim_date.fin_year -1 AS varchar(4))+'/'+CAST(dim_date.fin_year as varchar(4)) = @AuditYear ) -- exclude leavers after financial year they left
		) employees
where CAST(dim_date.fin_year -1 AS varchar(4))+'/'+CAST(dim_date.fin_year as varchar(4)) = @AuditYear
--and dim_date.calendar_date >= employees.employeestartdate
--and dim_date.calendar_date <= isnull(employees.leftdate, '20990101')
AND dim_date.fin_year >= employees.employeestartdate_fin_year


select #EmployeeDates.employeeid, #EmployeeDates.fin_quarter, #EmployeeDates.fin_quarter_no, #EmployeeDates.min_quarter_month, #EmployeeDates.max_quarter_month,
		#EmployeeDates.Division, #EmployeeDates.Department, #EmployeeDates.Team, #EmployeeDates.Name, #EmployeeDates.audit_year,
		count(#EmployeeDates.calendar_date) days_in_qtr, 
		sum(fact_employee_attendance.durationdays) days_absent
		, case  when max(#EmployeeDates.exclude) = 1 then 'Started ' + cast(cast(#EmployeeDates.employeestartdate as date) as varchar(12))
				when max(#EmployeeDates.exclude) = 2 then 'Left ' +  cast(cast(#EmployeeDates.leftdate as date) as varchar(12))
				when sum(fact_employee_attendance.durationdays) / count(#EmployeeDates.calendar_date) > .2 
				     then (select string_agg(val, ', ') from (select distinct val from dbo.split_delimited_to_rows(string_agg(category, ','),',')) x ) 
		  end as reason

		, case  when max(#EmployeeDates.exclude) in (1,2) then 1
				when sum(fact_employee_attendance.durationdays) / count(#EmployeeDates.calendar_date) > .2 then 1 
				
		  end as exclude_flag
  into #exclude_data
from #EmployeeDates
left outer join (select fact_employee_attendance.employeeid, fact_employee_attendance.durationdays, fact_employee_attendance.category, fact_employee_attendance.startdate
				from red_dw..fact_employee_attendance 
				where fact_employee_attendance.category IN
					(
					N'Adoption',
					N'Dependant Leave',
					N'Furlough',
					N'Jury Service',
					N'Maternity',
					N'Paid Dependant Leave',
					N'Secondment',
					N'Sabbatical',
					N'Unpaid Leave'
					)
				
				) fact_employee_attendance on #EmployeeDates.calendar_date = fact_employee_attendance.startdate and #EmployeeDates.employeeid = fact_employee_attendance.employeeid

group by #EmployeeDates.employeeid
       , #EmployeeDates.fin_quarter
	   , #EmployeeDates.employeestartdate
	   , #EmployeeDates.leftdate
	   , #EmployeeDates.Department
	   , #EmployeeDates.Division
	   , #EmployeeDates.Team
	   , #EmployeeDates.Name
	   , #EmployeeDates.audit_year
	   , #EmployeeDates.fin_quarter_no
	   , #EmployeeDates.min_quarter_month
	   , #EmployeeDates.max_quarter_month



select  #exclude_data.employeeid
		, #exclude_data.Division
		, #exclude_data.Department
		, #exclude_data.Team
		, #exclude_data.Name
		, #Audits.Auditor
		, #Audits.[Auditee Poistion]
		, CASE WHEN #Audits.Date IS NOT NULL THEN 1 ELSE 0 END AS [Audits Completed]
		, CASE WHEN #Audits.Status='Pass' THEN 1 ELSE 0 END AS [Audits Passed]
		, #Audits.[Client Code]
		, #Audits.[Matter Number]
		, #Audits.Date
		, #Audits.Status
		, #Audits.Template
		, #exclude_data.audit_year [Audit Year]
		, 'Q' + cast(#exclude_data.fin_quarter_no as varchar(1)) + ' ' + #exclude_data.min_quarter_month + '-' + #exclude_data.max_quarter_month [Audit Quarter]
		, #exclude_data.exclude_flag
		, #exclude_data.reason
from #exclude_data
left outer join #Audits on #Audits.auditee_emp_key = #exclude_data.employeeid and #Audits.fin_quarter = #exclude_data.fin_quarter
-- where #exclude_data.employeeid = '5D9FBEA8-1E61-48A0-A769-CEEB303C4A99'
order by #exclude_data.employeeid



GO
