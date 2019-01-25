public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("LR_GetDatabase", Native_LR_GetDatabase);
	CreateNative("LR_GetDatabaseType", Native_LR_GetDatabaseType);
	CreateNative("LR_GetTableName", Native_LR_GetTableName);
	CreateNative("LR_CheckCountPlayers", Native_LR_CheckCountPlayers);
	CreateNative("LR_GetTypeStatistics", Native_LR_GetTypeStatistics);
	CreateNative("LR_GetClientPos", Native_LR_GetClientPos);
	CreateNative("LR_GetClientInfo", Native_LR_GetClientInfo);
	CreateNative("LR_ChangeClientValue", Native_LR_ChangeClientValue);
	CreateNative("LR_SetMultiplierValue", Native_LR_SetMultiplierValue);
	CreateNative("LR_RoundWithoutValue", Native_LR_RoundWithoutValue);
	CreateNative("LR_MenuInventory", Native_LR_MenuInventory);
	CreateNative("LR_MenuTopMenu", Native_LR_MenuTopMenu);
	CreateNative("LR_MenuAdminPanel", Native_LR_MenuAdminPanel);
	RegPluginLibrary("levelsranks");
}

public int Native_LR_GetDatabase(Handle hPlugin, int iNumParams)
{
	return view_as<int>(CloneHandle(g_hDatabase, hPlugin));
}

public int Native_LR_GetDatabaseType(Handle hPlugin, int iNumParams)
{
	return g_bDatabaseSQLite;
}

public int Native_LR_GetTableName(Handle hPlugin, int iNumParams)
{
	SetNativeString(1, g_sTableName, GetNativeCell(2), false);
}

public int Native_LR_CheckCountPlayers(Handle hPlugin, int iNumParams)
{
	if(g_iCountPlayers >= g_iMinimumPlayers)
		return true;
	return false;
}

public int Native_LR_GetTypeStatistics(Handle hPlugin, int iNumParams)
{
	return g_iTypeStatistics;
}

public int Native_LR_GetClientPos(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	if(CheckStatus(iClient))
		return g_iDBRankPlayer[iClient];
	return 0;
}

public int Native_LR_GetClientInfo(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iStats = GetNativeCell(2);

	if(CheckStatus(iClient))
	{
		switch(iStats)
		{
			case 0: return g_iExp[iClient];
			case 1: return g_iRank[iClient];
			case 2: return g_iKills[iClient];
		}
	}

	return 0;
}

public int Native_LR_ChangeClientValue(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iValue = GetNativeCell(2);

	if(CheckStatus(iClient))
	{
		int iExpMin = (g_iTypeStatistics == 0 ? 0 : 400);
		g_iExp[iClient] += iValue;

		if(g_iExp[iClient] < iExpMin)
		{
			g_iExp[iClient] = iExpMin;
		}

		CheckRank(iClient);
		return g_iExp[iClient];
	}

	return 0;
}

public int Native_LR_SetMultiplierValue(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(g_iTypeStatistics == 0 && CheckStatus(iClient))
	{
		g_fCoefficient[iClient] = GetNativeCell(2);
		return true;
	}

	return false;
}

public int Native_LR_RoundWithoutValue(Handle hPlugin, int iNumParams)
{
	g_bRoundWithoutExp = true;
}

public int Native_LR_MenuInventory(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient))
	{
		InventoryMenu(iClient);
	}
}

public int Native_LR_MenuTopMenu(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient))
	{
		PrintTop(iClient);
	}
}

public int Native_LR_MenuAdminPanel(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);

	if(CheckStatus(iClient))
	{
		MainAdminMenu(iClient);
	}
}