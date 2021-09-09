SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create view [dbo].[vw_users]

as
 
select distinct client_user_identifier, first_name, last_name, email_address
from dbo.learningrecords_users


GO
