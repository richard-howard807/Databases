CREATE TABLE [dbo].[p45NHSCASES_Tranches]
(
[panel_ref] [nvarchar] (33) COLLATE Latin1_General_BIN NULL,
[date_closed] [date] NULL,
[scheme] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[tranche] [varchar] (19) COLLATE Latin1_General_CI_AS NULL,
[settlement_time] [float] NULL,
[defence_costs_billed] [numeric] (13, 2) NULL,
[claimants_costs_paid] [numeric] (13, 2) NULL,
[damages_paid] [numeric] (13, 2) NULL,
[settle_over] [varchar] (5) COLLATE Latin1_General_CI_AS NOT NULL,
[def_over] [varchar] (5) COLLATE Latin1_General_CI_AS NOT NULL,
[dam_over] [varchar] (5) COLLATE Latin1_General_CI_AS NOT NULL,
[claimant_costs_over] [varchar] (5) COLLATE Latin1_General_CI_AS NOT NULL,
[settlement_time_av] [float] NULL,
[defence_costs_av] [float] NULL,
[damages_av] [float] NULL,
[claimant_costs_av] [float] NULL
) ON [PRIMARY]
GO
