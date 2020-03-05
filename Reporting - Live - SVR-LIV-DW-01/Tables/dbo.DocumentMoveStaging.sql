CREATE TABLE [dbo].[DocumentMoveStaging]
(
[Id] [int] NOT NULL,
[OldPath] [varchar] (500) COLLATE Latin1_General_CI_AS NULL,
[NewPath] [varchar] (500) COLLATE Latin1_General_CI_AS NULL,
[Directory] [varchar] (500) COLLATE Latin1_General_CI_AS NULL,
[Processed] [int] NULL
) ON [PRIMARY]
GO
