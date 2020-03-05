SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-04-11
-- Description:	Created for Sarah Calvert  to view Precedents documents
-- =============================================
CREATE PROCEDURE [dbo].[Precedents]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT PrecTitle,PrecDesc,PrecType,'\\sbc.root\matterspheredocs\Mattersphere1\MS_PROD\Precs\'+ PrecPath PrecPath,CASE WHEN CHARINDEX('\', PrecPath) = 0 THEN '\\sbc.root\matterspheredocs\Mattersphere1\MS_PROD\Precs\'  ELSE '\\sbc.root\matterspheredocs\Mattersphere1\MS_PROD\Precs\' + SUBSTRING(PrecPath,0,CHARINDEX('\', PrecPath) +1 ) END location, CASE WHEN CHARINDEX('\', PrecPath) = 0 THEN PrecPath ELSE SUBSTRING(PrecPath,CHARINDEX('\', PrecPath) +1 , LEN(PrecPath)) end   AS name
  FROM MS_prod.[dbo].[dbPrecedents] 
  WHERE PrecTitle NOT LIKE '%(DEL%' AND (precDeleted <> 1 OR precDeleted IS NULL) AND PrecPath IS NOT null
  ORDER BY PrecTitle

END



GO
