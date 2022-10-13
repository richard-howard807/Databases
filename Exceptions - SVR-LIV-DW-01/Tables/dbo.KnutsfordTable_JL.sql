CREATE TABLE [dbo].[KnutsfordTable_JL]
(
[Claim Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ClientCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MatterNumber] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date Case Opened] [datetime] NULL,
[Date Case Closed] [datetime] NULL,
[Case Manager Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Team] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Postcode if not dealt with at Knutsford Office] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Worktype] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[contact_salutation] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[addresse] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[address_line_1] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[address_line_2] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[address_line_3] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[address_line_4] [char] (50) COLLATE Latin1_General_BIN NULL,
[address_line_5] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[postcode] [char] (15) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
