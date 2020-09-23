CREATE TABLE [dbo].[FEDToMSCapacities]
(
[Capacity Code] [char] (10) COLLATE Latin1_General_CI_AS NULL,
[Capacity Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MatterSphere Code] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[MatterSphere Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Notes] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MS Code length] [float] NULL,
[Contact type 1] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Create?] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Notes1] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[F10] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
