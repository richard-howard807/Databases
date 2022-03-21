CREATE TABLE [dbo].[ds_sh_axxia_kdclicon]
(
[kc_client] [char] (8) COLLATE Latin1_General_BIN NULL,
[kc_orgidn] [char] (8) COLLATE Latin1_General_BIN NULL,
[kc_rectyp] [char] (1) COLLATE Latin1_General_BIN NULL,
[kc_addrid] [int] NULL,
[kc_salutn] [char] (30) COLLATE Latin1_General_BIN NULL,
[kc_qualif] [char] (30) COLLATE Latin1_General_BIN NULL,
[kc_fornam] [char] (30) COLLATE Latin1_General_BIN NULL,
[kc_suppid] [char] (8) COLLATE Latin1_General_BIN NULL,
[kc_casefl] [char] (1) COLLATE Latin1_General_BIN NULL,
[kc_casinv] [char] (1) COLLATE Latin1_General_BIN NULL,
[kc_mktdet] [char] (1) COLLATE Latin1_General_BIN NULL,
[kc_mkthis] [char] (1) COLLATE Latin1_General_BIN NULL,
[kc_mktper] [char] (1) COLLATE Latin1_General_BIN NULL,
[kc_tmprec] [smallint] NULL,
[kc_noteid] [int] NULL,
[dss_create_time] [datetime] NULL,
[dss_update_time] [datetime] NULL
) ON [DS_TAB]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ds_sh_axxia_kdclicon_idx_A] ON [dbo].[ds_sh_axxia_kdclicon] ([kc_client]) ON [DS_IDX]
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was created in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_axxia_kdclicon', 'COLUMN', N'dss_create_time'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_axxia_kdclicon', 'COLUMN', N'dss_update_time'
GO
