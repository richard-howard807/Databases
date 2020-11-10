CREATE TABLE [dbo].[IA_WorkingLists]
(
[Company Name] [nvarchar] (150) COLLATE Latin1_General_BIN NULL,
[Lead Partner] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Activity Originator] [nvarchar] (101) COLLATE Latin1_General_BIN NULL,
[Working List Title] [nvarchar] (150) COLLATE Latin1_General_BIN NULL,
[Days Since Last Contacted] [int] NULL,
[Last Contacted Date] [datetime] NULL,
[Activity Description] [nvarchar] (60) COLLATE Latin1_General_BIN NULL,
[activity_date] [datetime] NULL,
[summary] [nvarchar] (254) COLLATE Latin1_General_BIN NULL,
[PossibleCompanies] [int] NULL
) ON [PRIMARY]
GO
