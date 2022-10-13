CREATE TABLE [dbo].[financialyearcomparisonES4]
(
[Sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[Client Group] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[Client Name] [char] (80) COLLATE Latin1_General_BIN NULL,
[Client Partner] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Client Code] [varchar] (8) COLLATE Latin1_General_BIN NULL,
[Generator Status] [varchar] (11) COLLATE Latin1_General_CI_AS NULL,
[2016/2017 Profit Costs] [numeric] (38, 2) NULL,
[2017/2018 Profit Costs] [numeric] (38, 2) NULL,
[Client Number] [varchar] (8) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
