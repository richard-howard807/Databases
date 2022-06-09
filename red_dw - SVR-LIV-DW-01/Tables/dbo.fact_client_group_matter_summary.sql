CREATE TABLE [dbo].[fact_client_group_matter_summary]
(
[dim_client_group_summa_key] [int] NOT NULL,
[client_group_code] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[client_group_name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[costs_to_date_ytd] [numeric] (13, 2) NULL,
[wip_balance_ytd] [numeric] (13, 2) NULL,
[costs_to_date_ytd1] [numeric] (13, 2) NULL,
[wip_balance_ytd1] [numeric] (13, 2) NULL,
[costs_to_date_ytd2] [numeric] (13, 2) NULL,
[wip_balance_ytd2] [numeric] (13, 2) NULL,
[costs_to_date_running] [numeric] (13, 2) NULL,
[wip_balance_running] [numeric] (13, 2) NULL,
[open_matters] [int] NULL,
[debt_total] [numeric] (13, 2) NULL,
[aged_debt_total] [numeric] (13, 2) NULL,
[dss_create_time] [datetime] NULL,
[dss_update_time] [datetime] NULL
) ON [FACT_TAB]
GO
CREATE UNIQUE NONCLUSTERED INDEX [fact_client_group_matt_idx_A] ON [dbo].[fact_client_group_matter_summary] ([client_group_code], [client_group_name]) ON [FACT_IDX]
GO
CREATE NONCLUSTERED INDEX [fact_client_group_matt_idx_1] ON [dbo].[fact_client_group_matter_summary] ([dim_client_group_summa_key]) ON [FACT_IDX]
GO
EXEC sp_addextendedproperty N'Comment', N'Client Group from Artiion', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'client_group_code'
GO
EXEC sp_addextendedproperty N'Comment', N'Client Group from Artiion', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'client_group_name'
GO
EXEC sp_addextendedproperty N'Comment', N'Fee value billed since the matter was opened', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'costs_to_date_running'
GO
EXEC sp_addextendedproperty N'Comment', N'Fee value billed since the matter was opened', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'costs_to_date_ytd'
GO
EXEC sp_addextendedproperty N'Comment', N'Fee value billed since the matter was opened', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'costs_to_date_ytd1'
GO
EXEC sp_addextendedproperty N'Comment', N'Fee value billed since the matter was opened', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'costs_to_date_ytd2'
GO
EXEC sp_addextendedproperty N'Comment', N'stage_fact_client_group_matter_summary_10_dims.client_group_code=dim_client_group_summary.client_group_code
stage_fact_client_group_matter_summary_10_dims.client_group_name=dim_client_group_summary.client_group_name', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'dim_client_group_summa_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was created in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'dss_create_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'dss_update_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Work in progress balance of the matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'wip_balance_running'
GO
EXEC sp_addextendedproperty N'Comment', N'Work in progress balance of the matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'wip_balance_ytd'
GO
EXEC sp_addextendedproperty N'Comment', N'Work in progress balance of the matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'wip_balance_ytd1'
GO
EXEC sp_addextendedproperty N'Comment', N'Work in progress balance of the matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_client_group_matter_summary', 'COLUMN', N'wip_balance_ytd2'
GO
