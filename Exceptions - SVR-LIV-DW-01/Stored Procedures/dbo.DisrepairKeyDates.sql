SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 15-08-2022
-- Description:	Key Dates for Disrepair #158676
-- this has been added to the Tableau dasboard and a number of Disrepair BAR reports
-- =============================================
CREATE PROCEDURE [dbo].[DisrepairKeyDates]
AS
BEGIN

	SET NOCOUNT ON;



SELECT 

 dim_matter_header_current.client_code + '-' 
+ dim_matter_header_current.master_matter_number										AS [Client/Matter Number]
,matter_description
, STRING_AGG(CAST(key_date AS DATE), ' / ') WITHIN GROUP (ORDER BY key_date ASC)   AS	 [Trial Key Date]
, STRING_AGG(CAST(description AS NVARCHAR(MAX)), '/ ')	 AS Description
--,CASE WHEN type LIKE '%TRIAL%' THEN 'Trial' ELSE 'Other' END AS Type


FROM red_dw.dbo.fact_dimension_main
    INNER JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
        ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
        ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_key_dates 
		ON dim_key_dates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history 
        ON dim_fed_hierarchy_history .dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key

WHERE
dim_matter_worktype.work_type_code = '1150'
AND dim_matter_header_current.reporting_exclusions <> 1
AND dim_key_dates.key_date >= GETDATE()
AND is_active=1
--AND type LIKE '%TRIAL%'
AND type IN( 'ACKNOSERV',
'TRIAL',
'AQDQ',
'DISC' ,
'AQDQ',
'SCHLOSS',
'COUNTERSCHLOSS',
'COUNTERSCH',
'TRIALBUNDLE',
'DEFENCE',
'ACKNOSERV', 
'EXCHWITSTAT',
'KDTRIALDATELIT',
'PROTOCOL',
'TRIALWINDOW',
'HEARING',
'DEFENCESDUE',
'INSPECTDOCS',
'TRIALWARNED',
'PROTRESP',
'WITEVIDENCE'

)
--AND dim_matter_header_current.master_client_code + '/' 
--+ dim_matter_header_current.master_matter_number = '756630/761'

GROUP BY
 dim_matter_header_current.client_code + '-' 
+ dim_matter_header_current.master_matter_number										
,matter_description
--,CASE WHEN type LIKE '%TRIAL%' THEN 'Trial' ELSE 'Other' END
END
GO
