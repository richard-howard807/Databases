CREATE TABLE [dbo].[dim_employee]
(
[dim_employee_key] [int] NOT NULL IDENTITY(1, 1),
[payrollid] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[displayemployeeid] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[employeeid] [char] (36) COLLATE Latin1_General_BIN NULL,
[sequence] [bigint] NULL,
[forename] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[surname] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[othername] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[initials] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[knownas] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[title] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[workemail] [nvarchar] (320) COLLATE Latin1_General_BIN NULL,
[worksforemail] [nvarchar] (320) COLLATE Latin1_General_BIN NULL,
[locationidud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[workphone] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[windowsusername] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[fed_login] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[nt_login] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[levelidud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[postid] [nvarchar] (200) COLLATE Latin1_General_BIN NULL,
[leaverlastworkdate] [datetime] NULL,
[admissiondateud] [datetime] NULL,
[admissiontypeud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[photofilename] [nvarchar] (500) COLLATE Latin1_General_BIN NULL,
[dss_create_time] [datetime] NULL,
[dss_update_time] [datetime] NULL,
[secretaryud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[contracttype] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[jobtitle] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[classification] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[rolematrixlevelud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[fte] [numeric] (10, 2) NULL,
[role_responsibility_1] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[role_responsibility_2] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[employeestartdate] [datetime] NULL,
[leftdate] [datetime] NULL,
[client_segment] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[client_sector] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[deleted_from_cascade] [bit] NULL,
[client_manager] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[line_manager_email] [nvarchar] (320) COLLATE Latin1_General_BIN NULL,
[not_current_active] [bit] NULL,
[previous_firm] [nvarchar] (50) COLLATE Latin1_General_BIN NULL
) ON [DIM_TAB]
GO
ALTER TABLE [dbo].[dim_employee] ADD CONSTRAINT [dim_employee_idx_0] PRIMARY KEY CLUSTERED ([dim_employee_key]) ON [DIM_TAB]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dim_employee_idx_A] ON [dbo].[dim_employee] ([employeeid], [payrollid]) ON [DIM_IDX]
GO
GRANT SELECT ON  [dbo].[dim_employee] TO [ebilling]
GO
GRANT SELECT ON  [dbo].[dim_employee] TO [lnksvrdatareaderred_dw_EmployeeData]
GO
GRANT SELECT ON  [dbo].[dim_employee] TO [omnireader]
GO
EXEC sp_addextendedproperty N'Comment', N'Main employee dimension, contains various employee information', 'SCHEMA', N'dbo', 'TABLE', N'dim_employee', NULL, NULL
GO
EXEC sp_addextendedproperty N'Comment', N'Generated artificial key', 'SCHEMA', N'dbo', 'TABLE', N'dim_employee', 'COLUMN', N'dim_employee_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was created in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'dim_employee', 'COLUMN', N'dss_create_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'dim_employee', 'COLUMN', N'dss_update_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Employee ID from cascade', 'SCHEMA', N'dbo', 'TABLE', N'dim_employee', 'COLUMN', N'employeeid'
GO
EXEC sp_addextendedproperty N'Comment', N'Payrollid from cascade, used for FEDCode in dim_fed_hierarchy_history', 'SCHEMA', N'dbo', 'TABLE', N'dim_employee', 'COLUMN', N'payrollid'
GO
EXEC sp_addextendedproperty N'Comment', N'Team Manager Email - NOT LINE MANAGER (reportingbcm from dim_fed_hiererchy_history)', 'SCHEMA', N'dbo', 'TABLE', N'dim_employee', 'COLUMN', N'worksforemail'
GO
