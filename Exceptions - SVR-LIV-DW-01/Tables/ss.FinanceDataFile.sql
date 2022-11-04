CREATE TABLE [ss].[FinanceDataFile]
(
[Weightmans Reference] [varchar] (17) COLLATE Latin1_General_BIN NULL,
[Client Code] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter Number] [char] (8) COLLATE Latin1_General_BIN NULL,
[Client Name] [char] (80) COLLATE Latin1_General_BIN NULL,
[Admin Charges Total] [numeric] (13, 2) NULL,
[Defence Costs Billed] [numeric] (13, 2) NULL,
[Total Paid] [numeric] (13, 2) NULL,
[Disbursements Billed] [numeric] (13, 2) NULL,
[Disbursements Balance] [numeric] (13, 2) NULL,
[Unpaid Disbursements] [numeric] (13, 2) NULL,
[Opponents Disbursements Paid] [numeric] (13, 2) NULL,
[VAT Billed] [numeric] (13, 2) NULL,
[Unpaid Bill Balance] [numeric] (13, 2) NULL,
[Recovery Defence Costs from Claimant] [numeric] (13, 2) NULL,
[Recovery Claimants Costs via Third Party Contribution] [numeric] (13, 2) NULL,
[Recovery Defence Costs via Third Party Contribution] [numeric] (13, 2) NULL,
[Recovery Claimants Damages via Third Party Contribution] [numeric] (13, 2) NULL,
[Total Recovery (sum of NMI112+NMI135+NMI136+NMI137)] [numeric] (13, 2) NULL,
[Monies Recovered if Applicable] [numeric] (13, 2) NULL,
[Monies Received] [numeric] (13, 2) NULL,
[Fixed Fee Amount] [numeric] (13, 2) NULL,
[Total Budget Uploaded] [numeric] (13, 2) NULL,
[Date Budget Uploaded] [datetime] NULL,
[Budget Approved] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Personal Injury Paid] [numeric] (13, 2) NULL,
[Client Balance] [numeric] (13, 2) NULL,
[WIP] [numeric] (13, 2) NULL,
[Value of Instruction] [numeric] (13, 2) NULL,
[Initial Costs Estimate] [numeric] (13, 2) NULL,
[Current Costs Estimate] [numeric] (13, 2) NULL,
[Damage Interims] [numeric] (13, 2) NULL,
[Interim Costs Payments] [numeric] (13, 2) NULL,
[Special Damages Miscellaneous Paid] [numeric] (13, 2) NULL,
[CRU Paid by all Parties] [numeric] (13, 2) NULL,
[Total Settlement Value of the Claim Paid by all the Parties] [numeric] (13, 2) NULL,
[Detailed Assessment Costs Paid] [numeric] (13, 2) NULL,
[Interlocutory Costs Paid to Claimant] [numeric] (13, 2) NULL,
[Interim Costs Payments by Client Pre-Instruction] [numeric] (13, 2) NULL,
[Other Defendants Costs Paid] [numeric] (13, 2) NULL,
[Other Defendants Costs Reserve Initial] [numeric] (13, 2) NULL,
[Other Defendants Costs Reserve] [numeric] (13, 2) NULL,
[Costs Claimed by another Defendant] [numeric] (13, 2) NULL,
[Detailed Assessment Costs Claimed by Claimant] [numeric] (13, 2) NULL,
[Interlocutory Costs Claimed by Claimant] [numeric] (13, 2) NULL,
[Claimants Total Costs Paid by all Parties] [numeric] (13, 2) NULL,
[Damages Paid] [numeric] (13, 2) NULL,
[Claimants Costs Paid] [numeric] (13, 2) NULL,
[TP Total Costs Claimed] [numeric] (13, 2) NULL,
[Damages Reserve] [numeric] (13, 2) NULL,
[Damages Reserve Initial] [numeric] (13, 2) NULL,
[Damages Reserve Initial (based on detail TRA077)] [numeric] (13, 2) NULL,
[Defence Costs Reserve] [numeric] (13, 2) NULL,
[Defence Costs Reserve Initial] [numeric] (13, 2) NULL,
[TP  Costs Reserve] [numeric] (13, 2) NULL,
[TP Costs Reserve Initial] [numeric] (13, 2) NULL,
[Total Reserve] [numeric] (13, 2) NULL,
[Total Reserve Initial] [numeric] (13, 2) NULL,
[General Damages Paid] [numeric] (13, 2) NULL,
[Special Damages Paid] [numeric] (13, 2) NULL,
[CRU Paid] [numeric] (13, 2) NULL,
[Our Proportion % of Costs] [numeric] (13, 2) NULL,
[Our Proportion Costs] [numeric] (13, 2) NULL,
[Costs Paid] [numeric] (13, 2) NULL,
[Costs Reserve] [numeric] (13, 2) NULL,
[Primary Cover Value] [numeric] (13, 2) NULL,
[Costs Written off Compliance] [numeric] (13, 2) NULL,
[Fees Estimate] [numeric] (13, 2) NULL,
[Outstanding Costs] [numeric] (13, 2) NULL,
[Final Bill Date - Ageas] [datetime] NULL,
[Defence Costs] [numeric] (13, 2) NULL,
[Fee Estimates] [numeric] (13, 2) NULL,
[Costs to Date] [numeric] (13, 2) NULL,
[Trust Spend] [numeric] (14, 2) NULL,
[NHSLA Spend] [numeric] (13, 2) NULL,
[Damages Paid to Date] [numeric] (13, 2) NULL,
[Total Paid - Zurich] [numeric] (13, 2) NULL,
[Damages Banding] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Fee Arrangement] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Percentage Completion] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Costs Paid to Another Defendant] [numeric] (13, 2) NULL,
[NHS Charges Paid by all Parties] [numeric] (13, 2) NULL,
[Disease Total Estimated Settlement Value] [numeric] (13, 2) NULL,
[Claimant's Costs Paid] [numeric] (13, 2) NULL,
[Outsource Damages Paid (WPS278+WPS279+WPS281)] [numeric] (13, 2) NULL,
[Total third party costs claimed (the sum of TRA094+NMI599+NMI600)] [numeric] (13, 2) NULL,
[Total third party costs paid (sum of TRA072+NMI143+NMI379)] [numeric] (13, 2) NULL,
[Total Reserve (Net)] [numeric] (13, 2) NULL,
[Damages Reserve (Net)] [numeric] (13, 2) NULL,
[Claimant's Costs Reserve (Net)] [numeric] (13, 2) NULL,
[Defence Costs Reserve (Net)] [numeric] (13, 2) NULL,
[Solicitor Total Reserve Current] [numeric] (13, 2) NULL,
[Interim Payments] [numeric] (13, 2) NULL,
[PI Reserve Initial] [numeric] (13, 2) NULL,
[PI Reserve Current] [numeric] (13, 2) NULL,
[% Success Fee Claimed] [numeric] (13, 2) NULL,
[Amount of Success Fee Claimed] [numeric] (13, 2) NULL,
[ATE Premium Claimed] [numeric] (13, 2) NULL,
[Claimant's solicitor's base costs claimed + VAT] [numeric] (13, 2) NULL,
[Claimant's disbursements claimed] [numeric] (13, 2) NULL,
[% Success Fee Paid] [numeric] (13, 2) NULL,
[Amount of Success Fee Paid] [numeric] (13, 2) NULL,
[ATE Premium Paid] [numeric] (13, 2) NULL,
[Claimant's solicitor's base costs paid + VAT] [numeric] (13, 2) NULL,
[Claimant's solicitor's disbursements paid] [numeric] (13, 2) NULL,
[General Damages Misc Paid] [numeric] (13, 2) NULL,
[Past Care Paid] [numeric] (13, 2) NULL,
[Past Loss of Earnings Paid] [numeric] (13, 2) NULL,
[CRU Costs Paid] [numeric] (13, 2) NULL,
[CRU Offset against Damages] [numeric] (13, 2) NULL,
[Future Care Paid] [numeric] (13, 2) NULL,
[Future Loss of Earnings Paid] [numeric] (13, 2) NULL,
[Future Loss Misc Paid] [numeric] (13, 2) NULL,
[NHS Charges Paid by Client] [numeric] (13, 2) NULL,
[Other defendants costs - reserve (current)] [numeric] (13, 2) NULL,
[General damages (non-PI) - misc reserve (current)] [numeric] (13, 2) NULL,
[NHS) Billing Status] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL,
[claimant_costs_reserve_current] [numeric] (13, 2) NULL,
[Final Bill Flag] [varchar] (1) COLLATE Latin1_General_CI_AS NOT NULL,
[Nill Settlement] [varchar] (14) COLLATE Latin1_General_CI_AS NULL,
[Outstanding Costs Estimate] [numeric] (13, 2) NULL,
[Repudiated/Payment Made (lees)] [varchar] (12) COLLATE Latin1_General_CI_AS NULL,
[Claim Status] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Total Amount Billed] [numeric] (13, 2) NULL,
[Total Amount Billed (exc VAT)] [numeric] (14, 2) NULL,
[Total Outstanding Costs] [numeric] (15, 2) NULL,
[Opponents Cost Spend] [numeric] (16, 2) NULL,
[Initial claimant's costs reserve / estimation] [numeric] (14, 2) NULL,
[Total Bill Amount - Composite (IncVAT )] [numeric] (16, 2) NULL,
[Total Bill Amount - Composite (excVAT)] [numeric] (16, 2) NULL,
[disbursements_billed_exc_vat] [numeric] (16, 2) NULL,
[Total Outstanding Costs - Composite] [numeric] (17, 2) NULL,
[Damages Paid by Client - Disease] [numeric] (15, 2) NULL,
[Damages Paid (all parties) - Disease] [numeric] (31, 16) NULL,
[Claimant's Costs Paid by Client - Disease] [numeric] (13, 2) NULL,
[Claimant's Total Costs Paid (all parties) - Disease] [numeric] (29, 16) NULL,
[Other Defendant's Costs Reserve (Net)] [numeric] (13, 2) NULL,
[claimants_total_costs_paid_by_all_parties] [numeric] (13, 2) NULL,
[tp_total_costs_claimed_all_parties] [numeric] (13, 2) NULL,
[interim_damages_paid_by_client_preinstruction] [numeric] (13, 2) NULL,
[damages_interims] [numeric] (13, 2) NULL,
[indemnity_spend] [numeric] (13, 2) NULL
) ON [PRIMARY]
GO