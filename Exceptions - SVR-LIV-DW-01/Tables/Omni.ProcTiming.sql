CREATE TABLE [Omni].[ProcTiming]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[Procname] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[TimeStart] [datetime] NULL,
[TimeEnd] [datetime] NULL
) ON [PRIMARY]
GO
