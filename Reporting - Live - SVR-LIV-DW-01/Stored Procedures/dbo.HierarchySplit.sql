SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Dutton
-- Create date: 2019-02-20
-- Description:	Area managed hierarchy split
-- =============================================
CREATE PROCEDURE [dbo].[HierarchySplit]
	@FEDCode as VARCHAR(MAX)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

DECLARE @sql VARCHAR(MAX)
SET @sql = 'select * from red_dw.dbo.dim_fed_hierarchy_history where dim_fed_hierarchy_history_key in (' + @FEDCode + ')'

EXEC (@sql) 
END
GO
