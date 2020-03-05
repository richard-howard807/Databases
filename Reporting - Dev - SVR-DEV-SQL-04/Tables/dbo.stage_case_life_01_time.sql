CREATE TABLE [dbo].[stage_case_life_01_time]
(
[client_group] [varchar] (40) COLLATE Latin1_General_CI_AS NOT NULL,
[client_code] [char] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[matter_number] [char] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[time_days_elapsed] [int] NOT NULL,
[minutes_recorded] [numeric] (38, 2) NOT NULL
) ON [PRIMARY]
GO
