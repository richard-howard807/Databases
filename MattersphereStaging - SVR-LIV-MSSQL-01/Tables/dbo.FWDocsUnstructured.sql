CREATE TABLE [dbo].[FWDocsUnstructured]
(
[SourceSystemID] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Date Added] [datetime] NULL,
[Additional Description] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Client] [bigint] NULL,
[Matter] [bigint] NULL
) ON [PRIMARY]
GO
