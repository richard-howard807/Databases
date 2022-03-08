CREATE TABLE [dbo].[civil_justice_stats]
(
[year] [float] NULL,
[quarter] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[figure_status] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[money_claims] [float] NULL,
[personal_injury_claims] [float] NULL,
[other_damages_claims] [float] NULL,
[total_damages_claims] [float] NULL,
[total_money_and_damages_claims] [float] NULL,
[mortgage_and_landlord_possession_claims] [float] NULL,
[claims_for_return_of_goods] [float] NULL,
[other_non_money_claims] [float] NULL,
[total_non_money_claims] [float] NULL,
[total_claims] [float] NULL,
[total_insolvency_petitions] [float] NULL,
[total_proceedings_started] [float] NULL,
[total_completed_civil_proceedings_in_the_magistrates_courts] [float] NULL
) ON [PRIMARY]
GO
