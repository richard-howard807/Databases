CREATE TABLE [dbo].[JL_TimeTrans]
(
[client_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[matter_number] [char] (8) COLLATE Latin1_General_BIN NULL,
[dim_transaction_date_key] [int] NULL,
[dim_gl_date_key] [int] NULL,
[time_activity_code] [nvarchar] (16) COLLATE Latin1_General_BIN NULL,
[chargeable_nonc_nonb] [char] (2) COLLATE Latin1_General_BIN NULL,
[minutes_recorded] [numeric] (13, 2) NULL,
[hourly_charge_rate] [numeric] (10, 2) NULL,
[time_charge_value] [numeric] (13, 2) NULL,
[dim_all_time_narrative_key] [int] NULL,
[dim_all_time_activity_key] [int] NULL,
[Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[narrative] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[proceedings_issued] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[reason_for_instruction] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[GUIDNumber] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[fixed_fee] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[FeeArrangement] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[client_group_name] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[referral_reason] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[present_position] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
