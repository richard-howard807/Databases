SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 27-06-2022
-- Description:	New Immigration Report #154532
-- Carolyn Bowie and Mandy Higgins
-- =============================================
CREATE PROCEDURE [dbo].[ImmigrationRevenueReport]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

 DECLARE @FinYear AS INT
 
 SET @FinYear=(SELECT fin_year FROM red_dw.dbo.dim_date
WHERE CONVERT(DATE,calendar_date,103)=CONVERT(DATE,DATEADD(YEAR,-1,GETDATE()),103))

SELECT  
Revenue
,dim_client.client_group_name AS [Client Group Name]
,dim_client.client_name AS [Client Name]
,fed_code_fee_earner AS [Fee Earner Name]
,dim_detail_advice.[case_classification] [Case Classification]
,dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number [Weightmans Ref]
,hist.display_name




FROM 
red_dw.dbo.fact_dimension_main AS dimmain
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details AS core_details ON core_details.dim_detail_core_detail_key = dimmain.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=dimmain.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client AS dim_client ON dim_client.dim_client_key = dimmain.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice ON dim_detail_advice.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client AS dim_detail_client ON dim_detail_client.dim_detail_client_key = dimmain.dim_detail_client_key

			
 
--LEFT OUTER JOIN red_dw..dim_fed_hierarchy_history ON dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
	INNER  JOIN (SELECT DISTINCT dim_matter_header_curr_key
	, SUM(fact_bill_activity.bill_amount)  Revenue	
	,fed_code_fee_earner
	,dim_fed_hierarchy_history_key AS fedkey
	
	FROM red_dw.dbo.fact_bill_activity WITH(NOLOCK)			
	INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)			
	ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key	
	AND  fact_bill_activity.fed_code_fee_earner IN( '1262','5851')
	WHERE  bill_fin_year='2022'
	GROUP BY  dim_matter_header_curr_key,fed_code_fee_earner,dim_fed_hierarchy_history_key
				
) RevenueBilled2022 ON RevenueBilled2022.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS hist ON hist.dim_fed_hierarchy_history_key = RevenueBilled2022.fedkey
WHERE 
CASE WHEN 	dim_detail_advice.[case_classification]   LIKE '%IMM%' THEN 1
WHEN dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number  IN('R1001-34182','R1001-33466','R1001-33538')	THEN 1
WHEN dim_client.client_group_name = 'Royal Mail'  THEN 2
ELSE 1 END =1

END
GO
