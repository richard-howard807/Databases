CREATE TABLE [dbo].[NHSLA_time_charge]
(
[tt_client] [char] (8) COLLATE Latin1_General_BIN NOT NULL,
[tt_matter] [char] (8) COLLATE Latin1_General_BIN NOT NULL,
[NumberOfMinutes] [int] NULL,
[ChargeRate] [decimal] (10, 2) NOT NULL,
[TimeCharge] [decimal] (38, 2) NULL,
[Fed Code] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[TimeHandler] [nvarchar] (101) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LevelIDUD] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AdmissionDateud] [datetime] NULL,
[Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[PQEYears] [varchar] (17) COLLATE Latin1_General_CI_AS NULL,
[YearBilled] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[Total] [decimal] (38, 2) NULL,
[Percentage] [decimal] (38, 6) NULL
) ON [PRIMARY]
GO
