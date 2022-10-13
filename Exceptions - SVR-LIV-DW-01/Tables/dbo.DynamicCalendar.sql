CREATE TABLE [dbo].[DynamicCalendar]
(
[Dates] [smalldatetime] NULL,
[Day of Year] [int] NULL,
[Dayname] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[Day of Week] [int] NULL,
[Day of Month] [int] NULL,
[Week] [int] NULL,
[MonthNumber] [int] NULL,
[MonthName] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[Quarter_cal] [int] NULL,
[Year_cal] [int] NULL,
[Quarter_fin_legal] [varchar] (1) COLLATE Latin1_General_CI_AS NOT NULL,
[Quarter_fin_HMRC] [varchar] (1) COLLATE Latin1_General_CI_AS NOT NULL,
[Year_fin_legal] [int] NULL,
[Year_fin_HMRC] [int] NULL,
[YearPeriod_fin] [varchar] (32) COLLATE Latin1_General_CI_AS NULL,
[FirstDayinMonth] [smalldatetime] NULL,
[LastDayinMonth] [smalldatetime] NULL,
[LastDayPrevMonth] [smalldatetime] NULL,
[WorkingDay] [int] NOT NULL
) ON [PRIMARY]
GO
