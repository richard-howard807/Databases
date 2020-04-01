SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [CommercialRecoveries].[UPSFixedFeeDisbs]
(
@StartDAte AS DATE
,@EndDate AS DATE
,@Report AS NVARCHAR(MAX)
) 
AS 
BEGIN

SELECT 
ISNULL(CRSystemSourceID,clNo +'-' + fileNo) AS [F&W Ref]
,txtCliRef AS [UPS Acc No]	
,Defendant.Defendant AS [Debtor Name]
,red_dw.dbo.datetimelocal(dtePosted) AS [Action Date]
,txtItemDesc AS [Description]	
,curOffice AS [Fixed Costs]	
,curVAT AS [Vat]
,ISNULL(curOffice,0) + ISNULL(curVAT,0) AS [Total]
,CASE WHEN cboCatDesc='7' THEN 'Fixed Cost' ELSE 'Disbursements' END AS CategoryType
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN [MS_PROD].config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
WHERE (CRSystemSourceID  LIKE '13329-%' OR clNo='FW13329' OR clNo='FW13905')
AND cboCatDesc IN ('7','1','0')
AND fileType='2038'
AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103) BETWEEN @StartDate AND @EndDate
AND (CASE WHEN 	txtCliRef LIKE '8GB%' OR txtCliRef='6GB%' THEN 'UPS COD' ELSE 'UPS Exc COD' END)=@Report
AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103)>'2020-02-29'
ORDER BY dtePosted

END
GO
