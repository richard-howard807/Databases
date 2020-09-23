CREATE TABLE [dbo].[PickLists]
(
[Detail] [char] (10) COLLATE Latin1_General_CI_AS NULL,
[Detail desc] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FED Code] [int] NULL,
[FED Desc] [char] (60) COLLATE Latin1_General_CI_AS NULL,
[MS Lookup Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MS Option Code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
