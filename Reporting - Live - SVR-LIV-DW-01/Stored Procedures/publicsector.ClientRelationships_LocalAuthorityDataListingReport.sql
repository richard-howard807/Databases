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
-- 1.1 #77976 amended logic requested by A-M
-- #134494, amended type logic to take into account the specialty work type
-- =============================================


CREATE PROCEDURE [publicsector].[ClientRelationships_LocalAuthorityDataListingReport] 
-- Add the parameters for the stored procedure here
	@period_from DATE
	,@period_to DATE
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	-- For testing purposes
   -- DECLARE @period_from DATE = '20200501'
			--,@period_to DATE = '20201031'
	

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

	/*The matter should be classified as “litigated” if the work type group 
	is in your list below ('EL','PL All','Disease','Claims Handling','Motor','Insurance Costs','Prof Risk','NHSLA','LMT','Recovery'), 
	otherwise it should be classified as “core” */
	CASE WHEN TRIM(work_type_group) IN ('EL','PL All','Disease','Claims Handling','Motor','Insurance Costs','Prof Risk','NHSLA','LMT','Recovery')
	THEN 'Litigation Work' 
	WHEN work_type_name LIKE ('Specialty:%')
	THEN 'Litigation Work'
	ELSE 'Core Work' END AS  [Type]
		, matter.client_code
		, matter.matter_number
		, matter.matter_description
		, matter.client_name
		, matter.client_group_name
		, claim.dst_insured_client_name [Client/Insured Client Name]
		, CASE WHEN claim.dst_insured_client_name IS NOT NULL THEN LTRIM(RTRIM(claim.dst_insured_client_name))
			WHEN client.sector  IN ('Local & Central Government','Local and Central Government') THEN RTRIM(client.client_name)
			ELSE RTRIM(insured.insuredclient_name)
			END [name_calculation]
		, insuredclient_name [insuredclient_name] 
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
		LEFT JOIN [red_dw].dbo.dim_department dept ON dept.department_code = matter.department_code
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
			
			WHERE 1= 1
	
			AND dim_bill_date.bill_fin_year >= @fin_year_minus2
			GROUP BY fact_bill.client_code 
					,fact_bill.matter_number
	) finances ON finances.client_code = matter.client_code AND finances.matter_number = matter.matter_number 

WHERE 
	-- exclude test and ml matters
	matter.reporting_exclusions = 0
	AND finance.total_amount_billed <> 0 
	AND finance.total_amount_billed IS NOT NULL
	AND finances.total_billed + finances.fees_total <> 0 

AND (TRIM(core.[insured_sector]) = 'Local & Central Government' OR TRIM(client.sector) = 'Local & Central Government' )
OR LOWER(insuredclient_name) LIKE '%council%'  OR LOWER(insuredclient_name) LIKE '% borough%' OR LOWER(insuredclient_name) LIKE '%mbc%'


END		








GO
