CREATE TABLE [dbo].[Request10676]
(
[MS Client] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[MS Matter] [nvarchar] (20) COLLATE Latin1_General_CI_AS NOT NULL,
[FED Client] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[FED Matter] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Old Fee Earner] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[New Fee Earner] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[New Case Assistant] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[New BCM] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[New Partner] [varchar] (4) COLLATE Latin1_General_CI_AS NOT NULL,
[TicketNumber] [int] NULL
) ON [PRIMARY]
GO
