SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[GLDetail_3ESQ-01]
AS
SELECT 
       [FirmDR],
       [FirmCR]
       
FROM [TE_3E_PROD].[dbo].[GLDetail] WITH (NOLOCK)
WHERE GLAcct = 15504;
GO
