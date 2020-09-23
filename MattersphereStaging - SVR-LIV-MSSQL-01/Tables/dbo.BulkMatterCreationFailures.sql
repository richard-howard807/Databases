CREATE TABLE [dbo].[BulkMatterCreationFailures]
(
[ID] [bigint] NOT NULL IDENTITY(1, 1),
[ORDERID] [float] NULL,
[clNo] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Owner] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Department] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Work Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FileStatus] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fileCreated] [datetime] NULL,
[Partner] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[StatusID] [float] NULL,
[InsertDate] [datetime] NULL CONSTRAINT [DF__BulkMatte__Inser__12E8C319] DEFAULT (getdate())
) ON [PRIMARY]
GO
