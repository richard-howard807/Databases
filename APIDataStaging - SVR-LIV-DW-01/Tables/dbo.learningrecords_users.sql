CREATE TABLE [dbo].[learningrecords_users]
(
[client_user_identifier] [nvarchar] (104) COLLATE Latin1_General_CI_AS NULL,
[first_name] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[last_name] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[email_address] [nvarchar] (359) COLLATE Latin1_General_CI_AS NULL,
[course_name] [nvarchar] (359) COLLATE Latin1_General_CI_AS NULL,
[history_status] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[score] [float] NULL,
[history_status_date] [datetime] NULL,
[duration] [nvarchar] (20) COLLATE Latin1_General_CI_AS NULL,
[category] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[subcategory] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[body_name] [nvarchar] (800) COLLATE Latin1_General_CI_AS NULL,
[accreditation_type_name] [nvarchar] (500) COLLATE Latin1_General_CI_AS NULL,
[credit_amount] [float] NULL
) ON [PRIMARY]
GO
