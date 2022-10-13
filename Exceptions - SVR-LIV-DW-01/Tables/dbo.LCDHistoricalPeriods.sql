CREATE TABLE [dbo].[LCDHistoricalPeriods]
(
[StartDate] [datetime] NULL,
[EndDate] [datetime] NULL,
[ClosedPeriod] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Reported Volume] [float] NULL,
[Reported Value] [float] NULL
) ON [PRIMARY]
GO
