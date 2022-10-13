CREATE TABLE [dbo].[HiscoxSet1]
(
[DocumentSource] [nvarchar] (2000) COLLATE Latin1_General_CI_AS NOT NULL,
[Documentdestination] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DestinationFolder] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Document] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CreationDate] [bigint] NULL,
[FileID] [bigint] NOT NULL
) ON [PRIMARY]
GO
