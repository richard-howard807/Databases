CREATE TABLE [dbo].[results]
(
[client_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[matter_number] [char] (8) COLLATE Latin1_General_BIN NULL,
[sequence_no] [int] NULL,
[dim_parent_key] [int] NOT NULL,
[xorder] [bigint] NULL,
[WPS275] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[WPS277] [numeric] (13, 2) NULL,
[WPS386] [datetime] NULL,
[WPS387] [char] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
