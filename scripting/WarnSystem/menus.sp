Handle g_hAdminMenu;
int g_iTarget[MAXPLAYERS+1];

public void InitializeMenu(Handle hTopMenu)
{
	if (hTopMenu == g_hAdminMenu)
		return;
	
	g_hAdminMenu = hTopMenu;
	TopMenuObject WarnCategory = FindTopMenuCategory(g_hAdminMenu, "warnmenu");
	
	if (!WarnCategory)
		WarnCategory = AddToTopMenu(g_hAdminMenu, "warnmenu", TopMenuObject_Category, Handle_AdminCategory, INVALID_TOPMENUOBJECT, "sm_warnmenu", ADMFLAG_GENERIC);
	
	AddToTopMenu(g_hAdminMenu, "sm_warn", TopMenuObject_Item, AdminMenu_Warn, WarnCategory, "sm_warn", ADMFLAG_GENERIC);
	AddToTopMenu(g_hAdminMenu, "sm_unwarn", TopMenuObject_Item, AdminMenu_UnWarn, WarnCategory, "sm_unwarn", ADMFLAG_GENERIC);
	AddToTopMenu(g_hAdminMenu, "sm_resetwarn", TopMenuObject_Item, AdminMenu_ResetWarn, WarnCategory, "sm_resetwarn", ADMFLAG_GENERIC);
	AddToTopMenu(g_hAdminMenu, "sm_checkwarn", TopMenuObject_Item, AdminMenu_CheckWarn, WarnCategory, "sm_checkwarn", ADMFLAG_GENERIC);
}

public void Handle_AdminCategory(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuTitle", param);
	else if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuOption", param);
}

public void AdminMenu_Warn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuWarnTitle", param);
	else if (action == TopMenuAction_SelectOption)
		DisplaySomeoneTargetMenu(param, MenuHandler_Warn);
}

public void AdminMenu_UnWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuUnWarnTitle", param);
	else if (action == TopMenuAction_SelectOption)
		DisplaySomeoneTargetMenu(param, MenuHandler_UnWarn);
}

public void AdminMenu_ResetWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuResetWarnTitle", param);
	else if (action == TopMenuAction_SelectOption)
		DisplaySomeoneTargetMenu(param, MenuHandler_ResetWarn);
}

public void AdminMenu_CheckWarn(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		FormatEx(buffer, maxlength, "%T", "WS_AdminMenuCheckWarnTitle", param);
	else if (action == TopMenuAction_SelectOption)
		DisplaySomeoneTargetMenu(param, MenuHandler_CheckWarn);
}

public void DisplaySomeoneTargetMenu(int iClient, MenuHandler ptrFunc) {
	Menu hMenu = new Menu(ptrFunc);
	SetMenuTitle(hMenu, "%T", "WS_TargetMenuTitle", iClient);
	SetMenuExitBackButton(hMenu, true);
	AddTargetsToMenuCustom(hMenu, iClient);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

stock void AddTargetsToMenuCustom(Menu hMenu, int iAdmin)
{
	char sUserId[12], sName[128], sDisplay[128+12];
	for (int i = 1; i <= MaxClients; ++i) {
		if (IsClientConnected(i) && !IsClientInKickQueue(i) && !IsFakeClient(i) && IsClientInGame(i) && /*iAdmin != i &&*/ CanUserTarget(iAdmin, i))
		{
			GetClientName(i, sName, sizeof(sName));
			switch(g_iWarnType) {
				case 0: FormatEx(sDisplay, sizeof(sDisplay), "%s [%i/%i]", sName, g_iWarnings[i], g_iMaxWarns);
				case 1: FormatEx(sDisplay, sizeof(sDisplay), "%s [%i/%i]", sName, g_iScore[i], g_iMaxScore);
				case 2: FormatEx(sDisplay, sizeof(sDisplay), "%s [%i/%i] [%i/%i]", sName, g_iWarnings[i], g_iMaxWarns, g_iScore[i], g_iMaxScore);
			}
				
			IntToString(GetClientUserId(i), sUserId, sizeof(sUserId));
			hMenu.AddItem(sUserId, sDisplay);
		}
	}
}

public int MenuHandler_Warn(Menu menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[8];
			int iTarget;
			
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			if (!(iTarget = GetClientOfUserId(StringToInt(sInfo))))
				WS_PrintToChat(param1, " %t %t", "WS_Prefix", "Player no longer available");
			else if (!CanUserTarget(param1, iTarget))
				WS_PrintToChat(param1, " %t %t", "WS_Prefix", "Unable to target");
			else
			{
				g_iTarget[param1] = iTarget;
				DisplayWarnReasons(param1);
			}
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public int MenuHandler_UnWarn(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[8];
			int iTarget;
			
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			if (!(iTarget = GetClientOfUserId(StringToInt(sInfo))))
				WS_PrintToChat(param1, " %t %t", "WS_Prefix", "Player no longer available");
			else if (!CanUserTarget(param1, iTarget))
				WS_PrintToChat(param1, " %t %t", "WS_Prefix", "Unable to target");
			else
			{
				g_iTarget[param1] = iTarget;
				DisplayUnWarnReasons(param1);
			}
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public int MenuHandler_ResetWarn(Menu menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[8];
			int iTarget;
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			if (!(iTarget = GetClientOfUserId(StringToInt(sInfo))))
				WS_PrintToChat(param1, " %t %t", "WS_Prefix", "Player no longer available");
			else if (!CanUserTarget(param1, iTarget))
				WS_PrintToChat(param1, " %t %t", "WS_Prefix", "Unable to target");
			else
			{
				g_iTarget[param1] = iTarget;
				DisplayResetWarnReasons(param1);
			}
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		
		case MenuAction_End:
			CloseHandle(menu);
	}
}

public int MenuHandler_CheckWarn(Menu menu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char sInfo[8];
			int iTarget;
			GetMenuItem(menu, param2, sInfo, sizeof(sInfo));
			
			if (!(iTarget = GetClientOfUserId(StringToInt(sInfo))))
				WS_PrintToChat(param1, " %t %t", "WS_Prefix", "Player no longer available");
			if (!CanUserTarget(param1, iTarget))
				WS_PrintToChat(param1, " %t %t", "WS_Prefix", "Unable to target");
			else
				CheckPlayerWarns(param1, iTarget);
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			
		case MenuAction_End:
			CloseHandle(menu);
	}
}

//-----------------------------------Display Update Menu----------------------------------
void UTIL_DisplayUpdateSQL(int iClient)
{
	
	
	Menu hMenu = new Menu(Handler_UpdateMenu);
	hMenu.SetTitle("%T", "WS_UpdateTitle");
	hMenu.AddItem(NULL_STRING, "MySQL");
	hMenu.AddItem(NULL_STRING, "SQLite");
	hMenu.ExitButton = true;
	hMenu.Display(iClient, 20);
}

public int Handler_UpdateMenu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action) {
		case MenuAction_Select: {
			if(iItem == 0) UTIL_UpdateSQL(iClient, true);
			else if(iItem == 1)	UTIL_UpdateSQL(iClient, false);
		}
		case MenuAction_End:	CloseHandle(hMenu);
	}
}

void CustomReasonETC(Menu hMenu, int iClient)
{
	char szBuffer[64];
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_Custom_ReasonWarn", iClient);
	hMenu.AddItem("custom_reason", szBuffer);
	//g_iTargetCustom = 
}

public void DisplayWarnReasons(int iClient) 
{
	char sReason[129], sFlags[13], sDisplay[250];
	int iScore, iTime;
	Menu hMenu = new Menu(MenuHandler_PreformWarn);
	hMenu.SetTitle("%T", "WS_AdminMenuReasonTitle", iClient);
	
	for(int i = 0; i < g_aWarn.Length; i++) {
		StringMap hWarn = g_aWarn.Get(i);
		if(!hWarn.GetString("warn", sReason, sizeof(sReason)))
			strcopy(sReason, sizeof(sReason), "Unknown reason");
		
		if(!hWarn.GetString("flags_warn", sFlags, sizeof(sFlags)))
			strcopy(sFlags, sizeof(sFlags), "Unknown flags");
		
		if (!(CheckAdminFlagsByString(iClient, sFlags))) continue;
		
		if(!hWarn.GetValue("time", iTime))
			iTime = 0;
		
		if(!hWarn.GetValue("score", iScore))
			iScore = 0; 
		
		FormatEx(sDisplay, sizeof(sDisplay), "[%i] %s", iScore, sReason);
		
		hMenu.AddItem(sReason, sDisplay);
	}

	if(g_bUseCustom)
		CustomReasonETC(hMenu, iClient);
	
	hMenu.ExitBackButton = true;
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayUnWarnReasons(int iClient) 
{
	//WS_PrintToChat(iClient, "Test");
	char sReason[129], sDisplay[250], sFlags[13];
	//int iFlags;
	
	Menu hMenu = new Menu(MenuHandler_PreformUnWarn);
	hMenu.SetTitle("%T", "WS_AdminMenuReasonTitle", iClient);
	hMenu.ExitBackButton = true;
	
	for(int i = 0; i < g_aUnwarn.Length; i++) {
		StringMap hUnwarn = g_aUnwarn.Get(i);
		if(!hUnwarn.GetString("unwarn", sReason, sizeof(sReason)))
			strcopy(sReason, sizeof(sReason), "Unknown reason");
		
		if(!hUnwarn.GetString("flags_unwarn", sFlags, sizeof(sFlags)))
			strcopy(sFlags, sizeof(sFlags), "Unknown flags");
		
		if (!(CheckAdminFlagsByString(iClient, sFlags))) continue;
		
		FormatEx(sDisplay, sizeof(sDisplay), "%s", sReason);
		hMenu.AddItem(sReason, sDisplay);
	}

	if(g_bUseCustom)
		CustomReasonETC(hMenu, iClient);

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public void DisplayResetWarnReasons(int iClient) 
{
	//WS_PrintToChatAll("Test2");
	char sReason[129], sDisplay[250], sFlags[13];
	//int iFlags;
	
	Menu hMenu = new Menu(MenuHandler_PreformResetWarn);
	hMenu.SetTitle("%T", "WS_AdminMenuReasonTitle", iClient);
	hMenu.ExitBackButton = true;
	
	for(int i = 0; i < g_aResetWarn.Length; i++) {
		StringMap hResetwarn = g_aResetWarn.Get(i);
		if(!hResetwarn.GetString("resetwarn", sReason, sizeof(sReason)))
			strcopy(sReason, sizeof(sReason), "Unknown reason");
		
		if(!hResetwarn.GetString("flags_resetwarn", sFlags, sizeof(sFlags)))
			strcopy(sFlags, sizeof(sFlags), "Unknown flags");
		
		if (!(CheckAdminFlagsByString(iClient, sFlags))) continue;
		
		FormatEx(sDisplay, sizeof(sDisplay), "%s", sReason);
		hMenu.AddItem(sReason, sDisplay);
	}

	if(g_bUseCustom)
		CustomReasonETC(hMenu, iClient);
	
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_PreformWarn(Menu hMenu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char szInfo[129], szReason[129];
			int iScore, iTime;
			hMenu.GetItem(param2, szInfo, sizeof(szInfo));
			for(int i = 0; i < g_aWarn.Length; i++) {
				StringMap hWarn = g_aWarn.Get(i);
				if(hWarn.GetString("warn", szReason, sizeof(szReason)) && StrEqual(szReason, szInfo) && hWarn.GetValue("time", iTime) && hWarn.GetValue("score", iScore)) {
					WarnPlayer(param1, g_iTarget[param1], iScore, iTime, szReason);
					break;
				}
			}
			if(StrEqual(szInfo, "custom_reason"))
			{
				WS_PrintToChat(param1, "%t", "WS_CustomWarn");
				g_iCustom[param1] = 1;
				PrintToChat(param1, "Debug: %d", g_iCustom[param1]);
			}
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
			
		case MenuAction_End:
			CloseHandle(hMenu);
	}
}

public int MenuHandler_PreformUnWarn(Menu hMenu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char szInfo[129], szReason[129];
			hMenu.GetItem(param2, szInfo, sizeof(szInfo));
			for(int i = 0; i < g_aUnwarn.Length; i++) {
				StringMap hUnwarn = g_aUnwarn.Get(i);
				if(hUnwarn.GetString("unwarn", szReason, sizeof(szReason)) && StrEqual(szReason, szInfo)) {
					UnWarnPlayer(param1, g_iTarget[param1], szReason);
					break;
				}
			}
			if(StrEqual(szInfo, "custom_reason"))
			{
				WS_PrintToChat(param1, "%t", "WS_CustomWarn");
				g_iCustom[param1] = 2;
				PrintToChat(param1, "Debug: %d", g_iCustom[param1]);
			}
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		
		case MenuAction_End:
			CloseHandle(hMenu);
	}
}

public int MenuHandler_PreformResetWarn(Menu hMenu, MenuAction action, int param1, int param2) 
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char szInfo[129], szReason[129];
			hMenu.GetItem(param2, szInfo, sizeof(szInfo));
			for(int i = 0; i < g_aResetWarn.Length; i++) {
				StringMap hResetwarn = g_aResetWarn.Get(i);
				if(hResetwarn.GetString("resetwarn", szReason, sizeof(szReason)) && StrEqual(szReason, szInfo)) {
					ResetPlayerWarns(param1, g_iTarget[param1], szReason);
					break;
				}
			}
			if(StrEqual(szInfo, "custom_reason"))
			{
				WS_PrintToChat(param1, "%t", "WS_CustomWarn");
				g_iCustom[param1] = 3;
				PrintToChat(param1, "Debug: %d", g_iCustom[param1]);
			}
		}
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack && g_hAdminMenu)
				DisplayTopMenu(g_hAdminMenu, param1, TopMenuPosition_LastCategory);
		
		case MenuAction_End:
			CloseHandle(hMenu);
	}
}

public void BuildAgreement(int iClient, int iAdmin, int iScore, int iTime, char[] szReason)
{
	Handle hFilePath = OpenFile(g_sPathAgreePanel, "rt");
	if (!hFilePath)
	{
		LogWarnings("Could not find the config file (addons/sourcemod/configs/WarnSystem/WarnAgreement.cfg)");
		return;
	}
	
	char sBuffer[128], szAdmin[20], szTimeFormat[128], szScore[8];
	
	Handle hMenu = CreatePanel();
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "WS_AgreementTitle", iClient);
	SetPanelTitle(hMenu, sBuffer);
	DrawPanelItem(hMenu, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	
	IntToString(iScore, szScore, sizeof(szScore));
	GetClientName(iAdmin, szAdmin, sizeof(szAdmin));
	FormatTime(szTimeFormat, sizeof(szTimeFormat), "%X", iTime);
	
	while(!IsEndOfFile(hFilePath) && ReadFileLine(hFilePath, sBuffer, sizeof(sBuffer))) {
		
		ReplaceString(sBuffer, sizeof(sBuffer), "{ADMIN}", szAdmin, false);
		ReplaceString(sBuffer, sizeof(sBuffer), "{REASON}", szReason, false);
		ReplaceString(sBuffer, sizeof(sBuffer), "{TIME}", szTimeFormat, false);
		ReplaceString(sBuffer, sizeof(sBuffer), "{SCORE}", szScore, false);
		DrawPanelText(hMenu, sBuffer);
	}
	DrawPanelItem(hMenu, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	FormatEx(sBuffer, sizeof(sBuffer), "%T", "WS_AgreementAgree", iClient);
	DrawPanelItem(hMenu, sBuffer);
	SendPanelToClient(hMenu, iClient, MenuHandler_WarnAgreement, MENU_TIME_FOREVER);
	
	CloseHandle(hMenu);
	CloseHandle(hFilePath);
}

public int MenuHandler_WarnAgreement(Handle hMenu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		WS_PrintToChat(param1, " %t %t", "WS_Prefix", "WS_AgreementMessage");
		if (IsPlayerAlive(param1))
			SetEntityMoveType(param1, MOVETYPE_WALK);
	} else if (action == MenuAction_End)
		CloseHandle(hMenu);
}

//------------------------------------------CREATE MENU WITH ALL WARNS OF TARGET---------------------------------------------

void DisplayCheckWarnsMenu(DBResultSet hDatabaseResults, Handle hCheckData)
{
	int iAdmin, iClient;
	
	if(hCheckData)
	{
		iAdmin = GetClientOfUserId(ReadPackCell(hCheckData));
		iClient = GetClientOfUserId(ReadPackCell(hCheckData));
		g_iUserID[iAdmin] = GetClientUserId(iClient);
		CloseHandle(hCheckData); 
	} else return;
	
	if (!hDatabaseResults.RowCount)
	{
		WS_PrintToChat(iAdmin, " %t %t", "WS_Prefix", "WS_NotWarned", iClient);
		return;
	}
	
	if(!IsValidClient(iAdmin))      return;
	
	//`ws_warn`.`warn_id`, `ws_player`.`account_id`, `ws_player`.`username`, `ws_warn`.`created_at`
	
	char szAdmin[129], szTimeFormat[65], szBuffer[80], szID[25];
	int iDate, iID;
	Menu hMenu = new Menu(CheckPlayerWarnsMenu);
	hMenu.SetTitle("%T:\n", "WS_CPWTitle", iAdmin, iClient);
	//Ya, nice output *NOW TO MENU, BITCHES*!
	
	while (hDatabaseResults.FetchRow())
	{
		iID = hDatabaseResults.FetchInt(0);
		IntToString(iID, szID, sizeof(szID));
		SQL_FetchString(hDatabaseResults, 2, szAdmin, sizeof(szAdmin));
		iDate = hDatabaseResults.FetchInt(3);
		
		
		FormatTime(szTimeFormat, sizeof(szTimeFormat), "%d-%m-%Y %X", iDate);
		FormatEx(szBuffer, sizeof(szBuffer), "[%s] %s", szAdmin, szTimeFormat);
		hMenu.AddItem(szID, szBuffer);
	}
	hMenu.ExitBackButton = true;
	hMenu.Display(iAdmin, MENU_TIME_FOREVER);
}

public int CheckPlayerWarnsMenu(Menu hMenu, MenuAction action, int param1, int iItem)
{
	switch(action){
		
		case MenuAction_Select: {
			char szdbQuery[513];
			char szID[25];
			int iID;
			hMenu.GetItem(iItem, szID, sizeof(szID));
			iID = StringToInt(szID);
			
			FormatEx(szdbQuery, sizeof(szdbQuery),  g_sSQL_GetInfoWarn, iID);
			g_hDatabase.Query(SQL_GetInfoWarn, szdbQuery, param1); // OH NO! DB-query in menus.sp!!! FUCK!!!
			if(g_bLogQuery)
				LogQuery("CheckPlayerWarnsMenu::SQL_GetInfoWarn: %s", szdbQuery);
		} 
		case MenuAction_End:    CloseHandle(hMenu);
		case MenuAction_Cancel: if(iItem == MenuCancel_ExitBack)    DisplaySomeoneTargetMenu(param1, MenuHandler_CheckWarn);
			
			
	}
}

//-------------------------------------CREATE MENU WITH INFORMATION ABOUT SELECTED WARN------------------------------------------

void DisplayInfoAboutWarn(DBResultSet hDatabaseResults, any iAdmin)
{
	if(!hDatabaseResults.FetchRow())     return;
	if(!IsValidClient(iAdmin))      return;
	char szClient[129], szAdmin[129], szReason[129], szTimeFormat[65], szBuffer[80];
	int iDate, iExpired, iScore;
	
	//                    0                            1                                 2                              3                      4                  5                       6
	//`admin`.`account_id` admin_id, `admin`.`username` admin_name, `player`.`account_id` client_id, `player`.`username` client_name, `ws_warn`.`reason` `ws_warn`.`expires_at`, `ws_warn`.`created_at`
	
	Menu hMenu = new Menu(GetInfoWarnMenu_CallBack);
	hMenu.SetTitle("%T:\n", "WS_InfoWarn", iAdmin);
	
	SQL_FetchString(hDatabaseResults, 1, szAdmin, sizeof(szAdmin));
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoAdmin", iAdmin, szAdmin);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	SQL_FetchString(hDatabaseResults, 3, szClient, sizeof(szClient));
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoClient", iAdmin, szClient);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	SQL_FetchString(hDatabaseResults, 4, szReason, sizeof(szReason));
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoReason", iAdmin ,szReason);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	iScore 	 = hDatabaseResults.FetchInt(5);
	iExpired = hDatabaseResults.FetchInt(6);
	iDate    = hDatabaseResults.FetchInt(7);
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoScore", iAdmin, iScore);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	FormatTime(szTimeFormat, sizeof(szTimeFormat), "%Y-%m-%d %X", iExpired);
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoExpired", iAdmin, szTimeFormat);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	FormatTime(szTimeFormat, sizeof(szTimeFormat), "%Y-%m-%d %X", iDate);
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "WS_InfoTime", iAdmin, szTimeFormat);
	hMenu.AddItem(NULL_STRING, szBuffer, ITEMDRAW_DISABLED);
	
	hMenu.ExitBackButton = true;
	hMenu.ExitButton = false;
	hMenu.Display(iAdmin, MENU_TIME_FOREVER);
}

public int GetInfoWarnMenu_CallBack(Menu hMenu, MenuAction action, int iAdmin, int iItem)
{
	switch(action){
		case MenuAction_End:    CloseHandle(hMenu);
		case MenuAction_Cancel: if(iItem == MenuCancel_ExitBack)    CheckPlayerWarns(iAdmin, GetClientOfUserId(g_iUserID[iAdmin]));
	}
}