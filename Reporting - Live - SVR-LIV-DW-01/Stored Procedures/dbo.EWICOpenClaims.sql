SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[EWICOpenClaims]

AS 

BEGIN 

SELECT GETDATE() AS [Report Date]
,CASE WHEN [Loss Number] = '' THEN a.Claim_Number
ELSE [Loss Number] END AS [EWIC Ref] 
,a.Claim_Number AS ClaimNumber
,a.Claim_Handler_Code AS Claim_Handler
,[Customer Reference]
,[Claimant Name] AS ClaimantName
,b.Zurich_Policy_No AS PolicyNumber
,a.Loss_Type AS ClaimType
,[Claimant Post Code] AS [Claimant Post Code]
,CAST(CONVERT(DATE,CASE WHEN [Notification Date]='' THEN NULL ELSE [Notification Date] END,103) AS DATETIME) AS ClaimNotificationDate
--,RD.[Indemnity Loss] AS [Indemnity Loss OSLR]
--,RD.[Loss Expense] AS [Loss Expense OSLR]
--,RD.[Alternative_Accommodation] As [Alternative_Accommodation OSLR]
--,RD.[Mamagement Fee] AS [Management Fee OSLR]
--,RD.[Misc Loss] AS [Misc Loss OSLR]
--,SD.GrossOSLRIndemnity AS GrossOSLR
--,RD.Recovery As [Recovery OSLR]
--,RD.Subrogation AS [Subrogation OSLR]
--,SD.GrossOSLRRecoveryIndemity *-1 AS GrossOSLRRecovery
--,SD.GrossOSLRTotal AS [NetOSLRTotal (Net of recovery)]
--,SD.Net_Paid_Current
--,SD.Net_Incurred_Current
--,CONCAT((Case When SD.Net_Incurred_Current <0 Then 'REC' Else NUll End),(Case When Round(ABS(Net_Incurred_Current),2) < 49999.99 Then '0-50K' 
--When Round(ABS(Net_Incurred_Current),2) < 499999.99 Then '50-500K'
--When Round(ABS(Net_Incurred_Current),2) > 499999.99 Then '500K+' Else 'NA'
--End)) AS [Incurred Category]
--,Development_Total_Incurred
,[Loss Number] AS [Large Loss Number]
,Development
,[Loss Name] AS [Large Loss Name]

,CASE WHEN a.Claim_Status = 'REOPEN' AND Reopened_Date != '' THEN 'Reopened' ELSE 'Open' END AS ClaimStatus
,CAST(CONVERT(DATE,CASE WHEN Reopened_Date ='' THEN NULL ELSE Reopened_Date END,103) AS DATETIME) AS Reopened_Date
,Initial_Potential_Estimate AS[Initial Potential Estimate]
,CAST(CONVERT(DATE,CASE WHEN Date_IPE_likely_to_be_updated='' THEN NULL ELSE Date_IPE_likely_to_be_updated END,103) AS DATETIME) AS[Date on which IPE likely to be updated to Reserve]

,Policy_Wording AS[Policy Wording]
,New_or_Rectification_Work AS[New / Rectification Work]
,CASE WHEN Cunningham_Lindsay_as_Previous_Contractor='Y' THEN 'Yes' WHEN Cunningham_Lindsay_as_Previous_Contractor='N' THEN 'No' ELSE Cunningham_Lindsay_as_Previous_Contractor END AS[Cunningham Lindsay (Previous Contractor)]
--,CASE WHEN [Hardship_Considerations?]='Y' THEN 'Yes' WHEN [Hardship_Considerations?]='N' THEN 'No' ELSE [Hardship_Considerations?] END AS[Possible Hardship Considerations]
,FSCS_Qualifying_Test AS[FSCS qualifying test]
,FSCS_Eligibility_Status AS[FSCS eligibity status]
,Claim_Phase AS[Claim Phase]
,Priority AS[Priority]
,Waking_Watch_or_Fire_Notice_Issued AS[Waking Watch or Fire Notice issued]
,Reason_for_High_Priority AS[Reason For Priority]

,CAST(CONVERT(DATE,CASE WHEN Expected_Next_Phase_Date='' THEN NULL ELSE Expected_Next_Phase_Date END,103) AS DATETIME) AS[Date when claim expected to enter next phase]
,CAST(CONVERT(DATE,CASE WHEN Next_Review_Date='' THEN NULL ELSE Next_Review_Date END,103) AS DATETIME) AS[Next review date]
,CAST(CONVERT(DATE,CASE WHEN Anticipated_Resolution_Date ='' THEN NULL ELSE Anticipated_Resolution_Date END,103) AS DATETIME)  AS[Date anticipated resolution of claim]
,Group_Claim_Phase
,Hardship_Indicator
,a.Incident AS [Category/type of claim]
,a.Claim_Status AS [Polygonal Claim Status]
FROM [SVR-LIV-3PTY-01].Wellington_Live.dbo.dqvwCustomClaimFields AS a WITH(NOLOCK)
INNER JOIN  [SVR-LIV-3PTY-01].[Wellington_Live].[dbo].[dqvwClaim_Register] AS b WITH(NOLOCK)
 ON b.Claim_Number = a.Claim_Number
 LEFT OUTER JOIN [SVR-LIV-3PTY-01].[Wellington_Live].[dbo].zvwClaimDetail WITH(NOLOCK)
 ON zvwClaimDetail.[Claim Number] = a.Claim_Number
WHERE a.Claim_Status NOT IN ('CLOSED','CANC')
--AND a.Claim_Number='Z0577418000 '

END 
GO
