CREATE TABLE [dbo].[ClaimsMSChecklistData]
(
[client] [char] (8) COLLATE Latin1_General_BIN NULL,
[matter number] [char] (8) COLLATE Latin1_General_BIN NULL,
[matter description] [char] (40) COLLATE Latin1_General_BIN NOT NULL,
[matter owner] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[department] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Client Name] [char] (80) COLLATE Latin1_General_BIN NULL,
[date opened] [datetime] NULL,
[date closed] [datetime] NULL,
[work type] [char] (40) COLLATE Latin1_General_BIN NULL,
[fee arrangement] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[referral reason] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[present position] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[profit costs billed] [numeric] (13, 2) NULL,
[total billed] [numeric] (13, 2) NULL,
[date of last bill] [datetime] NULL,
[date of last time record] [datetime] NULL,
[wip] [numeric] (13, 2) NULL,
[unbilled disbursements] [numeric] (13, 2) NULL,
[Unpaid bill balance] [numeric] (13, 2) NULL,
[client balance] [numeric] (13, 2) NULL,
[MI exception number] [int] NOT NULL,
[InsertDate] [date] NULL,
[CurrentWeek] [int] NULL,
[CurrentYear] [int] NULL,
[work type code] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[WorktypeException] [int] NULL,
[RedLogic] [int] NULL,
[dim_fed_hierarchy_history_key] [int] NULL,
[Leaver] [int] NULL
) ON [PRIMARY]
GO
