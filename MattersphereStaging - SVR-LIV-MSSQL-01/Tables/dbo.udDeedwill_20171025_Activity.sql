CREATE TABLE [dbo].[udDeedwill_20171025_Activity]
(
[dwID] [bigint] NOT NULL,
[File Reference] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fileID] [bigint] NULL,
[current_udDeedwill_status] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[new_status] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[live_file_status] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[change_description] [varchar] (200) COLLATE Latin1_General_CI_AS NULL,
[step] [int] NOT NULL
) ON [PRIMARY]
GO
