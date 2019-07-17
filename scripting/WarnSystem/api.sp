Handle g_hGFwd_OnClientLoaded, g_hGFwd_OnClientWarn, g_hGFwd_OnClientUnWarn, g_hGFwd_OnClientResetWarns,
		g_hGFwd_WarnPunishment, g_hGFwd_WarnMaxPunishment, g_hGFwd_OnClientWarn_Pre, g_hGFwd_OnClientUnWarn_Pre, 
		g_hGFwd_OnClientResetWarns_Pre;
bool g_bIsLateLoad;

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_Max)
{
	CreateNative("WarnSystem_Warn", Native_WarnPlayer);
	CreateNative("WarnSystem_UnWarn", Native_UnWarnPlayer);
	CreateNative("WarnSystem_ResetWarn", Native_ResetWarnPlayer);
	CreateNative("WarnSystem_GetDatabase", Native_GetDatabase);
	CreateNative("WarnSystem_GetPlayerInfo", Native_GetPlayerInfo);
	CreateNative("WarnSystem_PrintToAdmins", Native_PrintToAdmins);
	CreateNative("WarnSystem_GetMaxWarns", Native_GetMaxWarns);
	CreateNative("WarnSystem_GetMaxScore", Native_MaxScore);
	
	g_hGFwd_OnClientLoaded = CreateGlobalForward("WarnSystem_OnClientLoaded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_hGFwd_OnClientWarn = CreateGlobalForward("WarnSystem_OnClientWarn", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_Cell);
	g_hGFwd_OnClientUnWarn = CreateGlobalForward("WarnSystem_OnClientUnWarn", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_OnClientResetWarns = CreateGlobalForward("WarnSystem_OnClientResetWarns", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_OnClientWarn_Pre = CreateGlobalForward("WarnSystem_OnClientWarnPre", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_Cell);
	g_hGFwd_OnClientUnWarn_Pre = CreateGlobalForward("WarnSystem_OnClientUnWarnPre", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_OnClientResetWarns_Pre = CreateGlobalForward("WarnSystem_OnClientResetWarnsPre", ET_Hook, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_WarnPunishment = CreateGlobalForward("WarnSystem_WarnPunishment", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_hGFwd_WarnMaxPunishment = CreateGlobalForward("WarnSystem_WarnMaxPunishment", ET_Hook, Param_Cell, Param_Cell, Param_Cell, Param_String);
	
	RegPluginLibrary("WarnSystem");
	
	g_bIsLateLoad = bLate;
	
	//STATS_MarkNativesAsOptional();
	
	return APLRes_Success;
}

public int Native_WarnPlayer(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iTarget = GetNativeCell(2);
	char sReason[129];
	int iScore = GetNativeCell(3);
	int iTime = GetNativeCell(4);
	GetNativeString(5, sReason, sizeof(sReason));
	if (IsValidClient(iTarget) && -1<iClient<=MaxClients)
		WarnPlayer(iClient, iTarget, iScore, iTime, sReason);
	else
		ThrowNativeError(1, "Native_WarnPlayer: Client or admin index is invalid.");
}

public int Native_UnWarnPlayer(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iId = GetNativeCell(2);
	//int iScore = GetNativeCell(3);
	char sReason[129];
	GetNativeString(3, sReason, sizeof(sReason));
	if (IsValidClient(iClient))
		FindWarn(iClient, iId, sReason);
	else
		ThrowNativeError(2, "Native_UnWarnPlayer: Client or admin index is invalid.");
}

public int Native_ResetWarnPlayer(Handle hPlugin, int iNumParams)
{
	int iClient = GetNativeCell(1);
	int iTarget = GetNativeCell(2);
	char sReason[129];
	GetNativeString(3, sReason, sizeof(sReason));
	if (IsValidClient(iTarget) && -1<iClient<=MaxClients)
		ResetPlayerWarns(iClient, iTarget, sReason);
	else
		ThrowNativeError(3, "Native_ResetWarnPlayer: Client or admin index is invalid.");
}

public int Native_GetDatabase(Handle hPlugin, int iNumParams) {return view_as<int>(CloneHandle(g_hDatabase, hPlugin));}

public int Native_GetPlayerInfo(Handle hPlugin, int iNumParams)
{
	int iTarget = GetNativeCell(1);
	int iType = GetNativeCell(2);
	switch(iType) {
		case 1:	return g_iWarnings[iTarget];
		case 2: return g_iScore[iTarget];
	}
	return 0;
}

public int Native_GetMaxWarns(Handle hPlugin, int iNumParams) { return g_iMaxWarns; }
public int Native_MaxScore(Handle hPlugin, int iNumParams) { return g_iMaxScore; }

public int Native_PrintToAdmins(Handle hPlugin, int iNumParams)
{
	char sMessage[256];
	GetNativeString(1, sMessage, sizeof(sMessage));
	PrintToAdmins("%s", sMessage);
}

void WarnSystem_OnClientLoaded(int iTarget)
{
	Call_StartForward(g_hGFwd_OnClientLoaded);
	Call_PushCell(iTarget);
	Call_PushCell(g_iWarnings[iTarget]);
	Call_PushCell(g_iScore[iTarget]);
	Call_PushCell(g_iMaxWarns);
	Call_Finish();
}

void WarnSystem_OnClientWarn(int iClient, int iTarget, int iScore, int iTime, char sReason[129], bool bIsAdmin)
{
	Call_StartForward(g_hGFwd_OnClientWarn);
	Call_PushCell(iClient);
	Call_PushCell(iTarget);
	Call_PushCell(iScore);
	Call_PushCell(iTime);
	Call_PushString(sReason);
	Call_PushCell(bIsAdmin);
	
	Call_Finish();
}

void WarnSystem_OnClientUnWarn(int iClient, int iTarget, int iId, int iScore, char sReason[129])
{
	Call_StartForward(g_hGFwd_OnClientUnWarn);
	Call_PushCell(iClient);
	Call_PushCell(iTarget);
	Call_PushCell(iId);
	Call_PushCell(iScore);
	Call_PushString(sReason);
	Call_Finish();
}

void WarnSystem_OnClientResetWarns(int iClient, int iTarget, char sReason[129])
{
	Call_StartForward(g_hGFwd_OnClientResetWarns);
	Call_PushCell(iClient);
	Call_PushCell(iTarget);
	Call_PushString(sReason);
	Call_Finish();
}

Action WarnSystem_OnClientWarnPre(int iClient, int iTarget, int iTime, int iScore, char sReason[129])
{
	Action act = Plugin_Continue;
	Call_StartForward(g_hGFwd_OnClientWarn_Pre);
	Call_PushCell(iClient);
	Call_PushCell(iTarget);
	Call_PushCell(iTime);
	Call_PushCell(iScore);
	Call_PushString(sReason);
	Call_Finish(act);
	return act;
}

Action WarnSystem_OnClientUnWarnPre(int iClient, int iTarget, int iId, int iScore, char sReason[129])
{
	Action act = Plugin_Continue;
	Call_StartForward(g_hGFwd_OnClientUnWarn_Pre);
	Call_PushCell(iClient);
	Call_PushCell(iTarget);
	Call_PushCell(iId);
	Call_PushCell(iScore);
	Call_PushString(sReason);
	Call_Finish(act);
	return act;
}

Action WarnSystem_OnClientResetWarnsPre(int iClient, int iTarget, char sReason[129])
{
	Action act = Plugin_Continue;
	Call_StartForward(g_hGFwd_OnClientResetWarns_Pre);
	Call_PushCell(iClient);
	Call_PushCell(iTarget);
	Call_PushString(sReason);
	Call_Finish(act);
	return act;
}

Action WarnSystem_WarnPunishment(int iClient, int iTarget, int iBanLenght,  char sReason[129])
{
	Action act = Plugin_Continue;
	Call_StartForward(g_hGFwd_WarnPunishment);
	Call_PushCell(iClient);
	Call_PushCell(iTarget);
	Call_PushCell(iBanLenght);
	Call_PushString(sReason);
	Call_Finish(act);
	return act;
}

Action WarnSystem_WarnMaxPunishment(int iClient, int iTarget, int iBanLenght, char sReason[129])
{
	Action act = Plugin_Continue;
	Call_StartForward(g_hGFwd_WarnMaxPunishment);
	Call_PushCell(iClient);
	Call_PushCell(iTarget);
	Call_PushCell(iBanLenght);
	Call_PushString(sReason);
	Call_Finish(act);
	return act;
}