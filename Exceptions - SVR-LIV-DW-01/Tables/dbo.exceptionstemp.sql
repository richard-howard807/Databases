CREATE TABLE [dbo].[exceptionstemp]
(
[DatasetID] [int] NOT NULL,
[DatasetName] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[MainFilter] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[MainFilterNarrative] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[FieldID] [int] NOT NULL,
[FieldName] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[Narrative] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[DescriptionSuffix] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[Comments] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[QueryString] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[Severity] [tinyint] NOT NULL,
[Critical] [bit] NOT NULL,
[DetailsUsed] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DetailsInvolved] [nvarchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
