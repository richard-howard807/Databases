SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SpringboardUserMigration]

AS
BEGIN
SELECT DISTINCT  fed_code
,name
,hierarchylevel2hist AS Division
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,worksforname AS [Works For]
,jobtitle As [Job Title]
,brName AS [Office]
,employeestartdate AS employeestartdate
,CASE WHEN MSOnly.usrAlias IS NOT NULL THEN 1 ELSE 0 END  AS Migrated
,ISNULL([No Live Matters],0) AS [No Live Matters]
,ISNULL([No Closed Matters],0) AS [No Closed Matters]
,ISNULL([Number Matters],0) AS [Number Matters]
FROM red_dw.dbo.dim_fed_hierarchy_history
LEFT OUTER JOIN MS_Prod.dbo.dbUser
 ON fed_code=usrAlias collate database_default
LEFT OUTER JOIN MS_Prod.dbo.dbBranch ON dbUser.brID=dbBranch.brID
LEFT OUTER JOIN (SELECT employeeid,contservicedate AS employeestartdate   FROM red_dw.dbo.ds_sh_employee
WHERE dss_current_flag='Y'
AND displayemployeeid IS NOT NULL
AND employeestartdate IS NOT NULL
) AS Employee
 ON dim_fed_hierarchy_history.employeeid=employee.employeeid collate database_default 
LEFT OUTER JOIN (SELECT usrAlias  FROM MS_PROD.dbo.udExtUser
INNER JOIN MS_PROD.dbo.dbUser
 ON udExtUser.usrID=dbUser.usrID
WHERE bitMSOnlyUser=1) AS MSOnly
 ON fed_code=MSOnly.usrAlias collate database_default
LEFT OUTER JOIN (SELECT mg_feearn,SUM(CASE WHEN mg_datcls IS NULL THEN 1 ELSE 0 END)  AS [No Live Matters]
,SUM(CASE WHEN mg_datcls IS NULL THEN 0 ELSE 1 END)  AS [No Closed Matters]
,COUNT(1) AS [Number Matters]
FROM axxia01.dbo.cashdr
INNER JOIN axxia01.dbo.camatgrp
 ON client=mg_client AND matter=mg_matter
WHERE mg_matter <>'ML'
AND mg_client  NOT IN ('00030645','00453737','95000C','P00016')
AND (mg_datcls IS NULL OR mg_datcls>='2017-05-01')
GROUP BY mg_feearn) AS MatterCount
 ON fed_code=MatterCount.mg_feearn collate database_default
WHERE dss_current_flag='Y'
AND leaver=0
AND activeud=1
AND fed_code <>'Unknown'
AND fed_code <>'5847'

ORDER BY hierarchylevel2hist 
,hierarchylevel3hist
,hierarchylevel4hist 


END





--SELECT mg_feearn,COUNT(DISTINCT cashdr.case_id) AS [Number Matters]
--,COUNT(1) AS [Number Docs]
-- FROM red_dw.dbo.dim_fed_hierarchy_history AS A
--INNER JOIN axxia01.dbo.camatgrp
-- ON fed_code=mg_feearn collate database_default
--INNER JOIN axxia01.dbo.cashdr
-- ON mg_client=client AND mg_matter=matter
--        INNER JOIN axxia01.dbo.casact AS casact ON cashdr.case_id = casact.case_id
--        INNER JOIN axxia01.dbo.documt AS Docs ON cashdr.case_id = Docs.case_id
--                                                 AND casact.document_no = Docs.document_no
--                                                 AND casact.activity_seq = Docs.activity_seq
 
--        --LEFT OUTER JOIN ARTIION.axxia01.dbo.docversn  AS docversion WITH(NOLOCK) 
--        --ON Docs.document_no=docversion.document_no
--WHERE dss_current_flag='Y'
--AND leaver=0
--AND activeud=1
--AND fed_code <>'Unknown'
--AND mg_matter <>'ML'
--AND mg_client  NOT IN ('00030645','00453737','95000C','P00016')
--AND (mg_datcls IS NULL OR mg_datcls>='2017-05-01')
--AND casact.document_no > 0

--GROUP BY mg_feearn
GO
