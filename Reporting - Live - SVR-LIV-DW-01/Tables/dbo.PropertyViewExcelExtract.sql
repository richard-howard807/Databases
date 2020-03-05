CREATE TABLE [dbo].[PropertyViewExcelExtract]
(
[client_name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[client_code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[matter_number] [float] NULL,
[clientcontact_name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Address ] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Postcode ] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[date_instructions_received] [datetime] NULL,
[anticipated_completion_date] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[completion_date] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fixed_fee_amount] [float] NULL
) ON [PRIMARY]
GO
