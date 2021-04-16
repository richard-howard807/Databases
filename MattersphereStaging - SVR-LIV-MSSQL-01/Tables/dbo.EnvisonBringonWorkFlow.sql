CREATE TABLE [dbo].[EnvisonBringonWorkFlow]
(
[Matter No] [nvarchar] (33) COLLATE Latin1_General_CI_AS NULL,
[MSFileID] [bigint] NOT NULL,
[WorkType] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[MSAppCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MSPlanCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Exclude] [int] NULL,
[fileStatus] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
