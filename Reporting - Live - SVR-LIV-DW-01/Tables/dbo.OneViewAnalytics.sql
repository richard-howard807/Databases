CREATE TABLE [dbo].[OneViewAnalytics]
(
[username] [nvarchar] (60) COLLATE Latin1_General_CI_AS NULL,
[idsite] [int] NULL,
[client_name] [nvarchar] (60) COLLATE Latin1_General_CI_AS NULL,
[visit_id] [numeric] (20, 0) NULL,
[time_spent_seconds] [numeric] (10, 0) NULL,
[visit_first_action_time] [datetime2] NULL,
[visit_last_action_time] [datetime2] NULL,
[server_time] [datetime2] NULL,
[url_visited] [nvarchar] (400) COLLATE Latin1_General_CI_AS NULL,
[site_page] [nvarchar] (400) COLLATE Latin1_General_CI_AS NULL,
[date_logged_on] [date] NULL
) ON [PRIMARY]
GO
