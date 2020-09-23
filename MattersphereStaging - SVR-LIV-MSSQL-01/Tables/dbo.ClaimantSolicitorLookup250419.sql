CREATE TABLE [dbo].[ClaimantSolicitorLookup250419]
(
[Claimant's Solicitor Associate] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tidied Version] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[ClaimantSolicitorLookup250419] TO [lnksvrdatareader_dw01]
GO
GRANT SELECT ON  [dbo].[ClaimantSolicitorLookup250419] TO [lnksvrreader_DWH-01]
GO
