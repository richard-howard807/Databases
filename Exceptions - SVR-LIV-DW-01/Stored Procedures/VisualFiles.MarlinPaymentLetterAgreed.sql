SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[MarlinPaymentLetterAgreed] --EXEC VisualFiles.MarlinPaymentLetterAgreed '2016-09-01','2016-09-21'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT 
CDE_ClientAccountNumber AS [SupplierRef] 
,CDE_ClientAccountNumber AS [ClientRef] 
,Title
,Forename
,NULL AS [Middle Name]
,Surname
,[Payment arrangement agreed date]
,CASE WHEN [Date sent] IS NOT NULL THEN 'Y' ELSE 'N' END  AS [Payment Arrangement agreed letter sent?]
,[Date sent]

FROM VFile_Streamlined.dbo.AccountInformation AS AccountInfo
INNER JOIN (SELECT mt_int_code,MAX(History.HTRY_DateInserted) AS [Payment arrangement agreed date] FROM VFile_Streamlined.dbo.History WHERE UPPER(History.HTRY_description) LIKE '%NEW ARRANGEMENT%' AND HTRY_DateInserted BETWEEN @StartDate AND @EndDate GROUP BY mt_int_code) AS Arrangement
ON AccountInfo.mt_int_code=Arrangement.mt_int_code
LEFT  JOIN (SELECT mt_int_code,MAX(History.HTRY_DateInserted) AS [Date sent] FROM VFile_Streamlined.dbo.History WHERE UPPER(History.HTRY_description) LIKE '%ARRANGEMENT LETTER%' GROUP BY mt_int_code) AS Letter
ON AccountInfo.mt_int_code=Letter.mt_int_code

LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens ON AccountInfo.mt_int_code=ClientScreens.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.SOLCDE ON AccountInfo.mt_int_code=SOLCDE.mt_int_code
LEFT OUTER JOIN (SELECT * FROM VFile_Streamlined.dbo.DebtorInformation WHERE DebtorInformation.ContactType='Primary Debtor') AS Debtor
  ON AccountInfo.mt_int_code=Debtor.mt_int_code 
WHERE ClientName='Marlin'
AND FileStatus <>'COMP'
END
GO
