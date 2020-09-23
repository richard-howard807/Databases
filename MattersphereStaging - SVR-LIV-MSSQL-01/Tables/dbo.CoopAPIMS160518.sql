CREATE TABLE [dbo].[CoopAPIMS160518]
(
[case_id] [float] NULL,
[FEDCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FileID] [float] NULL,
[BitMSOnly] [float] NULL,
[client] [float] NULL,
[matter] [float] NULL,
[case_detail_code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtMSCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtMSTable] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[case_detail_type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[case_text] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[case_value] [float] NULL,
[case_date] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
