CREATE TABLE [dbo].[NHSPARMatter160522]
(
[FileID] [float] NULL,
[LegacyRef] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocumentNumber] [float] NULL,
[DocumentTitle] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CreationDate] [datetime] NULL,
[ModifiedDate] [datetime] NULL,
[VersionNumber] [float] NULL,
[IsCurrent] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocumentExtension] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocumentSource] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[LEN] [float] NULL,
[TitleLEN] [float] NULL
) ON [PRIMARY]
GO
