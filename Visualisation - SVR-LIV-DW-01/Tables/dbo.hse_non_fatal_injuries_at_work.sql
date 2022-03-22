CREATE TABLE [dbo].[hse_non_fatal_injuries_at_work]
(
[Year] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[self_reported_non_fatal_injury] [float] NULL,
[slips_trips_falls_same_level] [float] NULL,
[handling_lifting_carrying] [float] NULL,
[struck_by_moving_object] [float] NULL,
[acts_of_violence] [float] NULL,
[falls_from_height] [float] NULL,
[current_flag] [nvarchar] (8) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
