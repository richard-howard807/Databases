CREATE TABLE [dbo].[TableauTableSSPolice]
(
[Client Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Client Name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Matter Description] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[Matter Owner] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Date Case Opened] [datetime] NULL,
[Date Case Closed] [datetime] NULL,
[Matter Type] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[Borough] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Source of Instruction] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Police Stations] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[FEE Eraner Code] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Matter Type Group] [nvarchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[Policing Priority] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Total Billed] [numeric] (13, 2) NULL,
[Revenue] [numeric] (13, 2) NULL,
[Disbursements] [numeric] (13, 2) NULL,
[Hours Recorded] [numeric] (17, 6) NULL,
[Financial Years] [varchar] (7) COLLATE Latin1_General_CI_AS NULL,
[Revenue 2016/2017] [numeric] (38, 2) NULL,
[Revenue 2017/2018] [numeric] (38, 2) NULL,
[Revenue 2018/2019] [numeric] (38, 2) NULL,
[Revenue 2019/2020] [numeric] (38, 2) NULL,
[Revenue 2020/2021] [numeric] (38, 2) NULL,
[Revenue 2021/2022] [numeric] (38, 2) NULL,
[Revenue 2022/2023] [numeric] (38, 2) NULL,
[Disbursements 2016/2017] [numeric] (38, 2) NULL,
[Disbursements 2017/2018] [numeric] (38, 2) NULL,
[Disbursements 2018/2019] [numeric] (38, 2) NULL,
[Disbursements 2019/2020] [numeric] (38, 2) NULL,
[Disbursements 2020/2021] [numeric] (38, 2) NULL,
[Disbursements 2021/2022] [numeric] (38, 2) NULL,
[Disbursements 2022/2023] [numeric] (38, 2) NULL,
[Total Costs 2016/2017] [numeric] (38, 2) NULL,
[Total Costs 2017/2018] [numeric] (38, 2) NULL,
[Total Costs 2018/2019] [numeric] (38, 2) NULL,
[Total Costs 2019/2020] [numeric] (38, 2) NULL,
[Total Costs 2020/2021] [numeric] (38, 2) NULL,
[Total Costs 2021/2022] [numeric] (38, 2) NULL,
[Total Costs 2022/2023] [numeric] (38, 2) NULL,
[Hours 2016/2017] [numeric] (38, 6) NULL,
[Hours 2017/2018] [numeric] (38, 6) NULL,
[Hours 2018/2019] [numeric] (38, 6) NULL,
[Hours 2019/2020] [numeric] (38, 6) NULL,
[Hours 2020/2021] [numeric] (38, 6) NULL,
[Hours 2021/2022] [numeric] (38, 6) NULL,
[Hours 2022/2023] [numeric] (38, 6) NULL,
[DVPO Victim Postcode] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Victim Postcode Latitude] [decimal] (8, 6) NULL,
[DVPO Victim Postcode Longitude] [decimal] (9, 6) NULL,
[DVPO Number of Children] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Division] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Granted?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Contested?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Breached?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO is First Breach?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Breach Admitted] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Breach Proved?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Breach Sentence] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Breach Sentence Length] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Legal Costs Sought?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Court Fee Awarded?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO Own Fees Awarded?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ClientOrder] [int] NULL
) ON [PRIMARY]
GO
