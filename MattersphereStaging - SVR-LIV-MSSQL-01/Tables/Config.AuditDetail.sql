CREATE TABLE [Config].[AuditDetail]
(
[AuditDetailID] [int] NOT NULL IDENTITY(1, 1),
[AuditID] [int] NOT NULL,
[AuditDetailDate] [datetime] NULL,
[AuditErrorCode] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[AuditErrorDescription] [varchar] (1000) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [Config].[AuditDetail] ADD CONSTRAINT [PK_AuditDetail] PRIMARY KEY CLUSTERED  ([AuditDetailID]) ON [PRIMARY]
GO
