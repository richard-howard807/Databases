CREATE TABLE [dbo].[FWHistoryUnstructured]
(
[SourceSystemID] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[hinumb] [numeric] (8, 0) NULL,
[hidate] [datetime] NULL,
[hidesc] [varchar] (240) COLLATE Latin1_General_CI_AS NULL,
[hiamnt] [numeric] (10, 2) NULL,
[hitype] [numeric] (8, 0) NULL
) ON [PRIMARY]
GO
