CREATE TABLE [dbo].[Finance_Master_Payment_060921]
(
[UID] [float] NULL,
[Claim Ledger Date Polygonal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Folio Polygonal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Payee Polygonal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Currency] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Total Amount booked Polygonal] [float] NULL,
[Polygonal Pay Code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Polygonal Policy Reference] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Polygonal Claim Reference] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Claimant Forename] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Claimant Surname] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Claimant Date Of Birth_dd/mm/yyyy] [datetime] NULL,
[Address 1] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Address 2 - City] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Address 3 - State/County] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Address 4 - Postcode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Address 5 - Country] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Payee Date Of Birth_dd/mm/yyyy] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[BACS Payee Email Address] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Finance Notes/Comments] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Claim Handler] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Handler Comment] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Bank Sort Code Polygonal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Bank Account number Polygonal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Payment Reference Polygonal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Eligible] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Bordereau No (BDX Prefix)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Claim Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Claim Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Payment Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Exposure] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Northern Irish Claim?] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Payment Method] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Urgent] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Gross Amount] [float] NULL,
[FSCS Percentage Protected at 100%] [float] NULL,
[FSCS Payment at 100%] [float] NULL,
[FSCS Percentage Protected at 90%] [float] NULL,
[FSCS Payment at 90%] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Less Dividend] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Current Dividend %] [float] NULL,
[FSCS Net Amount] [float] NULL,
[FSCS Paid Date] [datetime] NULL,
[FSCS Paid Amount] [float] NULL,
[EY Payment Date] [datetime] NULL,
[EY Payment Amount] [float] NULL,
[1st DIVIDEND Payment Date] [datetime] NULL,
[1st DIVIDEND Payment Amount] [float] NULL,
[2nd DIVIDEND Payment Date] [datetime] NULL,
[2nd DIVIDEND Payment Amount] [float] NULL,
[Total Paid (Dividends)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Balance Due] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Outstanding / Paid?] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Sanction ID] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Previously Paid/Payee Contact Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Verified by] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date] [datetime] NULL,
[Date Added to master] [datetime] NULL,
[Unique Payment Pack ID (FINANCE)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Unique Payment Pack ID (CLAIMS)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MES POLICY NUMBER] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MES POLICY HOLDER NAME] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MES APPROVED ] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FSCS Bordereau Number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Uploaded to FSCS Portal] [datetime] NULL,
[F67] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Paid on Polygonal] [datetime] NULL,
[Polygonal Cash Batch Number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Batched on Polygonal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Approved on Polygonal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CSV File] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Notes] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO