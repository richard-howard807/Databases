CREATE TABLE [dbo].[Haven_JL]
(
[ClientAssociateRef] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Client Number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Group] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Category] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Handler] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Partner] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Our ref:] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[fileID] [float] NULL,
[Matter Description] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Damages Claim Portal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Referral Reason] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Fee Arrangement] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Motor Personal / Corporate] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date Report Due] [datetime] NULL,
[Send Client Care Letter?] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Number of Defendants] [float] NULL,
[Fixed Fee Amount] [money] NULL,
[Incident Date] [datetime] NULL,
[Date Instruction Received] [datetime] NULL,
[Date of Receipt of client's file of papers] [datetime] NULL
) ON [PRIMARY]
GO
