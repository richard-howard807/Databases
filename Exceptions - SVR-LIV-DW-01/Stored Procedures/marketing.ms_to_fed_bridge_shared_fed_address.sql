SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
	20190423 LD Amended so that Marketing can use the IA reference ( dim_client_key) to search the report.  I have 
				also returned it in the columns 

*/

CREATE PROCEDURE [marketing].[ms_to_fed_bridge_shared_fed_address] -- EXEC dbo.[MSToFedBridgeSharedFedAddressV2] 'MS','5092806'
(
@System AS NVARCHAR(5)
,@entity AS NVARCHAR(20)

)
AS
BEGIN

--DECLARE @System AS NVARCHAR(5)='FED'
--,@entity AS NVARCHAR(20)='00002849'

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
 
IF @System = 'FED'
 
 BEGIN 
 
SET @FEDAddress=(SELECT [FedClientAddressNumber]

  FROM [MS_Prod].[dbo].[udClientContactBridgingTable]
  LEFT OUTER JOIN axxia01.dbo.caclient ON FEDClientNumber=cl_accode COLLATE DATABASE_DEFAULT
  LEFT OUTER JOIN axxia01.dbo.fmsaddr ON FEDClientAddressNumber=fm_addnum   
  WHERE FEDClientNumber=@entity)
 
 END 

IF @System='IA'

BEGIN
INSERT INTO @@ContID
([FedClientAddressNumber]) 

SELECT [FedClientAddressNumber] 
FROM (SELECT a.[FedClientAddressNumber]
FROM [MS_Prod].[dbo].[udClientContactBridgingTable] a
INNER JOIN red_dw.dbo.dim_client b ON a.ContID = b.contactid
WHERE  b.dim_client_key=@entity ) c

  
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
