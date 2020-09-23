CREATE TABLE [dbo].[SegmentAPI20170530]
(
[client_code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[client_name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[client_partner_name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Segment (cboSegment)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Sector (cboSubSegment)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Subsector] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MSCliD] [float] NULL,
[clname] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[NewcboSegment] [float] NULL,
[NewcboSubSegment] [float] NULL,
[NewcboSector] [float] NULL
) ON [PRIMARY]
GO
