CREATE TABLE [Exceptions].[Joins]
(
[JoinName] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[JoinCode] [varchar] (max) COLLATE Latin1_General_BIN NOT NULL,
[Comments] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [Exceptions].[Joins] ADD CONSTRAINT [PK_Joins_1] PRIMARY KEY CLUSTERED  ([JoinName]) ON [PRIMARY]
GO
