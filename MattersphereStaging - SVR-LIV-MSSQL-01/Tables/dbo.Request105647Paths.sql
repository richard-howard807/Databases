CREATE TABLE [dbo].[Request105647Paths]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[FileID] [bigint] NOT NULL,
[DocumentSource] [nvarchar] (2000) COLLATE Latin1_General_CI_AS NOT NULL,
[DocumentTitle] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[AlternateDocDescription] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocumentExtension] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[DocumentDestination] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocWallet] [varchar] (19) COLLATE Latin1_General_CI_AS NOT NULL,
[CreationDate] [datetime] NULL,
[ModifiedDate] [datetime] NULL,
[InsertDate] [datetime] NULL,
[DocumentLocation] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocFileName] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocID] [bigint] NULL,
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[ShowOnExtranet] [nvarchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Processed] [int] NULL,
[MSassocID] [bigint] NULL
) ON [PRIMARY]
GO
