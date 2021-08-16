CREATE TABLE [dbo].[NHSRAudit1819]
(
[File Reference] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MS Ref] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Worktype] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Audit Date] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Overall Audit Score] [money] NULL,
[First report sent promptly? (SLA)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Have we updated client regularly (SLA)?] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
