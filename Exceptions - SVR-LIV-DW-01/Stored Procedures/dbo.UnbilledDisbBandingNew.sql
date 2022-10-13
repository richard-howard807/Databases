SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
/*    
===================================================    
===================================================    
Author:    Max Taylor    
Created Date:  2020-01-27    
Description:  Unbilled Disbursements proc    
Current Version: Update to old version     
====================================================    
====================================================    
*/    
      
CREATE PROCEDURE [dbo].[UnbilledDisbBandingNew]       
(      
 @finMonth AS varchar(10)      
)      
AS      
BEGIN      
    
--DECLARE @finMonth AS nvarchar(20) = 'Feb-20'-- Test     
IF  @finMonth <> CAST(LEFT(DATENAME(mm,GETDATE()), 3) AS VARCHAR(10))  + '-' +  CAST(right(YEAR(GETDATE()), 2) AS VARCHAR(10))    
SELECT     
 [Business Line]      
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
  
AND b.transaction_fin_month_name + '-' +  right(B.transaction_cal_year, 2)  = @finMonth      
  
AND @finMonth <> CAST(LEFT(DATENAME(mm,GETDATE()), 3) AS VARCHAR(10))  + '-' +  CAST(right(YEAR(GETDATE()), 2) AS VARCHAR(10)) -- used to exclude current Month Year from Snapshot    
  
) AS AllData      
GROUP BY [Business Line]      
, [Practice Area]      
,[Team]      
, [Display Name]      
,[Days_Banding]      
      
HAVING SUM(DisbAmount)<>0      
    
/* Used to pull in Current MonthYear as logic for Current is incorrect when looking at snapshot table*/    
    
ELSE
    
SELECT     
    
 [Business Line]      
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
,c.client_name     
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
    
,CASE WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 0 AND 30 THEN '0 - 30 Days'      
 WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 31 AND 90     THEN '31 - 90 days'      
 WHEN DATEDIFF(DAY,a.workdate,GETDATE()) > 90                  THEN '90 + Days'     
 END  AS [Days_Banding]      
      
,CASE WHEN DATEDIFF(DAY,a.workdate, GETDATE()) BETWEEN 0 AND 30 THEN -1      
 WHEN DATEDIFF(DAY,a.workdate,GETDATE()) BETWEEN 31 AND 90 THEN 2      
 WHEN DATEDIFF(DAY,a.workdate,GETDATE()) > 90 THEN 30     
 END AS [Dim Days Banding Key]      
    
,dim_matter_header_current.matter_description    
,dim_fed_hierarchy_history.fed_code    
    
FROM       red_dw.dbo.fact_disbursements_detail AS a      
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK) ON a.client_code=dim_matter_header_current.client_code  AND a.matter_number=dim_matter_header_current.matter_number       
INNER JOIN red_dw.dbo.dim_client c ON c.client_code = dim_matter_header_current.client_code    
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK)  ON dim_matter_header_current.fee_earner_code= fed_code collate database_default AND dss_current_flag='Y'      
       
WHERE  1 = 1     
AND    dim_bill_key=0      
AND    total_unbilled_disbursements <> 0      
    
--AND reporting_exclusions=0 -- Requested by steve Scullion to remove      
    
AND @finMonth =   CAST(LEFT(DATENAME(mm,GETDATE()), 3) AS VARCHAR(10))  + '-' +  CAST(right(YEAR(GETDATE()), 2) AS VARCHAR(10))  
    
    
) AS AllData      
GROUP BY     
    
 [Business Line]      
,[Practice Area]      
,[Team]      
,[Display Name]      
,[Days_Banding]    
      
HAVING SUM(DisbAmount)<>0      
    
    
 END   
  
-- SELECT DISTINCT   
-- cal_month_name + '-' + right(cal_year, 2) as 'DAXPeriod'  
-- ,transaction_fin_month,transaction_fin_period   
-- FROM red_dw.dbo.dim_transaction_date  
--JOIN red_dw.dbo.dim_date ON dim_transaction_date.transaction_fin_month = dim_date.fin_month  
--WHERE transaction_fin_month >201001  
--ORDER BY transaction_fin_month  
  
  
--select distinct  
--cal_month_name + '-' + right(cal_year, 2) as 'DAXPeriod',  
--fin_period as 'MDXPeriod'  
--,fin_month  
  
--from   
--red_dw.dbo.dim_date  
  
--where  
--calendar_date between '2007-04-01' and (select top 1 calendar_date from red_dw.dbo.dim_date where current_fin_year = 'Current' order by calendar_date desc)  
  
--order by   
--fin_period
GO
