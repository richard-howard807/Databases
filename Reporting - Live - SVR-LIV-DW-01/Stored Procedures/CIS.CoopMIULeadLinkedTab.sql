SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [CIS].[CoopMIULeadLinkedTab]  -- EXEC [CIS].[CoopMIULeadLinkedTab] '2017-01-01','2017-01-31'
(
@StartDate AS DATE
,@EndDate AS Date
)
AS
BEGIN

set transaction isolation level read uncommitted

DECLARE @PreviousData AS DATE

SET @PreviousData=(DATEADD(month, DATEDIFF(month, 0, DATEADD(DAY,-1,@StartDate)), 0))
PRINT @PreviousData


DECLARE @RollingStart AS DATE
SET @RollingStart=DATEADD(Month,-11,@StartDate)

IF OBJECT_ID('tempdb..#Guids') IS NOT NULL DROP TABLE #Guids

IF OBJECT_ID('tempdb..#AllData') IS NOT NULL DROP TABLE #AllData

SELECT
 DISTINCT CASE WHEN UPPER(GuidNumber) ='LEGACY' OR UPPER(GuidNumber) ='Legacy File' THEN [CIS Reference] ELSE GuidNumber END collate database_default  AS GuidNumber
INTO #Guids
FROM CIS.MIUSLASnapshotData
WHERE InsertedDate BETWEEN @RollingStart AND @EndDate
AND InsertedDate <>'2014-08-31'
AND (CASE WHEN UPPER(GuidNumber) ='LEGACY' OR UPPER(GuidNumber) ='Legacy File' THEN [CIS Reference] ELSE GuidNumber END) IS NOT NULL







SELECT
[CIS Reference]
,[Insured Name]
,[ID]
,[No. of Claimants]
,[RTA Date]
,[Date received]
,[Date Closed/declared dormant]
,[Status]
,[Outcome]
,[ABI Fraud Proven]
,[Is this a fraud ring]
,[Underwriting Referral Made?]
,[Fraud Type]
,[MI Reserve]
,[Settlement Value] AS   [Settlement Value]
,[Master settlement value]
, MasterFlag
,Claim.[Pre Lit Fees] AS [Pre Lit Fees]
,Claim.[Litigated Fees] AS [Litigated Fees]
,Claim.[Disbursements] AS [Disbursements]
,Claim.Fees AS  Fees
,Claim.[Net Savings] AS  [Net Savings]
,[Potential Recovery]
,MIULeadLinkedSnapshot.case_id as case_id
,CASE WHEN UPPER(GuidNumber) ='LEGACY' THEN [CIS Reference] ELSE GuidNumber END collate database_default  AS GuidNumber
,GuidNumber AS OriginalGuidNumber
,[Period] AS DataPeriod
,[Year Period]
,CASE WHEN [Year Period]=YEAR(@StartDate) AND [Period]='P' +CAST(MONTH(@StartDate) AS VARCHAR(10)) THEN 1 ELSE 0 END AS CurrentData
,'Claimant' AS [Level]
,FeeEarner
,[Date MI Updated]
,[Date re-opened]
,[Estimated Final Fee]
,[Policyholder Involvement]
,[Date Pleadings Issued]
,[Paid prior to instruction]
,[Reporting Level] AS Orderx

INTO #AllData
FROM CIS.MIULeadLinkedSnapshot
LEFT OUTER JOIN (SELECT
case_id
,[Pre Lit Fees]
,[Litigated Fees]
,[Disbursements]
,Fees
,[Net Savings]
,MasterFlag
FROM (SELECT Period,[Period Year],[Date]  
FROM [dbo].[CISMIUPeriods] 
WHERE [Date] BETWEEN @RollingStart AND @EndDate
) AS Periods
INNER JOIN 
(
SELECT
[CIS Reference]
,[Insured Name]
,[ID]
,[No. of Claimants]
,[RTA Date]
,[Date received]
,[Date Closed/declared dormant]
,[Status]
,[Outcome]
,[ABI Fraud Proven]
,[Is this a fraud ring]
,[Underwriting Referral Made]
,[Fraud Type]
,[MI Reserve]
,[Settlement Value]
,[Pre Lit Fees]
,[Litigated Fees]
,[Disbursements]
,Fees
,[Net Savings]
,[Potential Recovery]
,case_id
,CASE WHEN UPPER(GuidNumber) ='LEGACY' OR UPPER(GuidNumber) ='Legacy File' THEN [CIS Reference] ELSE GuidNumber END collate database_default  AS GuidNumber
,GuidNumber AS OriginalGuidNumber
,[Period] AS DataPeriod
,[Year Period]
,CASE WHEN [Year Period]=YEAR(@StartDate) AND [Period]='P' +CAST(MONTH(@StartDate) AS VARCHAR(10)) THEN 1 ELSE 0 END AS CurrentData
,'Claim' AS [Level]
,FeeEarner
,[Date MI Updated]
,[Date re-opened]
,[Estimated Final Fee]
,[Policyholder Involvement]
,[Date Pleadings Issued]
,[Paid prior to instruction]
,[Master settlement value]
,CASE 
 WHEN (CASE WHEN [Date re-opened] >='2014-07-01' AND [Master Outcome] IS NOT NULL THEN Outcome
 WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master Outcome] IS NOT NULL THEN [Master Outcome]
 WHEN [Master Outcome] IS NULL THEN Outcome 
 END)='Pending' THEN 0
				WHEN [Date re-opened] >='2014-07-01' AND [Master settlement value] IS NOT NULL THEN 1
				WHEN ([Date re-opened] IS NULL OR [Date re-opened] <'2014-07-01') AND [Master settlement value] IS NOT NULL THEN 0
				WHEN [Master settlement value] IS NULL THEN 1 
			 END
			  AS MasterFlag

FROM CIS.MIUSLASnapshotData

WHERE InsertedDate BETWEEN @RollingStart AND @EndDate
AND InsertedDate <>'2014-08-31'
) AS SLAData
 
ON Periods.Period=SLAData.DataPeriod 
AND Periods.[Period Year]=SLAData.[Year Period]
WHERE CurrentData=1
)  AS Claim
  ON MIULeadLinkedSnapshot.case_id = Claim.case_id
  
  
WHERE [Reporting Level] IN(3,2)
AND (CASE WHEN UPPER(GuidNumber) ='LEGACY' OR UPPER(GuidNumber) ='Legacy File' THEN [CIS Reference] ELSE GuidNumber END) 
IN (SELECT GuidNumber FROM #Guids)








SELECT DISTINCT 
[CIS Reference]
,[Insured Name]
,[ID]
,[No. of Claimants]
,[RTA Date]
,[Date received]
,[Date Closed/declared dormant]
,[Status]
,[Outcome]
,[ABI Fraud Proven]
,[Is this a fraud ring]
,[Underwriting Referral Made?]
,[Fraud Type]
,CASE WHEN Orderx=2 THEN [MI Reserve] ELSE NULL END AS[MI Reserve]
,CASE WHEN Orderx=3 AND [IsMaster]=1 THEN 0.00 ELSE [Settlement Value] END AS [Settlement Value]
,[Master settlement value]
,[Pre Lit Fees]
,[Litigated Fees]
,[Disbursements]
,Fees
,[Net Savings]
,[Potential Recovery]
,case_id
,a.GuidNumber AS GuidNumber
,OriginalGuidNumber
,DataPeriod
,[Year Period]
,CurrentData
,[Level]
,FeeEarner
,[Date MI Updated]
,[Date re-opened]
,[Estimated Final Fee]
,[Policyholder Involvement]
,[Date Pleadings Issued]
,[Paid prior to instruction]
,Orderx
,[IsMaster]
FROM #AllData AS a
LEFT OUTER JOIN (SELECT DISTINCT  GuidNumber,CASE WHEN [Settlement Value] = [Master settlement value] THEN 1 ELSE 0 END AS [IsMaster]  FROM  #AllData
WHERE Orderx=2
and GuidNumber <>'Legacy File'

)  AS b
 ON a.GuidNumber=b.GuidNumber
WHERE  CurrentData=1














END 
GO
