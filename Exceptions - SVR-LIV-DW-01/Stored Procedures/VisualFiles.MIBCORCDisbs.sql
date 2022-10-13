SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[MIBCORCDisbs]
AS
BEGIN
SELECT DISTINCT 
MIB_ClaimNumber AS [MIB Reference]
,MatterCode
,Debtor AS [Defendant Name]
,OriginalBalance AS [Original Balance]
,CurrentBalance AS [Current Balance]
,CASE WHEN (CASE WHEN ISNULL(CHO_Finalorderdated,'1900-01-01')='1900-01-01' THEN ISNULL(CHO_Interimdate,'1900-01-01') ELSE ISNULL(CHO_Finalorderdated,'1900-01-01')  END)='1900-01-01' THEN NULL 
ELSE (CASE WHEN ISNULL(CHO_Finalorderdated,'1900-01-01')='1900-01-01' THEN ISNULL(CHO_Interimdate,'1900-01-01') ELSE ISNULL(CHO_Finalorderdated,'1900-01-01')  END) END  AS [Charge Date]
,MilestoneCode
FROM VFile_Streamlined.dbo.DebtLedger
INNER JOIN VFile_Streamlined.dbo.AccountInformation ON DebtLedger.mt_int_code=AccountInformation.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens
 ON DebtLedger.mt_int_code=ClientScreens.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.Charges
 ON DebtLedger.mt_int_code=Charges.mt_int_code AND (ISNULL(CHO_Interimdate,'1900-01-01') <>'1900-01-01' OR ISNULL(CHO_Finalorderdated,'1900-01-01') <>'1900-01-01' )
LEFT OUTER JOIN (SELECT DebtorInformation.mt_int_code,ISNULL(Title,'')  + ' ' + ISNULL(Forename,'')  + ' ' + ISNULL(Surname,'')  AS Debtor
,ISNULL(Address1,'') + ' ' + ISNULL(Address2,'')  + ' ' + ISNULL(Address3,'')  + ' ' + ISNULL(Address4,'')  + ' ' + ISNULL(PostCode,'')  AS [DebtorAddress]
FROM VFile_Streamlined.dbo.DebtorInformation
INNER JOIN VFile_Streamlined.dbo.AccountInformation ON DebtorInformation.mt_int_code=AccountInformation.mt_int_code
WHERE ContactType='Primary Debtor'
AND ClientName LIKE '%MIB%') AS Addresses
 ON DebtLedger.mt_int_code=Addresses.mt_int_code


WHERE ItemCode='CORC'
AND TransactionType='COST'
AND ClientName LIKE '%MIB%'
AND ISNULL(FileStatus,'')<>'COMP'
ORDER BY MIB_ClaimNumber
END
GO
