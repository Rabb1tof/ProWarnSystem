int g_iServerID = 0;

char g_sSQL_CreateTablePlayers_SQLite[] = "CREATE TABLE IF NOT EXISTS `ws_player` ( \
		`account_id` INTEGER PRIMARY KEY NOT NULL, \
		`username` VARCHAR(64) NOT NULL default '', \
		`warns` INTEGER(10) NOT NULL DEFAULT '0', \
		`score` INTEGER NOT NULL DEFAULT '0');",
	g_sSQL_CreateTablePlayers_MySQL[] = "CREATE TABLE IF NOT EXISTS `ws_player` (\
`account_id` int(10) unsigned NOT NULL COMMENT 'Steam Account ID',\
`username` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unnamed',\
`warns` int(10) unsigned NOT NULL DEFAULT '0',\
`score` smallint(6) unsigned NOT NULL DEFAULT '0',\
PRIMARY KEY (`account_id`)\
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Перечень всех игроков';",
	g_sSQL_CreateTableWarns_MySQL[] = "CREATE TABLE IF NOT EXISTS `ws_warn` ( \
`warn_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Уникальный идентификатор предупреждения',\
`admin_id` int(10) unsigned NOT NULL COMMENT 'Идентификатор игрока-администратора, выдавшего предупреждение',\
`client_id` int(10) unsigned NOT NULL COMMENT 'Идентификатор игрока, который получил предупреждение',\
`server_id` smallint(6) unsigned NOT NULL COMMENT 'Идентификатор сервера',\
`reason` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Причина',\
`score` smallint(6) unsigned DEFAULT '0' COMMENT 'Количество баллов за выданное предупреждение', \
`created_at` int(10) unsigned NOT NULL COMMENT 'TIMESTAMP, когда был создан',\
`expires_at` int(10) unsigned NOT NULL COMMENT 'TIMESTAMP, когда истекает, или 0, если бессрочно',\
`deleted` TINYINT(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Истекло ли предупреждение 1 - да',\
`isadmin` TINYINT(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Является ли предупрежденный админом (1 - да)',\
PRIMARY KEY (`warn_id`),\
KEY `FK_ws_warn_ws_server` (`server_id`),\
KEY `FK_ws_warn_ws_admin` (`admin_id`),\
KEY `FK_ws_warn_ws_client` (`client_id`),\
CONSTRAINT `FK_ws_warn_ws_admin` FOREIGN KEY (`admin_id`) REFERENCES `ws_player` (`account_id`) ON DELETE CASCADE ON UPDATE CASCADE,\
CONSTRAINT `FK_ws_warn_ws_client` FOREIGN KEY (`client_id`) REFERENCES `ws_player` (`account_id`) ON DELETE CASCADE ON UPDATE CASCADE,\
CONSTRAINT `FK_ws_warn_ws_server` FOREIGN KEY (`server_id`) REFERENCES `ws_server` (`server_id`) ON DELETE CASCADE ON UPDATE CASCADE\
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Все выданные когда-либо предупреждения';",

	g_sSQL_CreateTableWarns_SQLite[] = "CREATE TABLE IF NOT EXISTS `ws_warn` ( \
	`warn_id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, \
	`admin_id` INTEGER NOT NULL, \
	`client_id` INTEGER NOT NULL, \
	`server_id` INTEGER NOT NULL, \
	`reason` VARCHAR(128) NOT NULL, \
	`score` INTEGER NOT NULL DEFAULT '0', \
	`created_at` INTEGER NOT NULL, \
	`expires_at` INTEGER NOT NULL, \
	`deleted` TINYINT NOT NULL DEFAULT '0', \
	`isadmin` TINYINT NOT NULL DEFAULT '0', \
	CONSTRAINT `FK_ws_warn_ws_admin` FOREIGN KEY (`admin_id`) REFERENCES `ws_player` (`account_id`) ON DELETE CASCADE ON UPDATE CASCADE, \
	CONSTRAINT `FK_ws_warn_ws_client` FOREIGN KEY (`client_id`) REFERENCES `ws_player` (`account_id`) ON DELETE CASCADE ON UPDATE CASCADE)",
	
	g_sSQL_CreateTableServers[] = "CREATE TABLE IF NOT EXISTS `ws_server` (\
`server_id` smallint(6) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Уникальный идентификатор сервера',\
`address` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '0' COMMENT 'IP-адрес сервера',\
`port` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT 'Порт сервера',\
PRIMARY KEY (`server_id`),\
UNIQUE KEY `ws_servers_address_port` (`address`,`port`)\
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Перечень серверов';",
	g_sSQL_GetServerID[] = "SELECT `server_id` FROM `ws_server` WHERE `address` = '%s' AND `port` = '%i';",
	g_sSQL_SetServerID[] = "INSERT IGNORE INTO `ws_server` (`address`, `port`) VALUES ('%s', '%i');",
	g_sSQL_WarnPlayerW[] = "INSERT INTO `ws_warn` (`server_id`, `client_id`, `admin_id`, `reason`, `score`, `created_at`, `expires_at`, `isadmin`) VALUES ('%i', '%i', '%i', '%s', '%i', '%i', '%i', '%i');",
	g_sSQL_WarnPlayerP[] = "UPDATE `ws_player` SET `username` = '%s', `warns` = '%i', `score` = '%i' WHERE `account_id` = '%i';",
	g_sSQL_DeleteWarns[] = "UPDATE `ws_warn` SET `deleted` = '1' WHERE `client_id` = '%i';",
	g_sSQL_DeleteExpired[] = "UPDATE `ws_warn` SET `deleted` = '1' WHERE `expires_at` <= '%i' AND `expires_at` <> '0';",
	g_sSQL_SelectWarns[] = "SELECT `ws_warn`.`warn_id`, `ws_warn`.`score`, `ws_warn`.`reason` FROM `ws_warn` \
INNER JOIN `ws_player` AS `player` \
	ON `ws_warn`.`client_id` = `player`.`account_id`\
WHERE `client_id` = '%i' AND `server_id` = '%i' AND `deleted` = '0';",
	g_sSQL_FindWarn[] = "SELECT `ws_warn`.`client_id`, `player`.`warns`, `ws_warn`.`score`\
	FROM `ws_warn`\
INNER JOIN `ws_player` AS `player`\
WHERE `ws_warn`.`warn_id` = '%i' AND\
`ws_warn`.`server_id` = '%i'",
	g_sSQL_CheckData[] = "SELECT `username`, `warns`, `score` FROM `ws_player` WHERE `account_id` = '%i'",
	g_sSQL_UploadData[] = "INSERT INTO `ws_player` (`account_id`, `username`, `warns`, `score`) VALUES ('%i', '%s', '%i', '%i');",
	g_sSQL_UpdateData[] = "UPDATE `ws_player` SET `warns` = ( IFNULL((SELECT COUNT(*) FROM `ws_warn` WHERE `client_id` = '%i' AND `deleted` = '0'), '0')), `score` = ( \
IFNULL((SELECT SUM(`score`) FROM `ws_warn` WHERE `client_id` = '%i' AND `deleted` = '0'), '0')),\
		`username` = '%s' WHERE `account_id` = '%i';",
	g_sSQL_LoadPlayerData[] = "SELECT COUNT(`warn_id`), SUM(`score`) FROM `ws_warn` WHERE `client_id` = '%i' AND `server_id` = '%i' AND `deleted` = '0';",
	g_sSQL_UnwarnPlayerW[] = "UPDATE `ws_warn` SET `deleted` = '1' WHERE `warn_id` = '%i';",
	g_sSQL_UnwarnPlayerP[] = "UPDATE `ws_player` SET `username` = '%s', `warns` = '%i', `score` = '%i' WHERE `account_id` = '%i';",
	g_sSQL_CheckPlayerWarns[] = "SELECT \
	`ws_warn`.`warn_id`, \
	`ws_warn`.`client_id`, \
	`ws_player`.`username`, \
	`ws_warn`.`created_at` \
FROM \
	`ws_warn` \
INNER JOIN `ws_player`\
	ON `ws_warn`.`admin_id` = `ws_player`.`account_id` \
WHERE\
	`ws_warn`.`client_id` = '%i' AND \
	`ws_warn`.`deleted` = 0;",    
	g_sSQL_GetInfoWarn[] = "SELECT `admin`.`account_id` `admin_id`, \
	`admin`.`username`, \
	`player`.`account_id`, \
	`player`.`username`, \
	`ws_warn`.`reason`, \
	`ws_warn`.`score`, \
	`ws_warn`.`expires_at`, \
	`ws_warn`.`created_at` \
FROM \
	`ws_warn` \
INNER JOIN `ws_player` AS `admin` \
	ON `ws_warn`.`admin_id` = `admin`.`account_id` \
INNER JOIN `ws_player` AS `player` \
	ON `ws_warn`.`client_id` = `player`.`account_id` \
WHERE `ws_warn`.`warn_id` = '%i';",
	g_sSQL_UpdateSQLiteW[] = "ALTER TABLE `ws_warn` ADD COLUMN `score` INTEGER NOT NULL DEFAULT '0';\
							ALTER TABLE `ws_warn` ADD COLUMN `isadmin` TINYINT NOT NULL DEFAULT '0';",
	g_sSQL_UpdateSQLiteP[] = "ALTER TABLE `ws_player` ADD COLUMN `score` INTEGER NOT NULL DEFAULT '0'",
	g_sSQL_UpdateMySQLW[] = "ALTER TABLE `ws_warn` ADD COLUMN `score` smallint(6) unsigned NOT NULL DEFAULT '0' COMMENT 'Количество баллов за выданное предупреждение.',\
							ALTER TABLE `ws_warn` ADD COLUMN `isadmin` TINYINT(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Является ли предупрежденный админом.'",
	g_sSQL_UpdateMySQLP[] = "ALTER TABLE `ws_player` ADD COLUMN `score` smallint(6) unsigned NOT NULL DEFAULT '0' COMMENT 'Количество баллов у юзера.'",
	g_sClientIP[MAXPLAYERS+1][65];
	
int g_iAccountID[MAXPLAYERS+1];

//----------------------------------------------------DATABASE INITILIZING---------------------------------------------------

public void InitializeDatabase()
{
	char sError[256];
	g_hDatabase = SQL_Connect("warnsystem", false, sError, 256);
	if(!g_hDatabase)
	{
		if (sError[0])
			LogWarnings(sError);
		g_hDatabase = SQLite_UseDatabase("warnsystem", sError, 256);
		if(!g_hDatabase)
			SetFailState("[WarnSystem] Could not connect to the database (%s)", sError);
	}

	Handle hDatabaseDriver = view_as<Handle>(g_hDatabase.Driver);
	if (hDatabaseDriver == SQL_GetDriver("sqlite"))
	{
		g_hDatabase.SetCharset("utf8");
		Transaction hTxn = new Transaction();
		hTxn.AddQuery(g_sSQL_CreateTablePlayers_SQLite); // 0 
		hTxn.AddQuery(g_sSQL_CreateTableWarns_SQLite); // 1
		g_hDatabase.Execute(hTxn, SQL_TransactionSuccefully, SQL_TransactionFailed, 1);
	} else if (hDatabaseDriver == SQL_GetDriver("mysql")) {
			g_hDatabase.SetCharset("utf8");
			Transaction hTxn = new Transaction();
			hTxn.AddQuery(g_sSQL_CreateTablePlayers_MySQL); // 0
			hTxn.AddQuery(g_sSQL_CreateTableServers, 5); // 1
			hTxn.AddQuery(g_sSQL_CreateTableWarns_MySQL); // 2
			g_hDatabase.Execute(hTxn, SQL_TransactionSuccefully, SQL_TransactionFailed, 1);
			PrintToServer("Creating DB started...");
		} else
			SetFailState("[WarnSystem] InitializeDatabase - type database is invalid");
	
	if (g_bIsLateLoad)
	{
		for(int iClient = 1; iClient <= MaxClients; ++iClient)
			LoadPlayerData(iClient);
		g_bIsLateLoad = false;
	}
}

public void SQL_TransactionSuccefully(Database hDatabase, any data, int iNumQueries, Handle[] hResults, any[] queryData)
{
	char szBuffer[80], szQuery[14];
	switch(data) {
		case 1:     szQuery = "Create Tables";
		case 2:     szQuery = "Warn Player";
		case 3:     szQuery = "Unwarn Player";
	}
	PrintToServer("-----------------------------------------------------");
	FormatEx(szBuffer, sizeof(szBuffer), "[WarnSystem] Transaction '%s' succefully done.", szQuery);
	PrintToServer(szBuffer);
	PrintToServer("-----------------------------------------------------");
	if(queryData[1] == 5) 
		GetServerID();
}

public void SQL_TransactionFailed(Database hDatabase, any data, int iNumQueries, const char[] szError, int iFailIndex, any[] queryData)
{
	char szBuffer[256], szQuery[14];
	switch(data) {
		case 1:     szQuery = "Create Tables";
		case 2:     szQuery = "Warn Player";
		case 3:     szQuery = "Unwarn Player";
	}
	FormatEx(szBuffer, sizeof(szBuffer), "Query: %s, %i index: %s", szQuery, iFailIndex, szError);
	LogWarnings(szBuffer);
}

public void GetServerID()
{
	char dbQuery[513];
	FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_GetServerID, g_sAddress, g_iPort);
	g_hDatabase.Query(SQL_SelectServerID, dbQuery);
	if(g_bLogQuery)
		LogQuery("GetServerID: %s", dbQuery);
}

public void SQL_SelectServerID(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, any data)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_SelectServerID: %s", sError);
		return;
	}

	if(SQL_FetchRow(hDatabaseResults))
	{
		g_iServerID = SQL_FetchInt(hDatabaseResults, 0);
		return;
	}
	
	char dbQuery[513];
	FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_SetServerID, g_sAddress, g_iPort);
	g_hDatabase.Query(SQL_SetServerID, dbQuery);
	if(g_bLogQuery)
		LogQuery("SQL_SelectServerID: %s", dbQuery);
}

public void SQL_SetServerID(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, any data)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_SetServerID: %s", sError);
		return;
	}

	if(SQL_GetAffectedRows(hDatabaseResults))
		g_iServerID = SQL_GetInsertId(g_hDatabase);
}

//----------------------------------------------------LOAD PLAYER DATA---------------------------------------------------

public void LoadPlayerData(int iClient)
{
	if(IsValidClient(iClient) && g_hDatabase)
	{
		char dbQuery[513];
		g_iAccountID[iClient] = GetSteamAccountID(iClient);
		GetClientIP(iClient, g_sClientIP[iClient], 65);
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_CheckData, g_iAccountID[iClient]);
		g_hDatabase.Query(SQL_CheckData, dbQuery, iClient);
		if(g_bLogQuery)
			LogQuery("LoadPlayerData::g_sSQL_CheckData: %s", dbQuery);
	}
}

public void SQL_CheckData(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, int iClient)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_CheckData - error while working with data (%s)", sError);
		return;
	}
	if(IsValidClient(iClient))
	{
		char dbQuery[513], szName[64], sEscapedClientName[129];
		GetClientName(iClient, szName, sizeof(szName));
		SQL_EscapeString(g_hDatabase, szName, sEscapedClientName, sizeof(sEscapedClientName));
		if (hDatabaseResults.RowCount == 0) {
			g_iWarnings[iClient] = g_iScore[iClient] = 0;
			FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UploadData, g_iAccountID[iClient], sEscapedClientName, g_iWarnings[iClient], g_iScore[iClient]);
			if(g_bLogQuery)
				LogQuery("SQL_CheckData::SQL_CheckData: %s", dbQuery);
			g_hDatabase.Query(SQL_UploadData, dbQuery, iClient);
			return;
		}
		else {
			FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UpdateData, g_iAccountID[iClient], g_iAccountID[iClient], sEscapedClientName, g_iAccountID[iClient]);
			if(g_bLogQuery)
				LogQuery("SQL_CheckData::SQL_CheckData: %s", dbQuery);
			g_hDatabase.Query(SQL_UpdateData, dbQuery, iClient);
			return;
		}
	}
}

public void SQL_UploadData(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, int iClient)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_UploadData - error while working with data (%s)", sError);
		return;
	}
	else {
		char dbQuery[513];
		CheckExpiredWarns();
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_SelectWarns, g_iAccountID[iClient], g_iServerID);
		if(g_bLogQuery)
			LogQuery("SQL_UploadData::SQL_UploadData: %s", dbQuery);
		g_hDatabase.Query(SQL_LoadPlayerData, dbQuery, iClient);
	}
}

public void SQL_UpdateData(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, int iClient)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_UpdateData - error while working with data (%s)", sError);
		return;
	}
	else {
		char dbQuery[513];
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_LoadPlayerData, g_iAccountID[iClient], g_iServerID);
		if(g_bLogQuery)
			LogQuery("SQL_UpdateData::SQL_UpdateData: %s", dbQuery);
		g_hDatabase.Query(SQL_LoadPlayerData, dbQuery, iClient);
	}
}

public void SQL_LoadPlayerData(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, int iClient)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_LoadPlayerData - error while working with data (%s)", sError);
		return;
	}
	else if (hDatabaseResults.FetchRow())
	{
		switch(g_iWarnType){
			case 0: g_iWarnings[iClient] = hDatabaseResults.FetchInt(0);
			case 1: g_iScore[iClient] = hDatabaseResults.FetchInt(1);
			case 2: {
						g_iWarnings[iClient] = hDatabaseResults.FetchInt(0);
						g_iScore[iClient] = hDatabaseResults.FetchInt(1);
			}
		}
		
		
		if (g_bPrintToAdmins && !g_bIsLateLoad){
			switch(g_iWarnType)
			{
				case 0:	PrintToAdmins(" %t %t", "WS_ColoredPrefix", "WS_PlayerWarns", iClient, g_iWarnings[iClient]);
				case 1: PrintToAdmins(" %t %t", "WS_ColoredPrefix", "WS_PlayerScore", iClient, g_iScore[iClient]);
				case 2:	PrintToAdmins(" %t %t", "WS_ColoredPrefix", "WS_PlayerWarnsAndScore", iClient, g_iWarnings[iClient], g_iScore[iClient]);
			}
		}

		//PrintToChatAll("Debug: %b", g_bIsFuckingGame);
	} else {
		g_iWarnings[iClient] = 0;
		g_iScore[iClient] = 0;
	}

	if(g_iScore[iClient] > g_iMaxScore || g_iWarnings[iClient] > g_iMaxWarns)
	{
		KickClient(iClient, "[WarnSystem] %t", "WS_MaxKick", "баллов или предупреждений");
	}
	
	WarnSystem_OnClientLoaded(iClient);
	
	PrintToServer("Succefully load player data.");
}

//--------------------------------------------------UPDATE SQL (DB)-------------------------------------------------

void UTIL_UpdateSQL(int iClient, bool bType)
{
	char dbQuery[257];
	Transaction hTxn = new Transaction();
	if(bType) {
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UpdateMySQLP);
		hTxn.AddQuery(dbQuery); // 0 transaction
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UpdateMySQLW);
		hTxn.AddQuery(dbQuery); // 1 transaction
	}
	else {
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UpdateSQLiteP);
		hTxn.AddQuery(dbQuery); // 0 transaction
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UpdateSQLiteW);
		hTxn.AddQuery(dbQuery); // 1 transaction
	}
	g_hDatabase.Execute(hTxn, SQL_SuccefullyUpdate, SQL_FailedUpdate, iClient);
}

public void SQL_SuccefullyUpdate(Database hDatabase, any data, int iNumQueries, Handle[] hResults, any[] queryData)
{
	ReplyToCommand(data, "-----------------------------------------------------");
	ReplyToCommand(data, "[WarnSystem] Transaction 'Update SQL to PRO' succefully done.");
	ReplyToCommand(data, "-----------------------------------------------------");
}

public void SQL_FailedUpdate(Database hDatabase, any data, int iNumQueries, const char[] szError, int iFailIndex, any[] queryData)
{
	char szBuffer[256];
	FormatEx(szBuffer, sizeof(szBuffer), "SQL_UpdateSQL::Transaction: %i index: %s", iFailIndex, szError);
	ReplyToCommand(data, szBuffer);
	if(g_bLogQuery)
		LogQuery(szBuffer);
}

//----------------------------------------------------WARN PLAYER---------------------------------------------------

public void WarnPlayer(int iAdmin, int iClient, int iScore, int iTime, char sReason[129])
{
	if (IsValidClient(iClient) && -1<iAdmin && iAdmin<=MaxClients && WarnSystem_OnClientWarnPre(iAdmin, iClient, iTime, iScore, sReason) == Plugin_Continue)
	{
		/*if (iAdmin == iClient)
		{
			WS_PrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_CantTargetYourself");
			return;
		}*/
		char sEscapedAdminName[257], sEscapedClientName[257], sEscapedReason[259], 
				dbQuery[513], TempNick[128];
		int iCurrentTime = GetTime();
		bool bIsAdmin; // Is client admin

		if(GetUserFlagBits(iClient) & (ADMFLAG_GENERIC | ADMFLAG_ROOT))
			bIsAdmin = true;
		
		GetClientName(iAdmin, TempNick, sizeof(TempNick));
		SQL_EscapeString(g_hDatabase, TempNick, sEscapedAdminName, sizeof(sEscapedAdminName));
		GetClientName(iClient, TempNick, sizeof(TempNick));
		SQL_EscapeString(g_hDatabase, TempNick, sEscapedClientName, sizeof(sEscapedClientName));
		SQL_EscapeString(g_hDatabase, sReason, sEscapedReason, sizeof(sEscapedReason));
		
		//`server_id`, `client_id`, `admin_id`, `reason`, `time`, `expires_at`
		switch(g_iWarnType){
			case 0: ++g_iWarnings[iClient];
			case 1: g_iScore[iClient] += iScore;
			case 2: {
						++g_iWarnings[iClient];
						g_iScore[iClient] += iScore;
			}
		}
		
		Transaction hTxn = new Transaction();
		
		
		// `account_id`, `username`, `warns`
		if(g_bWarnTime)
			FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_WarnPlayerW, g_iServerID, g_iAccountID[iClient], g_iAccountID[iAdmin], sEscapedReason, iScore, iCurrentTime, g_iWarnLength == 0 ? 0 : iCurrentTime + g_iWarnLength, bIsAdmin);
		else
			FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_WarnPlayerW, g_iServerID, g_iAccountID[iClient], g_iAccountID[iAdmin], sEscapedReason, iScore, iCurrentTime, iCurrentTime + iTime, bIsAdmin);
		hTxn.AddQuery(dbQuery); // 0 transaction
		if(g_bLogQuery)
			LogQuery("WarnPlayer::g_sSQL_WarnPlayerW: %s", dbQuery);
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_WarnPlayerP, sEscapedClientName, g_iWarnings[iClient], g_iScore[iClient], g_iAccountID[iClient]);
		hTxn.AddQuery(dbQuery); // 1 transaction
		if(g_bLogQuery)
			LogQuery("WarnPlayer::g_sSQL_WarnPlayerP: %s", dbQuery);
		g_hDatabase.Execute(hTxn, SQL_TransactionSuccefully, SQL_TransactionFailed, 2);
		if(g_bWarnSound)
			if (g_bIsFuckingGame)
			{
				char sBuffer[PLATFORM_MAX_PATH];
				FormatEx(sBuffer, sizeof(sBuffer), "*/%s", g_sWarnSoundPath);
				EmitSoundToClient(iClient, sBuffer);
			} else
				EmitSoundToClient(iClient, g_sWarnSoundPath);
	
		if (g_bPrintToChat) 
			WS_PrintToChatAll(" %t %t", "WS_ColoredPrefix", "WS_WarnPlayer", iAdmin, iClient, sReason);
		else
		{
			PrintToAdmins(" %t %t", "WS_ColoredPrefix", "WS_WarnPlayer", iAdmin, iClient, sReason);
			WS_PrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_WarnPlayerPersonal", iAdmin, sReason);
		}
		
		if(g_bLogWarnings)
			LogWarnings("[WarnSystem] ADMIN (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) issued a warning (duration: %i (in sec.)) on PLAYER (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) with reason: %s", iAdmin, g_iAccountID[iAdmin] & 1, g_iAccountID[iAdmin] / 2, g_sClientIP[iAdmin], g_iWarnLength, iClient, g_iAccountID[iClient] & 1, g_iAccountID[iClient] / 2,g_sClientIP[iClient], sReason);
		
		WarnSystem_OnClientWarn(iAdmin, iClient, iScore, iTime, sReason, bIsAdmin);
		
		//We don't need to fuck db because we cached warns.
		if ((g_iWarnings[iClient] >= g_iMaxWarns && g_iMaxWarns != 0) || (g_iScore[iClient] >= g_iMaxScore) && g_iMaxScore != 0)
		{
			if(g_bResetWarnings){
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteWarns, g_iAccountID[iClient], g_iServerID);
				g_hDatabase.Query(SQL_CheckError, dbQuery);
				if(g_bLogQuery)
					LogQuery("WarnPlayer::g_sSQL_DeleteWarns: %s", dbQuery);
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UpdateData, g_iAccountID[iClient], g_iAccountID[iClient], sEscapedClientName, g_iAccountID[iClient]);
				g_hDatabase.Query(SQL_CheckError, dbQuery);
				if(g_bLogQuery)
					LogQuery("WarnPlayer::g_sSQL_UpdateData: %s", dbQuery);
			}
			if(g_iScore[iClient] >= g_iMaxScore)
				PunishPlayerOnMaxWarns(iAdmin, iClient, sReason, true);
			else if(g_iWarnings[iClient] >= g_iMaxWarns)
				PunishPlayerOnMaxWarns(iAdmin, iClient, sReason, false);
			g_iWarnings[iClient] = g_iScore[iClient] = 0;
			//PrintToServer("score: %d | warns: %d", g_iScore[iClient], g_iWarnings[iClient]);
		} else 
			PunishPlayer(iAdmin, iClient, iScore, iTime, sReason);
	}
}

//----------------------------------------------------FIND WARN-------------------------------------------------------

public void FindWarn(int iAdmin, int iId, char sReason[129])
{
	if(IsValidClient(iAdmin))
	{
		char dbQuery[513];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_FindWarn, iId, g_iServerID);

		DataPack dPack = new DataPack();
		dPack.WriteCell(iAdmin);
		dPack.WriteCell(iId);
		dPack.WriteString(sReason);
		g_hDatabase.Query(SQL_FindWarn, dbQuery, dPack);
		if(g_bLogQuery)
			LogQuery("FindWarn::g_sSQL_FindWarn: %s", dbQuery);
	}
}

public void SQL_FindWarn(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, DataPack dPack)
{
	/*if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_FindWarn - error while working with data (%s)", sError);
		return;
	}*/

	int iAdmin, iClient, iId, iScore;
	char sReason[129];

	if(dPack)
	{
		dPack.Reset();
		iAdmin = dPack.ReadCell();
		iId = dPack.ReadCell();
		dPack.ReadString(sReason, sizeof(sReason));
	} else 		return;

	if(hDatabaseResults.FetchRow())
	{
		iClient              = 	FindClientByAccountID(hDatabaseResults.FetchInt(0));
		if(iClient == -1){
			LogWarnings("%t", "WS_IndexNotFunded");
			return;
		}
		g_iWarnings[iClient] = 	hDatabaseResults.FetchInt(1);
		iScore				 =	hDatabaseResults.FetchInt(2);
		UnwarnPlayer(iAdmin, iClient, iId, iScore, sReason);
	}
	else
		WS_PrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_NotWarned", iClient);

}

//----------------------------------------------------UNWARN PLAYER---------------------------------------------------

public void UnwarnPlayer(int iAdmin, int iClient, int iId, int iScore, char sReason[129])
{
	if (IsValidClient(iClient) && -1<iAdmin && iAdmin<=MaxClients && WarnSystem_OnClientUnWarnPre(iAdmin, iClient, iId, iScore, sReason) == Plugin_Continue)
	{
		/*if (iAdmin == iClient)
		{
			WS_PrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_CantTargetYourself");
			return;
		}*/
		
		char dbQuery[513];

		switch(g_iWarnType) {
			case 0: --g_iWarnings[iClient];
			case 1: g_iScore[iClient] -= iScore;
			case 2: {
						--g_iWarnings[iClient];
						g_iScore[iClient] -= iScore;
			}
		}
		
		Transaction hTxn = new Transaction();
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UnwarnPlayerW, iId);
		hTxn.AddQuery(dbQuery); // 0 transaction
		if(g_bLogQuery)
			LogQuery("SQL_UnWarnPlayer::g_sSQL_UnwarnPlayerW: %s", dbQuery);
		char szName[64];
		GetClientName(iClient, szName, sizeof(szName));
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UnwarnPlayerP, szName, g_iWarnings[iClient], g_iScore[iClient], g_iAccountID[iClient]);
		hTxn.AddQuery(dbQuery); // 1 transaction
		if(g_bLogQuery)
			LogQuery("SQL_UnWarnPlayer::g_sSQL_UnwarnPlayerP: %s", dbQuery);
		g_hDatabase.Execute(hTxn, SQL_TransactionSuccefully, SQL_TransactionFailed, 3);
		
		if (g_bPrintToChat)
			WS_PrintToChatAll(" %t %t", "WS_ColoredPrefix", "WS_UnWarnPlayer", iAdmin, iClient, sReason);
		else
		{
			PrintToAdmins(" %t %t", "WS_ColoredPrefix", "WS_UnWarnPlayer", iAdmin, iClient, sReason);
			WS_PrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_UnWarnPlayerPersonal", iAdmin, sReason);
		}
		
		if (g_bLogWarnings)
			LogWarnings("[WarnSystem] ADMIN (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) removed a warning on PLAYER (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) with reason: %s", iAdmin, g_iAccountID[iAdmin] & 1, g_iAccountID[iAdmin] / 2, g_sClientIP[iAdmin], iClient, g_iAccountID[iClient] & 1, g_iAccountID[iClient] / 2, g_sClientIP[iClient], sReason);
		
		WarnSystem_OnClientUnWarn(iAdmin, iClient, iId, iScore, sReason);
	}
}

//----------------------------------------------------RESET WARNS---------------------------------------------------

public void ResetPlayerWarns(int iAdmin, int iClient, char sReason[129])
{
	if (IsValidClient(iClient) && -1<iAdmin && iAdmin<=MaxClients && WarnSystem_OnClientResetWarnsPre(iAdmin, iClient, sReason) == Plugin_Continue)
	{
		if (iAdmin == iClient)
		{
			WS_PrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_CantTargetYourself");
			return;
		}
		char dbQuery[513];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_SelectWarns, g_iAccountID[iClient], g_iServerID);
		
		Handle hResetWarnData = CreateDataPack();
		
		if (iAdmin)
			WritePackCell(hResetWarnData, GetClientUserId(iAdmin));
		else
			WritePackCell(hResetWarnData, 0);
		WritePackCell(hResetWarnData, GetClientUserId(iClient));
		WritePackString(hResetWarnData, sReason);
		ResetPack(hResetWarnData);
		
		g_hDatabase.Query(SQL_ResetWarnPlayer, dbQuery, hResetWarnData);
		if(g_bLogQuery)
			LogQuery("ResetPlayerWarns::SQL_ResetWarnPlayer: %s", dbQuery);
	}
}

//------------------------------------Check for expired warnings------------------------------------------------

void CheckExpiredWarns()
{
	char dbQuery[513];
	int iTime = GetTime();
	FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteExpired, iTime);
	g_hDatabase.Query(SQL_CheckExpiredWarns, dbQuery);
	if(g_bLogQuery)
			LogQuery("CheckExpiredWarns::SQL_CheckExpiredWarns: %s", dbQuery);
}

public void SQL_CheckExpiredWarns(Database hDatabase, DBResultSet hDatabaseResults, const char[] szError, Handle hResetWarnData)
{
	if (szError[0])
	{
		LogWarnings("[WarnSystem] SQL_CheckExpiredWarns - error while working with data (%s)", szError);
		return;
	}
}

public void SQL_ResetWarnPlayer(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hResetWarnData)
{	
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_ResetWarnPlayer - error while working with data (%s)", sError);
		return;
	}

	char sReason[129], dbQuery[513];
	int iAdmin, iClient;
	
	if(hResetWarnData)
	{
		iAdmin = GetClientOfUserId(ReadPackCell(hResetWarnData));
		iClient = GetClientOfUserId(ReadPackCell(hResetWarnData));
		ReadPackString(hResetWarnData, sReason, sizeof(sReason));
		CloseHandle(hResetWarnData); 
	} else return;
	
	if (hDatabaseResults.HasResults)
	{
		g_iWarnings[iClient] = 0;
		g_iScore[iClient] = 0;
		Transaction hTxn = new Transaction();
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteWarns, g_iAccountID[iClient], g_iServerID);
		hTxn.AddQuery(dbQuery); // 0 transaction
		if(g_bLogQuery)
			LogQuery("SQL_ResetWarnPlayer::g_sSQL_DeleteWarns: %s", dbQuery);
		char szName[64], sEscapedClientName[129];
		GetClientName(iClient, szName, sizeof(szName));
		SQL_EscapeString(g_hDatabase, szName, sEscapedClientName, sizeof(sEscapedClientName));
		FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_UpdateData, g_iAccountID[iClient], g_iAccountID[iClient], sEscapedClientName, g_iAccountID[iClient]);
		hTxn.AddQuery(dbQuery); // 1 transaction
		g_hDatabase.Execute(hTxn, SQL_ResetWarnPlayerSuccefully, SQL_ResetWarnPlayerFailed);
		
		if (g_bPrintToChat)
			WS_PrintToChatAll(" %t %t", "WS_ColoredPrefix", "WS_ResetPlayer", iAdmin, iClient, sReason);
		else
		{
			PrintToAdmins(" %t %t", "WS_ColoredPrefix", "WS_ResetPlayer", iAdmin, iClient, sReason);
			WS_PrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_ResetPlayerPersonal", iAdmin, sReason);
		}
		
		WarnSystem_OnClientResetWarns(iAdmin, iClient, sReason);
		if(g_bLogWarnings)
			LogWarnings("[WarnSystem] ADMIN (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) reseted warnings on PLAYER (NICK: %N | STEAMID32: STEAM_1:%i:%i | IP: %s) with reason: %s", iAdmin, g_iAccountID[iAdmin] & 1, g_iAccountID[iAdmin] / 2, g_sClientIP[iAdmin], iClient, g_iAccountID[iAdmin] & 1, g_iAccountID[iAdmin] / 2, g_sClientIP[iClient], sReason);
	} else
		WS_PrintToChat(iAdmin, " %t %t", "WS_ColoredPrefix", "WS_NotWarned", iClient);
}

public void SQL_ResetWarnPlayerSuccefully(Database hDatabase, any data, int iNumQueries, Handle[] hResults, any[] queryData)
{
	PrintToServer("[WarnSystem] Transaction 'Reset Warns of Player' succefully done.");
}

public void SQL_ResetWarnPlayerFailed(Database hDatabase, any data, int iNumQueries, const char[] szError, int iFailIndex, any[] queryData)
{
	char szBuffer[256];
	FormatEx(szBuffer, sizeof(szBuffer), "SQL_ResetWarnPlayer::Transaction: %i index: %s", iFailIndex, szError);
	if(g_bLogQuery)
		LogQuery(szBuffer);
}

//----------------------------------------------------CHECK PLAYER WARNS---------------------------------------------------

public void CheckPlayerWarns(int iAdmin, int iClient)
{
	if (IsValidClient(iClient) && -1<iAdmin && iAdmin<=MaxClients)
	{
		char dbQuery[513];
		FormatEx(dbQuery, sizeof(dbQuery),  g_sSQL_CheckPlayerWarns, g_iAccountID[iClient]);
		
		Handle hCheckData = CreateDataPack(); 
		WritePackCell(hCheckData, GetClientUserId(iAdmin));
		WritePackCell(hCheckData, GetClientUserId(iClient));
		ResetPack(hCheckData);
		
		g_hDatabase.Query(SQL_CheckPlayerWarns, dbQuery, hCheckData);
		if(g_bLogQuery)
			LogQuery("CheckPlayerWarns::SQL_CheckPlayerWarns: %s", dbQuery);
	}
}

public void SQL_CheckPlayerWarns(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, Handle hCheckData)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
	{
		LogWarnings("[WarnSystem] SQL_CheckPlayerWarns - error while working with data (%s)", sError);
		return;
	}
	
	DisplayCheckWarnsMenu(hDatabaseResults, hCheckData); // Transfer to menus.sp
}

//------------------------------------------------GET INFO ABOUT WARN--------------------------------------------------------

public void SQL_GetInfoWarn(Database hDatabase, DBResultSet hDatabaseResults, const char[] szError, any iAdmin)
{
	if (hDatabaseResults == INVALID_HANDLE || szError[0])
	{
		LogWarnings("[WarnSystem] SQL_GetInfoWarn - error while working with data (%s)", szError);
		return;
	}
	
	DisplayInfoAboutWarn(hDatabaseResults, iAdmin); // Transfer to menus.sp
}

public void SQL_CheckError(Database hDatabase, DBResultSet hDatabaseResults, const char[] sError, any data)
{
	if (hDatabaseResults == INVALID_HANDLE || sError[0])
		LogWarnings("[WarnSystem] SQL_CheckError: %s", sError);
}