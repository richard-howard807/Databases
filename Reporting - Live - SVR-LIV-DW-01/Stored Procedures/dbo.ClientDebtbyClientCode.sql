SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Max Taylor
Created Date:		2021-03-30
Description:		This is to drive Client Debt by Client Code
Current Version:	Initial Create
====================================================

====================================================

*/
	CREATE PROCEDURE [dbo].[ClientDebtbyClientCode]	
 
	( 
	@ClientCode AS VARCHAR(max) ,
	@ClientGroup VARCHAR (max), 
	@FeeEarner VARCHAR(max)
	)

	AS
	BEGIN

	
--TESTING
--DECLARE @ClientCode AS NVARCHAR(20) = '', 
--@ClientGroup AS NVARCHAR(20) = '', 
--@FeeEarner AS NVARCHAR(20) = ''
--01711241



	SELECT 
							dim_client.client_group_name                 AS [ClientGroupName],
							dim_client.client_code                       AS [ClientCode],
							dim_client.client_name                       AS [ClientName],
							dim_matter_header_current.matter_number      AS [MatterNumber],
							matter_description                           AS [MatterDesc],
							fed_code                                     AS [MatterFEDCode],
							display_name                                 AS [MatterFEDDisplayName],
							bill_date                                    AS [BillDateDate],
							fact_debt.bill_number                        AS [BillNumber],
							SUM(outstanding_total_bill)                  AS [AmountOutstanding],
							Factbill.[FeeValue]							 AS [FeeValue],
							Factbill.[DisbursementsPaid]                 AS [DisbursementsPaid],
							SUM(fact_debt.outstanding_vat)               AS [VATAmount],
							AVG(fact_debt.age_of_debt)                   AS [BillAgeDays],
							SUM(fact_debt.outstanding_disb)              AS [DisbursementsUnpaid]
							
							

				FROM red_dw.dbo.fact_debt 
				JOIN red_dw.dbo.dim_matter_header_current 
					ON dim_matter_header_current.dim_matter_header_curr_key = fact_debt.dim_matter_header_curr_key
				JOIN red_dw.dbo.fact_dimension_main 
					ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
				JOIN red_dw.dbo.dim_client 
					ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
				JOIN red_dw.dbo.dim_fed_hierarchy_history	
					ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
				
				
				LEFT JOIN (SELECT 	DISTINCT	
							bill_number,
							SUM(fact_bill.fees_total)  OVER (PARTITION BY bill_number)                  AS [FeeValue],
							SUM(fact_bill.paid_disbursements) OVER (PARTITION BY bill_number)             AS [DisbursementsPaid]
							FROM red_dw.dbo.fact_bill ) Factbill
					ON Factbill.bill_number = fact_debt.bill_number

			
			WHERE  1=1
			AND dim_client.client_code  = CASE WHEN @ClientCode = '' THEN dim_client.client_code ELSE  ISNULL(@ClientCode, dim_client.client_code) END
			AND ISNULL(dim_client.client_group_name,'')  = CASE WHEN ISNULL(@ClientGroup,'') = '' THEN ISNULL(dim_client.client_group_name,'') ELSE ISNULL(@ClientGroup, ISNULL(dim_client.client_group_name,'') ) END 
			AND fed_code  = CASE WHEN @FeeEarner = '' THEN fed_code ELSE ISNULL(@FeeEarner, fed_code) END
			AND outstanding_total_bill <> 0

				GROUP BY 

				dim_client.client_group_name            
				,dim_client.client_code                  
				,dim_client.client_name                  
				,dim_matter_header_current.matter_number 
				,matter_description                      
				,fed_code                                
				,display_name                            
				,bill_date                               
				,fact_debt.bill_number        
				,Factbill.[FeeValue]						
				,Factbill.[DisbursementsPaid]               

				ORDER BY bill_date 
	
END 

GO
