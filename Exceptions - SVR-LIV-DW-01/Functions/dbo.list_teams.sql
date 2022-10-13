SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 06/07/2018
-- Description:	Returns a list of teams for the departments passed through

-- RH 17/05/2021 Changed logic to remove 'not like %&%'' and get a distinct list of active teams
-- =============================================



CREATE FUNCTION [dbo].[list_teams]
(
	-- Add the parameters for the function here
		@department VARCHAR(MAX)
)
RETURNS 
@team TABLE 
(
	-- Add the column definitions for the TABLE variable here
	team VARCHAR(200)
)
AS
BEGIN
	-- Fill the table variable with the rows for your result set
	INSERT INTO @team
	        ( team )
	SELECT DISTINCT
			a.hierarchylevel4hist
	FROM red_dw.dbo.dim_fed_hierarchy_history a
	WHERE a.dss_current_flag = 'Y'
		AND a.activeud = 1
		AND a.hierarchylevel4hist IS NOT NULL
		AND a.hierarchylevel3hist COLLATE DATABASE_DEFAULT IN (SELECT val FROM [dbo].[split_delimited_to_rows] (@department,','))
		--AND a.hierarchylevel4hist NOT LIKE '%&%'
		and a.leaver = 0 
		and a.dim_employee_key <> 0
	RETURN 
END

GO
GRANT SELECT ON  [dbo].[list_teams] TO [SBC\CascadeDepartment - MI]
GO
