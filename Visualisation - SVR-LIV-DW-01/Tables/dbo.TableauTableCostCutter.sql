CREATE TABLE [dbo].[TableauTableCostCutter]
(
[CaseCode] [nvarchar] (33) COLLATE Latin1_General_CI_AS NULL,
[CaseDesc] [nvarchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[AlternativeRef] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[PrincipalDebt] [money] NULL,
[TerminationFees] [money] NULL,
[Total Debt] [money] NULL,
[SumsRecovered] [money] NULL,
[CurrentBalance] [money] NULL,
[ClaimNumber] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[Reporting Notes] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[WeightmansHandler] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[FileStatus] [varchar] (6) COLLATE Latin1_General_CI_AS NOT NULL,
[DateOpened] [datetime] NULL,
[DateClosed] [datetime] NULL,
[DaysOpened] [int] NULL,
[fileID] [bigint] NOT NULL,
[Defendant] [nvarchar] (80) COLLATE Latin1_General_CI_AS NULL,
[Postcode] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[Longitude] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Latitude] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Company Or Individual] [varchar] (10) COLLATE Latin1_General_CI_AS NOT NULL,
[RecoveredYTD] [money] NULL,
[CostcutterStatus] [nvarchar] (2003) COLLATE Latin1_General_CI_AS NULL,
[Insolvency proceedings] [nvarchar] (2001) COLLATE Latin1_General_CI_AS NULL,
[Court proceedings] [nvarchar] (1000) COLLATE Latin1_General_CI_AS NULL,
[ActionRequired] [nvarchar] (1000) COLLATE Latin1_General_CI_AS NULL,
[HearingDate] [datetime] NULL,
[Revenue] [numeric] (13, 2) NOT NULL,
[Costs Recovered from o/s] [money] NULL,
[Net Payment to Costcutter £] [numeric] (20, 4) NULL,
[Net % to Costcutter] [decimal] (10, 2) NULL,
[master_matter_number] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[Settlement Sum Agreed] [money] NULL,
[DCB] [numeric] (13, 2) NULL,
[fileNotes] [ntext] COLLATE Latin1_General_CI_AS NULL,
[fileExternalNotes] [ntext] COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
