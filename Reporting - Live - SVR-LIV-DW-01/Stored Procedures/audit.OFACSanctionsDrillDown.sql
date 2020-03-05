SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [audit].[OFACSanctionsDrillDown] 
(
@ID BIGINT 
)

AS
BEGIN
SELECT sdnEntry.sdnEntry_Id AS sdnEntry_Id
,sdnListsdnEntry.uid AS uid
,firstName.firstName AS [First Name]
,lastName.lastName AS [Last Name]
,title.title AS [Title]
,FirtNameAlias
,LastNameAlias
,dateofBirth
,program
,address1
,address2
,address3
,postalCode
,city
,country
FROM SanctionsList.[dbo].[sdnEntry] AS sdnEntry
INNER JOIN  SanctionsList.[dbo].[sdnListsdnEntry] AS sdnListsdnEntry
 ON sdnEntry.sdnEntry_Id=sdnListsdnEntry.sdnEntry_id
LEFT OUTER JOIN SanctionsList.[dbo].firstName ON sdnEntry.sdnEntry_Id=firstName.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].lastName ON sdnEntry.sdnEntry_Id=lastName.sdnEntry_Id
LEFT OUTER JOIN SanctionsList.[dbo].title ON sdnEntry.sdnEntry_Id=title.sdnEntry_Id
LEFT OUTER JOIN (SELECT sdnEntry_Id,firstName AS FirtNameAlias,lastName AS LastNameAlias
FROM SanctionsList.dbo.akaList
INNER JOIN SanctionsList.dbo.aka ON akaList.akaList_Id=aka.akaList_Id) AS Alias
 ON sdnEntry.sdnEntry_Id=Alias.sdnEntry_Id
LEFT OUTER JOIN (SELECT sdnEntry_Id,dateOfBirthitem.dateofBirth
FROM SanctionsList.dbo.dateOfBirthList
INNER JOIN SanctionsList.dbo.dateOfBirthitem ON dateOfBirthList.dateOfBirthList_Id=dateOfBirthitem.dateOfBirthList_Id) AS DateOfBirth
 ON sdnEntry.sdnEntry_Id=dateofBirth.sdnEntry_Id
LEFT OUTER JOIN (SELECT sdnEntry_Id,program FROM SanctionsList.dbo.programList
INNER JOIN SanctionsList.dbo.program ON programList.programList_Id=program.programList_Id) AS Program
 ON sdnEntry.sdnEntry_Id=Program.sdnEntry_Id
LEFT OUTER JOIN (SELECT addressList.sdnEntry_Id
,address1
,address2
,address3
,postalCode
,city
,stateOrProvince
,country

FROM SanctionsList.dbo.addressList
INNER JOIN SanctionsList.dbo.address ON addressList.addressList_Id=address.addressList_Id
LEFT OUTER JOIN SanctionsList.dbo.address1  ON address.address_Id=address1.address_Id
LEFT OUTER JOIN SanctionsList.dbo.address2  ON address.address_Id=address2.address_Id
LEFT OUTER JOIN SanctionsList.dbo.address3  ON address.address_Id=address3.address_Id
LEFT OUTER JOIN SanctionsList.dbo.postcode  ON address.address_Id=postcode.address_Id
LEFT OUTER JOIN SanctionsList.dbo.city  ON address.address_Id=city.address_Id
LEFT OUTER JOIN SanctionsList.dbo.country  ON address.address_Id=country.address_Id
LEFT OUTER JOIN SanctionsList.dbo.stateOrProvince ON address.address_Id=stateOrProvince.address_Id
) AS Addresses
 ON sdnEntry.sdnEntry_Id=Addresses.sdnEntry_Id
WHERE sdnListsdnEntry.uid = @ID

END

GO
