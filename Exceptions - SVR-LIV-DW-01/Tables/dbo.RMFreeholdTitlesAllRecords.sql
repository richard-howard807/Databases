CREATE TABLE [dbo].[RMFreeholdTitlesAllRecords]
(
[client] [char] (8) COLLATE Latin1_General_CI_AS NULL,
[matter] [char] (8) COLLATE Latin1_General_CI_AS NULL,
[case_id] [int] NOT NULL,
[TitleNumber] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Descriptionofproperty] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[ClassofTitle] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Currentproprietor] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Titlerestrictions] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Restrictivecovenantsbenefitting] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Restrictivecovenantsburdening] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Rightsbenefitting] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Rightsburdening] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Charges] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Notices] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Cautions] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Leasesregistered] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Easementsregistered] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Otherrelevantmatters] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Checks] [varchar] (27) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
