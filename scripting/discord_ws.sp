#include <discord_extended>
#include <WarnSystem>
#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

#define VERS_PLUGIN "1.0"

public Plugin myinfo =
{
	author = "Rabb1t",
	name = "[Discord] WarnSystem Logging",
	version = VERS_PLUGIN,
	description = "",
	url = "Discord: Rabb1t#2017"
};

public void WarnSystem_OnClientWarn(int iAdmin, int iClient, int iScore, int iTime, char szReason[129]) { UTIL_Reporting(iAdmin, iClient, iScore, iTime, szReason, "Warning"); }

public void WarnSystem_OnClientUnWarn(int iAdmin, int iClient, int iScore, char szReason[129]) { UTIL_Reporting(iAdmin, iClient, iScore, 0, szReason, "Unwarning"); }

public void WarnSystem_OnClientResetWarns(int iAdmin, int iClient, char szReason[129]) { UTIL_Reporting(iAdmin, iClient, 0, 0, szReason, "Reset Warning"); }

void UTIL_Reporting(int iAdmin, int iClient, int iScore, int iTime, const char[] szReason, const char[] szType) 
{
	char szBuffer[256];  

	Discord_StartMessage();
	Discord_SetUsername("Warning System");
	//Discord_SetColor(0xFF9900AA);
	GetConVarString(FindConVar("hostname"), szBuffer, sizeof(szBuffer));
	Discord_AddField("Server", szBuffer);
	
	Discord_AddField("Type Notify", szType, true);
	if(StrEqual(szType, "Warning") || StrEqual(szType, "Unwarning")){
		IntToString(iScore, szBuffer, sizeof(szBuffer));
		Discord_AddField("Score", szBuffer, true);
	}
	if(StrEqual(szType, "Warning")) {
		FormatTime(szBuffer, sizeof(szBuffer), "%X", iTime);
		Discord_AddField("Time", szBuffer);
	}

	// Admin Name
	GetClientName(iAdmin, szBuffer, sizeof(szBuffer));
	Discord_AddField("Admin Name", szBuffer, true);
	
	// Admin SteamID
	GetClientAuthId(iAdmin, AuthId_Steam2, szBuffer, sizeof(szBuffer));
	Discord_AddField("Admin SteamID", szBuffer, true);
	
	// Client Name
	GetClientName(iClient, szBuffer, sizeof(szBuffer));
	Discord_AddField("Client Name", szBuffer, true);
	
	// Client SteamID
	GetClientAuthId(iClient, AuthId_Steam2, szBuffer, sizeof(szBuffer));
	Discord_AddField("Client SteamID", szBuffer, true);
	
	// Reason
	Discord_AddField("Reason", szReason, true);
	
	Discord_EndMessage("warnsystem", true);
}