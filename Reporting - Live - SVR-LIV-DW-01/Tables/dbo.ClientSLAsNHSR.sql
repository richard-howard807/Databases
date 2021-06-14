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
[subsequent_report_months] [float] NULL
) ON [PRIMARY]
GO
