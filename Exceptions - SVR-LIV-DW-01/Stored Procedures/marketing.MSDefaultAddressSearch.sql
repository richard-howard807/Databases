SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [marketing].[MSDefaultAddressSearch] -- EXEC marketing.MSDefaultAddressSearch  4792104
(
@ContactID AS BIGINT
)

AS 

BEGIN

DECLARE @AddID AS BIGINT
SET @AddID=(SELECT contDefaultAddress FROM ms_prod.config.dbContact WHERE contID=@ContactID)

SELECT AllData.clNo,
       AllData.fileNo,
       AllData.fileDesc,
       AllData.fileStatus,
       AllData.contID,
       AllData.contName,
       AllData.assocType,
       AllData.addLine1,
       AllData.addLine2,
       AllData.addLine3,
       AllData.addLine4,
       AllData.addLine5,
       AllData.addPostcode,
       AllData.AddressLevel,
	   AllData.ID,
	   contTypeCode,
	   CASE WHEN contTypeCode='INDIVIDUAL' THEN EmailAdd.EmailAddresses ELSE NULL END AS Email
	   FROM 
(
SELECT clno,fileNo,fileDesc,fileStatus,allData.contID,allData.contName
,allData.assocType
,addLine1,addLine2,addLine3,addLine4,addLine5,addPostcode,'Matter Level' AS AddressLevel
,@AddID AS [ID]
,contTypeCode
FROM(
SELECT fileID,assocType,dbAssociates.contid,assocdefaultaddID,contName,addLine1,addLine2,addLine3,addLine4,addLine5,addPostcode,contTypeCode FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
INNER JOIN ms_prod.dbo.dbAddress
 ON assocdefaultaddID=addID
WHERE assocdefaultaddID=@AddID
UNION
SELECT fileID,assocType,dbAssociates.contid,assocdefaultaddID,contName,addLine1,addLine2,addLine3,addLine4,addLine5,addPostcode,contTypeCode FROM ms_prod.config.dbAssociates
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbAssociates.contID
INNER JOIN ms_prod.dbo.dbAddress
 ON contDefaultAddress=addID
WHERE contDefaultAddress=@AddID
) AS allData
INNER JOIN ms_prod.config.dbFile
 ON dbFile.fileID = allData.fileID
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
 UNION

 SELECT NULL AS clno,NULL AS fileNo,NULL AS fileDesc,NULL AS fileStatus,dbContact.contID,dbContact.contName
,NULL AS assocType
,addLine1,addLine2,addLine3,addLine4,addLine5,addPostcode,'Default Contact Address' AS AddressLevel
,@AddID AS [ID]
,contTypeCode
FROM ms_prod.config.dbContact
 INNER JOIN ms_prod.dbo.dbAddress
  ON addID=contDefaultAddress
WHERE contDefaultAddress=@AddID
UNION
SELECT NULL AS clno,NULL AS fileNo,NULL AS fileDesc,NULL AS fileStatus,dbContact.contID,dbContact.contName
,NULL AS assocType
,addLine1,addLine2,addLine3,addLine4,addLine5,addPostcode,'Contact Linked Address' AS AddressLevel
,@AddID
,contTypeCode
FROM ms_prod.dbo.dbContactAddresses
INNER JOIN ms_prod.config.dbContact
 ON dbContact.contID = dbContactAddresses.contID
INNER JOIN ms_prod.dbo.dbAddress
 ON addID=contaddID
 WHERE contaddID=@AddID

) AS AllData
LEFT OUTER JOIN 
(
SELECT contID,STRING_AGG(CAST(contEmail AS NVARCHAR(MAX)),',') AS [EmailAddresses]
FROM ms_prod.dbo.dbContactEmails
GROUP BY contID
) AS EmailAdd
 ON EmailAdd.contID = AllData.contID


 END
GO
