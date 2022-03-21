CREATE TABLE [dbo].[ds_sh_axxia_fmsaddr]
(
[fmsaddr_uid] [int] NOT NULL IDENTITY(1, 1),
[source_system_id] [int] NULL,
[fm_addnum] [int] NULL,
[effective_start_date] [datetime] NULL,
[effective_end_date] [datetime] NULL,
[current_flag] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[original_cdc_date] [datetime] NULL,
[deleted_flag] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[operation] [int] NULL,
[sequence_number] [binary] (10) NOT NULL,
[fm_addtyp] [char] (2) COLLATE Latin1_General_BIN NULL,
[fm_clinum] [char] (8) COLLATE Latin1_General_BIN NULL,
[fm_matnum] [char] (8) COLLATE Latin1_General_BIN NULL,
[fm_contac] [char] (30) COLLATE Latin1_General_BIN NULL,
[fm_addree] [char] (40) COLLATE Latin1_General_BIN NULL,
[fm_addli1] [char] (40) COLLATE Latin1_General_BIN NULL,
[fm_addli2] [char] (40) COLLATE Latin1_General_BIN NULL,
[fm_addli3] [char] (40) COLLATE Latin1_General_BIN NULL,
[fm_addli4] [char] (40) COLLATE Latin1_General_BIN NULL,
[fm_poscod] [char] (12) COLLATE Latin1_General_BIN NULL,
[fm_addph1] [char] (20) COLLATE Latin1_General_BIN NULL,
[fm_addph2] [char] (20) COLLATE Latin1_General_BIN NULL,
[fm_addph3] [char] (20) COLLATE Latin1_General_BIN NULL,
[fm_addfax] [char] (20) COLLATE Latin1_General_BIN NULL,
[fm_addlex] [char] (15) COLLATE Latin1_General_BIN NULL,
[fm_adddxn] [char] (20) COLLATE Latin1_General_BIN NULL,
[fm_salute] [char] (30) COLLATE Latin1_General_BIN NULL,
[fm_matid] [int] NULL,
[dss_update_time] [datetime] NULL
) ON [DS_TAB]
GO
CREATE UNIQUE NONCLUSTERED INDEX [ds_sh_axxia_fmsaddr_idx_A] ON [dbo].[ds_sh_axxia_fmsaddr] ([source_system_id], [fm_addnum], [sequence_number]) ON [DS_IDX]
GO
DENY SELECT ON  [dbo].[ds_sh_axxia_fmsaddr] TO [DBDenySelect]
GO
DENY SELECT ON  [dbo].[ds_sh_axxia_fmsaddr] TO [lnksvrdatareader]
GO
DENY SELECT ON  [dbo].[ds_sh_axxia_fmsaddr] TO [lnksvrdatareader_artdb]
GO
DENY SELECT ON  [dbo].[ds_sh_axxia_fmsaddr] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01_Limited]
GO
EXEC sp_addextendedproperty N'Comment', N'This is the data store for the fmsaddr table.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_axxia_fmsaddr', NULL, NULL
GO
EXEC sp_addextendedproperty N'Comment', N'Operation value can be:
1: Delete
2: Insert
4: Update', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_axxia_fmsaddr', 'COLUMN', N'deleted_flag'
GO
EXEC sp_addextendedproperty N'Comment', N'Date and time the row was updated in the data warehouse.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_axxia_fmsaddr', 'COLUMN', N'dss_update_time'
GO
EXEC sp_addextendedproperty N'Comment', N'generated from cdc date, but modified by a custom procedure as well.
If the address has no entry started with 1900-01-01, then the first record effective start date will be modified.', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_axxia_fmsaddr', 'COLUMN', N'effective_start_date'
GO
EXEC sp_addextendedproperty N'Comment', N'Operation value can be:
1: Delete
2: Insert
4: Update', 'SCHEMA', N'dbo', 'TABLE', N'ds_sh_axxia_fmsaddr', 'COLUMN', N'operation'
GO
