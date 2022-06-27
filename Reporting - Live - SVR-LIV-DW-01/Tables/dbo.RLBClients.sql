CREATE TABLE [dbo].[RLBClients]
(
[clnum] [varchar] (14) COLLATE Latin1_General_CI_AS NULL,
[clname1] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[clind] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[clopendt] [datetime2] (3) NULL,
[claddr1] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[claddr2] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[claddr3] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[claddr4] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[claddr5] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[claddr6] [varchar] (60) COLLATE Latin1_General_CI_AS NULL,
[Postcode] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[clstatus] [varchar] (1) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
