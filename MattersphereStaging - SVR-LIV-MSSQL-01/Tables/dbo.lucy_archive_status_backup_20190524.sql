CREATE TABLE [dbo].[lucy_archive_status_backup_20190524]
(
[dwRef] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[dwID] [bigint] NOT NULL,
[fileID] [bigint] NULL,
[dwDestroyDue] [datetime] NULL,
[dwDestroyDate] [datetime] NULL,
[Status] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
