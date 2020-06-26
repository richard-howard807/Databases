SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[AIActivities]

AS 

BEGIN

SELECT dim_client_key AS dim_client_key
,activity_calendar_date AS [Activity]
,activity_type_desc AS [Activity type]
,activity_calendar_date AS [Date of activity]
 FROM red_dw.dbo.dim_ia_activities
INNER JOIN red_dw.dbo.dim_activity_date
 ON activity_date_key=dim_activity_date_key
INNER JOIN red_dw.dbo.dim_ia_activity_type
 ON dim_ia_activity_type.dim_activity_type_key = dim_ia_activities.dim_activity_type_key

 END


GO
