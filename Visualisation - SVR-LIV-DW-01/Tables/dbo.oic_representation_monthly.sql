CREATE TABLE [dbo].[oic_representation_monthly]
(
[reporting_period] [nvarchar] (2) COLLATE Latin1_General_CI_AS NULL,
[reporting_period_start] [datetime] NULL,
[reporting_period_end] [datetime] NULL,
[claims_year] [int] NULL,
[claims_month] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[claims_month_no] [int] NULL,
[representation] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[settlements_per_month] [int] NULL,
[portal_support_centre_calls] [int] NULL
) ON [PRIMARY]
GO
