CREATE TABLE [dbo].[EmilyCurium110522]
(
[Client Code] [nvarchar] (12) COLLATE Latin1_General_BIN NULL,
[Matter Number] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[Fee Earner] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Fee Earner Department] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Fee Earner Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Job Title] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Start Date] [datetime] NULL,
[Left Date] [datetime] NULL,
[Chargeable Hours] [numeric] (38, 6) NULL,
[Date Recorded] [datetime] NULL,
[Hourly Charge Rate] [numeric] (10, 2) NULL
) ON [PRIMARY]
GO
