SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[DennisHarveyClaireWilliams]
AS
BEGIN
SELECT 
'Clients' AS [Search Type]
,dbclient.clNo  AS [MS Client No]
,FedClientNumber AS [FED Ref]
,CASE WHEN cltypeCode='1' THEN 'Individual' WHEN cltypeCode='2' THEN 'Organisation' ELSE cltypeCode END AS [Type]
,contName
,addLine1
,addLine2
,addLine3
,addLine4
,addLine5
,addPostcode
,dbContactIndividual.contTitle,contChristianNames,contSurname
,dbContact.Created AS [Date Contact/Matter Created]
,dbClient.Created AS [Date Client Created]
,usrAlias AS [Partner]
FROM MS_Prod.config.dbClient
LEFT OUTER JOIN MS_Prod.config.dbContact ON dbClient.clDefaultContact =dbContact.contID
LEFT OUTER JOIN MS_Prod.dbo.dbContactIndividual ON dbClient.clDefaultContact=dbContactIndividual.contID
LEFT OUTER JOIN MS_Prod.dbo.dbAddress ON contDefaultAddress=dbAddress.addID
LEFT OUTER JOIN MS_Prod.dbo.udClientContactBridgingTable ON dbContact.contID=udClientContactBridgingTable.ContID
LEFT OUTER JOIN (SELECT clID,usrAlias FROM MS_Prod.dbo.udExtClient
INNER JOIN MS_Prod.dbo.dbUser ON cboPartner=usrID) AS ClientPartner
 ON dbClient.clID=ClientPartner.clID
WHERE UPPER(clName)  LIKE '%CLAIRE WILLIAMS%' OR UPPER(contName)  LIKE '%CLAIRE WILLIAMS%'
OR UPPER(clName)  LIKE '%DENNIS HARVEY%' OR UPPER(contName)  LIKE '%DENNIS HARVEY%'
UNION
SELECT 
'Associates' AS [Search Type]
,dbclient.clNo + '.' + dbFile.fileNo AS [MS Ref]
,FEDCode AS [FED Ref]
,assocType AS [Associate Type]
,contName
,addLine1
,addLine2
,addLine3
,addLine4
,addLine5
,addPostcode
,dbContactIndividual.contTitle,contChristianNames,contSurname
,dbContact.Created AS [Date Contact/Matter Created]
,dbClient.Created AS [Date Client Created]
,usrAlias AS [Partner]
FROM MS_Prod.config.dbAssociates
INNER JOIN MS_Prod.config.dbFile
 ON dbAssociates.fileID=dbFile.fileID
INNER JOIN MS_Prod.config.dbClient
 ON dbFile.clID=dbClient.clID
INNER JOIN MS_Prod.config.dbContact
 ON dbAssociates.contID=dbContact.contID
LEFT OUTER JOIN MS_Prod.dbo.dbAddress ON contDefaultAddress=dbAddress.addID
LEFT OUTER JOIN MS_Prod.dbo.dbContactIndividual ON dbAssociates.contID=dbContactIndividual.contID
LEFT OUTER JOIN MS_Prod.config.dbClient as clcon ON  dbAssociates.contID=clcon.clDefaultContact
LEFT OUTER JOIN MS_Prod.dbo.udExtFile ON dbFile.fileID=udExtFile.fileID
LEFT OUTER JOIN (SELECT clID,usrAlias FROM MS_Prod.dbo.udExtClient
INNER JOIN MS_Prod.dbo.dbUser ON cboPartner=usrID) AS ClientPartner
 ON dbClient.clID=ClientPartner.clID
WHERE 
UPPER(contChristianNames) + ' ' + UPPER(contSurname) LIKE '%CLAIRE WILLIAMS%'
OR UPPER(contName) LIKE '%CLAIRE WILLIAMS%'
OR UPPER(dbClient.clName)  LIKE '%CLAIRE WILLIAMS%' 
OR UPPER(clcon.clName)  LIKE '%CLAIRE WILLIAMS%'
OR (UPPER(contChristianNames) LIKE '%CLAIRE%' AND  UPPER(contSurname) LIKE '%WILLIAMS%')
OR UPPER(contChristianNames) + ' ' + UPPER(contSurname) LIKE '%DENNIS HARVEY%'
OR UPPER(contName) LIKE '%DENNIS HARVEY%'
OR UPPER(dbClient.clName)  LIKE '%DENNIS HARVEY%' 
OR UPPER(clcon.clName)  LIKE '%DENNIS HARVEY%'
OR (UPPER(contChristianNames) LIKE '%DENNIS%' AND  UPPER(contSurname) LIKE '%HARVEY%')
END
GO
