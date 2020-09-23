CREATE TABLE [Exceptions].[FieldTypes]
(
[FieldTypeID] [tinyint] NOT NULL,
[FieldTypeName] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [Exceptions].[FieldTypes] ADD CONSTRAINT [PK__FieldTyp__74418A823CA283FF] PRIMARY KEY CLUSTERED  ([FieldTypeID]) ON [PRIMARY]
GO
