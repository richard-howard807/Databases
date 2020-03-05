SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--use Reporting
/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2018-04-23
Description:		Springboard report for LTA - see ticket 299992
Current Version:	Initial Create
====================================================
====================================================

*/
 CREATE PROCEDURE [dbo].[CompletedMIFields]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF OBJECT_ID('tempdb..#tabs') IS NOT NULL DROP TABLE #tabs
IF OBJECT_ID('tempdb..#TabDescription') IS NOT NULL DROP TABLE #TabDescription

 SELECT DISTINCT UPPER(detail_code) AS detail_code ,tab_desc INTO #tabs
FROM axxia01.dbo.casluptab AS detail
LEFT OUTER JOIN axxia01.dbo.cmdettab AS tabs
  ON detail.tab_code=tabs.tab_code
ORDER BY detail_code


SELECT detail_code
,CAST(STUFF((   SELECT ',' + RTRIM(tab_desc)
                        FROM #tabs te
                        WHERE T.detail_code = te.detail_code 
                        
                        FOR XML PATH ('')  ),1,1,'')  AS VARCHAR(MAX))as [Tab Description]
    INTO #TabDescription
    from #tabs  t
    GROUP BY detail_code
    
    


    
    
  SELECT hierarchylevel3hist,hierarchylevel4hist
,RTRIM(casdet.case_detail_code) AS [FED Case Detail Code]
,ISNULL([Tab Description],'Misc')  AS [Tab Description]
,CASE WHEN txtDetCode IS NULL THEN 'No' ELSE 'Yes' END AS [Mapped in MS]
,case_detail_desc,COUNT(1) AS NoTimesUsed
FROM axxia01.dbo.cashdr
INNER JOIN axxia01.dbo.camatgrp 
 ON client=mg_client ANd matter=mg_matter
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
  ON mg_feearn=fed_code collate database_default 
  AND dss_current_flag='Y' AND activeud=1
INNER JOIN axxia01.dbo.casdet ON cashdr.case_id=casdet.case_id
INNER JOIN axxia01.dbo.caslup
ON casdet.case_detail_code=caslup.case_detail_code 
LEFT OUTER JOIN (SELECT DISTINCT txtDetCode FROM dbo.udMapDetail090418) AS udMapDetail -- this table will need to point to a LIVE version of udMapDetail
ON RTRIM(casdet.case_detail_code)=RTRIM(txtDetCode) collate database_default
LEFT OUTER JOIN #TabDescription AS Tabs
ON casdet.case_detail_code=Tabs.detail_code collate database_default
WHERE mg_matter <>'ML'
AND mg_client  NOT IN ('00030645','00453737','95000C','P00016')
AND (mg_datcls IS NULL OR mg_datcls>='2017-07-01')
AND hierarchylevel3hist IN ('EPI','Glasgow','Corp-Comm','Litigation','Real Estate','Regulatory','Regulatory Services Unit')
AND hierarchylevel2hist='Legal Ops - LTA'
AND (case_date IS NOT NULL OR case_text IS NOT NULL OR case_value IS NOT NULL)

GROUP BY casdet.case_detail_code,txtDetCode
,[Tab Description]
,case_detail_desc,hierarchylevel3hist,hierarchylevel4hist
ORDER BY hierarchylevel3hist,hierarchylevel4hist,casdet.case_detail_code,case_detail_desc

end
GO
