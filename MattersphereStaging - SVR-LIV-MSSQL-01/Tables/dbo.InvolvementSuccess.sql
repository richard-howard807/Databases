CREATE TABLE [dbo].[InvolvementSuccess]
(
[ID] [int] NOT NULL,
[FEDClient] [varchar] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[FEDMatter] [varchar] (8) COLLATE Latin1_General_CI_AS NOT NULL,
[MSClientID] [bigint] NOT NULL,
[MSFileID] [nvarchar] (20) COLLATE Latin1_General_CI_AS NULL,
[FileID] [bigint] NOT NULL,
[contID] [bigint] NULL,
[assocOrder] [smallint] NOT NULL,
[assocType] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[assocHeading] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[assocdefaultaddID] [bigint] NULL,
[assocSalut] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[assocRef] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[assocUseDX] [bit] NOT NULL,
[AuditID] [int] NULL,
[InsertDate] [datetime] NOT NULL,
[StatusID] [tinyint] NOT NULL,
[error] [int] NULL,
[errormsg] [nvarchar] (2000) COLLATE Latin1_General_CI_AS NULL,
[AssocDIWOR] [int] NULL
) ON [PRIMARY]
GO
