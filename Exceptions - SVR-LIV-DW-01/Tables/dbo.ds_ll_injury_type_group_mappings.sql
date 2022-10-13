CREATE TABLE [dbo].[ds_ll_injury_type_group_mappings]
(
[injury_type] [nvarchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[description] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[injury_type_group] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[sub_injury_type_group] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ds_ll_injury_type_group_mappings] ADD CONSTRAINT [PK__ds_ll_in__0ABDC4C362278CDE] PRIMARY KEY CLUSTERED  ([injury_type]) ON [PRIMARY]
GO
