SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 20/11/2017
-- Description:	Client Generator Report 
--				Previously a manual report put together by marketing Webby 268619
-- =============================================
CREATE PROCEDURE [marketing].[generator_programme_report_detailBK20180418]
(
	@CurrentFinancialYear INT
	,@finMonth INT
)
AS

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    --=== For testing purposes=============
	--DECLARE @CurrentFinancialYear INT = 2018
	--DECLARE @finMonth INT = 7
	--======================================

	
	-- Generator status column not available in the warehouse at the moment
	-- using the below to extract from replicated version of MS_PROD
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#GeneratorStatus')) 
					DROP TABLE #GeneratorStatus

	SELECT  ISNULL(dbClient.clNo,udExtClient.FEDCode) clNo
				,[cboGenClientStatus]
				,udExtClient.cboPartner
				,dbUser.usrFullName
				,udExtClient.FEDCode
				,udClientGroup.[description] [client_group_name]
				,dbClient.clName [client_name]

	
	INTO #GeneratorStatus
	FROM [MS_Prod].[dbo].[udExtClient] udExtClient
	INNER JOIN MS_Prod.config.dbClient dbClient ON dbClient.clID = udExtClient.clID
	LEFT JOIN MS_Prod.dbo.dbUser dbUser ON dbUser.usrID = udExtClient.cboPartner
	LEFT JOIN MS_Prod.dbo.udClientGroup udClientGroup ON udClientGroup.code = udExtClient.cboClientGroup

	WHERE cboGenClientStatus IS NOT NULL -- only those clients that have a status
	--AND udExtClient.active = 1



	DECLARE @PreviousFinancialYear INT 
	DECLARE @PrevFinancialYearMinus1 INT

	SET @PreviousFinancialYear = @CurrentFinancialYear - 1
	SET @PrevFinancialYearMinus1 = @CurrentFinancialYear - 2
	DECLARE @Delimiter VARCHAR(10) = ';'

	

	SELECT 
			


		COALESCE(generator.client_group_name,generator.client_name COLLATE DATABASE_DEFAULT) client_group_name
		,matter.master_client_code
		,dim_client.client_name
		,dim_client.client_code
		,generator.usrFullName [client_partner_name]


		,REPLACE(dim_client.segment,CHAR(9),'') segment
		,REPLACE(dim_client.sector,CHAR(9),'') sector
		
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
	INNER JOIN red_dw.dbo.dim_matter_header_current matter ON matter.dim_matter_header_curr_key = fact_bill_activity.dim_matter_header_curr_key

	INNER JOIN #GeneratorStatus generator ON matter.master_client_code = generator.clNo COLLATE DATABASE_DEFAULT

    WHERE  billed_date.fin_year BETWEEN @PrevFinancialYearMinus1 AND @CurrentFinancialYear
	AND matter.master_matter_number <>'ML'
	AND generator.cboGenClientStatus <> '0004' -- exclude client
	AND matter.reporting_exclusions <>1
	AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
	--AND ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
	--AND COALESCE(dim_client.client_group_name,dim_client.client_name)  = 'Ageas'
	GROUP BY 
  		COALESCE(generator.client_group_name,generator.client_name COLLATE DATABASE_DEFAULT)
		,matter.master_client_code
		,dim_client.client_name
		,dim_client.client_code
		
		,generator.usrFullName 
		,dim_client.segment
		,dim_client.sector
		,[cboGenClientStatus]
	
	








GO
