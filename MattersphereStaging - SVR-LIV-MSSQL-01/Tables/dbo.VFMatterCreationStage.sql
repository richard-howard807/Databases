CREATE TABLE [dbo].[VFMatterCreationStage]
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
[fileFundCode] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL CONSTRAINT [DF__VFMatterC__fileF__381A47C8] DEFAULT ('NOCHG'),
[fileCurISOCode] [nchar] (3) COLLATE Latin1_General_CI_AS NOT NULL CONSTRAINT [DF__VFMatterC__fileC__390E6C01] DEFAULT ('GBP'),
[fileStatus] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[fileCreated] [datetime] NULL CONSTRAINT [DF__VFMatterC__fileC__3A02903A] DEFAULT (getdate()),
[fileUpdated] [datetime] NULL,
[fileClosed] [datetime] NULL,
[fileSource] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL CONSTRAINT [DF__VFMatterC__fileS__3AF6B473] DEFAULT ('IMPORT'),
[fileSection] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[fileSectionGroup] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[MattIndex] [int] NULL,
[Office] [int] NULL,
[brID] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[Partner] [bigint] NOT NULL,
[InsertDate] [datetime] NOT NULL CONSTRAINT [DF__VFMatterC__Inser__3BEAD8AC] DEFAULT (getdate()),
[Imported] [datetime] NULL,
[StatusID] [tinyint] NOT NULL CONSTRAINT [DF__VFMatterC__Statu__3CDEFCE5] DEFAULT ((0)),
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[NewMatterNumber] [int] NULL,
[BusinessLine] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[FEDCode] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[SourceSystemID] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[VFMatterCreationStage] ADD CONSTRAINT [PK_VFMatterCreationStage] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
