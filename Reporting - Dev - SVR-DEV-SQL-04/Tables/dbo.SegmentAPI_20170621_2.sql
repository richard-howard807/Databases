CREATE TABLE [dbo].[SegmentAPI_20170621_2]
(
[ClientID] [float] NULL,
[historic_client_code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[client_code] [float] NULL,
[client_name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[client_partner_name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[segment] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cbosegment] [float] NULL,
[sector] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cbosubsegment] [float] NULL,
[sub_sector] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cbosector] [float] NULL
) ON [PRIMARY]
GO
