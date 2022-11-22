CREATE TABLE [dbo].[injury_type_group]
(
[Injury Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Site] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Severity] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[injury_type_group] TO [WEBAPP-PredictLargeLoss]
GO
