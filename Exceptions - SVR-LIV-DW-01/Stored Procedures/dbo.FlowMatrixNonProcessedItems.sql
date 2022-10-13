SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--===============================================================
-- ES 12-01-2021 #84530, added deleted flag to where clause logic
--===============================================================


CREATE PROCEDURE [dbo].[FlowMatrixNonProcessedItems]

AS

BEGIN



SELECT [job_id],
       [created],
       [owner],
       [active],
       [completed],
       [execution_state],
       [state],
       [priority],
       [queue_id],
       [modified]
FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs]
WHERE completed = '0'
      AND active = '0'
	  AND Jobs.deleted = '0'
ORDER BY [job_id] DESC;


END
GO
