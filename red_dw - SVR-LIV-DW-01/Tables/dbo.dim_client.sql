CREATE TABLE [dbo].[dim_client]
(
[dim_client_key] [int] NOT NULL IDENTITY(0, 1),
[source_system_id] [int] NULL,
[client_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[client_name] [char] (80) COLLATE Latin1_General_BIN NULL,
[client_group_name] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[client_partner_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[client_partner_name] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[contact_salutation] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[contact_name] [varchar] (80) COLLATE Latin1_General_BIN NULL,
[address_type] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[addresse] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[address_line_1] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[address_line_2] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[address_line_3] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[address_line_4] [char] (50) COLLATE Latin1_General_BIN NULL,
[postcode] [char] (15) COLLATE Latin1_General_BIN NULL,
[phone_number] [char] (30) COLLATE Latin1_General_BIN NULL,
[dss_update_time] [datetime] NULL,
[open_date] [datetime] NULL,
[sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[audit_alert] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[aml_failed] [nvarchar] (3) COLLATE Latin1_General_BIN NULL,
[client_status] [nvarchar] (15) COLLATE Latin1_General_BIN NULL,
[file_alert_message] [nvarchar] (150) COLLATE Latin1_General_BIN NULL,
[credit_limit] [numeric] (13, 2) NULL,
[client_type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[aml_client_type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[client_group_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[email] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[branch] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[address_line_5] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[business_source] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[referrer_type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[sub_sector] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[segment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[business_source_name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[created_by] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[practice_management_client_status] [nvarchar] (16) COLLATE Latin1_General_BIN NULL,
[client_group_partner] [nvarchar] (15) COLLATE Latin1_General_BIN NULL,
[client_group_partner_name] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[firm_contact_code] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[firm_contact_name] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[generator_status] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[contactid] [bigint] NULL,
[push_to_ia] [bit] NULL,
[client_source_contactid] [bigint] NULL,
[client_source_contact] [nvarchar] (80) COLLATE Latin1_General_BIN NULL,
[client_source_user_fed_code] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[client_source_user] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[client_source] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[credit_specialist] [nvarchar] (80) COLLATE Latin1_General_BIN NULL
) ON [DIM_IDX]
GO
ALTER TABLE [dbo].[dim_client] ADD CONSTRAINT [dim_client_idx_0] PRIMARY KEY CLUSTERED  ([dim_client_key]) ON [DIM_IDX]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dim_client_idx_A] ON [dbo].[dim_client] ([client_code]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_client_idx_grp] ON [dbo].[dim_client] ([client_group_code]) INCLUDE ([client_group_name]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_client_idx_grnm] ON [dbo].[dim_client] ([client_group_name]) INCLUDE ([client_group_code]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_client_idx_x] ON [dbo].[dim_client] ([client_name]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_client_idx_contact_x] ON [dbo].[dim_client] ([contactid]) ON [DIM_IDX]
GO
GRANT SELECT ON  [dbo].[dim_client] TO [ebilling]
GO
GRANT SELECT ON  [dbo].[dim_client] TO [lnksvrdatareader]
GO
GRANT SELECT ON  [dbo].[dim_client] TO [omnireader]
GO
GRANT SELECT ON  [dbo].[dim_client] TO [SBC\lnksvrdatareader_ext]
GO
EXEC sp_addextendedproperty N'Comment', N'Main client dimension', 'SCHEMA', N'dbo', 'TABLE', N'dim_client', NULL, NULL
GO
EXEC sp_addextendedproperty N'Comment', N'Business key for dimension. Padded with 0''s if code is a number', 'SCHEMA', N'dbo', 'TABLE', N'dim_client', 'COLUMN', N'client_code'
GO
EXEC sp_addextendedproperty N'Comment', N'Client Group code', 'SCHEMA', N'dbo', 'TABLE', N'dim_client', 'COLUMN', N'client_group_code'
GO
EXEC sp_addextendedproperty N'Comment', N'Client Group ', 'SCHEMA', N'dbo', 'TABLE', N'dim_client', 'COLUMN', N'client_group_name'
GO
EXEC sp_addextendedproperty N'Comment', N'Partner listed in MS for the client', 'SCHEMA', N'dbo', 'TABLE', N'dim_client', 'COLUMN', N'client_group_partner'
GO
EXEC sp_addextendedproperty N'Comment', N'login of client partner - FEDCode in dim_fed_hierarchy_history ', 'SCHEMA', N'dbo', 'TABLE', N'dim_client', 'COLUMN', N'client_partner_code'
GO
EXEC sp_addextendedproperty N'Comment', N'Generated artificial key for dimension', 'SCHEMA', N'dbo', 'TABLE', N'dim_client', 'COLUMN', N'dim_client_key'
GO
