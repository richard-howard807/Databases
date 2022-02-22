CREATE TABLE [dbo].[NHSRevenueCasesHrsWorked]
(
[Mattersphere Ref] [nvarchar] (33) COLLATE Latin1_General_BIN NULL,
[Matter Owner] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Matter Type] [char] (40) COLLATE Latin1_General_BIN NULL,
[Trust] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Office] [char] (40) COLLATE Latin1_General_BIN NULL,
[Date Opened] [datetime] NULL,
[Date Closed] [datetime] NULL,
[Damages Reserve] [numeric] (13, 2) NULL,
[Outcome] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Present Position] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Referral Reason] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Scheme] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Instruction Type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[NHS Matter Type] [varchar] (12) COLLATE Latin1_General_CI_AS NULL,
[NHSR Tranche] [varchar] (19) COLLATE Latin1_General_CI_AS NULL,
[Transaction Date] [datetime] NULL,
[Hrs Recorded] [numeric] (38, 6) NULL
) ON [PRIMARY]
GO
