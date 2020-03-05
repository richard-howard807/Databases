CREATE TABLE [dbo].[udMapDetail090418]
(
[rowguid] [uniqueidentifier] NOT NULL,
[ID] [int] NOT NULL,
[txtDetCode] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[txtDesc] [nvarchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[txtDataType] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[txtLookupCode] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[txtLookupTable] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[txtMSCode] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[txtMSTable] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[txtParentCode] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[bitSearchList] [bit] NOT NULL,
[intSearchListSeq] [int] NULL,
[dteCreated] [smalldatetime] NOT NULL,
[dteLastModified] [smalldatetime] NULL,
[bitActive] [bit] NOT NULL,
[txtOldTable] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
