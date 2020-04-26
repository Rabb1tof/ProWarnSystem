//---------------------------------DEFINES && INCLUDES--------------------------------
#pragma semicolon 1

#define PLUGIN_NAME         "[warnsystem] Core Pro"
#define PLUGIN_AUTHOR       "Rabb1t & vadrozh"
#define PLUGIN_VERSION      "1.6.3.1"
#define PLUGIN_DESCRIPTION  "Warn players when they are doing something wrong"
#define PLUGIN_URL          "hlmod.ru/threads/warnsystem.42835/"

#define PLUGIN_BUILDDATE    __DATE__ ... " " ... __TIME__
#define PLUGIN_COMPILEDBY   SOURCEMOD_V_MAJOR ... "." ... SOURCEMOD_V_MINOR ... "." ... SOURCEMOD_V_RELEASE

//#include <colors>
#include <csgo_colors>
#include <morecolors>
#include <SteamWorks>
#include <sdktools_sound>
#include <sourcemod>
#include <sdktools_stringtables>
#include <sdktools_functions>
#include <dbi>
#undef REQUIRE_PLUGIN
#undef REQUIRE_EXTENSIONS
#tryinclude <adminmenu>
#tryinclude <vip_core>
#define REQUIRE_PLUGINS
#define REQUIRE_EXTENSIONS

#pragma newdecls required

//----------------------------------------------------------------------------

char g_sPathAgreePanel[PLATFORM_MAX_PATH], g_sLogPath[PLATFORM_MAX_PATH], g_szQueryPath[PLATFORM_MAX_PATH], g_sAddress[64];

bool g_bIsFuckingGame;
ArrayList g_aWarn, g_aUnwarn, g_aResetWarn;

Database g_hDatabase;

int g_iWarnings[MAXPLAYERS+1], /*(g_iPrintToAdminsOverride,*/ g_iUserID[MAXPLAYERS+1], g_iPort, g_iScore[MAXPLAYERS+1], g_iCustom[MAXPLAYERS+1];

#define LogWarnings(%0) LogToFileEx(g_sLogPath, %0)
#define LogQuery(%0)    LogToFileEx(g_szQueryPath, %0)

#include "warnsystem/stats.sp"
#include "warnsystem/convars.sp"
#include "warnsystem/api.sp"
#include "warnsystem/database.sp"
#include "warnsystem/commands.sp"
#include "warnsystem/configs.sp" 
#include "warnsystem/menus.sp"
#include "warnsystem/func.sp"

public Plugin myinfo =
{
	name = 			PLUGIN_NAME,
	author = 		PLUGIN_AUTHOR,
	description = 	PLUGIN_DESCRIPTION,
	version = 		PLUGIN_VERSION,
	url = 			PLUGIN_URL
};

//----------------------------------------------------INITIALIZING---------------------------------------------------

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("warnsystem.phrases");

	switch (GetEngineVersion())
	{ 
		case Engine_CSGO: 		g_bIsFuckingGame = true;
	 	case Engine_Left4Dead:  g_bIsFuckingGame = true;
		case Engine_Left4Dead2: g_bIsFuckingGame = true; 
	}
	if(!DirExists("addons/sourcemod/logs/warnsystem"))
		CreateDirectory("addons/sourcemod/logs/warnsystem", 511);
	if(!FileExists("addons/sourcemod/logs/warnsystem/warnsystem.log"))
		OpenFile("addons/sourcemod/logs/warnsystem/warnsystem.log", "w");
	if(!FileExists("addons/sourcemod/logs/warnsystem/WarnSystem_Query.log"))
		OpenFile("addons/sourcemod/logs/warnsystem/WarnSystem_Query.log", "w");
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/warnsystem/warnsystem.log");
	BuildPath(Path_SM, g_szQueryPath, sizeof(g_szQueryPath), "logs/warnsystem/WarnSystem_Query.log");
	
	InitializeConVars();
	InitializeDatabase();
	InitializeCommands();
	InitializeConfig();
	

	SteamWorks_SteamServersConnected();
	
	if (LibraryExists("adminmenu"))
	{
		Handle hAdminMenu;
		if ((hAdminMenu = GetAdminTopMenu()))
			InitializeMenu(hAdminMenu);
	}
	
	GetIPServer();
	GetPort();
		
	strcopy(g_sClientIP[0], 65, "localhost");
	g_iAccountID[0] = -1;
	
	//if (!GetCommandOverride("sm_warn", Override_Command, g_iPrintToAdminsOverride))
		//g_iPrintToAdminsOverride = ADMFLAG_GENERIC;
}

public Action CmdDB(int iClient, int args)
{
	InitializeDatabase();
	return Plugin_Handled;
}

public void OnLibraryAdded(const char[] sName)
{
	Handle hAdminMenu;
	if (StrEqual(sName, "adminmenu"))
		if ((hAdminMenu = GetAdminTopMenu()))
			InitializeMenu(hAdminMenu);
}

public void OnLibraryRemoved(const char[] sName)
{
	if (StrEqual(sName, "adminmenu"))
		g_hAdminMenu = INVALID_HANDLE;
}

public Action OnClientSayCommand(int iClient, const char[] szCommand, const char[] szArgs)
{
	if(g_iCustom[iClient] == 0)		return Plugin_Continue;

	char szReason[129];
	strcopy(szReason, sizeof(szReason), szArgs);
	//GetCmdArgString(szReason, sizeof(szReason));
	StripQuotes(szReason);
	if (StrEqual(szReason[0], "!stop") || StrEqual(szReason[0], "!cancel") || StrEqual(szReason[0], "!s") || StrEqual(szReason[0], "!c"))
	{
		WS_PrintToChat(iClient, "%t", "WS_Reason_Aborted");
		return Plugin_Handled;
	}

	switch(g_iCustom[iClient])		
	{
		case 1: 	WarnPlayer(iClient, g_iTarget[iClient], g_iScoreLength, g_iWarnLength, szReason); // issue a warning	
		case 2:		FindWarn(iClient, g_iDataID[iClient], szReason);
		case 3:		ResetPlayerWarns(iClient, g_iTarget[iClient], szReason);
		//return Plugin_Handled; // block the reason to be sent in chat
	}
	g_iCustom[iClient] = 0;
	return Plugin_Handled;
}

public void OnMapStart()
{
	SteamWorks_SteamServersConnected();
	/*for(int iClient = 1; iClient <= MaxClients; ++iClient)
		LoadPlayerData(iClient);*/
	
	InitializeConfig();
	if(g_bWarnSound)
	{
		char sBuffer[PLATFORM_MAX_PATH];
		FormatEx(sBuffer, sizeof(sBuffer), "sound/%s", g_sWarnSoundPath);
		if(FileExists(sBuffer, true) || FileExists(sBuffer))
		{
			AddFileToDownloadsTable(sBuffer);
			if(g_bIsFuckingGame)
			{
				FormatEx(sBuffer, sizeof(sBuffer), "*/%s", g_sWarnSoundPath);
				AddToStringTable(FindStringTable("soundprecache"), sBuffer);
			}
			else
				PrecacheSound(g_sWarnSoundPath, true);
		}
	}
	if(g_bDeleteExpired)
		CheckExpiredWarns();
}

public void OnAdminMenuReady(Handle hTopMenu) {InitializeMenu(hTopMenu);}

public void OnClientAuthorized(int iClient) {
  IsClientInGame(iClient) &&
	LoadPlayerData(iClient);
}

public void OnClientPutInServer(int iClient) {
  IsClientAuthorized(iClient) &&
	LoadPlayerData(iClient);
}

//----------------------------------------------------PUNISHMENTS---------------------------------------------------

public void PunishPlayerOnMaxWarns(int iAdmin, int iClient, char sReason[129], bool bType)
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient)){
		//PrintToServer("score: %d | warns: %d", g_iScore[iClient], g_iWarnings[iClient]);
		switch (g_iMaxPunishment)
		{
			case 1:
				KickClient(iClient, "[warnsystem] %t", "WS_MaxKick", bType ? "баллов" : "предупреждений");
			case 2:
			{
				char sBanReason[129];
				FormatEx(sBanReason, sizeof(sBanReason), "[warnsystem] %t", "WS_MaxBan", sReason, bType ? "баллов" : "предупреждений");
				BanClient(iClient, g_iBanLenght, BANFLAG_AUTO, sBanReason, sBanReason, "warnsystem");
			}
			case 3:
			{
				char dbQuery[256];
				g_iWarnings[iClient] = g_iScore[iClient] = 0;
				FormatEx(dbQuery, sizeof(dbQuery), g_sSQL_DeleteWarns, g_iAccountID[iClient], g_iServerID);
				g_hDatabase.Query(SQL_CheckError, dbQuery);
				char sBanReason[129];
				FormatEx(sBanReason, sizeof(sBanReason), "[warnsystem] %t", "WS_MaxBan", sReason, bType ? "баллов" : "предупреждений");
				if (WarnSystem_WarnMaxPunishment(iAdmin, iClient, g_iBanLenght, sReason) == Plugin_Continue)
				{
					LogWarnings("Selected max punishment with custom module but module doesn't exists.  Client kicked.");
					KickClient(iClient, "[warnsystem] %t", "WS_MaxKick", bType ? "баллов" : "предупреждений");
				}
			}
		}
	}
}

public void PunishPlayer(int iAdmin, int iClient, int iScore, int iTime, char sReason[129])
{
	if (iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
		switch (g_iPunishment)
		{
			case 1:
				WS_PrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_Message");
			case 2:
			{
				if (IsPlayerAlive(iClient))
					SlapPlayer(iClient, g_iSlapDamage, true);
				WS_PrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_Message");
			}
			case 3:
			{
				if (IsPlayerAlive(iClient))
					ForcePlayerSuicide(iClient);
				WS_PrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_Message");
			}
			case 4: 
				PunishmentSix(iClient, iAdmin, iScore, iTime, sReason);
			case 5:
			{
				char sKickReason[129];
				FormatEx(sKickReason, sizeof(sKickReason), "[warnsystem] %t", "WS_PunishKick", sReason);
				KickClient(iClient, sKickReason);
			}
			case 6:
			{
				char sBanReason[129];
				FormatEx(sBanReason, sizeof(sBanReason), "[warnsystem] %t", "WS_PunishBan", sReason);
				BanClient(iClient, g_iBanLenght, BANFLAG_AUTO, sBanReason, sBanReason, "warnsystem");
			}
			case 7:
			{
				char sBanReason[129];
				FormatEx(sBanReason, sizeof(sBanReason), "[warnsystem] %t", "WS_PunishBan", sReason);
				if (WarnSystem_WarnPunishment(iAdmin, iClient, g_iBanLenght, sReason) == Plugin_Continue)
				{
					LogWarnings("Selected punishment with custom module but module doesn't exists.");
					PunishmentSix(iClient, iAdmin, iScore, iTime, sReason);
				}
			}
		}

}

public void PunishmentSix(int iClient, int iAdmin, int iScore, int iTime, char[] szReason)
{
	if (IsPlayerAlive(iClient))
		SetEntityMoveType(iClient, MOVETYPE_NONE);
	BuildAgreement(iClient, iAdmin, iScore, iTime, szReason);
	WS_PrintToChat(iClient, " %t %t", "WS_ColoredPrefix", "WS_Message");
}