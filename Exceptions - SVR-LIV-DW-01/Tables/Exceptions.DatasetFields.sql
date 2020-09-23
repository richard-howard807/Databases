CREATE TABLE [Exceptions].[DatasetFields]
(
[DatasetID] [int] NOT NULL,
[FieldID] [int] NOT NULL,
[SequenceNumber] [int] NOT NULL,
[Severity] [tinyint] NOT NULL CONSTRAINT [DF_DatasetFields_Severity] DEFAULT ((5)),
[Critical] [bit] NOT NULL CONSTRAINT [DF_DatasetFields_Critical] DEFAULT ((0)),
[CheckExists] [bit] NOT NULL CONSTRAINT [DF_DatasetFields_CheckExists] DEFAULT ((0)),
[Alias] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Filter] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Comments] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Exceptions].[DatasetFields] ADD CONSTRAINT [PK_DatasetFields] PRIMARY KEY CLUSTERED  ([DatasetID], [SequenceNumber]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_DatasetFields_DatasetID] ON [Exceptions].[DatasetFields] ([DatasetID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_DatasetFields_RuleID] ON [Exceptions].[DatasetFields] ([DatasetID], [FieldID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_DatasetFields_FieldID] ON [Exceptions].[DatasetFields] ([FieldID]) ON [PRIMARY]
GO
ALTER TABLE [Exceptions].[DatasetFields] ADD CONSTRAINT [FK_DatasetFields_FieldID] FOREIGN KEY ([FieldID]) REFERENCES [Exceptions].[Fields] ([FieldID])
GO
