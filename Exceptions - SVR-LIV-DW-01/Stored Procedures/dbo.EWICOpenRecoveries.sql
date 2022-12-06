SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[EWICOpenRecoveries]

AS 

BEGIN 

SELECT GETDATE() AS [Report Date]
,CASE WHEN [Loss Number] = '' THEN a.Claim_Number
ELSE [Loss Number] END AS [EWIC Ref] 
,a.Claim_Number AS ClaimNumber
,a.Claim_Handler_Code AS Claim_Handler
,[Customer Reference] [Customer Reference]
,[Claimant Name] AS ClaimantName
,a.Zurich_Policy_No AS PolicyNumber
,a.Loss_Type AS ClaimType
,a.Recovery_Group_Status
,a.Recovery_Phase

--,SD.GrossOSLRTotal AS [NetOSLRTotal (Net of recovery)]
--,SD.Net_Paid_Current
--,SD.Net_Incurred_Current
--,CONCAT((Case When SD.Net_Incurred_Current <0 Then 'REC' Else NUll End),(Case When Round(ABS(Net_Incurred_Current),2) < 49999.99 Then '0-50K' 
--When Round(ABS(Net_Incurred_Current),2) < 499999.99 Then '50-500K'
--When Round(ABS(Net_Incurred_Current),2) > 499999.99 Then '500K+' Else 'NA'
--End)) AS [Incurred Category]
--,Development_Total_Incurred
,Development_Code  AS [Large Loss Name of Development]
,CASE WHEN a.Claim_Status = 'REOPEN' AND b.Reopened_Date != '' THEN 'Reopened' ELSE 'Open' END AS ClaimStatus
,a.Incident AS[Category/type of claim ]
,a.Policy_Wording AS [Policy Wording]
,a.New_or_Rectification_Work AS[New / Rectification Work]
,a.RoM_Recoveries_Status AS [RoM Recovery Status]
,a.Litigated_Recoveries_Status AS [Litigated Recovery Status]
,CAST(CONVERT(DATE,CASE WHEN Date_when_recovery_expected_to_enter_next_phase='' THEN NULL ELSE Date_when_recovery_expected_to_enter_next_phase END,103) AS DATETIME) AS[Date when recovery expected to enter next phase]
, TargetOne.TARGETS_Entity AS [Name of target entity 1]
, CASE WHEN TargetOne.TARGETS_Type_Of_Target='EA' THEN 'EWIC appointed Architect'
WHEN TargetOne.TARGETS_Type_Of_Target='EC' THEN 'EWIC appointed Contractor'
WHEN TargetOne.TARGETS_Type_Of_Target='ED' THEN 'EWIC appointed Developer'
WHEN TargetOne.TARGETS_Type_Of_Target='EE' THEN 'EWIC appointed Engineer'
WHEN TargetOne.TARGETS_Type_Of_Target='EL' THEN 'EWIC appointed Loss Adjustor'
WHEN TargetOne.TARGETS_Type_Of_Target='EP' THEN 'EWIC appointed Product Supplier'
WHEN TargetOne.TARGETS_Type_Of_Target='ES' THEN 'EWIC appointed Surveyor'
WHEN TargetOne.TARGETS_Type_Of_Target='OA' THEN 'Original Architect'
WHEN TargetOne.TARGETS_Type_Of_Target='OC' THEN 'Original Contractor'
WHEN TargetOne.TARGETS_Type_Of_Target='OD' THEN 'Original Developer'
WHEN TargetOne.TARGETS_Type_Of_Target='OE' THEN 'Original Engineer'
WHEN TargetOne.TARGETS_Type_Of_Target='OP' THEN 'Original Product Supplier'
WHEN TargetOne.TARGETS_Type_Of_Target='OS' THEN 'Original Surveyor'
WHEN TargetOne.TARGETS_Type_Of_Target='ZA' THEN 'Zurich appointed Architect'
WHEN TargetOne.TARGETS_Type_Of_Target='ZC' THEN 'Zurich appointed Contractor'
WHEN TargetOne.TARGETS_Type_Of_Target='ZD' THEN 'Zurich appointed Developer'
WHEN TargetOne.TARGETS_Type_Of_Target='ZE' THEN 'Zurich appointed Engineer'
WHEN TargetOne.TARGETS_Type_Of_Target='ZL' THEN 'Zurich appointed Loss Adjustor'
WHEN TargetOne.TARGETS_Type_Of_Target='ZP' THEN 'Zurich appointed Product Supplier'
WHEN TargetOne.TARGETS_Type_Of_Target='ZS' THEN 'Zurich appointed Surveyor'
END  AS [Type of target entity 1]
, TargetOne.TARGETS_Limitation_Date AS [Limitation date in relation to entity 1]
, TargetTwo.TARGETS_Entity AS [Name of target entity 2]
, CASE WHEN TargetTwo.TARGETS_Type_Of_Target='EA' THEN 'EWIC appointed Architect'
WHEN TargetTwo.TARGETS_Type_Of_Target='EC' THEN 'EWIC appointed Contractor'
WHEN TargetTwo.TARGETS_Type_Of_Target='ED' THEN 'EWIC appointed Developer'
WHEN TargetTwo.TARGETS_Type_Of_Target='EE' THEN 'EWIC appointed Engineer'
WHEN TargetTwo.TARGETS_Type_Of_Target='EL' THEN 'EWIC appointed Loss Adjustor'
WHEN TargetTwo.TARGETS_Type_Of_Target='EP' THEN 'EWIC appointed Product Supplier'
WHEN TargetTwo.TARGETS_Type_Of_Target='ES' THEN 'EWIC appointed Surveyor'
WHEN TargetTwo.TARGETS_Type_Of_Target='OA' THEN 'Original Architect'
WHEN TargetTwo.TARGETS_Type_Of_Target='OC' THEN 'Original Contractor'
WHEN TargetTwo.TARGETS_Type_Of_Target='OD' THEN 'Original Developer'
WHEN TargetTwo.TARGETS_Type_Of_Target='OE' THEN 'Original Engineer'
WHEN TargetTwo.TARGETS_Type_Of_Target='OP' THEN 'Original Product Supplier'
WHEN TargetTwo.TARGETS_Type_Of_Target='OS' THEN 'Original Surveyor'
WHEN TargetTwo.TARGETS_Type_Of_Target='ZA' THEN 'Zurich appointed Architect'
WHEN TargetTwo.TARGETS_Type_Of_Target='ZC' THEN 'Zurich appointed Contractor'
WHEN TargetTwo.TARGETS_Type_Of_Target='ZD' THEN 'Zurich appointed Developer'
WHEN TargetTwo.TARGETS_Type_Of_Target='ZE' THEN 'Zurich appointed Engineer'
WHEN TargetTwo.TARGETS_Type_Of_Target='ZL' THEN 'Zurich appointed Loss Adjustor'
WHEN TargetTwo.TARGETS_Type_Of_Target='ZP' THEN 'Zurich appointed Product Supplier'
WHEN TargetTwo.TARGETS_Type_Of_Target='ZS' THEN 'Zurich appointed Surveyor'
 END  AS [Type of target entity 2]
, TargetTwo.TARGETS_Limitation_Date AS [Limitation date in relation to entity 2]
, TargetThree.TARGETS_Entity AS [Name of target entity 3]
, CASE WHEN TargetThree.TARGETS_Type_Of_Target='EA' THEN 'EWIC appointed Architect'
WHEN TargetThree.TARGETS_Type_Of_Target='EC' THEN 'EWIC appointed Contractor'
WHEN TargetThree.TARGETS_Type_Of_Target='ED' THEN 'EWIC appointed Developer'
WHEN TargetThree.TARGETS_Type_Of_Target='EE' THEN 'EWIC appointed Engineer'
WHEN TargetThree.TARGETS_Type_Of_Target='EL' THEN 'EWIC appointed Loss Adjustor'
WHEN TargetThree.TARGETS_Type_Of_Target='EP' THEN 'EWIC appointed Product Supplier'
WHEN TargetThree.TARGETS_Type_Of_Target='ES' THEN 'EWIC appointed Surveyor'
WHEN TargetThree.TARGETS_Type_Of_Target='OA' THEN 'Original Architect'
WHEN TargetThree.TARGETS_Type_Of_Target='OC' THEN 'Original Contractor'
WHEN TargetThree.TARGETS_Type_Of_Target='OD' THEN 'Original Developer'
WHEN TargetThree.TARGETS_Type_Of_Target='OE' THEN 'Original Engineer'
WHEN TargetThree.TARGETS_Type_Of_Target='OP' THEN 'Original Product Supplier'
WHEN TargetThree.TARGETS_Type_Of_Target='OS' THEN 'Original Surveyor'
WHEN TargetThree.TARGETS_Type_Of_Target='ZA' THEN 'Zurich appointed Architect'
WHEN TargetThree.TARGETS_Type_Of_Target='ZC' THEN 'Zurich appointed Contractor'
WHEN TargetThree.TARGETS_Type_Of_Target='ZD' THEN 'Zurich appointed Developer'
WHEN TargetThree.TARGETS_Type_Of_Target='ZE' THEN 'Zurich appointed Engineer'
WHEN TargetThree.TARGETS_Type_Of_Target='ZL' THEN 'Zurich appointed Loss Adjustor'
WHEN TargetThree.TARGETS_Type_Of_Target='ZP' THEN 'Zurich appointed Product Supplier'
WHEN TargetThree.TARGETS_Type_Of_Target='ZS' THEN 'Zurich appointed Surveyor'
 END AS [Type of target entity 3]
, TargetThree.TARGETS_Limitation_Date AS [Limitation date in relation to entity 3]
, Overall_prospects_of_successful_recovery AS [Overall prospects of successful recovery]
, Total_recovery_made_to_date AS [Total recovery made to date]
, Reasonably_expected_recovery_value AS [Reasonably expected recovery value]
,CAST(CONVERT(DATE,CASE WHEN Anticipated_Resolution_Date='' THEN NULL ELSE Anticipated_Resolution_Date END,103) AS DATETIME)  AS[Date anticipated resolution of claim]
,zvwClaimDetail.[Loss Name] AS Loss_name
,Projected_contribution_value
,Total_contribution_made
,a.Claim_Status AS [Polygonal Claim Status]
,a.Claim_Category AS [Polygonal Claim Category]
FROM [SVR-LIV-3PTY-01].Wellington_Live.dbo.dqvwCustomClaimFields AS a WITH(NOLOCK)
INNER JOIN  [SVR-LIV-3PTY-01].[Wellington_Live].[dbo].[dqvwClaim_Register] AS b WITH(NOLOCK)
 ON b.Claim_Number = a.Claim_Number
LEFT OUTER JOIN 
(
SELECT Claim_Number,TARGETS_Entity,TARGETS_Type_Of_Target,TARGETS_Limitation_Date 
FROM [SVR-LIV-3PTY-01].[Wellington_Live].[dbo].[vwCLAIMS_CUSTOM_Exp] WITH(NOLOCK)
WHERE TARGETS_Entity<>''
AND RIGHT(UID,2)='|1'
) AS TargetOne
 ON a.Claim_Number=TargetOne.Claim_Number COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT Claim_Number,TARGETS_Entity,TARGETS_Type_Of_Target,TARGETS_Limitation_Date 
FROM [SVR-LIV-3PTY-01].[Wellington_Live].[dbo].[vwCLAIMS_CUSTOM_Exp] WITH(NOLOCK)
WHERE TARGETS_Entity<>''
AND RIGHT(UID,2)='|2'
) AS TargetTwo
 ON a.Claim_Number=TargetTwo.Claim_Number COLLATE DATABASE_DEFAULT

LEFT OUTER JOIN 
(
SELECT Claim_Number,TARGETS_Entity,TARGETS_Type_Of_Target,TARGETS_Limitation_Date 
FROM [SVR-LIV-3PTY-01].[Wellington_Live].[dbo].[vwCLAIMS_CUSTOM_Exp] WITH(NOLOCK)
WHERE TARGETS_Entity<>''
AND RIGHT(UID,2)='|3'
) AS TargetThree
 ON a.Claim_Number=TargetThree.Claim_Number COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN [SVR-LIV-3PTY-01].[Wellington_Live].[dbo].zvwClaimDetail WITH(NOLOCK)
 ON zvwClaimDetail.[Claim Number] = a.Claim_Number

WHERE a.Claim_Status NOT IN ('CLOSED','CANC')
END 
GO
