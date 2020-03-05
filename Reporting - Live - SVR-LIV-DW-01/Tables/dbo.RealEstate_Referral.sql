CREATE TABLE [dbo].[RealEstate_Referral]
(
[File Number] [nvarchar] (18) COLLATE Latin1_General_CI_AS NULL,
[DateofReferral] [datetime] NULL,
[Referrer] [nvarchar] (120) COLLATE Latin1_General_CI_AS NULL,
[Referree] [nvarchar] (120) COLLATE Latin1_General_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Comments] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[RealEstate_Referral] TO [ssrs_dynamicsecurity]
GO
