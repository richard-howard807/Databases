CREATE TABLE [dbo].[exceptions_field_test]
(
[fieldID] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[error_description] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[exception_name] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[sql_query] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[error] [int] NULL
) ON [PRIMARY]
GO
