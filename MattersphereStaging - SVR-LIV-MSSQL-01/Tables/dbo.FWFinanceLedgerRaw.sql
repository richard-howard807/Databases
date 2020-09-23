CREATE TABLE [dbo].[FWFinanceLedgerRaw]
(
[Item] [numeric] (9, 0) NULL,
[SourceSystemID] [nchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Date] [datetime] NULL,
[Description 1] [char] (30) COLLATE Latin1_General_CI_AS NULL,
[Description 2] [char] (30) COLLATE Latin1_General_CI_AS NULL,
[Type] [char] (4) COLLATE Latin1_General_CI_AS NULL,
[Office] [numeric] (12, 2) NULL,
[Client] [numeric] (12, 2) NULL,
[Bill] [numeric] (7, 0) NULL
) ON [PRIMARY]
GO
