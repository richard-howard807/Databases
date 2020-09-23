CREATE TABLE [Exceptions].[ExceptionsEmailTable]
(
[datasetid] [int] NOT NULL,
[email_sent] [tinyint] NOT NULL,
[date_added] [datetime] NULL,
[ERROR_MESSAGE] [nvarchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
