SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RLBWIPByTeam]
AS
BEGIN

IF OBJECT_ID(N'tempdb..#RLBWIPData') IS NOT NULL
BEGIN
DROP TABLE #RLBWIPData
END

SELECT 
MSupaty AS [FE]
,timekeep.tkfirst +' ' +timekeep.tklast AS [Fe Name]
,CASE WHEN DATEDIFF(DAY,tworkdt,GETDATE())<0 THEN '<0 Days' 
WHEN DATEDIFF(DAY,tworkdt,GETDATE()) BETWEEN 0 AND 30 THEN '0 - 30 Days'
WHEN DATEDIFF(DAY,tworkdt,GETDATE()) BETWEEN 31 AND 90 THEN '31 - 90 days'
WHEN DATEDIFF(DAY,tworkdt,GETDATE()) >90 THEN 'Greater than 90 Days'
 END AS Banding 
, timecard.tinvoice, SUM(timecard.tbilldol) AS WIP
INTO #RLBWIPData
FROM [lon-elite1].son_db.dbo.timecard WITH(NOLOCK)
INNER JOIN [lon-elite1].son_db.dbo.matter WITH(NOLOCK)
 ON tmatter=mmatter
LEFT OUTER JOIN [lon-elite1].son_db.dbo.timekeep  WITH(NOLOCK)
 ON MSupaty=timekeep.tkinit
WHERE timecard.tstatus NOT IN ('BNC','D','NB','NBP','WA','P','PB','ADE','E')
--AND tmatter='00124192.00001'
GROUP BY timekeep.tkfirst + ' ' + timekeep.tklast,
         CASE
         WHEN DATEDIFF(DAY, tworkdt, GETDATE()) < 0 THEN
         '<0 Days'
         WHEN DATEDIFF(DAY, tworkdt, GETDATE())
         BETWEEN 0 AND 30 THEN
         '0 - 30 Days'
         WHEN DATEDIFF(DAY, tworkdt, GETDATE())
         BETWEEN 31 AND 90 THEN
         '31 - 90 days'
         WHEN DATEDIFF(DAY, tworkdt, GETDATE()) > 90 THEN
         'Greater than 90 Days'
         END,
         msupaty,
         tinvoice
HAVING (((timecard.tinvoice)=0 OR (timecard.tinvoice) IS NULL))
--SELECT 
--ttk AS [FE]
--,tkfirst +' ' +tklast AS [Fe Name]
--,CASE WHEN DATEDIFF(DAY,tworkdt,GETDATE())<0 THEN '<0 Days' 
--WHEN DATEDIFF(DAY,tworkdt,GETDATE()) BETWEEN 0 AND 30 THEN '0 - 30 Days'
--WHEN DATEDIFF(DAY,tworkdt,GETDATE()) BETWEEN 31 AND 90 THEN '31 - 90 days'
--WHEN DATEDIFF(DAY,tworkdt,GETDATE()) >90 THEN 'Greater than 90 Days'
-- END AS Banding 
--, timecard.tinvoice, SUM(timecard.tbilldol) AS WIP
--INTO #RLBWIPData
--FROM [lon-elite1].son_db.dbo.timecard WITH(NOLOCK)
--LEFT OUTER JOIN [lon-elite1].son_db.dbo.timekeep  WITH(NOLOCK)
-- ON ttk=tkinit
--WHERE timecard.tstatus NOT IN ('BNC','D','NB','NBP','WA','P','PB','ADE','E')

--GROUP BY CASE
--         WHEN DATEDIFF(DAY, tworkdt, GETDATE()) < 0 THEN
--         '<0 Days'
--         WHEN DATEDIFF(DAY, tworkdt, GETDATE())
--         BETWEEN 0 AND 30 THEN
--         '0 - 30 Days'
--         WHEN DATEDIFF(DAY, tworkdt, GETDATE())
--         BETWEEN 31 AND 90 THEN
--         '31 - 90 days'
--         WHEN DATEDIFF(DAY, tworkdt, GETDATE()) > 90 THEN
--         'Greater than 90 Days'
--         END,
--         ttk,
--		 tkfirst +' ' +tklast,
--         tinvoice
--HAVING (((timecard.tinvoice)=0 OR (timecard.tinvoice) IS NULL))


SELECT #RLBWIPData.FE
,#RLBWIPData.[Fe Name]
,fed_code	
,ISNULL(display_name,#RLBWIPData.[Fe Name]) AS display_name
,employeeid
,ISNULL(hierarchylevel2hist,'Unknown') AS [Business Line]
,ISNULL(hierarchylevel3hist,'Unknown') AS [Practice Area]
,ISNULL(hierarchylevel4hist,'Unknown') AS [Team]
,Banding AS [Days Banding]
,#RLBWIPData.WIP AS [Wip Value]
 FROM #RLBWIPData
 LEFT OUTER JOIN RLBStaff141022 
  ON #RLBWIPData.FE=RLBStaff141022.FE
 LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
  ON fed_code=FEDCode COLLATE DATABASE_DEFAULT AND dss_current_flag='Y' 
GROUP BY ISNULL(hierarchylevel2hist, 'Unknown'),
         ISNULL(hierarchylevel3hist, 'Unknown'),
         ISNULL(hierarchylevel4hist, 'Unknown'),
         #RLBWIPData.FE,
         #RLBWIPData.[Fe Name],
         fed_code,
         display_name,
         employeeid,
         Banding,
         WIP
END
GO
