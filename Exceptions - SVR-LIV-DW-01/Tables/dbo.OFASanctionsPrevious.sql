CREATE TABLE [dbo].[OFASanctionsPrevious]
(
[SanctionNam] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[MatchedClientName] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[ClientNumber] [nvarchar] (8) COLLATE Latin1_General_CI_AS NULL,
[Matches] [varchar] (14) COLLATE Latin1_General_CI_AS NOT NULL,
[No Possible Matches] [int] NOT NULL,
[Number] [int] NOT NULL,
[ClientName] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[Capacity] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Systems] [varchar] (12) COLLATE Latin1_General_CI_AS NOT NULL,
[Weightmans Ref] [varchar] (131) COLLATE Latin1_General_CI_AS NULL,
[Address1] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Address2] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Address3] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Address4] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[Postcode] [varchar] (50) COLLATE Latin1_General_CI_AS NULL,
[uid] [int] NULL,
[Last Updated] [datetime] NULL,
[DateClosed] [datetime] NULL,
[Client Balance] [numeric] (13, 2) NOT NULL,
[SourceID] [int] NOT NULL,
[CaseID] [varchar] (100) COLLATE Latin1_General_CI_AS NULL,
[Is this a Linked File] [char] (60) COLLATE Latin1_General_BIN NULL,
[Linked Case] [char] (60) COLLATE Latin1_General_BIN NULL,
[Date of birth] [datetime] NULL,
[Was DoB obtained?] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Reviewed file against Sanctions list] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Date Sanctions list reviewed] [datetime] NULL,
[Re-Check Needed] [int] NOT NULL,
[AmberCheck] [int] NOT NULL,
[ExtraRed] [int] NOT NULL,
[Sanction Name] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[OFACDOB] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[SDN DOB] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[InsertDate] [datetime] NOT NULL
) ON [PRIMARY]
GO