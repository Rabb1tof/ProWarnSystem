#include <sourcemod>
#include <WarnSystem>
#undef REQUIRE_PLUGIN
#tryinclude <materialadmin>
#tryinclude <sourcebans>
#tryinclude <sourcebanspp>
#define REQUIRE_PLUGIN

#if !defined _sourcebans_included && !defined _sourcebanspp_included && !defined _materialadmin_included
#include <clientprefs>
#endif

#pragma newdecls required
#pragma semicolon 1

#define VERS_PLUGIN "2.0b"

#define LoopPlayers(%0)         for (int %0 = MaxClients; %0 != 0; --%0) if (IsClientInGame(%0))
#define LoopCookiesPlayers(%0)  LoopPlayers(%0) if (AreClientCookiesCached(%0))

public Plugin myinfo =
{
    author = "Rabb1t (Discord: Rabb1t#2017)",
    name = "[WarnSystem] Warning Admin (MA & SB support)",
    version = VERS_PLUGIN,
    description = "",
    url = "https://discord.gg/gpK9k8f https://t.me/rabb1tof"
    
}

bool        g_bDeletedAdmin[MAXPLAYERS+1];
//int         g_iType;
Database    g_hDatabase;
//ConVar      g_cType;
#if !defined _sourcebans_included && !defined _sourcebanspp_included && !defined _materialadmin_included
Handle      g_hDeletedAdmin;
#endif

public void OnPluginStart()
{
    #if defined _sourcebans_included || defined _sourcebanspp_included // if SB or SB++
    SQL_TConnect(SBGetDatabase, "sourcebans");
    #endif

    #if defined _materialadmin_included // if MA
    g_hDatabase = MAGetDatabase();
    #endif

    #if !defined _sourcebans_included && !defined _sourcebanspp_included && !defined _materialadmin_included // if nothing above
    g_hDeletedAdmin    = RegClientCookie("WS_ClientScore", "", CookieAccess_Private);

    LoopCookiesPlayers(iClient)
        OnClientCookiesCached(iClient);
    #endif

    /*g_cType = CreateConVar("sm_warns_admin_type", "2", "Работа всей системы: (0 - по колличеству предупреждений, 1 - система баллов, 2 - оба варианта.", _, true, 0.0, true, 2.0);
    g_cType.AddChangeHook(OnTypeChange);
    AutoExecConfig(true, "module_admin", "warnsystem");*/
}

/*public void OnConfigsExecuted() { g_iType = g_cType.IntValue; }

public void OnTypeChange(ConVar hCvar, const char[] oldValue, const char[] newValue) { g_iType = hCvar.IntValue; }*/

#if !defined _sourcebans_included && !defined _sourcebanspp_included && !defined _materialadmin_included
public void OnClientCookiesCached(int iClient)
{
    char szDummyData[16];
    GetClientCookie(iClient, g_hDeletedAdmin, szDummyData, sizeof(szDummyData));
    g_bDeletedAdmin[iClient] = UTIL_StringToInt(szDummyData);
}

public void OnClientDisconnect(int iClient) {
    char szDummyData[16];
    IntToString(g_iScore[iClient], szDummyData, sizeof(szDummyData));
    SetClientCookie(iClient, g_hDeletedAdmin, szDummyData);

}

int UTIL_StringToInt(const char[] szString) {
if (szString[0])
    return StringToInt(szString);
else
    return 0;
}
#endif

#if defined _sourcebans_included || defined _sourcebanspp_included
public int SBGetDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == INVALID_HANDLE)
    {
        LogError("Database failure: %s. See FAQ: https://github.com/SB-MaterialAdmin/Web/wiki/FAQ", error);
        return;
    }

    g_hDatabase = view_as<Database>(hndl);
    SQL_SetCharset(g_hDatabase, "utf8");
}
#endif

public void OnClientPutInServer(int iClient)
{
    if(IsValidClient(iClient) && g_bDeletedAdmin[iClient] && GetUserFlagBits(iClient) & (ADMFLAG_GENERIC | ADMFLAG_ROOT))
        DeleteAdminAccess(iClient);

}

stock void DeleteAdminAccess(int iClient)
{
    char szSteamID[64];
    AdminId aAdmin[2]; 
    FormatEx(szSteamID, sizeof(szSteamID), "STEAM_1:%i:%i");
    aAdmin[0] = FindAdminByIdentity("steam", szSteamID);
    FormatEx(szSteamID, sizeof(szSteamID), "STEAM_0:%i:%i");
    aAdmin[1] = FindAdminByIdentity("steam", szSteamID);
    if(aAdmin[0] != INVALID_ADMIN_ID) 
        RemoveAdmin(aAdmin[0]);
    else if(aAdmin[1] != INVALID_ADMIN_ID)
        RemoveAdmin(aAdmin[1]);
}

public void WarnSystem_OnClientWarn(int iAdmin, int iClient, int iScore, int iTime, char sReason[129], bool bIsAdmin)
{
    if(!bIsAdmin) 	return;
    int iMaxWarn = WarnSystem_GetMaxWarns(), 
        iMaxScore = WarnSystem_GetMaxScore();
    int iScoreClient = WarnSystem_GetPlayerInfo(iClient, 2), 
        iWarns = WarnSystem_GetPlayerInfo(iClient, 1);
    /*#if defined _materialadmin_included
    g_hDatabase = MAGetDatabase();
    #endif*/
    if(g_hDatabase != INVALID_HANDLE && GetUserFlagBits(iClient))
    {
        #if defined _sourcebans_included && defined _sourcebanspp_included && defined _materialadmin_included
        char szBuffer[525];
        int iAccountIDA = GetSteamAccountID(iAdmin), iAccountIDC = GetSteamAccountID(iClient);
        #endif
        if(iMaxScore < iScoreClient || iMaxWarn < iWarns)
        {
            #if defined _sourcebans_included && defined _sourcebanspp_included && defined _materialadmin_included
            FormatEx(szBuffer, sizeof(szBuffer), "UPDATE `sb_admins` SET 'expired' = UNIX_TIMESTAMP() WHERE `authid` IN('STEAM_0:%i:%i', STEAM_1:%i:%i, '%i+76561197960265728')", iAccountIDC & 1, iAccountIDC / 2, 
                iAccountIDC & 1, iAccountIDC / 2, iAccountIDC);
            #endif
            DeleteAdminAccess(iClient);
            g_bDeletedAdmin[iClient] = true;
        }
        #if defined _sourcebans_included && defined _sourcebanspp_included && defined _materialadmin_included
        else
        {
            FormatEx(szBuffer, sizeof(szBuffer), "INSERT INTO\
    `sb_warns`\
    (`arecipient`, `afrom`, `expires`, `reason`)\
    VALUES (\
    IFNULL(\
        (\
        SELECT\
            `aid`\
        FROM\
            `sb_admins`\
        WHERE\
            `authid` IN('STEAM_0:%i:%i', STEAM_1:%i:%i, '%i+76561197960265728')\
        ), 0\
    ), IFNULL(\
        (\
        SELECT\
            `aid`\
        FROM\
            `sb_admins`\
        WHERE\
        `authid` IN('STEAM_0:%i:%i', STEAM_1:%i:%i, '%i+76561197960265728')\
        ), 0\
        ), %i, \
        '%s');",
            iAccountIDC & 1, iAccountIDC / 2, 
                iAccountIDC & 1, iAccountIDC / 2, iAccountIDC, iAccountIDA & 1, iAccountIDA / 2, 
                iAccountIDA & 1, iAccountIDA / 2, iAccountIDA, iTime, sReason);	
        }
        #endif
        
        #if defined _sourcebans_included && defined _sourcebanspp_included && defined _materialadmin_included
        //PrintToServer("%s", szBuffer);
        g_hDatabase.Query(SQL_AdminWarn, szBuffer);
        #endif
    }
}

public void SQL_AdminWarn(Database hDatabase, DBResultSet hDatabaseResults, const char[] szError, any data)
{
    if (hDatabaseResults == INVALID_HANDLE || szError[0])
    {
        LogError("SQL_AdminWarn - error while working with data (%s)", szError);
        return;
    }
}

stock bool IsValidClient(int iClient) { return (iClient > 0 && iClient < MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient)); }