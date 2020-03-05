CREATE TABLE [dbo].[ds_sh_exceptions_values]
(
[case_id] [int] NULL,
[exceptionruleid] [int] NULL,
[Flag] [bit] NULL,
[String] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Number] [decimal] (13, 2) NULL,
[Date] [datetime] NULL,
[dss_update_time] [datetime] NULL
) ON [PRIMARY]
GO
