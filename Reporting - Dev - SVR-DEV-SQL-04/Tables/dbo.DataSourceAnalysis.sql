CREATE TABLE [dbo].[DataSourceAnalysis]
(
[TimeStart] [datetime] NOT NULL,
[ReportName] [nvarchar] (425) COLLATE Latin1_General_CI_AS_KS_WS NOT NULL,
[DataSource] [nvarchar] (425) COLLATE Latin1_General_CI_AS_KS_WS NOT NULL,
[TimeDataRetrieval] [numeric] (19, 7) NULL
) ON [PRIMARY]
GO
