CREATE TABLE [dbo].[Vis_GeneralData]
(
[Weightmans Reference] [varchar] (17) COLLATE Latin1_General_BIN NULL,
[Client Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Description] [varchar] (200) COLLATE Latin1_General_BIN NULL,
[Date Case Opened] [datetime] NULL,
[Date Case Closed] [datetime] NULL,
[Open/Closed Case Status] [varchar] (6) COLLATE Latin1_General_CI_AS NOT NULL,
[Instruction Type] [char] (60) COLLATE Latin1_General_BIN NULL,
[Date Instructions Received] [datetime] NULL,
[Date Costs Settled] [datetime] NULL,
[Date Claim Concluded] [datetime] NULL,
[Case Manager] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Office] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Division] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Department] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Department Code] [char] (4) COLLATE Latin1_General_BIN NULL,
[Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Team Manager] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[BCM Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BCM] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Matter Category] [char] (40) COLLATE Latin1_General_BIN NULL,
[Matter Category Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Date Initial Report Sent] [datetime] NULL,
[Status On Instruction] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Issue On Liability] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Delegated] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fixed Fee Amount] [numeric] (13, 2) NULL,
[Output WIP Fee Arrangement] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Output WIP % Complete] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Linked File] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Lead File Client Matter Number] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Associated Matter Number] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Clients Claim Handler Full Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Work Type Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Work Type] [char] (40) COLLATE Latin1_General_BIN NULL,
[Work Type Group] [char] (40) COLLATE Latin1_General_BIN NULL,
[Client Group Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Client Group Name] [varchar] (40) COLLATE Latin1_General_BIN NULL,
[Client Name] [char] (80) COLLATE Latin1_General_BIN NULL,
[Client Segment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Client Sector] [char] (40) COLLATE Latin1_General_BIN NULL,
[Client Sub-sector] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claimant's Solicitor] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Claimant's Solicitor (Data Service)] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claimant Postcode Latitude] [decimal] (8, 6) NULL,
[Claimant Postcode Longitude] [decimal] (9, 6) NULL,
[TP Postcode Latitude] [decimal] (8, 6) NULL,
[TP Postcode Longitude] [decimal] (9, 6) NULL,
[Insured Department Depot Latitude] [decimal] (8, 6) NULL,
[Insured Department Depot Longitude] [decimal] (9, 6) NULL,
[Insurer Client Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insured Client Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insurer Client Reference] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insured Client Reference] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Insured Sector] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Present Position] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Outcome of Case] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Track] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Suspicion of Fraud?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Referral Reason] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fixed Fee] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Proceedings Issued] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date Proceedings Issued] [datetime] NULL,
[Accident Location] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Incident Postcode Latitude] [decimal] (8, 6) NULL,
[Incident Postcode Longitude] [decimal] (9, 6) NULL,
[Incident Date] [datetime] NULL,
[Description of Injury] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Hours Recorded] [numeric] (38, 6) NULL,
[Date of Last Time Posting] [datetime] NULL,
[Last Bill Date] [datetime] NULL,
[Last Bill Date Composite] [datetime] NULL,
[Date of Final Bill] [datetime] NULL,
[CFA Entered before 1st April 2013] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[AIG Reason for Service of Proceedings] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Exclude from Reports] [int] NULL,
[Total Reserve] [numeric] (13, 2) NULL,
[Total Reserve (Net)] [numeric] (13, 2) NULL,
[Damages Reserve] [numeric] (13, 2) NULL,
[TP Costs Reserve] [numeric] (13, 2) NULL,
[Defence Costs Reserve] [numeric] (13, 2) NULL,
[Other Defendants Costs Reserve] [numeric] (13, 2) NULL,
[Damages Paid] [numeric] (13, 2) NULL,
[Defence Costs Reserve Initial] [numeric] (13, 2) NULL,
[Disbursement Balance] [numeric] (13, 2) NULL,
[Other Defendants Costs Paid] [numeric] (13, 2) NULL,
[Other Defendants Cost Reserve Initial] [numeric] (13, 2) NULL,
[Output WIP Balance] [numeric] (13, 2) NULL,
[Date Referral to Costs Unit] [datetime] NULL,
[Claimant's Costs Paid] [numeric] (13, 2) NULL,
[Total third party costs claimed] [numeric] (13, 2) NULL,
[Total third party costs paid] [numeric] (13, 2) NULL,
[Detailed Assessment Costs Claimed by Claimant] [numeric] (13, 2) NULL,
[Detailed Assessment Costs Paid] [numeric] (13, 2) NULL,
[Costs Claimed by another Defendant] [numeric] (13, 2) NULL,
[Damages Reserve Initial] [numeric] (13, 2) NULL,
[Costs Paid to Another Defendant] [numeric] (13, 2) NULL,
[Total Recovery] [numeric] (13, 2) NULL,
[Total Paid] [numeric] (13, 2) NULL,
[Total Amount Billed] [numeric] (13, 2) NULL,
[VAT Non-comp] [numeric] (16, 2) NULL,
[Revenue] [numeric] (13, 2) NULL,
[Disbursements Billed] [numeric] (13, 2) NULL,
[WIP] [numeric] (13, 2) NULL,
[VAT] [numeric] (13, 2) NULL,
[Commercial Costs Estimate] [numeric] (13, 2) NULL,
[Client Account Balance of Matter] [numeric] (13, 2) NULL,
[Total Costs Claimed] [numeric] (13, 2) NULL,
[Total Costs Paid] [numeric] (13, 2) NULL,
[Total Reserve Initial] [numeric] (13, 2) NULL,
[Total Settlement Value of the Claim Paid by all the Parties] [numeric] (13, 2) NULL,
[TP Costs Reserve Initial] [numeric] (13, 2) NULL,
[Unpaid Disbursements] [numeric] (13, 2) NULL,
[Litigated/Proceedings Issued] [varchar] (13) COLLATE Latin1_General_CI_AS NOT NULL,
[damages_reserve_net] [numeric] (13, 2) NULL,
[tp_costs_reserve_net] [numeric] (13, 2) NULL,
[defence_costs_reserve_net] [numeric] (13, 2) NULL,
[other_defendants_costs_reserve_net] [numeric] (13, 2) NULL,
[ll00_have_we_had_an_extension_for_the_initial_report] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Elapsed Days Live Files] [int] NULL,
[Elapsed Days to Outcome] [int] NULL,
[Elapsed Days Conclusion] [int] NULL,
[Repudiation - outcome] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Leaver?] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[Time Billed] [numeric] (17, 6) NULL,
[Total Partner Hours] [numeric] (38, 6) NULL,
[Total Non Partner Hours] [numeric] (38, 6) NULL,
[Total Partner/Consultant Hours Recorded] [numeric] (38, 6) NULL,
[Total Associate Hours Recorded] [numeric] (38, 6) NULL,
[Total Solicitor/LegalExec Hours Recorded] [numeric] (38, 6) NULL,
[Total Paralegal Hours Recorded] [numeric] (38, 6) NULL,
[Total Trainee Hours Recorded] [numeric] (38, 6) NULL,
[Total Other Hours Recorded] [numeric] (38, 6) NULL,
[Credit Hire] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Are we Dealing with the Credit Hire?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claim for Hire] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Credit Hire Organisation] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Credit Hire Organisation Detail] [varchar] (500) COLLATE Latin1_General_BIN NULL,
[Hire Start Date] [datetime] NULL,
[Hire End Date] [datetime] NULL,
[CHV Date Hire Paid] [datetime] NULL,
[Hire Paid] [numeric] (13, 2) NULL,
[Hire Claimed] [numeric] (13, 2) NULL,
[Hire Paid Rolling] [int] NULL,
[CHO Postcode] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[CHO Postcode Latitude] [decimal] (8, 6) NULL,
[CHO Postcode Longitude] [decimal] (9, 6) NULL,
[Date Engineer Instructed] [datetime] NULL,
[Car Spaces Inc] [numeric] (13, 2) NULL,
[Client Paying] [numeric] (13, 2) NULL,
[Contribution] [numeric] (13, 2) NULL,
[Contribution Percent] [numeric] (13, 2) NULL,
[Current Rent] [numeric] (13, 2) NULL,
[Disbursements Estimate] [numeric] (13, 2) NULL,
[Fee Estimate] [numeric] (13, 2) NULL,
[Fee Estimates] [numeric] (13, 2) NULL,
[Floor Area Square Foot] [numeric] (13, 2) NULL,
[Full Price] [numeric] (13, 2) NULL,
[Gifa as let sq feet] [numeric] (13, 2) NULL,
[Mezz sq feet] [numeric] (13, 2) NULL,
[Next Rent Amount] [numeric] (13, 2) NULL,
[No of Bedrooms] [numeric] (13, 2) NULL,
[Original Rent] [numeric] (13, 2) NULL,
[Passing Rent] [numeric] (13, 2) NULL,
[Proposed Rent] [numeric] (13, 2) NULL,
[PS Purchase Price] [numeric] (13, 2) NULL,
[Purchase Price] [numeric] (13, 2) NULL,
[Reduced Purchase Price] [numeric] (13, 2) NULL,
[Rent Arrears] [numeric] (13, 2) NULL,
[Sales Admin sq ft] [numeric] (13, 2) NULL,
[Service Charge] [numeric] (13, 2) NULL,
[Size square foot] [numeric] (13, 2) NULL,
[Store sq ft] [numeric] (13, 2) NULL,
[Third Party Pay] [numeric] (13, 2) NULL,
[Total sq ft] [numeric] (13, 2) NULL,
[Address] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Agent] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BE Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BE Number] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Break Clause Notice Required] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Break Date] [datetime] NULL,
[Break] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Campus] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[University Lead] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Responsibilty/Budget] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Payable] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Case Classification] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date of Lease] [datetime] NULL,
[Date of Transfer] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Estate Manager] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[External Surveyor] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[First Rent Review] [datetime] NULL,
[Second Rent Review] [datetime] NULL,
[Third Rent Review] [datetime] NULL,
[Fourth Rent Review] [datetime] NULL,
[Fifth Rent Review] [datetime] NULL,
[Fixed Feehourly Rate] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fixed Fee or Hourly Rate?] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Freehold/Leasehold] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Insurance Premium] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Key Date Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Landlord] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Landlord Address] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Landlord Break Date] [datetime] NULL,
[Lease End Date] [datetime] NULL,
[Lease Start Date] [datetime] NULL,
[Lease Expiry Date] [datetime] NULL,
[Lease Term] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Next Key Date] [datetime] NULL,
[Option to Break] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Option to Purchase] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Pentland Brand] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Pentland Brand Contact] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Pentland Reference] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Postcode] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Postcode Latitude] [decimal] (8, 6) NULL,
[Property Postcode Longitude] [decimal] (9, 6) NULL,
[Property Address] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Ref] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Rateable Value] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Rates Payable] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Rates payable to] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Registered Proprietor] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Rent Commencement Date] [datetime] NULL,
[Rent Review Dates] [datetime] NULL,
[Restrictions on Register] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Service Charges] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Starting Rent] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Tenant Break] [datetime] NULL,
[Tenant Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Tenure] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Term Start Date] [datetime] NULL,
[Term End Date] [datetime] NULL,
[Title Number] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Tenant Rolling Break Notice] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Landlord Rolling Break Notice] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Latitude] [decimal] (8, 6) NULL,
[Property Longitude] [decimal] (9, 6) NULL,
[Operation Company] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Lease ID] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DP Number] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DP Location] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Region] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Branch Code] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[M3 Code] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Area] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Branch] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Start Date] [datetime] NULL,
[Property End Date] [datetime] NULL,
[Property Case Status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Break Date 2] [datetime] NULL,
[Date Lease Agreed] [datetime] NULL,
[Store Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Present Position] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Property Contact] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fascia] [char] (80) COLLATE Latin1_General_BIN NULL,
[Case Type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Days from Lease In] [decimal] (20, 2) NULL,
[Status ASW] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date Lease In] [datetime] NULL,
[Property Completion Date] [datetime] NULL,
[Matter Notes] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[Property Exchange Date] [datetime] NULL,
[Archibald Bathgate Document Link] [varchar] (96) COLLATE Latin1_General_BIN NULL,
[Position within Quarry] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Asset Number] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Parties] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date of Acquisition] [datetime] NULL,
[Costs of Acquisition] [numeric] (13, 2) NULL,
[Size of Title] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Restrictive Covenants] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Rights] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Footpaths] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Which Planning application is the property subject to] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Barratt Manchester Developments] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date of Acknowledgement] [datetime] NULL,
[Date of Exchange] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date of Search Results] [datetime] NULL,
[David Wilson Homes Limited Developments] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Deposit Money Received] [datetime] NULL,
[Developer] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Development] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Eccleston Homes Ltd] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Exchange Date] [datetime] NULL,
[Greenfields Place Development Company Limited Developments] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Lender] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Manchester Ship Canal Developments Advent Limited] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Mortgage Offer Received] [datetime] NULL,
[P Sols Anticipate Exchange of Contracts] [datetime] NULL,
[P Sols Received Contract] [datetime] NULL,
[Persimmon Homes Limited Development] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[PS Plot Number] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Purelake New Homes Limited] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Reservation Received] [datetime] NULL,
[Thomas Jones Sons Limited Development] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Type of Lease] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Type of Scheme] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Completion Date] [datetime] NULL,
[Exchange Date Combined] [datetime] NULL,
[Purchaser solicitors] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Information Received] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Reason for Info not Received] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date Info Received] [datetime] NULL,
[Contractual Documents Sent to P_Sols] [datetime] NULL,
[P Sols Acknowledge Receipt of Documents] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Reservation Signed] [datetime] NULL,
[Expiry of Reservation Period] [datetime] NULL,
[Client] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Issue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Job Title of Caller] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Job Title of Employee] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Job Title of Caller PH] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[Name of Caller] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Name of Employee] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Risk] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Secondary Issue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Region] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Site] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Employment Start Date] [datetime] NULL,
[TGIF Classifications] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Advice Outcome] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Issue HR] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Job Title of Caller HR] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Secondary Issue HR] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Site HR] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Status HR] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TGIF Branch] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[TGIF Postcode] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[TGIF Region] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[TGIF Team] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[TGIF Postcode Latitude] [decimal] (8, 6) NULL,
[TGIF Postcode Longitude] [decimal] (9, 6) NULL,
[Emp Primary Issue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Emp Secondary Issue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Workplace Postcode] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Category of Advice] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Policy Issue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Diversity Issue] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Summary of Advice] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Knowledge Gap] [varchar] (255) COLLATE Latin1_General_BIN NULL,
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
[Emp Litigated/Non-Litigated] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Outcome - Employment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Present Position - Employment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Stage of Outcome] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Whitbread Brand] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Current Costs Estimate] [numeric] (13, 2) NULL,
[Potential Compensation/Pension Loss] [numeric] (13, 2) NULL,
[Actual Compensation] [numeric] (13, 2) NULL,
[Admin Charges Total] [numeric] (13, 2) NULL,
[Group Company] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Bruntwood Case Status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Damages Paid by Client - Disease] [numeric] (15, 2) NULL,
[Claimant's Costs Paid by Client - Disease] [numeric] (13, 2) NULL,
[Damages Paid (all parties) - Disease] [numeric] (31, 16) NULL,
[Claimant's Total Costs Paid (all parties) - Disease] [numeric] (29, 16) NULL,
[Status - Disease] [varchar] (20) COLLATE Latin1_General_CI_AS NULL,
[Track - Disease] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[dss_update_time] [datetime] NOT NULL,
[Risk category health] [varchar] (6) COLLATE Latin1_General_CI_AS NULL,
[NHSR Date costs Paid] [datetime] NULL,
[Financial Risk ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Repitational Risk] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Case Prospects ] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[emp_litigatednonlitigated] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Outcome - Pizza Express] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Whitbread Employee Business Line] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Pizza Express Strategy] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Pizza Express Region] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Value of Instruction] [numeric] (13, 2) NULL,
[Whitbread Managed Business ROM] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Whitbread Employee Business Line_orig] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Client Case Classification] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Capita Stage of Settlement] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claimant's Solicitors Firm] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Claim Concluded Status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Area] [char] (30) COLLATE Latin1_General_BIN NULL,
[Tribunal Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[met_police_work_designation] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[police_offence_giving_rise_to_claim] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Borough] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Source of Instruction] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DVPO - Amount of Fine] [numeric] (13, 2) NULL,
[DVPO - Amount of Court Fees Awarded] [numeric] (13, 2) NULL,
[STW Reason for Litigation] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STW Water or Waste] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STW Status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STW Report Area] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STW Class of Business] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Critical MI Date Closed] [datetime] NULL,
[Working Days from Instruction Received to Initial Report] [decimal] (20, 2) NULL,
[Claim Status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Policy Type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STW Status On Instruction] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Effect Description] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STW Total Damages Paid] [numeric] (14, 2) NULL,
[STW Damages Paid (Lyra only)] [numeric] (13, 2) NULL,
[STW TP Costs Paid] [numeric] (13, 2) NULL,
[STW Defence Costs Paid] [numeric] (13, 2) NULL,
[STW Damages Reserve] [numeric] (13, 2) NULL,
[STW TP Costs Reserve] [numeric] (13, 2) NULL,
[STW Defence Costs Reserve] [numeric] (13, 2) NULL,
[STW Date of Acknowledgment] [datetime] NULL,
[STW Date of Initial Contact] [datetime] NULL,
[Working Days to Initial Contact] [decimal] (20, 2) NULL,
[Working Days to Acknowledge] [decimal] (20, 2) NULL,
[Outstanding Reserve Lyra] [numeric] (18, 2) NULL,
[STW Report] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[STW Report Filter] [int] NOT NULL,
[Current Fee Scale] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Instructing Office] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DST Claimant Solicitor Firm] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DST Insured Client Name] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Date Initial Acknowledgment to Claims Handler] [datetime] NULL,
[Working Days from Instruction Received to Initial Acknowledgment to Claims Handler] [decimal] (20, 2) NULL,
[Tesco Claim Type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Tesco Track] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fraud Type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Tesco Office] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Tesco Handler] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Settlement Stage] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Claim Category] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Ageas Instruction Type] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Name of Instructing Insurer] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[MOJ Stage] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Recovery Claimants Damages Third Party] [numeric] (13, 2) NULL,
[Recovery Defence Cost Third Party] [numeric] (13, 2) NULL,
[Recovery Defence Costs from Claimant] [numeric] (13, 2) NULL,
[Total Recovered] [numeric] (15, 2) NULL,
[Special Damages] [numeric] (13, 2) NULL,
[General Damages] [numeric] (13, 2) NULL,
[Medical Expert Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Claiment Medical Expert Name] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[Revenue 2016/2017] [numeric] (38, 5) NULL,
[Revenue 2017/2018] [numeric] (38, 5) NULL,
[Revenue 2018/2019] [numeric] (38, 5) NULL,
[Revenue 2019/2020] [numeric] (38, 5) NULL,
[Hours Billed 2016/2017] [numeric] (38, 5) NULL,
[Hours Billed 2017/2018] [numeric] (38, 5) NULL,
[Hours Billed 2018/2019] [numeric] (38, 5) NULL,
[Hours Billed 2019/2020] [numeric] (38, 5) NULL,
[Hours Posted 2016/2017] [numeric] (38, 6) NULL,
[Hours Posted 2017/2018] [numeric] (38, 6) NULL,
[Hours Posted 2018/2019] [numeric] (38, 6) NULL,
[Hours Posted 2019/2020] [numeric] (38, 6) NULL,
[PartnerHours] [numeric] (38, 6) NULL,
[NonPartnerHours] [numeric] (38, 6) NULL,
[Partner/ConsultantTime] [numeric] (38, 6) NULL,
[AssociateHours] [numeric] (38, 6) NULL,
[Solicitor/LegalExecTimeHours] [numeric] (38, 6) NULL,
[ParalegalHours] [numeric] (38, 6) NULL,
[TraineeHours] [numeric] (38, 6) NULL,
[OtherHours] [numeric] (38, 6) NULL
) ON [PRIMARY]
GO