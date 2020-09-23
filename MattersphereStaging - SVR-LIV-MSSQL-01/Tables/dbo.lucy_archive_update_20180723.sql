CREATE TABLE [dbo].[lucy_archive_update_20180723]
(
[fileID] [bigint] NULL,
[clID] [bigint] NULL,
[Client] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter] [float] NULL,
[FEDCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[dwID] [bigint] NOT NULL,
[current_status] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[new_status] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
