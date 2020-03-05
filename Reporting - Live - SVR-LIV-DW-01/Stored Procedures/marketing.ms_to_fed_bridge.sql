SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
	20190423 LD Amended so that Marketing can use the IA reference ( dim_client_key) to search the report.  I have 
				also returned it in the columns 

*/

CREATE PROCEDURE [marketing].[ms_to_fed_bridge] -- EXEC dbo.[MSToFedBridge] 'FED','00002849'
(
@System AS NVARCHAR(5)
,@entity AS NVARCHAR(20)

)
AS
BEGIN

--DECLARE @System AS NVARCHAR(5)='FED'
--,@entity AS NVARCHAR(20)='00002849'

IF @System='MS'

BEGIN

PRINT @System
SELECT 
      [ContID] AS [MS Contact ID]
      ,[clID] AS [MS Client ID]
      ,[clNo] AS [MS Client No]
	  ,dim_client_key AS [IA]
      ,[FedClientNumber]
      ,cl_clname AS [Fed Client Name]
      ,cl_part AS [Client Partner]
      ,[FedClientAddressNumber]
      ,fm_addli1
      ,fm_addli2
      ,fm_addli3
      ,fm_addli4
      ,fm_poscod
	  ,cl_datopn


  FROM [MS_Prod].[dbo].[udClientContactBridgingTable]
  LEFT OUTER JOIN axxia01.dbo.caclient ON FEDClientNumber=cl_accode COLLATE DATABASE_DEFAULT
  LEFT OUTER JOIN axxia01.dbo.fmsaddr ON FEDClientAddressNumber=fm_addnum 
  LEFT OUTER JOIN red_dw.dbo.dim_client ON contactid = ContID   
  WHERE  contid=CAST(@entity AS VARCHAR(20))
  
  
 END 
 
IF @System='FED'
 
 BEGIN 
 PRINT @System
SELECT 
      [ContID] AS [MS Contact ID]
      ,[clID] AS [MS Client ID]
      ,[clNo] AS [MS Client No]
	   ,dim_client_key AS [IA]
      ,[FedClientNumber]
      ,cl_clname AS [Fed Client Name]
      ,cl_part AS [Client Partner]
      ,[FedClientAddressNumber]
      ,fm_addli1
      ,fm_addli2
      ,fm_addli3
      ,fm_addli4
      ,fm_poscod
	  ,cl_datopn

  FROM [MS_Prod].[dbo].[udClientContactBridgingTable]
  LEFT OUTER JOIN axxia01.dbo.caclient ON FEDClientNumber=cl_accode COLLATE DATABASE_DEFAULT
  LEFT OUTER JOIN axxia01.dbo.fmsaddr ON FEDClientAddressNumber=fm_addnum   
  LEFT OUTER JOIN red_dw.dbo.dim_client ON contactid = ContID   
  WHERE FEDClientNumber=@entity
 
 END 
IF @System='IA'

BEGIN 
 PRINT @System
SELECT 
      a.[ContID] AS [MS Contact ID]
      ,a.[clID] AS [MS Client ID]
      ,a.[clNo] AS [MS Client No]
	   ,dim_client_key AS [IA]
      ,[FedClientNumber]
      ,cl_clname AS [Fed Client Name]
      ,cl_part AS [Client Partner]
      ,[FedClientAddressNumber]
      ,fm_addli1
      ,fm_addli2
      ,fm_addli3
      ,fm_addli4
      ,fm_poscod
	  ,cl_datopn

  FROM [MS_Prod].[dbo].[udClientContactBridgingTable] a
  INNER JOIN red_dw.dbo.dim_client c ON c.contactid = a.ContID   
  LEFT OUTER JOIN axxia01.dbo.caclient ON FEDClientNumber=cl_accode COLLATE DATABASE_DEFAULT
  LEFT OUTER JOIN axxia01.dbo.fmsaddr ON FEDClientAddressNumber=fm_addnum 

  WHERE c.dim_client_key = @entity

END 
END
GO
