#pragma semicolon 1
#include <WarnSystem>
#include <sourcemod>
#include <adminmenu>
#include <basecomm>
#include <csgo_colors>
#include <sdktools_functions>

#undef REQUIRE_PLUGIN
#tryinclude <sourcebans>
#tryinclude <sourcecomms>
#tryinclude <sourcebanspp>
#tryinclude <materialadmin>
#define REQUIRE_PLUGINS

#define TIME 15
#define REASON "[WS] Наказан."

#pragma newdecls required

ConVar g_cSbType, g_cUseSb, g_cDefaultPunish;
int g_iSbType, g_iDefaultPunish, /*g_iAdmin, g_iTarget,*/ g_iTimePunish, g_iTypePunish;
bool g_bUseSb;

public Plugin myinfo =
{
    name = "[WarnSystem] Punish",
    author = "Rabb1t",
    description = "Module adds support of sb (all)",
    version = "2.1.1",
    url = "https://discord.gg/gpK9k8f https://t.me/rabb1tof"
}

public void OnPluginStart()
{
    g_cUseSb            = CreateConVar("sm_ws_use_sourcebans", "1", "Using SB / MA when warnings or score are max (0 - don't use, 1 - use).", _, true, 0.0, true, 1.0);
    g_cSbType           = CreateConVar("sm_ws_sourcebans_type", "2", "Type of using sourcebans, where 0 - sb (old), 1 - sb++ (new), 2 - MaterialAdmin (MA FORK)");
    g_cDefaultPunish    = CreateConVar("sm_ws_default_punish", "1", "1 - kick, 2 - mute, 3 - ban");

    g_cSbType.AddChangeHook(OnSbTypeChanged);
    g_cUseSb.AddChangeHook(OnStatusSbChanged);
    g_cDefaultPunish.AddChangeHook(OnDefaultPunishChanged);

    AutoExecConfig(true, "punish", "warnsystem");
}

public void OnConfigsExecuted()
{
    g_iSbType = g_cSbType.IntValue;
    g_bUseSb = g_cUseSb.BoolValue;
    g_iDefaultPunish = g_cDefaultPunish.IntValue;
}

public void OnSbTypeChanged(ConVar hCV, const char[] oldValue, const char[] newValue) { g_iSbType = hCV.IntValue; }
public void OnStatusSbChanged(ConVar hCV, const char[] oldValue, const char[] newValue) { g_bUseSb = hCV.BoolValue; }
public void OnDefaultPunishChanged(ConVar hCV, const char[] oldValue, const char[] newValue) { g_iDefaultPunish = hCV.IntValue; }

public Action WarnSystem_WarnPunishment(int iClient, int iTarget, int iBanLenght, char sReason[129])
{
    // TODO: удалять к хуям добавление игроков меню.
    
    g_iTimePunish = iBanLenght;
    /*Menu hMenu = new Menu(OnPlayerPunished);
    hMenu.SetTitle("Выберите наказание для игрока:");
    AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_CONNECTED);

    hMenu.Display(iClient, TIME);*/

    if(IsValidClient(iClient))
        GetPunish(iClient, iClient);

    return Plugin_Handled;
}

/*public int OnPlayerPunished(Menu hMenu, MenuAction action, int iClient, int iTarget)
{
    switch(action)
    {
        case MenuAction_End: hMenu.Close();
        case MenuAction_Select: 
        {
            char szBuffer[6];
            hMenu.GetItem(iTarget, szBuffer, sizeof(szBuffer));
            g_iTarget = GetClientOfUserId(StringToInt(szBuffer));
            g_iAdmin = iClient;
            GetPunish(iClient);
        }
    }
}*/

public Action WarnSystem_WarnMaxPunishment(int iAdmin, int iClient, int iBanLenght, char sReason[129])
{
    /*if(g_bUseSb)
    {
        switch(g_iSbType){
            case 0:     SourceBans_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
            case 1:     SBPP_BanPlayer(iAdmin, iClient, iBanLenght, sReason);
            case 2:     MABanPlayer(iAdmin, iClient, MA_BAN_STEAM, iBanLenght, sReason);
        }
    }*/

    g_iTimePunish = iBanLenght;
    /*Menu hMenu = new Menu(OnPlayerPunished);
    hMenu.SetTitle("Выберите наказание для игрока:");
    AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_CONNECTED);

    hMenu.Display(iClient, TIME);*/
    if(IsValidClient(iClient))
        GetPunish(iAdmin, iClient);
    //PrintToChatAll("TEST#1");

    return Plugin_Handled;
}

void GetPunish(int iClient, int iTarget) /* this function helpeful get punish for a target */
{
    Menu hMenu = new Menu(OnPunishGetted);
    hMenu.SetTitle("Выберите тип наказания:");
    hMenu.AddItem(NULL_STRING, "Бан"); // 0 - ban
    hMenu.AddItem(NULL_STRING, "Мут"); // mute
    hMenu.AddItem(NULL_STRING, "Гаг"); // gag
    hMenu.AddItem(NULL_STRING, "Мут+гаг"); // mute + gag
    hMenu.AddItem(NULL_STRING, "Кик"); // 4 - kick
    hMenu.AddItem(NULL_STRING, "Убить"); // 5 - slay

    char buffer[40];
    IntToString(iTarget, buffer, sizeof(buffer));
    hMenu.AddItem("target", buffer, ITEMDRAW_NOTEXT);
    //IntToString(iClient, buffer, sizeof(buffer));
    //hMenu.AddItem("admin", buffer);

    //PrintToChatAll("TEST#2");

    hMenu.Display(iClient, TIME);
}

public int OnPunishGetted(Menu hMenu, MenuAction action, int iClient, int param2)
{
    char buffer[40];
    hMenu.GetItem(6, "", 0, _, buffer, sizeof(buffer));
    int iTarget = StringToInt(buffer);
    switch(action)
    {
        case MenuAction_End: hMenu.Close();
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_Timeout)
                switch(g_iDefaultPunish)
                {
                    case 1: UTIL_KickClient(iTarget, REASON);
                    case 2: GiveMute(iClient, iTarget, g_iTimePunish, 0);
                    case 3: GiveBan(iClient, iTarget, g_iTimePunish);
                }
        }
        case MenuAction_Select:
        {
            
            g_iTypePunish = param2;
            if(g_iTypePunish != 4 && g_iTypePunish != 5)
                GetTimePunish(iClient, buffer);
            else
            {
                if(g_iTypePunish == 4)
                    UTIL_KickClient(iTarget, REASON);
                if(g_iTypePunish == 5)
                    UTIL_SlayClient(iTarget, REASON);
            }
        }
    }
}

void GetTimePunish(int iClient, const char[] id)
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "configs/warnsystem/punish.cfg");
    KeyValues kv = new KeyValues("Punish");

    Menu hMenu = new Menu(OnTimeGetted);
    hMenu.SetTitle("Выберите время:");

    if (FileToKeyValues(kv, path)) 
	{
        //kv.Rewind();
        if (kv.JumpToKey("time", false))
        {
            if(kv.GotoFirstSubKey(false))
            {
                char buffer[64], info[20];
                int time;
                do {
                    KvGetSectionName(kv, buffer, sizeof(buffer));
                    time = kv.GetNum(NULL_STRING);
                    IntToString(time, info, sizeof(info));
                    hMenu.AddItem(info, buffer);
                    //PrintToServer("Item added :: Time is %d", time);
                    //KvGoBack(kv);
                } while (kv.GotoNextKey(false));
                //KvGoBack(kv);
            }
            //KvGoBack(kv);
        }
        else SetFailState("Key 'time' not found!");
        kv.Close();
	}
	else SetFailState("Configuration file not found!");

    if(hMenu.ItemCount != 0) 
    {
        hMenu.AddItem("target", id, ITEMDRAW_NOTEXT);
        hMenu.Display(iClient, TIME);
    }
    else
        hMenu.Close();
}

public int OnTimeGetted(Menu hMenu, MenuAction action, int iClient, int param2)
{
    int iTime, iTarget;
    char buffer[40];
    for(int i = 0, count = hMenu.ItemCount; i < count; ++i)
    {
        hMenu.GetItem(i, buffer, sizeof(buffer));
        if(StrEqual(buffer, "target"))
        {
            hMenu.GetItem(i, "", 0, _, buffer, sizeof(buffer));
            iTarget = StringToInt(buffer);
        }
    }
    switch(action)
    {
        case MenuAction_End: hMenu.Close();
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_Timeout) 
                DefaultPunish(iClient, param2);
            
        }
        case MenuAction_Select:
        {
            char info[20];
            hMenu.GetItem(param2, info, sizeof(info));
            iTime = StringToInt(info);

            /*switch(param2)
            {
                case 0: iTime = 3600/60;
                case 1: iTime = 21600/60;
                case 2: iTime = 43200/60;
                case 3: iTime = 86400/60;
                case 4: iTime = 172800/60;
                case 5: iTime = 259200/60;

            }*/
            switch(g_iTypePunish)
            {
                case 0: GiveBan(iClient,iTarget, iTime);
                case 1: GiveMute(iClient, iTarget, iTime, 0); // mute
                case 2: GiveMute(iClient, iTarget, iTime, 1); // gag
                case 3: GiveMute(iClient, iTarget, iTime, 2); // m + g
                case 4: UTIL_KickClient(iTarget, REASON);
            }
        }
    }
}

void DefaultPunish(int iClient, int iTarget)
{
    switch(g_iDefaultPunish)
    {
        case 1: UTIL_KickClient(iTarget, REASON);
        case 2: GiveMute(iClient, iTarget, g_iTimePunish, 0);
        case 3: GiveBan(iClient, iTarget, g_iTimePunish);
    }
}

void GiveBan(int iAdmin, int iTarget, int iTime)
{
    if(g_bUseSb)
    {
        switch(g_iSbType){
            case 0:     SBBanPlayer(iAdmin, iTarget, iTime, REASON);
            case 1:     SBPP_BanPlayer(iAdmin, iTarget, iTime, REASON);
            case 2:     MABanPlayer(iAdmin, iTarget, MA_BAN_STEAM, iTime, REASON);
        }
    } else {
        BanClient(iTarget, iTime, BANFLAG_AUTHID, REASON, REASON);
    }

    CGOPrintToChatAll("%N получил бан на %d минут", iTarget, iTime);
}

void GiveMute(int iAdmin, int iTarget, int iTime, int iType)
{
    //PrintToServer("GiveMute(): %L, %d, %d", iTarget, iTime, iType);

    if(g_bUseSb)
    {
        if(g_iSbType == 2)
        {
            switch(iType)
            {
                case 0: MASetClientMuteType(iAdmin, iTarget, REASON, MA_MUTE, iTime);
                case 1: MASetClientMuteType(iAdmin, iTarget, REASON, MA_GAG, iTime);
                case 2: MASetClientMuteType(iAdmin, iTarget, REASON, MA_SILENCE, iTime);
            }
        } else {
            switch(iType)
            {
                case 0: SourceComms_SetClientMute(iTarget, true, iTime, true, REASON);
                case 1: SourceComms_SetClientGag(iTarget, true, iTime, true, REASON);
                case 2: { 
                    SourceComms_SetClientMute(iTarget, true, iTime, true, REASON);
                    SourceComms_SetClientGag(iTarget, true, iTime, true, REASON); 
                }
            }
        }
    } else {
        switch(iType)
        {
            case 0: BaseComm_SetClientMute(iTarget, true);
            case 1: BaseComm_SetClientGag(iTarget, true);
            case 2: 
            {
                BaseComm_SetClientMute(iTarget, true);
                BaseComm_SetClientGag(iTarget, true);
            }
        }
    }
    char typePunish[16];
    switch(iType)
    {
        case 0: strcopy(typePunish, sizeof(typePunish), "мут");
        case 1: strcopy(typePunish, sizeof(typePunish), "гаг");
        case 2: strcopy(typePunish, sizeof(typePunish), "мут+гаг");
    }
    CGOPrintToChatAll("%N получил %s на %d минут", iTarget, typePunish, iTime);
}

void UTIL_KickClient(int iClient, const char[] reason)
{
    KickClient(iClient, reason);
    CGOPrintToChatAll("%N получил кик.", iClient);
}

void UTIL_SlayClient(int client, const char[] reason)
{
    ForcePlayerSuicide(client);
    CGOPrintToChatAll("%N был убит по причине: %s", client, reason);
}

stock bool IsValidClient(int iClient) { return (iClient > 0 && iClient < MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient)); }