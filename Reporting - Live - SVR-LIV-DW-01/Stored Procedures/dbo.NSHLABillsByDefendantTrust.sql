SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- LD 20190124 Rtrimmed defendant trust RTRIM([defendant_trust]) -- Ticket 8533

CREATE PROCEDURE [dbo].[NSHLABillsByDefendantTrust] --EXEC [dbo].[NSHLABillsByDefendantTrust] '2017-05-01','2018-04-04','Wrightington, Wigan & Leigh NHS Foundation Trust','Liverpool','Clinical Liverpool and Manchester'
(
@StartDate AS DATE
,@EndDate AS DATE
,@Trust AS NVARCHAR(MAX)
,@Branch AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
)
AS
BEGIN


SELECT ListValue  INTO #Trust FROM Reporting.dbo.[udt_TallySplit](',', @Trust)
SELECT ListValue  INTO #Branch FROM Reporting.dbo.[udt_TallySplit](',', @Branch)
SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit](',', @Team)


SELECT 
a.client_code AS Client
,a.matter_number AS Matter
,client_group_name AS [Client Group]
,a.matter_description AS [Matter Description]
,dim_instruction_type.instruction_type AS [Instruction Type]
,date_opened_case_management AS [Date Opened]
,a.matter_owner_full_name AS [Fee Earner]
,[nhs_scheme] AS [NHS Scheme]
,CASE WHEN RTRIM([defendant_trust]) IS NULL THEN 'Not Added' ELSE RTRIM([defendant_trust]) END  AS [Defendant Trust]
,fee_arrangement AS [Fee Arrangement]
,branch_name AS [Office]
,hierarchylevel4hist AS [Team]
--,fact_bill_matter_detail.bill_date AS  [Bill Date]
--,bill_number AS [Bill Number]
,SUM(bill_total) AS [Bill Total]
,SUM(fees_total) AS [Fee Total]
,SUM(hard_costs) + SUM(soft_costs) AS [Disbursements]
,SUM(vat) AS [VAT]
,CAST(dim_bill_date.bill_fin_year-1 AS NVARCHAR(4)) + '/' + CAST(RIGHT(dim_bill_date.bill_fin_year,2) AS NVARCHAR(2)) AS [Financial Year]


FROM red_dw.dbo.dim_matter_header_current AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.fact_dimension_main  AS b WITH (NOLOCK)
 ON a.dim_matter_header_curr_key=b.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.fact_bill_matter_detail  WITH (NOLOCK)  
 ON a.client_code=fact_bill_matter_detail.client_code AND a.matter_number=fact_bill_matter_detail.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_instruction_type WITH (NOLOCK) 
 ON a.dim_instruction_type_key=dim_instruction_type.dim_instruction_type_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health WITH (NOLOCK) 
 ON b.dim_detail_health_key=dim_detail_health.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim WITH (NOLOCK)
 ON b.dim_detail_claim_key=dim_detail_claim.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH (NOLOCK)
 ON b.dim_detail_outcome_key=dim_detail_outcome.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_date WITH (NOLOCK)
 ON fact_bill_matter_detail.dim_bill_date_key = dim_bill_date.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH (NOLOCK)
 ON a.fee_earner_code=dim_fed_hierarchy_history.fed_code AND dim_fed_hierarchy_history.dss_current_flag='Y' 

INNER JOIN #Trust AS Trust ON Trust.ListValue COLLATE database_default = (CASE WHEN [defendant_trust] IS NULL THEN 'Not Added' ELSE REPLACE([defendant_trust],',','') END) COLLATE database_default
INNER JOIN #Branch AS Branch ON Branch.ListValue COLLATE database_default = (CASE WHEN branch_name IS NULL THEN 'Not Added' ELSE branch_name END) COLLATE database_default
INNER JOIN #Team AS Team ON Team.ListValue COLLATE database_default = (CASE WHEN hierarchylevel4hist IS NULL THEN 'Unknown' ELSE hierarchylevel4hist END) COLLATE database_default


WHERE fact_bill_matter_detail.bill_date BETWEEN @StartDate AND @EndDate
AND client_group_name='NHS Resolution'
AND ISNUMERIC(a.matter_number)=1
--AND a.client_code='N1001' AND a.matter_number='00015496'

GROUP BY a.client_code 
,a.matter_number 
,client_group_name 
,a.matter_description
,dim_instruction_type.instruction_type 
,date_opened_case_management 
,a.matter_owner_full_name 
,[nhs_scheme] 
,[defendant_trust] 
,fee_arrangement
,branch_name
,hierarchylevel4hist 
,(CAST(dim_bill_date.bill_fin_year-1 AS NVARCHAR(4)) + '/' + CAST(RIGHT(dim_bill_date.bill_fin_year,2) AS NVARCHAR(2)))

ORDER BY a.client_code
,a.matter_number ,(CAST(dim_bill_date.bill_fin_year-1 AS NVARCHAR(4)) + '/' + CAST(RIGHT(dim_bill_date.bill_fin_year,2) AS NVARCHAR(2)))
END
GO
