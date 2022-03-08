SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Ageas_AgeasAutomatedPaymentReport]

AS 
DROP TABLE IF EXISTS #t1 
SELECT 

[Ageas Claim Reference] = dim_client_involvement.[insurerclient_reference]
,[Policyholder Name] = COALESCE(insuredclient_name, dim_defendant_involvement.[defendant_name])
,[Invoice Number] = bill_number
,[Invoice Amount] = SUM(bill_total) 
,[Invoice Date] =  MAX(CAST(bill_date AS DATE))
,dim_matter_header_current.master_client_code
,Division = hierarchylevel2hist
,Department = hierarchylevel3hist
,Team = hierarchylevel4hist
,[ClientMatter] = dim_matter_header_current.master_client_code +'/' +master_matter_number

INTO #t1
FROM  red_dw.dbo.fact_bill_detail
LEFT JOIN red_dw.dbo.dim_matter_header_current 
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_detail.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_date 
ON dim_bill_date.dim_bill_date_key = fact_bill_detail.dim_bill_date_key
LEFT JOIN red_dw.dbo.dim_defendant_involvement
ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
WHERE 1 = 1

AND dim_matter_header_current.master_client_code = 'A3003'
AND reporting_exclusions = 0
AND hierarchylevel3hist = 'Motor'

/*Testing*/
--AND bill_number = '02073545'

GROUP BY 
bill_number
,dim_client_involvement.[insurerclient_reference]
,COALESCE(insuredclient_name, dim_defendant_involvement.[defendant_name])
--, bill_date
,dim_matter_header_current.client_name
,dim_matter_header_current.master_client_code
,hierarchylevel2hist
,hierarchylevel3hist
,hierarchylevel4hist
,dim_matter_header_current.master_client_code +'/' +master_matter_number


SELECT * FROM #t1
WHERE [Invoice Date] >GETDATE() -60
ORDER BY [Invoice Date] DESC

GO
