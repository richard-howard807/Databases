SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[MSPartner]

AS


select fe.feeusrID as MSID,dbu.usrFullName as Name, td.timekeeperlkup as TKID
from MSFeeEarner fe
INNER JOIN [3ETimeKeeper] t on fe.feeExtID = t.tkprindex
Inner Join [3ETkprDate] TD    on fe.feeExtID = TD.timekeeperlkup
Inner Join [3EnxUser] U              on U.NxUserID = T.TRE_User
Inner Join [3ETNxFWKUser]   fwk  on fwk.NxFWKUserID = U.NxUserID
INNER JOIN [3ETSection] s      on s.code = td.Section
INNER JOIN [MSUsers] dbu on  fe.[feeusrID] = dbu.usrID
Where getDate() BETWEEN (NxStartDate ) AND (NxEndDate)
and t.tre_user is not null
and t.tkprstatus = 'Active'
and TD.Title in ('EQP','FSP','SEP')
GO
