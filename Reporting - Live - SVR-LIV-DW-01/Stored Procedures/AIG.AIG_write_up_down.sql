SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-08-14
-- Description:	created for A-M to see write ups and downs 331180  
 
-- =============================================
CREATE PROCEDURE [AIG].[AIG_write_up_down] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--IF OBJECT_ID ('tempdb.dbo.#results') IS NOT NULL
--DROP TABLE #results
--select  
--coalesce(left(ds_sh_3e_matter.loadnumber,(charindex('-',ds_sh_3e_matter.loadnumber)-1)),ds_sh_3e_client.altnumber,
--	CASE WHEN ISNUMERIC(ds_sh_3e_client.number) = 1 THEN RIGHT(CAST(CAST(ds_sh_3e_client.number AS int)  + 100000000 AS varchar(9)),8) ELSE ds_sh_3e_client.number END) client_code,
--isnull(right(ds_sh_3e_matter.loadnumber, len(ds_sh_3e_matter.loadnumber) - charindex('-',ds_sh_3e_matter.loadnumber))
--,
--right(ds_sh_3e_matter.altnumber, len(ds_sh_3e_matter.altnumber) - charindex('-',ds_sh_3e_matter.altnumber))
--) matter_number,
--billhrswdn,
--billhrswup,
--billamtwdn,
--billamtwup,
--workhrs,
--workamt,
--billhrs,
--billamt,
--dim_client.client_group_code
--INTO #results
--FROM  red_Dw.dbo.ds_sh_3e_timebill
--LEFT JOIN red_Dw.dbo.ds_sh_3e_invmaster ON invmaster = invindex
--LEFT OUTER JOIN red_Dw.dbo.ds_sh_3e_matter
--  ON ds_sh_3e_invmaster.leadmatter = ds_sh_3e_matter.mattindex
--LEFT OUTER JOIN red_Dw.dbo.ds_sh_3e_client
--ON ds_sh_3e_matter.client = ds_sh_3e_client.clientindex
--LEFT JOIN red_Dw.dbo.dim_client ON client_code = coalesce(left(ds_sh_3e_matter.loadnumber,(charindex('-',ds_sh_3e_matter.loadnumber)-1)),ds_sh_3e_client.altnumber,
--	CASE WHEN ISNUMERIC(ds_sh_3e_client.number) = 1 THEN RIGHT(CAST(CAST(ds_sh_3e_client.number AS int)  + 100000000 AS varchar(9)),8) ELSE ds_sh_3e_client.number END)
--WHERE client_group_code = '00000013' and workamt <> billamt 



SELECT 
fact_dimension_main.client_code,
fact_dimension_main.matter_number,
work_type_name,
CASE WHEN SUM(write_off_amt) IS NULL THEN 0 else SUM(write_off_amt) end write_off_amt,
CASE WHEN SUM(write_off_amt) IS NULL THEN 0 else SUM(write_off_hrs)/60 end write_off_hrs
FROM red_Dw.dbo.fact_dimension_main    WITH(NOLOCK)
LEFT JOIN red_Dw.dbo.dim_matter_header_current  WITH(NOLOCK) ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype  WITH(NOLOCK) ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_Dw.dbo.fact_write_off  WITH(NOLOCK) ON fact_write_off.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_Dw.dbo.dim_client  WITH(NOLOCK) ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
inner JOIN
(
SELECT distinct master_fact_key from red_dw.dbo.fact_all_time_activity
LEFT JOIN red_dw.dbo.dim_date ON dim_date_key = fact_all_time_activity.dim_transaction_date_key
WHERE calendar_date > = DATEADD(MONTH,-12,GETDATE())
) fact_all_time_activity ON fact_all_time_activity.master_fact_key = fact_dimension_main.master_fact_key
WHERE dim_client.client_group_code = '00000013' AND work_type_name LIKE 'Disease -%'  
GROUP BY 
fact_dimension_main.client_code,
fact_dimension_main.matter_number,
work_type_name
ORDER BY fact_dimension_main.client_code,
fact_dimension_main.matter_number
END


GO
