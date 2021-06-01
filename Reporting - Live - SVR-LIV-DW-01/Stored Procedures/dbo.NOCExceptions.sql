SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









CREATE PROCEDURE [dbo].[NOCExceptions] -- EXEC NOCExceptions 'Casualty Birmingham'
(
@Team NVARCHAR(MAX)
)
AS 

BEGIN

IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team

	CREATE TABLE #Team 
	( ListValue NVARCHAR(MAX) collate Latin1_General_BIN)
	INSERT INTO #Team
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Team) 

SELECT 
ms_fileid
,dim_matter_header_current.client_code AS Client
,dim_matter_header_current.matter_number AS [Matter]
,master_client_code + '-' + master_matter_number AS [MS Ref]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,name AS [Matter Manager]
,worksforname AS [TM]
,ISNULL(Defendant.NumberDefendants,0) AS NumberDefendants
,Defendant.CorrectDefaultAddress AS DefaultedDefendantAddress
,ISNULL(Claimants.NumberClaimants,0) AS [NumberClaimants]
,Claimants.ClaimantsCorrectDefaultAddress AS ClaimantsCorrectDefaultAddress
,ISNULL(Court.NumberCourt,0) AS NumberCourts
,Court.CourtCorrectDefaultAddress AS CourtCorrectDefaultAddress
,Court.CourtEmail AS CourtEmailAdded
,ISNULL(ClaimantSols.NumberClaimantSols,0) AS NumberClaimantSols
,ClaimantSols.ClaimantSolsCorrectDefaultAddress
,ClaimantSols.ClaimantSolEmail
,ClaimantSols.ClaimantSolRef
,CASE WHEN ISNULL(Defendant.NumberDefendants,0) >1 
OR ISNULL(Claimants.NumberClaimants,0)>1
OR ISNULL(Court.NumberCourt,0)>1 
OR ISNULL(ClaimantSols.NumberClaimantSols,0)>1
THEN 'Red' 
WHEN ISNULL(Defendant.NumberDefendants,0)=1 
AND ISNULL(Claimants.NumberClaimants,0)=1
AND ISNULL(Court.NumberCourt,0)=1
AND ISNULL(ClaimantSols.NumberClaimantSols,0)=1
AND Defendant.CorrectDefaultAddress='Yes'
AND Claimants.ClaimantsCorrectDefaultAddress='Yes'
AND Court.CourtCorrectDefaultAddress='Yes'
AND Court.CourtRefAdded='Yes'
AND Court.CourtEmail='Yes'
AND ClaimantSols.ClaimantSolsCorrectDefaultAddress='Yes'
AND ClaimantSols.ClaimantSolEmail='Yes'
AND ClaimantSols.ClaimantSolRef='Yes'

THEN 'Green' ELSE 'Orange'
END AS ExceptionsColour

,CASE WHEN ISNULL(Defendant.NumberDefendants,0) >1 
OR ISNULL(Claimants.NumberClaimants,0)>1
OR ISNULL(ClaimantSols.NumberClaimantSols,0)>1 THEN 'Red' 
WHEN ISNULL(Defendant.NumberDefendants,0)=1 
AND ISNULL(Claimants.NumberClaimants,0)=1
AND ISNULL(ClaimantSols.NumberClaimantSols,0)=1
AND Defendant.CorrectDefaultAddress='Yes'
AND Claimants.ClaimantsCorrectDefaultAddress='Yes'
AND ClaimantSols.ClaimantSolsCorrectDefaultAddress='Yes'
AND ClaimantSols.ClaimantSolEmail='Yes'
AND ClaimantSols.ClaimantSolRef='Yes'
 THEN 'Green' ELSE 'Orange'
END AS ExceptionsColourPreLit

,referral_reason
,ISNULL(proceedings_issued,'No') AS ProceedingIssued
,name AS [Display_Name]
,fed_code AS [Fee Earner]
,hierarchylevel2hist AS [Business Line]
,hierarchylevel3hist AS [Practice Area]
,hierarchylevel4hist AS [Team]
,1 AS [Number Live Matters]
,dim_detail_core_details.present_position
,branch_name
,branch_code
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.[dbo].[dim_fed_hierarchy_history]
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN #Team AS Team ON Team.ListValue = REPLACE(hierarchylevel4hist,',','')
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
  ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
  AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number

LEFT OUTER JOIN 
(
SELECT Defendant.fileID,
       Defendant.NumberDefendants AS NumberDefendants,
       CASE WHEN Defendant.CorrectDefaultAddress >0 THEN 'No' ELSE 'Yes' END AS CorrectDefaultAddress
FROM	(
SELECT fileID
,COUNT(1) AS NumberDefendants
,SUM(CASE WHEN assocdefaultaddID IS NULL OR assocdefaultaddID=contDefaultAddress THEN 0 ELSE 1 END) AS CorrectDefaultAddress 
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND assocActive=1
GROUP BY fileID
) AS Defendant
) AS Defendant
 ON Defendant.fileID=ms_fileid
LEFT OUTER JOIN 
(
SELECT Claimants.fileID,
       Claimants.NumberClaimants AS NumberClaimants,
       CASE WHEN Claimants.ClaimantsCorrectDefaultAddress >0 THEN 'No' ELSE 'Yes' END AS ClaimantsCorrectDefaultAddress
FROM	(
SELECT fileID
,COUNT(1) AS NumberClaimants
,SUM(CASE WHEN assocdefaultaddID IS NULL OR assocdefaultaddID=contDefaultAddress THEN 0 ELSE 1 END) AS ClaimantsCorrectDefaultAddress 
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='CLAIMANT'
AND assocActive=1
GROUP BY fileID
) AS Claimants
) AS Claimants
 ON ms_fileid=Claimants.fileID
LEFT OUTER JOIN 
(
SELECT Court.fileID,
       Court.NumberCourt AS NumberCourt,
       CASE WHEN Court.CourtCorrectDefaultAddress >0 THEN 'No' ELSE 'Yes' END AS CourtCorrectDefaultAddress,
       CASE WHEN Court.CourtRef >0 THEN 'No' ELSE 'Yes' END AS CourtRefAdded,
	   CASE WHEN Court.CourtRef >0 THEN 'No' ELSE 'Yes' END AS CourtEmail

FROM	(
SELECT fileID
,COUNT(1) AS NumberCourt
,SUM(CASE WHEN assocdefaultaddID IS NULL OR assocdefaultaddID=contDefaultAddress THEN 0 ELSE 1 END) AS CourtCorrectDefaultAddress 
,SUM(CASE WHEN assocRef IS NULL THEN 1 ELSE 0 END) AS CourtRef
,SUM(CASE WHEN assocEmail IS NULL THEN 1 ELSE 0 END) AS CourtEmail
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='COUNTYCRT'
AND assocActive=1
GROUP BY fileID
) AS Court

) AS Court
 ON ms_fileid=Court.fileID
LEFT OUTER JOIN 
(
SELECT ClaimantSols.fileID,
       ClaimantSols.NumberClaimantSols AS NumberClaimantSols,
       CASE WHEN ClaimantSols.ClaimantSolsCorrectDefaultAddress >0 THEN 'No' ELSE 'Yes' END AS ClaimantSolsCorrectDefaultAddress
	   ,CASE WHEN ClaimantSols.ClaimantSolEmail >0 THEN 'No' ELSE 'Yes' END  AS ClaimantSolEmail
	   ,CASE WHEN ClaimantSols.ClaimantSolRef >0 THEN 'No' ELSE 'Yes' END AS ClaimantSolRef

FROM	(
SELECT fileID
,COUNT(1) AS NumberClaimantSols
,SUM(CASE WHEN assocdefaultaddID IS NULL OR assocdefaultaddID=contDefaultAddress THEN 0 ELSE 1 END) AS ClaimantSolsCorrectDefaultAddress 
,SUM(CASE WHEN assocRef IS NULL THEN 1 ELSE 0 END) AS ClaimantSolRef
,SUM(CASE WHEN assocEmail IS NULL THEN 1 ELSE 0 END) AS ClaimantSolEmail
FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='CLAIMANTSOLS'
AND assocActive=1
GROUP BY fileID
) AS ClaimantSols

) AS ClaimantSols
 ON ms_fileid=ClaimantSols.fileID
LEFT OUTER JOIN ms_prod.config.dbFile
 ON dbFile.fileID = Claimants.fileID
WHERE [hierarchylevel2hist]='Legal Ops - Claims'
AND ms_only=1
AND date_closed_case_management IS NULL
--AND ISNULL(referral_reason,'') <>'Advice only'
AND dim_matter_header_current.client_code <>'00030645'
AND ms_fileid NOT IN (SELECT fileID FROM ms_prod.dbo.udClaimCleanseExclude)
AND ISNULL(dim_detail_core_details.present_position,'') NOT IN ('Final bill due - claim and costs concluded','Final bill sent - unpaid','To be closed/minor balances to be clear')
AND ISNULL(branch_name,'') <>'Liverpool'

END
GO
