CREATE TABLE [dbo].[dim_date]
(
[dim_date_key] [int] NOT NULL,
[calendar_date] [datetime] NULL,
[cal_day_in_week] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[cal_day_in_week_no] [int] NULL,
[cal_day_in_month] [int] NULL,
[cal_day_in_year] [int] NULL,
[cal_week_in_year] [int] NULL,
[cal_month_no] [int] NULL,
[cal_month] [int] NULL,
[cal_month_name] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[cal_quarter_no] [int] NULL,
[cal_quarter] [int] NULL,
[cal_year] [int] NULL,
[financial_date] [datetime] NULL,
[fin_day_in_week] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[fin_day_in_week_no] [int] NULL,
[fin_day_in_month] [int] NULL,
[fin_day_in_year] [int] NULL,
[fin_week_in_month] [int] NULL,
[fin_week_in_year] [int] NULL,
[fin_month_no] [int] NULL,
[fin_month] [int] NULL,
[fin_month_display] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[fin_month_name] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[fin_period] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[fin_quarter_no] [int] NULL,
[fin_quarter] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[fin_year] [int] NULL,
[current_cal_day] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_cal_week] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_cal_month] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_cal_year] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_cal_mtd] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_cal_ytd] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[moving_cal_year] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_fin_day] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_fin_week] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_fin_month] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_fin_quarter] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_fin_year] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_fin_mtd] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_fin_ytd] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[moving_fin_quarter] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[moving_fin_year] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[week_day_flag] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[week_end_flag] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[holiday_flag] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[holiday_desc] [varchar] (64) COLLATE Latin1_General_BIN NULL,
[trading_day_flag] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[trading_days_in_mth] [int] NULL,
[trading_days_so_far] [int] NULL,
[dss_update_time] [datetime] NULL,
[audit_date] [datetime] NULL,
[aud_day_in_week] [varchar] (3) COLLATE Latin1_General_BIN NULL,
[aud_day_in_week_no] [int] NULL,
[aud_day_in_month] [int] NULL,
[aud_day_in_year] [int] NULL,
[aud_month_no] [int] NULL,
[aud_month] [int] NULL,
[aud_month_display] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[aud_week_in_year] [int] NULL,
[aud_month_name] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[aud_period] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[aud_quarter_no] [int] NULL,
[aud_quarter] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[aud_year] [int] NULL,
[current_aud_day] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_aud_week] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_aud_month] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_aud_quarter] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_aud_year] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_aud_mtd] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[current_aud_ytd] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[moving_aud_quarter] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[moving_aud_year] [varchar] (8) COLLATE Latin1_General_BIN NULL
) ON [DIM_TAB]
GO
ALTER TABLE [dbo].[dim_date] ADD CONSTRAINT [dim_date_idx_0] PRIMARY KEY NONCLUSTERED  ([dim_date_key]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [IDX_NCL_DimDate_20170215_1] ON [dbo].[dim_date] ([cal_month]) ON [DIM_IDX]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dim_date_idx_A] ON [dbo].[dim_date] ([calendar_date]) ON [DIM_IDX]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dim_date_n_idx_A] ON [dbo].[dim_date] ([calendar_date]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_date_n_idx_2] ON [dbo].[dim_date] ([dim_date_key]) INCLUDE ([fin_month_no], [fin_period], [fin_year], [current_fin_month]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_date_n_idx_y] ON [dbo].[dim_date] ([dim_date_key]) INCLUDE ([holiday_flag], [trading_day_flag]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [IDX_NCL_DimDate_20170215] ON [dbo].[dim_date] ([fin_month]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_date_n_idx_x] ON [dbo].[dim_date] ([fin_period]) INCLUDE ([fin_month], [fin_year]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_date_n_idx_2016111] ON [dbo].[dim_date] ([fin_year]) INCLUDE ([calendar_date]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [IX_dim_date_weekendflag_calendardate] ON [dbo].[dim_date] ([week_end_flag], [calendar_date]) ON [DIM_TAB]
GO
GRANT SELECT ON  [dbo].[dim_date] TO [db_ssrs_dynamicsecurity]
GO
GRANT SELECT ON  [dbo].[dim_date] TO [extranetdatesync]
GO
DENY SELECT ON  [dbo].[dim_date] TO [lnksvrdatareader]
GO
DENY SELECT ON  [dbo].[dim_date] TO [lnksvrdatareader_artdb]
GO
GRANT SELECT ON  [dbo].[dim_date] TO [omnireader]
GO
GRANT SELECT ON  [dbo].[dim_date] TO [SBC\lnksvrdatareader_ext]
GO
GRANT SELECT ON  [dbo].[dim_date] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited]
GO
GRANT SELECT ON  [dbo].[dim_date] TO [SBC\SSAS - DWH-02 Cube Readers]
GO
EXEC sp_addextendedproperty N'Comment', N'Date dimension, generated.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', NULL, NULL
GO
EXEC sp_addextendedproperty N'Comment', N'The day in the month 1-31.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_day_in_month'
GO
EXEC sp_addextendedproperty N'Comment', N'The day in the week. Format DDD. Example: mon, tue, wed.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_day_in_week'
GO
EXEC sp_addextendedproperty N'Comment', N'The day number in the week. 1-7 where Sunday is day 1.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_day_in_week_no'
GO
EXEC sp_addextendedproperty N'Comment', N'The day in the year 1-366.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_day_in_year'
GO
EXEC sp_addextendedproperty N'Comment', N'The calendar month representation. Format YYYYMM. Example: 200206.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_month'
GO
EXEC sp_addextendedproperty N'Comment', N'The calendar month name. Format MON. Examples: jan, feb, mar.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_month_name'
GO
EXEC sp_addextendedproperty N'Comment', N'The calendar month number 1-12.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_month_no'
GO
EXEC sp_addextendedproperty N'Comment', N'The calendar quarter representation. Format YYYYQQ. Example 200204.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_quarter'
GO
EXEC sp_addextendedproperty N'Comment', N'The calendar quarter number 1-4.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_quarter_no'
GO
EXEC sp_addextendedproperty N'Comment', N'The week in the year 0-53.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_week_in_year'
GO
EXEC sp_addextendedproperty N'Comment', N'The calendar year. Format YYYY', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'cal_year'
GO
EXEC sp_addextendedproperty N'Comment', N'The calendar date for this row.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'calendar_date'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current day. Normally set to the last day information was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_cal_day'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current month. Set as per current_cal_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_cal_month'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate days in the current month to date. Set as per current_cal_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_cal_mtd'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current week. Set as per current_cal_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_cal_week'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current year. Set as per current_cal_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_cal_year'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate days in the current year to date. Set as per current_cal_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_cal_ytd'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current financial day. Normally set to the last financial day information was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_fin_day'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current financial month. Set as per current_fin_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_fin_month'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate days in the current financial month to date. Set as per current_fin_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_fin_mtd'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current financial quarter. Set as per current_fin_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_fin_quarter'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current financial week. Set as per current_fin_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_fin_week'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current financial year. Set as per current_fin_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_fin_year'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate days in the current financial year to date. Set as per current_fin_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'current_fin_ytd'
GO
EXEC sp_addextendedproperty N'Comment', N'dim_date.calendar_date=dim_date.calendar_date', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'dim_date_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Date/time that this record was updated in the data warehouse', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'dss_update_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial day in the month. Normally the same as calendar day in the month, unless the financial period starts mid calendar month.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_day_in_month'
GO
EXEC sp_addextendedproperty N'Comment', N'The financial day in the week. Format DDD. Example: mon,tue,wed.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_day_in_week'
GO
EXEC sp_addextendedproperty N'Comment', N'Day number in the current financial week.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_day_in_week_no'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial day in the year. Number of days since the start of the financial year.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_day_in_year'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial month representation. Fromat YYYYMM. Examples: 200101, 200102.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_month'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial month representation. Fromat YYYY-MM. Examples: 2001-01, 2001-02.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_month_display'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial month. Format MON. Examples: jan, feb, mar.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_month_name'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial month number. Format MM. Examples: 1,2,3.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_month_no'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial period. Format (YYYY-MM) MON-YYYY. Example: (2001-02) Feb-2002.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_period'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial quarter representation. Format YYYYQQ. Example: 1989-Q1.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_quarter'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial quarter number (1-4).', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_quarter_no'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial week in the financial month. ', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_week_in_month'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial week in the financial year. Number of weeks since the start of the financial year', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_week_in_year'
GO
EXEC sp_addextendedproperty N'Comment', N'Financial year. Format YYYY.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'fin_year'
GO
EXEC sp_addextendedproperty N'Comment', N'The financial date. Same as calendar date.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'financial_date'
GO
EXEC sp_addextendedproperty N'Comment', N'Description of the holiday when a holiday.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'holiday_desc'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate that the day in question is a holiday. Y=holiday, N=normal.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'holiday_flag'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate days that constitute a full year counting back from the current day. Set as per current_cal_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'moving_cal_year'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate days that constitute a quarter counting back from the current financial day. Set as per current_fin_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'moving_fin_quarter'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate days that constitute a financial year counting back from the current financial day. Set as per current_fin_day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'moving_fin_year'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate a trading day. Y=trading, N=non trading.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'trading_day_flag'
GO
EXEC sp_addextendedproperty N'Comment', N'Number of trading days in this calendar month.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'trading_days_in_mth'
GO
EXEC sp_addextendedproperty N'Comment', N'Number of trading days in the month so far.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'trading_days_so_far'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate if a week day Y=week day N=week end.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'week_day_flag'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate a week end day. Y=week end, N=week day.', 'SCHEMA', N'dbo', 'TABLE', N'dim_date', 'COLUMN', N'week_end_flag'
GO
