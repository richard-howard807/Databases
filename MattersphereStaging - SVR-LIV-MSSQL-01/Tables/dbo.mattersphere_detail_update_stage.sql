CREATE TABLE [dbo].[mattersphere_detail_update_stage]
(
[clNo] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FileNo] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fed_code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[table] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[column] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtLookupCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[text_value] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[money_value] [money] NULL,
[date_value] [datetime] NULL
) ON [PRIMARY]
GO
