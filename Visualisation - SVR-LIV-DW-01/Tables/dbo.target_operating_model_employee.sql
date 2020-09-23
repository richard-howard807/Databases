CREATE TABLE [dbo].[target_operating_model_employee]
(
[Month] [datetime] NULL,
[FED Code] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[Division] [nvarchar] (500) COLLATE Latin1_General_CI_AS NULL,
[Department] [nvarchar] (500) COLLATE Latin1_General_CI_AS NULL,
[Team] [nvarchar] (500) COLLATE Latin1_General_CI_AS NULL,
[FTE] [decimal] (5, 1) NULL,
[Role] [nvarchar] (500) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
