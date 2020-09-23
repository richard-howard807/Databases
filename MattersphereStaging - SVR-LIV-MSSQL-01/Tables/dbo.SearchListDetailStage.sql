CREATE TABLE [dbo].[SearchListDetailStage]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[fileID] [bigint] NOT NULL,
[FEDCode] [nvarchar] (17) COLLATE Latin1_General_CI_AS NOT NULL,
[FEDClient] [char] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[FEDMatter] [char] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[FEDCaseID] [int] NOT NULL,
[clNo] [nvarchar] (12) COLLATE Latin1_General_CI_AS NOT NULL,
[fileNo] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[FEDDetailCode] [char] (10) COLLATE Latin1_General_CI_AS NOT NULL,
[FEDCaseText] [char] (60) COLLATE Latin1_General_CI_AS NULL,
[FEDCaseDate] [datetime] NULL,
[FEDCaseValue] [decimal] (13, 2) NULL,
[seq_no] [int] NOT NULL,
[cd_parent] [int] NULL,
[DetailDesc] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DataType] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Lookupcode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[LookupTable] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MScode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MSTable] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[InsertDate] [datetime] NOT NULL CONSTRAINT [DF__SearchList__Inser__2FCF1A8A] DEFAULT (getdate()),
[Imported] [datetime] NULL,
[StatusID] [tinyint] NOT NULL CONSTRAINT [DF__SearchList__Statu__30C33EC3] DEFAULT ((0)),
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
