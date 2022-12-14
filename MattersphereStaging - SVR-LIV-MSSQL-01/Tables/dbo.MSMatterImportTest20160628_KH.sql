CREATE TABLE [dbo].[MSMatterImportTest20160628_KH]
(
[clNo] [varchar] (7) COLLATE Latin1_General_CI_AS NOT NULL,
[fileNo] [int] NULL,
[extFileID] [int] NULL,
[fileDesc] [char] (40) COLLATE Latin1_General_CI_AS NOT NULL,
[fileResponsibleID] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[filePrincipleID] [int] NULL,
[fileDept] [char] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[fileType] [char] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[fileFundCode] [int] NULL,
[fileCurISOCode] [int] NULL,
[fileStatus] [int] NULL,
[fileCreated] [datetime] NOT NULL,
[fileUpdated] [int] NULL,
[fileClosed] [datetime] NULL,
[fileSource] [int] NULL,
[fileSection] [int] NULL,
[fileSectionGroup] [int] NULL,
[MattIndex] [int] NULL,
[Office] [int] NULL,
[brID] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[Partner] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[InsertDate] [int] NULL,
[Imported] [int] NULL,
[StatusID] [int] NULL,
[error] [int] NULL,
[errormsg] [int] NULL,
[NewMatterNumber] [int] NULL,
[BusinessLine] [int] NULL,
[FEDCode] [int] NULL
) ON [PRIMARY]
GO
