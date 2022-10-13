CREATE TABLE [dbo].[KHTbl_Deed]
(
[ID] [int] NOT NULL,
[ClientMatter] [nvarchar] (16) COLLATE Latin1_General_CI_AS NULL,
[ClientNo] [int] NULL,
[ClientNot] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[ClientName] [nvarchar] (120) COLLATE Latin1_General_CI_AS NOT NULL,
[MatterNo] [int] NULL,
[MatterNot] [nvarchar] (8) COLLATE Latin1_General_CI_AS NULL,
[MatterDesc] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[MatterDescription] [nvarchar] (180) COLLATE Latin1_General_CI_AS NULL,
[Details] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[From] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Date] [datetime] NULL,
[Location] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Reference] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[CrossRef] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Remarks_Memo] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Remarks] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[PrintLabel] [bit] NOT NULL,
[Old_ClientName] [nvarchar] (120) COLLATE Latin1_General_CI_AS NULL,
[TimeStamp] [datetime] NULL
) ON [PRIMARY]
GO
