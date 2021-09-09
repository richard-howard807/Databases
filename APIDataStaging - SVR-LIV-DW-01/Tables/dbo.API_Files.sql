CREATE TABLE [dbo].[API_Files]
(
[API_Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FileName] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Friendly_Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[db_table] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[JSON_Query] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
