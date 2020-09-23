CREATE TABLE [Exceptions].[Fields]
(
[FieldID] [int] NOT NULL IDENTITY(1, 1),
[FieldName] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[QueryString] [nvarchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[DetailsUsed] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[JoinsUsed] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LookupField] [bit] NOT NULL CONSTRAINT [DF_Fields_LookupField] DEFAULT ((0)),
[ExceptionField] AS (case  when [FieldTypeID]=(0) then (1) else (0) end),
[LinkedFieldID] [int] NULL,
[Comments] [nvarchar] (max) COLLATE Latin1_General_BIN SPARSE NULL,
[Narrative] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[FieldTypeID] [tinyint] NOT NULL,
[MattersphereField] [bit] NOT NULL CONSTRAINT [DF_Fields_MattersphereField] DEFAULT ((0)),
[Owner] [nvarchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Exceptions].[Fields] ADD CONSTRAINT [PK_Fields] PRIMARY KEY CLUSTERED  ([FieldID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_NCL_Fields_20151126] ON [Exceptions].[Fields] ([ExceptionField]) INCLUDE ([FieldID]) ON [PRIMARY]
GO
ALTER TABLE [Exceptions].[Fields] ADD CONSTRAINT [FK_FieldTypeID] FOREIGN KEY ([FieldTypeID]) REFERENCES [Exceptions].[FieldTypes] ([FieldTypeID])
GO
