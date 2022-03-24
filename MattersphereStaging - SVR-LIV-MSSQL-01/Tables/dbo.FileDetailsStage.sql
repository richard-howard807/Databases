CREATE TABLE [dbo].[FileDetailsStage]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[clNo] [nvarchar] (12) COLLATE Latin1_General_CI_AS NOT NULL,
[fileNo] [nvarchar] (20) COLLATE Latin1_General_CI_AS NULL,
[extFileID] [bigint] NULL,
[fileDesc] [nvarchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[fileResponsibleID] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[filePrincipleID] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[fileDept] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[fileType] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[fileFundCode] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL CONSTRAINT [DF__FileDetai__fileF__1920BF5C] DEFAULT ('NOCHG'),
[fileCurISOCode] [nchar] (3) COLLATE Latin1_General_CI_AS NOT NULL CONSTRAINT [DF__FileDetai__fileC__1A14E395] DEFAULT ('GBP'),
[fileStatus] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[fileCreated] [datetime] NULL CONSTRAINT [DF__FileDetai__fileC__1B0907CE] DEFAULT (getdate()),
[fileUpdated] [datetime] NULL,
[fileClosed] [datetime] NULL,
[fileSource] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL CONSTRAINT [DF__FileDetai__fileS__1BFD2C07] DEFAULT ('IMPORT'),
[fileSection] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[fileSectionGroup] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[MattIndex] [int] NULL,
[Office] [int] NULL,
[brID] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[Partner] [bigint] NOT NULL,
[InsertDate] [datetime] NOT NULL CONSTRAINT [DF__FileDetai__Inser__1CF15040] DEFAULT (getdate()),
[Imported] [datetime] NULL,
[StatusID] [tinyint] NOT NULL CONSTRAINT [DF__FileDetai__Statu__1DE57479] DEFAULT ((0)),
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[NewMatterNumber] [int] NULL,
[BusinessLine] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[FEDCode] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[LegacyRef] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[FileDetailsStage] ADD CONSTRAINT [PK_FileDetailsStage] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
