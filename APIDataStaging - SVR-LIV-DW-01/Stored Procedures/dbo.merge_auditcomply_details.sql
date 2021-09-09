SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[merge_auditcomply_details]
AS 
MERGE dbo.audit_details AS target
USING (
		SELECT	DISTINCT 	
            staging_auditcomply.id,
            staging_auditcomply.question_id,
            staging_auditcomply.question_text,
            staging_auditcomply.requirement_identifier,
            staging_auditcomply.nonconformances,
            staging_auditcomply.custom_responses,
            staging_auditcomply.observation,
            staging_auditcomply.recommendation,
            staging_auditcomply.responses,
            staging_auditcomply.observation_start_time,
            staging_auditcomply.observation_end_time,
            staging_auditcomply.custom_dropdown,
            staging_auditcomply.custom_option_id,
            staging_auditcomply.field_label,
            staging_auditcomply.field_value,
            staging_auditcomply.nonconformance_id,
            staging_auditcomply.noncon_status,
            staging_auditcomply.overdue,
            staging_auditcomply.non_conformance,
            staging_auditcomply.complete_by,
            staging_auditcomply.approved_date,
            staging_auditcomply.noncon_created_at,
            staging_auditcomply.assigned_to,
            staging_auditcomply.assigned_by,
            staging_auditcomply.approved_by			

FROM dbo.staging_auditcomply
) AS source

ON (target.id=source.id AND target.question_id=source.question_id)
 WHEN NOT MATCHED BY TARGET THEN 
 INSERT (id,
            question_id,
            question_text,
            requirement_identifier,
            nonconformances,
            custom_responses,
            observation,
            recommendation,
            responses,
            observation_start_time,
            observation_end_time,
            custom_dropdown,
            custom_option_id,
            field_label,
            field_value,
            nonconformance_id,
            noncon_status,
            overdue,
            non_conformance,
            complete_by,
            approved_date,
            noncon_created_at,
            assigned_to,
            assigned_by,
            approved_by			
)
 VALUES (id,
            question_id,
            question_text,
            requirement_identifier,
            nonconformances,
            custom_responses,
            observation,
            recommendation,
            responses,
            observation_start_time,
            observation_end_time,
            custom_dropdown,
            custom_option_id,
            field_label,
            field_value,
            nonconformance_id,
            noncon_status,
            overdue,
            non_conformance,
            complete_by,
            approved_date,
            noncon_created_at,
            assigned_to,
            assigned_by,
            approved_by		
			)
			WHEN MATCHED THEN UPDATE SET 
			question_text = source.question_text,
            requirement_identifier = source.requirement_identifier,
            nonconformances = source.nonconformances,
            custom_responses = source.custom_responses,
            observation = source.observation,
            recommendation = source.recommendation,
            responses = source.responses,
            observation_start_time = source.observation_start_time,
            observation_end_time = source.observation_end_time,
            custom_dropdown = source.custom_dropdown,
            custom_option_id = source.custom_option_id,
            field_label = source.field_label,
            field_value = source.field_value,
            nonconformance_id = source.nonconformance_id,
            noncon_status = source.noncon_status,
            overdue = source.overdue,
            non_conformance = source.non_conformance,
            complete_by = source.complete_by,
            approved_date = source.approved_date,
            noncon_created_at = source.noncon_created_at,
            assigned_to = source.assigned_to,
            assigned_by = source.assigned_by,
            approved_by = source.approved_by;
GO
