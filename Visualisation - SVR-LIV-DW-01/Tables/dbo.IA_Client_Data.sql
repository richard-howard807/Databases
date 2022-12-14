CREATE TABLE [dbo].[IA_Client_Data]
(
[Opportunity Number] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[dim_client_key] [int] NOT NULL,
[Client Name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Client Category] [nvarchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[Opportunity Name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Opportunity Type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Revenue Type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Segment] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Sector] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[CRP] [nvarchar] (101) COLLATE Latin1_General_BIN NULL,
[Open Date] [datetime] NULL,
[Days Open] [int] NULL,
[Last Contacted Date] [datetime] NULL,
[Days Since Last Contacted] [int] NULL,
[Next Engagement Date] [datetime] NULL,
[Expected Close Date] [datetime] NULL,
[Stage] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Sales Stage] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Opportunity Source] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Campaigns] [int] NULL,
[Probability %] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Opportunity Value] [money] NULL,
[Referrer Name] [varchar] (80) COLLATE Latin1_General_BIN NULL,
[Referrer Company] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Division] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[BD] [varchar] (80) COLLATE Latin1_General_BIN NULL,
[Target Revenue] [float] NULL,
[Last YR Annual] [int] NULL,
[MTD Actual] [int] NULL,
[YTD Actual] [numeric] (38, 2) NULL,
[Outcome] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Outcome Reason] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[state_outcome] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[ActualClosedDate] [datetime] NULL,
[Product] [nvarchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
