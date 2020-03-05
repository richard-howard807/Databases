SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MSToFedBridgeSharedFedAddress] -- EXEC dbo.[MSToFedBridgeSharedFedAddressV2] 'MS','5092806'
(
@System AS nvarchar(5)
,@entity AS nvarchar(20)

)
AS
BEGIN


DECLARE @FEDAddress AS INT

DECLARE @@ContID AS TABLE([FedClientAddressNumber] INT )


IF @System='MS'

BEGIN


INSERT INTO @@ContID
([FedClientAddressNumber]) 

SELECT [FedClientAddressNumber] FROM (SELECT [FedClientAddressNumber]
FROM [MS_Prod].[dbo].[udClientContactBridgingTable]
WHERE  contid=CAST(@entity AS VARCHAR(20))) AS a
  
  
 END 
 
 ELSE 
 
 BEGIN 
 
SET @FEDAddress=(SELECT [FedClientAddressNumber]

  FROM [MS_Prod].[dbo].[udClientContactBridgingTable]
  LEFT OUTER JOIN axxia01.dbo.caclient ON FEDClientNumber=cl_accode collate database_default
  LEFT OUTER JOIN axxia01.dbo.fmsaddr ON FEDClientAddressNumber=fm_addnum   
  WHERE FEDClientNumber=@entity)
 
 END 
 
 SELECT kc_client,caclient.cl_clname
       ,fmsaddr.fm_addli1
      ,fmsaddr.fm_addli2
      ,fmsaddr.fm_addli3
      ,fmsaddr.fm_addli4
      ,fmsaddr.fm_poscod
      ,CASE WHEN MasterAdd.fm_clinum IS NOT NULL THEN 'Yes' ELSE 'No' END  AS [Is Primary]
 FROM axxia01.dbo.kdclicon
 LEFT OUTER JOIN axxia01.dbo.caclient ON kc_client=cl_accode
 LEFT OUTER JOIN axxia01.dbo.fmsaddr ON kc_addrid=fmsaddr.fm_addnum  
LEFT OUTER JOIN axxia01.dbo.fmsaddr AS MasterAdd ON kc_addrid=MasterAdd.fm_addnum  
AND kc_client=MasterAdd.fm_clinum
 WHERE kc_addrid=@FEDAddress OR kc_addrid IN (SELECT [FedClientAddressNumber]  FROM @@ContID)
 
END
GO
