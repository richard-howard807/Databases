CREATE TABLE [dbo].[cboTeamUpdate080519]
(
[fileID] [bigint] NOT NULL,
[Client] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[Matter] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[Matter Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[cboTeam] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[NewcboTeam] [varchar] (4) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
