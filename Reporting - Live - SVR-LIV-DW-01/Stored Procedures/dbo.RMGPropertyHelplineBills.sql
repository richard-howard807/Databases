SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[RMGPropertyHelplineBills]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS 

BEGIN 

SELECT
master_client_code + '-' +master_matter_number AS [MatterSphere Client/Matter Number]
,matter_description AS [Matter Description]
,matter_owner_full_name AS [Matter Owner]
,date_opened_case_management AS [Date Opened]
,[client_case_reference] AS [Client Case Reference]
,bill_date AS [Bill Date]
,fact_bill_matter_detail.bill_number AS [Bill Number]
,bill_total AS [Total Billed]
,fees_total AS [Revenue]
,ISNULL(fact_bill_matter_detail.hard_costs,0) + ISNULL(fact_bill_matter_detail.soft_costs,0) AS [Disbursements]
,fact_bill_matter_detail.vat AS [VAT]
,bill_on_account AS [Bill On Account]

FROM red_dw.dbo.dim_detail_property
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = dim_detail_property.client_code
 AND dim_matter_header_current.matter_number = dim_detail_property.matter_number
INNER JOIN red_dw.dbo.fact_bill_matter_detail
 ON fact_bill_matter_detail.client_code =dim_detail_property.client_code
 AND fact_bill_matter_detail.matter_number=dim_detail_property.matter_number
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_matter_detail.dim_bill_key
WHERE [client_case_reference]='2015-00092'
--AND reversed=0
AND CONVERT(DATE,bill_date,103) BETWEEN @StartDate AND @EndDate


END


GO
