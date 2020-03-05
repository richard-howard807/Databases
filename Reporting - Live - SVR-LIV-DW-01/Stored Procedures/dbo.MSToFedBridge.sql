SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MSToFedBridge] -- EXEC dbo.[MSToFedBridge] 'FED','00002849'
(
@System AS nvarchar(5)
,@entity AS nvarchar(20)

)
AS
BEGIN


--SET @System='FED'
--SET @entity='A1001'


IF @System='MS'

BEGIN


SELECT 
      [ContID] AS [MS Contact ID]
      ,[clID] AS [MS Client ID]
      ,[clNo] AS [MS Client No]
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
  LEFT OUTER JOIN axxia01.dbo.caclient ON FEDClientNumber=cl_accode collate database_default
  LEFT OUTER JOIN axxia01.dbo.fmsaddr ON FEDClientAddressNumber=fm_addnum    
  WHERE  contid=CAST(@entity AS VARCHAR(20))
  
  
 END 
 
 ELSE 
 
 BEGIN 
 
SELECT 
      [ContID] AS [MS Contact ID]
      ,[clID] AS [MS Client ID]
      ,[clNo] AS [MS Client No]
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
  LEFT OUTER JOIN axxia01.dbo.caclient ON FEDClientNumber=cl_accode collate database_default
  LEFT OUTER JOIN axxia01.dbo.fmsaddr ON FEDClientAddressNumber=fm_addnum   
  WHERE FEDClientNumber=@entity
 
 END 
END
GO
