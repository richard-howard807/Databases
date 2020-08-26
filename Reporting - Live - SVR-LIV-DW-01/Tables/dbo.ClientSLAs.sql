CREATE TABLE [dbo].[ClientSLAs]
(
[Client Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[File Opening SLA (days)] [float] NULL,
[Initial Report SLA (days)] [float] NULL,
[Update Report SLA] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Update Report SLA (days)] [float] NULL,
[Update Report SLA (working days)] [nchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Update Report SLA (months)] [nchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
