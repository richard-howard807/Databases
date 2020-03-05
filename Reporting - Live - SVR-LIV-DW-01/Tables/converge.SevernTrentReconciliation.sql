CREATE TABLE [converge].[SevernTrentReconciliation]
(
[EngageRef] [varchar] (17) COLLATE Latin1_General_BIN NULL,
[DateIssued] [datetime] NULL,
[PaymentType] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Details] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL,
[Net] [decimal] (13, 2) NOT NULL,
[VAT] [decimal] (13, 2) NOT NULL,
[TotalPayment] [decimal] (15, 2) NULL,
[amount] [decimal] (16, 2) NOT NULL,
[legacy_sequence_number] [varchar] (30) COLLATE Latin1_General_CI_AI NULL,
[case_text] [char] (60) COLLATE Latin1_General_BIN NULL,
[matter] [char] (8) COLLATE Latin1_General_BIN NULL,
[sequence_number] [varchar] (30) COLLATE Latin1_General_CI_AI NULL
) ON [PRIMARY]
GO
