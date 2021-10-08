SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[MSExceptionLog]
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS 

BEGIN

SELECT 
 ProviderName
, CASE WHEN [ProviderName] = 'Application Error' OR [ProviderName] = 'Application Hang' THEN 'Applications' 
	ELSE 'Mattersphere' 
	END [Type]
, CASE 
	WHEN [ProviderName] in ('Application Error','Application Hang') THEN LEFT([Message],60)
	WHEN [Message] like '%Control named%' THEN 'Control Named uAppPanel or uAppCommPanel is missing'
	WHEN [Message] like '%cannot be found within the database. Or you have insufficient permission to view the Client%' THEN 'Client cannot be found'
	WHEN [Message] like '%Call was rejected by callee%' THEN 'Call was rejected by callee'
	WHEN [Message] like '%Cannot access a disposed object%' THEN 'Cannot access a disposed object'
	WHEN [Message] like '%Update Error%' THEN 'Update Error'
	WHEN [Message] like '%Bulk Profiling Error%' THEN 'Bulk Profiling Error'
	WHEN [Message] like '%Bulk Profiling Error%' THEN 'Bulk Profiling Error'
	WHEN [Message] like '%Cannot access a disposed object%' THEN 'Cannot access a disposed object'
	WHEN [Message] like '%Cannot create ActiveX component%' THEN 'Cannot create ActiveX component'
	WHEN [Message] like '%Cannot uncomplete task%' THEN 'Cannot uncomplete task'
	WHEN [Message] like '%Extracting Attachments Error%' THEN 'Extracting Attachments Error'
	WHEN [Message] like '%The following required fields must be used%' THEN 'The following required fields must be used'
	WHEN [Message] like '%Object reference not set%' THEN 'Object reference not set'
	WHEN [Message] like '%Unable to complete task%' THEN 'Unable to complete task'
	WHEN [Message] like '%Unable to complete stage%' THEN 'Unable to complete stage'
	WHEN [Message] like '%Unable to Load Script%' THEN 'Unable to Load Script Error'
	WHEN [Message] like '%Unexpected error in Search%' THEN 'Unexpected Error in Search'
	WHEN [Message] like '%The session container has not been configured%' THEN 'The session container has not been configured'
	WHEN [Message] like '%SQL Code Error%' THEN 'SQL Code Error'
	WHEN [Message] like '%The process cannot access%' THEN 'The process cannot access the file'
	WHEN [Message] like '%Error Loading Addin%' THEN 'Error Loading Addin'
	WHEN [Message] like '%The specified item%' THEN 'The specified item does not exist within provider files'
	WHEN [Message] like '%There is a problem storing%' THEN 'There is a problem storing document'
	ELSE [Message]
END [Message Group]
,CAST([TimeStamp] as DATETIME) [IncidentDate]
,[TimeStamp]
,[ApplicationName]
,[Message]
from [SVR-LIV-XASQ-01].LogonAudit.dbo.errorTrackingEvents
 where ApplicationName ='Mattersphere Exception'
  --and ServerName='SVR-LIV-XA7-02.sbc.root'
AND CONVERT(DATE,CAST([TimeStamp] as Date),103) BETWEEN @StartDate AND @EndDate
END
GO
