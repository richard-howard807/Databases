CREATE TABLE [dbo].[ROI]
(
[entity number] [int] NULL,
[client number] [nvarchar] (64) COLLATE Latin1_General_BIN NULL,
[clientindex] [int] NULL,
[client name] [nvarchar] (128) COLLATE Latin1_General_BIN NULL,
[client status] [nvarchar] (16) COLLATE Latin1_General_BIN NULL,
[client open date] [datetime] NULL,
[Client Introducer] [nvarchar] (64) COLLATE Latin1_General_BIN NULL,
[timekeeper] [int] NULL,
[mattindex] [int] NULL,
[postdate] [datetime] NULL,
[billamt] [numeric] (16, 2) NULL,
[billhrs] [numeric] (16, 5) NULL,
[workamt] [numeric] (16, 2) NULL,
[workhrs] [numeric] (16, 5) NULL,
[ref_type] [varchar] (23) COLLATE Latin1_General_CI_AS NOT NULL,
[reftypeno] [int] NOT NULL,
[update_time] [datetime] NULL,
[altnumber] [varchar] (200) COLLATE Latin1_General_CI_AS NULL,
[percentage] [numeric] (16, 4) NULL,
[billamt_v2] [numeric] (16, 2) NULL,
[actual_timekeeper] [int] NULL,
[invindex] [int] NULL,
[paid_total] [numeric] (16, 2) NULL
) ON [PRIMARY]
GO
