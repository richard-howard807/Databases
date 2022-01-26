SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--SET QUOTED_IDENTIFIER ON
--SET ANSI_NULLS ON
--GO
---- =============================================
---- Author:		Emily Smith
---- Create date: 2021-09-13
---- Description:	Data for Risk and Complaince to keep track of audits created on audit comply
---- =============================================

---- JB 05-10-2021 - changed exclude flag and reason to 20% rather than 80% as per Hillary Stephenson's request. Also added min_quarter_month and max_quarter_month columns for final audit quarter column
---- JB 18-11-2021 - added NHS audit data 
---- JB 19-11-2021 - added HSD/Director/Trainee exclusions
---- RH 25-11-2021 - changed logic so that audits are always assigned to Qtr 1,2,3 & 4 in order regardless of when they are completed 
---- RH 25-11-2021 - Removed HSD/Director Logic, added sickness as exclusion criteria

CREATE PROCEDURE [audit].[ACInternalAudits]

( @Template AS NVARCHAR(MAX)
, @AuditYear AS NVARCHAR(50)
)
as


--DECLARE @Template AS NVARCHAR(MAX)
--, @AuditYear AS NVARCHAR(50)
--, @hsd_director AS NVARCHAR(MAX);
--SET @Template='Claims Audit|NHSR';
--SET @AuditYear='2021/2022';
--SET @hsd_director = '';-- '80B7D2FD-FE8B-4EC6-8D30-3B0A18C41F1D|65A08A7D-0242-4313-8DEA-8CE7E7C69170|D334CEA3-0FA4-4888-BE08-84B7F8D5A05D|DFD60922-F31F-4A76-AF90-C8A5E53B6350|EA6187FC-B92F-4A39-9FC8-7DF9572B1EB8|80B7D2FD-FE8B-4EC6-8D30-3B0A18C41F1D|DFD60922-F31F-4A76-AF90-C8A5E53B6350|EA6187FC-B92F-4A39-9FC8-7DF9572B1EB8|EA6187FC-B92F-4A39-9FC8-7DF9572B1EB8|B0CA9C28-B845-4B22-B3D9-972051F5DA72|B0CA9C28-B845-4B22-B3D9-972051F5DA72|B0CA9C28-B845-4B22-B3D9-972051F5DA72|DFD60922-F31F-4A76-AF90-C8A5E53B6350|DFD60922-F31F-4A76-AF90-C8A5E53B6350|65A08A7D-0242-4313-8DEA-8CE7E7C69170|D334CEA3-0FA4-4888-BE08-84B7F8D5A05D|463720C0-6995-4D1B-A296-3E6AEA43A32F|463720C0-6995-4D1B-A296-3E6AEA43A32F|463720C0-6995-4D1B-A296-3E6AEA43A32F|D334CEA3-0FA4-4888-BE08-84B7F8D5A05D|463720C0-6995-4D1B-A296-3E6AEA43A32F|80B7D2FD-FE8B-4EC6-8D30-3B0A18C41F1D|B0CA9C28-B845-4B22-B3D9-972051F5DA72|65A08A7D-0242-4313-8DEA-8CE7E7C69170|D334CEA3-0FA4-4888-BE08-84B7F8D5A05D|DFD60922-F31F-4A76-AF90-C8A5E53B6350|463720C0-6995-4D1B-A296-3E6AEA43A32F|65A08A7D-0242-4313-8DEA-8CE7E7C69170|D334CEA3-0FA4-4888-BE08-84B7F8D5A05D|65A08A7D-0242-4313-8DEA-8CE7E7C69170|DFD60922-F31F-4A76-AF90-C8A5E53B6350|80B7D2FD-FE8B-4EC6-8D30-3B0A18C41F1D|B0CA9C28-B845-4B22-B3D9-972051F5DA72|EE5B88B9-DBE7-422A-9911-12661FC930A3|80B7D2FD-FE8B-4EC6-8D30-3B0A18C41F1D|B0CA9C28-B845-4B22-B3D9-972051F5DA72|65A08A7D-0242-4313-8DEA-8CE7E7C69170|D334CEA3-0FA4-4888-BE08-84B7F8D5A05D|DFD60922-F31F-4A76-AF90-C8A5E53B6350|EE5B88B9-DBE7-422A-9911-12661FC930A3'


DROP TABLE IF EXISTS #Template;
DROP TABLE IF EXISTS #hsd_director;
DROP TABLE IF EXISTS #Audits;
DROP TABLE IF EXISTS #EmployeeDates;
DROP TABLE IF EXISTS #exclude_data;
drop table if exists #Audits_Calculated;

SELECT ListValue  INTO #Template  FROM Reporting.dbo.[udt_TallySplit]('|', @Template);


	
		SELECT  pvt3.audit_id
			,pvt3.employeeid
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
		FROM (SELECT 
					dim_ac_audits.audit_id,
					auditor.employeeid
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
		
		UNION	

		--NHSR audits
		select dim_matter_header_current.dim_matter_header_curr_key auditid,
			dim_fed_hierarchy_history.employeeid		AS employeeid
			, dim_matter_header_current.matter_owner_full_name		AS [Auditee Name]
			, dim_fed_hierarchy_history.dim_fed_hierarchy_history_key		AS [Auditee key]
			, dim_fed_hierarchy_history.employeeid		AS auditee_emp_key
			, 1			AS [Auditee Position]
			, dim_matter_header_current.client_code		AS [Client Code]
			, dim_matter_header_current.matter_number		AS [Matter Number]
			, dim_date.calendar_date		AS [Date]
		--------------------------------MS team changing score logic------------------------------------------
			, CASE
				WHEN fact_child_detail.nhs_audit_score >= 90 THEN
					'Pass'
				WHEN fact_child_detail.nhs_audit_score BETWEEN 70 AND 90 THEN
					'Warning'
				ELSE
					'Fail'
			  END				AS [Status]	
		------------------------------------------------------------------------------------------------------
			, 'NHSR'		AS [Template]
			, NULL		AS [Auditor]
			, dim_date.fin_quarter		AS fin_quarter
			, dim_date.fin_quarter_no		AS fin_quarter_no
			, dim_date.fin_year		AS fin_year
		--	SELECT DISTINCT dim_child_detail.*
		FROM red_dw.dbo.dim_matter_header_current
			INNER JOIN red_dw.dbo.fact_dimension_main
				ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
			INNER JOIN red_dw.dbo.dim_parent_detail
				ON dim_parent_detail.client_code = dim_matter_header_current.client_code
					AND dim_parent_detail.matter_number = dim_matter_header_current.matter_number
			INNER JOIN red_dw.dbo.fact_child_detail
				ON fact_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
			INNER JOIN red_dw.dbo.dim_date
				ON dim_date.calendar_date = CAST(dim_parent_detail.nhs_audit_date AS DATE)
			INNER JOIN #Template
				ON #Template.ListValue = 'NHSR'
		WHERE
			dim_parent_detail.nhs_audit_date IS NOT NULL
			AND fact_child_detail.nhs_audit_score IS NOT NULL
			AND dim_matter_header_current.master_client_code <> '30645'
			AND dim_date.calendar_date >= '2021-09-01'

		UNION	

		--MIB audits
		select dim_matter_header_current.dim_matter_header_curr_key auditid,
			dim_fed_hierarchy_history.employeeid		AS employeeid
			, dim_matter_header_current.matter_owner_full_name		AS [Auditee Name]
			, dim_fed_hierarchy_history.dim_fed_hierarchy_history_key		AS [Auditee key]
			, dim_fed_hierarchy_history.employeeid		AS auditee_emp_key
			, 1			AS [Auditee Position]
			, dim_matter_header_current.client_code		AS [Client Code]
			, dim_matter_header_current.matter_number		AS [Matter Number]
			, dim_date.calendar_date		AS [Date]
			, NULL				AS [Status]	
			, 'MIB'		AS [Template]
			, NULL		AS [Auditor]
			, dim_date.fin_quarter		AS fin_quarter
			, dim_date.fin_quarter_no		AS fin_quarter_no
			, dim_date.fin_year		AS fin_year
		FROM red_dw.dbo.dim_matter_header_current
			INNER JOIN red_dw.dbo.fact_dimension_main
				ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
			INNER JOIN red_dw.dbo.dim_detail_audit
				ON dim_detail_audit.dim_detail_audit_key = fact_dimension_main.dim_detail_audit_key 
			INNER JOIN red_dw.dbo.dim_date
				ON dim_date.calendar_date = CAST(dim_detail_audit.client_screen_date_of_audit AS DATE)
			INNER JOIN #Template
				ON #Template.ListValue = 'MIB'
		WHERE
			dim_matter_header_current.master_client_code = 'M1001'
			AND dim_detail_audit.client_screen_date_of_audit IS NOT NULL
			AND dim_date.calendar_date >= '2021-09-01'

	union all

	

	select dbFile.fileID auditid
	, auditor.employeeid 
	, dbFile.fileDesc collate Latin1_General_CI_AS [Auditee Name] 
	, dim_fed_hierarchy_history.dim_fed_hierarchy_history_key [Auditee key]
	, dim_fed_hierarchy_history.employeeid [auditee_emp_key]
	, 1 [Auditee Position]
	--, txtClMtNo MatterRef
	, replace(left(ltrim(rtrim(x.val)), charindex('-',ltrim(rtrim(x.val)),1)), '-','') collate Latin1_General_CI_AS client_code
	, substring(ltrim(rtrim(x.val)), charindex('-',ltrim(rtrim(x.val)),1) +1, 8) collate Latin1_General_CI_AS matter_number
	, [red_dw].[dbo].[datetimelocal](dteDateAudit) Date
	--, udRiskSearchList.txtReason
	, 'Pass' Status
	, 'August 21 MS Audits' Template
	, auditor.name Auditor
	, '2022-Q2' fin_quarter
	--,txtTMName
	, 2 fin_quarter_no
	, 2022 fin_year

	FROM MS_Prod.dbo.udRiskSearchList 
	INNER JOIN MS_Prod.config.dbFile
	 ON udRiskSearchList.fileID=dbFile.fileID
	 INNER JOIN red_dw.dbo.dim_matter_header_current header ON MS_Prod.config.dbFile.fileID = header.ms_fileid
	INNER JOIN MS_Prod.config.dbClient
	 ON dbFile.clID=dbClient.clID
	 inner join red_dw..dim_matter_header_current on dbFile.fileID = dim_matter_header_current.ms_fileid
	 inner join red_dw..dim_fed_hierarchy_history on dim_fed_hierarchy_history.name = dbFile.fileDesc collate Latin1_General_CI_AS
											and [red_dw].[dbo].[datetimelocal](dteDateAudit) between dim_fed_hierarchy_history.dss_start_date and dim_fed_hierarchy_history.dss_end_date 
											and dim_fed_hierarchy_history.activeud = 1
	 inner join red_dw..dim_fed_hierarchy_history auditor on auditor.fed_code = dim_matter_header_current.fee_earner_code and auditor.dss_current_flag = 'Y' and auditor.activeud = 1
	 cross apply (select val from dbo.split_delimited_to_rows(txtClMtNo, ','))  x

	 INNER JOIN #Template
				ON #Template.ListValue = 'August 21 MS Audits'

	 WHERE [red_dw].[dbo].[datetimelocal](dteDateAudit) between '20210801' and '20210901'
		 ;


select
	employees.employeeid, CAST(dim_date.fin_year -1 AS varchar(4))+'/'+CAST(dim_date.fin_year as varchar(4)) audit_year,
	dim_date.calendar_date, dim_date.fin_quarter, employees.employeestartdate, employees.employeestartdate_fin_year, employees.leftdate,
	employees.Name, employees.Department, employees.Team, employees.Division,
	case when employeestartdate >= dateadd(month, -3, dim_date.calendar_date) then 1
	when leftdate < dim_date.calendar_date then 2
	when not_current_active = 1 then 3
	end as exclude
	, dim_date.fin_quarter_no
	, quarter_name.min_quarter_month
	, quarter_name.max_quarter_month
	, employees.jobtitle
into #EmployeeDates
from red_dw.dbo.dim_date
INNER JOIN (SELECT DISTINCT
				dim_date.fin_quarter_no
				, dim_date.fin_quarter
				, dim_date.fin_year
				, FIRST_VALUE(dim_date.fin_month_name) OVER(PARTITION BY dim_date.fin_year, dim_date.fin_quarter, dim_date.fin_quarter_no ORDER BY dim_date.fin_quarter_no, dim_date.fin_month_no) AS min_quarter_month
				, LAST_VALUE(dim_date.fin_month_name) OVER(PARTITION BY dim_date.fin_year, dim_date.fin_quarter, dim_date.fin_quarter_no ORDER BY dim_date.fin_quarter_no) AS max_quarter_month
			FROM red_dw.dbo.dim_date) quarter_name on quarter_name.fin_quarter = dim_date.fin_quarter
			cross apply (select distinct dim_employee.employeeid, dim_employee.employeestartdate, start_year.fin_year AS employeestartdate_fin_year, dim_employee.leftdate, dim_employee.not_current_active
				, name AS [Name]
				, dim_fed_hierarchy_history.hierarchylevel2hist AS [Division]
				, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
				, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
				, dim_employee.jobtitle
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
AND dim_date.fin_year >= employees.employeestartdate_fin_year;


select #EmployeeDates.employeeid, #EmployeeDates.fin_quarter, #EmployeeDates.fin_quarter_no, #EmployeeDates.min_quarter_month, #EmployeeDates.max_quarter_month,
		#EmployeeDates.Division, #EmployeeDates.Department, #EmployeeDates.Team, #EmployeeDates.Name, #EmployeeDates.audit_year,
		count(#EmployeeDates.calendar_date) days_in_qtr,  #EmployeeDates.leftdate,
		#EmployeeDates.employeestartdate,
		sum(fact_employee_attendance.durationdays) days_absent
		, case  when max(#EmployeeDates.exclude) = 1 then 'Started ' + cast(format (cast(#EmployeeDates.employeestartdate as date), 'dd/MM/yyyy') as varchar(12))
				when max(#EmployeeDates.exclude) = 2 then 'Left ' +  cast(format (cast(leftdate as date), 'dd/MM/yyyy') as varchar(12))
				when sum(fact_employee_attendance.durationdays) / count(#EmployeeDates.calendar_date) > .2 
				     then (select string_agg(val, ', ') from (select distinct val from dbo.split_delimited_to_rows(string_agg(category, ','),',')) x ) 
                when max(#EmployeeDates.exclude) = 3 then 'Not an active employee' 
			    when #EmployeeDates.jobtitle = 'Investigator' then 'Investigator'
				WHEN hsd_director_data.employeeid IS NOT NULL THEN 'HSD/Director'
				WHEN trainees.employeeid IS NOT NULL THEN 'Trainee, no live matters'
				when noaudits.exclusion_reason is not null then noaudits.exclusion_reason collate database_default
		  end as reason

		, case  when max(#EmployeeDates.exclude) in (1,2,3) then 1
				when sum(fact_employee_attendance.durationdays) / count(#EmployeeDates.calendar_date) > .2 then 1 
				WHEN hsd_director_data.employeeid IS NOT NULL THEN 1
				WHEN trainees.employeeid IS NOT NULL THEN 1
				when #EmployeeDates.jobtitle = 'Investigator' then 1 
				when noaudits.exclusion_reason is not null then 1
		  end as exclude_flag

  into #exclude_data

from #EmployeeDates
left outer join (
				select fact_employee_attendance.employeeid, fact_employee_attendance.durationdays, fact_employee_attendance.category, fact_employee_attendance.startdate
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
					N'Unpaid Leave',
					N'Sickness'
					)
				
				) fact_employee_attendance on #EmployeeDates.calendar_date = fact_employee_attendance.startdate and #EmployeeDates.employeeid = fact_employee_attendance.employeeid
LEFT OUTER JOIN (
				select distinct dim_fed_hierarchy_history.employeeid
				from red_dw.dbo.dim_fed_hierarchy_history
				where 1=1
				and (dim_fed_hierarchy_history.management_role_one in ('HoSD','Director')
				or dim_fed_hierarchy_history.management_role_two in ('HoSD','Director'))
				and dim_fed_hierarchy_history.hierarchylevel2hist in ('Legal Ops - Claims', 'Legal Ops - LTA')
				)	AS hsd_director_data
		ON hsd_director_data.employeeid = #EmployeeDates.employeeid COLLATE database_default
        
LEFT OUTER JOIN (
				SELECT DISTINCT dim_employee.employeeid
				FROM red_dw.dbo.dim_fed_hierarchy_history
					left outer join ( SELECT dim_matter_header_current.fee_earner_code
									FROM red_dw.dbo.dim_matter_header_current
									WHERE dim_matter_header_current.date_closed_case_management is null
								) AS closed_cases ON dim_fed_hierarchy_history.fed_code = closed_cases.fee_earner_code
					INNER JOIN red_dw.dbo.dim_employee
						ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key
				WHERE
					closed_cases.fee_earner_code IS NULL
					AND dim_employee.classification = 'Casehandler'
					AND ISNULL(dim_employee.leftdate, '3000-01-01') >= CAST(GETDATE() AS DATE) 
					AND dim_employee.deleted_from_cascade = 0
					AND dim_employee.jobtitle IN ('Apprentice Solicitor', 'Trainee', 'Trainee Solicitor', 'Intelligence Analyst')
									   
				) AS trainees
		ON trainees.employeeid = #EmployeeDates.employeeid COLLATE database_default
        
left outer join (


		-- No Audit Audits (if an employee dosn't require an audit in a qtr but it's not recorded on Cascade they insert a dummy audit into AC and it falls into the exclusions
		select distinct dim_fed_hierarchy_history.employeeid, dim_date.calendar_date , exclusion_reason.response exclusion_reason
		from red_dw.dbo.dim_ac_audits
		inner join red_dw.dbo.dim_ac_audit_questions audit_qtr on audit_qtr.audit_id = dim_ac_audits.audit_id and audit_qtr.question_text = 'Audit Quarter'
		inner join red_dw.dbo.dim_ac_audit_questions audit_yr on audit_yr.audit_id = dim_ac_audits.audit_id and audit_yr.question_text = 'Audit Year'
		inner join red_dw.dbo.dim_ac_audit_questions exclusion_reason on exclusion_reason.audit_id = dim_ac_audits.audit_id and exclusion_reason.question_text = 'Auditee - Auditee Name - Cascade ID Number'
		inner join red_dw.dbo.dim_fed_hierarchy_history on dim_ac_audits.dim_auditee1_hierarchy_history_key =  dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
		inner join red_dw.dbo.dim_date on CAST(dim_date.fin_year -1 AS varchar(4))+'/'+CAST(right(dim_date.fin_year,2) as varchar(4)) = audit_yr.response
								and replace(lower(audit_qtr.response), 'quarter ', '') = dim_date.fin_quarter_no
		where dim_ac_audits.dim_ac_audit_type_key = 168

		
		) noaudits on noaudits.employeeid = #EmployeeDates.employeeid COLLATE database_default and #EmployeeDates.calendar_date = noaudits.calendar_date

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
	   , hsd_director_data.employeeid
	   , trainees.employeeid
	   , jobtitle
	   , #EmployeeDates.leftdate
	   , noaudits.exclusion_reason; 
	   


	   
select #Audits.*,
		-- Puts audits into qtr 1,2,3 & 4 regardless of when the audit was complete. 
		 iif(
           case
               when #Audits.fin_year = 2022 then -- Start at Qtr 2 for 2022 as we never used AC before that date 
                   row_number() over (partition by #Audits.auditee_emp_key
                                                 , #Audits.fin_year
                                      order by #Audits.Date
                                     ) + iif(dim_date.fin_year = #Audits.fin_year, dim_date.fin_quarter_no, 1) -- Starts qtr from employee start date if they started in current year
               else
                   row_number() over (partition by #Audits.auditee_emp_key
                                                 , #Audits.fin_year
                                      order by #Audits.Date
                                     ) + iif(dim_date.fin_year = #Audits.fin_year, dim_date.fin_quarter_no, 0) 
           end > 4 -- Put any audits over 4 into last qtr
         , 4
         , case
               when #Audits.fin_year = 2022 then
                   row_number() over (partition by #Audits.auditee_emp_key
                                                 , #Audits.fin_year
                                      order by #Audits.Date
                                     ) + iif(dim_date.fin_year = #Audits.fin_year, dim_date.fin_quarter_no, 1)
               else
                   row_number() over (partition by #Audits.auditee_emp_key
                                                 , #Audits.fin_year
                                      order by #Audits.Date
                                     ) + iif(dim_date.fin_year = #Audits.fin_year, dim_date.fin_quarter_no, 0)
           end) calculated_fin_qtr



 into #Audits_Calculated
from #Audits
    inner join red_dw..dim_employee on #Audits.auditee_emp_key = dim_employee.employeeid
    left outer join red_dw..dim_date on dim_date.calendar_date = dim_employee.employeestartdate






select    #exclude_data.employeeid
		, #exclude_data.Division
		, #exclude_data.Department
		, #exclude_data.Team
		, #exclude_data.Name
		,  string_agg(Audits.Auditor, '<br>') [Auditor]
		, string_agg(Audits.[Auditee Poistion],'<br>') [Auditee Poistion]
		, sum(CASE WHEN Audits.Date IS NOT NULL THEN 1 ELSE 0 END) as [Audits Completed]
		, sum(CASE WHEN Audits.Status='Pass' THEN 1 ELSE 0 end) AS [Audits Passed]
		, case when sum(CASE WHEN Audits.Date IS NOT NULL THEN 1 ELSE 0 END) > 0 then sum(CASE WHEN Audits.Status='Pass' THEN 1 ELSE 0 end) / sum(CASE WHEN Audits.Date IS NOT NULL THEN 1 ELSE 0 END) else null end [audits_passed_perc]
		, string_agg(Audits.[Client Code], '<br>') [Client Code]
		, string_agg(Audits.[Matter Number], '<br>') [Matter Number]
		, string_agg( format (cast(Audits.Date as date), 'dd/MM/yyyy') , '<br>') [Date]
		, string_agg(Audits.Status, '<br>') [Status]
	--	, Audits.Template
	--	, #exclude_data.audit_year [Audit Year]
		, #exclude_data.employeestartdate
	--	, Audits.Date audit_date
		, 'Q' + cast(#exclude_data.fin_quarter_no as varchar(1)) + ' ' + #exclude_data.min_quarter_month + '-' + #exclude_data.max_quarter_month [Audit Quarter]
		, iif(string_agg( format (cast(Audits.Date as date), 'dd/MM/yyyy') , '<br>') IS NULL and leftdate is not null and #exclude_data.exclude_flag is null, 1, #exclude_data.exclude_flag)  exclude_flag
		, iif(string_agg( format (cast(Audits.Date as date), 'dd/MM/yyyy') , '<br>') is NULL and leftdate is not null and #exclude_data.exclude_flag is null, 'Left ' + cast(format (cast(leftdate as date), 'dd/MM/yyyy') as varchar(12)), #exclude_data.reason) reason
		-- string_agg(Audits.Status, '<br>') Audits.audit_id
		
from #exclude_data
left outer join #Audits_Calculated Audits on Audits.auditee_emp_key = #exclude_data.employeeid and Audits.calculated_fin_qtr = #exclude_data.fin_quarter_no
 --where #exclude_data.employeeid = '440C1838-A18D-4592-B8AB-F196F1094221'
--where name = 'Julie Byrne'
group by 'Q' + cast(#exclude_data.fin_quarter_no as varchar(1)) + ' ' + #exclude_data.min_quarter_month + '-'
       + #exclude_data.max_quarter_month
       , #exclude_data.employeeid
       , #exclude_data.Division
       , #exclude_data.Department
       , #exclude_data.Team
       , #exclude_data.Name
     --  , Audits.Auditor
      -- , Audits.[Auditee Poistion]
       , #exclude_data.employeestartdate
       , #exclude_data.exclude_flag
       , #exclude_data.reason
	   , #exclude_data.leftdate
    --   , Audits.audit_id
order by #exclude_data.employeeid--, Audits.audit_id;









GO
