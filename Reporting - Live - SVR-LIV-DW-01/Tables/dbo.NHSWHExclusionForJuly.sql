CREATE TABLE [dbo].[NHSWHExclusionForJuly]
(
[dim_matter_header_curr_key] [int] NOT NULL IDENTITY(1, 1),
[master_client_code] [nvarchar] (12) COLLATE Latin1_General_BIN NULL,
[master_matter_number] [nvarchar] (20) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
