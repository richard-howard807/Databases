CREATE TABLE [dbo].[FWDebtUnstructured]
(
[SourceSystemID] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Detail] [char] (30) COLLATE Latin1_General_CI_AS NULL,
[FWText] [char] (1000) COLLATE Latin1_General_CI_AS NULL,
[FWDate] [datetime] NULL,
[FWValue] [numeric] (10, 2) NULL
) ON [PRIMARY]
GO
