SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ExRLBPatronHealthMIreport]

AS 

BEGIN

IF OBJECT_ID(N'tempdb..#Debt') IS NOT NULL BEGIN DROP TABLE #Debt END
SELECT Left([lmatter],8) AS ClientNo, dbo_ledger.lmatter, dbo_ledger.ltradat, dbo_ledger.linvoice, dbo_ledger.ldocumnt, dbo_ledger.llcode, dbo_ledcode.lcdebcr, IIf([lcdebcr]='C',[lamount]*-1,[lamount]) AS LedgerValue, dbo_ledger.lbatch, dbo_ledger.lindex, dbo_ledger.lperiod, dbo_ledger.lzero, dbo_ledger.laptoin
INTO #Debt
FROM  [LON-ELITE1].son_db.dbo.ledger AS dbo_ledger  WITH(NOLOCK)
INNER JOIN  [LON-ELITE1].son_db.dbo.ledcode AS dbo_ledcode  WITH(NOLOCK)
ON dbo_ledger.llcode = dbo_ledcode.lccode
WHERE Left([dbo_ledger].[lmatter],8) IN ('00101652','00900100','00900500') 
AND dbo_ledger.linvoice Is Not Null 
AND ((dbo_ledger.lzero)='N' Or (dbo_ledger.lzero)='Y')

IF OBJECT_ID(N'tempdb..#Revenue') IS NOT NULL BEGIN DROP TABLE #Revenue END
SELECT LEFT(tmatter,8) AS clnum
,SUM(tbilldol) AS RevenueYTD
,SUM(tbillhrs) AS BilledHoursYTD
INTO #Revenue
FROM  [LON-ELITE1].son_db.dbo.timecard  WITH(NOLOCK)
WHERE tbilldt>='2022-06-01'
AND (LEFT(tmatter,8)='00101652' OR Left(tmatter,8)='00900100' OR LEFT(tmatter,8)='00900500')
GROUP BY LEFT(tmatter, 8)


IF OBJECT_ID(N'tempdb..#WIP') IS NOT NULL BEGIN DROP TABLE #WIP END
SELECT LEFT(tmatter,8) AS clnum, timecard.tinvoice, Sum(timecard.tbilldol) AS SumOftbilldol
INTO #WIP
FROM [LON-ELITE1].son_db.dbo.timecard WITH(NOLOCK)
WHERE timecard.tstatus NOT IN ('BNC','D','NB','NBP','WA','P','PB','ADE','E')
AND  (LEFT(tmatter,8)='00101652' OR Left(tmatter,8)='00900100' OR LEFT(tmatter,8)='00900500')
GROUP BY LEFT(tmatter,8), timecard.tinvoice
HAVING (((timecard.tinvoice)=0 Or (timecard.tinvoice) Is Null))



SELECT #Revenue.clnum
, ISNULL([clname1],'') + ' ' + ISNULL([clname2],'') AS Client
,RevenueYTD
,BilledHoursYTD
,RevenueYTD / BilledHoursYTD AS [Recovery Rate]
,WIP.SumOftbilldol AS [WIP]
,UnpaidBills AS [Debt]
FROM #Revenue
INNER JOIN [LON-ELITE1].son_db.dbo.client  WITH(NOLOCK)
 ON client.clnum = #Revenue.clnum
LEFT OUTER JOIN #WIP AS WIP
 ON WIP.clnum = #Revenue.clnum
LEFT OUTER JOIN 
(

SELECT ClientNo AS clnum, Sum(LedgerValue) AS UnpaidBills
FROM #Debt
GROUP BY ClientNo


) AS debt
ON debt.clnum = #Revenue.clnum

ORDER BY 1

END 
GO
