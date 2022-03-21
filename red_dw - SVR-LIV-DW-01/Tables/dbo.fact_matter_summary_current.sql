CREATE TABLE [dbo].[fact_matter_summary_current]
(
[dim_fed_hierarchy_history_key] [int] NOT NULL,
[dim_matter_header_history_key] [int] NOT NULL,
[dim_matter_header_curr_key] [int] NOT NULL CONSTRAINT [DF__fact_matt__dim_m__004EE8A4] DEFAULT ((0)),
[dim_client_key] [int] NOT NULL,
[dim_date_key] [int] NOT NULL,
[dim_open_practice_management_date_key] [int] NOT NULL CONSTRAINT [DF__fact_matt__dim_o__01430CDD] DEFAULT ((0)),
[dim_closed_practice_management_date_key] [int] NOT NULL CONSTRAINT [DF__fact_matt__dim_c__02373116] DEFAULT ((0)),
[dim_open_case_management_date_key] [int] NOT NULL CONSTRAINT [DF__fact_matt__dim_o__032B554F] DEFAULT ((0)),
[dim_closed_case_management_date_key] [int] NOT NULL CONSTRAINT [DF__fact_matt__dim_c__041F7988] DEFAULT ((0)),
[client_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[matter_number] [char] (8) COLLATE Latin1_General_BIN NULL,
[fee_earner_fed_code] [char] (20) COLLATE Latin1_General_BIN NULL,
[date_opened_practice_management] [datetime] NULL,
[date_closed_practice_management] [datetime] NULL,
[date_opened_case_management] [datetime] NULL,
[date_closed_case_management] [datetime] NULL,
[disbursement_balance] [numeric] (13, 2) NULL,
[client_account_balance_of_matter] [numeric] (13, 2) NULL,
[number_unpaid_bills] [smallint] NULL,
[number_bills_matter] [smallint] NULL,
[unpaid_bill_balance] [numeric] (13, 2) NULL,
[deposit_account_balance] [numeric] (13, 2) NULL,
[wip_balance] [numeric] (13, 2) NULL,
[costs_to_date] [numeric] (13, 2) NULL,
[time_billed] [numeric] (13, 2) NULL,
[unbilled_time] [int] NULL,
[fin_month] [int] NULL,
[closed_practice_management] [int] NULL,
[closed_case_management] [int] NULL,
[matter_count] [int] NULL,
[open_practice_management] [int] NULL,
[open_case_management] [int] NULL,
[closed_practice_management_month] [int] NULL,
[closed_case_management_month] [int] NULL,
[open_case_management_month] [int] NULL,
[open_practice_management_month] [int] NULL,
[closed_practice_management_fin_ytd] [int] NULL,
[closed_case_management_fin_ytd] [int] NULL,
[open_case_management_fin_ytd] [int] NULL,
[open_practice_management_fin_ytd] [int] NULL,
[fact_matter_summary_key] [int] NOT NULL IDENTITY(1, 1),
[dss_update_time] [datetime] NULL,
[last_bill_date] [datetime] NULL,
[dim_last_bill_date_key] [int] NULL,
[dim_last_transaction_date_key] [int] NULL,
[master_fact_key] [int] NOT NULL CONSTRAINT [DF__fact_matt__maste__346E767F] DEFAULT ((0)),
[no_future_tasks] [numeric] (18, 6) NULL,
[overdue_tasks] [int] NULL,
[number_of_exceptions] [int] NULL,
[critical_exceptions] [bit] NULL,
[last_time_transaction_date] [datetime] NULL,
[last_bill_total] [numeric] (13, 2) NULL,
[number_of_exceptions_mi] [int] NULL,
[critical_exceptions_mi] [bit] NULL,
[client_account_last_posting_date] [datetime] NULL,
[disbursements_only_flag] [int] NULL,
[dim_last_posting_date_key] [int] NULL
) ON [FACT_TAB]
GO
CREATE NONCLUSTERED COLUMNSTORE INDEX [fact_matter_summary_cu_idx_csi] ON [dbo].[fact_matter_summary_current] ([disbursements_only_flag], [last_bill_total], [critical_exceptions_mi], [critical_exceptions], [number_of_exceptions_mi], [number_of_exceptions], [overdue_tasks], [no_future_tasks], [dim_last_transaction_date_key], [dim_last_bill_date_key], [last_time_transaction_date], [last_bill_date], [fact_matter_summary_key], [open_practice_management_fin_ytd], [open_case_management_fin_ytd], [closed_case_management_fin_ytd], [closed_practice_management_fin_ytd], [open_practice_management_month], [open_case_management_month], [closed_case_management_month], [closed_practice_management_month], [open_case_management], [open_practice_management], [matter_count], [closed_case_management], [closed_practice_management], [fin_month], [unbilled_time], [time_billed], [costs_to_date], [wip_balance], [deposit_account_balance], [unpaid_bill_balance], [number_bills_matter], [number_unpaid_bills], [client_account_last_posting_date], [client_account_balance_of_matter], [disbursement_balance], [date_closed_case_management], [date_opened_case_management], [date_closed_practice_management], [date_opened_practice_management], [fee_earner_fed_code], [matter_number], [client_code], [master_fact_key], [dim_last_posting_date_key], [dim_closed_case_management_date_key], [dim_open_case_management_date_key], [dim_closed_practice_management_date_key], [dim_open_practice_management_date_key], [dim_date_key], [dim_client_key], [dim_matter_header_curr_key], [dim_matter_header_history_key], [dim_fed_hierarchy_history_key]) ON [FACT_IDX]
GO
CREATE UNIQUE NONCLUSTERED INDEX [fact_matter_summary_cu_idx_A] ON [dbo].[fact_matter_summary_current] ([client_code], [matter_number]) ON [FACT_IDX]
GO
GRANT SELECT ON  [dbo].[fact_matter_summary_current] TO [lnksvrdatareader_ext]
GO
GRANT SELECT ON  [dbo].[fact_matter_summary_current] TO [omnireader]
GO
GRANT SELECT ON  [dbo].[fact_matter_summary_current] TO [SBC\rmccab]
GO
EXEC sp_addextendedproperty N'Comment', N'Matter fact summary at lowest grain Non-additive', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', NULL, NULL
GO
EXEC sp_addextendedproperty N'Comment', N'Client code on matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'client_code'
GO
EXEC sp_addextendedproperty N'Comment', N'Tracks to see if the matter is closed in case management system', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'closed_case_management'
GO
EXEC sp_addextendedproperty N'Comment', N'Checks to see whether the date run the case has been closed in the current fin ytd.', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'closed_case_management_fin_ytd'
GO
EXEC sp_addextendedproperty N'Comment', N'Checks to see whether the date run the case has been closed in the current month period.', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'closed_case_management_month'
GO
EXEC sp_addextendedproperty N'Comment', N'Tracks to see of the matter is closed in finance system', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'closed_practice_management'
GO
EXEC sp_addextendedproperty N'Comment', N'Checks to see whether the date run the case has been closed in the current financial period', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'closed_practice_management_fin_ytd'
GO
EXEC sp_addextendedproperty N'Comment', N'Checks to see whether the date run the case has been closed in the current month period.', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'closed_practice_management_month'
GO
EXEC sp_addextendedproperty N'Comment', N'Fee value billed since the matter was opened', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'costs_to_date'
GO
EXEC sp_addextendedproperty N'Comment', N'The date the file was closed in case management', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'date_closed_case_management'
GO
EXEC sp_addextendedproperty N'Comment', N'The date the file was closed in finance system', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'date_closed_practice_management'
GO
EXEC sp_addextendedproperty N'Comment', N'The date the file was opened in case management', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'date_opened_case_management'
GO
EXEC sp_addextendedproperty N'Comment', N'The date the matter was opened in finance system', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'date_opened_practice_management'
GO
EXEC sp_addextendedproperty N'Comment', N'Designated deposit account balance of the matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'deposit_account_balance'
GO
EXEC sp_addextendedproperty N'Comment', N'stage_fact_matter_summary_05_monthly.source_system_id=dim_client.source_system_id
stage_fact_matter_summary_05_monthly.client_code=dim_client.client_code', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'dim_client_key'
GO
EXEC sp_addextendedproperty N'Comment', N'stage_fact_matter_summary_05_monthly.date_closed_case_management=dim_closed_case_management_date.calendar_date', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'dim_closed_case_management_date_key'
GO
EXEC sp_addextendedproperty N'Comment', N'stage_fact_matter_summary_05_monthly.date_closed_practice_management=dim_closed_practice_management_date.calendar_date', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'dim_closed_practice_management_date_key'
GO
EXEC sp_addextendedproperty N'Comment', N'dim_date.calendar_date=dim_date.calendar_date', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'dim_date_key'
GO
EXEC sp_addextendedproperty N'Comment', N'dim_fed_hierarchy.source_system_id=dim_fed_hierarchy.source_system_id
dim_fed_hierarchy.fed_hierarchy_business_key=dim_fed_hierarchy.fed_hierarchy_business_key
dim_fed_hierarchy.fed_code_effective_start_date=dim_fed_hierarchy.fed_code_effective_start_date', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'dim_fed_hierarchy_history_key'
GO
EXEC sp_addextendedproperty N'Comment', N'stage_fact_matter_summary_05_monthly.source_system_id=dim_matter_header_current.source_system_id
stage_fact_matter_summary_05_monthly.matter_number=dim_matter_header_current.matter_number
stage_fact_matter_summary_05_monthly.client_code=dim_matter_header_current.client_code', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'dim_matter_header_curr_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Generated artificial key', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'dim_matter_header_history_key'
GO
EXEC sp_addextendedproperty N'Comment', N'stage_fact_matter_summary_05_monthly.date_opened_case_management=dim_open_case_management_date.calendar_date', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'dim_open_case_management_date_key'
GO
EXEC sp_addextendedproperty N'Comment', N'stage_fact_matter_summary_05_monthly.date_opened_practice_management=dim_open_practice_management_date.calendar_date', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'dim_open_practice_management_date_key'
GO
EXEC sp_addextendedproperty N'Comment', N'disbursement balance', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'disbursement_balance'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'dss_update_time'
GO
EXEC sp_addextendedproperty N'Comment', N'fact_matter_summary_key', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'fact_matter_summary_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial month representation. Fromat YYYYMM. Examples: 200101, 200102.', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'fin_month'
GO
EXEC sp_addextendedproperty N'Comment', N'Aggregate for the number of matters', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'matter_count'
GO
EXEC sp_addextendedproperty N'Comment', N'Unique matter number with client code', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'matter_number'
GO
EXEC sp_addextendedproperty N'Comment', N'Total number of bills rendered on the matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'number_bills_matter'
GO
EXEC sp_addextendedproperty N'Comment', N'Number of unpaid bills on the matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'number_unpaid_bills'
GO
EXEC sp_addextendedproperty N'Comment', N'Tracks to see if the matter is open in case management system', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'open_case_management'
GO
EXEC sp_addextendedproperty N'Comment', N'Checks to see whether the date run the case has been closed in the current fin ytd.', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'open_case_management_fin_ytd'
GO
EXEC sp_addextendedproperty N'Comment', N'Checks to see whether the date run the case has been closed in the current month period.', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'open_case_management_month'
GO
EXEC sp_addextendedproperty N'Comment', N'Tracks to see of the matter is open in finance system', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'open_practice_management'
GO
EXEC sp_addextendedproperty N'Comment', N'Checks to see whether the date run the case has been closed in the current month period.', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'open_practice_management_fin_ytd'
GO
EXEC sp_addextendedproperty N'Comment', N'Checks to see whether the date run the case has been closed in the current month period.', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'open_practice_management_month'
GO
EXEC sp_addextendedproperty N'Comment', N'Value of time billed at charge for the matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'time_billed'
GO
EXEC sp_addextendedproperty N'Comment', N'Total time unbilled on the matter (minutes)', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'unbilled_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Unpaid bills balance of the matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'unpaid_bill_balance'
GO
EXEC sp_addextendedproperty N'Comment', N'Work in progress balance of the matter', 'SCHEMA', N'dbo', 'TABLE', N'fact_matter_summary_current', 'COLUMN', N'wip_balance'
GO
