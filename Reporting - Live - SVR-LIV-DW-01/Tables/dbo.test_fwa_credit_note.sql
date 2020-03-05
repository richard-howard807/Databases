CREATE TABLE [dbo].[test_fwa_credit_note]
(
[source_system_id] [int] NULL,
[bill_number] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[bill_sequence] [int] NOT NULL,
[timekeeper_code] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[bill_record_type] [char] (9) COLLATE Latin1_General_CI_AS NULL,
[billed_time] [numeric] (13, 2) NULL,
[bill_amount] [numeric] (10, 2) NULL,
[admin_charge_fee_earner] [numeric] (10, 2) NULL,
[client_code] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[matter_number] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[bill_date] [datetime] NULL,
[bill_total] [numeric] (10, 2) NULL,
[vat_amount] [numeric] (10, 2) NULL,
[administration_charges] [numeric] (10, 2) NULL,
[fees_total] [numeric] (10, 2) NULL,
[paid_disbursements] [numeric] (10, 2) NULL,
[unpaid_disbursements] [numeric] (10, 2) NULL,
[amount_paid] [numeric] (10, 2) NULL,
[workdate] [datetime] NULL,
[gldate] [datetime] NULL,
[dss_update_time] [datetime] NULL
) ON [PRIMARY]
GO
