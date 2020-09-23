CREATE TABLE [dbo].[TaskImportSucess]
(
[ID] [int] NOT NULL,
[ExttskID] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[SourceSystemID] [int] NOT NULL,
[fileID] [bigint] NOT NULL,
[clNo] [nvarchar] (12) COLLATE Latin1_General_CI_AS NOT NULL,
[fileNo] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[tskType] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[tskDesc] [nvarchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[tskDue] [datetime] NOT NULL,
[feeusrID] [nvarchar] (8) COLLATE Latin1_General_CI_AS NULL,
[tsknotes] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[tskCreated] [datetime] NOT NULL,
[tskCreatedBy] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[tskCompleted] [datetime] NULL,
[tskCompletedBy] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[DocID] [bigint] NULL,
[tskReminder] [datetime] NULL,
[InsertDate] [datetime] NOT NULL,
[Imported] [datetime] NULL,
[StatusID] [tinyint] NOT NULL,
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[MSfeeusrID] [int] NULL,
[MStskCreatedBy] [int] NULL,
[MStskCompletedBy] [int] NULL
) ON [PRIMARY]
GO
