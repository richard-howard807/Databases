SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: 18.10.16
-- Description:	Validates involvements in regards to all data
-- =============================================
CREATE  PROCEDURE [dbo].[RunInvolValidation]

AS
BEGIN

DECLARE @DatabaseName AS nvarchar(100)
SET @DatabaseName=(SELECT Value FROM dbo.controlTable WHERE [Description]='envDb')


DECLARE @SQL AS NVARCHAR(MAX)
SET @SQL='
UPDATE a
SET a.assocOrder=a.assocOrder+LastOrder
FROM [MattersphereStaging].[dbo].[InvolvementStage] AS a
LEFT OUTER JOIN (SELECT fileID,MAX(assocOrder) AS LastOrder 
				 FROM '+@DatabaseName+'.config.dbAssociates
				 GROUP BY fileID
				) AS LastOrderID
			 ON a.FileID=LastOrderID.fileID'
			
---- dbAssoicate can already have assoicates attached the Associate Order is a NOT NULL column so we need to make sure it follows sequence
EXEC (@SQL)


DECLARE @SQL1 AS NVARCHAR(MAX)
SET @SQL1='
UPDATE a
SET StatusID=6
,error=11
,errormsg=ISNULL(a.assocType,'''') + '' Doesnt Exist,''
FROM InvolvementStage a
LEFT OUTER JOIN (SELECT cdCode,cdDesc FROM '+@DatabaseName+'.dbo.dbCodeLookup
WHERE cdType=''SUBASSOC'') AS AssociatesLookup
 ON a.assocType=AssociatesLookup.cdCode
WHERE cdCode IS NULL '


EXEC (@SQL1)


UPDATE [MattersphereStaging].[dbo].[InvolvementStage] 
SET StatusID=7
WHERE StatusID= 0


END 
GO
