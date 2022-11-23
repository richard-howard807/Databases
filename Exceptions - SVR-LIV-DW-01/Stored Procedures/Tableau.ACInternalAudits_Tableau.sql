SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 2022-01-14
-- Description:	Data for Risk and Complaince to keep track of audits created on audit comply dashboard
-- =============================================

CREATE PROCEDURE [Tableau].[ACInternalAudits_Tableau]
AS
BEGIN



    IF OBJECT_ID('dbo.AuditDataTableau') IS NOT NULL
        DROP TABLE dbo.AuditDataTableau;
    IF OBJECT_ID('#Audits') IS NOT NULL
        DROP TABLE #Audits;
    SET NOCOUNT ON;



    SELECT DISTINCT
           dim_ac_audits.dim_ac_audits_key,
           auditor.employeeid,
           dim_ac_audits.auditee_1_name AS [Auditee Name],
           dim_ac_audits.dim_auditee1_hierarchy_history_key AS [Auditee key],
           audite1.employeeid Auditee_Emp_key_1,
           audite2.display_name AS [Auditee Name 2],
           dim_ac_audits.dim_auditee2_hierarchy_history_key AS [Auditee Key 2],
           audite2.employeeid Auditee_Emp_key_2,
           audite3.display_name AS [Auditee Name 3],
           dim_ac_audits.dim_auditee3_hierarchy_history_key AS [Auditee Key 3],
           audite3.employeeid Auditee_Emp_key_3,
           dim_ac_audits.client_code AS [Client Code],
           dim_ac_audits.matter_number AS [Matter Number],
           dim_ac_audits.completed_at AS [Date],
           dim_ac_audits.status AS [Status],
           dim_ac_audit_type.name AS [Template],
           auditor.name AS [Auditor],
           dim_date.fin_quarter,
           dim_date.fin_quarter_no,
           dim_date.fin_year,
           dim_ac_audits.score,
           dim_ac_audits.dim_matter_header_curr_key,
           matter_description
    INTO #Audits
    FROM red_dw.dbo.dim_ac_audits
        LEFT OUTER JOIN red_dw.dbo.dim_ac_audit_type
            ON dim_ac_audit_type.dim_ac_audit_type_key = dim_ac_audits.dim_ac_audit_type_key
        LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS [auditor]
            ON auditor.dim_fed_hierarchy_history_key = dim_ac_audits.dim_auditor_fed_hierarchy_history_key
        INNER JOIN red_dw..dim_date
            ON dim_date.dim_date_key = dim_ac_audits.dim_completed_date_key
        INNER JOIN red_dw..dim_fed_hierarchy_history audite1
            ON audite1.dim_fed_hierarchy_history_key = dim_ac_audits.dim_auditee1_hierarchy_history_key
        LEFT OUTER JOIN red_dw..dim_fed_hierarchy_history audite2
            ON audite2.dim_fed_hierarchy_history_key = dim_ac_audits.dim_auditee2_hierarchy_history_key
               AND dim_auditee2_hierarchy_history_key <> 0
        LEFT OUTER JOIN red_dw..dim_fed_hierarchy_history audite3
            ON audite3.dim_fed_hierarchy_history_key = dim_ac_audits.dim_auditee3_hierarchy_history_key
               AND dim_auditee3_hierarchy_history_key <> 0
    WHERE dim_ac_audits.created_at >= '2021-09-01'
          AND dim_ac_audits.dim_auditee1_hierarchy_history_key <> 0
          AND audite1.display_name <> 'Unknown'
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
          AND red_dw.dbo.dim_ac_audit_type.dim_ac_audit_type_key IN (   22,  --Claims Audit
                                                                        33,  --Costs Audit
                                                                        171, --Commercial Recoveries Audit 
                                                                        134, --LTA Audit 
                                                                        133, --LTA (No CDD) Audit 
                                                                        141, --New Starter Audit 
                                                                        153,  --Real Estate Audit
																		292  --LTA Short Form Audit 
                                                                    );




    SELECT DISTINCT
           #Audits.employeeid,
           #Audits.[Client Code],
           #Audits.[Matter Number],
           #Audits.[Client Code] + '-' + #Audits.[Matter Number] AS [Client/Matter Number],
           #Audits.Date,
           #Audits.Status,
           #Audits.Template,
           #Audits.Auditor,
           #Audits.fin_quarter,
           #Audits.fin_quarter_no,
           #Audits.fin_year,
           dim_ac_audit_questions.question_id,
           CAST(LEFT(dim_ac_audit_questions.section_id, CHARINDEX('.', dim_ac_audit_questions.section_id) - 1) AS INT) section_id,
           CAST(SUBSTRING(dim_ac_audit_questions.section_id, CHARINDEX('.', dim_ac_audit_questions.section_id) + 1, 2) AS INT) subsection_id,
           dim_ac_audit_questions.question_text question_text,
           dim_ac_audit_questions.observation,
           dim_ac_audit_questions.recommendation,
           IIF(dim_ac_audit_questions.response = 'Assign Task', '', dim_ac_audit_questions.response) AS response,
           dim_ac_audit_questions.audit_id,
           dim_fed_hierarchy_history.hierarchylevel2hist Division,
           dim_fed_hierarchy_history.hierarchylevel3hist Department,
           dim_fed_hierarchy_history.hierarchylevel4hist Team,
           dim_fed_hierarchy_history.display_name,
           #Audits.[Auditee key],
           #Audits.Auditee_Emp_key_1,
           (
               SELECT STRING_AGG(CAST(observation AS VARCHAR(MAX)), ',')
               FROM red_dw..dim_ac_audit_questions x
               WHERE x.audit_id = dim_ac_audit_questions.audit_id
                     AND LEN(x.observation) > 1
           ) audit_observations,
           (
               SELECT STRING_AGG(CAST(recommendation AS VARCHAR(MAX)), ',')
               FROM red_dw..dim_ac_audit_questions x
               WHERE x.audit_id = dim_ac_audit_questions.audit_id
                     AND LEN(x.recommendation) > 1
           ) audit_recommendations,
           score,
           [#Audits].[Auditee Name 2],
           [#Audits].[Auditee Name 3],
           dim_ac_audit_details.positive_feedback_details,
           dim_ac_audit_details.complaint_details,
           matter_description,
           jobtitle AS [Fee Earner Job Title],
           name AS [Fee Earner]
    --, CASE WHEN levelidud	 LIKE '%Partner%' THEN 'Partner'
    --			 WHEN levelidud = 'Legal Director' THEN 'Legal Director'
    --			 ELSE levelidud END AS JobLevelTitle
    INTO dbo.AuditDataTableau
    FROM #Audits
        INNER JOIN red_dw..dim_ac_audit_questions
            ON dim_ac_audit_questions.dim_ac_audits_key = #Audits.dim_ac_audits_key
        INNER JOIN red_dw..dim_fed_hierarchy_history
            ON #Audits.[Auditee key] = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
        LEFT OUTER JOIN red_dw..dim_ac_audit_details
            ON dim_ac_audit_details.dim_ac_audits_key = #Audits.dim_ac_audits_key
    WHERE LOWER(dim_ac_audit_questions.question_text)NOT LIKE '%do you wish to include any feedback%'
          AND dim_ac_audit_questions.question_text NOT IN ( 'Positive feedback details', 'Complaint details' )
          AND dim_fed_hierarchy_history.hierarchylevel2hist IN ( 'Legal Ops - Claims', 'Legal Ops - LTA' );

-----------------------------------------------------------------------------------------


END;

GO
