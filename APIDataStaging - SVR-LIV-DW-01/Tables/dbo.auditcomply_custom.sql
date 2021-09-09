CREATE TABLE [dbo].[auditcomply_custom]
(
[id] [int] NULL,
[created_at] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[name] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[status] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[schedule_id] [int] NULL,
[updated_at] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[compliant] [bit] NULL,
[status_color] [varchar] (30) COLLATE Latin1_General_CI_AS NULL,
[state] [varchar] (250) COLLATE Latin1_General_CI_AS NULL,
[completed_at] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[closed_at] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[auditor_email] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[closed_by_email] [nvarchar] (250) COLLATE Latin1_General_CI_AS NULL,
[report] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[nc_breakdown] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[score] [int] NULL
) ON [PRIMARY]
GO
