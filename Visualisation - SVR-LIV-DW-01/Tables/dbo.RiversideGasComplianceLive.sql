CREATE TABLE [dbo].[RiversideGasComplianceLive]
(
[Firm Instructed] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[UPRN] [float] NULL,
[Region] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[LGSR Expiry] [datetime] NULL,
[Tenant's Full Address] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenant's Full Address 2] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenant's Full Address 3] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenant's Postcode (added so we can show the instructions on a ma] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenant's Name _(use separate line for joint tenant)__] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date LBA issued] [datetime] NULL,
[LBA expiry date] [datetime] NULL,
[Is this a joint tenancy? (Y/N)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Status (Live/Completed)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date billed] [datetime] NULL,
[Fees Billed exc# VAT] [money] NULL
) ON [PRIMARY]
GO
