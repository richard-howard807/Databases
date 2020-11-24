SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



--EXEC CommercialRecoveries.BMWAlphabetClosures 'BMW' ,'2020-08-01','2020-09-03'
CREATE PROCEDURE [CommercialRecoveries].[BMWAlphabetClosures]
(
 @Client AS NVARCHAR(50)
,@StartDate AS  DATE
,@EndDate  AS DATE
)
AS

BEGIN
--DECLARE @Client AS NVARCHAR(MAX)
--SET @Client='BMW'

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2020-08-01'
--SET @EndDate='2020-09-03'

SELECT txtCliRef AS [Account Number]
,clNo +'-' + fileNo  AS [Weightmans Reference]
,dbFile.Created AS [Date Instructred]
,Defendant.Defendant AS [Customer's Name]
,cdDesc AS [Closure Type]
,fileClosed AS [Date of Closure]
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN ms_prod.dbo.udCRBMWAlphabet
 ON udCRBMWAlphabet.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.dbCodeLookup
 ON cboClosureType=cdCode AND cdType='CLOSURE3'
 LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN [MS_PROD].config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
LEFT OUTER JOIN ms_prod.dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID



WHERE (CASE WHEN clNo IN ('FW30085','FW22135') THEN 'BMW' 
WHEN clNo='341077' THEN 'Land Rover'
WHEN clNo='FW22352' THEN 'Rover'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22275%' THEN 'MG'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22222%' THEN 'R&B'
WHEN clNo='FW22613' THEN 'Mini'
WHEN clNo='W15335' THEN 'Alphera'
WHEN clNo IN ('W20110','FW23557') THEN 'Alphabet' 
END)=@Client
AND fileClosed BETWEEN @StartDate AND @EndDate

END 
GO
