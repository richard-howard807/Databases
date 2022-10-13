CREATE TABLE [dbo].[KHSubsidiaryLink]
(
[Client ID] [bigint] NOT NULL,
[Client Number] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[Client Contid] [bigint] NOT NULL,
[Client Name] [nvarchar] (80) COLLATE Latin1_General_CI_AS NOT NULL,
[Subsidiary Contid] [bigint] NULL,
[Subsidiary Name] [nvarchar] (80) COLLATE Latin1_General_CI_AS NULL,
[Subsidiary Client Number] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[Subsidiary Client Name] [nvarchar] (80) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
