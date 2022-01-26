SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[load_auditcomply] 
(@FileName NVARCHAR(MAX)) AS 

DECLARE @sql nvarchar(MAX)

--DECLARE @FileName NVARCHAR(250)
--SET @FileName='C:\APIDataStaging\AuditComply\Files\Audits 1.json'
SET @sql =
N'
DECLARE @JSON nvarchar(MAX)

SELECT @JSON = BulkColumn
FROM OPENROWSET 
(BULK '''+@FileName+N''', SINGLE_NCLOB) 
AS j

INSERT INTO dbo.staging_auditcomply

select data.name,
      data.id,
      data.status,
      data.additional_signature_print,
      data.additional_signature_position,
      data.signature,
      data.asset_id,
      data.asset_name,
      data.updated_at,
      data.close_audit_enabled,
      data.latitude,
      data.signature_position,
      data.report,
      data.closed_at,
      data.closed_notes,
      data.closed_by_signature,
      data.status_color,
      data.completed_at,
      data.closed_by_id,
      data.created_at,
      data.state,
      data.longitude,
      data.signature_print,
      data.additional_signature,
      data.compliant,
      data.status_changed_on_close,
      data.device,
      data.published,
      data.auditor_id,
      data.notes,
      data.observations,
      NULL as customresponses,
      data.nonconformance,

	  case when cust.custom_option_id IS NOT null and custfields.value is not null then cast (cast (cust.custom_option_id as varchar(20)) + cast(row_number() over (partition by data.id, cust.custom_option_id order by cust.field_label ) as varchar(2)) as bigint  )
		   when cust.custom_option_id IS NOT null then cust.custom_option_id 
		   else obs.question_id end as question_id,

	  case when cust.field_label IS NOT NULL and custfields.label is not null then obs.question_text +'' - ''+ cust.field_label +'' - ''+ custfields.label
		   when cust.field_label IS NOT NULL then obs.question_text +'' - ''+ cust.field_label 
		   else obs.question_text end as question_text,	  

   
      obs.requirement_identifier,
      obs.nonconformances,
      obs.custom_responses,
      obs.observation,
      obs.recommendation,
      obs.responses,
      obs.observation_start_time,
      obs.observation_end_time,
      obs.custom_dropdown,
      cust.custom_option_id,
      iif(cust.field_value is null, custfields.label, cust.field_label) field_label,
      iif(cust.field_value is null, custfields.value, cust.field_value) field_value,
      noncon.nonconformance_id,
      noncon.status AS noncon_status,
      noncon.overdue,
      noncon.non_conformance,
      noncon.complete_by,
      noncon.approved_date,
      noncon.created_at AS noncon_created_at,
      noncon.assigned_to,
      noncon.assigned_by,
      noncon.approved_by,
	  data.audit_result


	from OPENJSON (@JSON) 
WITH (	  name nvarchar(MAX)
		, id INT
		, status nvarchar(MAX) 
		, additional_signature_print nvarchar(MAX)
		, additional_signature_position nvarchar(MAX) 
		, signature nvarchar(MAX) 
		, asset_id INT
		, asset_name  nvarchar(MAX) 
		, updated_at nvarchar(MAX)
		, close_audit_enabled bit
		, latitude nvarchar(MAX)
		, signature_position nvarchar(MAX)
        , report nvarchar(MAX)
		, closed_at nvarchar(MAX)
		, closed_notes nvarchar(MAX)
		, closed_by_signature nvarchar(MAX)
		, status_color nvarchar(MAX)
		, completed_at nvarchar(MAX)
		, closed_by_id int
		, created_at nvarchar(MAX)
		, state nvarchar(MAX)
		, longitude nvarchar(MAX)
		, signature_print nvarchar(MAX)
		, additional_signature bit
		, compliant bit
		, status_changed_on_close bit
		, device nvarchar(MAX)
		, published nvarchar(MAX)
		, auditor_id int
		, notes nvarchar(MAX)
		, observations NVARCHAR(max) as json
		--, customresponses  nvarchar(max) as JSON
        , nonconformance  nvarchar(max) as json
		, audit_result nvarchar(20)
		) data

outer apply openjson( observations, ''$'' ) 
	with ( question_id bigint
			, question_text nvarchar(MAX)
			, requirement_identifier nvarchar(MAX)
			, nonconformances nvarchar(MAX)
			, custom_responses nvarchar(MAX)  ''$.custom_responses'' AS json
			, observation nvarchar(MAX) 
			, recommendation nvarchar(MAX)
			, responses nvarchar(MAX) ''$.responses[0]''
			, observation_start_time nvarchar(MAX)
			, observation_end_time nvarchar(MAX)
			, custom_dropdown nvarchar(MAX)
			) obs

outer apply openjson( custom_responses, ''$'' ) 
	with (  custom_option_id INT
			, field_label  nvarchar(MAX)
			, field_value  nvarchar(MAX)
			, cust_response_field_value nvarchar(MAX)  ''$.field_value'' AS json 
			) cust

outer apply openjson( cust_response_field_value, ''$'' ) 
	with ( 	  label  nvarchar(MAX)
			, value  nvarchar(MAX)
			) custfields

outer apply openjson( nonconformance, ''$'' ) 
	with (  nonconformance_id INT
			, status  nvarchar(MAX) 
			, overdue bit
			, non_conformance  nvarchar(MAX)
			, complete_by nvarchar(MAX)
			, approved_date nvarchar(MAX)
			, created_at nvarchar(MAX)
			, assigned_to INT
			, assigned_by int
			, approved_by int
			) noncon

'
--select @sql

EXECUTE sys.sp_executesql @sql
GO
