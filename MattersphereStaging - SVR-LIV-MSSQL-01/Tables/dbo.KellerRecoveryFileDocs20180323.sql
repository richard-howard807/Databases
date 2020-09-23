CREATE TABLE [dbo].[KellerRecoveryFileDocs20180323]
(
[MSFileID] [float] NULL,
[MSWallet] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MSassocID] [float] NULL,
[PrimaryFolder] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SecondaryFolder] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[TertiaryFolder] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[QuaterneraryFolder] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DocumentSource] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Document Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Document Extenstion] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Creation Date] [datetime] NULL
) ON [PRIMARY]
GO
