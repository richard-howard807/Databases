CREATE TABLE [Config].[Audit]
(
[AuditID] [int] NOT NULL IDENTITY(1, 1),
[AuditDate] [datetime] NULL,
[AuditPackage] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[AuditTask] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[AuditTable] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[AuditStartTime] [datetime] NULL,
[AuditEndTime] [datetime] NULL,
[AuditRunTime] [float] NULL,
[AuditRowInserted] [int] NULL,
[AuditRowChanged] [int] NULL,
[AuditRowNew] [int] NULL,
[AuditRowExpired] [int] NULL,
[AuditTotalRowcount] [int] NULL,
[AuditError] [int] NULL,
[AuditCreatedDate] [datetime] NULL,
[AuditCreatedBy] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[AuditSource] [varchar] (400) COLLATE Latin1_General_CI_AS NULL,
[ParentAuditID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [Config].[Audit] ADD CONSTRAINT [PK_Audit] PRIMARY KEY CLUSTERED  ([AuditID]) ON [PRIMARY]
GO
