SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 21-03-2019
-- Description:	Zurich disbursement report
-- =============================================
CREATE PROCEDURE [dbo].[ZurichDisbursementReport]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT 
fact_dimension_main.client_code,
fact_dimension_main.matter_number,
matter_description,
date_opened_case_management,
date_closed_practice_management,
present_position,
outcome_of_case,
name,
fed_code,
hierarchylevel2hist,
hierarchylevel3hist,
hierarchylevel4hist,
billing_arrangement_description,
fixed_fee,
fixed_fee_amount,
[Copy], 
[Non Copy]
FROM red_Dw.dbo.fact_dimension_main 
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT JOIN (
SELECT 
master_fact_key,
[Copy],
[Non Copy]
FROM  
    (
	SELECT 
		master_fact_key,
		CASE WHEN costtype ='CP' THEN 'Copy' ELSE 'Non Copy' END costtype,
		SUM(total_unbilled_disbursements) total_disbursements
		FROM red_Dw.dbo.fact_disbursements_detail
		GROUP BY  
		master_fact_key,
		CASE WHEN costtype ='CP' THEN 'Copy' ELSE 'Non Copy' END
	)   
    AS fact_disbursements_detail
PIVOT  
(  
    SUM(total_disbursements)
FOR   
costtype
    IN 
	( 
		[Copy], [Non Copy]
	)  
) AS a
) result ON result.master_fact_key = fact_dimension_main.master_fact_key
WHERE result.[Non Copy] >= 250 AND reporting_exclusions = 0 AND LOWER(outcome_of_case )<> 'exclude from reports'
AND dim_matter_header_current.master_client_code = 'Z1001'
END
GO
