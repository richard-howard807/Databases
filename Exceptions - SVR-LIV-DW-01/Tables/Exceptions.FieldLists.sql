CREATE TABLE [Exceptions].[FieldLists]
(
[Client] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[SequenceNumber] [smallint] NOT NULL,
[Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[QueryString] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DetailsUsed] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LookupField] [bit] NULL,
[JoinsUsed] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ExceptionField] [bit] NOT NULL,
[Filter] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Comments] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [Exceptions].[TRG_DuplicateFieldName]
   ON  [Exceptions].[FieldLists]
   AFTER INSERT, UPDATE
AS
IF EXISTS(SELECT 1 FROM inserted INNER JOIN Reporting_DW.Exceptions.FieldLists ON inserted.Client = FieldLists.Client AND inserted.Name = FieldLists.Name HAVING COUNT(1) > 1)
BEGIN
	RAISERROR('A field with this name already exists for this client.', 16, 10)
	ROLLBACK TRANSACTION
	RETURN
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [Exceptions].[TRG_QueryOrFilterExists]
ON [Exceptions].[FieldLists]
AFTER INSERT, UPDATE
AS
IF EXISTS(SELECT 1 FROM inserted WHERE QueryString IS NULL AND Filter IS NULL)
BEGIN
	RAISERROR('QueryString and Filter fields cannot both be NULL.', 16, 10)
	ROLLBACK TRANSACTION
	RETURN
END
GO
ALTER TABLE [Exceptions].[FieldLists] ADD CONSTRAINT [PK_ExceptionFields] PRIMARY KEY CLUSTERED  ([Client], [SequenceNumber]) ON [PRIMARY]
GO
