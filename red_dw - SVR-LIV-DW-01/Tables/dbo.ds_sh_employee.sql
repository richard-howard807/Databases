CREATE TABLE [dbo].[ds_sh_employee]
(
[emp_uid] [int] NOT NULL IDENTITY(1, 1),
[source_system_id] [int] NOT NULL,
[employeeid] [char] (36) COLLATE Latin1_General_BIN NULL,
[sequence] [bigint] NULL,
[displayemployeeid] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[forename] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[surname] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[othername] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[initials] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[knownas] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[title] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[nationality] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[ethnicorigin] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[religion] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[sex] [smallint] NULL,
[dateofbirth] [datetime] NULL,
[photofilename] [nvarchar] (500) COLLATE Latin1_General_BIN NULL,
[securitylevel] [int] NULL,
[employeestartdate] [datetime] NULL,
[contservicedate] [datetime] NULL,
[maritalstatus] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[payrollid] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[costcentre] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[dependants] [int] NULL,
[disableddependants] [bit] NULL,
[sickpayscheme] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[leaverlastworkdate] [datetime] NULL,
[leftdate] [datetime] NULL,
[autocreateentitlements] [bit] NULL,
[driver] [bit] NULL,
[drivinglicenceno] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[companypension] [bit] NULL,
[workemail] [nvarchar] (320) COLLATE Latin1_General_BIN NULL,
[workphone] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[ruid] [char] (36) COLLATE Latin1_General_BIN NULL,
[employeedescnoid] [nvarchar] (101) COLLATE Latin1_General_BIN NULL,
[employeedesc] [nvarchar] (154) COLLATE Latin1_General_BIN NULL,
[sys_effectivedate] [datetime] NULL,
[sys_modifiedby] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[sys_modifieddate] [datetime] NULL,
[sys_requestid] [char] (36) COLLATE Latin1_General_BIN NULL,
[windowsusername] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[previousname] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[namechangedate] [datetime] NULL,
[psidud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[cpdstartud] [datetime] NULL,
[cpdpointsrequiredud] [int] NULL,
[leaver] [int] NULL,
[workmobilephonenumber] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[workinternalnumberud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[rowidud] [int] NULL,
[probationenddateud] [datetime] NULL,
[probationcompletedud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[offermadeud] [datetime] NULL,
[dateofferedud] [datetime] NULL,
[voluntaryinvoluntaryud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[lieuinhours] [bit] NULL,
[extendedprobationdateud] [datetime] NULL,
[includeinsir] [bit] NULL,
[nationalinsuranceno] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[includeinpayroll] [bit] NULL,
[includeinsspintegration] [bit] NULL,
[payrollrun] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[taxcode] [nvarchar] (5) COLLATE Latin1_General_BIN NULL,
[sspeligible] [bit] NULL,
[smpeligible] [bit] NULL,
[leaverreason] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[leaverreemploy] [bit] NULL,
[leavernotes] [nvarchar] (1000) COLLATE Latin1_General_BIN NULL,
[leavernoticedate] [datetime] NULL,
[wtdoptout] [bit] NULL,
[wtdoptoutdate] [datetime] NULL,
[pensiondateeligible] [datetime] NULL,
[pensiondatejoined] [datetime] NULL,
[absenceinhours] [bit] NULL,
[holidayinhours] [bit] NULL,
[maternitypayscheme] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[paternitypayscheme] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[adoptionpayscheme] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[deceased] [bit] NULL,
[suspended] [bit] NULL,
[carallowancescheme] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[excludefromtimeattendance] [bit] NULL,
[disabilityud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[sexualorientationud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[passportnumber] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[secondedfromeeacommcit] [bit] NULL,
[secondedepm6applies] [bit] NULL,
[secondedresidency] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[occupationalpensionamount] [numeric] (18, 6) NULL,
[occupationalpensionamountcurrency] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[occupationalpension] [bit] NULL,
[occupationalpensionbereaved] [bit] NULL,
[isabcmud] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[dss_start_date] [datetime] NULL,
[dss_end_date] [datetime] NULL,
[dss_current_flag] [char] (1) COLLATE Latin1_General_BIN NULL,
[dss_version] [int] NULL,
[dss_update_time] [datetime] NULL,
[weightmansstartdateud] [datetime] NULL
) ON [DS_TAB]
GO
CREATE NONCLUSTERED INDEX [ds_sh_employee_idx_2] ON [dbo].[ds_sh_employee] ([dss_current_flag]) INCLUDE ([employeeid], [displayemployeeid], [payrollid]) ON [DS_IDX]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ds_sh_employee_idx_A] ON [dbo].[ds_sh_employee] ([source_system_id], [employeeid], [dss_current_flag], [dss_version]) ON [DS_IDX]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ds_sh_employee_idx_SC] ON [dbo].[ds_sh_employee] ([source_system_id], [employeeid], [sequence], [displayemployeeid], [forename], [surname], [othername], [initials], [knownas], [title], [nationality], [ethnicorigin], [religion], [sex], [dss_current_flag], [dss_version]) ON [DS_IDX]
GO
CREATE NONCLUSTERED INDEX [ds_sh_employee_idx_1] ON [dbo].[ds_sh_employee] ([windowsusername], [dss_current_flag]) ON [DS_IDX]
GO
GRANT SELECT ON  [dbo].[ds_sh_employee] TO [db_ssrs_dynamicsecurity]
GO
DENY SELECT ON  [dbo].[ds_sh_employee] TO [DBDenySelect]
GO
DENY SELECT ON  [dbo].[ds_sh_employee] TO [lnksvrdatareader]
GO
DENY SELECT ON  [dbo].[ds_sh_employee] TO [lnksvrdatareader_artdb]
GO
GRANT SELECT ([emp_uid]) ON [dbo].[ds_sh_employee] TO [SBC\ewilli02]
GO
GRANT SELECT ([forename]) ON [dbo].[ds_sh_employee] TO [SBC\ewilli02]
GO
GRANT SELECT ([surname]) ON [dbo].[ds_sh_employee] TO [SBC\ewilli02]
GO
GRANT SELECT ([payrollid]) ON [dbo].[ds_sh_employee] TO [SBC\ewilli02]
GO
GRANT SELECT ON  [dbo].[ds_sh_employee] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01]
GO
DENY SELECT ON  [dbo].[ds_sh_employee] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited]
GO
DENY SELECT ([emp_uid]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([source_system_id]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([employeeid]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([sequence]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([displayemployeeid]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([forename]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([surname]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([othername]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([initials]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([knownas]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([title]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([nationality]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([ethnicorigin]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([religion]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([sex]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([dateofbirth]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([photofilename]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([securitylevel]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([employeestartdate]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([contservicedate]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([maritalstatus]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([payrollid]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([costcentre]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([dependants]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([disableddependants]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([sickpayscheme]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([leaverlastworkdate]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([leftdate]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([autocreateentitlements]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([driver]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([drivinglicenceno]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([companypension]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([workemail]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([workphone]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([ruid]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([employeedescnoid]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([employeedesc]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([sys_effectivedate]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([sys_modifiedby]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([sys_modifieddate]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([sys_requestid]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([windowsusername]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([previousname]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([namechangedate]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([psidud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([cpdstartud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([cpdpointsrequiredud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([leaver]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([workmobilephonenumber]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([workinternalnumberud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([rowidud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([probationenddateud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([probationcompletedud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([offermadeud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([dateofferedud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([voluntaryinvoluntaryud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([lieuinhours]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([extendedprobationdateud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([includeinsir]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([nationalinsuranceno]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([includeinpayroll]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([includeinsspintegration]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([payrollrun]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([taxcode]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([sspeligible]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([smpeligible]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([leaverreason]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([leaverreemploy]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([leavernotes]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([leavernoticedate]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([wtdoptout]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([wtdoptoutdate]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([pensiondateeligible]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([pensiondatejoined]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([absenceinhours]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([holidayinhours]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([maternitypayscheme]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([paternitypayscheme]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([adoptionpayscheme]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([deceased]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([suspended]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([carallowancescheme]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([excludefromtimeattendance]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([disabilityud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([sexualorientationud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([passportnumber]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([secondedfromeeacommcit]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([secondedepm6applies]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([secondedresidency]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([occupationalpensionamount]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([occupationalpensionamountcurrency]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([occupationalpension]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([occupationalpensionbereaved]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([isabcmud]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([dss_start_date]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([dss_end_date]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
GRANT SELECT ([dss_current_flag]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([dss_version]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
DENY SELECT ([dss_update_time]) ON [dbo].[ds_sh_employee] TO [SBC\SQL - DenyDataReader access to red_dw on SVR-LIV-DWH-01]
GO
EXEC sp_addextendedproperty N'Comment', N'This is the data store for the Cascade Employee Information table', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_employee', NULL, NULL
GO
EXEC sp_addextendedproperty N'Comment', N'Flag to indicate the current (latest) version of a business key.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_employee', 'COLUMN', N'dss_current_flag'
GO
EXEC sp_addextendedproperty N'Comment', N'Datetime a business key was retired.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_employee', 'COLUMN', N'dss_end_date'
GO
EXEC sp_addextendedproperty N'Comment', N'Datetime a business key was started.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_employee', 'COLUMN', N'dss_start_date'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_employee', 'COLUMN', N'dss_update_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Version number of a business key.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_employee', 'COLUMN', N'dss_version'
GO
EXEC sp_addextendedproperty N'Comment', N'Data warehouse internal source identifier', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_employee', 'COLUMN', N'source_system_id'
GO
