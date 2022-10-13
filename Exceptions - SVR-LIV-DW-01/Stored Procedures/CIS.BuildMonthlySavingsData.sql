SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [CIS].[BuildMonthlySavingsData]
AS
BEGIN
DECLARE @StartDate AS Date
SET @StartDate=CONVERT(DATE,GETDATE(),103)

DECLARE @Period AS DATE

SET @Period=(SELECT EndDate FROM dbo.LCDHistoricalPeriods WHERE @StartDate BETWEEN StartDate AND EndDate)

PRINT @Period



DELETE FROM CIS.CISSavingsRefs
WHERE [Inserted Date]=@Period

INSERT INTO CIS.CISSavingsRefs
(
ClaimNo
,FullPeriod
,Period
,[Period Year]
,[Inserted Date]
)
SELECT [CIS Reference],CASE WHEN [Status]='Dormant - 50% Confidence' THEN 'Period ' + CAST(MONTH(@StartDate) AS VARCHAR(2)) + ' ' + CAST(YEAR(@StartDate) AS VARCHAR(4)) 
ELSE 'Legacy' END 
,'Period ' + CAST(MONTH(@Period) AS VARCHAR(2)) AS Period
,YEAR(@Period) AS [Period Year]
,@Period FROM CIS.MIUSLASnapshotData AS SnapshotData
LEFT OUTER JOIN CIS.CISSavingsRefs AS SavingsRefs
 ON SnapshotData.[CIS Reference]=SavingsRefs.ClaimNo
WHERE InsertedDate=@StartDate
AND SavingsRefs.ClaimNo IS NULL
AND [Status] IN ('Legally Closed','Dormant - 95% Confidence','Dormant - 50% Confidence')
AND Outcome IN
(
'Reduced Settlement'
,'Gone Away'
,'Withdrawn'
,'Claims Fraud TP'
,'Claims Fraud PH'
,'Indemnity Fraud'
)


DELETE FROM CIS.MIUSavingsData WHERE [Inserted Date]=@Period

INSERT INTO CIS.MIUSavingsData
(
case_id
,[CIS Ref]
,[Insured Name]
,[Provider Ref]
,[Nbr Of Claimants]
,[RTA Date]
,[Date Received]
,[Date Closed/  Declared Dormant]
,[Status]
,[Outcome]
,[MI Reserve]
,[Paid Prior To Instruction]
,[Settlement Value]
,[Fees]
,[Net savings]
,[Potential Recovery]
,[Blank1]
,[Blank2]
,[Date 50% Dormant]
,[Savings from 50% Dormant]
,[Currently still 50% stage]
,[Blank3]
,[Period Closed/Dormant]
,[Savings from Closed Dormant]
,[Inserted Date]
)
SELECT 
case_id,[CIS Reference] AS [CIS Ref]
,[Insured Name] AS [Insured Name]
,RTRIM(ID +'.'+FeeEarner) AS [Provider Ref]
,[No. of Claimants] AS [Nbr Of Claimants]
,[RTA Date] AS [RTA Date]
,[Date Received] AS [Date Received]
,[Date Closed/declared dormant] AS [Date Closed/  Declared Dormant]
,RTRIM([Status]) AS [Status]
,RTRIM(Outcome) AS [Outcome]
,[MI Reserve] AS [MI Reserve]
,[Paid prior to instruction] AS [Paid Prior To Instruction]
,[Settlement Value] AS [Settlement Value]
,Fees AS [Fees]
,CASE WHEN [Date Closed/declared dormant] IS NULL THEN NULL ELSE  ISNULL([MI Reserve],0) -  ISNULL([Settlement Value],0) - ISNULL([Fees],0) END AS [Net savings]
,[Potential Recovery] AS [Potential Recovery]
,'' AS Blank1
,'' AS Blank2
,SavingsRefs.FullPeriod AS [Date 50% Dormant]
,CASE WHEN UPPER(SavingsRefs.FullPeriod)='LEGACY' THEN 0 ELSE (CASE WHEN [Date Closed/declared dormant] IS NULL THEN NULL ELSE  ISNULL([MI Reserve],0) -  ISNULL([Settlement Value],0) - ISNULL([Fees],0) END) *0.80 END  AS [Savings from 50% Dormant]
,CASE WHEN (CASE 
WHEN [CIS Reference] IN ('281472003T','281017804P','222077104T','281257605D','233595110D','282039302P','281779103M','281964302F','282117702M','281138803B') THEN 'Pre'
WHEN [Status] IN ('Legally Closed','Dormant - 95% Confidence') THEN 'Period' + ' ' + CAST(Month([Date Closed/declared dormant]) AS VARCHAR(2)) + ' ' + CAST(Year([Date Closed/declared dormant]) AS VARCHAR(4))
ELSE NULL END) IS NULL THEN 1 ELSE 0 END AS [Currently still 50% stage]
,'' AS Blank3
,CASE 
WHEN [Date Closed/declared dormant] <'2010-01-01' THEN LCDPeriods.ClosedPeriod 
WHEN [Status] IN ('Legally Closed','Dormant - 95% Confidence') THEN 'Period' + ' ' + CAST(Month([Date Closed/declared dormant]) AS VARCHAR(2)) + ' ' + CAST(Year([Date Closed/declared dormant]) AS VARCHAR(4))
ELSE NULL END AS [Period Closed/Dormant]
,CASE WHEN (CASE 
WHEN [Date Closed/declared dormant] <'2010-01-01' THEN LCDPeriods.ClosedPeriod 
WHEN [Status] IN ('Legally Closed','Dormant - 95% Confidence') THEN 'Period' + ' ' + CAST(Month([Date Closed/declared dormant]) AS VARCHAR(2)) + ' ' + CAST(Year([Date Closed/declared dormant]) AS VARCHAR(4))
ELSE NULL END) IS NULL THEN NULL ELSE 

(CASE WHEN [Date Closed/declared dormant] IS NULL THEN NULL ELSE  ISNULL([MI Reserve],0) -  ISNULL([Settlement Value],0) - ISNULL([Fees],0) END) -
(CASE WHEN UPPER(SavingsRefs.FullPeriod)='LEGACY' THEN 0 ELSE (CASE WHEN [Date Closed/declared dormant] IS NULL THEN NULL ELSE  ISNULL([MI Reserve],0) -  ISNULL([Settlement Value],0) - ISNULL([Fees],0) END) *0.80 END)
END  AS [Savings from Closed Dormant]
,@Period AS [Inserted Date]
FROM CIS.MIUSLASnapshotData AS SnapshotData
LEFT OUTER JOIN CIS.CISSavingsRefs AS SavingsRefs
 ON SnapshotData.[CIS Reference]=SavingsRefs.ClaimNo
LEFT OUTER JOIN [dbo].[LCDHistoricalPeriods] AS LCDPeriods
 ON [Date Closed/declared dormant] BETWEEN StartDate AND EndDate
WHERE InsertedDate=@StartDate
AND [Status] IN ('Legally Closed','Dormant - 95% Confidence','Dormant - 50% Confidence')
AND Outcome IN
(
'Reduced Settlement'
,'Gone Away'
,'Withdrawn'
,'Claims Fraud TP'
,'Claims Fraud PH'
,'Indemnity Fraud'
)

END

GO
