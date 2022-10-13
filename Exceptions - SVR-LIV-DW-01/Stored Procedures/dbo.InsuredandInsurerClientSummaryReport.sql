SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		M Taylor
-- Create date: 2022-07-19
-- Description:	initial create 
-- =============================================
CREATE PROCEDURE [dbo].[InsuredandInsurerClientSummaryReport] 

(
 @insured_sector AS NVARCHAR(MAX) 
,@segment AS NVARCHAR(MAX) 
,@sector AS NVARCHAR(MAX) 
,@insurerclient1 AS NVARCHAR(MAX) 
,@insuredclient AS NVARCHAR(MAX)
,@client_name AS NVARCHAR(MAX)
)

AS
DROP TABLE if EXISTS #Revenue
DROP TABLE IF EXISTS #groups_count

DECLARE @CurrentFinYear  AS INT = (SELECT DISTINCT fin_year FROM red_dw.dbo.dim_date WHERE current_fin_year = 'Current')
DECLARE @CurrentFinYear_minus1 AS INT  = @CurrentFinYear -1
DECLARE @CurrentFinYear_minus2 AS INT = @CurrentFinYear -2
DECLARE @CurrentFinYear_minus3 AS INT = @CurrentFinYear -3
DECLARE @CurrentFinYear_minus4 AS INT = @CurrentFinYear -4
DECLARE @CurrentFinYear_minus5 AS INT = @CurrentFinYear -5
DECLARE @CurrentFinYear_minus6 AS INT = @CurrentFinYear -6
 




SELECT 
			  dim_matter_header_curr_key
			, dim_bill_date.bill_fin_year
			, SUM(fact_bill_activity.bill_amount) Revenue
		INTO #Revenue
		FROM red_dw.dbo.fact_bill_activity
			INNER JOIN red_dw.dbo.dim_bill_date 
				ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
		WHERE 
			dim_bill_date.bill_fin_year BETWEEN @CurrentFinYear_minus5 AND @CurrentFinYear
		GROUP BY 
			dim_matter_header_curr_key
			, dim_bill_date.bill_fin_year

CREATE INDEX INX_Revenue ON #Revenue (dim_matter_header_curr_key)

	SELECT 
      dim_matter_header_current.dim_matter_header_curr_key
    , 1						AS [TotalMatterCount]
	, CASE WHEN dim_date.fin_year = @CurrentFinYear_minus5 THEN 1 ELSE 0 END AS [matters_CurrentFY_minus5]
	, CASE WHEN dim_date.fin_year = @CurrentFinYear_minus4 THEN 1 ELSE 0 END AS [matters_CurrentFY_minus4]
	, CASE WHEN dim_date.fin_year = @CurrentFinYear_minus3 THEN 1 ELSE 0 END AS [matters_CurrentFY_minus3]
	, CASE WHEN dim_date.fin_year = @CurrentFinYear_minus2 THEN 1 ELSE 0 END AS [matters_CurrentFY_minus2]
	, CASE WHEN dim_date.fin_year = @CurrentFinYear_minus1 THEN 1 ELSE 0 END AS [matters_CurrentFY_minus1]
	, CASE WHEN dim_date.fin_year = @CurrentFinYear        THEN 1 ELSE 0 END AS [Matters_CurrentFY]

INTO #groups_count
FROM red_dw.dbo.fact_dimension_main 
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_date
		ON dim_date.calendar_date = dim_matter_header_current.date_opened_practice_management
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE
	dim_date.fin_year >= @CurrentFinYear_minus5 AND 
	(dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims' OR dim_matter_worktype.work_type_name LIKE '%Prof Risk%')
	AND reporting_exclusions = 0

CREATE INDEX INX_CountGroups ON #groups_count (dim_matter_header_curr_key)

-- Testing
--DECLARE @insured_sector AS NVARCHAR(4000) =  'AMBULANCE' 
--,@segment AS NVARCHAR(4000) = 'Blank'
--,@sector AS NVARCHAR(4000) = 'Blank'
--,@insurerclient1 AS NVARCHAR(4000) = NULL
--,@insuredclient AS NVARCHAR(4000) = NULL
--,@client_name AS NVARCHAR(4000) = NULL
--DECLARE @CurrentFinYear  AS INT = (SELECT DISTINCT fin_year FROM red_dw.dbo.dim_date WHERE current_fin_year = 'Current')
--DECLARE @CurrentFinYear_minus1 AS INT  = @CurrentFinYear -1
--DECLARE @CurrentFinYear_minus2 AS INT = @CurrentFinYear -2
--DECLARE @CurrentFinYear_minus3 AS INT = @CurrentFinYear -3
--DECLARE @CurrentFinYear_minus4 AS INT = @CurrentFinYear -4
--DECLARE @CurrentFinYear_minus5 AS INT = @CurrentFinYear -5
--DECLARE @CurrentFinYear_minus6 AS INT = @CurrentFinYear -6


SELECT 
	dim_client_involvement.insurerclient_name
	, ISNULL(dim_client_involvement.insuredclient_name, dim_detail_claim.dst_insured_client_name)	AS insuredclient_name
	, dim_client.sector
	, dim_detail_core_details.insured_sector
	, dim_client.client_name
	, dim_client.client_group_name
	, dim_client.segment
	, dim_matter_worktype.work_type_name
	, dim_department.department_name
	, dim_matter_header_current.matter_partner_full_name

	/*Matters Count*/
	, SUM(COALESCE(#groups_count.TotalMatterCount,0))         AS TotalMattersCounttodate
	, SUM(COALESCE(#groups_count.matters_CurrentFY_minus5,0)) AS matters_CurrentFY_minus5
	, SUM(COALESCE(#groups_count.matters_CurrentFY_minus4,0)) AS matters_CurrentFY_minus4
	, SUM(COALESCE(#groups_count.matters_CurrentFY_minus3,0)) AS  matters_CurrentFY_minus3
	, SUM(COALESCE(#groups_count.matters_CurrentFY_minus2,0)) AS  matters_CurrentFY_minus2
	, SUM(COALESCE(#groups_count.matters_CurrentFY_minus1,0)) AS  matters_CurrentFY_minus1
    , SUM(COALESCE(#groups_count.matters_CurrentFY,0))        AS  matters_CurrentFY

	/*Revnue Amount*/

	, SUM(Revenue) AS  Revenue_Total
	, SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear_minus5 THEN Revenue END) AS Revenue_CurrentFY_minus5
	, SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear_minus4 THEN Revenue END) AS Revenue_CurrentFY_minus4
	, SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear_minus3 THEN Revenue END) AS Revenue_CurrentFY_minus3
	, SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear_minus2 THEN Revenue END) AS Revenue_CurrentFY_minus2
	, SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear_minus1 THEN Revenue END) AS Revenue_CurrentFY_minus1
	, SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear        THEN Revenue END) AS Revenue_CurrentFY

	, Label_toDate = '1 May ' + CAST(@CurrentFinYear_minus6 AS varchar(4)) + ' to date'
	, Label_minus5 = '1 May ' + CAST(@CurrentFinYear_minus6 AS varchar(4)) + ' - ' + '30th April ' + CAST(@CurrentFinYear_minus5 AS varchar(4)) 
	, Label_minus4 = '1 May ' + CAST(@CurrentFinYear_minus5 AS varchar(4)) + ' - ' + '30th April ' + CAST(@CurrentFinYear_minus4 AS varchar(4)) 
	, Label_minus3 = '1 May ' + CAST(@CurrentFinYear_minus4 AS varchar(4)) + ' - ' + '30th April ' + CAST(@CurrentFinYear_minus3 AS varchar(4)) 
	, Label_minus2 = '1 May ' + CAST(@CurrentFinYear_minus3 AS varchar(4)) + ' - ' + '30th April ' + CAST(@CurrentFinYear_minus2 AS varchar(4)) 
	, Label_minus1 = '1 May ' + CAST(@CurrentFinYear_minus2 AS varchar(4)) + ' - ' + '30th April ' + CAST(@CurrentFinYear_minus1 AS varchar(4)) 
	, Label_current = '1 May ' + CAST(@CurrentFinYear_minus1 AS varchar(4)) + ' - ' + '30th April ' + CAST(@CurrentFinYear AS varchar(4)) 

FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_client
		ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.dim_department
		ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
	LEFT JOIN #Revenue
	ON #Revenue.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT JOIN #groups_count
	ON #groups_count.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	

WHERE 
      
UPPER(ISNULL(insured_sector,'Blank')) IN (@insured_sector) 
AND UPPER(ISNULL(segment,'Blank')) IN (@segment) 
AND UPPER(ISNULL(sector,'Blank')) IN (@sector)
AND (CASE WHEN @insurerclient1 IS NULL THEN ISNULL(insurerclient_name,'Blank') ELSE  @insurerclient1 END)=ISNULL(insurerclient_name,'Blank')
AND  (CASE WHEN @insuredclient IS NULL THEN ISNULL(insuredclient_name,'Blank')  ELSE  @insuredclient END)=ISNULL(insuredclient_name,'Blank') 
AND (CASE WHEN @client_name IS NULL THEN dim_matter_header_current.client_name  ELSE  @client_name END)=dim_matter_header_current.client_name

AND ISNULL(segment, '') <> ''  	
AND	(dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims' OR dim_matter_worktype.work_type_name LIKE '%Prof Risk%')
AND dim_matter_header_current.reporting_exclusions = 0
AND dim_matter_header_current.master_client_code <> '30645'

	GROUP BY 

	  dim_client_involvement.insurerclient_name
	, ISNULL(dim_client_involvement.insuredclient_name, dim_detail_claim.dst_insured_client_name)
	, dim_client.sector
	, dim_detail_core_details.insured_sector
	, dim_client.client_name
	, dim_client.client_group_name
	, dim_client.segment
	, dim_matter_worktype.work_type_name
	, dim_department.department_name
	, dim_matter_header_current.matter_partner_full_name

	HAVING


	  SUM(#groups_count.TotalMatterCount)         <> 0 OR
	  SUM(#groups_count.matters_CurrentFY_minus5) <> 0 OR
	  SUM(#groups_count.matters_CurrentFY_minus4) <> 0 OR
	  SUM(#groups_count.matters_CurrentFY_minus3) <> 0 OR
	  SUM(#groups_count.matters_CurrentFY_minus2) <> 0 OR
	  SUM(#groups_count.matters_CurrentFY_minus1) <> 0 OR
      SUM(#groups_count.matters_CurrentFY)        <> 0 OR

	/*Revnue Amount*/

	  SUM(Revenue)  <> 0 OR
	  SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear_minus5 THEN Revenue END) <> 0 OR
	  SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear_minus4 THEN Revenue END) <> 0 OR
	  SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear_minus3 THEN Revenue END) <> 0 OR
	  SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear_minus2 THEN Revenue END) <> 0 OR
	  SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear_minus1 THEN Revenue END) <> 0 OR
	  SUM(CASE WHEN #Revenue.bill_fin_year = @CurrentFinYear        THEN Revenue END) <> 0 
	 
GO
