CREATE TABLE [dbo].[EnsureHistoryData]
(
[master_client_code] [nvarchar] (12) COLLATE Latin1_General_BIN NULL,
[master_matter_number] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[MatterDescription] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[Date Opened] [datetime] NULL,
[Date Closed] [datetime] NULL,
[Our Reference] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Claim Number] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insured] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[TCD Handler] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Weightmans Handler] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Reason for Issue] [varchar] (1) COLLATE Latin1_General_CI_AS NOT NULL,
[Litigation Avoidable] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Damages Claimed] [numeric] (13, 2) NULL,
[Damages Agreed] [numeric] (13, 2) NULL,
[Claimed Vs Settled] [numeric] (14, 2) NULL,
[Time to Settled(Days)] [int] NULL,
[Total Weightmans Profit Costs] [numeric] (13, 2) NULL,
[Total Disbursements] [numeric] (14, 2) NULL,
[Narrative] [varchar] (1) COLLATE Latin1_General_CI_AS NOT NULL,
[NewInstruction] [int] NOT NULL,
[ClosedInstruction] [int] NOT NULL,
[ProceedingsIssued] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date ProceedingsIssued] [datetime] NULL,
[Date Claim Concluded] [datetime] NULL,
[Year Period] [int] NULL,
[Period] [varchar] (11) COLLATE Latin1_General_CI_AS NULL,
[NewLitigated] [int] NOT NULL,
[bill_cal_month_no] [int] NULL,
[bill_cal_year] [int] NULL,
[bill_cal_month_name] [nvarchar] (7) COLLATE Latin1_General_CI_AS NULL,
[Name of Claimant] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[Date Instructions Received] [datetime] NULL,
[Instruction Type] [varchar] (40) COLLATE Latin1_General_CI_AS NULL,
[Date Proceedings Served] [datetime] NULL,
[Present Position] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Date Claimants Costs Settled] [datetime] NULL,
[Claimants Costs Claimed] [numeric] (13, 2) NULL,
[Claimants Costs Paid] [numeric] (13, 2) NULL,
[Claimants Costs Savings] [numeric] (14, 2) NULL
) ON [PRIMARY]
GO
