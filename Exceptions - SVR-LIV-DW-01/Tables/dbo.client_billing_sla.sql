CREATE TABLE [dbo].[client_billing_sla]
(
[master_client_code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[client_name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[bill_type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fixed_fee_rules] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[hourly_rate_rules] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[wip_minimum] [float] NULL,
[bill_frequency_months] [float] NULL,
[on_weightmans_quarter] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[bill_rule_num] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fixed_fee_success_fee] [nvarchar] (3) COLLATE Latin1_General_CI_AS NULL,
[billing_project] [nvarchar] (20) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
