SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		lucy Dickinson
-- Create date: 25/10/2018
-- Description:	Report to retrieve the drop down list of values for details that have a drop down
-- =============================================
CREATE PROCEDURE [dataservices].[fed_detail_dropdown_list]
	-- Add the parameters for the stored procedure here
	@case_detail_code varchar(250)
AS
BEGIN
	
	--For testing purposes
	--DECLARE @case_detail_code varchar(100) = 'TRA068'
	
	

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT 
	 a.sd_detcod	[Code]
	,a.sd_listxt [Description] 
	
	FROM axxia01.dbo.stdetlst a
	
	WHERE 1 = 1 
		AND sd_detcod = @case_detail_code

	ORDER BY a.sd_listxt
END
GO
