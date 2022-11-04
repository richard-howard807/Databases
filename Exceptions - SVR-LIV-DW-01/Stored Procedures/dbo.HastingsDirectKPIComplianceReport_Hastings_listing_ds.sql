SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[HastingsDirectKPIComplianceReport_Hastings_listing_ds]

AS

SELECT 
	hastings_listing_table.[Claim Reference]
	, hastings_listing_table.[Hastings Handler]
	, hastings_listing_table.[Supplier Reference]
	, hastings_listing_table.[Case Description - DELETE BEFORE SENDING]		AS [Case Description]
	, hastings_listing_table.[Supplier Handler]		AS [Case Manager]
	, hastings_listing_table.[Referral Reason - DELETE BEFORE SENDING]	AS [Referral Reason]
	, hastings_listing_table.[Instruction Type]			AS [Hastings Instruction Type]
	, hastings_listing_table.[Present Position - DELETED BEFORE SENDING]		AS [Present Position]
	, hastings_listing_table.[Date Opened on MS]		
	, hastings_listing_table.[Date Instructions Received]
	, hastings_listing_table.[Date Full File of Papers Received]		
	, hastings_listing_table.[Initial Report Required?]
	, hastings_listing_table.[Extension for Initial Report Agreed]
	, hastings_listing_table.[Date Initial Report Due]		
	, hastings_listing_table.[Date Initial Report Sent]
	, hastings_listing_table.[Number of Business Days to Initial Report Sent]
	, hastings_listing_table.[Date of Last SLA Report]
	, hastings_listing_table.Litigated			AS [Proceedings Issued]
	, hastings_listing_table.[Date Litigated]		AS [Date Proceedings Issued]
	, hastings_listing_table.[Date Defence Due - Key Date]		
	, hastings_listing_table.[Date Defence Due - MI Field]
	, hastings_listing_table.[Date Defence Filed]	
	, hastings_listing_table.[Suspicion of Fraud?]
	, hastings_listing_table.[Fundamental Dishonesty]
	, hastings_listing_table.[Type of Settlement]
	, hastings_listing_table.[Stage of Settlement]
	, hastings_listing_table.[Outcome of Case]
	, hastings_listing_table.[Offers Made with Intention to Rely on at Trial?]	AS [True (not Tactical) Part 36/Calderbank/Other Offers Made with the Intention to Rely on at Trial?]
	, hastings_listing_table.[Target Settlement Date]
	, hastings_listing_table.[Date of Settlement]		AS [Date Claim Concluded]
	, hastings_listing_table.[Date Costs Settled - DELETED BEFORE SENDING]	AS [Date Costs Settled]
	, hastings_listing_table.[Is Indemnity an Issue?]
	, hastings_listing_table.[Contribution Proceedings Issued?]
	, hastings_listing_table.[Are we Pursuing a Recovery]
	, hastings_listing_table.[Recovery from]
	, hastings_listing_table.[Date Recovery Concluded]
	, hastings_listing_table.[Amount Recovered]
	, hastings_listing_table.[Gross Damages Reserve Exceed £350,000?]
	, hastings_listing_table.[Does the Claimant have a PI Claim?]
	, hastings_listing_table.[Injury Type]
	, hastings_listing_table.[PREDICT Damages Meta-model Value]
	, hastings_listing_table.[PREDICT Recommended Damages Reserve (Current)]
	, hastings_listing_table.[Damages Paid 100%]
	, hastings_listing_table.[PREDICT Claimant Costs Meta-model Value]
	, hastings_listing_table.[PREDICT Recommended Claimant Costs Reserve (Current)]
	, hastings_listing_table.[Claimant Costs Paid]
	, hastings_listing_table.[PREDICT Lifecycle Meta-model Value]
	, hastings_listing_table.[PREDICT Recommended Settlement Time]
	, hastings_listing_table.[Damages Lifecycle]
	, hastings_listing_table.[Date Supplier Closed File]		AS [Hastings Closure Date]
	, hastings_listing_table.[Date Closed on Mattersphere - DELETE BEFORE SENDING]	AS [Date Closed on MS]
	, hastings_listing_table.[KPI A.1 Initial Advice]
	, hastings_listing_table.[KPI A.2 Fundamental Dishonesty Pleaded]
	, hastings_listing_table.[KPI A.2 Fundamental Dishonesty Success - Withdrawn]
	, hastings_listing_table.[KPI A.2 Fundamental Dishonesty Success - Compromised]
	, hastings_listing_table.[KPI A.2 Fundamental Dishonesty Success - Failed]
	, hastings_listing_table.[KPI A.2 Contribution Proceedings]
	, hastings_listing_table.[KPI A.3 Indemnity Recoveries]
	, hastings_listing_table.[KPI A.4 Offers and Outcomes]
	, hastings_listing_table.[KPI A.5 Lifecycle]
	, hastings_listing_table.[KPI A.6 PREDICT]
	, hastings_listing_table.[KPI A.7 Internal Monthly Audits]
	, hastings_listing_table.[SLA.A1 Instructions Acknowledged]
	, hastings_listing_table.[SLA.A2 File Allocated]
	, hastings_listing_table.[SLA.A2 on Collaborate]
	, hastings_listing_table.[SLA.A2 Refs Sent to Policyholder]
	, hastings_listing_table.[SLA.A2 Initial Contact with Claimant Sols]
	, hastings_listing_table.[SLA.A3 Initial Report 10 Days]
	, hastings_listing_table.[SLA.A4 Defencese Submitted 7 Days]
	, hastings_listing_table.[SLA.A5 Court Directions Provided to Hastings 2 Days]
	, hastings_listing_table.[SLA.A6 Defence Submitted to Court]
	, hastings_listing_table.[SLA.A7 Compliance with Court Dates]
	, hastings_listing_table.[SLA.A8 Identified Other Parties]
	, hastings_listing_table.[SLA.A9 Urgent Developments Reported]
	, hastings_listing_table.[SLA.A9 Update Reports Submitted]
	, hastings_listing_table.[SLA.A10 Significant Developments Reported]
	, hastings_listing_table.[SLA.A11 Non-urgent Written Responses]
	, hastings_listing_table.[SLA.A12 Urgent Written Responses]
	, hastings_listing_table.[SLA.A12 Supplier Written Responses]
	, hastings_listing_table.[SLA.A13 Responded to Phone Calls 2 Days]
	, hastings_listing_table.[SLA.A14 Outcome Reports Submitted 2 days]
	, hastings_listing_table.[SLA.A15 Trials Referred to Large Loss]
	, hastings_listing_table.[SLA.A15 Trial Advice Directed to Hastings]
	, hastings_listing_table.[SLA.A15 Full Report Tactics 2 Weeks]
	, hastings_listing_table.[SLA.A16 Trial Dates Missed]
	, hastings_listing_table.[SLA.A17 Experts Reports Provided to Hastings]
	, hastings_listing_table.[SLA.A17 Experts Reports Agreed with Hastings]
	, hastings_listing_table.[SLA.A19 Accurate Reserves Held]
	, hastings_listing_table.[SLA.A20 Justified Complaints Made]
	, hastings_listing_table.[SLA.A20 Non-Justified Complaints Made]
	, hastings_listing_table.[SLA.A21 Any Leakage Identified]
	, hastings_listing_table.[Date of Last Review]
FROM Reporting.dbo.hastings_listing_table

WHERE TRIM(ISNULL(hastings_listing_table.[Referral Reason - DELETE BEFORE SENDING],'')) <> 'Advice only'
GO