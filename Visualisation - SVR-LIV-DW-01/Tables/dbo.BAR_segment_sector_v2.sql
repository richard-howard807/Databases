CREATE TABLE [dbo].[BAR_segment_sector_v2]
(
[segment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[dim_gl_date_key] [int] NULL,
[gl_fin_month_no] [int] NULL,
[gl_fin_year] [int] NULL,
[gl_fin_period] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[gl_fin_month] [int] NULL,
[gl_calendar_date] [datetime] NULL,
[bill_amount] [numeric] (38, 2) NULL,
[outstanding_total_bill] [numeric] (38, 2) NULL,
[outstanding_total_bill_180_days] [numeric] (38, 2) NULL,
[outstanding_costs] [numeric] (38, 2) NULL,
[outstanding_costs_180_days] [numeric] (38, 2) NULL,
[wip_minutes] [numeric] (38, 2) NULL,
[wip_value] [numeric] (38, 2) NULL,
[wip_over_90_days] [numeric] (38, 2) NULL,
[target] [numeric] (6, 4) NULL,
[financial_year] [int] NULL
) ON [PRIMARY]
GO
