SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 20/11/2017
-- Description: 
--===============================================
CREATE PROCEDURE [marketing].[generator_programme_report_summary_by_sector]
(
	@CurrentFinancialYear INT
	,@finMonth INT
)
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --=== For testing purposes=============
	--DECLARE @CurrentFinancialYear INT = 2019
	--DECLARE @finMonth INT = 2
	--======================================

	DECLARE @PreviousFinancialYear INT 
	DECLARE @PrevFinancialYearMinus1 INT

	SET @PreviousFinancialYear = @CurrentFinancialYear - 1
	SET @PrevFinancialYearMinus1 = @CurrentFinancialYear - 2
	DECLARE @Delimiter VARCHAR(10) = ';'
	
	DECLARE @StartDate INT
	DECLARE @EndDate INT 
	SELECT @EndDate =  MAX(dim_date_key) FROM red_dw.dbo.dim_date WHERE fin_year = @CurrentFinancialYear AND fin_month_no = @finMonth
	PRINT @EndDate
	SELECT @StartDate = MIN(dim_date_key) FROM red_dw.dbo.dim_date WHERE fin_year = @PrevFinancialYearMinus1 AND fin_month_no = 1
	PRINT @StartDate
	
	
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#GeneratorStatus')) 
					DROP TABLE #GeneratorStatus
	SELECT  
			DISTINCT[cboGenClientStatus]
			,ISNULL(NULLIF(udClientGroup.[description],''), dbClient.clName)[client_group_name]
			,matter_header.client_code
	INTO #GeneratorStatus
	FROM [MS_Prod].[dbo].[udExtClient] udExtClient
	INNER JOIN MS_Prod.config.dbClient dbClient ON dbClient.clID = udExtClient.clID
	LEFT JOIN MS_Prod.dbo.dbUser dbUser ON dbUser.usrID = udExtClient.cboPartner
	LEFT JOIN MS_Prod.dbo.udClientGroup udClientGroup ON udClientGroup.code = udExtClient.cboClientGroup
	LEFT JOIN (SELECT DISTINCT client_code,master_client_code FROM red_dw.dbo.dim_matter_header_current ) matter_header ON dbClient.clNo = matter_header.master_client_code COLLATE DATABASE_DEFAULT
	WHERE cboGenClientStatus IS NOT NULL -- only those clients that have a status
	AND cboGenClientStatus <> '0004'
	AND dbClient.clID <> '69873' -- a collegiate management limited file that should be excluded  (has a markel client group)
	
	SELECT 
			
		COALESCE(generator.client_group_name,dim_client.client_name COLLATE DATABASE_DEFAULT) client_group_name
		,dim_client.sector
		,dim_client.segment
  		,CASE	WHEN [cboGenClientStatus] = '0001' THEN 'Patron'
				WHEN [cboGenClientStatus] = '0002' THEN 'Star'
				WHEN [cboGenClientStatus] = '0003' THEN 'Rising Star'
				WHEN [cboGenClientStatus] = '0004' THEN 'Client'
				END [generator_category]
		,[cboGenClientStatus] [category_code]
		,SUM(CASE WHEN @PrevFinancialYearMinus1 = fin_year THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [fin_year_minus_2]
		,SUM(CASE WHEN @PreviousFinancialYear = fin_year THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [fin_year_minus_1]
		,SUM(CASE WHEN @PreviousFinancialYear = fin_year AND billed_date.fin_month_no <= @finMonth THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [prev_ytd]
		,SUM(CASE WHEN @CurrentFinancialYear = fin_year AND  billed_date.fin_month_no <= @finMonth THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [curr_ytd]

	
	FROM [red_dw].[dbo].[fact_bill_activity] fact_bill_activity
	INNER JOIN red_dw.dbo.dim_client dim_client ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
	INNER JOIN red_dw.dbo.dim_date billed_date ON fact_bill_activity.dim_bill_date_key = billed_date.dim_date_key
	INNER JOIN #GeneratorStatus generator ON generator.client_code = fact_bill_activity.client_code 
    WHERE  billed_date.dim_date_key BETWEEN @StartDate AND @EndDate 
	AND fact_bill_activity.client_code <> '00069873'
	AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
	GROUP BY 
  		COALESCE(generator.client_group_name,dim_client.client_name COLLATE DATABASE_DEFAULT)
		,dim_client.sector
		,dim_client.segment
		,[cboGenClientStatus]
	ORDER BY category_code
	
	













GO
