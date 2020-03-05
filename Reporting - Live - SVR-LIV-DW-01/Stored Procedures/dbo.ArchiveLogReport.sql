SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ArchiveLogReport] -- EXEC dbo.ArchiveLogReport 'All','2017-02-01','2017-02-05'
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
        ,dwRef ah_arcref
        ,COALESCE(RTRIM(LEFT(FEDCode, CHARINDEX('-', FEDCode) - 1)),clno) AS cl_accode
        ,SUBSTRING(FEDCode, CHARINDEX('-', FEDCode)  + 1, LEN(FEDCode)) mt_matter
        ,COALESCE(dbfile.fileDesc,dwDesc) mg_descrn
        ,dwHolder AS  ah_holder
        ,dwArcLLoc AS ah_arcloc
        ,dwDestroyDate AS  ah_actdat
        ,dwArchivedDate ah_archdt
		,dbfile.Created mg_datopn
		,fileclosed AS  mg_datcls
        ,dwRemovedDate AS ah_remdat
        ,dwReturnDate AS ah_retdat
        ,dwDestroyDate AS  ah_destdt
		,fee.usrInits AS [FeeEarner]
		,part.usrInits AS [Partner]
		,dbfile.FileType AS WorkType
		,cboDepartment Department
        ,b.brName AS Branch
        ,cdDesc AS [Status]

FROM MS_PROD.dbo.udDeedWill AS Deeds  WITH(NOLOCK)

INNER JOIN MS_PROD.config.dbClient WITH(NOLOCK)
 ON Deeds.clID=dbClient.clID
LEFT OUTER JOIN MS_PROD.config.dbfile AS dbfile  WITH(NOLOCK)
 ON Deeds.fileID=dbfile.fileID
LEFT OUTER JOIN MS_PROD.dbo.dbBranch b  WITH(NOLOCK) on b.brid = dbfile.brid
LEFT OUTER JOIN MS_PROD.dbo.dbUser fee  WITH(NOLOCK) on fee.usrID = dbfile.filePrincipleID
LEFT OUTER JOIN MS_PROD.dbo.dbFileType ft  WITH(NOLOCK) on ft.typeCode = dbfile.fileType
LEFT OUTER JOIN MS_PROD.dbo.udExtFile ef  WITH(NOLOCK) on ef.fileid = dbfile.fileid
LEFT OUTER JOIN MS_PROD.dbo.dbUser part  WITH(NOLOCK) on part.usrID = ef.[cboPartner]
LEFT OUTER JOIN (SELECT * FROM MS_PROD.dbo.dbCodeLookup WHERE cdType='ARCHSTATUS') AS ArcStatus
 ON [Status]=cdCode

WHERE dwRemovedDate BETWEEN @StartDate AND @EndDate

END 

ELSE 

  BEGIN  
       
       SELECT 
        FEDCode AS WeightmansRef
        ,dwRef ah_arcref
        ,COALESCE(RTRIM(LEFT(FEDCode, CHARINDEX('-', FEDCode) - 1)),clno) AS cl_accode
        ,SUBSTRING(FEDCode, CHARINDEX('-', FEDCode)  + 1, LEN(FEDCode)) mt_matter
        ,COALESCE(dbfile.fileDesc,dwDesc) mg_descrn
        ,dwHolder AS  ah_holder
        ,dwArcLLoc AS ah_arcloc
        ,dwDestroyDate AS  ah_actdat
        ,dwArchivedDate ah_archdt
		,dbfile.Created mg_datopn
		,fileclosed AS  mg_datcls
        ,dwRemovedDate AS ah_remdat
        ,dwReturnDate AS ah_retdat
        ,dwDestroyDate AS  ah_destdt
		,fee.usrInits AS [FeeEarner]
		,part.usrInits AS [Partner]
		,dbfile.FileType AS WorkType
		,cboDepartment Department
        ,b.brName AS Branch
        ,cdDesc AS [Status]

FROM MS_PROD.dbo.udDeedWill AS Deeds  WITH(NOLOCK)

INNER JOIN MS_PROD.config.dbClient WITH(NOLOCK)
 ON Deeds.clID=dbClient.clID
LEFT OUTER JOIN MS_PROD.config.dbfile AS dbfile  WITH(NOLOCK)
 ON Deeds.fileID=dbfile.fileID
LEFT OUTER JOIN MS_PROD.dbo.dbBranch b  WITH(NOLOCK) on b.brid = dbfile.brid
LEFT OUTER JOIN MS_PROD.dbo.dbUser fee  WITH(NOLOCK) on fee.usrID = dbfile.filePrincipleID
LEFT OUTER JOIN MS_PROD.dbo.dbFileType ft  WITH(NOLOCK) on ft.typeCode = dbfile.fileType
LEFT OUTER JOIN MS_PROD.dbo.udExtFile ef  WITH(NOLOCK) on ef.fileid = dbfile.fileid
LEFT OUTER JOIN MS_PROD.dbo.dbUser part  WITH(NOLOCK) on part.usrID = ef.[cboPartner]
LEFT OUTER JOIN (SELECT * FROM MS_PROD.dbo.dbCodeLookup WHERE cdType='ARCHSTATUS') AS ArcStatus
 ON [Status]=cdCode
 
WHERE dwRemovedDate BETWEEN @StartDate AND @EndDate
AND b.brName=@Branch
END 

  
END
GO
