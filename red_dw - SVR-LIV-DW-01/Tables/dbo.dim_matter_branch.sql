CREATE TABLE [dbo].[dim_matter_branch]
(
[dim_matter_branch_key] [int] NOT NULL IDENTITY(1, 1),
[source_system_id] [int] NULL,
[branch_code] [char] (4) COLLATE Latin1_General_BIN NULL,
[branch_name] [char] (40) COLLATE Latin1_General_BIN NULL,
[dss_update_time] [datetime] NULL
) ON [DIM_TAB]
GO
ALTER TABLE [dbo].[dim_matter_branch] ADD CONSTRAINT [dim_matter_branch_idx_0] PRIMARY KEY CLUSTERED ([dim_matter_branch_key]) ON [DIM_TAB]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dim_matter_branch_idx_A] ON [dbo].[dim_matter_branch] ([branch_code]) ON [DIM_IDX]
GO
GRANT SELECT ON  [dbo].[dim_matter_branch] TO [omnireader]
GO
EXEC sp_addextendedproperty N'Comment', N'Generated artificial key', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_branch', 'COLUMN', N'dim_matter_branch_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_branch', 'COLUMN', N'dss_update_time'
GO
