CREATE TABLE [dbo].[staging_exceptions]
(
[ms_fileid] [bigint] NULL,
[exceptionruleid] [int] NULL,
[fieldname] [varchar] (200) COLLATE Latin1_General_CI_AS NULL,
[narrative] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[update_time] [datetime] NULL
) ON [PRIMARY]
GO
