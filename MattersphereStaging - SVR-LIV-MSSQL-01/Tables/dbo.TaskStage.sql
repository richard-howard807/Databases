CREATE TABLE [dbo].[TaskStage]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[ExttskID] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[SourceSystemID] [int] NOT NULL,
[fileID] [bigint] NOT NULL,
[clNo] [nvarchar] (12) COLLATE Latin1_General_CI_AS NOT NULL,
[fileNo] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[tskType] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL CONSTRAINT [DF__TaskStage__tskTy__6EF57B66] DEFAULT ('KEYDATE'),
[tskDesc] [nvarchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[tskDue] [datetime] NOT NULL,
[feeusrID] [nvarchar] (8) COLLATE Latin1_General_CI_AS NULL,
[tsknotes] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[tskCreated] [datetime] NOT NULL CONSTRAINT [DF__TaskStage__tskCr__6FE99F9F] DEFAULT (getdate()),
[tskCreatedBy] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[tskCompleted] [datetime] NULL,
[tskCompletedBy] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[DocID] [bigint] NULL,
[tskReminder] [datetime] NULL,
[InsertDate] [datetime] NOT NULL CONSTRAINT [DF__TaskStage__Inser__70DDC3D8] DEFAULT (getdate()),
[Imported] [datetime] NULL,
[StatusID] [tinyint] NOT NULL CONSTRAINT [DF__TaskStage__Statu__71D1E811] DEFAULT ((0)),
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[MSfeeusrID] [int] NULL,
[MStskCreatedBy] [int] NULL,
[MStskCompletedBy] [int] NULL
) ON [PRIMARY]
GO
