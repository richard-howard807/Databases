SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GoAheadBilling]

AS 

BEGIN
SELECT bill_date AS [Bill Date]
,Depot
,ISNULL([Operating Company],'London General Transport Services LTD') AS [Operating Company]
,ISNULL(ConcludedPeriod.[Period Name],'Historic') AS [GAG Period]
,ISNULL(ConcludedPeriod.Quarter,'Historic') AS [GAG Quarter]
,ISNULL(ConcludedPeriod.[GAG Year],'Historic') AS [GAG Year]
,SUM(bill_total) AS [Bill Total]
,SUM(fees_total) AS [Fee Total]
,SUM(paid_disbursements)+SUM(unpaid_disbursements) AS Disbursements
,SUM(vat_amount) AS VAT
FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (SELECT * FROM GoAheadReporingPeriods WHERE Exclude='No') AS ConcludedPeriod
 ON CONVERT(DATE,bill_date,103) BETWEEN CONVERT(DATE,ConcludedPeriod.[From],103) AND CONVERT(DATE,ConcludedPeriod.[To],103)
LEFT OUTER JOIN Reporting.dbo.GoAheadDepots  ON GoAheadDepots.Ref=UPPER(LEFT(dim_client_involvement.[insuredclient_reference], 3)) COLLATE DATABASE_DEFAULT

WHERE client_group_code = '00000126'
AND ISNULL(outcome_of_case,'')<> 'Exclude from reports'
AND ISNULL(dim_client_involvement.[insuredclient_name],'') <> 'Avis Budget UK'
AND dim_matter_header_current.matter_number <>'ML'
AND (date_closed_case_management IS NULL OR ISNULL(date_claim_concluded,date_closed_case_management)>='2018-07-01')--incident_date>='2012-06-30'
AND master_client_code + '-' + master_matter_number <>'W15492-1455'
--AND RTRIM(dim_matter_header_current.client_code) +'/'+ RTRIM(dim_matter_header_current.[matter_number])='00065232/00001259'
AND hierarchylevel3hist <>'Regulatory'
AND bill_reversed=0
AND dim_bill.bill_number<>'PURGE'
GROUP BY  ISNULL(ConcludedPeriod.[Period Name], 'Historic'),
          ISNULL(ConcludedPeriod.Quarter, 'Historic'),
          ISNULL(ConcludedPeriod.[GAG Year], 'Historic'),
          bill_date,
          Depot,
          [Operating Company]

		 ORDER BY bill_date

END 
GO
