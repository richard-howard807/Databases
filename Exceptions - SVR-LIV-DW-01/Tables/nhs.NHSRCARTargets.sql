CREATE TABLE [nhs].[NHSRCARTargets]
(
[Display Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Shelf Life Target] [float] NULL,
[Damages Target] [money] NULL,
[Defence Costs Target] [money] NULL,
[Consolidated Costs Target] [money] NULL,
[Scheme] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
