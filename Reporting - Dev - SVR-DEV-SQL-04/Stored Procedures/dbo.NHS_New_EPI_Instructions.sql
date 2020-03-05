SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2017-11-28
Description:		Additional data needed for NHS New EPI Instructions
Current Version:	Initial Create
====================================================
====================================================

*/


CREATE Procedure [dbo].[NHS_New_EPI_Instructions]   --'20171201'
( 


@date as date


)
AS
BEGIN

  
SELECT 

 rtrim(dim_matter_header_current.client_name) client_name  
,dim_matter_header_current.client_code
,dim_matter_header_current.matter_number
,date_opened_case_management
,open_case_management_financial_date
,CASE WHEN (DATEPART(MONTH, date_opened_case_management) = DATEPART(MONTH, DATEADD(mm,-1,@date)) AND DATEPART(YEAR, date_opened_case_management) = DATEPART(YEAR, DATEADD(mm,-1,@date))) THEN 1 ELSE 0 END [Previous Month]
,CASE WHEN (DATEPART(MONTH, open_case_management_financial_date) = DATEPART(MONTH, GETDATE())-1 AND DATEPART(YEAR, open_case_management_financial_date) = DATEPART(YEAR, GETDATE())-1) THEN 1 ELSE 0 END [Previous Month Prior Year]
,CASE WHEN  dim_open_case_management_date.open_case_management_fin_year = DATEPART(YEAR, GETDATE())-1 THEN 1 ELSE 0 END [Previous FY]
,CASE WHEN  dim_open_case_management_date.open_case_management_fin_year = DATEPART(YEAR, @date) THEN 1 ELSE 0 END [Current FY]
,CASE WHEN date_opened_case_management  between 
	(SELECT calendar_date AS prev_year_start FROM red_dw..dim_date 
	 WHERE fin_year = 
	(SELECT fin_year FROM red_dw..dim_date 
	 WHERE calendar_date = DATEADD(YEAR,-1,CAST(@date AS DATE) )) AND fin_day_in_year = 1 )  
	 AND
	(SELECT DATEADD(YEAR,-1,CAST(@date AS DATE) ) FROM red_dw..dim_date 
	 WHERE fin_year = 
	(SELECT fin_year FROM red_dw..dim_date
	 WHERE calendar_date = DATEADD(YEAR,-1,CAST(@date AS DATE) ))AND fin_day_in_year = 1 ) then 1 else 0 
    END AS [Weightmans PFY]

,CASE WHEN date_opened_case_management  between 
	(SELECT calendar_date AS current_year_start FROM red_dw..dim_date 
	 WHERE fin_year = 
	(SELECT fin_year FROM red_dw..dim_date
	 WHERE calendar_date = CAST(GETDATE() AS DATE)  ) AND fin_day_in_year = 1 )  
     AND 
	(SELECT DATEADD(MONTH,0,CAST(@date AS DATE) ) FROM red_dw..dim_date 
	 WHERE fin_year = 
	(SELECT fin_year FROM red_dw..dim_date 
	 WHERE calendar_date = DATEADD(MONTH,0,CAST(@date AS DATE) )) AND fin_day_in_year = 1 ) then 1 else 0 
     END AS [Weightmans CFY]
,dim_fed_hierarchy_history.[hierarchylevel3hist]
,dim_client.sector

FROM red_dw..dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_open_case_management_date  ON dim_open_case_management_date.calendar_date = cast(cast(dim_matter_header_current.date_opened_case_management as date) as datetime)
LEFT OUTER JOIN red_dw.dbo.fact_dimension_main ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw..dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND getdate() BETWEEN dss_start_date AND dss_end_date 

WHERE 

dim_matter_header_current.matter_number <> 'ML' 
AND 
(dim_matter_header_current.client_code in( '00040162', 
 '00134914', 
 '00252448', 
 '00561917', 
 '00658192', 
 '00658281', 
 '09010863', 
 '153801L', 
 '163086U', 
 '180187B', 
 '39885W', 
 '51130A', 
 'FW28813', 
 'N00002', 
 'TR00016', 
 'W15380', 
 'W15484', 
 'W16499', 
 'W18543', 
 '00009792', 
 '00013992', 
 '00054170', 
 '00117043', 
 '00143103', 
 '00200056', 
 '00389712', 
 '00451649', 
 '00452835', 
 '00602442', 
 '00713559', 
 '00720451', 
 '00760818', 
 '00875767', 
 '09008000', 
 '09011060', 
 '123447R', 
 '180529E', 
 '189405T', 
 'FW12897', 
 'FW29941', 
 'N00001', 
 'N00009', 
 'TR00020', 
 'TR00021', 
 'W16456', 
 'W16458', 
 'W18173', 
 '00041095', 
 '00047873', 
 '00054752', 
 '00121247', 
 '00157450', 
 '00239838', 
 '00339414', 
 '00554424', 
 '00655594', 
 '00707938', 
 '00747894', 
 '125409T', 
 '149966C', 
 '37213W', 
 '64631T', 
 '76676C', 
 '79266M', 
 '89377S', 
 'FW18877', 
 'FW34607', 
 'HRR00177', 
 'N00005', 
 'TR00010', 
 'W15416', 
 'W15508', 
 'W15974', 
 'W16943', 
 '00096875', 
 '00331771', 
 '00382442', 
 '00639641', 
 '00657459', 
 '00671103', 
 '00672863', 
 '00816632', 
 '09008502', 
 '09008761', 
 '133001X', 
 '174092C', 
 '175841N', 
 '177672A', 
 '188336E', 
 '33336L', 
 '66882S', 
 '97034B', 
 'FW32842', 
 'FW642', 
 'W15526', 
 'W15602', 
 'W15605', 
 'W15946', 
 'W16497', 
 'W16698', 
 'W16857', 
 'W17292', 
 'W17745') 

and (dim_client.sector = 'Health' and dim_fed_hierarchy_history.[hierarchylevel3hist] = 'EPI'))

--in ('00096875','00239838','00451649'
--,'00655594','00657459','00658192','00671103','00707938','00720451','00816632','153801L','174092C','189405T','33336L','37213W',
--'51130A','64631T','66882S','79266M','89377S','97034B','FW28813','FW29941','TR00010','TR00020','TR00021','W15380','W15484','W15508','W15602','W15605','W16456','W17745') )




order by date_opened_case_management








END
GO
