public Action OnClientSayCommand(int iClient, const char[] command, const char[] sArgs)
{
	if(CheckStatus(iClient))
	{
		if(!strcmp(sArgs, "top", false) || !strcmp(sArgs, "!top", false))
		{
			PrintTopExp(iClient);
		}
		else if(!strcmp(sArgs, "toptime", false) || !strcmp(sArgs, "!toptime", false))
		{
			PrintTopTime(iClient);
		}
		else if(!strcmp(sArgs, "session", false) || !strcmp(sArgs, "!session", false))
		{
			FullMyStatsSession(iClient);
		}
		else if(!strcmp(sArgs, "rank", false) || !strcmp(sArgs, "!rank", false))
		{
			if(g_bRankMessage)
			{
				for(int i = 1; i <= MaxClients; i++)
				{
					if(CheckStatus(i)) LR_PrintToChat(i, "%T", "RankPlayer", i, iClient, g_iDBRankPlayer[iClient], g_iDBCountPlayers, g_iExp[iClient], g_iKills[iClient], g_iDeaths[iClient], float(g_iKills[iClient] > 0 ? g_iKills[iClient] : 1) / float(g_iDeaths[iClient] > 0 ? g_iDeaths[iClient] : 1));
				}
			}
			else LR_PrintToChat(iClient, "%T", "RankPlayer", iClient, iClient, g_iDBRankPlayer[iClient], g_iDBCountPlayers, g_iExp[iClient], g_iKills[iClient], g_iDeaths[iClient], float(g_iKills[iClient] > 0 ? g_iKills[iClient] : 1) / float(g_iDeaths[iClient] > 0 ? g_iDeaths[iClient] : 1));
		}
	}

	return Plugin_Continue;
}

public Action ResetSettings(int iClient, int iArgs)
{
	SetSettings(true);
	Call_StartForward(g_hForward_OnSettingsModuleUpdate);
	Call_Finish();
	LR_PrintToChat(iClient, "%T", "ConfigUpdated", iClient);
	return Plugin_Handled;
}

public Action ResetStatsFull(int iClient, int iArgs)
{
	ResetStats();
	return Plugin_Handled;
}

public Action ResetStatsPlayer(int iClient, int iArgs)
{
	if(iArgs != 1)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_lvl_del <steamid>");
		return Plugin_Handled;
	}
	
	if(!g_hDatabase)
	{
		LogLR("ResetStats - database is invalid");
		return Plugin_Handled;
	}
	
	char sArg[65], sQuery[256];

	GetCmdArg(1, sArg, 65);
	FormatEx(sQuery, sizeof(sQuery), "DELETE FROM `%s` WHERE `steam` = '%s';", g_sTableName, sArg);

	LR_PrintToChat(iClient, "%T", "PlayerDataDeleted", iClient, sArg);
	SQL_FastQuery(g_hDatabase, sQuery);

	return Plugin_Handled;
}

public Action CallMainMenu(int iClient, int iArgs)
{
	MainMenu(iClient);
	return Plugin_Handled;
}

void MainMenu(int iClient)
{
	char sBuffer[32], sText[128];
	Menu hMenu = new Menu(MainMenuHandler);

	switch(g_iRank[iClient])
	{
		case 0, 18: FormatEx(sBuffer, sizeof(sBuffer), "%i", g_iExp[iClient]);
		default: FormatEx(sBuffer, sizeof(sBuffer), "%i / %i", g_iExp[iClient], g_iShowExp[g_iRank[iClient] + 1]);
	}

	hMenu.SetTitle(PLUGIN_NAME ... " " ... PLUGIN_VERSION ... "\n \n%T\n ", "MainMenu", iClient, g_sShowRank[g_iRank[iClient]], sBuffer, g_iDBRankPlayer[iClient], g_iDBCountPlayers);

	FormatEx(sText, sizeof(sText), "%T", "FullMyStats", iClient); hMenu.AddItem("0", sText);
	FormatEx(sText, sizeof(sText), "%T", "TOP", iClient); hMenu.AddItem("1", sText);
	FormatEx(sText, sizeof(sText), "%T\n ", "AllRanks", iClient); hMenu.AddItem("2", sText);

	if(g_bInventory) {FormatEx(sText, sizeof(sText), "%T", "SettingsLRMenu", iClient); hMenu.AddItem("3", sText);}

	int flags = GetUserFlagBits(iClient);
	if(flags & g_iAdminFlag || flags & ADMFLAG_ROOT)
	{
		FormatEx(sText, sizeof(sText), "%T", "MainAdminMenu", iClient); hMenu.AddItem("4", sText);
	}

	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

MenuLR(MainMenuHandler)
{	
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char sInfo[2];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			switch(StringToInt(sInfo))
			{
				case 0: FullMyStats(iClient);
				case 1: PrintTop(iClient);
				case 2: AllRankMenu(iClient);
				case 3: InventoryMenu(iClient);
				case 4: MainAdminMenu(iClient);
			}
		}
	}
}

void PrintTop(int iClient)
{
	char sText[128];
	Menu hMenu = new Menu(PrintTop_Callback);
	hMenu.SetTitle(PLUGIN_NAME ... " | %T\n ", "TOP", iClient);

	FormatEx(sText, sizeof(sText), "%T", "TOPExp", iClient);
	hMenu.AddItem("0", sText);

	FormatEx(sText, sizeof(sText), "%T", "TOPTime", iClient);
	hMenu.AddItem("1", sText);

	Call_StartForward(g_hForward_OnMenuCreatedTop);
	Call_PushCell(iClient);
	Call_PushCellRef(hMenu);
	Call_Finish();

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

MenuLR(PrintTop_Callback)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainMenu(iClient);}
		case MenuAction_Select:
		{
			char sInfo[32];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			if(strcmp(sInfo, "0") == 0)
			{
				PrintTopExp(iClient);
			}

			if(strcmp(sInfo, "1") == 0)
			{
				PrintTopTime(iClient);
			}

			Call_StartForward(g_hForward_OnMenuItemSelectedTop);
			Call_PushCell(iClient);
			Call_PushString(sInfo);
			Call_Finish();
		}
	}
}

void PrintTopExp(int iClient)
{
	if(CheckStatus(iClient))
	{
		char sQuery[128];
		FormatEx(sQuery, sizeof(sQuery), g_sSQL_CallTOP, g_sTableName);
		g_hDatabase.Query(SQL_PrintTopExp, sQuery, iClient);
	}
}

DBCallbackLR(SQL_PrintTopExp)
{
	if(dbRs == null)
	{
		LogLR("SQL_PrintTopExp - error while working with data (%s)", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}

	if(CheckStatus(iClient))
	{
		int i;
		char sText[256], sName[32], sTemp[512];

		while(dbRs.HasResults && dbRs.FetchRow())
		{
			i++;
			dbRs.FetchString(0, sName, sizeof(sName));
			FormatEx(sText, sizeof(sText), "%d - [ %d ] - %s\n", i, dbRs.FetchInt(1), sName);

			if(strlen(sTemp) + strlen(sText) < 512)
			{
				Format(sTemp, sizeof(sTemp), "%s%s", sTemp, sText);
				sText = "\0";
			}
		}

		Menu hMenu = new Menu(PrintTopExpMenuHandler);
		hMenu.SetTitle(PLUGIN_NAME ... " | %T\n \n%s\n ", "TOPExp", iClient, sTemp);

		FormatEx(sText, sizeof(sText), "%T", "BackToMainMenu", iClient);
		hMenu.AddItem("1", sText);

		hMenu.ExitButton = true;
		hMenu.Display(iClient, MENU_TIME_FOREVER);
	}
}

MenuLR(PrintTopExpMenuHandler)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select: MainMenu(iClient);
	}
}

void PrintTopTime(int iClient)
{
	if(CheckStatus(iClient))
	{
		char sQuery[128];
		FormatEx(sQuery, sizeof(sQuery), g_sSQL_CallTOPTime, g_sTableName);
		g_hDatabase.Query(SQL_PrintTopTime, sQuery, iClient);
	}
}

DBCallbackLR(SQL_PrintTopTime)
{
	if(dbRs == null)
	{
		LogLR("SQL_PrintTopTime - error while working with data (%s)", sError);
		if(StrContains(sError, "Lost connection to MySQL", false) != -1)
		{
			TryReconnectDB();
		}
		return;
	}

	if(CheckStatus(iClient))
	{
		int i;
		char sText[256], sName[32], sTemp[512];

		while(dbRs.HasResults && dbRs.FetchRow())
		{
			i++;
			dbRs.FetchString(0, sName, sizeof(sName));
			int iTime = dbRs.FetchInt(1);
			FormatEx(sText, sizeof(sText), "%d - [ %02d d %02d h %02d min ] - %s\n", i, iTime / 86400, iTime / 3600 % 24, iTime / 60 % 60, sName);

			if(strlen(sTemp) + strlen(sText) < 512)
			{
				Format(sTemp, sizeof(sTemp), "%s%s", sTemp, sText);
				sText = "\0";
			}
		}

		Menu hMenu = new Menu(PrintTopTimeMenuHandler);
		hMenu.SetTitle(PLUGIN_NAME ... " | %T\n \n%s\n ", "TOPTime", iClient, sTemp);

		FormatEx(sText, sizeof(sText), "%T", "BackToMainMenu", iClient);
		hMenu.AddItem("1", sText);

		hMenu.ExitButton = true;
		hMenu.Display(iClient, MENU_TIME_FOREVER);
	}
}

MenuLR(PrintTopTimeMenuHandler)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select: MainMenu(iClient);
	}
}

void AllRankMenu(int iClient)
{
	char sText[192];
	Menu hMenu = new Menu(AllRankMenuHandler);
	hMenu.SetTitle(PLUGIN_NAME ... " | %T\n ", "AllRanks", iClient);

	for(int i = 1; i <= 18; i++)
	{
		if(i > 1)
		{
			FormatEx(sText, sizeof(sText), "[%i] %s", g_iShowExp[i], g_sShowRank[i]);
			hMenu.AddItem("", sText, ITEMDRAW_DISABLED);
		}
		else
		{
			FormatEx(sText, sizeof(sText), "%s", g_sShowRank[i]);
			hMenu.AddItem("", sText, ITEMDRAW_DISABLED);
		}
	}

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

MenuLR(AllRankMenuHandler)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainMenu(iClient);}
	}
}

void InventoryMenu(int iClient)
{
	Menu hMenu = new Menu(MenuHandler_Category);
	hMenu.SetTitle(PLUGIN_NAME ... " | %T\n ", "SettingsLRMenu", iClient);
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;

	Call_StartForward(g_hForward_OnMenuCreated);
	Call_PushCell(iClient);
	Call_PushCellRef(hMenu);
	Call_Finish();

	if(hMenu.ItemCount == 0)
	{
		hMenu.AddItem("", "-----");
	}

	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

MenuLR(MenuHandler_Category)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainMenu(iClient);}
		case MenuAction_Select:
		{
			char sInfo[64];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			Call_StartForward(g_hForward_OnMenuItemSelected);
			Call_PushCell(iClient);
			Call_PushString(sInfo);
			Call_Finish();
		}
	}

	return 0;
}

void FullMyStats(int iClient)
{
	char sText[128];
	Menu hMenu = new Menu(FullStats_Callback);

	int iRoundsAll = g_iRoundWinStats[iClient] + g_iRoundLoseStats[iClient];
	hMenu.SetTitle(PLUGIN_NAME ... " | %T\n ", "FullStats", iClient, g_iPlayTime[iClient] / 3600, g_iPlayTime[iClient] / 60 % 60, g_iPlayTime[iClient] % 60, g_iKills[iClient], g_iDeaths[iClient], g_iAssists[iClient], g_iHeadshots[iClient], RoundToCeil((100.00 / float(g_iKills[iClient] > 0 ? g_iKills[iClient] : 1)) * float(g_iHeadshots[iClient] > 0 ? g_iHeadshots[iClient] : 1)), float(g_iKills[iClient] > 0 ? g_iKills[iClient] : 1) / float(g_iDeaths[iClient] > 0 ? g_iDeaths[iClient] : 1), g_iShoots[iClient], g_iHits[iClient], RoundToCeil((100.00 / float(g_iShoots[iClient] > 0 ? g_iShoots[iClient] : 1)) * float(g_iHits[iClient] > 0 ? g_iHits[iClient] : 1)), iRoundsAll, g_iRoundWinStats[iClient], RoundToCeil((100.00 / float(iRoundsAll > 0 ? iRoundsAll : 1)) * float(g_iRoundWinStats[iClient] > 0 ? g_iRoundWinStats[iClient] : 1)));

	FormatEx(sText, sizeof(sText), "%T", "FullMyStatsSession", iClient);
	hMenu.AddItem("0", sText);

	if(g_bResetRank)
	{
		FormatEx(sText, sizeof(sText), "%T", "ResetMyStats", iClient);
		hMenu.AddItem("1", sText);
	}

	FormatEx(sText, sizeof(sText), "%T", "BackToMainMenu", iClient);
	hMenu.AddItem("2", sText);

	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

MenuLR(FullStats_Callback)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char sInfo[2];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			switch(StringToInt(sInfo))
			{
				case 0: FullMyStatsSession(iClient);
				case 1: ResetMyStatsMenu(iClient);
				case 2: MainMenu(iClient);
			}
		}
	}
}

void FullMyStatsSession(int iClient)
{
	char sText[128], sBuffer[64];
	Menu hMenu = new Menu(FullStatsSession_Callback);

	int iRoundsAll = g_iClientSessionData[iClient][7] + g_iClientSessionData[iClient][8];
	int iDifference = g_iExp[iClient] - g_iClientSessionData[iClient][0];
	FormatEx(sBuffer, sizeof(sBuffer), "%s%i", iDifference == 0 ? "" : iDifference > 0 ? "+" : "-", iDifference > 0 ? iDifference : -iDifference);

	hMenu.SetTitle(PLUGIN_NAME ... " | %T\n ", "FullStatsSession", iClient, sBuffer, g_iClientSessionData[iClient][9] / 3600, g_iClientSessionData[iClient][9] / 60 % 60, g_iClientSessionData[iClient][9] % 60, g_iClientSessionData[iClient][1], g_iClientSessionData[iClient][2], g_iClientSessionData[iClient][6], g_iClientSessionData[iClient][5], RoundToCeil((100.00 / float(g_iClientSessionData[iClient][1] > 0 ? g_iClientSessionData[iClient][1] : 1)) * float(g_iClientSessionData[iClient][5] > 0 ? g_iClientSessionData[iClient][5] : 1)), float(g_iClientSessionData[iClient][1] > 0 ? g_iClientSessionData[iClient][1] : 1) / float(g_iClientSessionData[iClient][2] > 0 ? g_iClientSessionData[iClient][2] : 1), g_iClientSessionData[iClient][3], g_iClientSessionData[iClient][4], RoundToCeil((100.00 / float(g_iClientSessionData[iClient][3] > 0 ? g_iClientSessionData[iClient][3] : 1)) * float(g_iClientSessionData[iClient][4] > 0 ? g_iClientSessionData[iClient][4] : 1)), iRoundsAll, g_iClientSessionData[iClient][7], RoundToCeil((100.00 / float(iRoundsAll > 0 ? iRoundsAll : 1)) * float(g_iClientSessionData[iClient][7] > 0 ? g_iClientSessionData[iClient][7] : 1)));

	FormatEx(sText, sizeof(sText), "%T", "BackToMainMenu", iClient);
	hMenu.AddItem("", sText);

	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

MenuLR(FullStatsSession_Callback)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select: MainMenu(iClient);
	}
}

void ResetMyStatsMenu(int iClient)
{
	char sText[192];
	Menu hMenu = new Menu(ResetMyStatsMenu_Callback);
	hMenu.SetTitle(PLUGIN_NAME ... " | %T\n ", "ResetMyStatsMenu", iClient);

	FormatEx(sText, sizeof(sText), "%T", "Yes", iClient);
	hMenu.AddItem("", sText);

	FormatEx(sText, sizeof(sText), "%T", "No", iClient);
	hMenu.AddItem("", sText);

	hMenu.ExitButton = false;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

MenuLR(ResetMyStatsMenu_Callback)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			switch(iSlot)
			{
				case 0:
				{
					if(g_iTypeStatistics == 0)
					{
						g_iExp[iClient] = 0;
					}
					else g_iExp[iClient] = 1000;

					g_iRank[iClient] = 0;
					g_iKills[iClient] = 0;
					g_iHeadshots[iClient] = 0;
					g_iHits[iClient] = 0;
					g_iDeaths[iClient] = 0;
					g_iShoots[iClient] = 0;
					g_iAssists[iClient] = 0;
					g_iRoundWinStats[iClient] = 0;
					g_iRoundLoseStats[iClient] = 0;
					g_iPlayTime[iClient] = 0;

					CheckRank(iClient);
					MainMenu(iClient);
				}
				case 1: MainMenu(iClient);
			}
		}
	}
}

void MainAdminMenu(int iClient)
{
	char sText[192];
	Menu hMenu = new Menu(MainAdminMenu_Callback);
	hMenu.SetTitle(PLUGIN_NAME ... " | %T\n ", "MainAdminMenu", iClient);

	FormatEx(sText, sizeof(sText), "%T", "ReloadAllConfigs", iClient);
	hMenu.AddItem("0", sText);

	if(g_iTypeStatistics == 0)
	{
		FormatEx(sText, sizeof(sText), "%T", "GiveTakeMenuExp", iClient);
		hMenu.AddItem("1", sText);
	}

	Call_StartForward(g_hForward_OnMenuCreatedAdmin);
	Call_PushCell(iClient);
	Call_PushCellRef(hMenu);
	Call_Finish();

	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

MenuLR(MainAdminMenu_Callback)
{
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			if(iSlot == MenuCancel_ExitBack)
			{
				MainMenu(iClient);
			}
		}
		case MenuAction_Select:
		{
			char sInfo[32];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo));

			if(strcmp(sInfo, "0") == 0)
			{
				SetSettings(true);
				Call_StartForward(g_hForward_OnSettingsModuleUpdate);
				Call_Finish();
				LR_PrintToChat(iClient, "%T", "ConfigUpdated", iClient);
			}

			if(strcmp(sInfo, "1") == 0)
			{
				GiveTakeValue(iClient);
			}

			Call_StartForward(g_hForward_OnMenuItemSelectedAdmin);
			Call_PushCell(iClient);
			Call_PushString(sInfo);
			Call_Finish();
		}
	}
}

void GiveTakeValue(int iClient)
{
	char sID[16], sNickName[32];
	Menu hMenu = new Menu(GiveTakeValueHandler);
	hMenu.SetTitle(PLUGIN_NAME ... " | %T\n ", "GiveTakeMenuExp", iClient);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && CheckStatus(i))
		{
			IntToString(GetClientUserId(i), sID, 16);
			sNickName[0] = '\0';
			GetClientName(i, sNickName, 32);
			hMenu.AddItem(sID, sNickName);
		}
	}
	
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

MenuLR(GiveTakeValueHandler)
{	
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {MainAdminMenu(iClient);}
		case MenuAction_Select:
		{
			char sID[16];
			hMenu.GetItem(iSlot, sID, 16);

			int iRecipient = GetClientOfUserId(StringToInt(sID));
			if(CheckStatus(iRecipient))
			{
				GiveTakeValueEND(iClient, sID);
			}
			else GiveTakeValue(iClient);
		}
	}
}

public void GiveTakeValueEND(int iClient, char[] sID) 
{
	Menu hMenu = new Menu(ChangeExpPlayersENDHandler);
	hMenu.SetTitle(PLUGIN_NAME ... " | %T\n ", "GiveTakeMenuExp", iClient);
	hMenu.AddItem(sID, "100");
	hMenu.AddItem(sID, "500");
	hMenu.AddItem(sID, "1000");
	hMenu.AddItem(sID, "-1000");
	hMenu.AddItem(sID, "-500");
	hMenu.AddItem(sID, "-100");
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = true;
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

MenuLR(ChangeExpPlayersENDHandler)
{	
	switch(mAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if(iSlot == MenuCancel_ExitBack) {GiveTakeValue(iClient);}
		case MenuAction_Select:
		{
			char sInfo[32], sBuffer[32], sBuffer2[PLATFORM_MAX_PATH];
			hMenu.GetItem(iSlot, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));
			int iRecipient = GetClientOfUserId(StringToInt(sInfo));
			int iBuffer = StringToInt(sBuffer);

			if(CheckStatus(iRecipient))
			{
				GiveTakeValueEND(iClient, sInfo);
				g_iExp[iRecipient] += iBuffer;
				if(g_iExp[iRecipient] < 0) g_iExp[iRecipient] = 0;
				CheckRank(iRecipient);

				if(g_bUsualMessage)
				{
					FormatEx(sBuffer, sizeof(sBuffer), "%s%i", iBuffer > 0 ? "+" : "-", iBuffer > 0 ? iBuffer : -iBuffer);
					LR_PrintToChat(iRecipient, "%T", iBuffer > 0 ? "AdminGive" : "AdminTake", iRecipient, g_iExp[iRecipient], sBuffer);
				}

				FormatEx(sBuffer2, sizeof(sBuffer2), "%s%i", iBuffer > 0 ? "+" : "-", iBuffer > 0 ? iBuffer : -iBuffer);
				LR_PrintToChat(iClient, "%N - {GRAY}%i (%s)", iRecipient, g_iExp[iRecipient], sBuffer2);
			}
		}
	}
}