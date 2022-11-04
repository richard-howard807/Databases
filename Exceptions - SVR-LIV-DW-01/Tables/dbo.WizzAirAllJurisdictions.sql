CREATE TABLE [dbo].[WizzAirAllJurisdictions]
(
[Nr#] [float] NULL,
[Country] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Year and Quarter ] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Claim number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Nr of PAX] [float] NULL,
[AOC] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Flight number] [float] NULL,
[Operation (Original) day] [datetime] NULL,
[Original Departure AP] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Actual Departure AP] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Original Arrival AP] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Actual Arrival AP] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[DHC/DLC] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Main Reason] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Comments (if any)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[OTA involved (1/0)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Claim farm (1/0)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Withdrawn (1/0)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Admitted/immediate payment (1/0)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Defended and Won (1/0)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Settled (1/0)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Defended and lost (1/0)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Default judgement] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Appealed by Wizz] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Appealed by Claimant] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Reason for loosing] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Comment (if any)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Own attorney fee (EUR)] [float] NULL,
[Other expenses (EUR)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Claimed amount (EUR)] [float] NULL,
[Rendered amount (without interest, EUR)] [float] NULL,
[EU261 (EUR)] [float] NULL,
[Refund (EUR)] [float] NULL,
[Other claims (EUR)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Litigation cost (EUR)] [float] NULL
) ON [PRIMARY]
GO