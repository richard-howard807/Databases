SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MSPrecedentSearch]
(
@StartDate AS DATE
,@EndDate AS DATE
,@SearchString AS NVARCHAR(MAX)
)
AS 

BEGIN

SELECT 
       dbFile.fileID,
          dbClient.clNo [Client],
       dbFile.fileNo [Matter],
       dbPrec.PrecDesc,
       dbPrec.PrecPubName,
	   docID,
	   docDesc,
       MS_PROD.config.dbDocument.Created [Date Document Created],
       dbUser.usrFullName [Created by Name],
       FileOwner.usrFullName [Matter Owner]
		  FROM ms_prod.config.dbDocument WITH(NOLOCK)
  INNER JOIN MS_Prod.dbo.dbPrecedents dbPrec WITH(NOLOCK)
        ON dbDocument.docbaseprecid = dbPrec.PrecID
	  LEFT JOIN MS_Prod.config.dbFile dbFile
        ON dbFile.fileID = dbDocument.fileID
    LEFT JOIN MS_Prod.config.dbClient dbClient
        ON dbFile.clID = dbClient.clID
  LEFT JOIN MS_Prod.dbo.dbUser dbUser
        ON dbUser.usrID = dbdocument.Createdby
    LEFT JOIN MS_Prod.dbo.dbUser FileOwner
        ON FileOwner.usrID = dbFile.filePrincipleID
		WHERE dbDocument.Created BETWEEN @StartDate AND @EndDate
		
		AND LOWER(dbPrec.PrecDesc) LIKE '%'+LOWER(@SearchString)+'%'
		ORDER BY dbDocument.Created

		END 
GO
