CREATE TABLE [dbo].[CoopMIUDataLookup]
(
[Client] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[CIS Reference] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date Closed in FED] [datetime] NULL,
[Date Opened in FED] [datetime] NULL,
[Insured Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
