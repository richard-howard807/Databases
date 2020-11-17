SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 20170822
-- Description:	This is a rewrite of the Local Authority Sector report 
--				found on sql2008svr.Reporting.LocalAuthority.LocalAuthoritySectorReportV2
--				It uses a date parameters to generate figures for a period and the same period the year before
--				and also includes figures for current YTD and the last two financial years 
--
-- =============================================

  --exec [publicsector].[local_authority_insured_client] '20190501','20200801'
-- added a soundex function to group
create PROCEDURE [publicsector].[local_authority_sector_listing_test_OK] 
--	-- Add the parameters for the stored procedure here
	@period_from DATE
	,@period_to DATE
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- For testing purposes
   -- DECLARE @period_from DATE = '20190501'
			--,@period_to DATE = '20191031'
	

	DECLARE @previous_period_from DATE = DATEADD(yyyy,-1,@period_from)
			,@previous_period_to DATE = DATEADD(yyyy,-1,@period_to)
			
	
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
	
		'Litigation Work' [Type]
		, matter.client_code
		, matter.matter_number
		, matter.matter_description
		, matter.client_name
		, matter.client_group_name
		, claim.dst_insured_client_name [Client/Insured Client Name]
		, CASE WHEN claim.dst_insured_client_name IS NOT NULL THEN LTRIM(RTRIM(claim.dst_insured_client_name))
			WHEN client.sector  IN ('Local & Central Government','Local and Central Government') THEN RTRIM(client.client_name)
			ELSE RTRIM(claim.insured_client_name)
			END [name_calculation]
		, ISNULL(insuredclient_name,matter.client_name) [insuredclient_name] 
	--	, SOUNDEX(ISNULL(insuredclient_name,matter.client_name)) [Group] -- it works well in some instances but totally wrong in others
		, matter.date_closed_case_management
		, dept.department_code
		, dept.department_name
		, worktype.work_type_code
		, worktype.work_type_name
		, matter.reporting_exclusions
		, core.insured_sector
		, outcome.outcome_of_case
		, client.sector
		, client.sub_sector
		, client.segment
		, finance.total_amount_billed
		, structure.name 
		, structure.hierarchylevel2hist [Business Line]
		, structure.hierarchylevel3hist [Practice Area]
		, structure.hierarchylevel4hist [Team]
		, matter.final_bill_date
		, finances.fin_year_bill_total
		, fin_year_fees_total
		, fin_year_minus_1_fees_total
		, fin_year_minus_1_bill_total
		, fin_year_minus_2_bill_total
		, fin_year_minus_2_fees_total
		, period_bill_total
		, period_fees_total
		, previous_period_bill_total
		, Previous_period_fees_total
			, CASE WHEN claim.dst_insured_client_name IS NULL AND client.sector = 'Local & Central Government' THEN client.client_name  ELSE claim.insured_client_name END AS [dstinsured]
		, matter.date_opened_case_management
		, @fin_year_current current_fin_year
		, @fin_year_minus1 fin_year_minus_1
		, @fin_year_minus2 fin_year_minus_2
		, @previous_period_from previous_period_from
		, @previous_period_to previous_period_to

	FROM red_dw.dbo.dim_matter_header_current matter 
		INNER JOIN [red_dw].dbo.dim_department dept ON dept.department_code = matter.department_code
		INNER JOIN [red_dw].dbo.dim_matter_worktype worktype ON matter.dim_matter_worktype_key = worktype.dim_matter_worktype_key
		INNER JOIN [red_dw].dbo.dim_detail_core_details core ON core.client_code = matter.client_code AND core.matter_number = matter.matter_number
		INNER JOIN [red_dw].dbo.dim_detail_outcome outcome ON outcome.client_code = matter.client_code AND outcome.matter_number = matter.matter_number
		INNER JOIN [red_dw].dbo.dim_client client ON client.client_code = matter.client_code
		INNER JOIN [red_dw].dbo.fact_finance_summary finance ON finance.client_code = matter.client_code AND finance.matter_number = matter.matter_number
		INNER JOIN [red_dw].dbo.dim_fed_hierarchy_history structure ON matter.fee_earner_code = structure.fed_code AND structure.dss_current_flag = 'Y'
		INNER JOIN red_dw.dbo.dim_detail_claim claim ON claim.client_code = core.client_code AND claim.matter_number = core.matter_number
		LEFT OUTER JOIN [red_dw].[dbo].[dim_client_involvement] insured ON insured.client_code = matter.client_code AND insured.matter_number = matter.matter_number
		INNER JOIN (SELECT 
				fact_bill.client_code 
				,fact_bill.matter_number 
				,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_current THEN fact_bill.bill_total END,0)) fin_year_bill_total
				,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_current THEN fact_bill.fees_total END,0)) fin_year_fees_total
				,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus1 THEN fact_bill.fees_total END,0)) fin_year_minus_1_fees_total
				,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus1 THEN fact_bill.bill_total END,0)) fin_year_minus_1_bill_total
				,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus2 THEN fact_bill.bill_total END,0)) fin_year_minus_2_bill_total
				,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus2 THEN fact_bill.fees_total END,0)) fin_year_minus_2_fees_total
				,SUM(ISNULL(CASE WHEN bill_date BETWEEN @period_from AND @period_to THEN fact_bill.bill_total END,0)) period_bill_total
				,SUM(ISNULL(CASE WHEN bill_date BETWEEN @period_from AND @period_to THEN fact_bill.fees_total END,0)) period_fees_total
				,SUM(ISNULL(CASE WHEN bill_date BETWEEN @previous_period_from AND @previous_period_to THEN fact_bill.bill_total END,0)) previous_period_bill_total
				,SUM(ISNULL(CASE WHEN bill_date BETWEEN @previous_period_from AND @previous_period_to THEN fact_bill.fees_total END,0)) Previous_period_fees_total
				,SUM(ISNULL(fact_bill.bill_total,0)) total_billed
				,SUM(ISNULL(fact_bill.fees_total,0)) fees_total
			FROM
			red_dw.dbo.fact_bill AS fact_bill 
			INNER JOIN red_dw.dbo.dim_bill_date ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
			INNER JOIN red_dw.dbo.dim_matter_header_current matter ON matter.client_code=fact_bill.client_code AND matter.matter_number=fact_bill.matter_number
			INNER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.master_fact_key = fact_bill.master_fact_key
			INNER JOIN [red_dw].dbo.dim_client client ON client.client_code = matter.client_code
			INNER JOIN [red_dw].dbo.dim_detail_outcome outcome ON outcome.client_code = matter.client_code AND outcome.matter_number = matter.matter_number
			INNER JOIN [red_dw].dbo.dim_detail_core_details core ON core.client_code = matter.client_code AND core.matter_number = matter.matter_number
			INNER JOIN [red_dw].dbo.dim_matter_worktype worktype ON matter.dim_matter_worktype_key = worktype.dim_matter_worktype_key
			 
			WHERE
		
			-- exclude test and ml matters
			 matter.reporting_exclusions = 0
			-- exclude from reports 
			AND (outcome.[outcome_of_case] <> 'Exclude from reports' OR outcome.[outcome_of_case] IS NULL ) 
			--AND (core.[insured_sector] = 'Local & Central Government' OR core.[insured_sector] IS NULL)-----------------------AM
			AND(
			( client.sector =  'Local & Central Government') OR (core.[insured_sector] = 'Local & Central Government                                 ' )
			OR( LOWER(matter.matter_description) LIKE '%council%' ) OR (LOWER(matter.matter_description) LIKE '%borough%') OR ( LOWER(matter.matter_description) LIKE '%mbc%')
			--or( LOWER(insured_client_name) LIKE '%council%' ) OR (LOWER(claim.dst_insured_client_name) LIKE '%borough%') OR ( LOWER(claim.dst_insured_client_name) LIKE '%mbc%')



			)

		
			AND dim_bill_date.bill_fin_year >= @fin_year_minus2
			GROUP BY fact_bill.client_code 
					,fact_bill.matter_number 
	) finances ON finances.client_code = matter.client_code AND finances.matter_number = matter.matter_number 

WHERE 
	-- exclude test and ml matters
	matter.reporting_exclusions = 0
	---- exclude from reports 
	AND (outcome.[outcome_of_case] <> 'Exclude from reports' OR outcome.[outcome_of_case] IS NULL ) 
	-- insured sector is blank or is local and central goverment
	

---------AND (core.[insured_sector] = 'Local & Central Government' OR core.[insured_sector] IS NULL)    AM 
		AND( client.sector =  'Local & Central Government' OR core.[insured_sector] = 'Local & Central Government                                 ' )
	-- Total Billed for the whole file is not 0 or null
	AND finance.total_amount_billed <> 0 
	AND finance.total_amount_billed IS NOT NULL
	AND finances.total_billed + finances.fees_total > 0 
	-- exclude the worktypes where the code falls between 1000 and 1138 or 1355 and 1361
	AND NOT worktype.work_type_code BETWEEN '1000' AND '1138'
	AND NOT worktype.work_type_code BETWEEN '1355' AND '1361'
	AND worktype.work_type_code NOT IN ('0007','0009','0010','0012','0014','0015','0022')
	--AND core_or_lit.[type] = 'lit'
	AND (	(	
				dept.department_code = '0004'
				AND client.sub_sector IN ('Insurance','Local & Central Government','Local and Central Government')
			)
			--=====================================
			OR
			
			(
				(
					worktype.work_type_code BETWEEN '1200' AND '1354'
					OR worktype.work_type_code = '0032'
					OR worktype.work_type_code >= '1567'
				)
				AND core.[insured_sector] = 'Local & Central Government'
			)
			--============================
			OR client.sub_sector IN ('Local & Central Government','Local and Central Government')
			

		 )

--=========================================================================================================
	UNION ALL
--=========================================================================================================

	SELECT 
	
		'Core Work' [Type]
		, matter.client_code
		, matter.matter_number
		, matter.matter_description
		, matter.client_name
		, matter.client_group_name
		,claim.dst_insured_client_name [Client/Insured Client Name]
		, CASE WHEN claim.dst_insured_client_name IS NOT NULL THEN LTRIM(RTRIM(claim.dst_insured_client_name))
			WHEN client.sector  IN ('Local & Central Government','Local and Central Government') THEN RTRIM(client.client_name)
			ELSE RTRIM(claim.insured_client_name)
			END [name_calculation]
		, ISNULL(insuredclient_name,matter.client_name) [insuredclient_name] 
	--	, SOUNDEX(ISNULL(insuredclient_name,matter.client_name)) [Group] -- it works well in some instances but totally wrong in others
		, matter.date_closed_case_management
		, dept.department_code
		, dept.department_name
		, worktype.work_type_code
		, worktype.work_type_name
		, matter.reporting_exclusions
		, core.insured_sector
		, outcome.outcome_of_case
		, client.sector
		, client.sub_sector
		, client.segment
		, finance.total_amount_billed
		, structure.name 
		, structure.hierarchylevel2hist [Business Line]
		, structure.hierarchylevel3hist [Practice Area]
		, structure.hierarchylevel4hist [Team]
		, matter.final_bill_date
		, finances.fin_year_bill_total
		, fin_year_fees_total
		, fin_year_minus_1_fees_total
		, fin_year_minus_1_bill_total
		, fin_year_minus_2_bill_total
		, fin_year_minus_2_fees_total
		, period_bill_total
		, period_fees_total
		, previous_period_bill_total
		, Previous_period_fees_total
		, CASE WHEN claim.dst_insured_client_name IS NULL AND client.sector = 'Local & Central Government' THEN client.client_name  ELSE claim.insured_client_name END AS [dstinsured]
		, matter.date_opened_case_management
		, @fin_year_current current_fin_year
		, @fin_year_minus1 fin_year_minus_1
		, @fin_year_minus2 fin_year_minus_2
		, @previous_period_from previous_period_from
		, @previous_period_to previous_period_to
		
	FROM red_dw.dbo.dim_matter_header_current matter 
		INNER JOIN [red_dw].dbo.dim_department dept ON dept.department_code = matter.department_code
		INNER JOIN [red_dw].dbo.dim_matter_worktype worktype ON matter.dim_matter_worktype_key = worktype.dim_matter_worktype_key
		INNER JOIN [red_dw].dbo.dim_detail_core_details core ON core.client_code = matter.client_code AND core.matter_number = matter.matter_number
		INNER JOIN [red_dw].dbo.dim_detail_outcome outcome ON outcome.client_code = matter.client_code AND outcome.matter_number = matter.matter_number
		INNER JOIN [red_dw].dbo.dim_client client ON client.client_code = matter.client_code
		INNER JOIN [red_dw].dbo.fact_finance_summary finance ON finance.client_code = matter.client_code AND finance.matter_number = matter.matter_number
		INNER JOIN [red_dw].dbo.dim_fed_hierarchy_history structure ON matter.fee_earner_code = structure.fed_code AND structure.dss_current_flag = 'Y'
		INNER JOIN red_dw.dbo.dim_detail_claim claim ON claim.client_code = core.client_code AND claim.matter_number = core.matter_number
		LEFT OUTER JOIN [red_dw].[dbo].[dim_client_involvement] insured ON insured.client_code = matter.client_code AND insured.matter_number = matter.matter_number
		INNER JOIN (SELECT 
					fact_bill.client_code 
					,fact_bill.matter_number 
					,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_current THEN fact_bill.bill_total END,0)) fin_year_bill_total
					,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_current THEN fact_bill.fees_total END,0)) fin_year_fees_total
					,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus1 THEN fact_bill.fees_total END,0)) fin_year_minus_1_fees_total
					,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus1 THEN fact_bill.bill_total END,0)) fin_year_minus_1_bill_total
					,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus2 THEN fact_bill.bill_total END,0)) fin_year_minus_2_bill_total
					,SUM(ISNULL(CASE WHEN bill_fin_year = @fin_year_minus2 THEN fact_bill.fees_total END,0)) fin_year_minus_2_fees_total
					,SUM(ISNULL(CASE WHEN bill_date BETWEEN @period_from AND @period_to THEN fact_bill.bill_total END,0)) period_bill_total
					,SUM(ISNULL(CASE WHEN bill_date BETWEEN @period_from AND @period_to THEN fact_bill.fees_total END,0)) period_fees_total
					,SUM(ISNULL(CASE WHEN bill_date BETWEEN @previous_period_from AND @previous_period_to THEN fact_bill.bill_total END,0)) previous_period_bill_total
					,SUM(ISNULL(CASE WHEN bill_date BETWEEN @previous_period_from AND @previous_period_to THEN fact_bill.fees_total END,0)) Previous_period_fees_total
					,SUM(ISNULL(fact_bill.bill_total,0)) total_billed
					,SUM(ISNULL(fact_bill.fees_total,0)) fees_total
				FROM
				red_dw.dbo.fact_bill AS fact_bill 
				INNER JOIN red_dw.dbo.dim_bill_date ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
				INNER JOIN red_dw.dbo.dim_matter_header_current matter ON matter.client_code=fact_bill.client_code AND matter.matter_number=fact_bill.matter_number
				INNER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.master_fact_key = fact_bill.master_fact_key
				INNER JOIN [red_dw].dbo.dim_client client ON client.client_code = matter.client_code
				INNER JOIN [red_dw].dbo.dim_detail_outcome outcome ON outcome.client_code = matter.client_code AND outcome.matter_number = matter.matter_number
				INNER JOIN [red_dw].dbo.dim_detail_core_details core ON core.client_code = matter.client_code AND core.matter_number = matter.matter_number
				INNER JOIN [red_dw].dbo.dim_matter_worktype worktype ON matter.dim_matter_worktype_key = worktype.dim_matter_worktype_key
						INNER JOIN red_dw.dbo.dim_detail_claim claim ON claim.client_code = core.client_code AND claim.matter_number = core.matter_number
			 
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
			AND( client.sector =  'Local & Central Government' OR core.[insured_sector] = 'Local & Central Government                                 ' )
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

















END		








GO
