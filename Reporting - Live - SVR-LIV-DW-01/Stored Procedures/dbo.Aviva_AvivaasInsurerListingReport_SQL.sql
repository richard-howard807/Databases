SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE  [dbo].[Aviva_AvivaasInsurerListingReport_SQL]

AS
DROP TABLE IF EXISTS #Revenue

		SELECT PVIOT.client_code,
			   PVIOT.matter_number,
			  
			   PVIOT.[2021]
			--W20163-87 --1236483
			   INTO #Revenue
		FROM (

			SELECT  fact_bill_activity.client_code, fact_bill_activity.matter_number,  bill_cal_year, SUM(fact_bill_activity.bill_amount) Revenue
			FROM red_dw.dbo.fact_bill_activity WITH(NOLOCK)
			INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
			ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
			WHERE dim_bill_date.bill_cal_year IN (2021)
			GROUP BY fact_bill_activity.client_code, fact_bill_activity.matter_number, bill_cal_year
			) AS revenue
		PIVOT	
			(
			SUM(Revenue)
			FOR bill_cal_year IN ([2021])
			) AS PVIOT



--DROP TABLE IF EXISTS #VatBilled

--		SELECT PVIOT.client_code,
--			   PVIOT.matter_number,
			  
--			   PVIOT.[2021]
			
--			   INTO #VatBilled
--		FROM (

--			SELECT fact_bill_activity.client_code, fact_bill_activity.matter_number,  bill_cal_year, SUM(fact_bill_activity.vat_amount) VatAmount --, SUM(fact_bill_activity.bill_amount_vat) BillAmountVAT
--			FROM red_dw.dbo.fact_bill_activity WITH(NOLOCK)
--			INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
--			ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
--			WHERE dim_bill_date.bill_cal_year IN (2021)
		
--			GROUP BY fact_bill_activity.client_code, fact_bill_activity.matter_number, bill_cal_year
--			) AS vatamount
--		PIVOT	
--			(
--			SUM(VatAmount)
--			FOR bill_cal_year IN ([2021])
--			) AS PVIOT


DROP TABLE IF EXISTS #VatBilledAmount

		SELECT PVIOT.client_code,
			   PVIOT.matter_number,
			  
			   PVIOT.[2021]
			
			   INTO #VatBilledAmount
		FROM (

			SELECT fact_bill_activity.client_code, fact_bill_activity.matter_number,  bill_cal_year, SUM(fact_bill_activity.bill_amount_vat) BillAmountVAT
			FROM red_dw.dbo.fact_bill_activity WITH(NOLOCK)
			INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
			ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
			WHERE dim_bill_date.bill_cal_year IN (2021)
		
			GROUP BY fact_bill_activity.client_code, fact_bill_activity.matter_number, bill_cal_year
			) AS vatamount
		PIVOT	
			(
			SUM(BillAmountVAT)
			FOR bill_cal_year IN ([2021])
			) AS PVIOT




DROP TABLE IF EXISTS #Disbursements
		SELECT PVIOT.client_code,
			   PVIOT.matter_number,
			   PVIOT.[2021]
			   INTO #Disbursements
		FROM (

						SELECT client_code, matter_number, bill_cal_year, SUM(fact_bill_detail.bill_total_excl_vat) Disbursements
			FROM red_dw.dbo.fact_bill_detail WITH(NOLOCK)
			INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK) ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
			WHERE dim_bill_date.bill_fin_year IN (2021)
			AND charge_type='disbursements'
	GROUP BY client_code,
             matter_number,
            bill_cal_year
			) AS disbursements
		PIVOT	
			(
			SUM(Disbursements)
			FOR bill_cal_year IN ([2021])
			) AS PVIOT



	SELECT DISTINCT  [Lookup] = TRIM(dim_matter_header_current.client_code) + '-' + TRIM(dim_matter_header_current.matter_number) 
	,#Revenue.[2021] AS Revenue_2021
	,#Disbursements.[2021] AS Disbursements_2021
	,#VatBilledAmount.[2021] AS VatBilled_2021
	
	
	FROM red_dw.dbo.dim_matter_header_current
	LEFT JOIN #Revenue ON #Revenue.client_code = dim_matter_header_current.client_code AND #Revenue.matter_number = dim_matter_header_current.matter_number
	LEFT JOIN #Disbursements ON #Disbursements.client_code = dim_matter_header_current.client_code AND #Disbursements.matter_number = dim_matter_header_current.matter_number
	LEFT JOIN #VatBilledAmount ON #VatBilledAmount.client_code = dim_matter_header_current.client_code AND #VatBilledAmount.matter_number = dim_matter_header_current.matter_number
	WHERE #Revenue.[2021] IS NOT NULL 
	OR #Disbursements.[2021] IS NOT NULL OR #VatBilledAmount.[2021] IS NOT NULL 
GO
