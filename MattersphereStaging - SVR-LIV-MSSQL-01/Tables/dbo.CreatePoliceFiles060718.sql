CREATE TABLE [dbo].[CreatePoliceFiles060718]
(
[ORDERID] [float] NULL,
[clNo] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[claimants name for conlict check] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[file description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fileResponsibleID] [float] NULL,
[filePrincipleID] [float] NULL,
[fileDept] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fileType] [float] NULL,
[fileSection] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fileSectionGroup] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[BusinessLine] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Client ref] [float] NULL
) ON [PRIMARY]
GO
