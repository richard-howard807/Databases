SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-05-27
Description:		Bills Data to drive the Omniscope Dashboards - this is at bills level not matter level
Current Version:	Initial Create
====================================================
====================================================
*/
 
CREATE PROCEDURE [Omni].[BillsDataFile]
AS

BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT DISTINCT 
				 RTRIM(fact_bill.client_code)+'/'+fact_bill.matter_number AS [Weightmans Reference]
				,fact_bill.client_code AS [Client Code]
				,fact_bill.matter_number AS [Matter Number]
				,dim_matter_header_current.master_client_code AS [Mattersphere Client Code]
				, dim_matter_header_current.master_matter_number AS [Mattersphere Matter Number]
				,dim_matter_header_current.[matter_description] AS [Matter Description]
				,dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
				,dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
				,fact_bill.bill_number AS [Bill Number]
				,fact_bill.bill_total AS [Bill Total]
				,fact_bill.fees_total AS [Profit Costs]
				,fact_bill.amount_paid AS [Bill Amount Paid]
				,ISNULL(fact_bill.bill_total,0) - ISNULL(fact_bill.amount_paid,0) AS [Left to Pay]
				,dim_bill_date.bill_date AS [Bill Date] --this has two different bill dates 
				,isnull(fact_bill_activity.bill_record_type,'') AS [Bill Type]
				,dim_bill_date.bill_cal_month_no AS [Month Billed]
				,dim_bill_date.bill_cal_month_name AS [Month Name Billed]
				,dim_bill_date.bill_cal_year [Year Billed]
				,CASE WHEN DATEPART(MONTH,dim_bill_date.bill_date)<=3 THEN 'Qtr 1'
					WHEN DATEPART(MONTH,dim_bill_date.bill_date)<=6 THEN 'Qtr 2'
					WHEN DATEPART(MONTH,dim_bill_date.bill_date)<=9 THEN 'Qtr 3'
					WHEN DATEPART(MONTH,dim_bill_date.bill_date)<=12 THEN 'Qtr 4'
				 END AS [Quarter Billed]
				,NULL [Abatement Total]
				,'Bill Level' [Level]
			
				


	FROM
	red_dw.dbo.fact_bill AS fact_bill 
	LEFT OUTER JOIN red_dw.dbo.dim_bill_date ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
	LEFT OUTER JOIN red_dw.dbo.[fact_bill_activity] ON fact_bill_activity.dim_bill_key=fact_bill.dim_bill_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.client_code=fact_bill.client_code AND dim_matter_header_current.matter_number=fact_bill.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_dimension_main ON fact_dimension_main.master_fact_key = fact_bill.master_fact_key
	
	


	WHERE 


	((fact_bill.client_code  = '90735C'and fact_bill.matter_number >= '00004570')
	OR (fact_bill.client_code  = '89471N'and fact_bill.matter_number >= '00000125')
	OR (fact_bill.client_code  = '00568762'and fact_bill.matter_number >= '00000106'))
	OR fact_bill.client_code in ('00004049','00247523','00439011','00677936','00599202','00646829','00464007','00649697','00451638','00113147')
	OR fact_bill.client_code in ('W00011','W00012','W15630')
	OR dim_matter_header_current.master_client_code in ('W15502','W15699','W17789')
	--OR (dim_matter_header_current.master_client_code='M1001' AND dim_bill_date.bill_date>='2017-07-01')
	AND dim_bill_date.bill_date >'20141231' -- this is for one client 
	AND dim_matter_header_current.reporting_exclusions=0
	AND (dim_matter_header_current.date_closed_case_management >='20120101' OR dim_matter_header_current.date_closed_case_management IS NULL) -- as per AMM



	ORDER BY  fact_bill.matter_number


END

GO
