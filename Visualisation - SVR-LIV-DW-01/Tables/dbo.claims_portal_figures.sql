CREATE TABLE [dbo].[claims_portal_figures]
(
[Month] [datetime] NULL,
[claim_type] [varchar] (7) COLLATE Latin1_General_CI_AS NULL,
[general_damages] [money] NULL,
[cnf_volumns] [float] NULL,
[update_time] [datetime] NULL
) ON [PRIMARY]
GO
