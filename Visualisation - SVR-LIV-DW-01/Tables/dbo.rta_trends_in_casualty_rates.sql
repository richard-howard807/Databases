CREATE TABLE [dbo].[rta_trends_in_casualty_rates]
(
[road_user_type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[casualty_year] [nvarchar] (128) COLLATE Latin1_General_CI_AS NULL,
[All casualties] [float] NULL,
[Slightly injured (unadjusted)] [float] NULL,
[Slightly injured (adjusted)] [float] NULL,
[Seriously injured (unadjusted)] [float] NULL,
[Seriously injured (adjusted)] [float] NULL,
[KSI (unadjusted)1] [float] NULL,
[KSI (adjusted)1] [float] NULL,
[Killed] [float] NULL
) ON [PRIMARY]
GO
