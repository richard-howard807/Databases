CREATE TABLE [dbo].[udInvoiceLinkBackup220222]
(
[rowguid] [uniqueidentifier] NOT NULL,
[dteBillDate] [datetime] NULL,
[txtBillNumber] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[txtDocumentLink] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[fileID] [bigint] NOT NULL,
[RecordID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
