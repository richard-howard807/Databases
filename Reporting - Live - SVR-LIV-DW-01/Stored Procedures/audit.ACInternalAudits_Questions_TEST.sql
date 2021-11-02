SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Richard Howard
-- Create date: 2021-10-26
-- Description:	Data for Risk and Complaince to keep track of audits created on audit comply
-- =============================================

CREATE PROCEDURE [audit].[ACInternalAudits_Questions_TEST]

( @Template AS NVARCHAR(MAX)
,@StartDate AS DATE 
,@EndDate AS DATE 
,@Department AS NVARCHAR(50)
,@Team AS NVARCHAR(50)

)
as

--DECLARE @Template AS NVARCHAR(MAX) ='Claims Audit'
--, @AuditYear AS NVARCHAR(50) ='2021/2022'
--,@StartDate AS DATE = GETDATE() -300
--,@EndDate AS DATE = GETDATE()
--,@Department AS NVARCHAR(50) = 'All'
--,@Team AS NVARCHAR(50) = 'All'




DROP TABLE IF EXISTS #Template
drop table if exists #Audits


SELECT ListValue  INTO #Template  FROM Reporting.dbo.[udt_TallySplit]('|', @Template)


	
		SELECT dim_ac_audits_key, pvt3.employeeid
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
			, pvt3.score
		into #Audits
		FROM (SELECT dim_ac_audits.dim_ac_audits_key,
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
				, dim_ac_audits.score

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
		


select distinct #Audits.employeeid
     , #Audits.auditee_emp_key
     , #Audits.[Auditee Poistion]
     , #Audits.[Client Code]
     , #Audits.[Matter Number]
     , #Audits.Date
     , #Audits.Status
     , #Audits.Template
     , #Audits.Auditor
     , #Audits.fin_quarter
     , #Audits.fin_quarter_no
     , #Audits.fin_year
     , dim_ac_audit_questions.question_id
     , dim_ac_audit_questions.section_id
     ,dim_ac_audit_questions.question_text question_text
     , dim_ac_audit_questions.observation
     , dim_ac_audit_questions.recommendation
     , iif(dim_ac_audit_questions.response = 'Assign Task', '', dim_ac_audit_questions.response) response
	 , dim_ac_audit_questions.audit_id
	 , dim_fed_hierarchy_history.hierarchylevel2hist Division
	 , dim_fed_hierarchy_history.hierarchylevel3hist Department
	 , dim_fed_hierarchy_history.hierarchylevel4hist Team
	 , dim_fed_hierarchy_history.display_name
	 , (select string_agg(cast(observation as varchar(max)), ',')  from red_dw..dim_ac_audit_questions x where x.audit_id=dim_ac_audit_questions.audit_id and len(x.observation) > 1 ) audit_observations
	 ,  (select string_agg(cast(recommendation as varchar(max)), ',') from red_dw..dim_ac_audit_questions x where x.audit_id=dim_ac_audit_questions.audit_id  and len(x.recommendation) > 1) audit_recommendations
	 , score
from #Audits
inner join red_dw..dim_ac_audit_questions on dim_ac_audit_questions.dim_ac_audits_key = #Audits.dim_ac_audits_key
inner join red_dw..dim_fed_hierarchy_history on #Audits.[Auditee key] = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
left outer join red_dw..dim_ac_audit_details on dim_ac_audit_details.dim_ac_audits_key = #Audits.dim_ac_audits_key
--where audit_id = 715658
WHERE #Audits.Date BETWEEN isnull(@StartDate,GETDATE()-365) AND ISNULL(@EndDate, GETDATE()+1)

AND iif(@Department = 'All', 'All', trim(dim_fed_hierarchy_history.hierarchylevel3hist)) in (@Department)
AND iif(@Team = 'All', 'All', trim(dim_fed_hierarchy_history.hierarchylevel4hist)) in (@Team)


GO
