SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 06/07/2018
-- Description:	Returns a list of departments for the Divisions passed through
-- =============================================

--SELECT * FROM  dbo.list_departments ('Legal Ops - Claims')

CREATE FUNCTION [dbo].[list_departments]
(
	-- Add the parameters for the function here
		@division VARCHAR(MAX)
)
RETURNS 
@department TABLE 
(
	-- Add the column definitions for the TABLE variable here
	department VARCHAR(200)
)
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	INSERT INTO @department
	        ( department )
	SELECT DISTINCT
			a.hierarchylevel3hist
	FROM red_dw.dbo.dim_fed_hierarchy_history a
	WHERE a.dss_current_flag = 'Y'
		AND a.activeud = 1
		AND a.hierarchylevel3hist IS NOT NULL
		AND a.hierarchylevel2hist COLLATE DATABASE_DEFAULT IN (SELECT val FROM [dbo].[split_delimited_to_rows] (@division,','))
	
	RETURN 
END
GO
GRANT SELECT ON  [dbo].[list_departments] TO [SBC\CascadeDepartment - MI]
GO
