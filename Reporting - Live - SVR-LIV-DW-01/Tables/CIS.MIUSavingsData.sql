CREATE TABLE [CIS].[MIUSavingsData]
(
[case_id] [int] NOT NULL,
[CIS Ref] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Insured Name] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Provider Ref] [varchar] (8000) COLLATE Latin1_General_CI_AS NULL,
[Nbr Of Claimants] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[RTA Date] [date] NULL,
[Date Received] [date] NULL,
[Date Closed/  Declared Dormant] [datetime] NULL,
[Status] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Outcome] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[MI Reserve] [money] NULL,
[Paid Prior To Instruction] [money] NULL,
[Settlement Value] [decimal] (19, 4) NULL,
[Fees] [decimal] (19, 4) NULL,
[Net savings] [decimal] (21, 4) NULL,
[Potential Recovery] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Blank1] [varchar] (1) COLLATE Latin1_General_CI_AS NOT NULL,
[Blank2] [varchar] (1) COLLATE Latin1_General_CI_AS NOT NULL,
[Date 50% Dormant] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Savings from 50% Dormant] [numeric] (24, 6) NULL,
[Currently still 50% stage] [int] NOT NULL,
[Blank3] [varchar] (1) COLLATE Latin1_General_CI_AS NOT NULL,
[Period Closed/Dormant] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Savings from Closed Dormant] [numeric] (25, 6) NULL,
[Inserted Date] [date] NULL
) ON [PRIMARY]
GO
