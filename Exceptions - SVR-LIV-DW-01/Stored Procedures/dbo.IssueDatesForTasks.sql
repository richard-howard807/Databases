SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[IssueDatesForTasks]
(
@FeeEarner AS NVARCHAR(20)
)

AS 

BEGIN


SELECT clNo
,fileNo
,fileDesc
,tskDesc AS TaskDescription
,tskDue AS tskDue
,dbTasks.Created AS [CreatedDate]
,name AS [Matter Owner]
,fed_code AS FEDCode

FROM MS_Prod.dbo.dbTasks
INNER JOIN MS_Prod.config.dbFile
 ON dbFile.fileID = dbTasks.fileID
INNER JOIN MS_Prod.config.dbClient
  ON dbClient.clID = dbFile.clID
INNER JOIN red_dw.dbo.dim_matter_header_current 
 ON dbFile.fileID=ms_fileid
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
 AND dss_current_flag='Y'



WHERE tskType LIKE '%KEYDATE%'
AND CONVERT(DATE,dbTasks.Created,103)>='2020-06-29'
AND CONVERT(DATE,dbTasks.Created,103)<='2020-07-09'
AND tskDesc LIKE '% - today%'
AND fed_code=@FeeEarner

END 
GO
