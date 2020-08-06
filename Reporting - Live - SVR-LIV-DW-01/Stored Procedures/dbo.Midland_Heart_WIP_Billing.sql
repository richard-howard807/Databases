SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 23/07/2020
-- Description:	New report for Midland Heart see ticket 65197
-- =============================================
CREATE PROCEDURE [dbo].[Midland_Heart_WIP_Billing]
AS
BEGIN

	SET NOCOUNT ON;

SELECT 
CASE WHEN work_type_name IN ('Commercial Contracts','Commercial drafting (advice)','Company','Competition Law','Contract','Contract Supplier'                       
,'Defamation','Direct Selling','Events','Health and Safety - Advisory/Consultancy','Health and Safety - Defending','Health and Safety - Prosecuting','Health and Safety - Training'            
,'Injunction','Injunctions','Intellectual property','Judicial Review','Non-contentious IP & IT Contracts','Partnership','Partnerships & JVs','Private Equity','Procurement'                             
,'Recoveries','Share Structures & Company Reorganisatio') THEN 'Contracts, Commercials, Procurement, Health and Safety' 
WHEN work_type_name IN( 'Comm conveyancing (business premises)','Due Dilligence','Landlord & Tenant - Commercial','Landlord & Tenant - Disrepair'           
,'Landlord & Tenant - Residential','Leases-granting,taking,assigning,renewin','Reactive Training','Remortgage','Residential conveyancing (houses/flats)' 
,'Right to buy','Social Housing - Property','Training') THEN 'Homelessness, Housing Management, Home Ownership, Asset Management'                            
ELSE 'Other' END AS [LOT/Category]
, fact_finance_summary.total_amount_billed AS [Total gross bills]




FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.fed_code = dim_matter_header_current.fee_earner_code
               AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
               AND GETDATE()
               BETWEEN dss_start_date AND dss_end_date

WHERE 

dim_matter_header_current.matter_number <> 'ML'
AND dim_matter_header_current.reporting_exclusions=0
AND fact_dimension_main.client_code = 'W23552'



END
GO
