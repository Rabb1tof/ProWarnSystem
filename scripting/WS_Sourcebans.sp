#pragma semicolon 1
#include <WarnSystem>

#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>
#tryinclude <materialadmin>
#define REQUIRE_PLUGINS
#pragma newdecls required

int g_iSbType;

public Plugin myinfo =
{
	name = "[WarnSystem] Sourcebans support (all version)",
	author = "vadrozh, Rabb1t",
	description = "Module adds support of sb (all)",
	version = "1.1",
	url = "hlmod.ru"
};

public void OnLibraryAdded(const char[] sName) {SetPluginDetection(sName);}

public void OnLibraryRemoved(const char[] sName){SetPluginDetection(sName);}

void SetPluginDetection(const char[] sName) {
    if (StrEqual(sName, "sourcebans"))
        g_iSbType = 2;
	else if(StrEqual(sName, "materialadmin"))
		g_iSbType = 1;
}

public Action WarnSystem_WarnPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129])
{
	switch(g_iSbType){
		#if defined _materialadmin_included
		case 1:     MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
		#endif
		#if defined _sourcebans_included
		case 2:     SourceBans_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
		//case 3:     SBBanPlayer(iAdmin, iClient, iBanLenght, sReason);
		#endif
	}
	
	return Plugin_Handled;
}

public Action WarnSystem_WarnMaxPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129])
{
	switch(g_iSbType){
		#if defined _materialadmin_included
		case 1:     MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
		#endif
		#if defined _sourcebans_included
		case 2:     SourceBans_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
		//case 3:     SBBanPlayer(iAdmin, iClient, iBanLenght, sReason);
		#endif
	}
	
	return Plugin_Handled;
}