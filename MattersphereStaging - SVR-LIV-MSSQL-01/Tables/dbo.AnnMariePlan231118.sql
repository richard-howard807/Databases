CREATE TABLE [dbo].[AnnMariePlan231118]
(
[MSFileID] [bigint] NOT NULL,
[FEDCode] [varchar] (17) COLLATE Latin1_General_CI_AS NULL,
[client] [varchar] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[matter] [varchar] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[MSAppCode] [varchar] (11) COLLATE Latin1_General_CI_AS NOT NULL,
[MSPlanCode] [varchar] (6) COLLATE Latin1_General_CI_AS NOT NULL,
[FileID] [bigint] NOT NULL,
[Exclude] [int] NULL
) ON [PRIMARY]
GO
