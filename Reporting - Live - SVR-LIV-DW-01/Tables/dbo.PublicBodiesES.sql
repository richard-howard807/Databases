CREATE TABLE [dbo].[PublicBodiesES]
(
[Client Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Description] [varchar] (8000) COLLATE Latin1_General_BIN NULL,
[Matter Owner] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Matter Owner Department] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Matter Owner Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Time Keeper Name] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Time Keeper Department] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Time Keeper Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Work Type] [char] (40) COLLATE Latin1_General_BIN NULL,
[Client Name] [char] (80) COLLATE Latin1_General_BIN NULL,
[Client Group Name] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[Insured Client Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Profit Costs] [numeric] (38, 2) NULL
) ON [PRIMARY]
GO
