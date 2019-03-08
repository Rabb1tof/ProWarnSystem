//---------------------------------------------------SOME FEATURES-------------------------------------------------

stock void PrintToAdmins(char[] sFormat, any ...)
{
	char sBuffer[255];
	for (int i = 1; i<=MaxClients; ++i)
		if (IsValidClient(i) && (GetUserFlagBits(i) & g_iPrintToAdminsOverride))
		{	
			VFormat(sBuffer, sizeof(sBuffer), sFormat, 2);
			CPrintToChat(i, "%s", sBuffer);
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

stock bool CheckAdminFlagsByString(int iClient, const char[] szFlagString)
{
    AdminId aAdmin = GetUserAdmin(iClient);

    if (aAdmin != INVALID_ADMIN_ID)
    {
        int iCount; int iFound; int iFlags = ReadFlagString(szFlagString);

        for (int i = 0; i <= 20; i++)
        {
            if (iFlags & (1 << i))
            {
                iCount++;

                if (GetAdminFlag(aAdmin, view_as<AdminFlag>(i)))
                {
                    iFound++;
                }
            }
        }

        if (iCount == iFound)
        {
            return true;
        }
    }
    return false;
}