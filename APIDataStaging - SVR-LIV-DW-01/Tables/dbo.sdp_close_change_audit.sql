CREATE TABLE [dbo].[sdp_close_change_audit]
(
[change_id] [int] NULL,
[date_package_run] [date] NULL,
[script_output_worklog_ref] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[script_output_closure_code] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[script_output_update_change_close] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[script_output_update_change_rejected] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
