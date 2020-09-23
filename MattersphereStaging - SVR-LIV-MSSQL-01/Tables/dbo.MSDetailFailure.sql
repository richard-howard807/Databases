CREATE TABLE [dbo].[MSDetailFailure]
(
[ID] [int] NOT NULL,
[fileID] [bigint] NOT NULL,
[clNo] [nvarchar] (12) COLLATE Latin1_General_CI_AS NOT NULL,
[fileNo] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[MSCaseDate] [datetime] NULL,
[MSCaseValue] [decimal] (13, 2) NULL,
[DetailDesc] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DataType] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Lookupcode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[LookupTable] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MScode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MSTable] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[InsertDate] [datetime] NOT NULL,
[Imported] [datetime] NULL,
[StatusID] [tinyint] NOT NULL,
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[MSCaseText] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
