CREATE TABLE [dbo].[KevComments]
(
[ID] [int] NOT NULL,
[Comment] [nvarchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[Extension] [nvarchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[date] [datetime] NOT NULL,
[Name] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
