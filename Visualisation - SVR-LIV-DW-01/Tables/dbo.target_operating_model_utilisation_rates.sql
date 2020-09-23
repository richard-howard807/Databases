CREATE TABLE [dbo].[target_operating_model_utilisation_rates]
(
[Financial Year] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Month_Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[FED Code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Surname] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Division] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Department] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Team] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Rounded FTE] [decimal] (5, 1) NULL,
[Role] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Location] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Hours] [decimal] (38, 5) NULL,
[Working Days in Month] [decimal] (38, 5) NULL,
[Hours Per Day] [decimal] (38, 5) NULL,
[Hours Per Month] [decimal] (38, 5) NULL,
[Chargeable Hours] [decimal] (38, 5) NULL,
[Non Chargeable Hours] [decimal] (38, 5) NULL,
[Partner Ratio] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Grade] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Month] [date] NULL
) ON [PRIMARY]
GO
