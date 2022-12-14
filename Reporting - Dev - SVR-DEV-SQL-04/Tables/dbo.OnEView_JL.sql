CREATE TABLE [dbo].[OnEView_JL]
(
[Weightmans Reference] [varchar] (17) COLLATE Latin1_General_BIN NULL,
[Client Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Description] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[Work Type Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Work Type] [char] (40) COLLATE Latin1_General_BIN NULL,
[Property Contact] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenant Break Option] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[lease_report_leasehold_25k_100k] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[rolling_fixed_date] [char] (60) COLLATE Latin1_General_BIN NULL,
[date_fixed_2] [datetime] NULL,
[Term End Date] [datetime] NULL,
[next_review_date] [datetime] NULL,
[BE Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BE Number] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date of Lease] [datetime] NULL,
[Demised Premises] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Team] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FIXEDcountofdays] [int] NULL,
[NextReviewcountofdays] [int] NULL,
[TermEndCountofdays] [int] NULL,
[case_type_rmg] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[instruction_type] [char] (60) COLLATE Latin1_General_BIN NULL,
[postcode] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[completion_date] [datetime] NULL,
[case_classification] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[present_position] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Open/Closed Case Status] [varchar] (6) COLLATE Latin1_General_CI_AS NOT NULL,
[date_opened_case_management] [datetime] NULL,
[No. Days Opened] [int] NULL,
[FixedDate] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[RentReviewDate] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[TermEndDate] [varchar] (2) COLLATE Latin1_General_CI_AS NULL,
[RMG Case Type] [varchar] (23) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
