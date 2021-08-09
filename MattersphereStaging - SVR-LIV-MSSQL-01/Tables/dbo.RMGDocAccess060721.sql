CREATE TABLE [dbo].[RMGDocAccess060721]
(
[FileID] [float] NULL,
[MSOnly] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Client Code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Number ] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Matter Description ] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Pay Number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Primary Case Classification] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date Opened] [datetime] NULL,
[Date Closed] [datetime] NULL,
[Case Manager] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Team] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[RMG Instruction Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Actual Compensation ] [money] NULL,
[Date Claim Concluded ] [datetime] NULL,
[WIP Amt] [money] NULL,
[WIP Hrs] [money] NULL
) ON [PRIMARY]
GO
