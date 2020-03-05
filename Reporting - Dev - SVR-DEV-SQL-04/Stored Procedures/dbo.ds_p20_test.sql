SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[ds_p20_test]
	--@fee_arrangement NVARCHAR(255)
	--,@proceedings_issued NVARCHAR(255) 
	--,@suspicion_of_fraud NVARCHAR(255)
	--,@department NVARCHAR(255)
	--,@bin NVARCHAR(255)
	--,@work_type_group NVARCHAR(255)
	--,@team NVARCHAR(255)
	--,@target_matter_owner NVARCHAR(255)
AS
BEGIN
	DECLARE @years_time_window INT;
	SET @years_time_window = 4; 

	
	SELECT
			RTRIM(red_dw.dbo.fact_dimension_main.client_code) + N'-' + red_dw.dbo.fact_dimension_main.matter_number AS N'matter'
			,red_dw.dbo.fact_dimension_main.dim_matter_header_curr_key
			,LTRIM(RTRIM(LOWER(red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel3hist))) AS department
			,LTRIM(RTRIM(LOWER(red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel4hist))) AS team
			,LTRIM(RTRIM(LOWER(red_dw.dbo.dim_matter_worktype.work_type_group))) AS work_type_group
			,LTRIM(RTRIM(LOWER(matter_owner_full_name))) AS matter_owner_full_name
			,CASE 
				WHEN fact_detail_reserve_detail.damages_reserve <= 25000 THEN N'fast track'
				WHEN fact_detail_reserve_detail.damages_reserve > 25000 AND fact_detail_reserve_detail.damages_reserve <= quant_25 THEN N'band 1'
				WHEN fact_detail_reserve_detail.damages_reserve > quant_25 AND fact_detail_reserve_detail.damages_reserve <= quant_50 THEN N'band 2'
				WHEN fact_detail_reserve_detail.damages_reserve > quant_50 AND fact_detail_reserve_detail.damages_reserve <= quant_75 THEN N'band 3'
				ELSE N'band 4'
			END AS bin
			,CASE
				WHEN LTRIM(RTRIM(LOWER(red_dw.dbo.dim_matter_header_current.fee_arrangement))) = N'annual retainer' THEN N'annual retainer' 
				WHEN LTRIM(RTRIM(LOWER(red_dw.dbo.dim_matter_header_current.fee_arrangement))) = N'fixed fee/fee quote/capped fee' THEN N'fixed' 
				WHEN LTRIM(RTRIM(LOWER(red_dw.dbo.dim_matter_header_current.fee_arrangement))) = N'hourly rate' THEN N'not fixed' 
				ELSE N'other_or_unknown'
			END AS fee_arrangement
			,CASE
				WHEN LTRIM(RTRIM(LOWER(red_dw.dbo.dim_detail_core_details.proceedings_issued))) NOT IN (N'yes', N'no') OR LTRIM(RTRIM(LOWER(red_dw.dbo.dim_detail_core_details.proceedings_issued))) IS NULL THEN N'unknown' 
				ELSE LTRIM(RTRIM(LOWER(red_dw.dbo.dim_detail_core_details.proceedings_issued)))
			END AS proceedings_issued

			,CASE
				WHEN LTRIM(RTRIM(LOWER(dim_detail_core_details.suspicion_of_fraud))) NOT IN (N'yes', N'no') OR LTRIM(RTRIM(LOWER(dim_detail_core_details.suspicion_of_fraud))) IS NULL THEN N'unknown' 
				ELSE LTRIM(RTRIM(LOWER(dim_detail_core_details.suspicion_of_fraud)))
			END AS suspicion_of_fraud
			,N'damages_paid' AS category
			,red_dw.dbo.fact_finance_summary.damages_paid AS value_for_target
		FROM red_dw.dbo.fact_dimension_main
		LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history	ON red_dw.dbo.dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = red_dw.dbo.fact_dimension_main.dim_fed_hierarchy_history_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome			ON red_dw.dbo.dim_detail_outcome.dim_detail_outcome_key = red_dw.dbo.fact_dimension_main.dim_detail_outcome_key
		LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current	ON red_dw.dbo.dim_matter_header_current.dim_matter_header_curr_key = red_dw.dbo.fact_dimension_main.dim_matter_header_curr_key
		LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype			ON red_dw.dbo.dim_matter_worktype.dim_matter_worktype_key = red_dw.dbo.dim_matter_header_current.dim_matter_worktype_key
		LEFT OUTER JOIN red_dw.dbo.fact_finance_summary			ON red_dw.dbo.fact_finance_summary.master_fact_key = red_dw.dbo.fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_client					ON red_dw.dbo.dim_client.dim_client_key = red_dw.dbo.fact_dimension_main.dim_client_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail	ON red_dw.dbo.fact_detail_reserve_detail.master_fact_key = red_dw.dbo.fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days		ON red_dw.dbo.fact_detail_elapsed_days.master_fact_key = red_dw.dbo.fact_dimension_main.master_fact_key
		LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details		ON red_dw.dbo.fact_dimension_main.dim_detail_core_detail_key = red_dw.dbo.dim_detail_core_details.dim_detail_core_detail_key
		LEFT OUTER JOIN red_dw.dbo.dim_employee					ON red_dw.dbo.dim_employee.dim_employee_key = red_dw.dbo.dim_fed_hierarchy_history.dim_employee_key
		LEFT OUTER JOIN [Reporting].[dbo].[ds_p20_quantiles]	ON LTRIM(RTRIM(LOWER(red_dw.dbo.dim_matter_worktype.work_type_group))) COLLATE Latin1_General_CI_AS = [Reporting].[dbo].[ds_p20_quantiles].work_type_group 
		WHERE
			hierarchylevel2hist = N'Legal Ops - Claims'
			AND dim_matter_worktype.work_type_code != N'0032'
			AND exclude_from_reports = 0
			AND DATEDIFF(DAY, date_opened_case_management, date_claim_concluded) >= 0
			AND LOWER(dim_detail_outcome.outcome_of_case) not in (N'exclude from reports', N'returned to client')
			AND ISNULL(dim_fed_hierarchy_history.jobtitle, N'') != N''
			AND fact_detail_reserve_detail.damages_reserve IS NOT NULL 
			AND LTRIM(RTRIM(LOWER(red_dw.dbo.dim_matter_worktype.work_type_group))) IN (N'disease',	N'el',	N'motor', N'nhsla',	N'pl all')
			AND LTRIM(RTRIM(LOWER(red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel3hist))) IN (N'casualty', N'disease', N'healthcare', N'large loss', N'motor')
			AND red_dw.dbo.dim_detail_outcome.date_claim_concluded IS NOT NULL 
			AND red_dw.dbo.dim_detail_outcome.date_claim_concluded BETWEEN DATEADD(YEAR, -1 * @years_time_window, GETDATE()) AND GETDATE()
			AND red_dw.dbo.fact_finance_summary.damages_paid > 0
	
END;

GO
