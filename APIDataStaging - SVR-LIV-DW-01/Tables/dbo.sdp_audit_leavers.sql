CREATE TABLE [dbo].[sdp_audit_leavers]
(
[asset] [nvarchar] (20) COLLATE Latin1_General_CI_AS NULL,
[office] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[display_name] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[email_body] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[office_manager_email] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[package_run_date] [date] NULL,
[ticket_id] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[package_output_message] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
