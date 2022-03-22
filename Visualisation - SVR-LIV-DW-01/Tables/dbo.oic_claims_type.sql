CREATE TABLE [dbo].[oic_claims_type]
(
[reporting_period] [nvarchar] (2) COLLATE Latin1_General_CI_AS NULL,
[reporting_period_start] [datetime] NULL,
[reporting_period_end] [datetime] NULL,
[claims_year] [int] NULL,
[claim_types] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[claim_type_group] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[number_of_claims] [int] NULL
) ON [PRIMARY]
GO
