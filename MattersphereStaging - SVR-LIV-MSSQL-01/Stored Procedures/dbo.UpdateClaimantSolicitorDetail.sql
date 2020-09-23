SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Kevin Hansen
-- Create date: 12.06.19
-- Description:	API to update the claimant solicitor detail based the associate.
-- =============================================
CREATE PROCEDURE [dbo].[UpdateClaimantSolicitorDetail]
AS
BEGIN

UPDATE a
SET a.txtClaimSolFm=b.NewtxtClaimSolFm
--SELECT a.txtClaimSolFm,b.NewtxtClaimSolFm 
FROM MS_PROD.dbo.udMIDataTeam AS a
INNER JOIN 
(
SELECT dbAssociates.fileID
,[Tidied Version] AS NewtxtClaimSolFm
FROM MS_PROD.config.dbAssociates
INNER JOIN MS_PROD.config.dbFile
 ON dbFile.fileID = dbAssociates.fileID
INNER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
INNER JOIN ClaimantSolicitorLookup250419 AS SolicitorLookup
 ON RTRIM(contName)=RTRIM([Claimant's Solicitor Associate])
INNER JOIN MS_PROD.dbo.udMIDataTeam
 ON udMIDataTeam.fileID = dbAssociates.fileID
LEFT OUTER JOIN (SELECT fileID,COUNT(1) AS NoSols
  FROM MS_PROD.config.dbAssociates WHERE assocType='CLAIMANTSOLS'
  GROUP BY fileID) AS NoSols
   ON NoSols.fileID = dbFile.fileID
 WHERE assocType='CLAIMANTSOLS'
 AND assocActive=1
 AND NoSols=1
 AND RTRIM(ISNULL([Tidied Version],''))<>RTRIM(ISNULL(txtClaimSolFm,''))
 AND fileStatus='LIVE'
 ) AS b
  ON b.fileID = a.fileID


END
GO
