CREATE TABLE [dbo].[target_operating_model_data]
(
[value_group] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fin_quarter] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[firm] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[division] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[department] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[customer_satisfaction_score] [numeric] (4, 2) NULL,
[file_lifecycle_days] [int] NULL,
[revenue_per_case_handler] [money] NULL,
[utilisation_rate_per_case_handler] [numeric] (5, 2) NULL
) ON [PRIMARY]
GO
