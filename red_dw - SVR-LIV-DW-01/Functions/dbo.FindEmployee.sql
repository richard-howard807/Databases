SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[FindEmployee] (@search VARCHAR(25))
RETURNS VARCHAR (100)
AS 
-- select dbo.FindEmployee('5741')
-- DECLARE @search VARCHAR(20) = 'SBC\5741'
BEGIN 
DECLARE @Display_Name VARCHAR(5000) = 'X'

	SELECT  TOP 1 @Display_Name = 
				dim_fed_hierarchy_history.display_name + ' (' + dim_fed_hierarchy_history.windowsusername + ')  -  '+ dim_fed_hierarchy_history.hierarchylevel2hist + ' -> ' + dim_fed_hierarchy_history.hierarchylevel3hist + 
					' -> ' + dim_fed_hierarchy_history.hierarchylevel4hist 
	FROM dbo.dim_fed_hierarchy_history
	WHERE REPLACE(LOWER(@search),'sbc\','') = LOWER(dim_fed_hierarchy_history.fed_code)
	AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
	AND dim_fed_hierarchy_history.activeud = 1

IF @Display_Name = 'X'
	BEGIN 

		SELECT  TOP 1 @Display_Name = 
				dim_fed_hierarchy_history.display_name +  ' (' + dim_fed_hierarchy_history.windowsusername + ') -  '+ dim_fed_hierarchy_history.hierarchylevel2hist + ' -> ' + dim_fed_hierarchy_history.hierarchylevel3hist + 
					' -> ' + dim_fed_hierarchy_history.hierarchylevel4hist 
		FROM dbo.dim_fed_hierarchy_history
		WHERE REPLACE(LOWER(@search),'sbc\','') = LOWER(dim_fed_hierarchy_history.windowsusername)
		AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
		AND dim_fed_hierarchy_history.activeud = 1

	END 

IF @Display_Name = 'X'
	BEGIN 

		SELECT  TOP 1 @Display_Name = 
				dim_fed_hierarchy_history.display_name +  ' (' + dim_fed_hierarchy_history.windowsusername + ') -  '+ dim_fed_hierarchy_history.hierarchylevel2hist + ' -> ' + dim_fed_hierarchy_history.hierarchylevel3hist + 
					' -> ' + dim_fed_hierarchy_history.hierarchylevel4hist 
		FROM dbo.dim_fed_hierarchy_history
		WHERE REPLACE(LOWER(@search),'sbc\','') = LOWER(dim_fed_hierarchy_history.name)
		AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
		AND dim_fed_hierarchy_history.activeud = 1

	END 


RETURN @Display_Name
END

GO
