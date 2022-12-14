SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_dim_claimant_thirdparty_involvement]
AS 

SELECT  [dim_claimant_thirdpart_key]
--      ,[client_code]
--      ,[matter_number]
--      ,[claimant_1_key]
--      ,[claimant_2_key]
--      ,[claimant_3_key]
--      ,[claimant_4_key]
--      ,[claimantcostneg_2_key]
--      ,[claimantcostneg_1_key]
--      ,[claimantemploy_1_key]
--      ,[claimantemploy_2_key]
--      ,[claimantemploy_4_key]
--      ,[claimantemploy_3_key]
--      ,[claimantrep_4_key]
--      ,[claimantrep_3_key]
--      ,[claimantrep_2_key]
--      ,[claimantrep_1_key]
--      ,[claimantschool_1_key]
--      ,[claimantschool_2_key]
--      ,[claimantschool_3_key]
--      ,[claimantschool_4_key]
--      ,[claimantsols_4_key]
--      ,[claimantsols_3_key]
--      ,[claimantsols_2_key]
--      ,[claimantsols_1_key]
--      ,[familyrepsols_1_key]
--      ,[opponent_1_key]
--      ,[other_1_key]
--      ,[other_2_key]
--      ,[other_3_key]
--      ,[other_4_key]
--      ,[otherparty_4_key]
--      ,[otherparty_3_key]
--      ,[otherparty_2_key]
--      ,[otherparty_1_key]
--      ,[otherprosecuter_1_key]
--      ,[otherside_1_key]
--      ,[otherside_2_key]
--      ,[otherside_3_key]
--      ,[otherside_4_key]
--      ,[othersidesols_4_key]
--      ,[othersidesols_3_key]
--      ,[othersidesols_2_key]
--      ,[othersidesols_1_key]
--      ,[othertypepers_2_key]
--      ,[othertypepers_1_key]
--      ,[othertypepers_3_key]
--      ,[othertypepers_4_key]
--      ,[othpartyinscomp_1_key]
--      ,[othpartyinscomp_2_key]
--      ,[p20claimant_1_key]
--      ,[thirdparty_2_key]
--      ,[thirdparty_1_key]
--      ,[thirdparty_4_key]
--      ,[thirdparty_3_key]
--      ,[tpaccidentdriv_1_key]
--      ,[tpaccmancomp_1_key]
--      ,[tpaccount_1_key]
--      ,[tpaltvehprovide_1_key]
--      ,[tpexpertnonmed_1_key]
--      ,[tpexpertnonmed_2_key]
--      ,[tpexpertnonmed_4_key]
--      ,[tpexpertnonmed_3_key]
--      ,[tphirecomp_1_key]
--      ,[tpinformation_1_key]
--      ,[tpinformation_2_key]
--      ,[tpinsurer_1_key]
--      ,[tpphysio_1_key]
--      ,[tprepaircomp_1_key]
--      ,[tpsolicitors_1_key]
--      ,[tpsolicitors_2_key]
--      ,[tpsolicitors_4_key]
--      ,[tpsolicitors_3_key]
--      ,[tpstorereccomp_1_key]
--      ,[tpvehicleowner_1_key]
--      ,[tpvehownerins_1_key]
--      ,[dss_update_time]
      ,[claimant_name]
--      ,[claimantcostneg_name]
--      ,[claimantemploy_name]
--      ,[claimantrep_name]
--      ,[claimantschool_name]
      ,[claimantsols_name]
--      ,[familyrepsols_name]
--      ,[opponent_name]
--      ,[other_name]
--      ,[otherparty_name]
--      ,[otherprosecuter_name]
--      ,[otherside_name]
--      ,[othersidesols_name]
--      ,[othertypepers_name]
--      ,[othpartyinscomp_name]
--      ,[p20claimant_name]
--      ,[thirdparty_name]
--      ,[tpaccidentdriv_name]
--      ,[tpaccmancomp_name]
--      ,[tpaccount_name]
--      ,[tpaltvehprovide_name]
--      ,[tpexpertnonmed_name]
--      ,[tphirecomp_name]
--      ,[tpinformation_name]
--      ,[tpinsurer_name]
--      ,[tpphysio_name]
--      ,[tprepaircomp_name]
--      ,[tpsolicitors_name]
--      ,[tpstorereccomp_name]
--      ,[tpvehicleowner_name]
--      ,[tpvehownerins_name]
--      ,[claimant_reference]
--      ,[claimantcostneg_reference]
--      ,[claimantemploy_reference]
--      ,[claimantrep_reference]
--      ,[claimantschool_reference]
--      ,[claimantsols_reference]
--      ,[familyrepsols_reference]
--      ,[opponent_reference]
--      ,[other_reference]
--      ,[otherparty_reference]
--      ,[otherprosecuter_reference]
--      ,[otherside_reference]
--      ,[othersidesols_reference]
--      ,[othertypepers_reference]
--      ,[othpartyinscomp_reference]
--      ,[p20claimant_reference]
--      ,[thirdparty_reference]
--      ,[tpaccidentdriv_reference]
--      ,[tpaccmancomp_reference]
--      ,[tpaccount_reference]
--      ,[tpaltvehprovide_reference]
--      ,[tpexpertnonmed_reference]
--      ,[tphirecomp_reference]
--      ,[tpinformation_reference]
--      ,[tpinsurer_reference]
--      ,[tpphysio_reference]
--      ,[tprepaircomp_reference]
--      ,[tpsolicitors_reference]
--      ,[tpstorereccomp_reference]
--      ,[tpvehicleowner_reference]
--      ,[tpvehownerins_reference]
  FROM [red_dw].[dbo].[dim_claimant_thirdparty_involvement] WITH (NOLOCK)


GO
