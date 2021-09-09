SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create view [dbo].[vw_courses]

as
 
select distinct course_name, category, subcategory
from dbo.learningrecords_users


GO
