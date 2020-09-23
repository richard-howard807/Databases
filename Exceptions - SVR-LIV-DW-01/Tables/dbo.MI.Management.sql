CREATE TABLE [dbo].[MI.Management]
(
[rowid] [int] NOT NULL IDENTITY(1, 1),
[employeeid] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[no_of_cases] [int] NULL,
[no_of_exceptions] [int] NULL,
[date] [datetime2] NULL CONSTRAINT [DF_Exceptions.MI.Management_date] DEFAULT (getdate())
) ON [PRIMARY]
GO
GRANT ALTER ON  [dbo].[MI.Management] TO [SBC\ExceptionsRedSVC]
GO
