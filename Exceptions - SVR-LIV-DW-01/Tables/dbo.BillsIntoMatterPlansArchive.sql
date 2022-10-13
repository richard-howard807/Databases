CREATE TABLE [dbo].[BillsIntoMatterPlansArchive]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[fileID] [bigint] NOT NULL,
[case_id] [int] NULL,
[Client Code] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[Matter Number] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[3e References] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Matter Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[Date Opened] [datetime] NULL,
[Fee Earner] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[Fee Earner Code] [nvarchar] (36) COLLATE Latin1_General_CI_AS NULL,
[Bill Number] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[Bill Date] [datetime] NULL,
[Bill Amount] [decimal] (16, 2) NULL,
[Invoice Link] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[Document Name] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[SystemsDestination] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Is Credit Note] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Does Doc Exist] [int] NOT NULL,
[InsertDate] [datetime] NOT NULL CONSTRAINT [DF__BillsInto__Inser__75C27486] DEFAULT (getdate()),
[ExcelDoc] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Fee Earner Email] [nvarchar] (1000) COLLATE Latin1_General_CI_AS NULL,
[OriginatorName] [nvarchar] (1000) COLLATE Latin1_General_CI_AS NULL,
[OriginatorEmail] [nvarchar] (1000) COLLATE Latin1_General_CI_AS NULL,
[ProformaComments] [nvarchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[BillingInstructions] [nvarchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[EmailType] [nvarchar] (20) COLLATE Latin1_General_CI_AS NULL,
[OriginatorEmailsNeeded] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BillsIntoMatterPlansArchive] ADD CONSTRAINT [PK_BilltoMatterArchID] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
