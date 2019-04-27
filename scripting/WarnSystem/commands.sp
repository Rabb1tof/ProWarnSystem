public void InitializeCommands()
{
	RegConsoleCmd("sm_warn", Command_WarnPlayer);
	RegConsoleCmd("sm_unwarn", Command_UnWarnPlayer);
	RegConsoleCmd("sm_checkwarn", Command_CheckWarnPlayer);
	RegConsoleCmd("sm_resetwarn", Command_WarnReset);
	RegConsoleCmd("ws_update_sql", Command_UpdateSQL);
}

public Action Command_WarnPlayer(int iClient, int iArgs)
{
	if(GetUserFlagBits(iClient) || VIP_GetClientFeatureStatus(iClient, "Warns") == ENABLED)
	{
		if (iArgs < 3)
		{
			ReplyToCommand(iClient, " %t %t", "WS_Prefix", "WS_WarnArguments");
			return Plugin_Handled;
		}

		char sBuffer[128], sReason[129];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		int iTarget = FindTarget(iClient, sBuffer, true, true);
		if (!iTarget)
			return Plugin_Handled;
		
		GetCmdArg(2, sBuffer, sizeof(sBuffer));
		int iScore = StringToInt(sBuffer);
		GetCmdArg(3, sBuffer, sizeof(sBuffer));
		int iTime = StringToInt(sBuffer);
		GetCmdArg(4, sReason, sizeof(sReason));
		if (iArgs > 5)
			for (int i = 5; i <= iArgs; ++i)
			{
				GetCmdArg(i, sBuffer, sizeof(sBuffer));
				Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
			}
			
		WarnPlayer(iClient, iTarget, iScore, iTime, sReason); // sm_warn <#userid> <score> <time> <reason>
		return Plugin_Handled;
	}	return Plugin_Continue;
}	

public Action Command_UnWarnPlayer(int iClient, int iArgs)
{
	if(GetUserFlagBits(iClient) || VIP_GetClientFeatureStatus(iClient, "Unwarns") == ENABLED)
	{
		if (iArgs < 3)
		{
			ReplyToCommand(iClient, " %t %t", "WS_Prefix", "WS_UnWarnArguments");
			return Plugin_Handled;
		}
		char sBuffer[128], sReason[129];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		int iTarget = FindTarget(iClient, sBuffer, true, true);
		if (!iTarget)
			return Plugin_Handled;
		/*GetCmdArg(3, sBuffer, sizeof(sBuffer));
		int iScore = StringToInt(sBuffer);*/
		
		GetCmdArg(2, sReason, sizeof(sReason));
		if (iArgs > 2)
			for (int i = 3; i <= iArgs; ++i)
			{
				GetCmdArg(i, sBuffer, sizeof(sBuffer));
				Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
			}
		
		UnWarnPlayer(iClient, iTarget, sReason);
		return Plugin_Handled;
	}	return Plugin_Continue;
}

public Action Command_WarnReset(int iClient, int iArgs)
{
	if(GetUserFlagBits(iClient) || VIP_GetClientFeatureStatus(iClient, "Unwarns") == ENABLED)
	{
		if(!g_bResetWarnings)
		{
			ReplyToCommand(iClient, " %t %t", "WS_Prefix", "No Access");
			return Plugin_Handled;
		}
		if (iArgs < 2)
		{
			ReplyToCommand(iClient, " %t %t", "WS_Prefix", "WS_ResetWarnArguments");
			return Plugin_Handled;
		}
		char sBuffer[128], sReason[129];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		int iTarget = FindTarget(iClient, sBuffer, true, true);
		if (!iTarget)
			return Plugin_Handled;
		
		GetCmdArg(2, sReason, sizeof(sReason));
		if (iArgs > 2)
			for (int i = 3; i <= iArgs; ++i)
			{
				GetCmdArg(i, sBuffer, sizeof(sBuffer));
				Format(sReason, sizeof(sReason), "%s %s", sReason, sBuffer);
			}
		
		ResetPlayerWarns(iClient, iTarget, sReason);
		return Plugin_Handled;
	}	return Plugin_Continue;
}

public Action Command_CheckWarnPlayer(int iClient, int iArgs)
{
	if (!iClient)
	{
		PrintToServer(" %t %t", "WS_Prefix", "Command is in-game only");
		return Plugin_Handled;
	}
	if (!iArgs)
	{
		ReplyToCommand(iClient, " %t %t", "WS_Prefix", "WS_CheckWarnArguments");
		return Plugin_Handled;
	}
	char sBuffer[128];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	int iTarget = FindTarget(iClient, sBuffer, true, true);
	if (!iTarget)
		return Plugin_Handled;
	CheckPlayerWarns(iClient, iTarget);
	return Plugin_Handled;
}

public Action Command_UpdateSQL(int iClient, int iArgs)
{
	if(!iArgs && IsValidClient(iClient))
	{
		UTIL_DisplayUpdateSQL(iClient);
		return Plugin_Handled;
	}
	char szBuffer[12];
	GetCmdArg(1, szBuffer, sizeof(szBuffer));
	if(StrEqual(szBuffer, "mysql")) {
		UTIL_UpdateSQL(iClient, true);
	}
	else if(StrEqual(szBuffer, "sqlite")) {
		UTIL_UpdateSQL(iClient, false);
	}
	else
		ReplyToCommand(iClient, " %t %t", "WS_Prefix", "WS_InvalidArgument");
	return Plugin_Handled;
}