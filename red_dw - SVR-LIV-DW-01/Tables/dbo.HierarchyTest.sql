CREATE TABLE [dbo].[HierarchyTest]
(
[windowsusername] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[director_flag] [bit] NULL,
[hierarchy2] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[hierarchy3] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[hierarchy4] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[default_hierarchy2] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[default_hierarchy3] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[default_hierarchy4] [varchar] (100) COLLATE Latin1_General_BIN NULL
) ON [WRK_TAB]
GO
