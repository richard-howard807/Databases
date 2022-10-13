SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--USE [Reporting]
--GO
--/****** Object:  StoredProcedure [marketing].[client_generator_report_summary]    Script Date: 01/09/2021 13:48:21 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO




---- =============================================
---- Author:		Lucy Dickinson
---- Create date: 20/11/2017
---- Description: Stored Procedure for the Generator Programm Report in the Marketing folder
----===============================================
---- 19/02/2019 LD  Added a new Generator Status called Pipeline and tried to improve the report a bit
----					Rewrote the current generator programme report to deal with Pipeline clients and just tweaked to improve experience
---- 03/09/2021 JB	Added CBO clients for ticket #112091 rather than create a new report as they want the same data
---- 04/10/2022 JL  Have changed the list of Generator Programme Clients Only as per ticket #171290

CREATE PROCEDURE [marketing].[client_generator_report_summary]
(
	@fin_period INT
	
)
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	
    --=== For testing purposes=============
	--DECLARE @fin_period INT = 202309
	--======================================


	DECLARE @CurrentFinancialYear INT  
	DECLARE @PreviousFinancialYear INT 
	DECLARE @PrevFinancialYearMinus1 INT

	DECLARE @PrevFinYearMinus1Start DATE
		,@PrevFinYearMinus1End DATE
		,@PrevFinYearStart DATE
		,@PrevFinYearEnd DATE
		,@CurrFinYearStart DATE
		,@PrevPeriodEnd DATE
		,@CurrPeriodEnd DATE


	SELECT  @CurrentFinancialYear = fin_year FROM red_dw.dbo.dim_date WHERE fin_month = @fin_period
	SELECT  @PreviousFinancialYear = fin_year FROM red_dw.dbo.dim_date WHERE fin_month = @fin_period - 100
	SELECT  @PrevFinancialYearMinus1 = fin_year FROM red_dw.dbo.dim_date WHERE fin_month = @fin_period - 200
	
	SELECT @PrevFinYearMinus1Start = MIN(calendar_date), @PrevFinYearMinus1End = MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_year = @PrevFinancialYearMinus1
	SELECT @PrevFinYearStart = MIN(calendar_date), @PrevFinYearEnd = MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_year = @PreviousFinancialYear
	SELECT @PrevPeriodEnd = MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_month = @fin_period - 100
	SELECT @CurrFinYearStart = MIN(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_year = @CurrentFinancialYear
	SELECT @CurrPeriodEnd = MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE fin_month = @fin_period
	
	
	
	--PRINT @PrevFinancialYearMinus1
	--PRINT @PrevFinYearMinus1Start
	--PRINT @PrevFinYearMinus1End
	
	--PRINT @PreviousFinancialYear
	--PRINT @PrevFinYearStart
	--PRINT @PrevFinYearEnd
	--PRINT @PrevPeriodEnd

	--PRINT @CurrentFinancialYear
	--PRINT @CurrFinYearStart
	--PRINT @CurrPeriodEnd
	
	
	
	DECLARE @Delimiter VARCHAR(10) = ';'
	
	DECLARE @StartDate INT
	DECLARE @EndDate INT 
	
	SELECT @EndDate =  MAX(dim_date_key) FROM red_dw.dbo.dim_date WHERE cal_month = @fin_period
	PRINT @EndDate
	SELECT @StartDate = MIN(dim_date_key) FROM red_dw.dbo.dim_date WHERE fin_year = @PrevFinancialYearMinus1 AND fin_month_no = 1
	PRINT @StartDate
	

--===========================================================================================================================================	
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#cbo_clients')) 
					DROP TABLE #cbo_clients


SELECT DISTINCT
	dim_client.client_code
	, CASE
		WHEN ISNULL(NULLIF(dim_client.client_group_name, ''), dim_client.client_name) = 'Global orphan group'	 THEN
			'HealthNet Homecare (UK) Limited' 
		ELSE
			ISNULL(NULLIF(dim_client.client_group_name, ''), dim_client.client_name)
	  END																			AS client_name
	, NULL AS [cboGenClientStatus]
	, 'cbo'		AS generator_category
	, 'cbo'		AS report_type
INTO #cbo_clients
FROM red_dw.dbo.dim_client
WHERE
	ISNULL(NULLIF(dim_client.client_group_name, ''), dim_client.client_name) IN (
	N'All About Food Limited',
	N'OBG',
	N'S Norton & Co Ltd',
	N'Edge Worldwide Logistics Ltd',
	N'WHT Holdings Limied',
	N'Albany Products Limited',
	N'Dennis Distribution',
	N'Dennis Distribution LLP',
	N'DENNIS DISTRIBUTION',
	N'Mach Recruitment Limited',
	N'Ultima Furniture Systems Limited',
	N'PSI Global Ltd',
	N'Gadcap Technical Solutions Limited',
	N'HiComply Ltd',
	N'Blackrose Management Limited',
	N'Gaist',
	N'Ansador Limited',
	N'Empresaria Group plc',
	N'Pure World Energy Limited',
	N'Sontay Limited',
	N'Turners Soham Turners Soham',
	N'McGills Bus Company',
	N'SB Drug Discovery Limited'
	)
	OR ISNULL(NULLIF(dim_client.client_group_name, ''), dim_client.client_name) LIKE 'Sandal Motors (Bayern) Limited%'
	OR dim_client.client_code = 'W23164'


--===========================================================================================================================================
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#GeneratorStatus')) 
					DROP TABLE #GeneratorStatus
SELECT  
			DISTINCT cboGenClientStatus AS[cboGenClientStatus]
			,ISNULL(NULLIF(client_data.group_name,''), client_data.client_name)[client_group_name]
			,client_code
			, 'generator'		AS report_type
INTO #GeneratorStatus
FROM (
	SELECT DISTINCT
		CASE 
				WHEN (RTRIM(dim_client.client_code) = 'T3003' 
					OR ISNULL(dim_detail_claim.name_of_instructing_insurer, '') = 'Tesco Underwriting (TU)') AND dim_client.client_group_name = 'Ageas' THEN 
					'Tesco'
				WHEN dim_client.client_group_name = 'Ageas' THEN 
					CASE 
						WHEN RTRIM(dim_client.client_code) <> 'T3003' AND ISNULL(dim_detail_claim.name_of_instructing_insurer, '') <> 'Tesco Underwriting (TU)' 
							AND dim_client.client_group_name = 'Ageas' THEN 
							'Ageas'
					END 
				ELSE 
					dim_client.client_group_name
		END										AS [group_name]
		, CASE	
			WHEN ISNULL(dim_client.client_group_name, '') = '' THEN
				dim_client.client_name
		  END			AS [client_name]
		  ,dim_client.client_code
	FROM red_dw.dbo.dim_client
			INNER JOIN red_dw.dbo.dim_matter_header_current
				ON dim_matter_header_current.client_code = dim_client.client_code
			LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
				ON dim_detail_claim.client_code = dim_matter_header_current.client_code
					AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
	WHERE  dim_matter_header_current.master_client_code <> '69873'-- Collegiate Management Ltd issue (file switched client)
	)		AS client_data
	LEFT OUTER JOIN ms_prod.config.dbClient
	 ON client_data.client_code=clNo COLLATE DATABASE_DEFAULT 
	LEFT OUTER JOIN ms_prod.dbo.udExtClient
	 ON udExtClient.clID = dbClient.clID
WHERE 1 = 1
	AND ISNULL(NULLIF(client_data.group_name, ''), client_data.client_name) <> 'AXA Insurance UK Plc'
	AND ISNULL(NULLIF(client_data.group_name, ''), client_data.client_name) IN (
		N'Zurich',
		N'NHS Resolution',
		N'Ageas',
		N'AXA XL',
		N'AXA Insurance UK Plc',
		N'AXA Insurance UK Plc',
		N'AIG',
		N'Royal Mail',
		N'Markel',
		N'Surrey Police',
		N'Sussex Police',
		N'Sabre',
		N'pwc',
		N'Clarion Housing Group Limited',
		N'Metropolitan Police',
		N'Northern Powergrid',
		N'Co-op/Markerstudy',
		N'Tesco',
		N'Hastings Direct',
		N'Hiscox Group'                            
	)
	OR ISNULL(NULLIF(client_data.group_name, ''), client_data.client_name) LIKE '%Northern Electric%'
	--	SELECT  
--			DISTINCT[cboGenClientStatus]
--			,ISNULL(NULLIF(udClientGroup.[description],''), dbClient.clName)[client_group_name]
--			,matter_header.client_code
--	INTO #GeneratorStatus
--	FROM [MS_Prod].[dbo].[udExtClient] udExtClient
--	INNER JOIN MS_Prod.config.dbClient dbClient ON dbClient.clID = udExtClient.clID
--	LEFT JOIN MS_Prod.dbo.dbUser dbUser ON dbUser.usrID = udExtClient.cboPartner
--	LEFT JOIN MS_Prod.dbo.udClientGroup udClientGroup ON udClientGroup.code = udExtClient.cboClientGroup
--	LEFT JOIN (SELECT DISTINCT client_code,master_client_code FROM red_dw.dbo.dim_matter_header_current ) matter_header ON dbClient.clNo = matter_header.master_client_code COLLATE DATABASE_DEFAULT
--	--WHERE cboGenClientStatus IS NOT NULL -- only those clients that have a status
--	--AND cboGenClientStatus NOT IN ('0004','0005')
--	--AND dbClient.clID <> '69873' -- a collegiate management limited file that should be excluded  (has a markel client group)
--	WHERE cboGenClientStatus IS NOT NULL -- only those clients that have a status
--	AND ISNULL(NULLIF(udClientGroup.[description],''),dbClient.clName) <>'AXA Insurance UK Plc'
--	AND ISNULL(NULLIF(udClientGroup.[description],''),dbClient.clName) 
--IN (
--N'Zurich',N'Zurich',N'NHS Resolution',N'Ageas',
--N'AXA XL',N'AXA Insurance UK Plc',N'AXA Insurance UK Plc',
--N'AIG',N'Royal Mail',N'Markel',N'Markel',N'BARRATT PLC',
--N'Surrey Police',N'Sussex Police',N'Sabre',N'pwc',N'Bibby Group',
--N'Clarion Housing Group Limited',
--N'Metropolitan Police',
--N'Sovini Group', 
--N'Business Energy Solutions Ltd' ,                                                
--N'BES Utilities Holding Ltd',                                                    
--N'BES Metering Services Limited',  
--N'BES Group',
--N'Northern Powergrid'
--)

--OR (dbClient.clNo = 'W21402') OR (ISNULL(NULLIF(udClientGroup.[description],''),dbClient.clName) LIKE '% : Northern Electrical Facilities Limited')
	
	

		 ------------------------------------------------------------------------------------------------------------------------------


	SELECT 
			
		COALESCE(generator.client_group_name,dim_client.client_name COLLATE DATABASE_DEFAULT) client_group_name
		,dim_client.sector
		,dim_client.segment
  		--,CASE	WHEN [cboGenClientStatus] = '0001' THEN 'Patron'
				--WHEN [cboGenClientStatus] = '0002' THEN 'Star'
				--WHEN [cboGenClientStatus] = '0003' THEN 'Rising Star'
				--WHEN [cboGenClientStatus] = '0004' THEN 'Client'
				--WHEN [cboGenClientStatus] = '0005' THEN 'Pipeline'

				--END [generator_category]
		,CASE WHEN dim_client.client_group_name IN ('BES Group','Bibby Group') THEN 'Star' ELSE 'Patron' END  AS [generator_category] -- Sarah Gerrad asked for them all to show as Parton
		,[cboGenClientStatus] [category_code]
		, generator.report_type	AS report_type
		,SUM(CASE WHEN fin_year = @PrevFinancialYearMinus1 THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [fin_year_minus_2]
		,SUM(CASE WHEN fin_year = @PreviousFinancialYear THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [fin_year_minus_1]
		,SUM(CASE WHEN calendar_date BETWEEN @PrevFinYearStart AND @PrevPeriodEnd THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [prev_ytd]
		,SUM(CASE WHEN calendar_date BETWEEN @CurrFinYearStart AND @CurrPeriodEnd THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [curr_ytd]

	
	FROM [red_dw].[dbo].[fact_bill_activity] fact_bill_activity
	INNER JOIN red_dw.dbo.dim_client dim_client ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
	INNER JOIN red_dw.dbo.dim_date billed_date ON fact_bill_activity.dim_bill_date_key = billed_date.dim_date_key
	INNER JOIN #GeneratorStatus generator ON generator.client_code = fact_bill_activity.client_code 
    WHERE  billed_date.calendar_date BETWEEN @PrevFinYearMinus1Start AND @CurrPeriodEnd
	AND fact_bill_activity.client_code <> '00069873'
	AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
	GROUP BY 
  		COALESCE(generator.client_group_name,dim_client.client_name COLLATE DATABASE_DEFAULT)
		,dim_client.sector
		,dim_client.segment
		,[cboGenClientStatus]
		, generator.report_type
		,CASE WHEN dim_client.client_group_name IN ('BES Group','Bibby Group') THEN 'Star' ELSE 'Patron' END

	UNION
    
	SELECT 
			
		#cbo_clients.client_name AS client_group_name
		,dim_client.sector
		,dim_client.segment
		,#cbo_clients.generator_category
		,[cboGenClientStatus] [category_code]
		, #cbo_clients.report_type		AS report_type
		,SUM(CASE WHEN fin_year = @PrevFinancialYearMinus1 THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [fin_year_minus_2]
		,SUM(CASE WHEN fin_year = @PreviousFinancialYear THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [fin_year_minus_1]
		,SUM(CASE WHEN calendar_date BETWEEN @PrevFinYearStart AND @PrevPeriodEnd THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [prev_ytd]
		,SUM(CASE WHEN calendar_date BETWEEN @CurrFinYearStart AND @CurrPeriodEnd THEN [fact_bill_activity].[bill_amount] ELSE 0 END) [curr_ytd]

	
	FROM [red_dw].[dbo].[fact_bill_activity] fact_bill_activity
	INNER JOIN red_dw.dbo.dim_client dim_client ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
	INNER JOIN red_dw.dbo.dim_date billed_date ON fact_bill_activity.dim_bill_date_key = billed_date.dim_date_key
	INNER JOIN #cbo_clients ON #cbo_clients.client_code = fact_bill_activity.client_code 
    WHERE  billed_date.calendar_date BETWEEN @PrevFinYearMinus1Start AND @CurrPeriodEnd
	AND fact_bill_activity.client_code <> '00069873'
	AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
	GROUP BY 
  		#cbo_clients.client_name
		,dim_client.sector
		,dim_client.segment
		, #cbo_clients.generator_category
		, [cboGenClientStatus]
		, #cbo_clients.report_type
		

	ORDER BY category_code
	
	













GO
