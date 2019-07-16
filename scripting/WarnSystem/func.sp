//---------------------------------------------------SOME FEATURES-------------------------------------------------

stock void PrintToAdmins(char[] sFormat, any ...)
{
	char sBuffer[255];
	for (int i = 1; i<=MaxClients; ++i)
		if (IsValidClient(i) && (GetUserFlagBits(i) & ADMFLAG_GENERIC))
		{	
			VFormat(sBuffer, sizeof(sBuffer), sFormat, 2);
			WS_PrintToChat(i, "%s", sBuffer);
		}
}

stock void WS_PrintToChat(int iClient, const char[] szFormat, any ...)
{
	char szBuffer[MAX_BUFFER_LENGTH];
	VFormat(szBuffer, sizeof(szBuffer), szFormat, 3);
	if(g_bIsFuckingGame)	CGOPrintToChat(iClient, "%s", szBuffer);
	else 					CPrintToChat(iClient, "%s", szBuffer);
}

stock void WS_PrintToChatAll(const char[] szFormat, any ...)
{
	char szBuffer[MAX_BUFFER_LENGTH];
	VFormat(szBuffer, sizeof(szBuffer), szFormat, 2);
	if(g_bIsFuckingGame)	CGOPrintToChatAll("%s", szBuffer);
	else 					CPrintToChatAll("%s", szBuffer);
}

void UTIL_CleanMemory() {
	UTIL_CleanArrayList(g_aWarn);
	UTIL_CleanArrayList(g_aUnwarn);
	UTIL_CleanArrayList(g_aResetWarn);
}

void UTIL_CleanArrayList(ArrayList &hArr) {
	if (!hArr) {
		hArr = new ArrayList(ByteCountToCells(4));
		return;
	}

	int iLength = hArr.Length;
	for (int i = iLength-1; i >= 0; i--) {
		CloseHandle(hArr.Get(i));
		hArr.Erase(i);
	}
}

stock bool IsValidClient(int iClient) { return (iClient > 0 && iClient < MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient)); }
stock void GetPort() { g_iPort=FindConVar("hostport").IntValue; }
stock void GetIPServer() { 
	int iHostIP = FindConVar("hostip").IntValue;
	FormatEx(g_sAddress, sizeof(g_sAddress), "%d.%d.%d.%d", (iHostIP >> 24) & 0x000000FF, (iHostIP >> 16) & 0x000000FF, (iHostIP >>  8) & 0x000000FF, iHostIP & 0x000000FF);
}

void UTIL_FormatTime(int iTime, char[] szBuffer, int iMaxLength) {
  int days = iTime / (60 * 60 * 24);
  int hours = (iTime - (days * (60 * 60 * 24))) / (60 * 60);
  int minutes = (iTime - (days * (60 * 60 * 24)) - (hours * (60 * 60))) / 60;
  int len;

  if (days) {
    len += FormatEx(szBuffer[len], iMaxLength - len, "%d %t", days, "ws_days");
  }

  if (hours) {
    len += FormatEx(szBuffer[len], iMaxLength - len, "%s%d %t", days ? " " : "", hours, "ws_hours");
  }

  if (minutes) {
    len += FormatEx(szBuffer[len], iMaxLength - len, "%s%d %t", (days || hours) ? " " : "", minutes, "ws_minutes");
  }
}

stock bool CheckAdminFlagsByString(int iClient, const char[] szFlagString)
{
    AdminFlag aFlag;
    int iFlags;

    for (int i = 0; i < strlen(szFlagString); i++)
    {
        if(!FindFlagByChar(szFlagString[i], aFlag))     continue;
        iFlags |= FlagToBit(aFlag);
        if (GetUserFlagBits(iClient) & iFlags)
        {
            return true;
        }
    }
    return false;
}

stock int FindClientByAccountID(int iAccountID)
{
	int iTargetAccountID;
	for(int i = 1; i < MaxClients; i++)
	{
		iTargetAccountID = GetSteamAccountID(i);
		if(iAccountID == iTargetAccountID)
			return i;
	}
	return -1;
}