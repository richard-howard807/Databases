CREATE TABLE [dbo].[dim_payor_parent]
(
[payorindex] [int] NULL,
[entity] [int] NULL,
[payor_name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[payor_name_parent] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[LastUpdated] [datetime] NULL CONSTRAINT [DF__dim_payor__LastU__69AC45C5] DEFAULT (NULL),
[LastUpdatedBy] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL CONSTRAINT [DF__dim_payor__LastU__6AA069FE] DEFAULT (NULL)
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [ClusteredIndex-20200130-111509] ON [dbo].[dim_payor_parent] ([payorindex]) ON [PRIMARY]
GO
