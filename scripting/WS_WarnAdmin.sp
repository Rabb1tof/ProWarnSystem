#include <sourcemod>
#include <WarnSystem>
#undef REQUIRE_PLUGIN
#tryinclude <materialadmin>
#tryinclude <sourcebans>
#tryinclude <sourcebanspp>
#define REQUIRE_PLUGIN

#pragma newdecls required
#pragma semicolon 1

#define VERS_PLUGIN "1.1"

public Plugin myinfo =
{
	author = "Rabb1t (Discord: Rabb1t#2017)",
	name = "[WarnSystem] Warning Admin (MA & SB support)",
	version = VERS_PLUGIN,
	description = "",
	url = "https://discord.gg/gpK9k8f https://t.me/rabb1tof"
	
}

Database g_hDatabase;

public void OnPluginStart()
{
	#if defined _sourcebans_included || defined _sourcebanspp_included
	SQL_TConnect(SBGetDatabase, "sourcebans");
	#endif

	#if defined _materialadmin_included
	g_hDatabase = MAGetDatabase();
	#endif
}

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

public void WarnSystem_OnClientWarn(int iAdmin, int iClient, int iScore, int iTime, char sReason[129], bool bIsAdmin)
{
	if(!bIsAdmin) 	return;
	int iMaxWarn = WarnSystem_GetMaxWarns(), 
		iMaxScore = WarnSystem_GetMaxScore();
	int	iScoreClient = WarnSystem_GetPlayerInfo(iClient, 2), 
		iWarns = WarnSystem_GetPlayerInfo(iClient, 1);
	/*#if defined _materialadmin_included
	g_hDatabase = MAGetDatabase();
	#endif*/
	if(g_hDatabase != INVALID_HANDLE && GetUserFlagBits(iClient))
	{
		char szBuffer[525];
		int iAccountIDA = GetSteamAccountID(iAdmin), iAccountIDC = GetSteamAccountID(iClient);
		if(iMaxScore < iScoreClient || iMaxWarn < iWarns)
		{
			FormatEx(szBuffer, sizeof(szBuffer), "UPDATE `sb_admins` SET 'expired' = UNIX_TIMESTAMP() WHERE `authid` IN('STEAM_0:%i:%i', STEAM_1:%i:%i, '%i+76561197960265728')", iAccountIDC & 1, iAccountIDC / 2, 
				iAccountIDC & 1, iAccountIDC / 2, iAccountIDC);
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
		
		//PrintToServer("%s", szBuffer);
		g_hDatabase.Query(SQL_AdminWarn, szBuffer);
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