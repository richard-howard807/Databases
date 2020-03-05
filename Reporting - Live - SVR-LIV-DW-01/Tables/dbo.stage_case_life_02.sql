CREATE TABLE [dbo].[stage_case_life_02]
(
[client_group] [varchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[client_code] [char] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[matter_number] [char] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[date_open] [datetime] NOT NULL,
[date_closed] [datetime] NOT NULL,
[date_last_time_recorded] [datetime] NULL,
[date_last_bill] [datetime] NULL,
[work_type] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[work_type_group] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[time_recorded_date] [datetime] NULL,
[time_days_elapsed] [int] NULL,
[num_bills] [int] NULL
) ON [PRIMARY]
GO
