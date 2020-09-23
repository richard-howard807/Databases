CREATE TABLE [dbo].[Archiveupdate120220]
(
[client number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[matter number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fileID] [float] NULL,
[Matter Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Status Code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Status Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Destruction date] [datetime] NULL,
[dwRef] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[dwID] [float] NULL
) ON [PRIMARY]
GO
