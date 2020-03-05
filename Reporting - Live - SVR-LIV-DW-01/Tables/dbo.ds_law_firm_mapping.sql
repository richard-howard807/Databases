CREATE TABLE [dbo].[ds_law_firm_mapping]
(
[law_firm] [nvarchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[category] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ds_law_firm_mapping] ADD CONSTRAINT [PK__ds_law_f__7EE5A59DD4F28602] PRIMARY KEY CLUSTERED  ([law_firm]) ON [PRIMARY]
GO
