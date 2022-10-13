CREATE TABLE [dbo].[MSTeamChanges070722]
(
[ms_fileid] [float] NULL,
[fed_code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[client_code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[matter_number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MS_ref] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[date_open] [datetime] NULL,
[fileID] [float] NULL,
[Matter_Owner] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[NewTeam] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[NewTeamName] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DWHNewTeam] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[OldTeam] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[OldTeamName] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[client_code1] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[matter_number1] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
