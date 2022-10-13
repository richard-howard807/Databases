SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [audit].[SDNSanctionsDrillDown] 
(
@ID BIGINT 
)

AS
BEGIN
SELECT sdnEntry.sdnEntry_Id AS sdnEntry_Id
,uid_sd.uid AS uid
,firstName.firstName AS [First Name]
,lastName.lastName AS [Last Name]
,title.title AS [Title]
,FirtNameAlias
,LastNameAlias
,DOB AS dateofBirth
,program
,address1
,address2
,address3
,postalCode
,city
,country
FROM SanctionsList.[dbo].[sdnEntry_sdn] AS sdnEntry
LEFT OUTER JOIN SanctionsList.dbo.uid_sdn AS uid_sd
 ON sdnEntry.sdnEntry_Id=uid_sd.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].firstName_sdn AS firstName ON sdnEntry.sdnEntry_Id=firstName.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].lastName_sdn AS lastName ON sdnEntry.sdnEntry_Id=lastName.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].title_sdn AS title ON sdnEntry.sdnEntry_Id=title.sdnEntry_Id
LEFT OUTER JOIN (select sdnEntry_Id
,CAST(STUFF((   SELECT ',' + RTRIM(dateOfBirth)
				FROM (SELECT sdnEntry_Id,b.dateOfBirth
						FROM SanctionsList.dbo.dateOfBirthList_sdn AS a
						INNER JOIN SanctionsList.dbo.dateOfBirthitem_sdn AS b
						ON b.dateOfBirthList_Id=a.dateOfBirthList_Id) te
				WHERE a.sdnEntry_Id = te.sdnEntry_Id 
				
				FOR XML PATH ('')  ),1,1,'')  AS VARCHAR(MAX))as [DOB]
    
     FROM (SELECT sdnEntry_Id  
						FROM SanctionsList.dbo.dateOfBirthList_sdn AS a
						INNER JOIN SanctionsList.dbo.dateOfBirthitem_sdn AS b
						ON b.dateOfBirthList_Id=a.dateOfBirthList_Id) AS a
  GROUP BY a.sdnEntry_Id) AS DOB
   ON sdnEntry.sdnEntry_Id=DOB.sdnEntry_Id
  LEFT OUTER JOIN (
select sdnEntry_Id
,CAST(STUFF((   SELECT ',' + RTRIM(program)
				FROM (SELECT sdnEntry_Id ,program
						FROM SanctionsList.dbo.programList_sdn AS a
						INNER JOIN SanctionsList.dbo.program_sdn AS b
						ON b.programList_Id=a.programList_Id) te
				WHERE a.sdnEntry_Id = te.sdnEntry_Id 
				
				FOR XML PATH ('')  ),1,1,'')  AS VARCHAR(MAX))as [Program]
    
     FROM (SELECT sdnEntry_Id  
						FROM SanctionsList.dbo.programList_sdn AS a
						INNER JOIN SanctionsList.dbo.program_sdn AS b
						ON b.programList_Id=a.programList_Id) AS a
  GROUP BY a.sdnEntry_Id
  
  ) AS Program
   ON sdnEntry.sdnEntry_Id=Program.sdnEntry_Id
LEFT OUTER JOIN (SELECT sdnEntry_Id,firstName AS FirtNameAlias,lastName AS LastNameAlias
FROM SanctionsList.dbo.akaList_sdn
INNER JOIN SanctionsList.dbo.aka_sdn ON akaList_sdn.akaList_Id=aka_sdn.akaList_Id) AS Alias
 ON sdnEntry.sdnEntry_Id=Alias.sdnEntry_Id
LEFT OUTER JOIN (SELECT sdnEntry_Id,address1,address2,address3,city,postalCode,country,stateOrProvince FROM SanctionsList.dbo.addressList_sdn AS a
INNER JOIN SanctionsList.dbo.address_sdn AS b
 ON a.addressList_Id=b.addressList_Id
) AS Addresses
 ON sdnEntry.sdnEntry_Id=Addresses.sdnEntry_Id

WHERE uid_sd.uid=@ID

END

GO
