SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MarkelBillings] -- EXEC [dbo].[MarkelBillings] '2018-09-11','2018-12-10',''
(
@StartDate AS DATE
,@EndDate AS DATE
,@Client AS NVARCHAR(MAX)
)
AS
BEGIN

SELECT ListValue  INTO #Client FROM Reporting.dbo.[udt_TallySplit](',', @Client)


SELECT dim_matter_header_current.client_name AS [Client Name]
,'Weightmans LLP' AS [Panel Solicitor Firm]
,RTRIM(dim_matter_header_current.master_client_code) + '.' + RTRIM(dim_matter_header_current.master_matter_number) AS [Weightmans Ref]
,name AS [Matter owner]
,claimant_name AS [Claimant]
,insurerclient_reference AS [Markel reference]
,NULL AS [Period]
,InvNumber
,SUM(Revenue) AS [Total Fees Billed in Period]
,SUM(HardCosts) + SUM(SoftCosts) AS [Total Disbursements Billed]
,SUM([MarkelTax]) AS [Total VAT Billed to Markel In Period]
,SUM([NonMarkelTax]) AS [Total VAT Not Billed to Markel In Period]
,SUM(AllData.[Bill Total])  AS [Total Billed In Period]
--,orlaghbill
,SUM([Bill Total]) - SUM([NonMarkelTax]) AS [Total Billed In Period Incluisve of Disbursements VAT payable by Markel only]
,ISNULL(CounselExpert,0) AS [Total Counsel Fees Billed In Period]
FROM
(SELECT 
coalesce(left(Matter.loadnumber,(charindex('-',Matter.loadnumber)-1)),Client.altnumber,CASE WHEN ISNUMERIC(Client.number) = 1 THEN RIGHT(CAST(CAST(Client.number AS int)  + 100000000 AS varchar(9)),8) ELSE Client.number END)  AS client_code
,isnull(right(Matter.loadnumber, len(Matter.loadnumber) - charindex('-',Matter.loadnumber))
,right(Matter.altnumber, len(Matter.altnumber) - charindex('-',Matter.altnumber)))  AS matter_number
,ARDetail.InvDate
,InvNumber
,IsReverse
,IsReversed
,ARDetail.ARFee AS Revenue
,ARDetail.ARHCo AS HardCosts
,ARDetail.ARSCo AS SoftCosts
,CASE WHEN Payor.DisplayName LIKE '%Markel%' THEN  ARDetail.ARTAx ELSE 0 END AS [MarkelTax]
,CASE WHEN Payor.DisplayName NOT LIKE '%Markel%' THEN  ARDetail.ARTAx ELSE 0 END AS [NonMarkelTax]
,ARDetail.AROth AS [OtherCosts]
,ARDetail.ARAmt AS [Bill Total]

,Payor.DisplayName AS [Payor]
FROM TE_3E_Prod.dbo.ARDetail WITH (NOLOCK)
INNER JOIN TE_3E_Prod.dbo.InvMaster
 ON ARDetail.InvMaster=InvMaster.InvIndex
INNER JOIN TE_3E_Prod.dbo.Matter WITH (NOLOCK) 
 ON ARDetail.Matter=Matter.MattIndex
INNER JOIN TE_3E_Prod.dbo.Client
 ON Matter.Client=Client.ClientIndex
LEFT OUTER JOIN TE_3E_Prod.dbo.Payor ON ARDetail.Payor=Payor.PayorIndex
WHERE ARDetail.InvDate BETWEEN  @StartDate AND @EndDate
AND ARList IN ('Bill','BillRev')
) AS AllData


-------------------
INNER JOIN #Client AS Client ON Client.ListValue COLLATE database_default = AllData.client_code COLLATE database_default

INNER JOIN red_dw.dbo.dim_matter_header_current
 ON AllData.client_code=dim_matter_header_current.client_code collate database_default
 AND AllData.matter_number=dim_matter_header_current.matter_number  collate database_default 

LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code collate database_default AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement WITH(NOLOCK)  
 ON dim_matter_header_current.client_code=dim_claimant_thirdparty_involvement.client_code 
 AND dim_matter_header_current.matter_number=dim_claimant_thirdparty_involvement.matter_number

LEFT OUTER JOIN red_dw.dbo.dim_client_involvement WITH(NOLOCK)  
 ON dim_matter_header_current.client_code=dim_client_involvement.client_code 
 AND dim_matter_header_current.matter_number=dim_client_involvement.matter_number 
LEFT OUTER JOIN
(
SELECT fact_bill_detail.client_code_bill_item
,fact_bill_detail.matter_number_bill_item
,fact_bill_detail.bill_number
,SUM(bill_total_excl_vat) AS CounselExpert 
FROM red_dw.dbo.fact_bill_detail WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON fact_bill_detail.client_code_bill_item=dim_matter_header_current.client_code
 AND fact_bill_detail.matter_number_bill_item=dim_matter_header_current.matter_number
 AND client_group_name='Markel'
INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK) 
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_bill_cost_type WITH(NOLOCK) 
  ON fact_bill_detail.dim_bill_cost_type_key=dim_bill_cost_type.dim_bill_cost_type_key
WHERE charge_type='disbursements' 
AND cost_type_description IN ('Counsel','Counsel Fees','COUNSEL','COUNSEL FEES')
GROUP BY fact_bill_detail.client_code_bill_item
,fact_bill_detail.matter_number_bill_item
,fact_bill_detail.bill_number
) AS CounselExpert
 ON dim_matter_header_current.client_code=CounselExpert.client_code_bill_item
 AND dim_matter_header_current.matter_number=CounselExpert.matter_number_bill_item
 AND InvNumber=bill_number collate database_default
WHERE client_group_name='Markel' 
AND InvNumber <>'PURGE'



GROUP BY dim_matter_header_current.client_name 
,RTRIM(dim_matter_header_current.master_client_code) + '.' + RTRIM(dim_matter_header_current.master_matter_number) 
,name 
,claimant_name 
,insurerclient_reference 
,InvNumber
,CounselExpert

ORDER BY RTRIM(dim_matter_header_current.master_client_code) + '.' + RTRIM(dim_matter_header_current.master_matter_number) 
END
GO
