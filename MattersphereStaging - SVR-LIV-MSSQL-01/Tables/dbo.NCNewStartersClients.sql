CREATE TABLE [dbo].[NCNewStartersClients]
(
[clNo] [varchar] (max) COLLATE Latin1_General_CI_AS NULL,
[clName] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[cbopartner] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[addid] [int] NOT NULL,
[addLine1] [int] NULL,
[addLine2] [int] NULL,
[addLine3] [int] NULL,
[addLine4] [int] NULL,
[addLine5] [int] NULL,
[addPostCode] [int] NULL,
[addCountry] [int] NULL,
[addDXCode] [int] NULL,
[contType] [int] NULL,
[contSalut] [nvarchar] (106) COLLATE Latin1_General_CI_AS NULL,
[contTitle] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[contFirstNames] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[contSurname] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[Sex] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[contNotes] [int] NULL,
[contCreated] [int] NULL,
[contEmail] [int] NULL,
[contTelHome] [int] NULL,
[contTelWork] [int] NULL,
[contTelMob] [int] NULL,
[contFAX] [int] NULL,
[brID] [varchar] (2) COLLATE Latin1_General_CI_AS NOT NULL,
[contSubType] [varchar] (10) COLLATE Latin1_General_CI_AS NOT NULL,
[InsertDate] [datetime] NULL,
[Imported] [datetime] NULL,
[StatusID] [int] NOT NULL,
[error] [int] NULL,
[errormsg] [int] NULL,
[IsClient] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
