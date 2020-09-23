SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_dim_matter_header_current]
AS 
SELECT 
*
FROM red_dw.dbo.dim_matter_header_current WITH (NOLOCK)

WHERE reporting_exclusions = 0



GO
