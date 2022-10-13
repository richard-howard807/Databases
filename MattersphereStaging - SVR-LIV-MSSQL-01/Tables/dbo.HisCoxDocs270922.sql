CREATE TABLE [dbo].[HisCoxDocs270922]
(
[FileID] [float] NULL,
[LegacyRef] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocumentNumber] [float] NULL,
[Set] [float] NULL,
[TitleLen] [float] NULL,
[PathLen] [float] NULL,
[DocumentTitle] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CreationDate] [datetime] NULL,
[ModifiedDate] [datetime] NULL,
[VersionNumber] [float] NULL,
[IsCurrent] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocumentExtension] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocumentSource] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
