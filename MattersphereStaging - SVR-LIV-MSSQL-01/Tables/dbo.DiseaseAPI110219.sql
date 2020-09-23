CREATE TABLE [dbo].[DiseaseAPI110219]
(
[MSFilEID] [float] NULL,
[cboReasLeftPort] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cboReasReop] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cboSingleMulti] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cboWeiCourtRec] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cboCliReferral] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cboShouldMOJPor] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cboZurichAParty] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtAudiolName] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtCaseHaRevCom] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[dteCaseHandRev] [datetime] NULL,
[dteDateOfReport] [datetime] NULL,
[dteExam] [datetime] NULL,
[txtLocOfExam] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtLossClaimAud] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtLossRepAudio] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[curNoMedReps] [float] NULL,
[txtCalcDBAudio] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[curDBLossOver] [float] NULL,
[txtDBRepAud] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtSuperComm] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[dteSuperRev] [datetime] NULL,
[txtDropPortal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[dteRequestedAud] [datetime] NULL
) ON [PRIMARY]
GO
