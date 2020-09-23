SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[vis_view_doogal]
AS 

SELECT Postcode
	, Latitude
	, Longitude
	
  FROM [red_dw].[dbo].[Doogal] WITH (NOLOCK)


GO
