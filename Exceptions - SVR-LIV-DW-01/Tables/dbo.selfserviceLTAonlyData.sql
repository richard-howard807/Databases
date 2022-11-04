CREATE TABLE [dbo].[selfserviceLTAonlyData]
(
[Date Case Opened] [datetime] NULL,
[Date Case Closed] [datetime] NULL,
[MS Only] [bit] NULL,
[Weightmans Reference] [varchar] (17) COLLATE Latin1_General_BIN NULL,
[Client Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Mattersphere Client Code] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[Mattersphere Matter Number] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[Mattersphere Weightmans Reference] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[Matter Description] [varchar] (300) COLLATE Latin1_General_BIN NULL,
[Case Manager Name] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Case Manager] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Grade] [nvarchar] (200) COLLATE Latin1_General_BIN NULL,
[Leaver?] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Team Manager] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[BCM Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Office] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Department] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Department Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Division] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Matter Type] [char] (40) COLLATE Latin1_General_BIN NULL,
[Matter Type Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Type Group] [varchar] (17) COLLATE Latin1_General_CI_AS NOT NULL,
[Instruction Type] [char] (60) COLLATE Latin1_General_BIN NULL,
[Client Name] [char] (80) COLLATE Latin1_General_BIN NULL,
[Client Group Name] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[Client Name combined ] [varchar] (80) COLLATE Latin1_General_BIN NULL,
[Client Sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[Client Segment ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Client Partner Name] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Client Type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Outcome] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Repudiated/Paid ] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[Date Initial Report Sent] [datetime] NULL,
[Date Instructions Received] [datetime] NULL,
[Commercial BL Status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fixed Fee] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fixed Fee Amount] [numeric] (13, 2) NOT NULL,
[Fee Arrangement] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[Percentage Completion] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Total Bill Amount - Composite (IncVAT )] [numeric] (16, 2) NULL,
[Claimants Representative ] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Revenue Costs Billed] [numeric] (13, 2) NULL,
[Disbursements Billed ] [numeric] (16, 2) NULL,
[VAT Billed] [numeric] (13, 2) NULL,
[WIP] [numeric] (13, 2) NULL,
[Unbilled Disbursements] [numeric] (13, 2) NULL,
[Total Disbs Budget Agreed/Recorded] [numeric] (13, 2) NULL,
[Total profit costs agreed/recorded] [numeric] (13, 2) NULL,
[Client Account Balance of Matter] [numeric] (13, 2) NULL,
[Unpaid Bill Balance] [numeric] (13, 2) NULL,
[Last Bill Date] [datetime] NULL,
[Last Bill Date Composite ] [datetime] NULL,
[Date of Last Time Posting] [datetime] NULL,
[Hours Recorded] [numeric] (38, 6) NULL,
[Minutes Recorded] [numeric] (38, 2) NULL,
[Legal Spend exc (VAT)] [numeric] (38, 6) NULL,
[Time Billed] [numeric] (17, 6) NULL,
[Hours Billed to Client] [numeric] (38, 6) NULL,
[Revenue 2015/2016] [numeric] (38, 5) NULL,
[Revenue 2016/2017] [numeric] (38, 5) NULL,
[Revenue 2017/2018] [numeric] (38, 5) NULL,
[Revenue 2018/2019] [numeric] (38, 5) NULL,
[Revenue 2019/2020] [numeric] (38, 5) NULL,
[Hours Billed 2015/2016] [numeric] (38, 5) NULL,
[Hours Billed 2016/2017] [numeric] (38, 5) NULL,
[Hours Billed 2017/2018] [numeric] (38, 5) NULL,
[Hours Billed 2018/2019] [numeric] (38, 5) NULL,
[Hours Billed 2019/2020] [numeric] (38, 5) NULL,
[Total Non-Partner Hours Recorded] [numeric] (38, 6) NULL,
[Total Partner Hours Recorded] [numeric] (38, 6) NULL,
[Total Associate Hours Recorded] [numeric] (38, 6) NULL,
[Total Other Hours Recorded] [numeric] (38, 6) NULL,
[Total Paralegal Hours Recorded] [numeric] (38, 6) NULL,
[Total Partner/Consultant Hours Recorded] [numeric] (38, 6) NULL,
[Total Solicitor/LegalExec Hours Recorded] [numeric] (38, 6) NULL,
[Total Trainee Hours Recorded] [numeric] (38, 6) NULL,
[Current Costs Estimate] [numeric] (13, 2) NULL,
[revenue_and_disb_estimate_net_of_vat] [numeric] (13, 2) NULL,
[revenue_estimate_net_of_vat] [numeric] (13, 2) NULL,
[disbursements_estimate_net_of_vat] [numeric] (13, 2) NULL,
[International elements] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Billing Arrangement] [nvarchar] (64) COLLATE Latin1_General_BIN NULL,
[update_time] [datetime] NOT NULL
) ON [PRIMARY]
GO