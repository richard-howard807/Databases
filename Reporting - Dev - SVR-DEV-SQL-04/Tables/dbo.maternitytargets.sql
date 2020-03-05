CREATE TABLE [dbo].[maternitytargets]
(
[calendar_date] [datetime] NULL,
[division] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[department] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[income] [numeric] (38, 2) NULL,
[target] [numeric] (38, 2) NULL,
[distance_from_target] [numeric] (38, 2) NULL,
[maternity_count] [int] NULL,
[people_in_dept] [int] NULL
) ON [PRIMARY]
GO
