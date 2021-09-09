SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[vw_user_course]

as
 
select distinct client_user_identifier, course_name, history_status, score, history_status_date, duration, subcategory, category
from dbo.learningrecords_users

GO
