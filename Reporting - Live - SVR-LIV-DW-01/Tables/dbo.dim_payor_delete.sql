CREATE TABLE [dbo].[dim_payor_delete]
(
[dim_payor_key] [int] NOT NULL IDENTITY(1, 1),
[source_system_id] [int] NULL,
[payorindex] [int] NULL,
[client] [int] NULL,
[entity] [int] NULL,
[site] [int] NULL,
[payor_name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[payor_name_parent] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[altnum] [nvarchar] (64) COLLATE Latin1_General_BIN NULL,
[stmtsite] [int] NULL
) ON [PRIMARY]
GO
