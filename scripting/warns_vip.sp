#include <sourcemod>
#include <WarnSystem>
#include <vip_core>
#include <adminmenu>

#pragma newdecls required
#pragma semicolon 1

#define VERS_PLUGIN "1.1"

public Plugin myinfo =
{
    author = "Rabb1t (Discord: Rabb1t#2017)",
    name = "[WS] Warns access VIP",
    version = VERS_PLUGIN,
    description = "",
    url = "https://discord.gg/gpK9k8f https://t.me/rabb1tof"
    
}

static const char g_szFeatureName[][] = { "Warns", "Unwars", "Resetwarns" };

public void OnPluginStart()
{
    if(VIP_IsVIPLoaded())
    {
        VIP_OnVIPLoaded();
    }
}

public void VIP_OnVIPLoaded() 
{
    for(int i; i < 3; i++)
        VIP_RegisterFeature(g_szFeatureName[i], INT, SELECTABLE, VIP_OnItemSelected, _, VIP_OnItemDraw);
}

public int VIP_OnItemDraw(int iClient, const char[] szFeatureName, int iStyle) 
{
    return iStyle;
}

public bool VIP_OnItemSelected(int iClient, const char[] szFeatureName) 
{    
    //Menu hMenu = new Menu(SelectPlayer);
    if(StrEqual(szFeatureName, g_szFeatureName[0]))
    {
        Menu hMenu = new Menu(SelectPlayer_Warn);
        AddTargets(iClient, hMenu);
        //hMenu.Display(iClient, 0);
        return true;
    }
    else if(StrEqual(szFeatureName, g_szFeatureName[1]))
    {
        Menu hMenu = new Menu(SelectPlayer_Unwarn);
        AddTargets(iClient, hMenu);
        //hMenu.Display(iClient, 0);
        return true;
    }
    else if(StrEqual(szFeatureName, g_szFeatureName[2]))
    {
        Menu hMenu = new Menu(SelectPlayer_Resetwarn);
        AddTargets(iClient, hMenu);
        //hMenu.Display(iClient, 0);
        return true;
    }

    return false;
}

public int SelectPlayer_Warn(Menu hMenu, MenuAction eAction, int iAdmin, int iItem) {
    switch (eAction) {
        case MenuAction_End:    CloseHandle(hMenu);
        case MenuAction_Select: 
        {
            char szBuf[12];
            GetMenuItem(hMenu, iItem, szBuf, sizeof(szBuf));

            int iUserId = StringToInt(szBuf);
            int iClient = GetClientOfUserId(iUserId);

            if (iClient == 0) {
                PrintToChat(iAdmin, "[VIP] Игрок вышел с сервера!");
                return;
            }

            WarnSystem_Warn(iAdmin, iClient, "Нарушение правил");
        }
    }
}

public int SelectPlayer_Unwarn(Menu hMenu, MenuAction eAction, int iAdmin, int iItem) {
    switch (eAction) {
        case MenuAction_End:    CloseHandle(hMenu);
        case MenuAction_Select: 
        {
            char szBuf[12];
            GetMenuItem(hMenu, iItem, szBuf, sizeof(szBuf));

            int iUserId = StringToInt(szBuf);
            int iClient = GetClientOfUserId(iUserId);

            if (iClient == 0) {
                PrintToChat(iAdmin, "[VIP] Игрок вышел с сервера!");
                return;
            }

            WarnSystem_UnWarn(iAdmin, iClient, "Понят и прощен");
        }
    }
}

public int SelectPlayer_Resetwarn(Menu hMenu, MenuAction eAction, int iAdmin, int iItem) {
    switch (eAction) {
        case MenuAction_End:    CloseHandle(hMenu);
        case MenuAction_Select: 
        {
            char szBuf[12];
            GetMenuItem(hMenu, iItem, szBuf, sizeof(szBuf));

            int iUserId = StringToInt(szBuf);
            int iClient = GetClientOfUserId(iUserId);

            if (iClient == 0) {
                PrintToChat(iAdmin, "[VIP] Игрок вышел с сервера!");
                return;
            }

            WarnSystem_ResetWarn(iAdmin, iClient, "Понят и прощен (сброс)");
        }
    }
}


void AddTargets(int iClient, Menu hMenu)
{
    SetMenuTitle(hMenu, "Выберите игрока:\n ");
    AddTargetsToMenu2(hMenu, 0, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_NO_BOTS);

    hMenu.Display(iClient, 0);
    //PrintToChatAll("Debug");
}

public void OnPluginEnd()
{
    for(int i; i>=3; i++)
        VIP_UnregisterFeature(g_szFeatureName[i]);
}

stock bool IsValidClient(int iClient) { return (iClient > 0 && iClient < MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient)); }