CREATE TABLE [dbo].[dim_fed_hierarchy_history]
(
[dim_fed_hierarchy_history_key] [int] NOT NULL IDENTITY(0, 1),
[dim_employee_key] [int] NULL,
[source_system_id] [int] NULL,
[fed_hierarchy_business_key] [varchar] (1000) COLLATE Latin1_General_BIN NOT NULL,
[fed_code] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[employeeid] [char] (36) COLLATE Latin1_General_BIN NOT NULL,
[activeud] [bit] NULL,
[fed_code_effective_start_date] [datetime] NULL,
[jobtitle] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[fte] [numeric] (18, 16) NULL,
[linemanageridud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[linemanagername] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[reportingbcmidud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[reportingbcmname] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[worksforemployeeid] [char] (36) COLLATE Latin1_General_BIN NULL,
[worksforname] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[display_name] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[name] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[windowsusername] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchynode] [bigint] NULL,
[hierarchynodehist] [bigint] NULL,
[hierarchylevel1hist] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel2hist] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel3hist] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel4hist] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel5hist] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel6hist] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel1] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel2] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel3] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel4] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel5] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel6] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchynodehistnorm] [bigint] NULL,
[hierarchylevel1histnorm] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel2histnorm] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel3histnorm] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel4histnorm] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel5histnorm] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel6histnorm] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[level] [int] NULL,
[securitylevel] [int] NULL,
[effective_start_date] [datetime] NULL,
[leaver] [int] NULL,
[warning_flag] [varchar] (1) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF__wc_copy_1__warni__1E0CC7E3] DEFAULT ('N'),
[hierarchynodehist_pre_francis] [bigint] NULL,
[hierarchylevel1hist_pre_francis] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel2hist_pre_francis] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel3hist_pre_francis] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel4hist_pre_francis] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel5hist_pre_francis] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[hierarchylevel6hist_pre_francis] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[management_role_one] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[management_role_two] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[latest_hierarchy_flag] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[dss_update_time] [datetime] NULL,
[dss_start_date] [datetime] NULL,
[dss_end_date] [datetime] NULL,
[dss_current_flag] [char] (1) COLLATE Latin1_General_BIN NULL,
[dss_version] [int] NULL,
[cost_handler] [bit] NULL
) ON [DIM_TAB]
GO
ALTER TABLE [dbo].[dim_fed_hierarchy_history] ADD CONSTRAINT [dim_fed_hierarchy_hist_idx_0] PRIMARY KEY CLUSTERED  ([dim_fed_hierarchy_history_key]) ON [DIM_TAB]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_p] ON [dbo].[dim_fed_hierarchy_history] ([cost_handler]) INCLUDE ([dim_employee_key], [employeeid], [fed_code]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_1] ON [dbo].[dim_fed_hierarchy_history] ([dim_employee_key]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_x] ON [dbo].[dim_fed_hierarchy_history] ([dim_fed_hierarchy_history_key]) INCLUDE ([fed_code]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_AC_20151125] ON [dbo].[dim_fed_hierarchy_history] ([dss_current_flag]) INCLUDE ([activeud], [employeeid], [fed_code], [hierarchylevel4hist], [name], [reportingbcmidud], [worksforemployeeid]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_20161102] ON [dbo].[dim_fed_hierarchy_history] ([dss_current_flag]) INCLUDE ([display_name], [dss_end_date], [dss_start_date], [employeeid], [fed_code], [fed_hierarchy_business_key], [hierarchylevel1hist], [hierarchylevel2hist], [hierarchylevel3], [hierarchylevel3hist], [hierarchylevel4hist], [hierarchylevel5hist]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_20161202] ON [dbo].[dim_fed_hierarchy_history] ([dss_start_date], [dss_end_date]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_y] ON [dbo].[dim_fed_hierarchy_history] ([dss_start_date], [dss_end_date]) INCLUDE ([dim_fed_hierarchy_history_key]) ON [DIM_IDX]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_A] ON [dbo].[dim_fed_hierarchy_history] ([employeeid], [fed_hierarchy_business_key], [fed_code], [dss_current_flag], [dss_version]) ON [DIM_IDX]
GO
CREATE UNIQUE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_SC] ON [dbo].[dim_fed_hierarchy_history] ([employeeid], [fed_hierarchy_business_key], [source_system_id], [activeud], [fed_code_effective_start_date], [jobtitle], [fte], [linemanageridud], [linemanagername], [reportingbcmidud], [reportingbcmname], [worksforemployeeid], [worksforname], [fed_code], [dss_current_flag], [dss_version]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_B] ON [dbo].[dim_fed_hierarchy_history] ([fed_code], [dss_current_flag]) INCLUDE ([employeeid], [hierarchylevel2hist], [hierarchylevel3hist], [hierarchylevel4hist], [hierarchylevel5hist]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_20161020] ON [dbo].[dim_fed_hierarchy_history] ([hierarchylevel2hist]) INCLUDE ([dim_fed_hierarchy_history_key], [hierarchylevel3hist], [hierarchylevel4hist]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_20161101] ON [dbo].[dim_fed_hierarchy_history] ([hierarchylevel4hist]) INCLUDE ([display_name], [dss_current_flag], [dss_end_date], [dss_start_date], [fed_code], [fed_hierarchy_business_key], [hierarchylevel1hist], [hierarchylevel2hist], [hierarchylevel3hist], [hierarchylevel5hist]) ON [DIM_IDX]
GO
CREATE NONCLUSTERED INDEX [dim_fed_hierarchy_hist_idx_5] ON [dbo].[dim_fed_hierarchy_history] ([windowsusername], [dss_start_date], [dss_end_date]) INCLUDE ([hierarchylevel2hist], [hierarchylevel3hist], [hierarchylevel4hist]) ON [DIM_IDX]
GO
GRANT SELECT ON  [dbo].[dim_fed_hierarchy_history] TO [ebilling]
GO
GRANT SELECT ON  [dbo].[dim_fed_hierarchy_history] TO [lnksvrdatareader]
GO
GRANT SELECT ON  [dbo].[dim_fed_hierarchy_history] TO [lnksvrdatareader_ext]
GO
GRANT SELECT ON  [dbo].[dim_fed_hierarchy_history] TO [lnksvrdatareaderred_dw_EmployeeData]
GO
GRANT SELECT ON  [dbo].[dim_fed_hierarchy_history] TO [omnireader]
GO
GRANT SELECT ON  [dbo].[dim_fed_hierarchy_history] TO [SBC\SQL - DBO access to Non-Sensitive DBs on SVR-LIV-DWH-01]
GO
GRANT SELECT ON  [dbo].[dim_fed_hierarchy_history] TO [SBC\SQL - Workflow Team Exceptions Access]
GO
EXEC sp_addextendedproperty N'Comment', N'Slowly changing dimension, records team, job title, manager etc. changes for each employee', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', NULL, NULL
GO
EXEC sp_addextendedproperty N'Comment', N'Used to show active records for user, new hierachy is activeud=1', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'activeud'
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current (latest) version of a business key (Y/N)', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'dss_current_flag'
GO
EXEC sp_addextendedproperty N'Comment', N'Indicates when the record is no longer effective.', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'dss_end_date'
GO
EXEC sp_addextendedproperty N'Comment', N'Indicates when the record became effective from', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'dss_start_date'
GO
EXEC sp_addextendedproperty N'Comment', N'EmployeeID from Cascade', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'employeeid'
GO
EXEC sp_addextendedproperty N'Comment', N'Mainly payrollid from Cascade, older records are from other sources', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'fed_code'
GO
EXEC sp_addextendedproperty N'Comment', N'Employee start date', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'fed_code_effective_start_date'
GO
EXEC sp_addextendedproperty N'Comment', N'Payrollid from Cascade', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'fed_hierarchy_business_key'
GO
EXEC sp_addextendedproperty N'Comment', N'Indicates if they are a full or part time employee ', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'fte'
GO
EXEC sp_addextendedproperty N'Comment', N'Used for reporting structure', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'hierarchylevel2hist'
GO
EXEC sp_addextendedproperty N'Comment', N'Used for reporting structure', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'hierarchylevel3hist'
GO
EXEC sp_addextendedproperty N'Comment', N'Used for reporting structure', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'hierarchylevel4hist'
GO
EXEC sp_addextendedproperty N'Comment', N'Used for reporting structure', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'hierarchylevel5hist'
GO
EXEC sp_addextendedproperty N'Comment', N'Team ID key from Cascade', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'hierarchynode'
GO
EXEC sp_addextendedproperty N'Comment', N'Job title', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'jobtitle'
GO
EXEC sp_addextendedproperty N'Comment', N'indicates if the employee no longer works for Weightmans', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'leaver'
GO
EXEC sp_addextendedproperty N'Comment', N'', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'linemanageridud'
GO
EXEC sp_addextendedproperty N'Comment', N'', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'linemanagername'
GO
EXEC sp_addextendedproperty N'Comment', N'This is the team manager and can differ from who the person reports to. In Cascade, it is called the Team Manager.', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'reportingbcmidud'
GO
EXEC sp_addextendedproperty N'Comment', N'This is the team manager and can differ from who the person reports to. In Cascade, it is called the Team Manager.', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'reportingbcmname'
GO
EXEC sp_addextendedproperty N'Comment', N'Active directy userid - what they log on with', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'windowsusername'
GO
EXEC sp_addextendedproperty N'Comment', N'Line Manager, the person the employee reports to directly. In Cascade, this field is also called line manager.', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'worksforemployeeid'
GO
EXEC sp_addextendedproperty N'Comment', N'Line Manager, the person the employee reports to directly. In Cascade, this field is also called line manager.', 'SCHEMA', N'dbo', 'TABLE', N'dim_fed_hierarchy_history', 'COLUMN', N'worksforname'
GO
