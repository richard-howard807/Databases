SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Richard Howard
-- Create date: 2021-10-26
-- Description:	Data for Risk and Complaince to keep track of audits created on audit comply
-- =============================================
-- ad-hoc from Hillary 01/12/2021 - added Client paramater
-- ad-hoc from Hillary 07/12/2021 - Changed department, team and client params to enable multiple selection

CREATE PROCEDURE [audit].[ACInternalAudits_Questions]

( @Template AS NVARCHAR(MAX)
,@StartDate AS DATE 
,@EndDate AS DATE 
,@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
,@Client AS NVARCHAR(MAX)
,@Fee_Earner AS NVARCHAR(MAX)
)
as

--DECLARE @Template AS NVARCHAR(MAX) ='Claims Audit'
--, @AuditYear AS NVARCHAR(50) ='2021/2022'
--,@StartDate AS DATE = GETDATE() -300
--,@EndDate AS DATE = GETDATE()
--,@Department AS NVARCHAR(MAX) = 'Casualty|Healthcare'
--,@Team AS NVARCHAR(MAX) = 'Casualty Liverpool|Healthcare North West 1'
--, @Client AS NVARCHAR(MAX) = 'Z1001|A1001|A3003'
--, @Fee_Earner AS NVARCHAR(MAX) = '67FBDB1C-4457-44C9-89FC-D321B699C2C9|CDA09A5D-504A-4B88-B36A-6D3B50287692|4D4D7697-6D70-405C-8619-0CB22D55094F'



DROP TABLE IF EXISTS #Template
DROP TABLE IF EXISTS #Department
DROP TABLE IF EXISTS #Team
DROP TABLE IF EXISTS #Client
DROP TABLE IF EXISTS #Fee_Earner
DROP table if exists #Audits



SELECT ListValue  INTO #Template  FROM Reporting.dbo.[udt_TallySplit]('|', @Template)
SELECT ListValue  INTO #Department  FROM Reporting.dbo.[udt_TallySplit]('|', @Department)
SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)
SELECT ListValue INTO #Client FROM Reporting.dbo.udt_TallySplit('|', @Client)
SELECT ListValue INTO #Fee_Earner FROM Reporting.dbo.udt_TallySplit('|', @Fee_Earner)

	
	SELECT distinct dim_ac_audits.dim_ac_audits_key,
				auditor.employeeid
				, dim_ac_audits.auditee_1_name AS [Auditee Name]
				, dim_ac_audits.dim_auditee1_hierarchy_history_key AS [Auditee key]
				, audite1.employeeid Auditee_Emp_key_1
				, audite2.display_name AS [Auditee Name 2]
				, dim_ac_audits.dim_auditee2_hierarchy_history_key AS [Auditee Key 2]
				, audite2.employeeid Auditee_Emp_key_2
				, audite3.display_name AS [Auditee Name 3]
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
				, dim_ac_audits.dim_matter_header_curr_key
				, matter_description 

				--	SELECT * from red_dw..dim_date
					into #Audits
				from red_dw.dbo.dim_ac_audits
				LEFT OUTER JOIN red_dw.dbo.dim_ac_audit_type
				ON dim_ac_audit_type.dim_ac_audit_type_key = dim_ac_audits.dim_ac_audit_type_key
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS [auditor]
				ON auditor.dim_fed_hierarchy_history_key=dim_ac_audits.dim_auditor_fed_hierarchy_history_key

				INNER JOIN #Template AS Template ON Template.ListValue COLLATE DATABASE_DEFAULT =  dim_ac_audit_type.name COLLATE DATABASE_DEFAULT
				inner join red_dw..dim_date on dim_date.dim_date_key = dim_ac_audits.dim_completed_date_key

				inner join red_dw..dim_fed_hierarchy_history audite1 on audite1.dim_fed_hierarchy_history_key = dim_ac_audits.dim_auditee1_hierarchy_history_key
				left outer join red_dw..dim_fed_hierarchy_history audite2 on audite2.dim_fed_hierarchy_history_key = dim_ac_audits.dim_auditee2_hierarchy_history_key and dim_auditee2_hierarchy_history_key <> 0			
				left outer join red_dw..dim_fed_hierarchy_history audite3 on audite3.dim_fed_hierarchy_history_key = dim_ac_audits.dim_auditee3_hierarchy_history_key and dim_auditee3_hierarchy_history_key <> 0	

				WHERE dim_ac_audits.created_at >='2021-09-01'
				and dim_ac_audits.dim_auditee1_hierarchy_history_key <> 0 
				and audite1.display_name <> 'Unknown'
				AND ISNULL(dim_ac_audits.status, '') <> 'Deleted'
				AND (CASE	
						WHEN LOWER(dim_ac_audits.client_code) LIKE '%test%' THEN
							1
						WHEN LOWER(dim_ac_audits.matter_number) LIKE '%test%' THEN
							1
						WHEN LOWER(dim_ac_audits.area) LIKE '%test%' THEN
							1
						WHEN LOWER(dim_ac_audits.matter_description) LIKE '%test%' THEN
							1
						ELSE
							0
					  END 
					) = 0

		


select distinct #Audits.employeeid
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
	 , cast(left(dim_ac_audit_questions.section_id, charindex('.', dim_ac_audit_questions.section_id) - 1) as int) section_id
	 , cast (substring(dim_ac_audit_questions.section_id, charindex('.', dim_ac_audit_questions.section_id) + 1, 2) as int) subsection_id

     ,dim_ac_audit_questions.question_text question_text
     , dim_ac_audit_questions.observation
     , dim_ac_audit_questions.recommendation
     , iif(dim_ac_audit_questions.response = 'Assign Task', '', dim_ac_audit_questions.response) response
	 , dim_ac_audit_questions.audit_id
	 , dim_fed_hierarchy_history.hierarchylevel2hist Division
	 , dim_fed_hierarchy_history.hierarchylevel3hist Department
	 , dim_fed_hierarchy_history.hierarchylevel4hist Team
	 , dim_fed_hierarchy_history.display_name
	 , #Audits.[Auditee key]
	 , #Audits.Auditee_Emp_key_1
	 , (select string_agg(cast(observation as varchar(max)), ',')  from red_dw..dim_ac_audit_questions x where x.audit_id=dim_ac_audit_questions.audit_id and len(x.observation) > 1 ) audit_observations
	 ,  (select string_agg(cast(recommendation as varchar(max)), ',') from red_dw..dim_ac_audit_questions x where x.audit_id=dim_ac_audit_questions.audit_id  and len(x.recommendation) > 1) audit_recommendations
	 , score
	 , [#Audits].[Auditee Name 2]
	 , [#Audits].[Auditee Name 3]
	 , dim_ac_audit_details.positive_feedback_details
	 , dim_ac_audit_details.complaint_details
	 , matter_description
from #Audits
inner join red_dw..dim_ac_audit_questions on dim_ac_audit_questions.dim_ac_audits_key = #Audits.dim_ac_audits_key
inner join red_dw..dim_fed_hierarchy_history 
	ON #Audits.[Auditee key] = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
INNER JOIN #Department
	ON dim_fed_hierarchy_history.hierarchylevel3hist = #Department.ListValue COLLATE DATABASE_DEFAULT
INNER JOIN #Team
	ON dim_fed_hierarchy_history.hierarchylevel4hist = #Team.ListValue COLLATE DATABASE_DEFAULT
INNER JOIN #Client
	ON UPPER(TRIM(#Audits.[Client Code])) = #Client.ListValue COLLATE DATABASE_DEFAULT
INNER JOIN #Fee_Earner
	ON #Fee_Earner.ListValue = #Audits.Auditee_Emp_key_1 COLLATE DATABASE_DEFAULT
left outer join red_dw..dim_ac_audit_details on dim_ac_audit_details.dim_ac_audits_key = #Audits.dim_ac_audits_key
--where audit_id = 715658
WHERE #Audits.Date BETWEEN isnull(@StartDate,GETDATE()-365) AND ISNULL(@EndDate, GETDATE()+1)
and lower(dim_ac_audit_questions.question_text) not like '%do you wish to include any feedback%'
and dim_ac_audit_questions.question_text not in ('Positive feedback details','Complaint details')
--AND iif(@Department = 'All', 'All', trim(dim_fed_hierarchy_history.hierarchylevel3hist)) in (@Department)
--AND iif(@Team = 'All', 'All', trim(dim_fed_hierarchy_history.hierarchylevel4hist)) in (@Team)

GO
