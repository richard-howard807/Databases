CREATE TABLE [dbo].[ds_mds_divergent_hierarchy]
(
[windowslogin] [nvarchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[mdx_string] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[sql_string] [nvarchar] (1000) COLLATE Latin1_General_BIN NOT NULL,
[dax_string] [nvarchar] (max) COLLATE Latin1_General_BIN NULL
) ON [DS_TAB]
GO
