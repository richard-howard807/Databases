SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-02-12
-- Description:	#87929, new report for Costcutter Invoices
-- =============================================
CREATE PROCEDURE [CommercialRecoveries].[CostCutterInvoices]
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT DISTINCT 
	'Weightmans' AS [Firm]
	, dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Weightmans Ref]
	, matter_owner_full_name AS [Partner / Fee Earner]
	, matter_description AS [Matter Description]
	, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Live' ELSE 'Closed' END AS [Status]
	, work_type_name AS [Category of Work]
	, CASE WHEN dim_matter_header_current.fee_arrangement='Fixed Fee/Fee Quote/Capped Fee' THEN 'Yes' ELSE 'No' END AS [Fixed Fee]
	, MatterRate.description AS [Rate]
	, narrative AS [Description of Work]
	, timekeeper.name AS [Time Recorder]
	, SUM(bill_hours) AS [Hours]
	, SUM(CASE WHEN fact_bill_detail.charge_type='time' THEN bill_total_excl_vat END)  AS [Fees (ex VAT)]
	, SUM(CASE WHEN fact_bill_detail.charge_type='disbursements' THEN bill_total_excl_vat END) AS [Disbursements (ex VAT)]
	, bill_date.calendar_date AS [Date of Invoice]
	, work_date.calendar_date AS [Date of Work]
	, fact_bill_detail.bill_number AS [Bill Number]
	, DENSE_RANK() OVER ( PARTITION BY dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number ORDER BY fact_bill_detail.bill_number asc) AS [Rank]
	, dim_matter_header_current.matter_number
	
FROM red_dw.dbo.fact_bill_detail
LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
ON fact_bill_detail.master_fact_key=fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_date bill_date
ON bill_date.dim_date_key=fact_bill_detail.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_date work_date
ON work_date.dim_date_key=fact_bill_detail.dim_transaction_date_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_narrative
ON dim_bill_narrative.dim_bill_narrative_key=fact_bill_detail.dim_bill_narrative_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS timekeeper
ON timekeeper.fed_code=fact_bill_detail.timekeeper
AND timekeeper.dss_current_flag='Y'
AND timekeeper.activeud=1

LEFT OUTER JOIN (  SELECT   master_client_code,master_matter_number ,client_code,matter_number,ds_sh_3e_mattdate.matterlkup,
    ds_sh_3e_arrangement.description,nxstartdate,nxenddate,effstart
	,fee_arrangement
	,fileRatePerUnit
  from red_dw.dbo.ds_sh_3e_mattdate
  INNER JOIN MS_Prod.config.dbFile
   ON fileExtLinkID=matterlkup
  INNER JOIN red_dw.dbo.dim_matter_header_current
   ON fileID=ms_fileid
  INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
   ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y' 
  LEFT OUTER JOIN red_dw.dbo.ds_sh_3e_arrangement
  ON ds_sh_3e_mattdate.arrangement = ds_sh_3e_arrangement.code
  WHERE dim_matter_header_current.master_client_code='W22511') AS [MatterRate]
ON MatterRate.master_client_code = dim_matter_header_current.master_client_code
AND MatterRate.master_matter_number = dim_matter_header_current.master_matter_number

WHERE fact_bill_detail.client_code='W22511'
AND reporting_exclusions=0
--AND fact_bill_detail.matter_number='00000069'

GROUP BY dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number
	, matter_owner_full_name
	, matter_description 
	, CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL THEN 'Live' ELSE 'Closed' END 
	, work_type_name
	, dim_matter_header_current.fee_arrangement 
	, MatterRate.description
	, timekeeper.name 
	, bill_rate 
	, narrative
	, bill_date.calendar_date 
	, work_date.calendar_date
	, fact_bill_detail.bill_number
	, dim_matter_header_current.matter_number


ORDER BY dim_matter_header_current.matter_number
, fact_bill_detail.bill_number

    
END
GO
