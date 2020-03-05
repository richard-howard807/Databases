CREATE TABLE [dbo].[PoliceExtract]
(
[Client Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Client Name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Matter Description] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[Matter Owner] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Date Case Opened] [datetime] NULL,
[Date Case Closed] [datetime] NULL,
[Work Type] [char] (40) COLLATE Latin1_General_BIN NULL,
[Borough] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Source of Instruction] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[surrey_police_stations] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[fee_earner_code] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[GroupWorkTypeLookup] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Total Billed to date] [numeric] (16, 2) NULL,
[Profit Costs to date] [numeric] (16, 2) NULL,
[Total Billed] [numeric] (38, 2) NULL,
[Profit Costs] [numeric] (38, 2) NULL
) ON [PRIMARY]
GO
