CREATE TABLE [dbo].[audit_details]
(
[id] [int] NULL,
[question_id] [int] NULL,
[question_text] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[requirement_identifier] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[nonconformances] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[custom_responses] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[observation] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[recommendation] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[responses] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[observation_start_time] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[observation_end_time] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[custom_dropdown] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[custom_option_id] [int] NULL,
[field_label] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[field_value] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[nonconformance_id] [int] NULL,
[noncon_status] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[overdue] [bit] NULL,
[non_conformance] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[complete_by] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[approved_date] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[noncon_created_at] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[assigned_to] [int] NULL,
[assigned_by] [int] NULL,
[approved_by] [int] NULL
) ON [PRIMARY]
GO
