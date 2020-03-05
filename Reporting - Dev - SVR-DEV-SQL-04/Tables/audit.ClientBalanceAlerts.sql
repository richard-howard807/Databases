CREATE TABLE [audit].[ClientBalanceAlerts]
(
[FileID] [bigint] NOT NULL,
[MS Client] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[MS Matter] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[FED Client] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[FED Matter] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[AlertType] [int] NULL,
[MSOrFED] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[usrinits] [nvarchar] (30) COLLATE Latin1_General_CI_AS NOT NULL,
[usrid] [int] NOT NULL,
[DateAlertSent] [date] NULL,
[ID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [audit].[ClientBalanceAlerts] ADD CONSTRAINT [PK_ClientBalanceAlert_ID] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
