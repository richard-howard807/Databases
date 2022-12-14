CREATE TABLE [dbo].[ClientSLAsNHSR]
(
[master_client_code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[nhs_instruction_type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[do_clients_require_initial_report] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[initial_report_rule] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[initial_report_sla_days] [float] NULL,
[subsequent_report_rule] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[subsequent_report_days] [float] NULL,
[subsequent_report_working_days] [float] NULL,
[subsequent_report_months] [float] NULL,
[inverted_initial_rule] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[initial_report_working_days_flag] [nvarchar] (3) COLLATE Latin1_General_CI_AS NULL,
[can_sub_report_rule_be_calculated] [nvarchar] (3) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
