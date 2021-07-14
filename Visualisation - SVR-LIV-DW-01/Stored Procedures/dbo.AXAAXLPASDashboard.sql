SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[AXAAXLPASDashboard]

AS
BEGIN 
SELECT [Date Case Opened]
,[Fin Year Opened]
,[Date Case Closed]
,[Fin Year Closed]
,[MS Only]
,[Weightmans Reference]
,[Client Code]
,[Matter Number]
,[Mattersphere Client Code]
,[Mattersphere Matter Number]
,[Mattersphere Weightmans Reference]
,CASE WHEN [axa_instruction_type]='PAS' THEN 'PAS' END  AS [AXA PAS?]
,[Matter Description]
,[Case Manager]
,[Matter Owner Full Name]
,[Matter Partner]
,[Grade]
,[Leaver?]
,[Team Manager]
,[BCM Name]
,[Office]
,[Team]
,[Department]
,[Department Code]
,[Division]
,[Work Type]
,[Work Type Code]
,[Worktype Group]
,[Instruction Type]
,[Client Name]
,CASE WHEN [Client Group Name]='AXA XL' THEN 'AXA XL'
WHEN [Client Group Name]='Sabre' THEN 'Benchmark' END   [Client Like for Like]
,CASE WHEN [Client Group Name]='AXA XL' THEN 'AXA XL' 
ELSE'Market'END AS [market]
,[Client Group Name]
,[Client Sector]
,[Client Sub-Sector]
,[Client Segment ]
,[Client Partner Name]
,[Client Type]
,[Insurer Client Reference FED]
,[Insurer Name FED]
,[Clients Claim Handler ]
,[Insured Client Reference FED]
,[Insured Client Name FED]
,[Insured Sector]
,[Insured Department]
,[Insured Department Depot Postcode]
,[Converge Date Closed]
,[Present Position]
,[Converge Claim Status]
,[Date Instructions Received]
,[Status On Instruction]
,[Referral Reason]
,[Proceedings Issued]
,[Date Proceedings Issued]
,[Reason For Litigation]
,[Court Reference]
,[Court Name]
,[Track]
,[Suspicion of Fraud?]
,[Fraud Type]
,[Credit Hire]
,[Credit Hire Organisation]
,[Credit Hire Org HF]
,[Credit Hire Organisation Detail]
,[Brief Details of Claim]
,[Claimant Name]
,[Number of Claimants]
,[Defendant Name]
,[Number of Defendants ]
,[Does the Claimant have a PI Claim? ]
,[Description of Injury]
,[Claimant's medical expert]
,[Litigation / Regulatory]
,[Liability Issue]
,[Delegated]
,[Fixed Fee]
,[Fixed Fee Amount]
,[Fee Arrangement]
,[Percentage Completion]
,[Linked File?]
,[Lead Follow]
,[Lead File Matter Number]
,[Associated Matter Numbers]
,[MoJ stage]
,[Incident Date]
,[Incident Location]
,[Has the Claimant got a CFA? ]
,[CFA entered into before 1 April 2013]
,[Claimant's Solicitor (Data Service)]
,[Claimant's Solicitor]
,[Claimants Representative]
,[Claimant's Postcode]
,[Total Reserve Calc]
,[total_current_reserve]
,[Converge Disease Reserve]
,[Damages Reserve (Initial)]
,[Damages Reserve Current ]
,[Hire Claimed ]
,[Claimant Costs Reserve Current (Initial)]
,[Claimant Costs Reserve Current ]
,[Defence Cost Reserve (Initial )]
,[Defence Costs Reserve Current]
,[Other Defendant's Costs Reserve (Net)]
,[Disease Total Estimated Settlement Value ]
,[Outcome of Case]
,[Settlement basis]
,[Date of first day of trial window]
,[Date of Trial]
,[Date Claim Concluded]
,[Fin Year Claim Concluded]
,[Date "Date Claim Concluded" Last Changed]
,[Interim Damages]
,[Damages Paid by Client ] AS [Damages Paid by Client]
,[Outsource Damages Paid (WPS278+WPS279+WPS281)]
,[Personal Injury Paid]
,[Hire Paid ]
,[Damages Paid (all parties) - Disease]
,[Date Referral to Costs Unit]
,[Date Claimants Costs Received]
,[Date Costs Settled]
,[Fin Year Costs Settled]
,[Date Settlement form Sent to Zurich WPS386 VE00571]
,[Interim Costs Payments]
,[Total third party costs claimed (the sum of TRA094+NMI599+NMI600)]
,[Total third party costs paid (sum of TRA072+NMI143+NMI379)]
,[Claimants Total Costs Claimed against Client]
,[Claimant's Costs Paid by Client - Disease]
,[Outsource Claimants Costs]
,[Detailed Assessment Costs Claimed by Claimant]
,[Detailed Assessment Costs Paid]
,[Costs Claimed by another Defendant]
,[Costs Paid to Another Defendant]
,[Claimants Total Costs Paid by All Parties]
,[Are we pursuing a recovery?]
,[Total Recovery (NMI112,NMI135,NMI136,NMI137)]
,[Outsource Recovery Paid]
,[Total Bill Amount - Composite (IncVAT )]
,[Revenue Costs Billed]
,[Disbursements Billed ]
,[VAT Billed]
,[WIP]
,[Unbilled Disbursements]
,[Revenue Estimate net of VAT]
,[Disbursements net of VAT]
,[Total Disbs Budget Agreed/Recorded]
,[Total profit costs agreed/recorded]
,[Client Account Balance of Matter]
,[Unpaid Bill Balance]
,[Last Bill Date]
,[Last Bill Date Composite ]
,[Fin Year Of Last Bill]
,[Date of Last Time Posting]
,[Fin Year Of Last Time Posting]
,[Hours Recorded]
,[Minutes Recorded]
,[Legal Spend exc (VAT)]
,[Time Billed]
,[Total Non-Partner Hours Recorded]
,[Total Partner Hours Recorded]
,[Total Associate Hours Recorded]
,[Total Other Hours Recorded]
,[Total Paralegal Hours Recorded]
,[Total Partner/Consultant Hours Recorded]
,[Total Solicitor/LegalExec Hours Recorded]
,[Total Trainee Hours Recorded]
,[Damages Banding]
,[Elapsed Days Live Files]
,[Elapsed Days to Costs Settlement]
,[Elapsed Days to Damages Concluded]
,[Initial Costs Estimate]
,[Current Costs Estimate]
,[revenue_and_disb_estimate_net_of_vat]
,[revenue_estimate_net_of_vat]
,[disbursements_estimate_net_of_vat]
,[Recovery Claimants Damages Via Third Party Contribution]
,[Recovery Defence Costs From Claimant ]
,[Recovery Claimants via Third Party Contribution ]
,[Defence Costs via Third Party Contribution]
,[Insured Client Name]
,[Commerical BI Status]
,[Broker Name]
,[TP Account Name]
,[Third party storage and recovery company]
,[update_time]
,[Revenue 2015/2016]
,[Revenue 2016/2017]
,[Revenue 2017/2018]
,[Revenue 2018/2019]
,[Revenue 2019/2020]
,[Revenue 2020/2021]
,[Hours Billed 2015/2016]
,[Hours Billed 2016/2017]
,[Hours Billed 2017/2018]
,[Hours Billed 2018/2019]
,[Hours Billed 2019/2020]
,[Hours Billed 2020/2021]
,[Chargeable Hours Posted 2015/2016]
,[Chargeable Hours Posted 2016/2017]
,[Chargeable Hours Posted 2017/2018]
,[Chargeable Hours Posted 2018/2019]
,[Chargeable Hours Posted 2019/2020]
,[Chargeable Hours Posted 2020/2021]
,[Disbursements Billed 2015/2016]
,[Disbursements Billed 2016/2017]
,[Disbursements Billed 2017/2018]
,[Disbursements Billed 2018/2019]
,[Disbursements Billed 2019/2020]
,[Disbursements Billed 2020/2021]
,[STW Work Type]
,[minutes_recorded_cost_handler]
,[time_charge_value_cost_handler]
,[cost_handler_revenue]
,[Client Ref]
,[date_recovery_concluded]
,[Counsel Fees Billed ex VAT]
,[Counsel Fees Billed inc VAT]
,[Date of receipt of clients file of papers]
,[Do clients require an initial report]
,[Date initial report sent]
,[[Date_initial_report_due]
,[Have we had an extension for the initial report]
,[Final Bill Date]
,[latest_archive_date]
,[latest_archive_status]
,[latest_archive_type]
,[Trust Type of Instruction]
,[Covid Reason]
,[Covid Other]
,[Acknowledgement of Service]
,[Defence Due]
,[Directions Questionnaire]
,[CMC]
,[Disclosure]
,[Exchange of witness statements]
,[Exchange of medical reports]
,[Pre-trial checklist]
,[Trial date]
,[date of trial not KD]
,[Is This Part of a Campaign?]
,[tier_1_3_case]
,[International elements]
,[LL Damages £350k+]

FROM Reporting.dbo.selfservice
LEFT OUTER JOIN red_dw.dbo.dim_detail_client 
ON [Client Code]=client_code
AND [Matter Number]=matter_number

WHERE Department='Motor'
AND [Date Claim Concluded]>='2020-07-01'
AND ISNULL([Suspicion of Fraud?],'') <>'Yes'
AND ISNULL([Outcome of Case],'') NOT IN ('Exclude from reports','Returned to Client')
AND  ISNULL([Damages Paid by Client ],0)<=50000

END
GO