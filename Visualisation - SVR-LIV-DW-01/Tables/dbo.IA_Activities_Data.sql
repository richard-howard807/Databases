CREATE TABLE [dbo].[IA_Activities_Data]
(
[dim_client_key] [int] NULL,
[Activity] [datetime] NULL,
[Activity Type] [nvarchar] (60) COLLATE Latin1_General_BIN NULL,
[Date of Activity] [datetime] NULL,
[CreatedBy] [nvarchar] (101) COLLATE Latin1_General_BIN NULL,
[Client Name] [char] (80) COLLATE Latin1_General_BIN NULL,
[Client Category] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[Segment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[Days Since Last Contacted] [int] NULL,
[Next Engagement Date] [datetime] NULL,
[CRP] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[ClientKey] [int] NULL
) ON [PRIMARY]
GO