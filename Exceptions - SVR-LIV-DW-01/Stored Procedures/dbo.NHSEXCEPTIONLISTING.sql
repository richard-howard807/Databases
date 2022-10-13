SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Orlagh Kelly>
-- Create date: <31st August 2018,>
-- Description:	<report to drive the sabre listing report >
-- =============================================
CREATE PROCEDURE [dbo].[NHSEXCEPTIONLISTING]

(
@FeeEarners AS NVARCHAR(MAX)
)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


SELECT 
name,
dim_fed_hierarchy_history.fed_code,
hierarchylevel2hist,
hierarchylevel3hist,
hierarchylevel4hist,
COUNT(*) no_excptions,
COUNT(DISTINCT case_id) cases
 FROM red_Dw.dbo.fact_exceptions_update
 LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_exceptions_update.dim_fed_hierarchy_history_key
WHERE datasetid = 226
AND fact_exceptions_update.client_code = 'N1001'
--AND dim_fed_hierarchy_history.hierarchylevel3hist <> 'Healthcare'
AND duplicate_flag <> 1
AND miscellaneous_flag <> 1
AND dim_fed_hierarchy_history.name IN (@FeeEarners)
--AND dim_fed_hierarchy_history.name = 'Graham Dean'
GROUP BY name,
dim_fed_hierarchy_history.fed_code,
hierarchylevel2hist,
hierarchylevel3hist,
hierarchylevel4hist






END
--GO
GO
