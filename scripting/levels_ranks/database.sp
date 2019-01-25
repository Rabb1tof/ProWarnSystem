bool			g_bInitialized[MAXPLAYERS+1];
char			g_sSQL_CreateTable_SQLITE[] = "CREATE TABLE IF NOT EXISTS `%s` (`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, `value` NUMERIC, `steam` varchar(32) NOT NULL default '', `name` varchar(128) NOT NULL default '', `rank` NUMERIC, `kills` NUMERIC, `deaths` NUMERIC, `shoots` NUMERIC, `hits` NUMERIC, `headshots` NUMERIC, `assists` NUMERIC, `round_win` NUMERIC, `round_lose` NUMERIC, `playtime` NUMERIC, `lastconnect` NUMERIC);",
			g_sSQL_CreateTable_MYSQL[] = "CREATE TABLE IF NOT EXISTS `%s` (`id` INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT, `value` NUMERIC, `steam` varchar(32) NOT NULL default '', `name` varchar(128) NOT NULL default '', `rank` NUMERIC, `kills` NUMERIC, `deaths` NUMERIC, `shoots` NUMERIC, `hits` NUMERIC, `headshots` NUMERIC, `assists` NUMERIC, `round_win` NUMERIC, `round_lose` NUMERIC, `playtime` NUMERIC, `lastconnect` NUMERIC) CHARSET=utf8 COLLATE utf8_general_ci",
			g_sSQL_CreatePlayer[] = "INSERT INTO `%s` (`value`, `steam`, `name`, `lastconnect`) VALUES ('%d', '%s', '%s', '%d');",
			g_sSQL_LoadPlayer[] = "SELECT `value`, `rank`, `kills`, `deaths`, `shoots`, `hits`, `headshots`, `assists`, `round_win`, `round_lose`, `playtime` FROM `%s` WHERE `steam` = '%s';",
			g_sSQL_SavePlayer[] = "UPDATE `%s` SET `value` = %d, `name` = '%s', `rank` = %d, `kills` = %d, `deaths` = %d, `shoots` = %d, `hits` = %d, `headshots` = %d, `assists` = %d, `round_win` = %d, `round_lose` = %d, `playtime` = %d, `lastconnect` = %d WHERE `steam` = '%s';",
			g_sSQL_CountPlayers[] = "SELECT `steam` FROM `%s`;",
			g_sSQL_PlacePlayer[] = "SELECT `value`, `steam` FROM `%s` ORDER BY `value` DESC;",
			g_sSQL_PurgeDB[] = "DELETE FROM `%s` WHERE `lastconnect` < %d;",
			g_sSQL_PurgeDBCalibration[] = "DELETE FROM `%s` WHERE `lastconnect` < %d AND `rank` = 0;",
			g_sSQL_CallTOP[] = "SELECT `name`, `value` FROM `%s` ORDER BY `value` DESC LIMIT 10 OFFSET 0",
			g_sSQL_CallTOPTime[] = "SELECT `name`, `playtime` FROM `%s` ORDER BY `playtime` DESC LIMIT 10 OFFSET 0",
			g_sSteamID[MAXPLAYERS+1][32];
Database	g_hDatabase = null;

void ConnectDB()
{
	char sIdent[16], sError[256], sQuery[1024];
	g_hDatabase = SQL_Connect("levels_ranks", false, sError, 256);
	if(!g_hDatabase)
	{
		g_hDatabase = SQLite_UseDatabase("lr_base", sError, 256);
		if(!g_hDatabase)
		{
			CrashLR("Could not connect to the database (%s)", sError);
		}
	}

	g_hDatabase.Driver.GetIdentifier(sIdent, sizeof(sIdent));
	SQL_LockDatabase(g_hDatabase);

	switch(sIdent[0])
	{
		case 's':
		{
			g_bDatabaseSQLite = true;
			FormatEx(sQuery, 1024, g_sSQL_CreateTable_SQLITE, g_sTableName);
			if(!SQL_FastQuery(g_hDatabase, sQuery)) CrashLR("ConnectDB - could not create table in SQLite");
		}
		case 'm':
		{
			g_bDatabaseSQLite = false;
			FormatEx(sQuery, 1024, g_sSQL_CreateTable_MYSQL, g_sTableName);
			if(!SQL_FastQuery(g_hDatabase, sQuery)) CrashLR("ConnectDB - could not create table in MySQL");

			char sQueryFast[256];
			FormatEx(sQueryFast, 256, "ALTER TABLE `%s` MODIFY `kills` NUMERIC;", g_sTableName);
			SQL_FastQuery(g_hDatabase, sQueryFast);

			FormatEx(sQueryFast, 256, "ALTER TABLE `%s` MODIFY `hits` NUMERIC;", g_sTableName);
			SQL_FastQuery(g_hDatabase, sQueryFast);

			FormatEx(sQueryFast, 256, "ALTER TABLE `%s` MODIFY `headshots` NUMERIC;", g_sTableName);
			SQL_FastQuery(g_hDatabase, sQueryFast);
		}
		default: CrashLR("ConnectDB - type database is invalid");
	}

	SQL_UnlockDatabase(g_hDatabase);

	g_hDatabase.SetCharset("utf8");
	GetCountPlayers();
	Call_StartForward(g_hForward_OnDatabaseLoaded);
	Call_Finish();
}

void GetCountPlayers()
{
	if(!g_hDatabase)
	{
		LogLR("GetCountPlayers - database is invalid");
		return;
	}

	char sQuery[128];
	FormatEx(sQuery, 128, g_sSQL_CountPlayers, g_sTableName);
	g_hDatabase.Query(SQL_GetCountPlayers, sQuery);
}

DBCallbackLR(SQL_GetCountPlayers)
{
	if(dbRs == null)
	{
		LogLR("SQL_GetCountPlayers - error while working with data (%s)", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}

	g_iDBCountPlayers = dbRs.RowCount;
}

void GetPlacePlayer(int iClient)
{
	if(!g_hDatabase)
	{
		LogLR("GetPlacePlayer - database is invalid");
		return;
	}

	char sQuery[256];
	FormatEx(sQuery, 256, g_sSQL_PlacePlayer, g_sTableName);
	g_hDatabase.Query(SQL_GetPlacePlayer, sQuery, iClient);
}

DBCallbackLR(SQL_GetPlacePlayer)
{
	if(dbRs == null)
	{
		LogLR("SQL_GetPlacePlayer - error while working with data (%s)", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}

	int i;
	char sSteam[32];
	while(dbRs.HasResults && dbRs.FetchRow())
	{
		i++;
		dbRs.FetchString(1, sSteam, sizeof(sSteam));
		if(StrEqual(sSteam, g_sSteamID[iClient], false))
		{
			g_iDBRankPlayer[iClient] = i;
			break;
		}
	}
}

void CreateDataPlayer(int iClient)
{
	if(!g_hDatabase)
	{
		LogLR("CreateDataPlayer - database is invalid");
		return;
	}

	if(IsClientConnected(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char sQuery[512], sSaveName[MAX_NAME_LENGTH * 2 + 1];
		g_hDatabase.Escape(GetFixNamePlayer(iClient), sSaveName, sizeof(sSaveName));

		if(g_iTypeStatistics == 0)
		{
			g_iExp[iClient] = 0;
		}
		else g_iExp[iClient] = 1000;

		g_iClientSessionData[iClient][0] = g_iExp[iClient];
		FormatEx(sQuery, sizeof(sQuery), g_sSQL_CreatePlayer, g_sTableName, g_iExp[iClient], g_sSteamID[iClient], sSaveName, GetTime());
		g_hDatabase.Query(SQL_CreateDataPlayer, sQuery, iClient);
	}
}

DBCallbackLR(SQL_CreateDataPlayer)
{
	if(dbRs == null)
	{
		LogLR("SQL_CreateDataPlayer - error while working with data (%s)", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}

	g_bInitialized[iClient] = true;
	g_iRank[iClient] = 0;
	g_iKills[iClient] = 0;
	g_iDeaths[iClient] = 0;
	g_iShoots[iClient] = 0;
	g_iHits[iClient] = 0;
	g_iHeadshots[iClient] = 0;
	g_iAssists[iClient] = 0;
	g_iRoundWinStats[iClient] = 0;
	g_iRoundLoseStats[iClient] = 0;
	g_iPlayTime[iClient] = 0;

	Call_StartForward(g_hForward_OnPlayerLoaded);
	Call_PushCell(iClient);
	Call_Finish();

	g_iDBCountPlayers += 1;
	CheckRank(iClient);
}

void LoadDataPlayer(int iClient)
{
	if(!g_hDatabase)
	{
		LogLR("LoadDataPlayer - database is invalid");
		return;
	}

	if(!IsFakeClient(iClient) && !g_bInitialized[iClient])
	{
		char sQuery[256];
		GetClientAuthId(iClient, AuthId_Steam2, g_sSteamID[iClient], 32);
		FormatEx(sQuery, sizeof(sQuery), g_sSQL_LoadPlayer, g_sTableName, g_sSteamID[iClient]);
		g_hDatabase.Query(SQL_LoadDataPlayer, sQuery, iClient);
	}
}

DBCallbackLR(SQL_LoadDataPlayer)
{
	if(dbRs == null)
	{
		LogLR("SQL_LoadDataPlayer - error while working with data (%s)", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}
	
	if(dbRs.HasResults && dbRs.FetchRow())
	{
		g_iExp[iClient] = dbRs.FetchInt(0);
		g_iRank[iClient] = dbRs.FetchInt(1);
		g_iKills[iClient] = dbRs.FetchInt(2);
		g_iDeaths[iClient] = dbRs.FetchInt(3);
		g_iShoots[iClient] = dbRs.FetchInt(4);
		g_iHits[iClient] = dbRs.FetchInt(5);
		g_iHeadshots[iClient] = dbRs.FetchInt(6);
		g_iAssists[iClient] = dbRs.FetchInt(7);
		g_iRoundWinStats[iClient] = dbRs.FetchInt(8);
		g_iRoundLoseStats[iClient] = dbRs.FetchInt(9);
		g_iPlayTime[iClient] = dbRs.FetchInt(10);

		if(g_bDebug && iClient && IsClientInGame(iClient))
		{
			LogToFile(g_sDebugFile, "Игрок %N (%s) загружен. Его данные: %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i", iClient, g_sSteamID[iClient], g_iExp[iClient], g_iRank[iClient], g_iKills[iClient], g_iDeaths[iClient], g_iShoots[iClient], g_iHits[iClient], g_iHeadshots[iClient], g_iAssists[iClient], g_iRoundWinStats[iClient], g_iRoundLoseStats[iClient], g_iPlayTime[iClient]);
		}

		g_iClientSessionData[iClient][0] = g_iExp[iClient];
		g_bInitialized[iClient] = true;

		Call_StartForward(g_hForward_OnPlayerLoaded);
		Call_PushCell(iClient);
		Call_Finish();

		GetPlacePlayer(iClient);
		CheckRank(iClient);
	}
	else
	{
		if(g_bDebug && iClient && IsClientInGame(iClient))
		{
			LogToFile(g_sDebugFile, "Игрок %N (%s) не найден в базе. Добавляем как нового!", iClient, g_sSteamID[iClient]);
		}
		CreateDataPlayer(iClient);
	}
}

void SaveDataPlayer(int iClient)
{
	if(!g_hDatabase)
	{
		LogLR("SaveDataPlayer - database is invalid");
		return;
	}

	if(CheckStatus(iClient))
	{
		char sQuery[512], sSaveName[MAX_NAME_LENGTH * 2 + 1];
		g_hDatabase.Escape(GetFixNamePlayer(iClient), sSaveName, sizeof(sSaveName));
		FormatEx(sQuery, 512, g_sSQL_SavePlayer, g_sTableName, g_iExp[iClient], sSaveName, g_iRank[iClient], g_iKills[iClient], g_iDeaths[iClient], g_iShoots[iClient], g_iHits[iClient], g_iHeadshots[iClient], g_iAssists[iClient], g_iRoundWinStats[iClient], g_iRoundLoseStats[iClient], g_iPlayTime[iClient], GetTime(), g_sSteamID[iClient]);
		g_hDatabase.Query(SQL_SaveDataPlayer, sQuery, iClient, DBPrio_High);
	}
}

DBCallbackLR(SQL_SaveDataPlayer)
{
	if(dbRs == null)
	{
		LogLR("SQL_SaveDataPlayer - error while working with data (%s)", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
	}
}

void PurgeDatabase()
{
	if(!g_hDatabase)
	{
		LogLR("PurgeDatabase - database is invalid");
		return;
	}

	char sQuery[256];
	FormatEx(sQuery, 256, g_sSQL_PurgeDB, g_sTableName, GetTime() - (g_iDaysDeleteFromBase * 86400));
	g_hDatabase.Query(SQL_PurgeDatabase, sQuery);
}

DBCallbackLR(SQL_PurgeDatabase)
{
	if(dbRs == null)
	{
		LogLR("SQL_PurgeDatabase - error while working with data (%s)", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
	}

	GetCountPlayers();
}

void PurgeDatabaseCalibration()
{
	if(!g_hDatabase)
	{
		LogLR("PurgeDatabaseCalibration - database is invalid");
		return;
	}

	char sQuery[256];
	FormatEx(sQuery, 256, g_sSQL_PurgeDBCalibration, g_sTableName, GetTime() - (g_iDaysDeleteFromBaseCalib * 86400));
	g_hDatabase.Query(SQL_PurgeDatabaseCalibration, sQuery);
}

DBCallbackLR(SQL_PurgeDatabaseCalibration)
{
	if(dbRs == null)
	{
		LogLR("SQL_PurgeDatabaseCalibration - error while working with data (%s)", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
	}

	GetCountPlayers();
}

void ResetStats()
{
	if(!g_hDatabase)
	{
		LogLR("ResetStats - database is invalid");
		return;
	}

	SQL_LockDatabase(g_hDatabase);

	char sQuery[128];
	FormatEx(sQuery, 128, "DELETE FROM `%s`;", g_sTableName);
	SQL_FastQuery(g_hDatabase, sQuery);

	SQL_UnlockDatabase(g_hDatabase);

	g_iDBCountPlayers = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(CheckStatus(i))
		{
			g_bInitialized[i] = false;
			CreateDataPlayer(i);
		}
	}
}

void TryReconnectDB()
{
	delete g_hDatabase;
	g_hDatabase = null;
	g_iCountRetryConnect = 0;
	CreateTimer(g_fDBReconnectTime, TryReconnectDBTimer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action TryReconnectDBTimer(Handle hTimer)
{
	char sError[256];
	g_hDatabase = SQL_Connect("levels_ranks", false, sError, 256);

	if(!g_hDatabase)
	{
		g_iCountRetryConnect++;
		if(g_iCountRetryConnect >= g_iDBReconnectCount)
		{
			CrashLR("The attempt to restore the connection was failed, plugin disabled (%s)", sError);
		}
		else LogLR("The attempt to restore the connection was failed #%i", g_iCountRetryConnect);
	}
	else
	{
		g_hDatabase.SetCharset("utf8");
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

/*
* Fix name by Феникс
*/
char[] GetFixNamePlayer(int iClient)
{
	char sName[MAX_NAME_LENGTH * 2 + 1];
	GetClientName(iClient, sName, sizeof(sName));

	for(int i = 0, len = strlen(sName), CharBytes; i < len;)
	{
		if((CharBytes = GetCharBytes(sName[i])) >= 4)
		{
			len -= CharBytes;
			for(int u = i; u <= len; u++)
			{
				sName[u] = sName[u + CharBytes];
			}
		}
		else i += CharBytes;
	}
	return sName;
}