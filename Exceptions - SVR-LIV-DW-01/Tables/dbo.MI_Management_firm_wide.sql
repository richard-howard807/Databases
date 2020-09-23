CREATE TABLE [dbo].[MI_Management_firm_wide]
(
[rowid] [int] NOT NULL IDENTITY(1, 1),
[employeeid] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[no_of_cases] [int] NULL,
[no_of_exceptions] [int] NULL,
[date] [datetime2] NULL CONSTRAINT [DF_Exceptions.MI_Management_firm_wide] DEFAULT (getdate()),
[closed] [int] NULL
) ON [PRIMARY]
GO
