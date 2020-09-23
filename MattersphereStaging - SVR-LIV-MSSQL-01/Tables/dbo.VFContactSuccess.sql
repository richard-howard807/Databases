CREATE TABLE [dbo].[VFContactSuccess]
(
[ID] [int] NOT NULL,
[extContID] [nvarchar] (20) COLLATE Latin1_General_CI_AS NULL,
[clNo] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[clName] [nvarchar] (80) COLLATE Latin1_General_CI_AS NOT NULL,
[cbocligrp] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[cbopartner] [bigint] NULL,
[addid] [bigint] NULL,
[addLine1] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[addLine2] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[addLine3] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[addLine4] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[addLine5] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[addPostCode] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[addCountry] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[addDXCode] [nvarchar] (80) COLLATE Latin1_General_CI_AS NULL,
[contType] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[contSalut] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[contTitle] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[contFirstNames] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[contSurname] [nvarchar] (60) COLLATE Latin1_General_CI_AS NULL,
[contSex] [nchar] (1) COLLATE Latin1_General_CI_AS NULL,
[contNotes] [nvarchar] (1000) COLLATE Latin1_General_CI_AS NULL,
[contCreated] [datetime] NULL,
[contEmail] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[contTelHome] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[contTelWork] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[contTelMob] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[contFAX] [nvarchar] (30) COLLATE Latin1_General_CI_AS NULL,
[brID] [int] NULL,
[contSubType] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[InsertDate] [datetime] NOT NULL,
[Imported] [datetime] NULL,
[StatusID] [tinyint] NOT NULL,
[error] [int] NULL,
[errormsg] [varchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[IsClient] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[NewClientID] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[clType] AS (case  when upper([contSubType])='INDIVIDUAL' then (1) when upper([contSubType])='ORGANISATION' then (2) end),
[NewContactID] [bigint] NULL,
[contAddressee] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[VFileEntityCode] [varchar] (10) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
