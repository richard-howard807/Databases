CREATE TABLE [dbo].[mattersphere_api_detail_stage]
(
[fileID] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Client] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter] [float] NULL,
[fed_case_detail_code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[msphere_table] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[msphere_column] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[lookup_yes_no] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[text_value] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[numeric_value] [float] NULL,
[date_value] [datetime] NULL,
[txtLookupCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
