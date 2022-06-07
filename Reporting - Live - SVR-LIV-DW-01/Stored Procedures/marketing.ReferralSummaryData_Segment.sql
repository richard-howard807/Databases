SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- ===============================================
-- Author:		Max Taylo
-- Create date: 20211027
-- Description:	119870 New Referaal summary data 
-- ================================================

-- ================================================
CREATE PROCEDURE [marketing].[ReferralSummaryData_Segment]
(
@BusinessSource VARCHAR(4000)
,@Segment AS NVARCHAR(4000) 
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--Testing
--DECLARE @BusinessSource AS NVARCHAR(50) = 'Web'
--,@Segment AS NVARCHAR(50) = 'All'

SELECT DISTINCT 
 @BusinessSource [Referral Type Description]
 ,dim_client.segment AS Segment
, dim_bill_date.bill_fin_year AS [Fin Year]
, dim_bill_date.bill_fin_month_no AS [Fin Month No]
, dim_bill_date.bill_cal_year AS [Year]
, dim_bill_date.bill_cal_month_no AS [Month No]
, dim_bill_date.bill_cal_month_name AS [Month Name]
, CONCAT(dim_bill_date.bill_cal_month_name,'-',dim_bill_date.bill_cal_year) AS [Period]
, SUM(bill_amount) AS [Value]
, 'Bill Date' AS [Date Range]
, dim_bill_date.bill_fin_period AS table_order
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
ON dim_bill_date.bill_date = fact_bill_activity.bill_date
AND dim_bill_date.bill_fin_year>=(SELECT bill_fin_year FROM red_dw.dbo.dim_bill_date
									WHERE CONVERT(DATE,bill_date,103)=CONVERT(DATE,DATEADD(YEAR,-1,GETDATE()),103))
LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.master_fact_key=fact_bill_activity.master_fact_key
LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key


WHERE  dim_matter_header_current.reporting_exclusions = 0
AND LOWER(dim_client.client_name) NOT LIKE '%test%'

AND dim_client.client_code COLLATE DATABASE_DEFAULT IN 
(
SELECT DISTINCT dbClient.clNo FROM  MS_Prod.config.dbClient dbClient 
JOIN MS_Prod.dbo.udExtClient udExtClient  ON udExtClient.clID = dbClient.clID
JOIN MS_Prod.dbo.udReferral udReferral ON udExtClient.cboReferralType = udReferral.code
where
ISNULL(udExtClient.cboReferralType,'Unknown') IN (SELECT value  FROM   STRING_SPLIT(@BusinessSource,',') )
)

AND dim_client.segment	= CASE WHEN @Segment ='All' THEN dim_client.segment ELSE @Segment END

GROUP BY  
         CONCAT(dim_bill_date.bill_cal_month_name, '-', dim_bill_date.bill_cal_year),
         dim_bill_date.bill_fin_year,
         dim_bill_date.bill_fin_month_no,
         dim_bill_date.bill_cal_year,
         dim_bill_date.bill_cal_month_no,
         dim_bill_date.bill_cal_month_name
		  ,dim_client.segment
		  , dim_bill_date.bill_fin_period

UNION

SELECT DISTINCT
	 @BusinessSource [Referral Type Description]
	  ,dim_client.segment AS Segment
	, dim_date.fin_year AS [Fin Year]
	, dim_date.fin_month_no AS [Fin Month No]
	, dim_date.cal_year AS [Year]
	, dim_date.cal_month_no AS [Month No]
	, dim_date.cal_month_name AS [Month Name]
	, CONCAT(dim_date.cal_month_name,'-',dim_date.cal_year) AS [Period]
	, COUNT(dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number) AS [Value] 
	, 'Date Opened' AS [Date Range]
	, dim_date.fin_period AS table_order

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date
ON dim_date.calendar_date=CAST(dim_matter_header_current.date_opened_case_management AS DATE)
AND dim_date.cal_year>=(SELECT cal_year FROM red_dw.dbo.dim_date
						WHERE CONVERT(DATE,dim_date.calendar_date,103)=CONVERT(DATE,DATEADD(YEAR,-1,GETDATE()),103))
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key



WHERE 
dim_matter_header_current.reporting_exclusions = 0
AND LOWER(dim_client.client_name) NOT LIKE '%test%'
AND dim_client.client_code COLLATE DATABASE_DEFAULT IN 
(
SELECT DISTINCT dbClient.clNo FROM  MS_Prod.config.dbClient dbClient 
JOIN MS_Prod.dbo.udExtClient udExtClient  ON udExtClient.clID = dbClient.clID
JOIN MS_Prod.dbo.udReferral udReferral ON udExtClient.cboReferralType = udReferral.code
where
ISNULL(udExtClient.cboReferralType,'Unknown') IN (SELECT value  FROM   STRING_SPLIT(@BusinessSource,',') )
)

AND dim_client.segment	= CASE WHEN @Segment ='All' THEN dim_client.segment ELSE @Segment END

GROUP BY 
         
         CONCAT(dim_date.cal_month_name, '-', dim_date.cal_year),
         dim_date.fin_year,
         dim_date.fin_month_no,
         dim_date.cal_year,
         dim_date.cal_month_no,
         dim_date.cal_month_name
		  ,dim_client.segment
		  , dim_date.fin_period
END
GO
