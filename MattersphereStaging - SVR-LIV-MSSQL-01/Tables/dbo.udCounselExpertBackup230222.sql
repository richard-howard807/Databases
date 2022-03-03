CREATE TABLE [dbo].[udCounselExpertBackup230222]
(
[fileID] [bigint] NOT NULL,
[row guid] [uniqueidentifier] NOT NULL,
[txtSupName] [nvarchar] (60) COLLATE Latin1_General_CI_AS NULL,
[txtInvNumber] [nvarchar] (60) COLLATE Latin1_General_CI_AS NULL,
[dteInvoiceDate] [datetime] NULL,
[curInvAmount] [money] NULL,
[txtCounExpert] [nvarchar] (60) COLLATE Latin1_General_CI_AS NULL,
[txtDocumentLink] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[RecordID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
