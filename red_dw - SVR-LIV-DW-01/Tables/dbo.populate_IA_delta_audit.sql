CREATE TABLE [dbo].[populate_IA_delta_audit]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[table_populated] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[insert_time] [datetime] NULL,
[rows_inserted] [int] NULL
) ON [WRK_TAB]
GO
ALTER TABLE [dbo].[populate_IA_delta_audit] ADD CONSTRAINT [PK__populate__3213E83FE5716848] PRIMARY KEY CLUSTERED  ([id]) ON [WRK_TAB]
GO
