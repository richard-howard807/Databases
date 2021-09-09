CREATE TABLE [dbo].[locations]
(
[loc_code] [nvarchar] (64) COLLATE Latin1_General_CI_AS NULL,
[loc_name] [nvarchar] (64) COLLATE Latin1_General_CI_AS NULL,
[local_date_format] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[local_time_format] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[paper_size] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[record_status] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[time_zone_name] [nvarchar] (60) COLLATE Latin1_General_CI_AS NULL,
[venue_code] [nvarchar] (64) COLLATE Latin1_General_CI_AS NULL,
[venue_name] [nvarchar] (64) COLLATE Latin1_General_CI_AS NULL,
[is_conflict_check_ignored] [bit] NULL,
[is_default_venue] [bit] NULL,
[venue_status] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
