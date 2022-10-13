SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MarketingContactsAndLists]

AS
BEGIN 
IF OBJECT_ID('tempdb..#UnPivot') IS NOT NULL
    DROP TABLE #UnPivot
    
SELECT RTRIM(kd_client) AS [Entity]
,RTRIM([Entity Name]) AS [Entity Name]
,RTRIM([Organisation Entity]) AS [Organisation Entity]
,RTRIM([Organisation Name]) AS [Organisation Name]
,RTRIM(ke_descrn)  AS [Detail Description]
,ISNULL(RTRIM(kf_dtdesc),RTRIM(kd_dettxt)) + ' (Date:' + ISNULL(convert(nvarchar(MAX), kd_detdat, 104),'') + ')'  AS [Category Description]
INTO #UnPivot
FROM     ARTIION.axxia01.dbo.kdmarkdt   AS a  WITH (NOLOCK)
INNER JOIN (SELECT   DISTINCT kd_client AS [Entity]  
,cl_clname As [Entity Name]
,cl_datopn AS [DateClientOpened]
,[Organisation Entity]
,[Organisation Name]
FROM     ARTIION.axxia01.dbo.kdmarkdt AS kdmarkdt_1 WITH (NOLOCK)
 LEFT OUTER JOIN ARTIION.axxia01.dbo.kddetcat AS categories  WITH (NOLOCK)
	ON kdmarkdt_1.kd_detcod = categories.kf_detcod
AND kdmarkdt_1.kd_detcat = categories.kf_catcod
LEFT OUTER JOIN axxia01.dbo.caclient WITH (NOLOCK) 
 ON kd_client=cl_accode
INNER JOIN (SELECT kc_client,kc_orgidn AS [Organisation Entity],cl_clname AS [Organisation Name] FROM axxia01.dbo.kdclicon WITH (NOLOCK)
LEFT  JOIN axxia01.dbo.caclient WITH (NOLOCK) 
ON kdclicon.kc_orgidn=cl_accode) AS Organisation
 ON kd_client=Organisation.kc_client
WHERE kd_detcod='MARK'
AND UPPER(kd_dettxt)  NOT LIKE '%ARCH%'
) AS Entities
 ON a.kd_client=Entities.Entity
LEFT OUTER JOIN ARTIION.axxia01.dbo.kddetlup AS c WITH (NOLOCK)
 ON a.kd_detcod=c.ke_defcod
LEFT OUTER JOIN ARTIION.axxia01.dbo.kddetcat  AS b WITH (NOLOCK)
ON a.kd_detcod=b.kf_detcod AND a.kd_detcat=b.kf_catcod
WHERE kd_detcod IN 
(
'114'      ,'areaint'   ,'BS'        ,'client'    ,'COM'       ,'date'      ,'Email'     
,'email'     ,'GM'        ,'jobt'      ,'mail2'     ,'mail3'     ,'mail4'     ,'MARK '
,'NL'        ,'off'       ,'REG'       ,'SEG'       ,'sourenq'   ,'SUB'       ,'UNSB'      

)
--AND RTRIM(kd_client)
-- IN
--(
--'00427880'
--,'00712284'
--,'00712289'
--,'00712290'
--,'00712299'
--,'00712307'
--,'00712315'
--,'00712339'
--,'00712349'
--,'00712488'
--,'00712490'
--)

AND(ISNULL(RTRIM(kf_dtdesc),RTRIM(kd_dettxt)) + ' (Date:' + ISNULL(convert(nvarchar(MAX), kd_detdat, 104),'') + ')') IS NOT NULL

select   [Entity]
,[Entity Name]
,[Organisation Entity]
,[Organisation Name]
,[Detail Description]
,CAST(STUFF((   SELECT '| ' + RTRIM([Category Description])
				FROM #UnPivot te
				WHERE T.[Entity] = te.[Entity] 
				AND T.[Detail Description]=te.[Detail Description]
				FOR XML PATH ('')  ),1,1,'')  AS VARCHAR(MAX))as [Category Description]
    from #UnPivot  t
  
    group by [Entity],[Entity Name]
,[Organisation Entity]
,[Organisation Name]
,[Detail Description]
ORDER BY [Organisation Name] 

END 
GO
