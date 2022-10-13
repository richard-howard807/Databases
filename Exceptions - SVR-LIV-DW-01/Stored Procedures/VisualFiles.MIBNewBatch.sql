SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[MIBNewBatch] --[VisualFiles].[MIBNewBatch] '2016'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT DateOpened
,Title + ' '  + Forename + ' ' + Surname AS Short_name,MIB_ClaimNumber
,MIB_ClaimNumber2
,OriginalBalance
,CurrentBalance
,CASE WHEN MilestoneCode='COMP' THEN 'Closed' ELSE 'Open' END AS FileStatus
    ,CLO_ClosureCode
    ,CLO_ClosureReason
	,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END AS [ADA28]
 FROM VFile_Streamlined.dbo.AccountInformation
LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens ON AccountInformation.mt_int_code=ClientScreens.mt_int_code
LEFT OUTER JOIN (SELECT * FROM VFile_Streamlined.dbo.DebtorInformation WHERE ContactType='Primary Debtor') AS Debtor
 ON AccountInformation.mt_int_code=Debtor.mt_int_code
LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON AccountInformation.mt_int_code=ADA.mt_int_code
WHERE ClientName IN ('MIB Review File','MIB')

AND (
DateOpened BETWEEN @StartDate AND @EndDate
OR CLO_ClosedDate BETWEEN @StartDate AND @EndDate
)
END
GO
