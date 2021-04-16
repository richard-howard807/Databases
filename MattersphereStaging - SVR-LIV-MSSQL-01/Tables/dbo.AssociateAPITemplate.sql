CREATE TABLE [dbo].[AssociateAPITemplate]
(
[clNo] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[fileNo] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[contID] [bigint] NULL,
[assocType] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[assocdefaultaddID] [bigint] NULL,
[assocRef] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[assocEmail] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[FileIDCheck] [int] NULL
) ON [PRIMARY]
GO
