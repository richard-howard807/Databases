CREATE TABLE [dbo].[ExecutionLogQuerying]
(
[InstanceName] [nvarchar] (38) COLLATE Latin1_General_CI_AS_KS_WS NOT NULL,
[ReportID] [uniqueidentifier] NULL,
[UserName] [nvarchar] (260) COLLATE Latin1_General_CI_AS_KS_WS NULL,
[RequestType] [bit] NULL,
[Format] [nvarchar] (26) COLLATE Latin1_General_CI_AS_KS_WS NULL,
[Parameters] [ntext] COLLATE Latin1_General_CI_AS_KS_WS NULL,
[TimeStart] [datetime] NOT NULL,
[TimeEnd] [datetime] NOT NULL,
[TimeDataRetrieval] [int] NOT NULL,
[TimeProcessing] [int] NOT NULL,
[TimeRendering] [int] NOT NULL,
[Source] [int] NOT NULL,
[Status] [nvarchar] (40) COLLATE Latin1_General_CI_AS_KS_WS NOT NULL,
[ByteCount] [bigint] NOT NULL,
[RowCount] [bigint] NOT NULL
) ON [PRIMARY]
GO
