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
,bill_fin_month_no,SUM(OrgFee) AS Fees FROM [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.InvMaster
INNER JOIN [SVR-LIV-SQLU-01].TE_3E_EnvisionConv.dbo.Matter
 ON LeadMatter=MattIndex
LEFT OUTER JOIN red_dw.dbo.dim_bill_date
 ON InvDate=bill_date
WHERE Matter.number LIKE 'WB164659%'
AND bill_fin_year>='2017'
GROUP BY  bill_fin_year,bill_fin_period,bill_fin_month_no

) AS Fees
LEFT OUTER JOIN (SELECT bill_fin_period,COUNT(1) AS NoMatters
FROM [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbFile
INNER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [SVR-LIV-MSP-01].MS_EnvisonConv.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
LEFT OUTER JOIN red_dw.dbo.dim_bill_date
 ON dbfile.Created=bill_date
WHERE clNo='WB164659'
GROUP BY bill_fin_period) AS NumberNewMatters
 ON Fees.FinancialYear=NumberNewMatters.bill_fin_period
ORDER BY bill_fin_year,bill_fin_month_no


END

GO
