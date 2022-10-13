SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---- =============================================
---- Author:		Jamie Bonner
---- Create date:	2021-12-08
---- Description:	Billing arrangement data to replicate 3E Rates screen in MS
---- =============================================

CREATE PROCEDURE [dbo].[matter_billing_arrangement] (
	@client_number AS NVARCHAR(8)
	, @matter_number AS NVARCHAR(8)
)
AS 

-- Testing
--DECLARE @client_number AS NVARCHAR(8) = '00000659'--'Z1001'
--		, @matter_number AS NVARCHAR(8) = '00000317' --'78536' 

IF OBJECT_ID('tempdb..#rates_table') IS NOT NULL DROP TABLE #rates_table

SELECT 
	all_data.master_client_code
	, all_data.master_matter_number
	, all_data.name
	, all_data.rate_name
	, all_data.Arrangement
	, all_data.arrangement_name
	, all_data.title
	, all_data.merged_titles
	, all_data.office
	, all_data.locationidud
	, CASE
		WHEN MIN(all_data.rate_class) = 0 THEN
			'<' + CAST(MAX(all_data.rate_class) AS NVARCHAR(2)) + ' Years PQE'
		ELSE
			CAST(MIN(all_data.rate_class) AS NVARCHAR(2)) + ' - ' + CAST(MAX(all_data.rate_class) AS NVARCHAR(2)) + ' Years PQE'
	  END			AS [Rate Group]
	, all_data.Rate
INTO #rates_table
FROM (
		SELECT DISTINCT 
			dim_matter_header_current.master_client_code
			, dim_matter_header_current.master_matter_number
			, dim_fed_hierarchy_history.name
			, RateTypeDate.Description			AS rate_name
			, RateDateDet.Arrangement
			, Arrangement.Description		AS arrangement_name
			, CASE 
				WHEN Title.Description IS NULL THEN 
					'No Grade Specified'
				ELSE 
				Title.Description
			  END				AS title
			, CASE 
				WHEN Title.Description IS NULL THEN 
					'No Grade Specified'
				WHEN Title.Description IN ('Equity Partner', 'Fixed Share Partner', 'Silver Equity Partner') THEN
					'All Partners'
				WHEN Title.Description IN ('External Trainee', 'Trainee') THEN
					'All Trainees'
				ELSE 
					Title.Description
			  END				AS merged_titles
			, CASE
				WHEN Office.Description LIKE '%London%' THEN 
					'London'
				WHEN ISNULL(Office.Description, '') NOT LIKE '%London%' THEN 
					'Regional'
			  END			AS office
			, dim_employee.locationidud
			, RateDateDet.Rate
			, RateDateDet.TimeType			AS time_type_code
			, CAST(RateDateDet.RateClass AS INT)				AS rate_class
		from [TE_3E_Prod].[dbo].[RateDateDet]
			INNER JOIN [TE_3E_Prod].[dbo].[RateTypeDate] 
				ON RateTypeDate.RateTypeDateID = RateDateDet.RateTypeDate 
					AND NxStartDate <= getdate() 
						AND NxEndDate >= getdate()
			INNER JOIN [TE_3E_Prod].[dbo].[Arrangement]
				ON Arrangement.Code = RateDateDet.Arrangement
			LEFT OUTER JOIN [TE_3E_PROD].[dbo].[Title]  
				ON Title.Code = RateDateDet.Title
			LEFT OUTER JOIN [TE_3E_PROD].[dbo].[Office] 
				ON Office.Code = RateDateDet.Office
			INNER JOIN red_dw.dbo.dim_matter_header_current
				ON dim_matter_header_current.billing_arrangement = RateDateDet.Arrangement COLLATE DATABASE_DEFAULT
			INNER JOIN red_dw.dbo.fact_dimension_main
				ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
			INNER JOIN red_dw.dbo.dim_employee
				ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
		WHERE 1 = 1 
			AND RateDateDet.TimeType IS NULL
			AND CASE
					WHEN Office.Description LIKE '%London%' THEN 
						'London'
					WHEN ISNULL(Office.Description, '') NOT LIKE '%London%' THEN 
						'Regional'
				END	= IIF(dim_employee.locationidud LIKE '%London%', 'London', 'Regional')
			AND dim_matter_header_current.client_code = @client_number
			AND dim_matter_header_current.matter_number = @matter_number
) AS all_data
GROUP BY
	all_data.master_client_code
	, all_data.master_matter_number
	, all_data.name
	, all_data.rate_name
	, all_data.Arrangement
	, all_data.arrangement_name
	, all_data.title
	, all_data.merged_titles
	, all_data.office
	, all_data.locationidud
	, all_data.Rate
ORDER BY
	all_data.merged_titles


SELECT DISTINCT
	#rates_table.master_client_code
	, #rates_table.master_matter_number
	, #rates_table.name
	, #rates_table.rate_name
	, #rates_table.Arrangement
	, #rates_table.arrangement_name
	, CASE 
		WHEN #rates_table.merged_titles = 'All Partners' AND merge_check.count_of_merge = 3 THEN
			#rates_table.merged_titles
		WHEN #rates_table.merged_titles = 'All Trainees' AND merge_check.count_of_merge = 2 THEN
			#rates_table.merged_titles
		ELSE
			#rates_table.title
	  END					AS title
	, #rates_table.office
	, #rates_table.[Rate Group]
	, #rates_table.Rate
FROM #rates_table
	LEFT OUTER JOIN (
				SELECT
					#rates_table.merged_titles
					, #rates_table.Rate
					, COUNT(#rates_table.merged_titles)  AS count_of_merge
				FROM #rates_table
				WHERE
					#rates_table.[Rate Group] IS NULL
				GROUP BY
					#rates_table.merged_titles
					, #rates_table.Rate
				) AS merge_check
		ON merge_check.merged_titles = #rates_table.merged_titles
			AND #rates_table.Rate = merge_check.Rate


GO
