CREATE TABLE [dbo].[selfservice]
(
[ms_fileid] [bigint] NULL,
[Date Case Opened] [datetime] NULL,
[Fin Year Opened] [int] NULL,
[Date Case Closed] [datetime] NULL,
[Fin Year Closed] [int] NULL,
[MS Only] [bit] NULL,
[Weightmans Reference] [varchar] (17) COLLATE Latin1_General_BIN NULL,
[Client Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Mattersphere Client Code] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[Mattersphere Matter Number] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[Mattersphere Weightmans Reference] [nvarchar] (4000) COLLATE Latin1_General_BIN NULL,
[Matter Description] [varchar] (300) COLLATE Latin1_General_BIN NULL,
[Case Manager] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Matter Owner Full Name] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Matter Partner] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
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
[work_type_group] [char] (40) COLLATE Latin1_General_BIN NULL,
[Matter Group] [nvarchar] (255) COLLATE Latin1_General_CI_AS NOT NULL,
[Instruction Type] [char] (60) COLLATE Latin1_General_BIN NULL,
[Client Name] [char] (80) COLLATE Latin1_General_BIN NULL,
[Client Group Name] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[Client Name combined ] [varchar] (80) COLLATE Latin1_General_BIN NULL,
[Client Sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[Client Sub-Sector] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Client Segment ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Client Partner Name] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Client Type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Insurer Client Reference FED] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insurer Name FED] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Clients Claim Handler ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Insured Client Reference] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insured Client Name (Associate)] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insured Client Name (Data Services)] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Insured Sector] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Insured Department] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Insured Department Depot Postcode] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Converge Date Closed] [datetime] NULL,
[Present Position] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Converge Claim Status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
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
[fic_score] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Total FIC Point Calc] [float] NULL,
[Credit Hire] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Credit Hire Organisation] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Credit Hire Org HF] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Credit Hire Organisation Detail] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Brief Details of Claim] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claimant Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Number of Claimants] [numeric] (13, 2) NULL,
[Defendant Name] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Number of Defendants ] [numeric] (13, 2) NULL,
[Does the Claimant have a PI Claim? ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Description of Injury] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claimant's medical expert] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Litigation / Regulatory] [varchar] (12) COLLATE Latin1_General_CI_AS NULL,
[Liability Issue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Delegated] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fixed Fee] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fixed Fee Amount] [numeric] (13, 2) NOT NULL,
[Fee Arrangement] [varchar] (255) COLLATE Latin1_General_BIN NULL,
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
[Method of claimants funding] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claimant's Solicitor (Data Service)] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claimant's Solicitor] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Claimants Representative] [varchar] (131) COLLATE Latin1_General_BIN NULL,
[Claimant's Postcode] [char] (15) COLLATE Latin1_General_BIN NULL,
[Total Reserve Calc] [numeric] (13, 2) NULL,
[total_current_reserve] [money] NULL,
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
[AXA Claim Strategy] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Outcome of Case] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Repudiated/Paid ] [varchar] (10) COLLATE Latin1_General_CI_AS NULL,
[Settlement basis] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date of first day of trial window] [datetime] NULL,
[Date of Trial] [datetime] NULL,
[Date Claim Concluded] [datetime] NULL,
[Fin Year Claim Concluded] [int] NULL,
[Date "Date Claim Concluded" Last Changed] [datetime] NULL,
[Interim Damages] [numeric] (13, 2) NULL,
[Damages Paid by Client ] [numeric] (15, 2) NULL,
[Outsource Damages Paid (WPS278+WPS279+WPS281)] [numeric] (13, 2) NULL,
[Personal Injury Paid] [numeric] (13, 2) NULL,
[Hire Paid ] [numeric] (13, 2) NULL,
[Damages Paid (all parties) - Disease] [numeric] (31, 16) NULL,
[Date Referral to Costs Unit] [datetime] NULL,
[Date Claimants Costs Received] [datetime] NULL,
[Date Costs Settled] [datetime] NULL,
[Fin Year Costs Settled] [int] NULL,
[Date Settlement form Sent to Zurich WPS386 VE00571] [datetime] NULL,
[Interim Costs Payments] [numeric] (13, 2) NULL,
[Total third party costs claimed (the sum of TRA094+NMI599+NMI600)] [numeric] (13, 2) NULL,
[Total third party costs paid (sum of TRA072+NMI143+NMI379)] [numeric] (13, 2) NULL,
[Ate Premimum Claimed] [numeric] (13, 2) NULL,
[Ate Premimum Paid] [numeric] (13, 2) NULL,
[Claimants Total Costs Claimed against Client] [numeric] (13, 2) NULL,
[Claimant's Costs Paid by Client - Disease] [numeric] (13, 2) NULL,
[Claimant’s Solicitor’s Base Costs Claimed + VAT] [numeric] (13, 2) NULL,
[Claimant’s Solicitor’s Disbursements Claimed] [numeric] (13, 2) NULL,
[Claimant’s Solicitor’s Base Costs Paid + VAT] [numeric] (13, 2) NULL,
[Claimant’s Solicitor’s Disbursements paid] [numeric] (13, 2) NULL,
[Costs Outcome] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Outsource Claimants Costs] [numeric] (13, 2) NULL,
[Detailed Assessment Costs Claimed by Claimant] [numeric] (13, 2) NULL,
[Detailed Assessment Costs Paid] [numeric] (13, 2) NULL,
[Costs Claimed by another Defendant] [numeric] (13, 2) NULL,
[Costs Paid to Another Defendant] [numeric] (13, 2) NULL,
[Claimants Total Costs Paid by All Parties] [numeric] (13, 2) NOT NULL,
[Are we pursuing a recovery?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Total Recovery (NMI112,NMI135,NMI136,NMI137)] [numeric] (13, 2) NULL,
[Outsource Recovery Paid] [numeric] (13, 2) NULL,
[Total Bill Amount - Composite (IncVAT )] [numeric] (13, 2) NULL,
[Revenue Costs Billed] [numeric] (13, 2) NULL,
[Disbursements Billed ] [numeric] (13, 2) NULL,
[VAT Billed] [numeric] (13, 2) NULL,
[WIP] [numeric] (13, 2) NULL,
[Unbilled Disbursements] [numeric] (13, 2) NULL,
[Revenue Estimate net of VAT] [numeric] (13, 2) NULL,
[Disbursements net of VAT] [numeric] (13, 2) NULL,
[Total Disbs Budget Agreed/Recorded] [numeric] (13, 2) NULL,
[Total profit costs agreed/recorded] [numeric] (13, 2) NULL,
[Client Account Balance of Matter] [numeric] (13, 2) NULL,
[Unpaid Bill Balance] [numeric] (13, 2) NULL,
[Last Bill Date] [datetime] NULL,
[Last Bill Date Composite ] [datetime] NULL,
[Fin Year Of Last Bill] [int] NULL,
[Date of Last Time Posting] [datetime] NULL,
[Fin Year Of Last Time Posting] [int] NULL,
[Hours Recorded] [numeric] (38, 6) NULL,
[Minutes Recorded] [numeric] (38, 2) NULL,
[Legal Spend exc (VAT)] [numeric] (38, 2) NULL,
[Time Billed] [numeric] (17, 6) NULL,
[Hours Billed To Client] [numeric] (38, 6) NULL,
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
[Initial Costs Estimate] [numeric] (13, 2) NULL,
[Current Costs Estimate] [numeric] (13, 2) NULL,
[revenue_and_disb_estimate_net_of_vat] [numeric] (13, 2) NULL,
[revenue_estimate_net_of_vat] [numeric] (13, 2) NULL,
[disbursements_estimate_net_of_vat] [numeric] (13, 2) NULL,
[Recovery Claimants Damages Via Third Party Contribution] [numeric] (13, 2) NULL,
[Recovery Defence Costs From Claimant ] [numeric] (13, 2) NULL,
[Recovery Claimants via Third Party Contribution ] [numeric] (13, 2) NULL,
[Defence Costs via Third Party Contribution] [numeric] (13, 2) NULL,
[Insured Client Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Commerical BI Status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Broker Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[TP Account Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Third party storage and recovery company] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[update_time] [datetime] NOT NULL,
[Revenue 2017/2018] [numeric] (38, 2) NULL,
[Revenue 2018/2019] [numeric] (38, 2) NULL,
[Revenue 2019/2020] [numeric] (38, 2) NULL,
[Revenue 2020/2021] [numeric] (38, 2) NULL,
[Revenue 2021/2022] [numeric] (38, 2) NULL,
[Revenue 2022/2023] [numeric] (38, 2) NULL,
[Hours Billed 2017/2018] [numeric] (38, 6) NULL,
[Hours Billed 2018/2019] [numeric] (38, 6) NULL,
[Hours Billed 2019/2020] [numeric] (38, 6) NULL,
[Hours Billed 2020/2021] [numeric] (38, 6) NULL,
[Hours Billed 2021/2022] [numeric] (38, 6) NULL,
[Hours Billed 2022/2023] [numeric] (38, 6) NULL,
[Chargeable Hours Posted 2017/2018] [numeric] (38, 2) NULL,
[Chargeable Hours Posted 2018/2019] [numeric] (38, 2) NULL,
[Chargeable Hours Posted 2019/2020] [numeric] (38, 2) NULL,
[Chargeable Hours Posted 2020/2021] [numeric] (38, 2) NULL,
[Chargeable Hours Posted 2021/2022] [numeric] (38, 2) NULL,
[Chargeable Hours Posted 2022/2023] [numeric] (38, 2) NULL,
[Disbursements Billed 2017/2018] [numeric] (38, 5) NULL,
[Disbursements Billed 2018/2019] [numeric] (38, 5) NULL,
[Disbursements Billed 2019/2020] [numeric] (38, 5) NULL,
[Disbursements Billed 2020/2021] [numeric] (38, 5) NULL,
[Disbursements Billed 2021/2022] [numeric] (38, 5) NULL,
[Disbursements Billed 2022/2023] [numeric] (38, 5) NULL,
[STW Work Type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[minutes_recorded_cost_handler] [numeric] (13, 2) NULL,
[time_charge_value_cost_handler] [numeric] (13, 2) NULL,
[cost_handler_revenue] [numeric] (38, 2) NULL,
[Client Ref] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[date_recovery_concluded] [datetime] NULL,
[Counsel Fees Billed ex VAT] [numeric] (38, 5) NULL,
[Counsel Fees Billed inc VAT] [numeric] (38, 5) NULL,
[Date of receipt of clients file of papers] [datetime] NULL,
[Do clients require an initial report] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[Date initial report sent] [datetime] NULL,
[[Date_initial_report_due] [datetime] NULL,
[Have we had an extension for the initial report] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Final Bill Date] [datetime] NULL,
[latest_archive_date] [datetime] NULL,
[latest_archive_status] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[latest_archive_type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Trust Type of Instruction] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Covid Reason] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Covid Other] [bit] NULL,
[Acknowledgement of Service] [datetime] NULL,
[Defence Due] [datetime] NULL,
[Directions Questionnaire] [datetime] NULL,
[CMC] [datetime] NULL,
[Disclosure] [datetime] NULL,
[Exchange of witness statements] [datetime] NULL,
[Exchange of medical reports] [datetime] NULL,
[Pre-trial checklist] [datetime] NULL,
[Trial date] [datetime] NULL,
[date of trial not KD] [datetime] NULL,
[Is This Part of a Campaign?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[tier_1_3_case] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[International elements] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[LL Damages £350k+] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MIB) Service Category] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Billing Arrangement] [nvarchar] (64) COLLATE Latin1_General_BIN NULL,
[reporting_exclusions] [smallint] NOT NULL,
[Total Write Off Value] [numeric] (38, 2) NULL,
[Local Authority Name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[MS Matter Group] [char] (40) COLLATE Latin1_General_BIN NULL,
[Tesco File Logic] [varchar] (5) COLLATE Latin1_General_CI_AS NULL,
[VAT non-comp] [numeric] (16, 2) NULL
) ON [PRIMARY]
GO
