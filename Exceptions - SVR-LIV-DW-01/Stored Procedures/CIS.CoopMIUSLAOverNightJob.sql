SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [CIS].[CoopMIUSLAOverNightJob]
AS
BEGIN

IF OBJECT_ID('tempdb..#MIUMonthlyData') IS NOT NULL DROP TABLE #MIUMonthlyData
CREATE TABLE #MIUMonthlyData
(
	[case_id] [int] NOT NULL,
	[Client] [varchar](8) NOT NULL,
	[Matter] [varchar](8) NOT NULL,
	[CIS Reference] [nvarchar](max) NULL,
	[Date Closed in FED] [date] NULL,
	[Date Opened in FED] [date] NOT NULL,
	[Insured Name] [nvarchar](max) NULL,
	[FeeEarner] [varchar](88) NULL,
	[ID] [varchar](8000) NULL,
	[No. of Claimants] [varchar](60) NULL,
	[RTA Date] [date] NULL,
	[Date Received] [date] NULL,
	[Month Instructions Received] [char](3) NULL,
	[Last 12 Months] [datetime] NULL,
	[Elapsed Days] [int] NULL,
	[Fixed Fee] [varchar](60) NULL,
	[GuidNumber] [varchar](60) NULL,
	[Date Closed/declared dormant] [datetime] NULL,
	[BlankColumn] [varchar](1) NOT NULL,
	[Date MI Updated] [datetime] NULL,
	[Date re-opened] [date] NULL,
	[Estimated Final Fee] [char](60) NULL,
	[Status] [varchar](60) NULL,
	[Outcome] [varchar](60) NULL,
	[Policyholder Involvement] [varchar](60) NULL,
	[Fraud Type] [char](60) NULL,
	[MI Reserve] [money] NULL,
	[BlankColumn2] [varchar](1) NOT NULL,
	[Date Pleadings Issued] [varchar](60) NULL,
	[Paid prior to instruction] [money] NULL,
	[Settlement Value] [decimal](19, 4) NULL,
	[Fees] [decimal](19, 4) NULL,
	[Net Savings] [decimal](19, 4) NULL,
	[Potential Recovery] [varchar](60) NULL,
	[Audit] [varchar](60) NULL,
	[Narrative] [varchar](60) NULL,
	[Gunum] [varchar](60) NULL,
	[date_closed] [date] NULL,
	[Team] [nvarchar](50) NULL,
	[Weightmans Fee Earner] [varchar](81) NULL,
	[FedStatus] [varchar](13) NULL,
	[Master date closed/ dormant] [datetime] NULL,
	[Master date MI updated] [datetime] NULL,
	[Master Status] [char](60) NULL,
	[Master Outcome] [char](60) NULL,
	[Master settlement value] [decimal](13, 2) NULL,
	[Master fees] [decimal](13, 2) NULL,
	[Master net savings] [decimal](13, 2) NULL,
	[ReportingTab] [varchar](5) NULL,
	[FeeEarnerCode] [varchar](4) NOT NULL,
	[SAP_Open] [varchar](9) NOT NULL,
	[WIPBal] [decimal](13, 2) NULL,
	[TotalProfitCostsBilled] [money] NULL,
	[ProfitCostsVAT] [money] NULL,
	[SAPClosedDate] [smalldatetime] NULL,
	[Date Claim Concluded] [datetime] NULL,
	[Month Claim Concluded] [char](3) NULL,
	[Year Claim Concluded] [int] NULL,
	[Incident Location] [varchar](60) NULL,
	[Claimant Postcode] [varchar](12) NULL,
	[Present Position] [varchar](50) NULL,
	[Date of repudiation] [date] NULL,
	[Date Proceedings Issued] [date] NULL,
	[Damages Reserve Held LeadLinked] [decimal](19, 4) NULL,
	[Opponents Costs Reserve Held LeadLinked][decimal](19, 4) NULL,
	[Defence Costs Reserve Held LeadLinked][decimal](19, 4) NULL,
	[ABI Fraud Proven] [varchar](60) NULL,
	[Is this a fraud ring] [varchar](60) NULL,
	[Underwriting Referral Made] [varchar](60) NULL,
	[Pre Lit Fees] [decimal] (19,4) NULL,
	[Litigated Fees] [decimal] (19,4) NULL,
	[Disbursements] [decimal] (19,4) NULL,
	
) ON [PRIMARY]

INSERT INTO #MIUMonthlyData
Exec [CIS].[CoopMIUV6]

DECLARE @StartDate AS DATE
DECLARE @EndDate AS DATE
SET @StartDate=(SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()),101))
SET @EndDate=(SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,GETDATE()))),DATEADD(mm,1,GETDATE())),101))
--SET @StartDate='2014-09-01'
--SET @EndDate='2014-09-30'

PRINT @StartDate
PRINT @EndDate

DECLARE @PreviousData AS DATE
PRINT @StartDate
SET @PreviousData=(DATEADD(month, DATEDIFF(month, 0, DATEADD(DAY,-1,@StartDate)), 0))
--SET @PreviousData='2014-08-01'
PRINT @PreviousData
DELETE FROM CIS.MIUSLASnapshotData
WHERE [Year Period]=YEAR(@StartDate)
AND [Period]='P' +CAST(MONTH(@StartDate) AS VARCHAR(10))

INSERT INTO   CIS.MIUSLASnapshotData
(
[case_id]
,[Client]
,[Matter]
,[CIS Reference]
,[Date Closed in FED]
,[Date Opened in FED]
,[Insured Name]
,[FeeEarner]
,[ID]
,[No. of Claimants]
,[RTA Date]
,[Date Received]
,[Month Instructions Received]
,[Last 12 Months]
,[Elapsed Days]
,[Fixed Fee]
,[GuidNumber]
,[Date Closed/declared dormant]
,[BlankColumn]
,[Date MI Updated]
,[Date re-opened]
,[Estimated Final Fee]
,[Status]
,[Outcome]
,[Policyholder Involvement]
,[Fraud Type]
,[MI Reserve]
,[BlankColumn2]
,[Date Pleadings Issued]
,[Paid prior to instruction]
,[Settlement Value]
,[Fees]
,[Net Savings]
,[Potential Recovery]
,[Audit]
,[Narrative]
,[Gunum]
,[date_closed]
,[Team]
,[Weightmans Fee Earner]
,[FedStatus]
,[Master date closed/ dormant]
,[Master date MI updated]
,[Master Status]
,[Master Outcome]
,[Master settlement value]
,[Master fees]
,[Master net savings]
,[ReportingTab]
,[FeeEarnerCode]
,[SAP_Open]
,[WIPBal]
,[TotalProfitCostsBilled]
,[ProfitCostsVAT]
,[SAPClosedDate]
,[Date Claim Concluded]
,[Month Claim Concluded]
,[Year Claim Concluded]
,[Incident Location]
,[Claimant Postcode]
,[Present Position]
,[Date of repudiation]
,[Date Proceedings Issued]
,[Recipt To Desition on Whether to Repudiate]
,[Recipt To Desition on Whether to Repudiate Volume]
,[Recept to 50% dormant Volume]
,[Recept to 50% dormant Elapsed]
,[Recept to 95% dormant Volume]
,[Recept to 95% dormant Elapsed]
,[Recept to File Closed Volume]
,[Recept to File Closed Elapsed]
,Litigation
,[Year Period]
,[Period]
,[Number opened claims]
,[Total Number of Claims In Litigation]
,[Number of Litigated Claims Concluded]
,[Number of Claims Entering Litigation]
,[InsertedDate]
,[Damages Reserve Held LeadLinked]
,[Opponents Costs Reserve Held LeadLinked]
,[Defence Costs Reserve Held LeadLinked]
,[ABI Fraud Proven]
,[Is this a fraud ring]
,[Underwriting Referral Made]
,[Pre Lit Fees]
,[Litigated Fees] 
,[Disbursements] 
	
)

SELECT 
Data.[case_id]
,[Client]
,[Matter]
,[CIS Reference]
,[Date Closed in FED]
,[Date Opened in FED]
,[Insured Name]
,[FeeEarner]
,[ID]
,[No. of Claimants]
,[RTA Date]
,[Date Received]
,[Month Instructions Received]
,[Last 12 Months]
,[Elapsed Days]
,[Fixed Fee]
,[GuidNumber]
,[Date Closed/declared dormant]
,[BlankColumn]
,[Date MI Updated]
,[Date re-opened]
,[Estimated Final Fee]
,[Status]
,[Outcome]
,[Policyholder Involvement]
,[Fraud Type]
,[MI Reserve]
,[BlankColumn2]
,[Date Pleadings Issued]
,[Paid prior to instruction]
,[Settlement Value]
,[Fees]
,[Net Savings]
,[Potential Recovery]
,[Audit]
,[Narrative]
,[Gunum]
,[date_closed]
,[Team]
,[Weightmans Fee Earner]
,[FedStatus]
,[Master date closed/ dormant]
,[Master date MI updated]
,[Master Status]
,[Master Outcome]
,[Master settlement value]
,[Master fees]
,[Master net savings]
,[ReportingTab]
,[FeeEarnerCode]
,[SAP_Open]
,[WIPBal]
,[TotalProfitCostsBilled]
,[ProfitCostsVAT]
,[SAPClosedDate]
,[Date Claim Concluded]
,[Month Claim Concluded]
,[Year Claim Concluded]
,[Incident Location]
,[Claimant Postcode]
,[Present Position]
,[Date of repudiation]
,[Date Proceedings Issued]
,CASE WHEN ([Date re-opened] IS NULL) AND [Date of repudiation] BETWEEN @StartDate AND @EndDate THEN DATEDIFF(Day,[Date Received],[Date of repudiation]) ELSE NULL END AS [Recipt To Desition on Whether to Repudiate]
,CASE WHEN ([Date re-opened] IS NULL) AND[Date of repudiation] BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END [Recipt To Desition on Whether to Repudiate Volume]
,CASE WHEN ( [Date re-opened] IS NULL) AND [Status]  IN ('Dormant - 50% confidence','Dormant - 50% Confidence') AND ISNULL(PreviousStatus,'') NOT IN
(
'Dormant - 50% confidence'
,'Dormant - 95% confidence'
,'Transferred file'
,'Legally closed'
,'Dormant - 50% Confidence'
,'Dormant - 95% Confidence'
,'Transferred File'
,'Legally Closed'

) THEN 1 ELSE  0 END  AS [Recept to 50% dormant Volume]
,CASE WHEN ([Date re-opened] IS NULL) AND [Status] IN ('Dormant - 50% confidence','Dormant - 50% Confidence') AND ISNULL(PreviousStatus,'') NOT IN
(
'Dormant - 50% confidence'
,'Dormant - 95% confidence'
,'Transferred file'
,'Legally closed'
,'Dormant - 50% Confidence'
,'Dormant - 95% Confidence'
,'Transferred File'
,'Legally Closed'


)
THEN DATEDIFF(DAY,[Date Received],[Date Closed/declared dormant]) ELSE NULL END  AS [Recept to 50% dormant Elapsed]
,CASE WHEN ([Date re-opened] IS NULL) AND [Status]   IN ('Legally closed','Dormant - 95% confidence','Legally Closed','Dormant - 95% Confidence')                                  
AND ISNULL(PreviousStatus,'') NOT IN
('Dormant - 95% confidence'
,'Transferred file'
,'Legally closed'
,'Dormant - 95% Confidence'
,'Transferred File'
,'Legally Closed'

) THEN 1 ELSE  0 END  AS [Recept to 95% dormant Volume]
,CASE WHEN ([Date re-opened] IS NULL) AND [Status]   IN ('Legally closed','Dormant - 95% confidence','Legally Closed','Dormant - 95% Confidence') AND ISNULL(PreviousStatus,'') NOT IN
('Dormant - 95% confidence'
,'Transferred file'
,'Legally closed'
,'Dormant - 95% Confidence'
,'Transferred File'
,'Legally Closed'
)
THEN DATEDIFF(DAY,[Date Received],[Date Closed/declared dormant]) ELSE NULL END  AS [Recept to 95% dormant Elapsed]
,CASE WHEN ([Date re-opened] IS NULL) AND [Present Position] IN ('Final bill sent - unpaid','Final bill due - claim and costs concluded','To be closed/minor balances to be clear') AND PreviousPosition  NOT IN ('Final bill sent - unpaid','Final bill due - claim and costs concluded','To be closed/minor balances to be clear') THEN 1 ELSE 0 END AS [Recept to File Closed Volume]
,CASE WHEN ([Date re-opened] IS NULL) AND [Present Position] IN ('Final bill sent - unpaid','Final bill due - claim and costs concluded','To be closed/minor balances to be clear') AND PreviousPosition  NOT IN ('Final bill sent - unpaid','Final bill due - claim and costs concluded','To be closed/minor balances to be clear')
THEN DATEDIFF(DAY,[Date Received],[Date Closed/declared dormant]) ELSE NULL END 
 AS [Recept to File Closed Elapsed]
,CASE WHEN [Date Pleadings Issued]='Yes' THEN 'Litigated' ELSE 'Non-Litigated' END AS Litigation
,YEAR(@StartDate) AS[Year Period]
,'P' +CAST(MONTH(@StartDate) AS VARCHAR(10)) AS [Period]
,CASE WHEN [Status] NOT IN ('Legally closed','Dormant - 95% confidence','Transferred file','Legally Closed','Dormant - 95% Confidence','Transferred File') THEN 1 ELSE 0 END AS [Number opened claims]
,CASE WHEN [Date pleadings issued]='Yes' AND [Status] NOT IN ('Legally closed','Dormant - 95% confidence','Legally Closed','Dormant - 95% Confidence') THEN 1 ELSE 0 END  [Total Number of Claims In Litigation]
,CASE WHEN [Date pleadings issued]='Yes' AND [Status] IN ('Legally closed','Dormant - 95% confidence','Legally Closed','Dormant - 95% Confidence') AND [Date Claim Concluded] BETWEEN @StartDate AND @EndDate  THEN 1 ELSE 0 END  [Number of Litigated Claims Concluded]
,CASE WHEN [Date Proceedings Issued] BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END  [Number of Claims Entering Litigation]
,CONVERT(DATE,GETDATE(),103) AS [InsertedDate]
,[Damages Reserve Held LeadLinked]
,[Opponents Costs Reserve Held LeadLinked]
,[Defence Costs Reserve Held LeadLinked]
,[ABI Fraud Proven]
,[Is this a fraud ring]
,[Underwriting Referral Made]
,[Pre Lit Fees]  
,[Litigated Fees] 
,[Disbursements]  
FROM #MIUMonthlyData AS Data
LEFT OUTER JOIN 
(
SELECT case_id AS case_id,[Status] AS PreviousStatus,[Present Position] AS PreviousPosition
FROM CIS.MIUSLASnapshotData
WHERE [Year Period]=YEAR(@PreviousData)
AND [Period]='P' +CAST(MONTH(@PreviousData) AS VARCHAR(10))
) AS PreviousData
 ON Data.case_id=PreviousData.case_id

END
GO
