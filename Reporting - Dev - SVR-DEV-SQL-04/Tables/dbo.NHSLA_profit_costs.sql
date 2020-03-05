CREATE TABLE [dbo].[NHSLA_profit_costs]
(
[Client Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Description] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[Handler] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Date Opened] [datetime] NULL,
[Date Closed] [datetime] NULL,
[Fixed Fee] [char] (60) COLLATE Latin1_General_BIN NULL,
[Year Profit Costs Billed] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[Total Profit Costs Billed Amount] [numeric] (38, 5) NULL,
[Fed Code] [nvarchar] (60) COLLATE Latin1_General_BIN NULL,
[Bill Handler] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Level] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[PQEYears] [varchar] (17) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
