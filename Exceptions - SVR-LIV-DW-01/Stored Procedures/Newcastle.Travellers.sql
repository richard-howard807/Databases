SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [Newcastle].[Travellers] 

AS 
BEGIN
SELECT Fees.bill_fin_year,
       Fees.FinancialYear,
       Fees.bill_fin_month_no,
       Fees.Fees AS [Fees per Month],
	   ISNULL(NoMatters,0) AS [Files Opened]
	   FROM
(
SELECT bill_fin_year,bill_fin_period AS FinancialYear
,bill_fin_month_no,SUM(OrgFee) AS Fees FROM TE_3E_Prod.dbo.InvMaster
INNER JOIN TE_3E_Prod.dbo.Matter
 ON LeadMatter=MattIndex
INNER JOIN MS_Prod.config.dbFile
 ON fileExtLinkID=mattindex
LEFT OUTER JOIN MS_Prod.dbo.udextfile
 ON dbfile.fileid=udextfile.fileid
LEFT OUTER JOIN red_dw.dbo.dim_bill_date
 ON InvDate=bill_date
WHERE Matter.number LIKE 'T1001%'
AND bill_fin_year>='2017'
AND (CRSystemSourceID IS NOT NULL OR brid=23)
GROUP BY  bill_fin_year,bill_fin_period,bill_fin_month_no

) AS Fees
LEFT OUTER JOIN (SELECT bill_fin_period,COUNT(1) AS NoMatters
FROM MS_Prod.config.dbFile
INNER JOIN MS_Prod.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN MS_Prod.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN red_dw.dbo.dim_bill_date
 ON dbfile.Created=bill_date
WHERE clNo='T1001'
AND (CRSystemSourceID IS NOT NULL OR dbfile.brid=23)
GROUP BY bill_fin_period) AS NumberNewMatters
 ON Fees.FinancialYear=NumberNewMatters.bill_fin_period
ORDER BY bill_fin_year,bill_fin_month_no


END

GO
