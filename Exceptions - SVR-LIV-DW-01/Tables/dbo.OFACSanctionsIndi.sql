CREATE TABLE [dbo].[OFACSanctionsIndi]
(
[sdnEntry_Id] [bigint] NULL,
[uid] [int] NULL,
[Name] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[FirstName] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Lastname] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[AliasName] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[AliasFirstName] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[AliasLastname] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Last Updated] [datetime] NULL,
[ListName] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[OFACDOB] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[SDN DOB] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
