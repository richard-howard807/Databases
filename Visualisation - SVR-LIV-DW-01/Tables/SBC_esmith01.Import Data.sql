CREATE TABLE [SBC\esmith01].[Import Data]
(
[Firm Instructed] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[UPRN] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Region] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[LGSR Expiry] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenant's Full Address] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenant's Full Address 2] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenant's Full Address 3] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenant's Postcode (added so we can show the instructions on a ma] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Tenant's Name _(use separate line for joint tenant)__] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date LBA issued] [datetime] NULL,
[LBA expiry date] [datetime] NULL,
[Is this a joint tenancy? (Y/N)] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Date billed] [datetime] NULL,
[Fees Billed exc# VAT] [money] NULL
) ON [PRIMARY]
GO
