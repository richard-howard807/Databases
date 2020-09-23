CREATE TABLE [dbo].[AuditSchemaChanges]
(
[DatabaseLogID] [int] NOT NULL IDENTITY(1, 1),
[PostTime] [datetime] NOT NULL,
[DatabaseUser] [sys].[sysname] NOT NULL,
[Event] [sys].[sysname] NOT NULL,
[Schema] [sys].[sysname] NULL,
[Object] [sys].[sysname] NULL,
[TSQL] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[XmlEvent] [xml] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[AuditSchemaChanges] ADD CONSTRAINT [PK_DatabaseLog_DatabaseLogID] PRIMARY KEY CLUSTERED  ([DatabaseLogID]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'Audit table tracking all DDL changes made to the database. Data is captured by the database trigger ddlDatabaseTriggerLog.', 'SCHEMA', N'dbo', 'TABLE', N'AuditSchemaChanges', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Primary key for DatabaseLog records.', 'SCHEMA', N'dbo', 'TABLE', N'AuditSchemaChanges', 'COLUMN', N'DatabaseLogID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The user who implemented the DDL change.', 'SCHEMA', N'dbo', 'TABLE', N'AuditSchemaChanges', 'COLUMN', N'DatabaseUser'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The type of DDL statement that was executed.', 'SCHEMA', N'dbo', 'TABLE', N'AuditSchemaChanges', 'COLUMN', N'Event'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The object that was changed by the DDL statment.', 'SCHEMA', N'dbo', 'TABLE', N'AuditSchemaChanges', 'COLUMN', N'Object'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The date and time the DDL change occurred.', 'SCHEMA', N'dbo', 'TABLE', N'AuditSchemaChanges', 'COLUMN', N'PostTime'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The schema to which the changed object belongs.', 'SCHEMA', N'dbo', 'TABLE', N'AuditSchemaChanges', 'COLUMN', N'Schema'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The exact Transact-SQL statement that was executed.', 'SCHEMA', N'dbo', 'TABLE', N'AuditSchemaChanges', 'COLUMN', N'TSQL'
GO
EXEC sp_addextendedproperty N'MS_Description', N'The raw XML data generated by database trigger.', 'SCHEMA', N'dbo', 'TABLE', N'AuditSchemaChanges', 'COLUMN', N'XmlEvent'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Primary key (nonclustered) constraint', 'SCHEMA', N'dbo', 'TABLE', N'AuditSchemaChanges', 'CONSTRAINT', N'PK_DatabaseLog_DatabaseLogID'
GO
