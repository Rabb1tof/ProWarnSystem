ConVar g_hCvarMaxWarns, g_hCvarMaxPunishment, g_hCvarBanLength, g_hCvarPunishment, g_hCvarSlapDamage, g_hCvarPrintToAdmins,
	   g_hCvarLogWarnings, g_hCvarWarnSound, g_hCvarWarnSoundPath, g_hCvarResetWarnings, g_hCvarPrintToChat, 
	   g_hCvarDeleteExpired, g_hCvarLogQuery, g_hCvarWarnLength, g_hCvarScoreLength, g_hCvarWarnTime, g_hCvarMaxScore,
	   g_hCvarWarnType, g_hCvarUseCustom;

bool g_bResetWarnings, g_bWarnSound, g_bPrintToAdmins, g_bLogWarnings, g_bPrintToChat, g_bDeleteExpired,
		g_bLogQuery, g_bWarnTime, g_bUseCustom;
int g_iMaxWarns, g_iPunishment, g_iMaxPunishment, g_iBanLenght, g_iScoreLength, g_iSlapDamage, g_iWarnLength, g_iMaxScore,
    g_iWarnType;
char g_sWarnSoundPath[PLATFORM_MAX_PATH];

public void InitializeConVars()
{
	g_hCvarResetWarnings = CreateConVar("sm_warns_resetwarnings", "0", "Delete warns then player reach max warns: 0 - Keep warns(set it expired), 1 - Delete warns", _, true, 0.0, true, 1.0);
	g_hCvarMaxWarns = CreateConVar("sm_warns_maxwarns", "3", "Max warnings before punishment", _, true, 0.0, true, 10.0);
	g_hCvarPunishment = CreateConVar("sm_warns_punishment", "7", "On warn: 1 - message player, 2 - slap player and message, 3 - slay player and message, 4 - Popup agreement and message, 5 - kick player with reason, 6 - ban player with reason, 7 - ban(or do something) with module", _, true, 1.0, true, 7.0);
	g_hCvarMaxPunishment = CreateConVar("sm_warns_maxpunishment", "3", "On max warns: 1 - kick, 2 - ban, 3 - ban(or do something) with module", _, true, 1.0, true, 3.0);
	g_hCvarBanLength = CreateConVar("sm_warns_banlength", "60", "Time to ban target(minutes): 0 - permanent");
	g_hCvarSlapDamage = CreateConVar("sm_warns_slapdamage", "0", "Slap player with damage: 0 - no damage", _, true, 0.0, true, 300.0);
	
	g_hCvarWarnSound = CreateConVar("sm_warns_warnsound", "1", "Play a sound when a user receives a warning: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0);
	g_hCvarWarnSoundPath = CreateConVar("sm_warns_warnsoundpath", "buttons/weapon_cant_buy.wav", "Path to the sound that'll play when a user receives a warning");
	
	g_hCvarPrintToAdmins = CreateConVar("sm_warns_printtoadmins", "1", "Print previous warnings on client connect to admins: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0);
	g_hCvarPrintToChat = CreateConVar("sm_warns_printtochat", "1", "Print to all, then somebody warned/unwarned: 0 - print only to admins, 1 - print to all", _, true, 0.0, true, 1.0);
	g_hCvarLogWarnings = CreateConVar("sm_warns_enablelogs", "1", "Log errors and warns: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0);
	g_hCvarDeleteExpired = CreateConVar("sm_warns_delete_expired", "1", "Delete expired warnings of DB: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0);
	g_hCvarLogQuery = CreateConVar("sm_warns_enable_querylog", "0", "Logging query to DB: 0 - disabled, 1 - enabled", _, true, 0.0, true, 1.0);
	g_hCvarWarnLength = CreateConVar("sm_warns_warnlength", "86400", "Duration of the issued warning in seconds (0 - permanent).");
	g_hCvarScoreLength = CreateConVar("sm_warns_score_default", "10");
	g_hCvarWarnTime = CreateConVar("sm_warns_warntime_type", "1", "Take duration from config if set 1 or from cvar ('sm_warns_warnlength') for all if set 0: 0 - cvar, 1 - config.");
	g_hCvarMaxScore = CreateConVar("sm_warns_maxscore", "50", "Max score (points) before punishment", _, true, 0.0);
	g_hCvarWarnType = CreateConVar("sm_warns_warntype", "2", "Работа всей системы: (0 - по колличеству предупреждений, 1 - система баллов, 2 - оба варианта.", _, true, 0.0, true, 2.0);
	g_hCvarUseCustom = CreateConVar("sm_warns_use_custom", "1", "Разрешить кастомные причины и их время: (1 - разрешить, 0 - запретить).", _, true, 0.0, true, 1.0);	

	g_hCvarWarnType.AddChangeHook(ChangeCvar_WarnType);
	g_hCvarMaxWarns.AddChangeHook(ChangeCvar_MaxWarns);
	g_hCvarWarnTime.AddChangeHook(ChangeCvar_WarnTime);
	g_hCvarMaxScore.AddChangeHook(ChangeCvar_MaxScore);
	g_hCvarLogQuery.AddChangeHook(ChangeCvar_LogQuery);
	g_hCvarWarnSound.AddChangeHook(ChangeCvar_WarnSound);
	g_hCvarBanLength.AddChangeHook(ChangeCvar_BanLength);
	g_hCvarScoreLength.AddChangeHook(ChangeCvar_ScoreLength);
	g_hCvarWarnLength.AddChangeHook(ChangeCvar_WarnLength);
	g_hCvarPunishment.AddChangeHook(ChangeCvar_Punishment);
	g_hCvarSlapDamage.AddChangeHook(ChangeCvar_SlapDamage);
	g_hCvarPrintToChat.AddChangeHook(ChangeCvar_PrintToChat);
	g_hCvarLogWarnings.AddChangeHook(ChangeCvar_LogWarnings);
	g_hCvarWarnSoundPath.AddChangeHook(ChangeCvar_WarnSoundPath);
	g_hCvarPrintToAdmins.AddChangeHook(ChangeCvar_PrintToAdmins);
	g_hCvarDeleteExpired.AddChangeHook(ChangeCvar_DeleteExpired);
	g_hCvarMaxPunishment.AddChangeHook(ChangeCvar_MaxPunishment);
	g_hCvarResetWarnings.AddChangeHook(ChangeCvar_ResetWarnings);
	g_hCvarUseCustom.AddChangeHook(ChangeCvar_UseCustom);
	
	
	AutoExecConfig(true, "core", "warnsystem");
}

public void OnConfigsExecuted()
{
	g_bResetWarnings = g_hCvarResetWarnings.BoolValue;
	g_iMaxWarns = g_hCvarMaxWarns.IntValue;
	g_iMaxScore = g_hCvarMaxScore.IntValue;
	g_iWarnType = g_hCvarWarnType.IntValue;
	g_iPunishment = g_hCvarPunishment.IntValue;
	g_iMaxPunishment = g_hCvarMaxPunishment.IntValue;
	g_iBanLenght = g_hCvarBanLength.IntValue;
	g_iSlapDamage = g_hCvarSlapDamage.IntValue;
	g_iWarnLength = g_hCvarWarnLength.IntValue;
	g_iScoreLength = g_hCvarScoreLength.IntValue;
	g_bWarnTime = g_hCvarWarnTime.BoolValue;
	
	g_bWarnSound = g_hCvarWarnSound.BoolValue;
	g_hCvarWarnSoundPath.GetString(g_sWarnSoundPath, sizeof(g_sWarnSoundPath));
	
	g_bPrintToAdmins = g_hCvarPrintToAdmins.BoolValue;
	g_bPrintToChat = g_hCvarPrintToChat.BoolValue;
	g_bLogWarnings = g_hCvarLogWarnings.BoolValue;
	g_bLogQuery = g_hCvarLogQuery.BoolValue;
	g_bDeleteExpired = g_hCvarDeleteExpired.BoolValue;
	
	g_bUseCustom = g_hCvarUseCustom.BoolValue;
}

public void ChangeCvar_WarnType(ConVar convar, const char[] oldValue, const char[] newValue) { g_iWarnType = convar.IntValue; }
public void ChangeCvar_ResetWarnings(ConVar convar, const char[] oldValue, const char[] newValue){g_bResetWarnings = convar.BoolValue;}
public void ChangeCvar_MaxWarns(ConVar convar, const char[] oldValue, const char[] newValue){g_iMaxWarns = convar.IntValue;}
public void ChangeCvar_MaxScore(ConVar convar, const char[] oldValue, const char[] newValue){g_iMaxScore = convar.IntValue;}
public void ChangeCvar_Punishment(ConVar convar, const char[] oldValue, const char[] newValue){g_iPunishment = convar.IntValue;}
public void ChangeCvar_MaxPunishment(ConVar convar, const char[] oldValue, const char[] newValue){g_iMaxPunishment = convar.IntValue;}
public void ChangeCvar_BanLength(ConVar convar, const char[] oldValue, const char[] newValue){g_iBanLenght = convar.IntValue;}
public void ChangeCvar_WarnLength(ConVar convar, const char[] oldValue, const char[] newValue){g_iWarnLength = convar.IntValue;}
public void ChangeCvar_ScoreLength(ConVar convar, const char[] oldValue, const char[] newValue){g_iScoreLength = convar.IntValue;}
public void ChangeCvar_SlapDamage(ConVar convar, const char[] oldValue, const char[] newValue){g_iSlapDamage = convar.IntValue;}
public void ChangeCvar_WarnSound(ConVar convar, const char[] oldValue, const char[] newValue){g_bWarnSound = convar.BoolValue;}
public void ChangeCvar_WarnSoundPath(ConVar convar, const char[] oldValue, const char[] newValue){convar.GetString(g_sWarnSoundPath, sizeof(g_sWarnSoundPath));}
public void ChangeCvar_PrintToAdmins(ConVar convar, const char[] oldValue, const char[] newValue){g_bPrintToAdmins = convar.BoolValue;}
public void ChangeCvar_PrintToChat(ConVar convar, const char[] oldValue, const char[] newValue){g_bPrintToChat = convar.BoolValue;}
public void ChangeCvar_LogWarnings(ConVar convar, const char[] oldValue, const char[] newValue){g_bLogWarnings = convar.BoolValue;}
public void ChangeCvar_DeleteExpired(ConVar convar, const char[] oldValue, const char[] newValue){g_bDeleteExpired = convar.BoolValue;}
public void ChangeCvar_LogQuery(ConVar convar, const char[] oldValue, const char[] newValue){g_bLogQuery = convar.BoolValue;}
public void ChangeCvar_WarnTime(ConVar convar, const char[] oldValue, const char[] newValue){g_bWarnTime = convar.BoolValue;}
public void ChangeCvar_UseCustom(ConVar convar, const char[] oldValue, const char[] newValue){g_bUseCustom = convar.BoolValue;}