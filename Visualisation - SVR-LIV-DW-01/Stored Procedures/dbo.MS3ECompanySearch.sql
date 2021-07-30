SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[MS3ECompanySearch]
(
@Search NVARCHAR(MAx)
)
AS 

BEGIN

DECLARE @lf CHAR(1) SET @lf = CHAR(10);
DECLARE @cr CHAR(1) SET @cr = CHAR(13);
DECLARE @tab CHAR(1) SET @tab = CHAR(9);
SELECT 
	ms_entity_number,
	IQ1.Telephone, 
	IQ1.Email,
	combined + N' ' + IQ1.Telephone + N' ' + IQ1.Email AS combined,
	IQ2.InteractionUCI,
	IQ2.existinInteraction,
	ms_entity_number AS [MS Entity Number],
	[MS Entity Name],
	[MS ContType],
	[MS Client Number],
	[MS Client Name],
	[MS Default Site Address],
	[MS Entity Create Date],
	[MS Entity Last Modified Date],
	[MS Number of Matters (Open & Closed Matters)],
	[MS Number of Site Links],
	[MS Number of Contact Links],
	[MS Number of Associate Links],
	[MS Number of FED Entities],
	[3E Entity Number] ,
	[3E Default Site Address] ,                                         
	[3EOrgName] ,
	[3E Country(ies)] ,                              	
	[3E Entity Last Modified Date] ,
	[3E Number of Matters (Open & Closed Matters)] , 
	[3E Number of Site Links] ,                  
	[3E Number of Clients Links] ,
	[3E Number of Payer Links] ,
	[3E Number of Payee Links] ,
	[3E Number of Vendor Links] ,
	[3E Number of User Links] ,               
	[Interaction UCI] 
	FROM 
	(
SELECT 
		dbcontact.contID AS ms_entity_number 
		,REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(LOWER(COALESCE(Telephone.Telephone, N'')))), @cr, N''), @lf, N''), @tab, N'') AS Telephone
		,REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(LOWER(COALESCE(Email.Email, N'')))), @cr, N''), @lf, N''), @tab, N'') AS Email
		,contName AS [MS Entity Name] ,
		dbcontact.contTypeCode AS [MS ContType] ,
		clNo AS [MS Client Number] ,
		clName AS [MS Client Name] ,
		LOWER(LTRIM(RTRIM(REPLACE(contName, char(9), N'')))) + N' '
		+ LOWER(LTRIM(RTRIM(REPLACE(REPLACE(
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
				REPLACE(RTRIM(addPostcode), N' ', N'')) ,
			'  ' ,
			' ') ,
		'  ' ,
		' '), char(9), N'')))) AS combined,

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

		RTRIM(addPostcode) AS MSPostcode ,
		dbcontact.Created AS [MS Entity Create Date],
			dbcontact.Updated AS [MS Entity Last Modified Date] ,
			ISNULL(MSNumberMatters, 0) AS [MS Number of Matters (Open & Closed Matters)] ,
			ISNULL([Number of Site Links], 0) AS [MS Number of Site Links] ,
		ISNULL([Number of Contact Links], 0) AS [MS Number of Contact Links] ,
		ISNULL(MSNumberAssociates, 0) AS [MS Number of Associate Links] ,
		ISNULL(NumberFEDAssociates, 0) AS [MS Number of FED Entities] ,
		EntIndex AS [3E Entity Number] ,
		[3EAddress] AS [3E Default Site Address] ,                                         --
		[3EOrgName] ,
		ISNULL(ctr_count.ctr_count, 0) AS [3E Country(ies)] ,                              --
		[TimeStamp] AS [3E Entity Last Modified Date] ,
		ISNULL(mat_count.mat_count, 0) AS [3E Number of Matters (Open & Closed Matters)] , --
		ISNULL(sites_count.sites_count, 0) AS [3E Number of Site Links] ,                  --
		ISNULL([Number of Clients Links], 0) AS [3E Number of Clients Links] ,
		ISNULL([Number Payor Links], 0) AS [3E Number of Payer Links] ,
		ISNULL([Number Payee Links], 0) AS [3E Number of Payee Links] ,
		ISNULL([Number Vendor Links], 0) AS [3E Number of Vendor Links] ,
		ISNULL([Number User Links], 0) AS [3E Number of User Links] ,
		dim_client.dim_client_key [Interaction UCI],
		NULL AS Ignore
FROM ms_prod.config.dbContact WITH(NOLOCK)
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
		LEFT OUTER JOIN (SELECT 
	Telephone.contID,
	Telephone.contNumber AS Telephone 

FROM 
(SELECT contID,contNumber,ROW_NUMBER() OVER (PARTITION BY contID ORDER BY contDefaultOrder ASC)  AS xorder
FROM MS_Prod.dbo.dbContactNumbers WHERE contCode='TELEPHONE' AND contActive=1
) AS Telephone
WHERE Telephone.xorder=1) AS Telephone
ON Telephone.contID = dbContact.contID
LEFT OUTER JOIN (SELECT 
	Email.contID,
	Email.Email

FROM 
(
SELECT contID,contEmail AS Email ,ROW_NUMBER() OVER (PARTITION BY contID ORDER BY contDefaultOrder ASC)  AS xorder
FROM MS_Prod.dbo.dbContactEmails WHERE   contActive=1
) AS Email
WHERE Email.xorder=1) AS Email
 ON   Email.contID = dbContact.contID
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

								) AS def_site ON Entity.EntIndex = def_site.EntNo
--		   LEFT OUTER JOIN (   SELECT   Relate ,
--										COUNT(*) sites_count
--							   FROM     TE_3E_Prod.dbo.Site WITH ( NOLOCK )
--							   GROUP BY Relate ) AS sites_count ON Entity.EntIndex = sites_count.Relate
LEFT OUTER JOIN ( SELECT Entity.EntIndex AS EntNo , COUNT(1) AS sites_count
				 FROM TE_3E_Prod.dbo.Entity  
				 INNER JOIN MS_Prod.config.dbContact WITH ( NOLOCK )
				ON dbcontact.contExtID = EntIndex
				INNER JOIN TE_3E_Prod.dbo.Relate 
				  ON EntIndex=Relate.SbjEntity
				INNER JOIN TE_3E_Prod.dbo.Site
				ON TE_3E_Prod.dbo.Relate.RelIndex=Site.Relate
				INNER JOIN TE_3E_Prod.dbo.Address a WITH ( NOLOCK ) ON site.Address = a.AddrIndex
GROUP BY EntIndex) AS sites_count ON Entity.EntIndex = sites_count.EntNo

--		   LEFT OUTER JOIN (   SELECT   Relate ,
--										COUNT(DISTINCT Country) ctr_count
--							   FROM     TE_3E_Prod.dbo.Site s WITH ( NOLOCK )
--										INNER JOIN TE_3E_Prod.dbo.Address a WITH ( NOLOCK ) ON s.Address = a.AddrIndex
--							   GROUP BY Relate ) ctr_count ON Entity.EntIndex = ctr_count.Relate
LEFT OUTER JOIN 
(
SELECT Entity.EntIndex AS EntNo , COUNT(DISTINCT Country) ctr_count
				 FROM TE_3E_Prod.dbo.Entity  
				 INNER JOIN MS_Prod.config.dbContact WITH ( NOLOCK )
				ON dbcontact.contExtID = EntIndex
				INNER JOIN TE_3E_Prod.dbo.Relate 
				  ON EntIndex=Relate.SbjEntity
				INNER JOIN TE_3E_Prod.dbo.Site
				ON TE_3E_Prod.dbo.Relate.RelIndex=Site.Relate
				INNER JOIN TE_3E_Prod.dbo.Address a WITH ( NOLOCK ) ON site.Address = a.AddrIndex
GROUP BY EntIndex
)  AS ctr_count ON Entity.EntIndex = ctr_count.EntNo
		   LEFT OUTER JOIN (   SELECT   Entity ,
										COUNT(*) mat_count
							   FROM     TE_3E_Prod.dbo.Client c WITH ( NOLOCK )
										INNER JOIN TE_3E_Prod.dbo.Matter m WITH ( NOLOCK ) ON c.ClientIndex = m.Client
							   GROUP BY Entity ) mat_count ON Entity.EntIndex = mat_count.Entity
--		   LEFT JOIN (   SELECT DISTINCT dbContactLinks.contID ,
--								'Yes' AS [EMPR Link]
--						 FROM   MS_Prod.dbo.dbContactLinks WITH ( NOLOCK )
--								LEFT JOIN MS_Prod.config.dbContact WITH ( NOLOCK ) ON dbcontact.contID = dbContactLinks.contLinkID
--						 WHERE  contLinkCode = 'EMPR' ) contactlinks ON dbcontact.contID = contactlinks.contID
		  LEFT OUTER JOIN red_dw.dbo.dim_client dim_client ON MS_Prod.config.dbContact.contID = dim_client.contactid
WHERE contTypeCode = N'ORGANISATION'
AND Entity.EntIndex IS NOT NULL
AND UPPER(contName)  LIKE'%'+UPPER( @Search) + '%'
) AS IQ1
LEFT OUTER JOIN --#temp ON IQ1.ms_entity_number = #temp.contactid
(
	SELECT 
		dim_client.contactid
		,dim_client.dim_client_key AS InteractionUCI
		,Interaction.existinInteraction
	FROM red_dw.dbo.dim_client
	LEFT OUTER JOIN (
	SELECT DISTINCT UCI AS dim_client_key 
,1 AS existinInteraction
FROM [svr-liv-iasq-01].InterAction.weightmans.vwContacts  WITH(NOLOCK)
WHERE ISNUMERIC(UCI)=1
) AS Interaction
ON Interaction.dim_client_key = dim_client.dim_client_key

) AS IQ2
ON IQ1.ms_entity_number = IQ2.contactid

END
GO
