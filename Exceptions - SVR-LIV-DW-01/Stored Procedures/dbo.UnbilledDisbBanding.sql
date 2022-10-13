SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[UnbilledDisbBanding] --EXEC [dbo].[UnbilledDisbBanding] '2018-12-10'
(
 @finMonth AS varchar(10)
)
AS
BEGIN

SELECT [Business Line]
,[Practice Area]
,[Team]
,[Display Name]
,[Days_Banding]
,SUM(DisbAmount) AS [Wip Value]
,SUM(HardCost) AS HardCost
,SUM(SoftCost) AS SoftCost
FROM 
(
SELECT a.client_code AS  Client
,a.matter_number AS  Matter
,total_unbilled_disbursements AS ChargeRate
,total_unbilled_disbursements AS DisbAmount
,total_unbilled_disbursements_vat AS [Tax Value]
,hierarchylevel2hist AS [Business Line]
,hierarchylevel3hist As [Practice Area]
,hierarchylevel4hist AS [Team]
,display_name As [Display Name]
,display_name AS AccountsUser
,unbilled_hard_disbursements AS HardCost
,unbilled_soft_disbursements AS SoftCost
,a.workdate AS DisbDate
,CASE WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) BETWEEN 0 AND 30 THEN '0-30 Days'
WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) BETWEEN 31 AND 90 THEN '31-90 Days'
WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) > 90 THEN '90 + Days' END  AS [Days_Banding]

,CASE WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) BETWEEN 0 AND 30 THEN -1
WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) BETWEEN 31 AND 90 THEN 2
WHEN DATEDIFF(DAY,a.workdate,EOMONTH(transaction_calendar_date)) > 90 THEN 30 END AS [Dim Days Banding Key]
,b.*
FROM red_dw.dbo.fact_disbursements_detail_monthly AS a
INNER JOIN red_dw.dbo.dim_transaction_date As b
 ON a.dim_transaction_date_key=b.dim_transaction_date_key

INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON a.client_code=dim_matter_header_current.client_code
 AND a.matter_number=dim_matter_header_current.matter_number 
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK) 
 ON dim_matter_header_current.fee_earner_code=fed_code collate database_default AND dss_current_flag='Y'
 
 WHERE dim_bill_key=0
AND total_unbilled_disbursements <> 0
--AND reporting_exclusions=0 -- Requested by steve Scullion to remove
AND b.transaction_fin_month=@finMonth
) AS AllData
GROUP BY [Business Line]
, [Practice Area]
,[Team]
, [Display Name]
,[Days_Banding]

HAVING SUM(DisbAmount)<>0


--SELECT [Business Line]
--,[Practice Area]
--,[Team]
--,[Display Name]
--,[Days_Banding]
--,SUM(DisbAmount) AS [Wip Value]
----,SUM(HardCost) AS HardCost
----,SUM(SoftCost) AS SoftCost
--FROM 
--(

--SELECT Matters.Client
--,Matters.Matter
--,WorkRate AS ChargeRate
--,REPLACE(UnbilledWIP.Narrative,'Supplier: ','') AS DisbNotes
--,COALESCE(VchrDetail.Amount,WorkAmt) AS DisbAmount
--,CASE WHEN UnbilledWIP.TransactionType='HCOST' THEN  COALESCE(VchrDetail.Amount,WorkAmt) ELSE NULL END AS HardCost
--,CASE WHEN UnbilledWIP.TransactionType='SCOST' THEN  COALESCE(VchrDetail.Amount,WorkAmt) ELSE NULL END AS SoftCost
--,ISNULL(VchrTax.CalcAmt,0) AS [Tax Value]
--,hierarchylevel2hist AS [Business Line]
--,hierarchylevel3hist As [Practice Area]
--,hierarchylevel4hist AS [Team]
--,display_name As [Display Name]
--,Timekeeper.DisplayName AS AccountsUser

--,WorkDate AS DisbDate
--,CASE WHEN DATEDIFF(DAY,WorkDate,@Date) BETWEEN 0 AND 30 THEN '0-30 Days'
--WHEN DATEDIFF(DAY,WorkDate,@Date) BETWEEN 31 AND 90 THEN '31-90 Days'
--WHEN DATEDIFF(DAY,WorkDate,@Date) > 90 THEN '90 + Days' END  AS [Days_Banding]

--,CASE WHEN DATEDIFF(DAY,WorkDate,@Date) BETWEEN 0 AND 30 THEN -1
--WHEN DATEDIFF(DAY,WorkDate,@Date) BETWEEN 31 AND 90 THEN 2
--WHEN DATEDIFF(DAY,WorkDate,@Date) > 90 THEN 30 END AS [Dim Days Banding Key]
--FROM 
--(
--SELECT  ISNULL(RTRIM(LEFT(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber) - 1)) ,RTRIM(LEFT(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber) - 1)) ) AS Client
--,ISNULL(SUBSTRING(Matter.LoadNumber, CHARINDEX('-', Matter.LoadNumber)  + 1, LEN(Matter.LoadNumber)),SUBSTRING(Matter.AltNumber, CHARINDEX('-', Matter.AltNumber)  + 1, LEN(Matter.AltNumber)))
--AS Matter
--,Matter.MattIndex
--,LoadNumber AS LoadNumber
--,AltNumber AS AltNumber
--FROM TE_3E_Prod.dbo.Matter  WITH(NOLOCK)
--) AS Matters
--INNER JOIN TE_3E_Prod.dbo.CostCard AS UnbilledWIP   WITH(NOLOCK) 
-- ON Matters.MattIndex=UnbilledWIP.Matter
--LEFT JOIN TE_3E_Prod.dbo.Timekeeper  WITH(NOLOCK) 
-- ON UnbilledWIP.Timekeeper=TkprIndex
--LEFT OUTER JOIN TE_3E_Prod.dbo.VchrDetail AS VchrDetail WITH(NOLOCK) 
-- ON UnbilledWIP.CostIndex=VchrDetail.CostCard
--LEFT OUTER JOIN (SELECT VchrTax.Voucher,SUM(VchrTax.CalcAmt) AS CalcAmt 
--			    FROM  TE_3E_Prod.dbo.VchrTax AS VchrTax WITH(NOLOCK) 
--			    WHERE  VchrTax.CalcAmt>0 AND VchrTax.IsActive=1
--			    GROUP BY VchrTax.Voucher
			    
--			    ) AS VchrTax
-- ON VchrDetail.Voucher=VchrTax.Voucher 
--INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK) 
-- ON Matters.Client=client_code  collate database_default
-- AND Matters.Matter=matter_number collate database_default 
--INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK) 
-- ON dim_matter_header_current.fee_earner_code=fed_code collate database_default AND dss_current_flag='Y'
--WHERE  WIPRemoveDate IS NULL
--AND CONVERT(DATE,WorkDate) <=@Date
--AND UnbilledWIP.IsActive=1
--AND (Matters.LoadNumber  LIKE '%-%' OR Matters.AltNumber LIKE '%-%' )
--AND reporting_exclusions=0
--) AS AllData
--GROUP BY [Business Line]
--, [Practice Area]
--,[Team]
--, [Display Name]
--,[Days_Banding]

--HAVING SUM(DisbAmount)<>0


END

GO
