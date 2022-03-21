CREATE TABLE [dbo].[dim_client_matter_summary]
(
[dim_client_matter_summ_key] [int] NOT NULL IDENTITY(1, 1),
[dim_client_key] [int] NOT NULL,
[client_group_code] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[client_group_name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[client_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[client_name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[title] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[firstname] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[surname] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[master_client_code] [nvarchar] (12) COLLATE Latin1_General_BIN NULL,
[date_last_opened_matter] [datetime] NULL,
[date_last_closed_matter] [datetime] NULL,
[branch] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[segment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[sub_sector] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[open_date] [datetime] NULL,
[client_partner_name] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[client_type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[crm_client_type] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[company_client_code] [nvarchar] (12) COLLATE Latin1_General_BIN NULL,
[client_status] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[job_title] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[dss_create_time] [datetime] NULL,
[dss_update_time] [datetime] NULL,
[company_house_number] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[archive_status] [char] (40) COLLATE Latin1_General_BIN NULL,
[website] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[phone_number] [char] (30) COLLATE Latin1_General_BIN NULL,
[email] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[firm_contact_code] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[firm_contact_name] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[client_partner_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[ia_sic_code] [nvarchar] (800) COLLATE Latin1_General_BIN NULL
) ON [DIM_TAB]
GO
ALTER TABLE [dbo].[dim_client_matter_summary] ADD CONSTRAINT [dim_client_matter_summ_idx_0] PRIMARY KEY CLUSTERED  ([dim_client_matter_summ_key]) ON [DIM_TAB]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dim_client_matter_summ_idx_A] ON [dbo].[dim_client_matter_summary] ([client_code]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_client_matter_summ_idx_x] ON [dbo].[dim_client_matter_summary] ([dim_client_key]) INCLUDE ([client_group_code], [client_group_name], [client_code], [client_name], [title], [firstname], [surname], [master_client_code], [date_last_opened_matter], [date_last_closed_matter], [branch], [segment], [sector], [sub_sector], [open_date], [client_partner_name], [client_type], [crm_client_type], [company_client_code], [client_status], [job_title], [company_house_number]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_client_matter_summ_idx_updtim] ON [dbo].[dim_client_matter_summary] ([dss_update_time]) INCLUDE ([dim_client_key]) ON [DIM_IDX]
GO
EXEC sp_addextendedproperty N'Comment', N'Client code on matter', 'SCHEMA', N'dbo', 'TABLE', N'dim_client_matter_summary', 'COLUMN', N'client_code'
GO
EXEC sp_addextendedproperty N'Comment', N'Client Group from Artiion', 'SCHEMA', N'dbo', 'TABLE', N'dim_client_matter_summary', 'COLUMN', N'client_group_code'
GO
EXEC sp_addextendedproperty N'Comment', N'Client Group from Artiion', 'SCHEMA', N'dbo', 'TABLE', N'dim_client_matter_summary', 'COLUMN', N'client_group_name'
GO
EXEC sp_addextendedproperty N'Comment', N'This is the client partner name and looks back to ds_employee and ds_employee_login', 'SCHEMA', N'dbo', 'TABLE', N'dim_client_matter_summary', 'COLUMN', N'client_partner_name'
GO
EXEC sp_addextendedproperty N'Comment', N'dim_client_matter_summary.client_code=dim_client.client_code', 'SCHEMA', N'dbo', 'TABLE', N'dim_client_matter_summary', 'COLUMN', N'dim_client_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Generated artificial key', 'SCHEMA', N'dbo', 'TABLE', N'dim_client_matter_summary', 'COLUMN', N'dim_client_matter_summ_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was created in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'dim_client_matter_summary', 'COLUMN', N'dss_create_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'dim_client_matter_summary', 'COLUMN', N'dss_update_time'
GO
EXEC sp_addextendedproperty N'Comment', N'client_extension_sector', 'SCHEMA', N'dbo', 'TABLE', N'dim_client_matter_summary', 'COLUMN', N'sector'
GO
