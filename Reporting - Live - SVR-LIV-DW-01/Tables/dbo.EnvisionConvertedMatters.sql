CREATE TABLE [dbo].[EnvisionConvertedMatters]
(
[Envision Reference] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Client] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[Matter] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[Matter Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[MSFileID] [bigint] NOT NULL
) ON [PRIMARY]
GO
