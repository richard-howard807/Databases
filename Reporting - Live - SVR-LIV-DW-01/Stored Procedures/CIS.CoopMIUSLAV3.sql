SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [CIS].[CoopMIUSLAV3] -- EXEC [CIS].[CoopMIUSLAV3] '2015-01-01','2015-01-31'
(
@StartDate AS DATE
,@EndDate AS Date
)
AS
BEGIN

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2015-01-01'
--SET @EndDate='2015-01-30'

--PRINT @StartDate
--PRINT @EndDate

DECLARE @PreviousData AS DATE

SET @PreviousData=(DATEADD(month, DATEDIFF(month, 0, DATEADD(DAY,-1,@StartDate)), 0))
PRINT @PreviousData


DECLARE @RollingStart AS DATE
SET @RollingStart=DATEADD(Month,-11,@StartDate)

PRINT @RollingStart

SELECT 
[case_id]
,Periods.Period  + ' ' + CAST(Periods.[Period Year] AS VARCHAR(10)) AS Period
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
,[Litigation]
,[Year Period]
,DataPeriod
,[Number opened claims]
,[Total Number of Claims In Litigation]
,[Number of Litigated Claims Concluded]
,[Number of Claims Entering Litigation]
,[InsertedDate]
,[caseid]
,[PreviousStatus]
,[PreviousPosition]
,CurrentData
,P11
,[Number closed within 360 days]
,[Number closed within 361-540 days]
,[Number closed within 541-720 days]
,[Number closed within 721-900 days]
,[Number closed within 901-1080 days]
,[Number closed over 1080 days]
,ReopenedPeriod
,[Number Reopened]
,MONTH([Date re-opened]) AS ReopenOrder
,[Date] AS PeriodOrder 
,[ABI Fraud Proven]
,[Is this a fraud ring]
,[Underwriting Referral Made]
,CASE WHEN [Date Closed/declared dormant] >='2016-01-01' THEN 1 ELSE 0 END AS ABIFilter
,CASE WHEN [ABI Fraud Proven]='Suspected' THEN 1 ELSE 0 END AS Suspected
,CASE WHEN [ABI Fraud Proven]='Proven' THEN 1 ELSE 0 END AS Proven
,CASE WHEN [ABI Fraud Proven]='Suspected' THEN [MI Reserve] ELSE 0 END AS SuspectedValue 
,CASE WHEN [ABI Fraud Proven]='Proven' THEN [MI Reserve] ELSE 0 END AS ProvenValue 
,[Pre Lit Fees],[Litigated Fees],[Disbursements] 
FROM 

(SELECT Period,[Period Year],[Date]  
FROM [dbo].[CISMIUPeriods] 
WHERE [Date] BETWEEN @RollingStart AND @EndDate
) AS Periods
INNER JOIN 
(
SELECT
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
,[Litigation]
,[Year Period]
,[Period] AS DataPeriod
,[Number opened claims]
,[Total Number of Claims In Litigation]
,[Number of Litigated Claims Concluded]
,[Number of Claims Entering Litigation]
,[InsertedDate]
,[caseid]
,[PreviousStatus]
,[PreviousPosition]
,CASE WHEN [Year Period]=YEAR(@StartDate) AND [Period]='P' +CAST(MONTH(@StartDate) AS VARCHAR(10)) THEN 1 ELSE 0 END AS CurrentData
,CASE WHEN Period='P11' THEN 1 ELSE 0 END AS P11
,CASE WHEN [Recept to File Closed Elapsed] BETWEEN 0 AND 360 THEN 1 ELSE 0 END AS [Number closed within 360 days]
,CASE WHEN [Recept to File Closed Elapsed] BETWEEN 361 AND 540 THEN 1 ELSE 0 END AS [Number closed within 361-540 days]
,CASE WHEN [Recept to File Closed Elapsed] BETWEEN 541 AND 720 THEN 1 ELSE 0 END AS [Number closed within 541-720 days]
,CASE WHEN [Recept to File Closed Elapsed] BETWEEN 721 AND 900 THEN 1 ELSE 0 END AS [Number closed within 721-900 days]
,CASE WHEN [Recept to File Closed Elapsed] BETWEEN 901 AND 1080 THEN 1 ELSE 0 END AS [Number closed within 901-1080 days]
,CASE WHEN [Recept to File Closed Elapsed] >1080 THEN 1 ELSE 0 END AS [Number closed over 1080 days]
,'P' +CAST(MONTH([Date re-opened])AS VARCHAR(MAX))  + ' '  + CAST(YEAR([Date re-opened])AS VARCHAR(MAX))  AS ReopenedPeriod
,CASE WHEN [Date re-opened] IS NOT NULL AND Period='P' +CAST(MONTH([Date re-opened])AS VARCHAR(MAX)) 
AND [Year Period]=YEAR([Date re-opened])  THEN 1 ELSE 0 END AS[Number Reopened]
,MONTH([Date re-opened]) AS ReopenOrder
,CAST(REPLACE(Period,'P','') AS INT) AS PeriodOrder
,[ABI Fraud Proven]
,[Is this a fraud ring]
,[Underwriting Referral Made]
,[Pre Lit Fees],[Litigated Fees],[Disbursements] 
FROM CIS.MIUSLASnapshotData
LEFT OUTER JOIN 
(
SELECT case_id AS caseid,[Status] AS PreviousStatus,[Present Position] AS PreviousPosition
FROM CIS.MIUSLASnapshotData
WHERE [Year Period]=YEAR(@PreviousData)
AND [Period]='P' +CAST(MONTH(@PreviousData) AS VARCHAR(10))
) AS PreviousData
 ON MIUSLASnapshotData.case_id=PreviousData.caseid
WHERE InsertedDate BETWEEN @RollingStart AND @EndDate
AND InsertedDate <>'2014-08-31'
) AS SLAData
 
ON Periods.Period=SLAData.DataPeriod 
AND Periods.[Period Year]=SLAData.[Year Period]
END

GO
