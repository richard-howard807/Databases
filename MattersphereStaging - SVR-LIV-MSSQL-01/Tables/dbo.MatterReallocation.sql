CREATE TABLE [dbo].[MatterReallocation]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[clNo] [nvarchar] (12) COLLATE Latin1_General_CI_AS NOT NULL,
[fileNo] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[FedClient] [nvarchar] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[FEDMatter] [nvarchar] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[PreviousFE] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[filePrincipleID] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[NewAssistant] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[fileResponsibleID] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[Partner] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[StatusID] [tinyint] NOT NULL,
[InsertDate] [datetime] NOT NULL CONSTRAINT [DF__MatterRea__Inser__6383C8BA] DEFAULT (getdate()),
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MatterReallocation] ADD CONSTRAINT [PK_MatterReallocation] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
