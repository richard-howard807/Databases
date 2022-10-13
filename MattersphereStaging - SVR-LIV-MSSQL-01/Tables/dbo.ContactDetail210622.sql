CREATE TABLE [dbo].[ContactDetail210622]
(
[ID] [bigint] NOT NULL,
[Client] [nvarchar] (8) COLLATE Latin1_General_CI_AS NULL,
[Matter] [nvarchar] (8) COLLATE Latin1_General_CI_AS NULL,
[ClNo] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[fileNo] [nvarchar] (20) COLLATE Latin1_General_CI_AS NULL,
[MSCode] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[MSTable] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[CaseDate] [datetime] NULL,
[CaseValue] [money] NULL,
[CaseText] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MSFileID] [bigint] NULL
) ON [PRIMARY]
GO
