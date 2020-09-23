CREATE TABLE [dbo].[date_closure_report_sent_for_updte]
(
[fileid] [float] NULL,
[ClNo] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fileNo] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Table] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Column] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date] [datetime] NULL,
[Value] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Text] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
