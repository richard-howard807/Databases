CREATE TABLE [dbo].[dim_department]
(
[dim_department_key] [int] NOT NULL IDENTITY(1, 1),
[source_system_id] [int] NULL,
[department_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[department_name] [char] (40) COLLATE Latin1_General_BIN NULL,
[dss_update_time] [datetime] NULL
) ON [DIM_TAB]
GO
ALTER TABLE [dbo].[dim_department] ADD CONSTRAINT [dim_department_idx_0] PRIMARY KEY CLUSTERED  ([dim_department_key]) ON [DIM_TAB]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dim_department_idx_A] ON [dbo].[dim_department] ([department_code]) ON [DIM_IDX]
GO
GRANT SELECT ON  [dbo].[dim_department] TO [omnireader]
GO
EXEC sp_addextendedproperty N'Comment', N'Department Dimension', 'SCHEMA', N'dbo', 'TABLE', N'dim_department', NULL, NULL
GO
EXEC sp_addextendedproperty N'Comment', N'Department code from practice management system', 'SCHEMA', N'dbo', 'TABLE', N'dim_department', 'COLUMN', N'department_code'
GO
EXEC sp_addextendedproperty N'Comment', N'Name of department from practice management system', 'SCHEMA', N'dbo', 'TABLE', N'dim_department', 'COLUMN', N'department_name'
GO
EXEC sp_addextendedproperty N'Comment', N'Generated artificial key', 'SCHEMA', N'dbo', 'TABLE', N'dim_department', 'COLUMN', N'dim_department_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'dim_department', 'COLUMN', N'dss_update_time'
GO
