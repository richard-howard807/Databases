SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
	Author: Lucy Dickinson
	Date:	16/08/2017
	Description:  Ticket:251026 HR have requested a report that shows the count number of instant messages sent 
				  between two individuals via Skype, within a specified time period


*/

CREATE PROCEDURE [hr].[skype_message_count] 

(
	@msg_from VARCHAR(300)
	,@msg_to VARCHAR(300)
	,@dateFrom DATE 
	,@dateTo DATE 

)
AS 

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  
  --DECLARE @msg_from VARCHAR (150)  = 'lucy.dickinson@weightmans.com'
  --DECLARE @msg_to VARCHAR(150) = 'stephen.daffern@weightmans.com'
  --DECLARE @dateFrom DATE = '20170523'
  --DECLARE @dateTo DATE = '20170523'
  DECLARE @nDate DATETIME = CONVERT(VARCHAR(10),@dateTo,101) +  ' 23:59:59.000'  
  

  
  SELECT user_from.UserUri [user_from]
		,user_to.UserUri [user_to]
	--	,msg.MessageIdTime
	--	,msg.Body
		, COUNT(*) [number_of_messages]
  FROM [svr-liv-sql-01].[LcsLog].[dbo].[Messages] msg
  INNER JOIN [svr-liv-sql-01].[LcsLog].[dbo].[Users] user_from ON user_from.UserId = msg.FromId
  INNER JOIN [svr-liv-sql-01].[LcsLog].[dbo].[Users] user_to ON user_to.UserId = msg.ToId

   WHERE user_from.UserUri in  (@msg_from,@msg_to)
   AND user_to.UserUri IN (@msg_from,@msg_to)
   AND msg.MessageIdTime BETWEEN @dateFrom AND @nDate
  GROUP BY user_from.UserUri
  ,user_to.UserUri
 -- ORDER BY msg.MessageIdTime
   
GO
