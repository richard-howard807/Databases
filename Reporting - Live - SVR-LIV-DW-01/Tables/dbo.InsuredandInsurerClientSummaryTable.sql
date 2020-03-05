CREATE TABLE [dbo].[InsuredandInsurerClientSummaryTable]
(
[insurerclient_name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[insuredclient_name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[insured_sector] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[client_name] [char] (80) COLLATE Latin1_General_BIN NULL,
[segment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[work_type_name] [char] (40) COLLATE Latin1_General_BIN NULL,
[department_name] [char] (40) COLLATE Latin1_General_BIN NULL,
[matter_partner_full_name] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[May_2015_now] [int] NULL,
[May_2015_April_2016] [int] NULL,
[May_2016_April_2017] [int] NULL,
[May_2017_now] [int] NULL,
[May_2015_now_bills] [numeric] (38, 2) NULL,
[May_2015_April_2016_bills] [numeric] (38, 2) NULL,
[May_2016_April_2017_bills] [numeric] (38, 2) NULL,
[May_2017_now_bills] [numeric] (38, 2) NULL,
[May_2018_now_bills] [numeric] (38, 2) NULL,
[May_2018_now] [int] NULL
) ON [PRIMARY]
GO
