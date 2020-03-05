SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[DeedWills]
(
@Branch AS nvarchar(10)
,@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
  
       
  
  IF @Branch='All'
  BEGIN  
   

SELECT 
		FEDCode AS WeightmansRef
		,COALESCE(RTRIM(LEFT(FEDCode, CHARINDEX('-', FEDCode) - 1)),clno) AS [Client] 
        ,SUBSTRING(FEDCode, CHARINDEX('-', FEDCode)  + 1, LEN(FEDCode)) AS [DeedNo]
        ,COALESCE(dbfile.fileDesc,dwDesc) AS [FILENAME]
        ,dwaddress AS [Address] 
        ,NULL AS DeedType
        ,dwArchivedDate AS DateStored 
        ,dwHolder AS HolderOfRecord 
        ,dwRemovedDate AS DateRemoved 
        ,dwReturnDate AS DateReturned
        ,b.brName AS Branch
               ,CASE WHEN dwType IN ('ARCH003','ARCH007','ARCH008') THEN 'Deeds'
        WHEN dwType IN ('ARCH005','ARCH006') THEN 'Wills' END  AS FilterType

FROM MS_PROD.dbo.udDeedWill AS Deeds  WITH(NOLOCK)
INNER JOIN MS_PROD.config.dbClient WITH(NOLOCK)
 ON Deeds.clID=dbClient.clID
 
LEFT OUTER JOIN MS_PROD.config.dbfile as dbfile  WITH(NOLOCK)
 ON Deeds.fileID=dbfile.fileID

LEFT OUTER JOIN MS_PROD.dbo.dbBranch b on dbClient.brID =	b.brId
LEFT OUTER JOIN MS_PROD.dbo.udExtFile ef  WITH(NOLOCK) on ef.fileid = dbfile.fileid

WHERE dwRemovedDate BETWEEN @StartDate AND @EndDate

END 

ELSE 

  BEGIN  
       
    

SELECT 
		FEDCode AS WeightmansRef
		,COALESCE(RTRIM(LEFT(FEDCode, CHARINDEX('-', FEDCode) - 1)),clno) AS [Client] 
        ,SUBSTRING(FEDCode, CHARINDEX('-', FEDCode)  + 1, LEN(FEDCode)) AS [DeedNo]
        ,COALESCE(dbfile.fileDesc,dwDesc) AS [FILENAME]
        ,dwaddress AS [Address] 
        ,NULL AS DeedType
        ,dwArchivedDate AS DateStored 
        ,dwHolder AS HolderOfRecord 
        ,dwRemovedDate AS DateRemoved 
        ,dwReturnDate AS DateReturned
        ,b.brName AS Branch
               ,CASE WHEN dwType IN ('ARCH003','ARCH007','ARCH008') THEN 'Deeds'
        WHEN dwType IN ('ARCH005','ARCH006') THEN 'Wills' END  AS FilterType
    

FROM MS_PROD.dbo.udDeedWill AS Deeds  WITH(NOLOCK)
INNER JOIN MS_PROD.config.dbClient WITH(NOLOCK)
 ON Deeds.clID=dbClient.clID
 
LEFT OUTER JOIN MS_PROD.config.dbfile as dbfile  WITH(NOLOCK)
 ON Deeds.fileID=dbfile.fileID

LEFT OUTER JOIN MS_PROD.dbo.dbBranch b on dbClient.brID =	b.brId
LEFT OUTER JOIN MS_PROD.dbo.udExtFile ef  WITH(NOLOCK) on ef.fileid = dbfile.fileid

WHERE dwRemovedDate BETWEEN @StartDate AND @EndDate
AND b.brName=@Branch
END 
END
GO
