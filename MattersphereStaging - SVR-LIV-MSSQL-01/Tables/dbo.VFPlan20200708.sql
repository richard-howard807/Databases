CREATE TABLE [dbo].[VFPlan20200708]
(
[Matter No] [nvarchar] (33) COLLATE Latin1_General_CI_AS NULL,
[MSFileID] [bigint] NOT NULL,
[WorkType] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[MSAppCode] [varchar] (11) COLLATE Latin1_General_CI_AS NOT NULL,
[MSPlanCode] [varchar] (11) COLLATE Latin1_General_CI_AS NOT NULL,
[Exclude] [int] NULL,
[fileStatus] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
