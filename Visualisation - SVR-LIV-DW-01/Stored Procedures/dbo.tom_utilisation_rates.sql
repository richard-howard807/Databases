SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lucy 
-- Create date: <Create Date,,>
-- Description:	Testing : pasting the code straight into Tableau doesn't work for some reason
-- =============================================
CREATE PROCEDURE [dbo].[tom_utilisation_rates]
AS



	  SELECT [Financial Year]
      , [Month]
	  , [Division]
      , [Department]
	  , SUM([Hours Per Month]) [Potential Hours Per Month]
	  , SUM([Chargeable Hours]) [Actual Chargeable Hours]


	   FROM [Visualisation].[dbo].[target_operating_model_utilisation_rates] 

     GROUP BY 
		[Financial Year]
		,[Month]
		,[Division]
		,[Department] 

GO
