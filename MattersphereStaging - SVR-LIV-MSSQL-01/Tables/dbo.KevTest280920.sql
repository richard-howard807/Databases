CREATE TABLE [dbo].[KevTest280920]
(
[ID] [int] NOT NULL,
[FEDClient] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[FEDMatter] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[MSClientID] [bigint] NULL,
[MSFileID] [bigint] NULL,
[DocumentSource] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[VersionNumber] [int] NULL,
[DocumentTitle] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[AlternateDocDescription] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocumentNumber] [int] NOT NULL,
[DocumentExtension] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[DocumentDestination] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FileID] [bigint] NULL,
[DocWallet] [varchar] (19) COLLATE Latin1_General_CI_AS NOT NULL,
[DocFileName] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocDirection] [bit] NOT NULL,
[FEDAuthor] [char] (4) COLLATE Latin1_General_CI_AS NULL,
[CreationDate] [datetime] NULL,
[DocFrom] [int] NULL,
[DocTo] [int] NULL,
[DocCC] [int] NULL,
[DocSent] [int] NULL,
[DocReceived] [int] NULL,
[DocSubject] [int] NULL,
[MSDocAuthor] [int] NULL,
[ModifiedDate] [datetime] NULL,
[InsertDate] [datetime] NULL,
[Imported] [datetime] NULL,
[StatusID] [tinyint] NULL,
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[FEDCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocumentLocation] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[IsCurrent] [char] (1) COLLATE Latin1_General_CI_AS NULL,
[AuditIdDataStage] [int] NULL,
[AuditIdFileMove] [int] NULL,
[DirectoryId] [int] NULL,
[SuccessDate] [datetime] NULL,
[MSSecurityOption] [bigint] NULL
) ON [PRIMARY]
GO
