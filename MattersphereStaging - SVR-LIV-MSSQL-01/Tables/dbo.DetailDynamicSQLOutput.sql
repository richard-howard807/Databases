CREATE TABLE [dbo].[DetailDynamicSQLOutput]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[DataType] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[TableName] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[InsertDate] [datetime] NULL CONSTRAINT [DF__DetailDyn__Inser__51300E55] DEFAULT (getdate()),
[SQLStatement] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
