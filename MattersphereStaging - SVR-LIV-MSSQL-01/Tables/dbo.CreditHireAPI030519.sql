CREATE TABLE [dbo].[CreditHireAPI030519]
(
[fileID] [float] NULL,
[txtHireAgree] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtCHOPostcode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtCHORef] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[cboCHO] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[curDRClaimGross] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[curDRClaimNet] [float] NULL,
[curHireClaimed] [float] NULL,
[dteHireEndDate] [datetime] NULL,
[curHirePaid] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[dteHireStart] [datetime] NULL,
[curNoHireAgrmts] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[curWaivExtChged] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[txtCHOther] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
