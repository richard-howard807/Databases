CREATE TABLE [converge].[SevernTrentCashbook]
(
[Category] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL,
[case_id] [int] NOT NULL,
[transaction_type_code] [nvarchar] (16) COLLATE Latin1_General_CI_AI NULL,
[ChequeNumber] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL,
[InstructionID] [nvarchar] (8) COLLATE Latin1_General_CI_AI NULL,
[Effect Description Additional] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[InvoiceNumber] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[DateOfLoss] [datetime] NULL,
[Year OF Account] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[PayableToName] [char] (60) COLLATE Latin1_General_BIN NULL,
[PaymentNet] [decimal] (17, 2) NULL,
[PaymentVAT] [decimal] (17, 2) NULL,
[PaymentGross] [decimal] (17, 2) NULL,
[CreditAmount] [decimal] (18, 2) NULL,
[DebitAmount] [decimal] (18, 2) NULL,
[Payment Notes] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Policy Type] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Business Unit] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Working Deductible] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[PostingDate] [datetime] NULL,
[NewTotalPaid_Total] [decimal] (38, 2) NULL,
[NewTotalRecovered_Total] [decimal] (38, 2) NULL,
[Peril Description] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[Wholesale OPS Burst Mains] [char] (60) COLLATE Latin1_General_BIN NOT NULL,
[District] [varchar] (60) COLLATE Latin1_General_BIN NOT NULL,
[gl_date] [datetime] NULL,
[transaction_date] [datetime] NULL,
[InsertDate] [date] NULL
) ON [PRIMARY]
GO
