CREATE TABLE [dbo].[NHSRSelfService]
(
[MS Only] [bit] NULL,
[Weightmans Reference] [varchar] (17) COLLATE Latin1_General_BIN NULL,
[Client Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Mattersphere Client Code] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[Mattersphere Matter Number] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[Mattersphere Weightmans Reference] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[Matter Description] [varchar] (200) COLLATE Latin1_General_BIN NULL,
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
[Work Type] [char] (40) COLLATE Latin1_General_BIN NULL,
[Work Type Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Worktype Group] [varchar] (17) COLLATE Latin1_General_CI_AS NOT NULL,
[Claim status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Brief Details of Claim] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Comments] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ Date of notification to NHS R] [datetime] NULL,
[ Defendant Trust] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[NHS Location] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Scheme] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Speciality] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date damages cheque sent] [datetime] NULL,
[Date costs paid] [datetime] NULL,
[Who dealt with  costs?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Any publicity?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claim, novel, contentious, repercussive?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Estimated financial year of settlement] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[NHS Instruction type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Probability] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Risk management factor] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Share] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date expert report sent to client] [datetime] NULL,
[Date disclosure concluded] [datetime] NULL,
[Instruction Type] [char] (60) COLLATE Latin1_General_BIN NULL,
[Client Name] [char] (80) COLLATE Latin1_General_BIN NULL,
[Client Group Name] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[Client Sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[Client Segment ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Client Partner Name] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Insurer Client Reference FED] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insurer Name FED] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Clients Claim Handler ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Insured Client Reference FED] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insured Client Name FED] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insured Sector] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Insured Department] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Insured Department Depot Postcode] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date Case Opened] [datetime] NULL,
[Date Case Closed] [datetime] NULL,
[Converge Date Closed] [datetime] NULL,
[Present Position] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date Initial Report Sent] [datetime] NULL,
[Date Instructions Received] [datetime] NULL,
[Status On Instruction] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Referral Reason] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Proceedings Issued] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date Proceedings Issued] [datetime] NULL,
[Reason For Litigation] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Court Reference] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Court Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Track] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Suspicion of Fraud?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fraud Type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Credit Hire] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Credit Hire Organisation] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Credit Hire Organisation Detail] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Claimant Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Number of Claimants] [numeric] (13, 2) NULL,
[Number of Defendants ] [numeric] (13, 2) NULL,
[Does the Claimant have a PI Claim? ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Description of Injury] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Litigation / Regulatory] [varchar] (12) COLLATE Latin1_General_CI_AS NULL,
[Liability Issue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Delegated] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fixed Fee] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fixed Fee Amount] [numeric] (13, 2) NOT NULL,
[Fee Arrangement] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[Percentage Completion] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Linked File?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Lead Follow] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Lead File Matter Number] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Associated Matter Numbers] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MoJ stage] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Incident Date] [datetime] NULL,
[Incident Location] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Has the Claimant got a CFA? ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CFA entered into before 1 April 2013] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claimant's Solicitor] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claimant's Postcode] [char] (15) COLLATE Latin1_General_BIN NULL,
[Total Reserve] [numeric] (13, 2) NULL,
[Converge Disease Reserve] [numeric] (13, 2) NOT NULL,
[Damages Reserve (Initial)] [numeric] (13, 2) NULL,
[Damages Reserve Current ] [numeric] (13, 2) NULL,
[Hire Claimed ] [numeric] (13, 2) NULL,
[Claimant Costs Reserve Current (Initial)] [numeric] (13, 2) NULL,
[Claimant Costs Reserve Current ] [numeric] (13, 2) NULL,
[Defence Cost Reserve (Initial )] [numeric] (13, 2) NULL,
[Defence Costs Reserve Current] [numeric] (13, 2) NULL,
[Other Defendant's Costs Reserve (Net)] [numeric] (13, 2) NULL,
[Disease Total Estimated Settlement Value ] [numeric] (13, 2) NULL,
[Outcome of Case] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Percent of Clients Liability Agreed/Awarded] [numeric] (13, 2) NULL,
[Percent Estimate of Reduction for Litigation Risk] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Settlement basis] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date of Trial] [datetime] NULL,
[Date Claim Concluded] [datetime] NULL,
[Interim Damages] [numeric] (13, 2) NULL,
[Damages Paid by Client ] [numeric] (15, 2) NULL,
[Outsource Damages Paid (WPS278+WPS279+WPS281)] [numeric] (13, 2) NULL,
[Personal Injury Paid] [numeric] (13, 2) NULL,
[Hire Paid ] [numeric] (13, 2) NULL,
[Damages Paid (all parties) - Disease] [numeric] (31, 16) NULL,
[Date Referral to Costs Unit] [datetime] NULL,
[Date Claimants Costs Received] [datetime] NULL,
[Date Costs Settled] [datetime] NULL,
[Date Settlement form Sent to Zurich WPS386 VE00571] [datetime] NULL,
[Interim Costs Payments] [numeric] (13, 2) NULL,
[Total third party costs claimed (the sum of TRA094+NMI599+NMI600)] [numeric] (13, 2) NULL,
[Total third party costs paid (sum of TRA072+NMI143+NMI379)] [numeric] (13, 2) NULL,
[Claimants Total Costs Claimed against Client] [numeric] (13, 2) NULL,
[Claimant's Costs Paid by Client - Disease] [numeric] (13, 2) NULL,
[Outsource Claimants Costs] [numeric] (13, 2) NULL,
[Detailed Assessment Costs Claimed by Claimant] [numeric] (13, 2) NULL,
[Detailed Assessment Costs Paid] [numeric] (13, 2) NULL,
[Costs Claimed by another Defendant] [numeric] (13, 2) NULL,
[Costs Paid to Another Defendant] [numeric] (13, 2) NULL,
[Claimants Total Costs Paid by All Parties] [numeric] (13, 2) NOT NULL,
[Are we pursuing a recovery?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Total Recovery (NMI112,NMI135,NMI136,NMI137)] [numeric] (13, 2) NULL,
[Outsource Recovery Paid] [numeric] (13, 2) NULL,
[Total Bill Amount - Composite (IncVAT )] [numeric] (16, 2) NULL,
[Revenue Costs Billed] [numeric] (13, 2) NULL,
[Disbursements Billed ] [numeric] (16, 2) NULL,
[VAT Billed] [numeric] (13, 2) NULL,
[WIP] [numeric] (13, 2) NULL,
[Unbilled Disbursements] [numeric] (13, 2) NULL,
[Client Account Balance of Matter] [numeric] (13, 2) NULL,
[Unpaid Bill Balance] [numeric] (13, 2) NULL,
[Last Bill Date] [datetime] NULL,
[Last Bill Date Composite ] [datetime] NULL,
[Date of Last Time Posting] [datetime] NULL,
[Hours Recorded] [numeric] (38, 6) NULL,
[Minutes Recorded] [numeric] (38, 2) NULL,
[Legal Spend exc (VAT)] [numeric] (38, 6) NULL,
[Time Billed] [numeric] (17, 6) NULL,
[Total Non-Partner Hours Recorded] [numeric] (38, 6) NULL,
[Total Partner Hours Recorded] [numeric] (38, 6) NULL,
[Total Associate Hours Recorded] [numeric] (38, 6) NULL,
[Total Other Hours Recorded] [numeric] (38, 6) NULL,
[Total Paralegal Hours Recorded] [numeric] (38, 6) NULL,
[Total Partner/Consultant Hours Recorded] [numeric] (38, 6) NULL,
[Total Solicitor/LegalExec Hours Recorded] [numeric] (38, 6) NULL,
[Total Trainee Hours Recorded] [numeric] (38, 6) NULL,
[Damages Banding] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Elapsed Days Live Files] [int] NULL,
[Elapsed Days to Costs Settlement] [int] NULL,
[Elapsed Days to Damages Concluded] [int] NULL,
[Current Costs Estimate] [numeric] (13, 2) NULL,
[Recovery Claimants Damages Via Third Party Contribution] [numeric] (13, 2) NULL,
[Recovery Defence Costs From Claimant ] [numeric] (13, 2) NULL,
[Recovery Claimants via Third Party Contribution ] [numeric] (13, 2) NULL,
[Defence Costs via Third Party Contribution] [numeric] (13, 2) NULL,
[Insured Client Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Annual PP (PPO)] [numeric] (13, 2) NULL,
[Capped fee] [numeric] (13, 2) NULL,
[Damages Tranche] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date of instruction of expert for schedule 1 & 2] [datetime] NULL,
[Date final bill sent to client] [datetime] NULL,
[Expected settlement date] [datetime] NULL,
[GD reserve] [numeric] (13, 2) NULL,
[Initial meaningful GD reserve] [numeric] (13, 2) NULL,
[Initial meaningful SD reserve] [numeric] (13, 2) NULL,
[Overall reserve] [numeric] (13, 2) NULL,
[Prospects of success ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Reason for trIal] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Recommended to proceed to trial] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Retained Lump sum amount (PPO)] [numeric] (13, 2) NULL,
[SD reserve] [numeric] (13, 2) NULL,
[Stage of settlement] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Type of instruction - billing] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Is this a PPO matter? ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DA success] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DA date] [datetime] NULL,
[Recommended to proceed to DA] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[update_time] [datetime] NOT NULL,
[Revenue 2015/2016] [numeric] (38, 2) NULL,
[Revenue 2016/2017] [numeric] (38, 2) NULL,
[Revenue 2017/2018] [numeric] (38, 2) NULL,
[Revenue 2018/2019] [numeric] (38, 2) NULL,
[Revenue 2019/2020] [numeric] (38, 2) NULL,
[Revenue 2020/2021] [numeric] (38, 2) NULL,
[Hours Billed 2015/2016] [numeric] (38, 5) NULL,
[Hours Billed 2016/2017] [numeric] (38, 5) NULL,
[Hours Billed 2017/2018] [numeric] (38, 5) NULL,
[Hours Billed 2018/2019] [numeric] (38, 5) NULL,
[Hours Billed 2019/2020] [numeric] (38, 5) NULL,
[Hours Billed 2020/2021] [numeric] (38, 5) NULL,
[Chargeable Hours Posted 2015/2016] [numeric] (38, 2) NULL,
[Chargeable Hours Posted 2016/2017] [numeric] (38, 2) NULL,
[Chargeable Hours Posted 2017/2018] [numeric] (38, 2) NULL,
[Chargeable Hours Posted 2018/2019] [numeric] (38, 2) NULL,
[Chargeable Hours Posted 2019/2020] [numeric] (38, 2) NULL,
[Chargeable Hours Posted 2020/2021] [numeric] (38, 2) NULL,
[Disbursements Billed 2015/2016] [numeric] (38, 5) NULL,
[Disbursements Billed 2016/2017] [numeric] (38, 5) NULL,
[Disbursements Billed 2017/2018] [numeric] (38, 5) NULL,
[Disbursements Billed 2018/2019] [numeric] (38, 5) NULL,
[Disbursements Billed 2019/2020] [numeric] (38, 5) NULL,
[Disbursements Billed 2020/2021] [numeric] (38, 5) NULL,
[reporting_exclusions] [bit] NULL
) ON [PRIMARY]
GO
