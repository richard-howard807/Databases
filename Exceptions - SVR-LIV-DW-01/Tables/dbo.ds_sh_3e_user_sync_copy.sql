CREATE TABLE [dbo].[ds_sh_3e_user_sync_copy]
(
[timekeeperindex] [int] NULL,
[Entity] [int] NULL,
[TRE_User] [uniqueidentifier] NULL,
[payrollid] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[firstname] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[surname] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[knownas] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[name] [nvarchar] (101) COLLATE Latin1_General_CI_AS NULL,
[DOB] [datetime] NULL,
[prefix] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[gender] [varchar] (6) COLLATE Latin1_General_CI_AS NOT NULL,
[email] [nvarchar] (320) COLLATE Latin1_General_CI_AS NULL,
[phonenumber] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[username] [nvarchar] (54) COLLATE Latin1_General_CI_AS NULL,
[startdate] [datetime] NULL,
[office] [nvarchar] (16) COLLATE Latin1_General_CI_AS NULL,
[officename] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[address] [int] NULL,
[sitetype] [nvarchar] (16) COLLATE Latin1_General_CI_AS NULL,
[businessline] [nvarchar] (16) COLLATE Latin1_General_CI_AS NULL,
[team] [nvarchar] (16) COLLATE Latin1_General_CI_AS NULL,
[jobrole] [nvarchar] (16) COLLATE Latin1_General_CI_AS NULL,
[hrtitle] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[payrollid_BCM] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[ratetype] [varchar] (6) COLLATE Latin1_General_CI_AS NOT NULL,
[defaultrate] [int] NOT NULL,
[tkrtype] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[userstatusid] [int] NULL,
[userstatus] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[leaverdate] [datetime] NULL,
[dss_update_time] [datetime] NULL
) ON [PRIMARY]
GO
