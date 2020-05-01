SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 20170822
-- Description:	This is a rewrite of the Local Authority Sector report for Healthcare
--				found on sql2008svr.Reporting.LocalAuthority.LocalAuthoritySectorReport_filtered
--				It uses a date parameters to generate figures for a period and the same period the year before
--				and also includes figures for current YTD and the last two financial years 
--
-- =============================================

--  exec [publicsector].[local_authority_insured_client] '20170501','20170801'

CREATE  PROCEDURE [publicsector].[local_authority_sector_listing_healthcare] 
	-- Add the parameters for the stored procedure here
	@StartDate DATE
	,@EndDate DATE
	,@type INT =1  -- 0 =EMLS; 1=NWLC
AS

	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- For testing purposes
   -- DECLARE @StartDate DATE = '20180501'
			--,@EndDate DATE = '20181231'
			--,@type int = 0
	

	DECLARE @previous_period_from DATE = DATEADD(yyyy,-1,@StartDate)
			,@previous_period_to DATE = DATEADD(yyyy,-1,@EndDate)
			
	
	DECLARE  @nDate DATE = GETDATE()		
			,@fin_year_current INT
			,@fin_year_minus1 INT 
			,@fin_year_minus2 INT

	
	SELECT @fin_year_current = MAX(bill_fin_year)  FROM red_dw.dbo.dim_bill_date WHERE bill_date = @nDate
	SET @fin_year_minus1 = @fin_year_current - 1
	SET @fin_year_minus2 = @fin_year_current - 2


	PRINT @fin_year_current
	PRINT @fin_year_minus1
	PRINT @fin_year_minus2




	
	SELECT 
	
		 CASE WHEN client_list.name IN ('East Midlands Ambulance Service NHS Trust','East Midlands Ambulance Trust') THEN 'East Midlands Ambulance Service NHS Trust' ELSE client_list.name END AS [insuredclient_name] 
		, structure.hierarchylevel3hist [Department]
		, SUM(fin_year_fees_total) AS fin_year_fees_total
		, SUM(fin_year_minus_1_fees_total) AS fin_year_minus_1_fees_total
		, SUM(fin_year_minus_2_fees_total) AS fin_year_minus_2_fees_total
		, SUM(period_fees_total) AS period_fees_total
		, SUM(Previous_period_fees_total) AS Previous_period_fees_total
		, @fin_year_current current_fin_year
		, @fin_year_minus1 fin_year_minus_1
		, @fin_year_minus2 fin_year_minus_2
		, @previous_period_from previous_period_from
		, @previous_period_to previous_period_to
	FROM red_dw.dbo.fact_dimension_main main 
		INNER JOIN red_dw.dbo.dim_matter_header_current matter ON main.dim_matter_header_curr_key = matter.dim_matter_header_curr_key
		INNER JOIN [Reporting].[publicsector].[local_authority_nwlc_emls] client_list ON RTRIM(main.client_code) = client_list.client_code COLLATE DATABASE_DEFAULT AND  client_list.[type] = @type
		INNER JOIN [red_dw].dbo.dim_department dept ON dept.department_code = matter.department_code
		INNER JOIN [red_dw].dbo.dim_matter_worktype worktype ON matter.dim_matter_worktype_key = worktype.dim_matter_worktype_key
		INNER JOIN [red_dw].dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key
		INNER JOIN [red_dw].dbo.dim_detail_outcome outcome ON outcome.dim_detail_outcome_key = main.dim_detail_outcome_key
		INNER JOIN [red_dw].dbo.dim_client client ON client.dim_client_key = main.dim_client_key
		INNER JOIN [red_dw].dbo.fact_finance_summary finance ON finance.master_fact_key = main.master_fact_key
		INNER JOIN [red_dw].dbo.dim_fed_hierarchy_history structure ON structure.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
		INNER JOIN (SELECT 
					fact_bill.client_code 
					,fact_bill.matter_number 
					--,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_current THEN fact_bill.bill_total END,0)) fin_year_bill_total
					,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_current THEN fact_bill.fees_total END,0)) fin_year_fees_total
					,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus1 THEN fact_bill.fees_total END,0)) fin_year_minus_1_fees_total
					--,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus1 THEN fact_bill.bill_total END,0)) fin_year_minus_1_bill_total
					--,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus2 THEN fact_bill.bill_total END,0)) fin_year_minus_2_bill_total
					,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus2 THEN fact_bill.fees_total END,0)) fin_year_minus_2_fees_total
					--,SUM(ISNULL(CASE WHEN bill_date BETWEEN @StartDate AND @EndDate THEN fact_bill.bill_total END,0)) period_bill_total
					,SUM(ISNULL(CASE WHEN bill_date BETWEEN @StartDate AND @EndDate THEN fact_bill.fees_total END,0)) period_fees_total
					--,SUM(ISNULL(CASE WHEN bill_date BETWEEN @previous_period_from AND @previous_period_to THEN fact_bill.bill_total END,0)) previous_period_bill_total
					,SUM(ISNULL(CASE WHEN bill_date BETWEEN @previous_period_from AND @previous_period_to THEN fact_bill.fees_total END,0)) Previous_period_fees_total
					,SUM(ISNULL(fact_bill.bill_total,0)) total_billed
					,SUM(ISNULL(fact_bill.fees_total,0)) fees_total
				FROM
				red_dw.dbo.fact_bill AS fact_bill 
				INNER JOIN [Reporting].[publicsector].[local_authority_nwlc_emls] clList ON fact_bill.client_code = clList.client_code COLLATE DATABASE_DEFAULT AND clList.[type] = @type
				INNER JOIN red_dw.dbo.dim_bill_date ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
				INNER JOIN red_dw.dbo.dim_matter_header_current matter ON matter.client_code=fact_bill.client_code AND matter.matter_number=fact_bill.matter_number
				INNER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.master_fact_key = fact_bill.master_fact_key
				INNER JOIN [red_dw].dbo.dim_client client ON client.client_code = matter.client_code
				INNER JOIN [red_dw].dbo.dim_detail_outcome outcome ON  outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
				INNER JOIN [red_dw].dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
				INNER JOIN [red_dw].dbo.dim_matter_worktype worktype ON matter.dim_matter_worktype_key = worktype.dim_matter_worktype_key
			    
				WHERE
				-- exclude test and ml matters
				 matter.reporting_exclusions = 0
				-- exclude from reports 
				AND (outcome.[outcome_of_case] <> 'Exclude from reports' OR outcome.[outcome_of_case] IS NULL ) 
				-- insured sector is blank or is local and central goverment
				AND dim_bill_date.bill_fin_year >= @fin_year_minus2
		
				GROUP BY fact_bill.client_code 
							,fact_bill.matter_number 
		) finances ON finances.client_code = matter.client_code AND finances.matter_number = matter.matter_number 

	WHERE 
		-- exclude test and ml matters
		 matter.reporting_exclusions = 0
		---- exclude from reports 
		AND (outcome.[outcome_of_case] <> 'Exclude from reports' OR outcome.[outcome_of_case] IS NULL ) 
		-- Total Billed for the whole file is not 0 or null
		AND finance.total_amount_billed <> 0 
		AND finance.total_amount_billed IS NOT NULL
		AND finances.total_billed + finances.fees_total > 0 
		-- department is Local Government Lit and sub_sector is in ('Insurance','Local and Central Government') but exclude
		-- the worktypes where the code falls between 1000 and 1138 or 1355 and 1361
		--AND client.sub_sector IN ('Local & Central Government','Local and Central Government')
		AND (worktype.work_type_code IN  ('0007','0009','0010','0012','0014','0015','0022')
									OR worktype.work_type_code BETWEEN '1000' AND '1138' 
									OR worktype.work_type_code BETWEEN '1128' AND '1134'
									OR worktype.work_type_code BETWEEN '1355' AND '1361')
		AND		(
						(	dept.department_code = '0029'
							AND (	worktype.work_type_code IN  ('0007','0009','0010','0012','0014','0015','0022')
									OR worktype.work_type_code BETWEEN '1128' AND '1134'
									OR worktype.work_type_code BETWEEN '1355' AND '1361'
								)	 
						)
						OR
						(	matter.date_closed_case_management IS NULL OR matter.date_closed_case_management >= '20130101'
							AND 
								( worktype.work_type_code IN  ('0007','0009','0010','0012','0014','0015','0022')
									OR worktype.work_type_code BETWEEN '1000' AND '1138' 
									OR worktype.work_type_code BETWEEN '1355' AND '1361'

								)
						)

				)

GROUP BY CASE WHEN client_list.name IN ('East Midlands Ambulance Service NHS Trust','East Midlands Ambulance Trust') THEN 'East Midlands Ambulance Service NHS Trust' ELSE client_list.name END 
	,structure.hierarchylevel3hist
	
	ORDER BY CASE WHEN client_list.name IN ('East Midlands Ambulance Service NHS Trust','East Midlands Ambulance Trust') THEN 'East Midlands Ambulance Service NHS Trust' ELSE client_list.name END  ASC























GO
