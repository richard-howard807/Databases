CREATE TABLE [CIS].[MIUSLAONOutcomes]
(
[client] [char] (8) COLLATE Latin1_General_CI_AS NULL,
[matter] [char] (8) COLLATE Latin1_General_CI_AS NULL,
[Outcome] [char] (60) COLLATE Latin1_General_CI_AS NULL,
[Date Claim Claim Concluded] [datetime] NULL,
[Total Concluded] [int] NOT NULL,
[Trial Win] [int] NOT NULL,
[Discontinued] [int] NOT NULL,
[Struck out] [int] NOT NULL,
[Reduced Settlement Saving Less 50] [int] NOT NULL,
[Reduced Settlement Saving greater 50] [int] NOT NULL,
[Damages Paid] [decimal] (13, 2) NULL,
[Damage Reserve] [decimal] (13, 2) NULL,
[Savings] [decimal] (34, 16) NULL,
[Litigation] [varchar] (13) COLLATE Latin1_General_CI_AS NOT NULL,
[Year Period] [int] NULL,
[Period] [varchar] (11) COLLATE Latin1_General_CI_AS NULL,
[InsertedDate] [datetime] NULL
) ON [PRIMARY]
GO
