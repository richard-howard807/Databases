CREATE TABLE [dbo].[RMOtherDocsComments]
(
[client] [char] (8) COLLATE Latin1_General_CI_AS NULL,
[matter] [char] (8) COLLATE Latin1_General_CI_AS NULL,
[TextValue] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[DocType] [varchar] (24) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
