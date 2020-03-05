CREATE TABLE [dbo].[Bills_Tableau]
(
[Weightmans Reference] [varchar] (17) COLLATE Latin1_General_BIN NULL,
[Client Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Mattersphere Client Code] [nvarchar] (12) COLLATE Latin1_General_BIN NULL,
[Mattersphere Matter Number] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[Matter Description] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[Date Case Opened] [datetime] NULL,
[Date Case Closed] [datetime] NULL,
[Bill Number] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[Bill Total] [numeric] (13, 2) NULL,
[Profit Costs] [numeric] (13, 2) NULL,
[Bill Amount Paid] [numeric] (13, 2) NULL,
[Left to Pay] [numeric] (14, 2) NULL,
[Bill Date] [datetime] NULL,
[Bill Type] [char] (9) COLLATE Latin1_General_BIN NOT NULL,
[Month Billed] [int] NULL,
[Month Name Billed] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[Year Billed] [int] NULL,
[Quarter Billed] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[Abatement Total] [int] NULL,
[Level] [varchar] (10) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
