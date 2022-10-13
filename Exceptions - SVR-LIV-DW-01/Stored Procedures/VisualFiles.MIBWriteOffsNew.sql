SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [VisualFiles].[MIBWriteOffsNew]	 --[VisualFiles].[MIBWriteOffsNew]	'2018-05-01','2018-05-31'		
    @StartDate	DATE	
,	@EndDate	DATE    
AS 

SELECT
Clients.MIB_ClaimNumber									             AS [File]
,name AS [Fee Earner]
,SOLADM.ADM_NameOfDebtorOnLetter									     AS Def_Name
,CLO_ClosureCode AS W_O_Code	,	AccountInfo.CLO_ClosedDate								             AS Date_File_Closed
,	AccountInfo.CurrentBalance						                     AS Amount
,   AccountInfo.DateOpened           AS DatePlaced
,CLO_ClosureCode
,CLO_ClosureReason
,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END [Placement]
--,ISNULL(ADA.ADA28,'No') AS [ADA28]
FROM  [VFile_streamlined].dbo.Accountinformation AS AccountInfo
 INNER JOIN [VFile_streamlined].dbo.ClientScreens AS Clients
    ON   AccountInfo.mt_int_code = Clients.mt_int_code 
 INNER JOIN [VFile_streamlined].dbo.SOLADM AS SOLADM
    ON   AccountInfo.mt_int_code = SOLADM.mt_int_code
 LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON Accountinfo.mt_int_code=ADA.mt_int_code
    	
    	LEFT OUTER JOIN VFile_Streamlined.dbo.fee ON  RIGHT(level_fee_earner,3)=fee_earner	
    WHERE	AccountInfo.FileStatus = 'COMP'
      AND ClientName LIKE '%MIB%'
      AND AccountInfo.CLO_ClosedDate		BETWEEN  @StartDate AND @EndDate
        
        ORDER BY Clients.MIB_ClaimNumber
GO
