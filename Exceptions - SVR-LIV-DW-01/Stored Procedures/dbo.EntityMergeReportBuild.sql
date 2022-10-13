SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[EntityMergeReportBuild]
AS
BEGIN

IF OBJECT_ID('dbo.EntityMergeReportSteHep', 'U') IS NOT NULL DROP TABLE dbo.EntityMergeReportSteHep;

SELECT dbcontact.contID AS [MS Entity Number] ,
       contName AS [MS Entity Name] ,
       dbcontact.contTypeCode AS [MS ContType] ,
       clNo AS [MS Client Number] ,
       clName AS [MS Client Name] ,
       REPLACE(
           REPLACE(
               CONCAT(
                   RTRIM(addLine1) ,
                   ' ' ,
                   RTRIM(addLine2),
                   ' ' ,
                   RTRIM(addLine3),
                   ' ' ,
                   RTRIM(addLine4),
                   ' ' ,
                   RTRIM(addLine5),
                   ' ' ,
                   RTRIM(addPostcode)) ,
               '  ' ,
               ' ') ,
           '  ' ,
           ' ') AS [MS Default Site Address] ,
       RTRIM(addLine1) AS MSaddLine1 ,
       RTRIM(addLine2) AS MSaddLine2 ,
       RTRIM(addLine3) AS MSaddLine3 ,
       RTRIM(addLine4) AS MSaddLine4 ,
       RTRIM(addLine5) AS MSaddLine5 ,
       RTRIM(addPostcode) AS MSPostcode ,
       dbcontact.Created AS [MS Entity Create Date] ,
       dbcontact.Updated AS [MS Entity Last Modified Date] ,
       ISNULL(MSNumberMatters, 0) AS [MS Number of Matters (Open & Closed Matters)] ,
       ISNULL([Number of Site Links], 0) AS [MS Number of Site Links] ,
       ISNULL([Number of Contact Links], 0) AS [MS Number of Contact Links] ,
       ISNULL(MSNumberAssociates, 0) AS [MS Number of Associate Links] ,
       ISNULL(NumberFEDAssociates, 0) AS [MS Number of FED Entities] ,
       ISNULL([EMPR Link], 'No') AS [MS IS EMPR Link] ,
       contExtID AS [MS/3E Join Number] ,
                                                                                          ------------------- 3E ---------------------------------------
       EntIndex AS [3E Entity Number] ,
       DisplayName AS [3E Entity Name] ,
       ArchetypeCode AS [3E ArchetypeCode] ,
       def_site.FormattedString AS [3E Address formattedstring] ,
       [3EAddress] AS [3E Default Site Address] ,                                         --
       [3EOrgName] ,
       [3EStreet] ,
       [3ECity] ,
       [3EState] ,
       [3ECountry] ,
       [3EZipCode] ,
       [3ECounty] ,
       [3EAdditional1] ,
       [3EAdditional2] ,
       [3EAdditional3] ,
       [3EAdditional4] ,
       ISNULL(ctr_count.ctr_count, 0) AS [3E Country(ies)] ,                              --
       NULL AS [3E Entity Created Date] ,
       [TimeStamp] AS [3E Entity Last Modified Date] ,
       ISNULL(mat_count.mat_count, 0) AS [3E Number of Matters (Open & Closed Matters)] , --
       ISNULL(sites_count.sites_count, 0) AS [3E Number of Site Links] ,                  --
       ISNULL([Number of Clients Links], 0) AS [3E Number of Clients Links] ,
       ISNULL([Number Payor Links], 0) AS [3E Number of Payer Links] ,
       ISNULL([Number Payee Links], 0) AS [3E Number of Payee Links] ,
	   ISNULL([Number Vendor Links], 0) AS [3E Number of Vendor Links] ,
       ISNULL([Number User Links], 0) AS [3E Number of User Links] ,
	   ISNULL([Number of Bank Links],0) AS [3E Number of Bank Links],
       NULL AS [Billings for clients in the last 3 yrs (Profit Costs)],                    --?
	   dim_client.dim_client_key [Interaction UCI]
	   ,CASE WHEN existinInteraction=1 THEN 'Yes' ELSE 'No' END  AS [existinInteraction]
INTO dbo.EntityMergeReportSteHep
FROM   MS_Prod.config.dbContact WITH ( NOLOCK )
       LEFT OUTER JOIN MS_Prod.config.dbClient WITH ( NOLOCK ) ON dbcontact.contID = dbClient.clDefaultContact
       LEFT OUTER JOIN (   SELECT   clID ,
                                    COUNT(1) AS MSNumberMatters
                           FROM     MS_Prod.config.dbFile WITH ( NOLOCK )
                           GROUP BY clID ) AS Matters ON dbClient.clID = Matters.clID
       LEFT OUTER JOIN (   SELECT   contID ,
                                    COUNT(1) AS MSNumberAssociates
                           FROM     MS_Prod.config.dbAssociates WITH ( NOLOCK )
                           GROUP BY contID ) AS Associates ON dbcontact.contID = Associates.contID
       LEFT OUTER JOIN (   SELECT   ContID ,
                                    COUNT(1) AS NumberFEDAssociates
                           FROM     MS_Prod.dbo.udClientContactBridgingTable AS bridge WITH ( NOLOCK )
                                    INNER JOIN axxia01.dbo.invol ON FedClientNumber = entity_code COLLATE DATABASE_DEFAULT
                           GROUP BY ContID ) AS FedEntities ON dbcontact.contID = FedEntities.ContID
       LEFT OUTER JOIN (   SELECT   contID ,
                                    COUNT(1) AS [Number of Contact Links]
                           FROM     MS_Prod.dbo.dbContactLinks WITH ( NOLOCK )
                           GROUP BY contID ) AS LinkedContacts ON dbcontact.contID = LinkedContacts.contID
       LEFT OUTER JOIN MS_Prod.dbo.dbAddress ON contDefaultAddress = dbAddress.addID
       LEFT OUTER JOIN (   SELECT   contID AS contID ,
                                    COUNT(1) AS [Number of Site Links]
                           FROM     [MS_Prod].[dbo].[dbContactAddresses] WITH ( NOLOCK )
                           GROUP BY contID ) AS SiteLinks ON dbcontact.contID = SiteLinks.contID
       --------------------- 3E
       LEFT OUTER JOIN TE_3E_Prod.dbo.Entity ON dbcontact.contExtID = EntIndex
       LEFT OUTER JOIN (   SELECT   Entity ,
                                    COUNT(1) AS [Number Payor Links]
                           FROM     TE_3E_Prod.dbo.Payor WITH ( NOLOCK )
                           GROUP BY Entity ) AS Payor ON Entity.EntIndex = Payor.Entity
       LEFT OUTER JOIN (   SELECT   Entity ,
                                    COUNT(1) AS [Number Payee Links]
                           FROM     TE_3E_Prod.dbo.Payee WITH ( NOLOCK )
                           GROUP BY Entity ) AS Payee ON Entity.EntIndex = Payee.Entity
						   
						          LEFT OUTER JOIN (   SELECT   Entity ,
                                    COUNT(1) AS [Number Vendor Links]
                           FROM     TE_3E_Prod.dbo.Vendor WITH ( NOLOCK )
                           GROUP BY Entity ) AS VendorLinks ON Entity.EntIndex = VendorLinks.Entity
       LEFT OUTER JOIN (   SELECT   Entity ,
                                    COUNT(1) AS [Number User Links]
                           FROM     TE_3E_Prod.dbo.Timekeeper WITH ( NOLOCK )
                           GROUP BY Entity ) AS UserLinks ON Entity.EntIndex = UserLinks.Entity
       LEFT OUTER JOIN (   SELECT   Entity ,
                                    COUNT(1) AS [Number of Clients Links]
                           FROM     TE_3E_Prod.dbo.Client WITH ( NOLOCK )
                           GROUP BY Entity ) AS Client ON Entity.EntIndex = Client.Entity
       LEFT OUTER JOIN (   SELECT   Entity ,
                                    COUNT(1) AS [Number of Bank Links]
                           FROM     TE_3E_Prod.dbo.Bank WITH ( NOLOCK )
                           GROUP BY Entity ) AS Bank ON Entity.EntIndex = Bank.Entity
						   LEFT OUTER JOIN (   SELECT Entity.EntIndex AS EntNo ,
                                  FormattedString ,
                                  REPLACE(
                                      REPLACE(
                                          ( ISNULL(RTRIM(Street), '') + ' '
                                            + ISNULL(RTRIM(Additional1), '')
                                            + ' ' + ISNULL(RTRIM(City), '')
                                            + ' ' + ISNULL(RTRIM(County), '')
                                            + ' ' + ISNULL(RTRIM(ZipCode), '')) ,
                                          '  ' ,
                                          ' ') ,
                                      '  ' ,
                                      ' ') AS [3EAddress] ,
                                  OrgName AS [3EOrgName] ,
                                  Street AS [3EStreet] ,
                                  City AS [3ECity] ,
                                  State AS [3EState] ,
                                  Country AS [3ECountry] ,
                                  ZipCode AS [3EZipCode] ,
                                  County AS [3ECounty] ,
                                  Additional1 AS [3EAdditional1] ,
                                  Additional2 AS [3EAdditional2] ,
                                  Additional3 AS [3EAdditional3] ,
                                  Additional4 AS [3EAdditional4]
 FROM TE_3E_Prod.dbo.Entity  
 INNER JOIN MS_Prod.config.dbContact WITH ( NOLOCK )
 ON dbcontact.contExtID = EntIndex
INNER JOIN TE_3E_Prod.dbo.Relate 
  ON EntIndex=Relate.SbjEntity
INNER JOIN TE_3E_Prod.dbo.Site
 ON TE_3E_Prod.dbo.Relate.RelIndex=Site.Relate
INNER JOIN TE_3E_Prod.dbo.Address a WITH ( NOLOCK ) ON site.Address = a.AddrIndex
WHERE site.IsDefault=1
--AND  contid=@contid

) AS def_site ON Entity.EntIndex = def_site.EntNo  --LEFT OUTER JOIN (   SELECT Relate ,
       --                           FormattedString ,
       --                           REPLACE(
       --                               REPLACE(
       --                                   ( ISNULL(RTRIM(Street), '') + ' '
       --                                     + ISNULL(RTRIM(Additional1), '')
       --                                     + ' ' + ISNULL(RTRIM(City), '')
       --                                     + ' ' + ISNULL(RTRIM(County), '')
       --                                     + ' ' + ISNULL(RTRIM(ZipCode), '')) ,
       --                                   '  ' ,
       --                                   ' ') ,
       --                               '  ' ,
       --                               ' ') AS [3EAddress] ,
       --                           OrgName AS [3EOrgName] ,
       --                           Street AS [3EStreet] ,
       --                           City AS [3ECity] ,
       --                           State AS [3EState] ,
       --                           Country AS [3ECountry] ,
       --                           ZipCode AS [3EZipCode] ,
       --                           County AS [3ECounty] ,
       --                           Additional1 AS [3EAdditional1] ,
       --                           Additional2 AS [3EAdditional2] ,
       --                           Additional3 AS [3EAdditional3] ,
       --                           Additional4 AS [3EAdditional4]
       --                    FROM   TE_3E_Prod.dbo.Site s WITH ( NOLOCK )
       --                           INNER JOIN TE_3E_Prod.dbo.Address a WITH ( NOLOCK ) ON s.Address = a.AddrIndex
       --                    WHERE  IsDefault = 1 ) AS def_site ON Entity.EntIndex = def_site.Relate
       LEFT OUTER JOIN (   SELECT   Relate ,
                                    COUNT(*) sites_count
                           FROM     TE_3E_Prod.dbo.Site WITH ( NOLOCK )
                           GROUP BY Relate ) AS sites_count ON Entity.EntIndex = sites_count.Relate
       LEFT OUTER JOIN (   SELECT   Relate ,
                                    COUNT(DISTINCT Country) ctr_count
                           FROM     TE_3E_Prod.dbo.Site s WITH ( NOLOCK )
                                    INNER JOIN TE_3E_Prod.dbo.Address a WITH ( NOLOCK ) ON s.Address = a.AddrIndex
                           GROUP BY Relate ) ctr_count ON Entity.EntIndex = ctr_count.Relate
       LEFT OUTER JOIN (   SELECT   Entity ,
                                    COUNT(*) mat_count
                           FROM     TE_3E_Prod.dbo.Client c WITH ( NOLOCK )
                                    INNER JOIN TE_3E_Prod.dbo.Matter m WITH ( NOLOCK ) ON c.ClientIndex = m.Client
                           GROUP BY Entity ) mat_count ON Entity.EntIndex = mat_count.Entity
       LEFT JOIN (   SELECT DISTINCT dbContactLinks.contID ,
                            'Yes' AS [EMPR Link]
                     FROM   MS_Prod.dbo.dbContactLinks WITH ( NOLOCK )
                            LEFT JOIN MS_Prod.config.dbContact WITH ( NOLOCK ) ON dbcontact.contID = dbContactLinks.contLinkID
                     WHERE  contLinkCode = 'EMPR' ) contactlinks ON dbcontact.contID = contactlinks.contID
	  LEFT OUTER JOIN (SELECT dim_client.contactid,dim_client.dim_client_key,Interaction.existinInteraction FROM red_dw.dbo.dim_client
					   LEFT OUTER JOIN (select DISTINCT UCI as dim_client_key 
,1 AS existinInteraction
FROM [svr-liv-iasq-01].InterAction.weightmans.vwContacts  WITH(NOLOCK)
--WHERE UCI IS NOT NULL
WHERE ISNUMERIC(UCI)=1
) AS Interaction
 ON Interaction.dim_client_key = dim_client.dim_client_key
  ) AS dim_client
	  ON MS_Prod.config.dbContact.contID = dim_client.contactid
WHERE 

clNo IS NULL   
AND dbContact.contID NOT IN (
4992957,4992972,4992973,4992998,4993056,
4993083,4993131,4993152,4993170,5254111)
AND EntIndex IS NOT NULL

AND ISNULL(MSNumberMatters, 0) = 0
AND ISNULL([Number of Contact Links], 0) = 0
AND ISNULL(MSNumberAssociates, 0) = 0
AND ISNULL(mat_count.mat_count, 0) = 0
AND ISNULL([Number of Clients Links], 0) = 0
AND ISNULL([Number Payor Links], 0)  = 0
AND ISNULL([Number Payee Links], 0)  = 0
AND ISNULL([Number Vendor Links], 0) = 0
AND ISNULL([Number User Links], 0) = 0
AND ISNULL(existinInteraction,0) <>1
AND ISNULL([Number of Bank Links],0)=0
AND dbContact.Created <='2019-04-30'
OPTION(QUERYTRACEON 9481)


END

GO
