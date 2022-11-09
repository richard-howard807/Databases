CREATE TABLE [dbo].[dim_matter_header_current]
(
[source_system_id] [int] NULL,
[dim_matter_header_curr_key] [int] NOT NULL IDENTITY(1, 1),
[dim_department_key] [int] NOT NULL,
[dim_matter_worktype_key] [int] NOT NULL,
[dim_matter_group_key] [int] NOT NULL,
[client_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[case_id] [int] NULL,
[matter_number] [char] (8) COLLATE Latin1_General_BIN NULL,
[date_closed_practice_management] [datetime] NULL,
[date_opened_case_management] [datetime] NULL,
[dss_update_time] [datetime] NULL,
[client_group_code] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[client_group_name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[client_name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[matter_description] [varchar] (300) COLLATE Latin1_General_BIN NULL,
[date_opened_practice_management] [datetime] NULL,
[date_closed_case_management] [datetime] NULL,
[branch_code] [char] (4) COLLATE Latin1_General_BIN NULL,
[branch_name] [char] (40) COLLATE Latin1_General_BIN NULL,
[matter_partner_code] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[matter_partner_full_name] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[fee_earner_code] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[matter_owner_full_name] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[department_code] [char] (20) COLLATE Latin1_General_BIN NULL,
[fixed_fee] [char] (60) COLLATE Latin1_General_BIN NULL,
[fixed_fee_amount] [numeric] (13, 2) NULL,
[delegated] [char] (60) COLLATE Latin1_General_BIN NULL,
[reporting_exclusions] [smallint] NULL,
[dim_instruction_type_key] [int] NOT NULL CONSTRAINT [DF__dim_matte__dim_i__06F35B40] DEFAULT ((0)),
[final_bill_flag] [char] (1) COLLATE Latin1_General_BIN NULL,
[final_bill_date] [datetime] NULL,
[present_position] [char] (60) COLLATE Latin1_General_BIN NULL,
[master_client_code] [nvarchar] (12) COLLATE Latin1_General_BIN NULL,
[master_matter_number] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[billing_portal_status] [nvarchar] (64) COLLATE Latin1_General_BIN NULL,
[fee_arrangement] [char] (60) COLLATE Latin1_General_BIN NULL,
[billing_arrangement] [nvarchar] (16) COLLATE Latin1_General_BIN NULL,
[matter_category] [nvarchar] (1000) COLLATE Latin1_General_BIN NULL,
[billing_arrangement_description] [nvarchar] (64) COLLATE Latin1_General_BIN NULL,
[ms_only] [bit] NULL,
[billing_rate_description] [nvarchar] (64) COLLATE Latin1_General_BIN NULL,
[billing_rate] [nvarchar] (16) COLLATE Latin1_General_BIN NULL,
[business_source] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[client_balance_review] [nvarchar] (15) COLLATE Latin1_General_BIN NULL,
[date_client_balance_review] [datetime] NULL,
[ms_fileid] [bigint] NULL,
[default_email] [nvarchar] (200) COLLATE Latin1_General_BIN NULL,
[default_email_association] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[client_balance_review_comments] [varchar] (1000) COLLATE Latin1_General_BIN NULL,
[exclude_from_exceptions_reports] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[latest_archive_date] [datetime] NULL,
[latest_archive_status] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[latest_archive_type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[matter_team_manager_fed_code] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[matter_team_manager] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[matter_source_user_fed_code] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[matter_source_user] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[matter_source_contactid] [bigint] NULL,
[matter_source_contact_name] [nvarchar] (80) COLLATE Latin1_General_BIN NULL,
[opt_out_of_auto_client_email] [nvarchar] (15) COLLATE Latin1_General_BIN NULL,
[reason_for_email_opt_out] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[opt_out_reason_desc] [nvarchar] (255) COLLATE Latin1_General_BIN NULL
) ON [DIM_TAB]
GO
ALTER TABLE [dbo].[dim_matter_header_current] ADD CONSTRAINT [dim_matt_header_curren_idx_0] PRIMARY KEY CLUSTERED  ([dim_matter_header_curr_key]) ON [DIM_TAB]
GO
CREATE NONCLUSTERED INDEX [dim_matt_header_curren_idx_4] ON [dbo].[dim_matter_header_current] ([case_id]) INCLUDE ([client_code], [matter_number], [source_system_id]) ON [DIM_IDX]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dim_matt_header_curren_idx_A] ON [dbo].[dim_matter_header_current] ([client_code], [matter_number]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_matt_header_curren_idx_y] ON [dbo].[dim_matter_header_current] ([client_group_code], [reporting_exclusions]) INCLUDE ([client_code], [matter_number]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_matt_header_curren_idx_3] ON [dbo].[dim_matter_header_current] ([date_closed_case_management], [case_id]) INCLUDE ([client_code], [matter_description], [matter_owner_full_name]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_matt_header_curren_idx_1] ON [dbo].[dim_matter_header_current] ([date_closed_practice_management], [reporting_exclusions], [date_opened_practice_management]) INCLUDE ([dim_matter_header_curr_key]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_matt_header_curren_idx_x] ON [dbo].[dim_matter_header_current] ([dim_instruction_type_key]) INCLUDE ([date_closed_practice_management], [date_opened_case_management], [fee_earner_code]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_matt_header_curren_idx_5] ON [dbo].[dim_matter_header_current] ([dim_matter_header_curr_key]) INCLUDE ([dim_matter_worktype_key]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_matt_header_curren_idx_2] ON [dbo].[dim_matter_header_current] ([master_client_code]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_matt_header_curren_idx_fileid] ON [dbo].[dim_matter_header_current] ([ms_fileid]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [INX_dmhc_dim_matter_worktype_key] ON [dbo].[dim_matter_header_current] ([reporting_exclusions]) INCLUDE ([client_name], [date_closed_case_management], [date_opened_case_management], [dim_instruction_type_key], [dim_matter_worktype_key], [master_client_code], [master_matter_number], [matter_description], [ms_fileid]) ON [DIM_TAB]
GO
CREATE NONCLUSTERED INDEX [dim_matt_header_curren_idx_w] ON [dbo].[dim_matter_header_current] ([reporting_exclusions], [present_position], [fee_arrangement], [dim_matter_worktype_key]) INCLUDE ([client_code], [client_group_code], [client_group_name], [client_name], [date_closed_case_management], [date_closed_practice_management], [date_opened_case_management], [dim_instruction_type_key], [fixed_fee_amount], [master_client_code], [master_matter_number], [matter_description], [matter_number], [matter_owner_full_name]) ON [DIM_IDX]
GO
GRANT SELECT ON  [dbo].[dim_matter_header_current] TO [ebilling]
GO
GRANT SELECT ON  [dbo].[dim_matter_header_current] TO [lnksvrapperio]
GO
GRANT SELECT ON  [dbo].[dim_matter_header_current] TO [lnksvrdatareader]
GO
GRANT SELECT ON  [dbo].[dim_matter_header_current] TO [omnireader]
GO
GRANT SELECT ON  [dbo].[dim_matter_header_current] TO [SBC\lnksvrdatareader_ext]
GO
GRANT SELECT ON  [dbo].[dim_matter_header_current] TO [SBC\rmccab]
GO
EXEC sp_addextendedproperty N'Comment', N'Client code on matter', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'client_code'
GO
EXEC sp_addextendedproperty N'Comment', N'Date closed in MS.', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'date_closed_case_management'
GO
EXEC sp_addextendedproperty N'Comment', N'Date closed in 3e.', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'date_closed_practice_management'
GO
EXEC sp_addextendedproperty N'Comment', N'Date opened in MS.', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'date_opened_case_management'
GO
EXEC sp_addextendedproperty N'Comment', N'Date opened in 3e.', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'date_opened_practice_management'
GO
EXEC sp_addextendedproperty N'Comment', N'dim_matter_header_current.source_system_id=dim_department.source_system_id
dim_matter_header_current.department_code=dim_department.department_code', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'dim_department_key'
GO
EXEC sp_addextendedproperty N'Comment', N'dim_matter_header_current.source_system_id=dim_matter_group.source_system_id
dim_matter_header_current.matter_group_code=dim_matter_group.matter_group_code', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'dim_matter_group_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Generated artificial key', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'dim_matter_header_curr_key'
GO
EXEC sp_addextendedproperty N'Comment', N'dim_matter_header_current.source_system_id=dim_matter_worktype.source_system_id
dim_matter_header_current.work_type_code=dim_matter_worktype.work_type_code', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'dim_matter_worktype_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'dss_update_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Unique matter number with client code', 'SCHEMA', N'dbo', 'TABLE', N'dim_matter_header_current', 'COLUMN', N'matter_number'
GO
