CREATE TABLE [Exceptions].[Datasets]
(
[DatasetID] [int] NOT NULL IDENTITY(1, 1),
[DatasetName] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[MainFilter] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[MainDetailsUsed] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MainJoinsUsed] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LookupField] [bit] NOT NULL CONSTRAINT [DF_Datasets_LookupField] DEFAULT ((0)),
[IncludeInFirmWide] [bit] NOT NULL CONSTRAINT [DF_Datasets_IncludeInFirmWide] DEFAULT ((0)),
[Comments] [varchar] (max) COLLATE Latin1_General_BIN SPARSE NULL,
[DescriptionSuffix] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Test] [bit] NOT NULL CONSTRAINT [DF_Datasets_Test] DEFAULT ((1)),
[LastUpdated] [datetime] NULL,
[QueryHint] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_Datasets_QueryHint] DEFAULT (''),
[CacheExceptions] [bit] NOT NULL CONSTRAINT [DF_Datasets_CacheExceptions] DEFAULT ((0)),
[CacheValues] [bit] NOT NULL CONSTRAINT [DF_Datasets_CacheValues] DEFAULT ((0)),
[ReportPath] [varchar] (512) COLLATE Latin1_General_BIN NULL,
[MainFilterNarrative] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[StartTime] [datetime] NULL,
[EndTime] [datetime] NULL,
[Duration] AS (datediff(minute,[StartTime],[EndTime])),
[Priority] [smallint] NULL,
[BatchNumber] [smallint] NULL,
[Mattersphere] [bit] NOT NULL CONSTRAINT [DF_Datasets_Mattersphere] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [Exceptions].[Datasets] ADD CONSTRAINT [PK_Datasets] PRIMARY KEY CLUSTERED  ([DatasetID]) ON [PRIMARY]
GO
