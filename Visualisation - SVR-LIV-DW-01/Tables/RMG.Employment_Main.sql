CREATE TABLE [RMG].[Employment_Main]
(
[Case - Status] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Pay Number & Surname] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Business Unit] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Geography] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Place of Work] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Org Unit] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Office Post Code] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Employee First Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Employee Surname] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Employee Title] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Date of Birth] [datetime] NULL,
[Personal - Employee Start Date] [datetime] NULL,
[Personal - Union Rep] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Type of Case] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Policy Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Appeal Manager / NAP Panelist Name] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Date Appeal Requested] [datetime] NULL,
[Case - Date Allocated to Appeal Manager / NAP Chair] [datetime] NULL,
[Case - Penalty Awarded] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Date Penalty Awarded] [datetime] NULL,
[Case - Last Day of Service] [datetime] NULL,
[Case - Last Day of Service Extended] [datetime] NULL,
[Case - Dismissing Manager] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Anything Missing from Papers] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Missing Paper Detail] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Actual Interview / NAP Hearing Date] [datetime] NULL,
[Case - Date LTBIH Further Medical Received] [datetime] NULL,
[Case - Historical Interview Detail] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Date of Decision for Appeal / NAP] [datetime] NULL,
[60 Day Target] [datetime] NULL,
[Delay - ICM Workload] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - ICM Workload - Days] [float] NULL,
[Delay - Archives] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - Archives - Days] [float] NULL,
[Delay - ATOS Evidence] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - ATOS Evidence - Days] [float] NULL,
[Delay - Availability of Union Rep] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - Availability of Union Rep - Days] [float] NULL,
[Delay - Availability of Witnesses] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - Availability of Witnesses - Days] [float] NULL,
[Delay - Awaiting Additional Info from LM] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - Awaiting Additional Info from LM - Days] [float] NULL,
[Delay - Awaiting Advice from Legal] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - Awaiting Advice from Legal - Days] [float] NULL,
[Delay - Ill Health Appeal Medical Evidence] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - Ill Health Appeal Medical Evidence - Days] [float] NULL,
[Delay - Line Manager Delay in Despatching] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - Line Manager Delay in Despatching - Days] [float] NULL,
[Delay - Missing Documentation Chase] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - Missing Documentation Chase - Days] [float] NULL,
[Delay - NAP] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - NAP - Days] [float] NULL,
[Delay - Postponement by Appellant (Sick, A/L, etc#)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Delay - Postponement by Appellant (Sick, A/L, etc#) - Days] [float] NULL,
[Delay - Total Number of Days] [float] NULL,
[Case - Outcome of Appeal / NAP] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Appeal / NAP Learning Detail] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Case - NAP CWU Panelist] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - NAP Chairman] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - App 3 Outcome Enclosed] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Was NAP Appropriate] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - NAP Majority Decision] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - NAP Costs 1 - Total] [money] NULL,
[Case - NAP Costs 2 - CWU Invoice] [money] NULL,
[Case - NAP Note Taking Costs] [money] NULL,
[ET - Did the appellant share their email contact details] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Early Conciliation] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Conciliation Reference No#] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Date Early Conciliation Requested] [datetime] NULL,
[EC - Period End Date] [datetime] NULL,
[EC - ICM Dealing] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Brief Description of Case] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[EC - ACAS Conciliator Details] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Which Letter/s Have Been Sent?] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Date Sent to XSP] [datetime] NULL,
[EC - XSP] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - XSP Contact Details] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Instructions Received by XSP] [datetime] NULL,
[EC - Instructions Via] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - EC Status] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - EC Outcome] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Amount Paid to Claimant] [money] NULL,
[EC - Agreement Other (non financial)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Outcome Known] [datetime] NULL,
[EC - Payee] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Payment Reason] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Amount] [money] NULL,
[EC - Date Requested] [datetime] NULL,
[EC - Date Sent] [datetime] NULL,
[EC - Method] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Payee 2 Required] [bit] NOT NULL,
[EC - Payee 2] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Payment Reason 2] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Amount 2] [money] NULL,
[EC - Date Requested 2] [datetime] NULL,
[EC - Date Sent 2] [datetime] NULL,
[EC - Method 2] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Learning Details] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[EC - Case Closed Date] [datetime] NULL,
[ET - Legal Claim Received] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Claim Number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - CMS Reference Number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - CMS Case Classification] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Primary Case Classification] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Secondary Case Classification/s] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - ICM Dealing / Contact] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Date ET1 sent by Tribunal] [datetime] NULL,
[ET - Date ET1 received by ERCM] [datetime] NULL,
[ET - eTAF Drop] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Tribunal Office] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - XSP] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - XSP Contact Details] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Instructions sent to XSP] [datetime] NULL,
[ET - Instructions Received by XSP] [datetime] NULL,
[ET - Instructions Via] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Brief Description of Case] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[ET - Sensitivity and Risk] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Date ET3 served] [datetime] NULL,
[ET - Status] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Stayed] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Stayed Reasons] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - List of Witnesses] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Start Date of Hearing] [datetime] NULL,
[ET - Finish Date of Hearing] [datetime] NULL,
[ET - Initial Prospects of Success] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Date Case Prospects Report Sent] [datetime] NULL,
[ET - Revised Prospects of Success] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Date Revised] [datetime] NULL,
[ET - Potential Cost] [money] NULL,
[ET - Present Position] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Outcome] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Outcome Known] [datetime] NULL,
[ET - Settlement Monies/Compensation - Paid to Claimant] [money] NULL,
[ET - Settlement other (non financial)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Costs Awarded to RMG] [money] NULL,
[ET - Costs Recovered] [money] NULL,
[ET - Payee 1] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Payment Reason 1] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Amount 1] [money] NULL,
[ET - Date Requested 1] [datetime] NULL,
[ET - Date Sent 1] [datetime] NULL,
[ET - Method 1] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Payee 2 Required] [bit] NOT NULL,
[ET - Payee 2] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Payment Reason 2] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Amount 2] [money] NULL,
[ET - Date Requested 2] [datetime] NULL,
[ET - Date Sent 2] [datetime] NULL,
[ET - Method 2] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Payee 3 Required] [bit] NOT NULL,
[ET - Payee 3] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Payment Reason 3] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Amount 3] [money] NULL,
[ET - Date Requested 3] [datetime] NULL,
[ET - Date Sent 3] [datetime] NULL,
[ET - Method 3] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Payee 4 Required] [bit] NOT NULL,
[ET - Payee 4] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Payment Reason 4] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Amount 4] [money] NULL,
[ET - Date Requested 4] [datetime] NULL,
[ET - Date Sent 4] [datetime] NULL,
[ET - Method 4] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Payee 5 Required] [bit] NOT NULL,
[ET - Payee 5] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Payment Reason 5] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET - Amount 5] [money] NULL,
[ET - Date Requested 5] [datetime] NULL,
[ET - Date Sent 5] [datetime] NULL,
[ET - Method 5] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[ET Learning Detail] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[ET Case Closed Date] [datetime] NULL,
[Further - Bullying and Harassment Case] [bit] NOT NULL,
[Further - Date Received in ER Ops from Sheffield Archives] [datetime] NULL,
[Further - Date Added to Portal by ER Ops] [datetime] NULL,
[Further - Comments] [nvarchar] (max) COLLATE Latin1_General_CI_AS NULL,
[Further - PSP Service Ticket Number] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Delay Reasons] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Hit 60 Day] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case - Total Delay Time] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Case Open For] [float] NULL,
[CMS Look Up] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[eTAF Form Sent] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[eTAF Form Submit] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[IH Medical Evidence Days] [float] NULL,
[Total Number of Days Case Open For] [float] NULL,
[Case - Suspended Start Date] [datetime] NULL,
[Case - Suspended End Date] [datetime] NULL,
[Case - Suspension Reason] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Created] [datetime] NULL,
[Created By] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Modified] [datetime] NULL,
[Modified By] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[SDD] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Remote Hearing] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Item Type] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Path] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Personal - Business Unit 2] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Learning Points] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO