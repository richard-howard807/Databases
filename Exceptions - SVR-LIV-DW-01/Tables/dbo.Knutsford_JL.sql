CREATE TABLE [dbo].[Knutsford_JL]
(
[Claim Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ClientCode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[MatterNumber] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date Case Opened] [datetime] NULL,
[Date Case Closed] [datetime] NULL,
[Case Manager Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Team] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Postcode if not dealt with at Knutsford Office] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Worktype] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
