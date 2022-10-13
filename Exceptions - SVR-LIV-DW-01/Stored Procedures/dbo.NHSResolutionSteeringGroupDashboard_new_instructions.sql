SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[NHSResolutionSteeringGroupDashboard_new_instructions]

@date_period AS NVARCHAR(18)

AS



--DECLARE @current_fin_period AS NVARCHAR(18) = '2022-12 (Apr-2022)'
DECLARE @current_fin_period AS NVARCHAR(18) = @date_period --'2022-12 (Apr-2022)'--
DECLARE	@fin_month_no AS INT = 
(SELECT DISTINCT dim_date.fin_month_no FROM red_dw.dbo.dim_date WHERE dim_date.fin_period = @current_fin_period)
DECLARE @current_fin_year AS INT = (SELECT DISTINCT dim_date.fin_year FROM red_dw.dbo.dim_date WHERE dim_date.fin_period = @current_fin_period)
DECLARE @previous_fin_year AS INT = @current_fin_year - 1

DECLARE @FinYearCheck AS INT = (SELECT fin_year FROM red_dw..dim_date WHERE calendar_date = CAST(GETDATE() AS DATE)  )

--SELECT @current_fin_year
--SELECT @previous_fin_year
--SELECT @fin_month_no

SELECT 
	dim_matter_header_current.master_client_code
	, dim_matter_header_current.master_matter_number
	, dim_fed_hierarchy_history.hierarchylevel4hist
	, current_team.current_team		AS mapped_team	
	, CASE
		WHEN dim_fed_hierarchy_history.employeeid IN ('08F353A2-4600-43D8-A9AC-216EA9525DA8', '97939CD1-5663-4646-AF59-EC4A3DB5FBE0') THEN
			'Birmingham'
		WHEN dim_fed_hierarchy_history.employeeid IN ('440C1838-A18D-4592-B8AB-F196F1094221', 'EE49BBDD-9570-4C98-937F-2A6D9F014061') THEN	
			'Liverpool'
		WHEN dim_employee.locationidud = 'Manchester Spinningfields' THEN
			'Liverpool'
		ELSE
			dim_employee.locationidud
	  END			AS locationidud
	, dim_fed_hierarchy_history.name
	, CAST(dim_matter_header_current.date_opened_case_management AS DATE)		AS date_opened
	, 1 AS instruction_count
	, dim_detail_health.nhs_instruction_type
	, dim_detail_health.nhs_scheme
	, CASE	
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'DH CL', 'ELS', 'Inquest funding', 'Inquest Funding', 'CNSC' ) THEN 
			'Clinical'
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNSGP', 'ELSGP', 'ELSGP (MDDUS)', 'ELSGP (MPS)') THEN
			'GPI'
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'LTPS', 'PES') THEN
			'Non-clinical'
		ELSE
			'Exclude'
	  END					AS scheme_type
	, CASE	
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'DH CL', 'ELS', 'Inquest funding', 'Inquest Funding', 'CNSGP', 'ELSGP', 'ELSGP (MDDUS)', 'ELSGP (MPS)', 'CNSC' ) THEN 
			'Clinical'
		WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'LTPS', 'PES') THEN
			'Non-clinical'
		ELSE
			'Exclude'
	  END			AS scheme_grouped
	, dim_date.fin_year	
	, CASE  WHEN dim_date.fin_year =  @FinYearCheck THEN dim_date.current_fin_year 
	        WHEN dim_date.fin_year <> @FinYearCheck AND dim_date.current_fin_year = 'Historic' THEN 'Previous' 
	        WHEN dim_date.fin_year <> @FinYearCheck AND dim_date.current_fin_year = 'Previous' THEN 'Current' 
	      END current_fin_year 
 
		   
	, dim_date.fin_month_name
	, dim_date.fin_month_no
	, TRIM(STR(RIGHT(@previous_fin_year, 2))) + '/' +  TRIM(STR(RIGHT(@current_fin_year, 2))) AS current_fin_year_formatted
	, TRIM(STR(RIGHT(@previous_fin_year - 1, 2))) + '/' +  TRIM(STR(RIGHT(@previous_fin_year, 2)))	AS previous_fin_year_formatted
	, CASE
		WHEN dim_date.current_fin_year = 'Current' THEN 
			RTRIM(dim_date.fin_month_name) + ' ' + TRIM(STR(RIGHT(@previous_fin_year, 2))) + '/' +  TRIM(STR(RIGHT(@current_fin_year, 2)))
		ELSE
			RTRIM(dim_date.fin_month_name) + ' ' + TRIM(STR(RIGHT(@previous_fin_year - 1, 2))) + '/' +  TRIM(STR(RIGHT(@previous_fin_year, 2)))
	  END						AS month_year_column_headings
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_date
		ON CAST(dim_matter_header_current.date_opened_case_management AS DATE) = dim_date.calendar_date
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key_original_matter_owner_dopm
	INNER JOIN red_dw.dbo.dim_employee
		ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
	LEFT OUTER JOIN (
						SELECT DISTINCT
							ds_sh_valid_hierarchy_x.hierarchylevel3
							, ds_sh_valid_hierarchy_x.hierarchylevel4		AS old_team
							, current_hierarchy.hierarchylevel4			AS current_team
						FROM red_dw.dbo.ds_sh_valid_hierarchy_x
							INNER JOIN (
										SELECT *
										FROM red_dw.dbo.ds_sh_valid_hierarchy_x
										WHERE 1 = 1
											AND ds_sh_valid_hierarchy_x.dss_current_flag = 'Y' 
											--AND ds_sh_valid_hierarchy_x.disabled = 0
											AND ds_sh_valid_hierarchy_x.hierarchylevel3 IN ('Healthcare', 'Regulatory')
											AND ds_sh_valid_hierarchy_x.hierarchylevel4 IS NOT NULL
									) AS current_hierarchy
								ON current_hierarchy.hierarchylevel3 = ds_sh_valid_hierarchy_x.hierarchylevel3
									AND current_hierarchy.hierarchynode = ds_sh_valid_hierarchy_x.hierarchynode
						WHERE
							ds_sh_valid_hierarchy_x.hierarchylevel4 IS NOT NULL
				) AS current_team
		ON current_team.old_team = dim_fed_hierarchy_history.hierarchylevel4hist
WHERE
	dim_matter_header_current.master_client_code = 'N1001'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_date.fin_year IN (@current_fin_year, @previous_fin_year)
	AND dim_date.fin_month_no BETWEEN 1 AND @fin_month_no
	AND dim_fed_hierarchy_history.hierarchylevel3hist = 'Healthcare'
	AND CASE	
			WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNST', 'DH CL', 'ELS', 'Inquest funding', 'Inquest Funding','CNSC') THEN 
				'Clinical'
			WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('CNSGP', 'ELSGP', 'ELSGP (MDDUS)', 'ELSGP (MPS)') THEN
				'GPI'
			WHEN RTRIM(dim_detail_health.nhs_scheme) IN ('DH Liab', 'LTPS', 'PES') THEN
				'Non-clinical'
			ELSE
				'Exclude'
		  END <> 'Exclude'
ORDER BY
	dim_date.fin_month_no
GO
