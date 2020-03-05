CREATE TABLE [dbo].[ArchiveData_Delete]
(
[fileID] [float] NULL,
[clID] [float] NULL,
[MS Client Number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Client Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MS Matter Number] [float] NULL,
[Matter Status] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Created] [datetime] NULL,
[dwArchivedDate] [datetime] NULL,
[Destruction due date] [datetime] NULL,
[Date destroyed] [datetime] NULL,
[Archive Status] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Event] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Archive type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FEDCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FEDCodeNoZeros] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Owner Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[usrInits] [float] NULL,
[bitMSOnlyMM] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[F20] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
