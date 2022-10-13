CREATE TABLE [dbo].[ReportExecsES]
(
[SERVER] [varchar] (20) COLLATE Latin1_General_CI_AS NULL,
[Path] [nvarchar] (425) COLLATE Latin1_General_CI_AS_KS_WS NOT NULL,
[ReportID] [int] NULL,
[Name] [nvarchar] (425) COLLATE Latin1_General_CI_AS_KS_WS NOT NULL,
[Description] [nvarchar] (512) COLLATE Latin1_General_CI_AS_KS_WS NULL,
[DateTime] [datetime] NULL,
[Type] [int] NOT NULL
) ON [PRIMARY]
GO
