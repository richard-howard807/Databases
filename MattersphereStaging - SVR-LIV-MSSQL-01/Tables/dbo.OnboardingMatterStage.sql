CREATE TABLE [dbo].[OnboardingMatterStage]
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
[fileFundCode] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL CONSTRAINT [DF__Onboardin__fileF__4B180DA3] DEFAULT ('NOCHG'),
[fileCurISOCode] [nchar] (3) COLLATE Latin1_General_CI_AS NOT NULL CONSTRAINT [DF__Onboardin__fileC__4C0C31DC] DEFAULT ('GBP'),
[fileStatus] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[fileCreated] [datetime] NULL CONSTRAINT [DF__Onboardin__fileC__4D005615] DEFAULT (getdate()),
[fileUpdated] [datetime] NULL,
[fileClosed] [datetime] NULL,
[fileSource] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL CONSTRAINT [DF__Onboardin__fileS__4DF47A4E] DEFAULT ('IMPORT'),
[fileSection] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[fileSectionGroup] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[MattIndex] [int] NULL,
[Office] [int] NULL,
[brID] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[Partner] [bigint] NOT NULL,
[InsertDate] [datetime] NOT NULL CONSTRAINT [DF__Onboardin__Inser__4EE89E87] DEFAULT (getdate()),
[Imported] [datetime] NULL,
[StatusID] [tinyint] NOT NULL CONSTRAINT [DF__Onboardin__Statu__4FDCC2C0] DEFAULT ((0)),
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[NewMatterNumber] [int] NULL,
[BusinessLine] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[FEDCode] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[LegacyRef] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[OnboardingMatterStage] ADD CONSTRAINT [PK_OnboardingMatterStage] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
