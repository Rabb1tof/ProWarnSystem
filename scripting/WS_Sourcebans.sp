#pragma semicolon 1
#include <WarnSystem>
#include <sourcemod>

#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>
#tryinclude <sourcebanspp>
#tryinclude <materialadmin>
#define REQUIRE_PLUGINS

#pragma newdecls required

ConVar g_cSbType;
int g_iSbType;

public Plugin myinfo =
{
	name = "[WarnSystem] Sourcebans support (all version)",
	author = "vadrozh, Rabb1t",
	description = "Module adds support of sb (all)",
	version = "1.2",
	url = "hlmod.ru"
}

public void OnPluginStart()
{
	g_cSbType = CreateConVar("sm_ws_sourcebans_type", "2", "Type of using sourcebans, where 0 - sb (old), 1 - sb++ (new), 2 - MaterialAdmin (MA FORK)");

	g_cSbType.AddChangeHook(OnSbTypeChanged);

	AutoExecConfig(true, "sourcebans", "warnsystem");
}

public void OnConfigsExecuted()
{
	g_iSbType = g_cSbType.IntValue;
}

public void OnSbTypeChanged(ConVar hCV, const char[] oldValue, const char[] newValue) { g_iSbType = hCV.IntValue; }

public Action WarnSystem_WarnPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129])
{
	switch(g_iSbType){
		case 0:     SBBanPlayer(iAdmin, iClient, iBanLenght, sReason);
		case 1:     SBPP_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
		case 2:     MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
	}
	
	return Plugin_Handled;
}

public Action WarnSystem_WarnMaxPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129])
{
	switch(g_iSbType){
		case 0:     SourceBans_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
		case 1:     SBPP_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
		case 2:     MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
	}
	
	return Plugin_Handled;
}