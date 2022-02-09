CREATE TABLE [dbo].[hastings_listing_table]
(
[Exposure Number] [int] NULL,
[Claim Reference] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Instruction Type] [char] (60) COLLATE Latin1_General_BIN NULL,
[Hastings Handler] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Supplier Handler] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Supplier Reference] [nvarchar] (33) COLLATE Latin1_General_BIN NULL,
[Case Description - DELETE BEFORE SENDING] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[Present Position - DELETED BEFORE SENDING] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Referral Reason - DELETE BEFORE SENDING] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[work_type_name] [char] (40) COLLATE Latin1_General_BIN NULL,
[Supplier Branch] [char] (40) COLLATE Latin1_General_BIN NULL,
[Claimant First Name] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Claimant Surname] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Claimant Postcode] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Adult or Minor] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Male or Female] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Injury Type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Firm Injury Type - DELETE BEFORE SENDING] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Policyholder First Name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Policyholder Last Name] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Policyholder Postcode] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Indemnity Position] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Date of Accident] [date] NULL,
[Date of Instruction] [date] NULL,
[Date Full File Received] [date] NULL,
[Accident Type] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Jurisdiction] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Fault Rating] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Fault Liability %] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[Claimant Solicitor Firm] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Claimant Solicitor Handler] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claimant Solicitor Branch] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Fundamental Dishonesty] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[Litigated] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[Date Litigated] [date] NULL,
[Claim Status] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Allocated Courts] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Was Litigation Avoidable?] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[Reason for Litigation] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Recovery to be Made?] [numeric] (13, 2) NULL,
[Recovery from] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Current Damages Reserve - DELETE BEFORE SENDING] [numeric] (13, 2) NULL,
[Claimant Schedule of Loss Value] [numeric] (13, 2) NULL,
[PPO Claimed] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[Provisional Damages Claimed] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[Counter Schedule of Loss Value] [numeric] (13, 2) NULL,
[Settlement Achieved] [varchar] (1) COLLATE Latin1_General_CI_AS NULL,
[Total Settlement] [numeric] (14, 2) NULL,
[Date of Settlement] [date] NULL,
[Damages Settlement Saving (money)] [numeric] (15, 2) NULL,
[Damages Settlement Saving (percent)] [numeric] (31, 16) NULL,
[Claimant Costs Claimed] [numeric] (13, 2) NULL,
[Claimant Disbursements Claimed] [numeric] (13, 2) NULL,
[Claimant Costs Paid] [numeric] (13, 2) NULL,
[Claimant Disbursements Paid] [numeric] (13, 2) NULL,
[Date Costs Paid] [date] NULL,
[Date Costs Settled - DELETED BEFORE SENDING] [date] NULL,
[Total Costs Claimed - DELETE BEFORE SENDING] [numeric] (13, 2) NULL,
[total_costs_claimed_rag_status] [varchar] (11) COLLATE Latin1_General_CI_AS NOT NULL,
[Total Costs Paid - DELETE BEFORE SENDING] [numeric] (13, 2) NULL,
[total_costs_paid_rag_status] [varchar] (11) COLLATE Latin1_General_CI_AS NOT NULL,
[Total Costs Savings (money)] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Total Costs Savings (percent)] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Total Costs of Claim Presented] [numeric] (14, 2) NULL,
[Total Claim Costs Savings (money)] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Total Claim Costs Savings (percent)] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[defence_costs_billed] [numeric] (13, 2) NULL,
[disbursements_billed] [numeric] (13, 2) NULL,
[vat_billed] [numeric] (13, 2) NULL,
[Suppliers Billing to Date] [numeric] (13, 2) NULL,
[Date of Final Invoice] [date] NULL,
[Suppliers Billing Paid] [decimal] (38, 2) NULL,
[VAT on Suppliers Billing Paid] [decimal] (38, 2) NULL,
[Suppliers Disbursements Paid] [decimal] (38, 2) NULL,
[Total Claim Cost] [numeric] (15, 2) NULL,
[Total Claim Saving £] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Total Claim Saving (percent)] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Date Supplier Closed File] [date] NULL,
[Lifecycle Accident - Litigation] [int] NULL,
[Lifecycle Accident - Settlement] [int] NULL,
[Lifecycle Accident - Panel File Closure] [int] NULL,
[Lifecycle Instruction - Damages Settlement] [int] NULL,
[Lifecycle Instruction - Panel File Closure] [int] NULL,
[Lifecycle Litigation - Damages Settlement] [int] NULL,
[Lifecycle Damages Settlement - Costs Settlement] [int] NULL,
[Lifecycle Costs Settlement - Panel File Closure] [int] NULL,
[Date Closed on Mattersphere - DELETE BEFORE SENDING] [date] NULL,
[Unbilled WIP - DELETE BEFORE SENDING] [numeric] (13, 2) NULL,
[Unbilled Disbs - DELETE BEFORE SENDING] [numeric] (13, 2) NULL,
[Unpaid Bill Balance - DELETE BEFORE SENDING] [numeric] (13, 2) NULL,
[Date of Trial] [date] NULL,
[Date of Trial Window] [date] NULL,
[Date of Mediation] [date] NULL,
[Date of Infant Approval Hearing] [date] NULL,
[Date of Disposal Hearing] [date] NULL,
[has_trial] [int] NOT NULL,
[Date Opened on MS] [date] NULL,
[Date Instructions Received] [date] NULL,
[Date Full File of Papers Received] [datetime] NULL,
[Initial Report Required?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Extension for Initial Report Agreed] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date Initial Report Due] [date] NULL,
[Date Initial Report Sent] [date] NULL,
[Number of Business Days to Initial Report Sent] [numeric] (13, 2) NULL,
[Date of Last SLA Report] [date] NULL,
[Date Defence Due - Key Date] [date] NULL,
[Date Defence Due - MI Field] [date] NULL,
[Date Defence Filed] [date] NULL,
[Suspicion of Fraud?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Type of Settlement] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Stage of Settlement] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Outcome of Case] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Offers Made with Intention to Rely on at Trial?] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Target Settlement Date] [date] NULL,
[Is Indemnity an Issue?] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Contribution Proceedings Issued?] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Are we Pursuing a Recovery] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date Recovery Concluded] [date] NULL,
[Amount Recovered] [numeric] (13, 2) NULL,
[Gross Damages Reserve Exceed £350,000?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Does the Claimant have a PI Claim?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PREDICT Damages Meta-model Value] [money] NULL,
[PREDICT Recommended Damages Reserve (Current)] [numeric] (13, 2) NULL,
[Damages Paid 100%] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[PREDICT Claimant Costs Meta-model Value] [money] NULL,
[PREDICT Recommended Claimant Costs Reserve (Current)] [numeric] (13, 2) NULL,
[PREDICT Lifecycle Meta-model Value] [numeric] (13, 2) NULL,
[PREDICT Recommended Settlement Time] [numeric] (13, 2) NULL,
[Damages Lifecycle] [int] NULL,
[SLA.A1 Instructions Acknowledged] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A2 File Allocated] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A2 on Collaborate] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A2 Refs Sent to Policyholder] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A2 Initial Contact with Claimant Sols] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A3 Initial Report 10 Days] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A4 Defencese Submitted 7 Days] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A5 Court Directions Provided to Hastings 2 Days] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A6 Defence Submitted to Court] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A7 Compliance with Court Dates] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A8 Identified Other Parties] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A9 Urgent Developments Reported] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A9 Update Reports Submitted] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A10 Significant Developments Reported] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A11 Non-urgent Written Responses] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A12 Urgent Written Responses] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A12 Supplier Written Responses] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A13 Responded to Phone Calls 2 Days] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A14 Outcome Reports Submitted 2 days] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A15 Trials Referred to Large Loss] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A15 Trial Advice Directed to Hastings] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A15 Full Report Tactics 2 Weeks] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A16 Trial Dates Missed] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A17 Experts Reports Provided to Hastings] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A17 Experts Reports Agreed with Hastings] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A19 Accurate Reserves Held] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[SLA.A20 Justified Complaints Made] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[SLA.A20 Non-Justified Complaints Made] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[SLA.A21 Any Leakage Identified] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Date of Last Review] [date] NULL,
[KPI A.1 Initial Advice] [varchar] (12) COLLATE Latin1_General_CI_AS NULL,
[KPI A.2 Fundamental Dishonesty Pleaded] [varchar] (12) COLLATE Latin1_General_CI_AS NULL,
[KPI A.2 Fundamental Dishonesty Success - Withdrawn] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[KPI A.2 Fundamental Dishonesty Success - Compromised] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[KPI A.2 Fundamental Dishonesty Success - Failed] [varchar] (8) COLLATE Latin1_General_CI_AS NULL,
[KPI A.2 Contribution Proceedings] [varchar] (12) COLLATE Latin1_General_CI_AS NULL,
[KPI A.3 Indemnity Recoveries] [varchar] (12) COLLATE Latin1_General_CI_AS NULL,
[KPI A.4 Offers and Outcomes] [varchar] (12) COLLATE Latin1_General_CI_AS NULL,
[KPI A.5 Lifecycle] [varchar] (12) COLLATE Latin1_General_CI_AS NULL,
[KPI A.6 PREDICT] [varchar] (3) COLLATE Latin1_General_CI_AS NULL,
[KPI A.7 Internal Monthly Audits] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
