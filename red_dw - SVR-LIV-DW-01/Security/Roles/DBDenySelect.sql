CREATE ROLE [DBDenySelect]
AUTHORIZATION [dbo]
GO
ALTER ROLE [DBDenySelect] ADD MEMBER [SBC\DEV-WEBAPP-OneToOne]
GO
ALTER ROLE [DBDenySelect] ADD MEMBER [SBC\SQL - SD ShareFile Document Report]
GO
ALTER ROLE [DBDenySelect] ADD MEMBER [SBC\SQL ROLE - DS_BI_DEVELOPER]
GO
ALTER ROLE [DBDenySelect] ADD MEMBER [SBC\SQL ROLE - DS_MI_ANALYST]
GO
ALTER ROLE [DBDenySelect] ADD MEMBER [SBC\SQL ROLE - IS_WEB_DEVELOPER]
GO
ALTER ROLE [DBDenySelect] ADD MEMBER [SBC\UAT-WEBAPP- OneToOne]
GO