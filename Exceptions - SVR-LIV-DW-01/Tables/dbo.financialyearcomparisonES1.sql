CREATE TABLE [dbo].[financialyearcomparisonES1]
(
[Master Client Code] [nvarchar] (12) COLLATE Latin1_General_BIN NULL,
[Client Name (grouped)] [varchar] (80) COLLATE Latin1_General_BIN NULL,
[Client Partner (grouped)] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Segment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[Sub-sector] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Generator Status] [varchar] (11) COLLATE Latin1_General_CI_AS NULL,
[2016/2017 Profit Costs] [numeric] (38, 2) NULL,
[2017/2018 Profit Costs] [numeric] (38, 2) NULL
) ON [PRIMARY]
GO
