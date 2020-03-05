CREATE TABLE [dbo].[clientList]
(
[client_name] [char] (80) COLLATE Latin1_General_BIN NULL,
[client_partner_name] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[hierarchylevel2hist] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[matter_partner_code] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[client_code] [char] (8) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
