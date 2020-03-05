CREATE TABLE [dbo].[Unpresentedv3]
(
[EngageRef] [varchar] (17) COLLATE Latin1_General_BIN NULL,
[DateIssued] [datetime] NULL,
[PaymentType] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Details] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL,
[Net] [decimal] (13, 2) NULL,
[VAT] [decimal] (13, 2) NULL,
[TotalPayment] [decimal] (13, 2) NULL,
[recon_status] [nvarchar] (16) COLLATE Latin1_General_CI_AI NULL,
[reference_number] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL,
[legacy_client_matter_number] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL
) ON [PRIMARY]
GO
