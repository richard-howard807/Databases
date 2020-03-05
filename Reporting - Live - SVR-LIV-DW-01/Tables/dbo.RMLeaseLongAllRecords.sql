CREATE TABLE [dbo].[RMLeaseLongAllRecords]
(
[client] [char] (8) COLLATE Latin1_General_CI_AS NULL,
[matter] [char] (8) COLLATE Latin1_General_CI_AS NULL,
[case_id] [int] NOT NULL,
[TitleNumber] [char] (60) COLLATE Latin1_General_CI_AS NULL,
[DemisedPremisis] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Date] [datetime] NULL,
[Originallandlord] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Originaltenant] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Term] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Groundrent] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[RentReview] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Servicechargepayable] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Insuranceeffectedby] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Repairobligation] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Decorationobligation] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Assignment] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Underlet] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Usepermitted] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[Structuralandexternal1] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Structuralandexternal2] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Internal1] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Internal2] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Groundsandforfeiture1] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Groundsandforfeiture2] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Otherrelevantleaseterms] [nvarchar] (max) COLLATE Latin1_General_CI_AS NOT NULL,
[PRO953] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[PRO954] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[PRO983] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[PRO955] [varchar] (60) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
