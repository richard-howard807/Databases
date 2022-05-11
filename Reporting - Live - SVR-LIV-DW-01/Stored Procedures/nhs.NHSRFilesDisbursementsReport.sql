SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [nhs].[NHSRFilesDisbursementsReport] 

--EXEC [nhs].[NHSRFilesDisbursementsReport] '2022-01-01', '2022-05-01', '125409T', '1232'

@StartDate AS DATE ,
@EndDate   AS DATE ,
@Client AS VARCHAR(10) ,
@Matter AS VARCHAR(10)

AS
/* Testing*/
--DECLARE
--@StartDate AS DATE = '2022-01-01', 
--@EndDate   AS DATE = '2022-05-01', 
--@Client AS VARCHAR(10) = '125409T',
--@Matter AS VARCHAR(10) = NULL --'1232'

SELECT DISTINCT 

clnt_matt_code =  dim_matter_header_current.master_client_code +'.'+master_matter_number ,      --NHS004.60
invoice_date	= dim_date.calendar_date,  --26 September 2018
vendor_name	   = coalesce(thirdparty_name, claimant_name, defendant_name),-- Judith Lowe
invoice_num	  = fact_bill.bill_number, --131568
base_amt	= fact_chargeable_time_activity.actual_time_recorded_value,  --£8.50
inv_amt	  =  fact_chargeable_time_activity.actual_time_recorded_value *1.2, --£10.20
cost_code	= time_activity_code , --BOOKSV
txt1 = dim_all_time_narrative.narrative
,dim_matter_header_current.client_name			
,claimantsols_reference
,dim_client_involvement.insurerclient_reference
,insuredclient_reference
,dim_matter_header_current.master_client_code
,master_matter_number
,WardHadawayFlag = CASE WHEN CRSystemSourceID LIKE 'NHS%' THEN 'Y' ELSE 'N' END 
FROM red_dw.dbo.fact_chargeable_time_activity
LEFT JOIN red_dw.dbo.fact_bill
ON fact_bill.dim_bill_key = fact_chargeable_time_activity.dim_bill_key
LEFT JOIN red_dw.dbo.dim_date
ON dim_transaction_date_key = dim_date_key
JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT JOIN red_dw.dbo.dim_defendant_involvement
ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
LEFT JOIN ms_prod.dbo.udExtFile
ON fileID = ms_fileid
LEFT JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_all_time_narrative
ON dim_all_time_narrative.dim_all_time_narrative_key = fact_chargeable_time_activity.dim_chargeable_time_narratives_key
--LEFT JOIN red_dw.dbo.dim_activity_time_type
--ON time_activity_code = activity_code


WHERE  1 = 1 
  AND (dim_matter_header_current.client_group_name = 'NHS Resolution'
		  OR fact_dimension_main.client_code IN ('00043006','00013994','00043006','00195691','00334312','00451649','00452904','00468733','00516358','00658192','00707938','00720451','00742694','00866428','09008761','125409T','51130A','TR00006','TR00010','TR00023','TR00024','W15380','W15414','W15508','W15524','W15602','W15605','W18173','W18543','W18697','W18762','W19835','W19836','W20891','W21443','W21617'))

AND dim_matter_header_current.[reporting_exclusions] = 0

AND fact_bill.bill_number <> 'PURGE'

AND actual_time_recorded_value >0

AND dim_date.calendar_date BETWEEN @StartDate AND @EndDate

--AND ISNULL(@Client, dim_matter_header_current.master_client_code) =  dim_matter_header_current.master_client_code  

--AND ISNULL(@Matter ,master_matter_number) =  master_matter_number 


ORDER BY 1 



GO
