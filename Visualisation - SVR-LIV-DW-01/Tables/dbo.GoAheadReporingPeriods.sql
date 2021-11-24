CREATE TABLE [dbo].[GoAheadReporingPeriods]
(
[Period Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[From] [datetime] NULL,
[To] [datetime] NULL,
[Quarter] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[GAG Year] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Exclude] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
