int		g_iAdminFlag,
		g_iTypeStatistics,
		g_iMinimumPlayers,
		g_iMinCountKills,
		g_iDaysDeleteFromBase,
		g_iDaysDeleteFromBaseCalib,
		g_iDBReconnectCount,
		g_iGiveCalibration,
		g_iGiveKill,
		g_iGiveDeath,
		g_iGiveHeadShot,
		g_iGiveAssist,
		g_iGiveSuicide,
		g_iGiveTeamKill,
		g_iRoundWin,
		g_iRoundLose,
		g_iRoundMVP,
		g_iBombPlanted,
		g_iBombDefused,
		g_iBombDropped,
		g_iBombPickup,
		g_iHostageKilled,
		g_iHostageRescued,
		g_iShowExp[20],
		g_iBonus[11];
float		g_fKillCoeff = 0.00,
		g_fWeaponsCoeff[47],
		g_fDBReconnectTime = 0.0;
bool		g_bDebug = false,
		g_bSpawnMessage = false,
		g_bRankMessage = false,
		g_bUsualMessage = false,
		g_bInventory = false,
		g_bResetRank = false,
		g_bWarmUpCheck = false;
char		g_sDebugFile[PLATFORM_MAX_PATH],
		g_sTableName[32],
		g_sShowRank[20][192];

void SetSettings(bool bReload)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/settings.ini");
	KeyValues hLR_Settings = new KeyValues("LR_Settings");

	if(!hLR_Settings.ImportFromFile(sPath) || !hLR_Settings.GotoFirstSubKey())
	{
		CrashLR("(%s) is not found", sPath);
	}

	hLR_Settings.Rewind();

	if(hLR_Settings.JumpToKey("MainSettings"))
	{
		char sBuffer[32];
		if(!bReload)
		{
			hLR_Settings.GetString("lr_table", g_sTableName, sizeof(g_sTableName), "lvl_base");
			hLR_Settings.GetString("lr_flag_adminmenu", sBuffer, sizeof(sBuffer), "z"); g_iAdminFlag = ReadFlagString(sBuffer);
			g_bDebug = view_as<bool>(hLR_Settings.GetNum("lr_debug", 0));

			if(g_bDebug)
			{
				BuildPath(Path_SM, g_sDebugFile, sizeof(g_sDebugFile), "logs/levelsranks_debug.log");
			}

			g_iTypeStatistics = hLR_Settings.GetNum("lr_type_statistics", 0);
		}

		g_iMinimumPlayers = hLR_Settings.GetNum("lr_minplayers_count", 4);
		g_iMinCountKills = hLR_Settings.GetNum("lr_min_kd", 0);

		g_bInventory = view_as<bool>(hLR_Settings.GetNum("lr_show_settings", 0));
		g_bResetRank = view_as<bool>(hLR_Settings.GetNum("lr_show_resetmystats", 1));
		g_bUsualMessage = view_as<bool>(hLR_Settings.GetNum("lr_show_usualmessage", 1));
		g_bSpawnMessage = view_as<bool>(hLR_Settings.GetNum("lr_show_spawnmessage", 1));
		g_bRankMessage = view_as<bool>(hLR_Settings.GetNum("lr_show_rankmessage", 1));
		g_bWarmUpCheck = view_as<bool>(hLR_Settings.GetNum("lr_block_warmup", 1));
		
		g_iDaysDeleteFromBase = hLR_Settings.GetNum("lr_db_cleaner", 15);
		g_iDaysDeleteFromBaseCalib = hLR_Settings.GetNum("lr_db_cleaner_calibration", 3);
		g_iDBReconnectCount = hLR_Settings.GetNum("lr_dbreconnect_count", 5);
		g_fDBReconnectTime = hLR_Settings.GetFloat("lr_dbreconnect_time", 5.0);

		if(g_iDBReconnectCount <= 0) {g_iDBReconnectCount = 5;}
		if(g_fDBReconnectTime <= 0.0) {g_fDBReconnectTime = 5.0;}
	}
	else CrashLR("Section MainSettings is not found (%s)", sPath);
	delete hLR_Settings;
	SetSettingsType();
}

void SetSettingsType()
{
	char sBuffer[64], sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/settings_stats.ini");
	KeyValues hLR_Settings = new KeyValues("LR_Settings");

	if(!hLR_Settings.ImportFromFile(sPath) || !hLR_Settings.GotoFirstSubKey())
	{
		CrashLR("(%s) is not found", sPath);
	}

	hLR_Settings.Rewind();

	if(g_iTypeStatistics == 0)
	{
		if(hLR_Settings.JumpToKey("Exp_Stats"))
		{
			g_iGiveKill = hLR_Settings.GetNum("lr_kill", 5);
			g_iGiveDeath = hLR_Settings.GetNum("lr_death", 5);
			g_iGiveHeadShot = hLR_Settings.GetNum("lr_headshot", 1);
			g_iGiveAssist = hLR_Settings.GetNum("lr_assist", 1);
			g_iGiveSuicide = hLR_Settings.GetNum("lr_suicide", 6);
			g_iGiveTeamKill = hLR_Settings.GetNum("lr_teamkill", 6);
			g_iRoundWin = hLR_Settings.GetNum("lr_winround", 2);
			g_iRoundLose = hLR_Settings.GetNum("lr_loseround", 2);
			g_iRoundMVP = hLR_Settings.GetNum("lr_mvpround", 3);
			g_iBombPlanted = hLR_Settings.GetNum("lr_bombplanted", 2);
			g_iBombDefused = hLR_Settings.GetNum("lr_bombdefused", 2);
			g_iBombDropped = hLR_Settings.GetNum("lr_bombdropped", 1);
			g_iBombPickup = hLR_Settings.GetNum("lr_bombpickup", 1);
			g_iHostageKilled = hLR_Settings.GetNum("lr_hostagekilled", 4);
			g_iHostageRescued = hLR_Settings.GetNum("lr_hostagerescued", 3);

			for(int i = 0; i <= 10; i++)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "lr_bonus_%i", i + 1);
				g_iBonus[i] = hLR_Settings.GetNum(sBuffer, i + 2);
			}
		}
		else CrashLR("Section Exp_Stats is not found (%s)", sPath);
	}
	else
	{
		if(hLR_Settings.JumpToKey("Elo_Stats"))
		{
			g_fKillCoeff = hLR_Settings.GetFloat("lr_killcoeff", 1.00);

			if(g_fKillCoeff < 0.50 || g_fKillCoeff > 1.50)
			{
				g_fKillCoeff = 1.00;
			}

			g_iGiveCalibration = hLR_Settings.GetNum("lr_calibration", 15);

			if(g_iGiveCalibration > 20)
			{
				g_iGiveCalibration = 15;
			}

			g_iGiveHeadShot = hLR_Settings.GetNum("lr_headshot", 1);
			g_iGiveAssist = hLR_Settings.GetNum("lr_assist", 1);
			g_iGiveSuicide = hLR_Settings.GetNum("lr_suicide", 10);
			g_iGiveTeamKill = hLR_Settings.GetNum("lr_teamkill", 5);
			g_iRoundWin = hLR_Settings.GetNum("lr_winround", 2);
			g_iRoundLose = hLR_Settings.GetNum("lr_loseround", 2);
			g_iRoundMVP = hLR_Settings.GetNum("lr_mvpround", 1);
			g_iBombPlanted = hLR_Settings.GetNum("lr_bombplanted", 3);
			g_iBombDefused = hLR_Settings.GetNum("lr_bombdefused", 3);
			g_iBombDropped = hLR_Settings.GetNum("lr_bombdropped", 2);
			g_iBombPickup = hLR_Settings.GetNum("lr_bombpickup", 2);
			g_iHostageKilled = hLR_Settings.GetNum("lr_hostagekilled", 20);
			g_iHostageRescued = hLR_Settings.GetNum("lr_hostagerescued", 5);

			for(int i = 0; i <= 10; i++)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "lr_bonus_%i", i + 1);
				g_iBonus[i] = hLR_Settings.GetNum(sBuffer, i + 1);
			}
		}
		else CrashLR("Section Elo_Stats is not found (%s)", sPath);
	}

	hLR_Settings.Rewind();

	if(hLR_Settings.JumpToKey("Weapon_Coeff"))
	{
		for(int i = 0; i < 47; i++)
		{
			g_fWeaponsCoeff[i] = hLR_Settings.GetFloat(g_sWeaponClassname[i], 1.0);
		}
	}
	else CrashLR("Section Weapon_Coeff is not found (%s)", sPath);

	delete hLR_Settings;
	SetSettingsRank();
}

void SetSettingsRank()
{
	char sPath[PLATFORM_MAX_PATH];
	KeyValues hLR_Settings = new KeyValues("LR_Settings");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/settings_ranks.ini");

	if(!hLR_Settings.ImportFromFile(sPath) || !hLR_Settings.GotoFirstSubKey())
	{
		CrashLR("(%s) is not found", sPath);
	}

	hLR_Settings.Rewind();

	if(hLR_Settings.JumpToKey("Ranks"))
	{
		int iRanksCount = 0;
		hLR_Settings.GotoFirstSubKey();

		do
		{
			hLR_Settings.GetString("name", g_sShowRank[iRanksCount], sizeof(g_sShowRank[]));

			if(iRanksCount > 1)
			{
				if(g_iTypeStatistics == 0)
				{
					g_iShowExp[iRanksCount] = hLR_Settings.GetNum("value_0", 0);
				}
				else g_iShowExp[iRanksCount] = hLR_Settings.GetNum("value_1", 0);
			}
			iRanksCount++;
		}
		while(hLR_Settings.GotoNextKey());
	}
	else CrashLR("Section Ranks is not found (%s)", sPath);
	delete hLR_Settings;
}