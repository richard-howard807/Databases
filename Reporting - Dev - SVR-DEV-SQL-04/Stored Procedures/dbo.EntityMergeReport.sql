SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[EntityMergeReport]
(
@contid AS BIGINT
)
AS
BEGIN
SELECT 
dbcontact.contID AS [MS Entity Number]      
,contName AS [MS Entity Name]
,dbContact.contTypeCode AS [MS ContType]
,clNo AS [MS Client Number]
,clName AS [MS Client Name]
,REPLACE(REPLACE(CONCAT(RTRIM(addLine1), ' ', RTRIM(addLine2), ' ', RTRIM(addLine3), ' ', RTRIM(addLine4), ' ',RTRIM(addLine5), ' ',RTRIM(addPostcode)),'  ',' '),'  ',' ') AS [MS Default Site Address]
,RTRIM(addLine1) AS MSaddLine1
,RTRIM(addLine2) AS MSaddLine2
,RTRIM(addLine3) AS MSaddLine3
,RTRIM(addLine4) AS MSaddLine4
,RTRIM(addLine5) AS MSaddLine5
,RTRIM(addPostcode) AS MSPostcode
,dbContact.Created AS [MS Entity Create Date]      
,dbContact.Updated AS [MS Entity Last Modified Date]       
,ISNULL(MSNumberMatters,0) AS [MS Number of Matters (Open & Closed Matters)]     
,ISNULL([Number of Site Links],0) AS [MS Number of Site Links]       
,ISNULL([Number of Contact Links],0) AS [MS Number of Contact Links]
,ISNULL(MSNumberAssociates,0) AS [MS Number of Associate Links]       
,ISNULL(NumberFEDAssociates,0) AS [MS Number of FED Entities]
,ISNULL([EMPR Link],'No')  AS [MS IS EMPR Link]
,contExtID AS [MS/3E Join Number]
------------------- 3E ---------------------------------------
,EntIndex AS [3E Entity Number]      
,DisplayName AS [3E Entity Name]
,ArchetypeCode AS [3E ArchetypeCode]   
,def_site.formattedstring AS [3E Address formattedstring] 
,[3EAddress]  AS [3E Default Site Address]      --
,[3EOrgName]
,[3EStreet]
,[3ECity]
,[3EState]
,[3ECountry]
,[3EZipCode]
,[3ECounty]
,[3EAdditional1]
,[3EAdditional2]
,[3EAdditional3]
,[3EAdditional4]

,ISNULL(ctr_count.ctr_count,0) AS [3E Country(ies)]   --
,NULL AS [3E Entity Created Date]    
,[TimeStamp] AS [3E Entity Last Modified Date]     
,ISNULL(mat_count.mat_count,0) AS [3E Number of Matters (Open & Closed Matters)]     --
,ISNULL(sites_count.sites_count,0) AS [3E Number of Site Links]       --
,ISNULL([Number of Clients Links],0) AS [3E Number of Clients Links] 
,ISNULL([Number Payor Links],0) AS [3E Number of Payer Links]       
,ISNULL([Number Vendor Links],0) AS [3E Number of Vendor Links]       
,ISNULL([Number User Links],0) AS [3E Number of User Links]  
,NULL AS [Billings for clients in the last 3 yrs (Profit Costs)] --?

FROM MS_Prod.config.dbContact WITH (NOLOCK)
       LEFT OUTER JOIN MS_Prod.config.dbClient WITH (NOLOCK)
        ON dbContact.contID=dbClient.clDefaultContact
       LEFT OUTER JOIN (SELECT clID,
                                                COUNT(1) AS MSNumberMatters
                                  FROM       MS_Prod.config.dbFile WITH (NOLOCK)
                                  GROUP BY clID
                                  ) AS Matters ON dbClient.clID=Matters.clID 
       LEFT OUTER JOIN (SELECT contID,
                                                COUNT(1) AS MSNumberAssociates 
                                  FROM       MS_Prod.config.dbAssociates WITH (NOLOCK) 
                                  GROUP BY contID
                                  ) AS  Associates ON dbContact.contID=Associates.contID
       LEFT OUTER JOIN (SELECT ContID,
                                                COUNT(1) AS NumberFEDAssociates
                                  FROM       MS_Prod.dbo.udClientContactBridgingTable AS bridge WITH (NOLOCK) 
                                         INNER JOIN axxia01.dbo.invol ON FedClientNumber=entity_code collate database_default
                                  GROUP BY ContID
                                  ) AS FedEntities ON dbContact.contID=FedEntities.ContID
       LEFT OUTER JOIN (SELECT contID,
                                                COUNT(1) AS [Number of Contact Links]
                                  FROM       MS_PROD.dbo.dbContactLinks WITH (NOLOCK)
                                  GROUP BY contID
                                  ) AS  LinkedContacts ON dbContact.contID=LinkedContacts.contID
       LEFT OUTER JOIN MS_Prod.dbo.dbAddress ON contDefaultAddress=dbAddress.addID
       LEFT OUTER JOIN (SELECT contID AS contID,
                                                COUNT(1) AS [Number of Site Links]
                                  FROM   [SVR-LIV-MSSQ-01].[MS_PROD].[dbo].[dbContactAddresses] WITH (NOLOCK)
                                  GROUP BY contID
                                  ) AS SiteLinks ON dbContact.contID=SiteLinks.contID
       --------------------- 3E
       LEFT OUTER JOIN TE_3E_Prod.dbo.Entity ON dbContact.contExtID=EntIndex
       LEFT OUTER JOIN (SELECT Entity,
                                                COUNT(1) AS [Number Payor Links] 
                                  FROM       TE_3E_Prod.dbo.Payor WITH (NOLOCK)
                                  GROUP BY Entity
                                  ) AS Payor ON Entity.EntIndex=Payor.Entity
       LEFT OUTER JOIN (SELECT Entity,
                                                COUNT(1) AS [Number Vendor Links]
                                  FROM       TE_3E_Prod.dbo.Vendor WITH (NOLOCK)
                                  GROUP BY Entity
                                  ) AS VendorLinks ON Entity.EntIndex=VendorLinks.Entity
       LEFT OUTER JOIN (SELECT  Entity,
                                                COUNT(1) AS [Number User Links]
                                  FROM       TE_3E_Prod.dbo.Timekeeper WITH (NOLOCK)
                                  GROUP BY Entity
                                  ) AS UserLinks ON Entity.EntIndex=UserLinks.Entity
       LEFT OUTER JOIN (SELECT  Entity,
                                                COUNT(1) AS [Number of Clients Links]
                                  FROM       TE_3E_Prod.dbo.Client WITH (NOLOCK)
                                  GROUP BY Entity
                                  ) AS Client ON Entity.EntIndex=Client.Entity

       left outer join (select relate,
                                                formattedstring,REPLACE(REPLACE((ISNULL(RTRIM(Street),'')
+' ' + ISNULL(RTRIM(Additional1),'')
+' ' + ISNULL(RTRIM(City),'')
+' ' + ISNULL(RTRIM(County),'')
+' ' + ISNULL(RTRIM(ZipCode),'')
),'  ',' '),'  ',' ')  AS [3EAddress]
,OrgName	AS [3EOrgName]
,Street	   AS [3EStreet]
,City	AS [3ECity]
,State	AS [3EState]
,Country	AS [3ECountry]
,ZipCode	AS [3EZipCode]
,County	AS [3ECounty]
,Additional1	AS [3EAdditional1]
,Additional2	AS [3EAdditional2]
,Additional3	AS [3EAdditional3]
,Additional4	AS [3EAdditional4]

                                  from   TE_3E_Prod.dbo.site s WITH (NOLOCK)
                                         inner join TE_3E_Prod.dbo.address a WITH (NOLOCK) on s.address=a.addrindex
                                  where  isdefault = 1) as def_site on Entity.entindex = def_site.relate
       left outer join (select relate,
                                                count(*) sites_count
                                  from   TE_3E_Prod.dbo.site WITH (NOLOCK)
                                  group by relate) as sites_count on Entity.entindex = sites_count.relate
       left outer join      (select       relate,
                                                count(distinct country) ctr_count
                                  from   TE_3E_Prod.dbo.site s WITH (NOLOCK)
                                         inner join TE_3E_Prod.dbo.address a WITH (NOLOCK) on s.address = a.addrindex
                                  group by relate) ctr_count on Entity.entindex = ctr_count.relate
       left outer join      (select entity,
                                  count(*)       mat_count
                                  from TE_3E_Prod.dbo.client c WITH (NOLOCK)
                                         inner join TE_3E_Prod.dbo.matter m  WITH (NOLOCK) on c.clientindex = m.client
                                  group by entity) mat_count on Entity.entindex = mat_count.entity

 LEFT JOIN (
SELECT DISTINCT  dbContactLinks.contID,'Yes' AS  [EMPR Link]
FROM MS_PROD.dbo.dbContactLinks  WITH (NOLOCK) 
LEFT JOIN MS_PROD.config.dbContact WITH (NOLOCK)  ON dbContact.contID = dbContactLinks.contLinkID
WHERE contLinkCode = 'EMPR') contactlinks
on dbContact.contID = contactlinks.contID

WHERE dbcontact.contID =@contid

END
GO
