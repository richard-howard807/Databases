CREATE TABLE [dbo].[stage_oic_claims]
(
[reporting_period] [nvarchar] (2) COLLATE Latin1_General_CI_AS NULL,
[reporting_period_start] [datetime] NULL,
[reporting_period_end] [datetime] NULL,
[claims_year] [int] NULL,
[claims_month] [nvarchar] (20) COLLATE Latin1_General_CI_AS NULL,
[claims_month_no] [int] NULL,
[claims_submitted] [int] NULL
) ON [PRIMARY]
GO
