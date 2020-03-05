SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Steven Gregory
-- Create date: 20/02/2018
-- Description:	Get the prviouse vale for NMI603 for MIB
-- =============================================
CREATE PROCEDURE [MIB].[last_subsequent_report_date]
AS

SET NOCOUNT ON;

SELECT 
rank.case_id,
rank.original_cdc_date,
rank.case_date,
client,
matter,
RTRIM(client)+'-'+matter lookup

FROM (

SELECT 
case_id,
original_cdc_date,
case_date, 
RANK() OVER( PARTITION BY case_id order BY original_cdc_date desc) row_rank
FROM red_dw.dbo.ds_sh_axxia_casdet WITH (NOLOCK)
WHERE case_detail_code = 'NMI603' AND case_date IS NOT NULL AND current_flag <> 'Y'
) rank
LEFT JOIN red_Dw.dbo.ds_sh_axxia_cashdr ON ds_sh_axxia_cashdr.case_id = rank.case_id AND ds_sh_axxia_cashdr.current_flag = 'Y'
WHERE rank.row_rank = 1
ORDER BY rank.case_id, rank.original_cdc_date DESC



GO
