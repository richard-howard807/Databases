CREATE TABLE [dbo].[DCPAPI100522]
(
[ms_fileid] [bigint] NULL,
[Client] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter] [char] (8) COLLATE Latin1_General_BIN NULL,
[ClNo] [nvarchar] (12) COLLATE Latin1_General_BIN NULL,
[FileNo] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[MSTable] [varchar] (9) COLLATE Latin1_General_CI_AS NOT NULL,
[MSCode] [varchar] (12) COLLATE Latin1_General_CI_AS NOT NULL,
[CaseText] [varchar] (2) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
