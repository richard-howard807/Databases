SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
	Created By:  Kevin Hansen
	Created Date:  01/09/2016


*/



 
CREATE PROCEDURE [archive].[ClosedStatusNoArchiveDate] --EXEC [archive].[ClosedStatusNoArchiveDate] '00046018','Liverpool','2012-01-01','2016-09-01'
(
@Client AS VARCHAR(MAX)
,@Branch AS VARCHAR(MAX)
,@StartDate AS DATE
,@EndDate AS DATE
)
AS

		

BEGIN

SELECT ListValue  INTO #Branch FROM Reporting.dbo.udt_TallySplit(',', @Branch)



SELECT    MSRef
         , ArchiveRef
         ,FEDClient
         ,FEDMatter
         ,MatterDescription
         ,Holder
         ,ArchiveLocation
         ,ActionDate
         ,ArchiveDate
         ,DateOpened
         ,DateClosed
         ,DateRemoved
         ,DateReturned
         ,DestructionDate
         ,[FeeEarner]
         ,[Partner]
         ,WorkType
         ,Department
         ,Branch
         ,ArchiveStatus
         ,fileStatus
FROM 
(
SELECT 
         clNo + '.' + fileNo AS MSRef
         ,dwRef ArchiveRef
         ,RTRIM(LEFT(FEDCode, CHARINDEX('-', FEDCode) - 1)) AS FEDClient
         ,SUBSTRING(FEDCode, CHARINDEX('-', FEDCode)  + 1, LEN(FEDCode)) FEDMatter
         ,dbfile.fileDesc MatterDescription
         ,dwHolder AS  Holder
         ,dwArcLLoc AS ArchiveLocation
         ,dwDestroyDate AS  ActionDate
         ,dwArchivedDate ArchiveDate
         ,dbfile.Created DateOpened
         ,fileclosed AS  DateClosed
         ,dwRemovedDate AS DateRemoved
         ,dwReturnDate AS DateReturned
         ,dwDestroyDate AS  DestructionDate
         ,fee.usrInits AS [FeeEarner]
         ,part.usrInits AS [Partner]
         ,dbfile.FileType AS WorkType
         ,cboDepartment Department
         ,b.brName AS Branch
         ,MS_PROD.dbo.GetCodeLookupDesc('ARCHSTATUS',[Status],'{default}') AS ArchiveStatus
         ,fileStatus

 FROM  MS_PROD.config.dbfile AS dbfile  WITH(NOLOCK)
 INNER JOIN MS_PROD.config.dbClient WITH(NOLOCK) ON dbfile.clID=dbClient.clID
 inner join MS_PROD.dbo.dbBranch b  WITH(NOLOCK) on b.brid = dbfile.brid
 inner join MS_PROD.dbo.dbUser fee  WITH(NOLOCK) on fee.usrID = dbfile.filePrincipleID
 inner join MS_PROD.dbo.dbFileType ft  WITH(NOLOCK) on ft.typeCode = dbfile.fileType
 inner join MS_PROD.dbo.udExtFile ef  WITH(NOLOCK) on ef.fileid = dbfile.fileid
 inner join MS_PROD.dbo.dbUser part  WITH(NOLOCK) on part.usrID = ef.[cboPartner]
 left outer join MS_PROD.dbo.udDeedWill AS Deeds  WITH(NOLOCK) ON dbfile.clID=Deeds.clID AND dbfile.fileID=Deeds.fileID

 WHERE fileStatus <> 'LIVE'
 AND fileNo <>'0'
 ) AS AllMatters
 INNER JOIN #Branch AS Branch ON Branch.ListValue COLLATE database_default = AllMatters.Branch COLLATE database_default

 WHERE FEDClient=@Client
 AND (CONVERT(DATE,DateClosed,103) IS NULL OR CONVERT(DATE,DateClosed,103) BETWEEN @StartDate AND @EndDate)
 AND FEDMatter <>'ML'
END
GO
