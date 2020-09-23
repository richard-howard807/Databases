CREATE TABLE [dbo].[NCNewStartersMatters]
(
[clNo] [nvarchar] (53) COLLATE Latin1_General_CI_AS NOT NULL,
[fileNo] [varchar] (1) COLLATE Latin1_General_CI_AS NOT NULL,
[fileDesc] [nvarchar] (118) COLLATE Latin1_General_CI_AS NOT NULL,
[fileResponsibleID] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[filePrincipleID] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[fileDept] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[fileType] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[fileStatus] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[fileCreated] [datetime] NULL,
[fileUpdated] [int] NULL,
[fileClosed] [int] NULL,
[fileSource] [int] NULL,
[fileSection] [int] NULL,
[fileSectionGroup] [int] NULL,
[Office] [int] NULL,
[brID] [varchar] (2) COLLATE Latin1_General_CI_AS NOT NULL,
[Partner] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[Imported] [int] NULL,
[StatusID] [int] NOT NULL,
[error] [int] NULL,
[errormsg] [int] NULL
) ON [PRIMARY]
GO
