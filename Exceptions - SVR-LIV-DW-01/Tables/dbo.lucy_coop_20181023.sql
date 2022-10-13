CREATE TABLE [dbo].[lucy_coop_20181023]
(
[case_id] [int] NULL,
[client_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[matter_number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Mattersphere Ref] [nvarchar] (33) COLLATE Latin1_General_BIN NULL,
[Case Manager] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Matter Category] [nvarchar] (1000) COLLATE Latin1_General_BIN NULL,
[Client Group Name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Client / Benchmark] [varchar] (10) COLLATE Latin1_General_CI_AS NOT NULL,
[Date Case Opened] [datetime] NULL,
[Date Case Closed] [datetime] NULL,
[Referral Reason] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Proceedings Issued?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date Proceedings Issued] [datetime] NULL,
[Track] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Delegated] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[fixed_fee] [char] (60) COLLATE Latin1_General_BIN NULL,
[fee_arrangement] [char] (60) COLLATE Latin1_General_BIN NULL,
[incident_date] [datetime] NULL,
[damages_reserve_initial] [numeric] (13, 2) NULL,
[damages_reserve] [numeric] (13, 2) NULL,
[defence_costs_reserve] [numeric] (13, 2) NULL,
[outcome_of_case] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[date_claim_concluded] [datetime] NULL,
[damages_paid_to_date] [numeric] (13, 2) NULL,
[date_costs_settled] [datetime] NULL,
[claimants_total_costs_paid_by_all_parties] [numeric] (13, 2) NULL,
[defence_costs_billed] [numeric] (13, 2) NULL,
[repudiated] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ Personal injury reserve initial] [numeric] (38, 2) NULL,
[Past care reserve initial] [numeric] (38, 2) NULL,
[Past loss of earnings reserve initial] [numeric] (38, 2) NULL,
[Past misc reserve initial] [numeric] (38, 2) NULL,
[Future care reserve initial] [numeric] (38, 2) NULL,
[Future loss of earnings reserve initial] [numeric] (38, 2) NULL,
[Future misc reserve initial] [numeric] (38, 2) NULL,
[personal_injury_reserve_current] [numeric] (13, 2) NULL,
[past_care_reserve_current] [numeric] (13, 2) NULL,
[past_loss_of_earnings_reserve_current] [numeric] (13, 2) NULL,
[special_damages_miscellaneous_reserve] [numeric] (13, 2) NULL,
[future_care_reserve_current] [numeric] (13, 2) NULL,
[future_loss_of_earnings_reserve_current] [numeric] (13, 2) NULL,
[future_loss_misc_reserve_current] [numeric] (13, 2) NULL,
[personal_injury_paid] [numeric] (13, 2) NULL,
[past_care_paid] [numeric] (13, 2) NULL,
[past_loss_of_earnings_paid] [numeric] (13, 2) NULL,
[special_damages_miscellaneous_paid] [numeric] (13, 2) NULL,
[future_care_paid] [numeric] (13, 2) NULL,
[future_loss_of_earnings_paid] [numeric] (13, 2) NULL,
[future_loss_misc_paid] [numeric] (13, 2) NULL,
[display_name] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[minutes_recorded] [numeric] (38, 2) NULL
) ON [PRIMARY]
GO
