CREATE TABLE [dbo].[case_life]
(
[client_group] [varchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[client_code] [char] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[matter_number] [char] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[client_matter] [varchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[date_open] [datetime] NOT NULL,
[date_closed] [datetime] NOT NULL,
[date_last_time_recorded] [datetime] NULL,
[work_type] [varchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[work_type_group] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[time_recorded_date] [datetime] NULL,
[last_bill_date] [datetime] NULL,
[time_days_elapsed] [int] NULL,
[num_bills] [int] NULL,
[minutes_recorded] [numeric] (38, 2) NOT NULL
) ON [PRIMARY]
GO
