CREATE TABLE [dbo].[nhs_panel_averages]
(
[Level] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Scheme] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Month] [datetime] NULL,
[Banding] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Damages Paid] [money] NULL,
[Defence Costs] [money] NULL,
[Shelf Life] [float] NULL,
[Start Date] [date] NULL,
[End Date] [date] NULL
) ON [PRIMARY]
GO
