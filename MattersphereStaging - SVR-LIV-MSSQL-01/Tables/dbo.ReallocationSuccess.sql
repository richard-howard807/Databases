CREATE TABLE [dbo].[ReallocationSuccess]
(
[ID] [int] NOT NULL,
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
[InsertDate] [datetime] NOT NULL,
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
