#if defined _levelsranks_included_
  #endinput
#endif
#define _levelsranks_included_

#define PLUGIN_VERSION "v2.5.4.1"

#define ST_VALUE 0
#define ST_RANK 1
#define ST_KILLS 2
#define ST_DEATHS 3
#define ST_SHOOTS 4
#define ST_HITS 5
#define ST_HEADSHOTS 6
#define ST_ASSISTS 7
#define ST_PLAYTIME 8

char		g_sColorsBefore[][] = {"{WHITE}", "{RED}", "{GREEN}", "{LIME}", "{LIGHTGREEN}", "{LIGHTRED}", "{GRAY}", "{LIGHTOLIVE}", "{OLIVE}", "{LIGHTBLUE}", "{BLUE}", "{PURPLE}"},
		g_sColorsCSGO[][] = {"\x01", "\x02", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0B", "\x0C", "\x0E"};
int		g_iColorsCSSOB[] = {0xFFFFFF, 0xFF0000, 0x00AD00, 0x00FF00, 0x99FF99, 0xFF4040, 0xCCCCCC, 0xFFBD6B, 0xFA8B00, 0x99CCFF, 0x3D46FF, 0xFA00FA};

char		g_sColorsOldBefore[][] = {"{DEFAULT}", "{TEAM}", "{GREEN}"},
		g_sColorsOldCSS[][] = {"\x01", "\x03", "\x04"};

int		g_iIdEngine;
bool		g_bGetEngine = false;

/**
 * Gets the connection to the database
 * 
 * @return Handle	-	Database connection
 */
native Database LR_GetDatabase();

/**
 * Gets the type of database
 * 
 * @return bool	-	if true - SQLite, otherwise - MySQL
 */
native bool LR_GetDatabaseType();

/**
 * Get the name of the table being used in the database.
 * 
 * @noreturn
 */
native void LR_GetTableName(char[] sBuffer, int iMaxLen);

/**
 * Checks if enough players are in this round to activate statistics
 * 
 * @return bool	-	if true - yes, otherwise - no
 */
native bool LR_CheckCountPlayers();

/**
 * Returns ID of statistics type
 * 
 * @return int		-	ID of stastics type
 */
native int LR_GetTypeStatistics();

/**
 * Gets the client's place in the TOP
 * 
 * @param iClient	-	Client index
 * @return int		-	Client position in TOP
 */
native int LR_GetClientPos(int iClient);

/**
 * Gets detailed statistics about the client
 * 
 * @param iClient	-	Client index
 * @param iStats	-	Number of selected data (Example: iStats = ST_VALUE).
 * @return int		-	Obtained data
 */
native int LR_GetClientInfo(int iClient, int iStats);

/**
 * Changes the amount of experience points (only for lr_type_stastics 0)
 * 
 * @param iClient	-	Client index
 * @param iAmount	Count Exp
 * @return int		-	New count client exp.
 */
native int LR_ChangeClientValue(int iClient, int iAmount);

/**
 * Exp Multiplier (only for lr_type_statistics 0)
 * 
 * @param iClient	-	Client index
 * @param fCoeff	-	Multiplier Exp for cases when experience is increased
 * @return bool	-	If true, then the multiplier is set, otherwise false.
 */
native bool LR_SetMultiplierValue(int iClient, float fCoeff);

/**
 * Disables issuance of experience points during the round, which was used by the native
 * 
 * @noreturn
 */
native void LR_RoundWithoutValue();

/**
 * Calls up the inventory menu (necessary to go back)
 * 
 * @param iClient	-	Client index
 * @noreturn
 */
native void LR_MenuInventory(int iClient);

/**
 * Calls up the TOP-10 menu (necessary to go back)
 * 
 * @param iClient	-	Client index
 * @noreturn
 */
native void LR_MenuTopMenu(int iClient);

/**
 * Calls up the Admin's Panel menu (necessary to go back)
 * 
 * @param iClient	-	Client index
 * @noreturn
 */
native void LR_MenuAdminPanel(int iClient);

/**
 * Called when the core is ready.
 */
forward void LR_OnCoreIsReady();

/**
 * Called when the plugin reloads the settings.
 */
forward void LR_OnSettingsModuleUpdate();

/**
 * Called when the plugin has successfully connected to the database.
 */
forward void LR_OnDatabaseLoaded();

/**
 * Called when a list opens Settings
 */
forward void LR_OnMenuCreated(int iClient, Menu& hMenu);

/**
 * Called when a list opens Settings
 */
forward void LR_OnMenuItemSelected(int iClient, const char[] sInfo);

/**
 * Called when a list opens TOP-10
 */
forward void LR_OnMenuCreatedTop(int iClient, Menu& hMenu);

/**
 * Called when a list opens TOP-10
 */
forward void LR_OnMenuItemSelectedTop(int iClient, const char[] sInfo);

/**
 * Called when a list opens Admin's Panel
 */
forward void LR_OnMenuCreatedAdmin(int iClient, Menu& hMenu);

/**
 * Called when a list opens Admin's Panel
 */
forward void LR_OnMenuItemSelectedAdmin(int iClient, const char[] sInfo);

/**
 * Called when the customer's rank changes
 *
 * @param iClient	-	Client index
 * @param iNewLevel	New level
 * @param bUp	-	If true, the level has risen, otherwise it has gone down.
 */
forward void LR_OnLevelChanged(int iClient, int iNewLevel, bool bUp);

/**
 * Called when a player was successfully loaded or added.
 */
forward void LR_OnPlayerLoaded(int iClient);

/**
 * Called when a player is saved
 */
forward void LR_OnPlayerSaved(int iClient, Transaction& hQuery);

stock void LR_PrintToChat(int iClient, char[] szMessage, any ...)
{
	if(iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		char szBuffer[PLATFORM_MAX_PATH], szNewMessage[PLATFORM_MAX_PATH];

		if(!g_bGetEngine)
		{
			g_bGetEngine = true;
			switch(GetEngineVersion())
			{
				case Engine_CSGO: g_iIdEngine = 0;
				case Engine_CSS: g_iIdEngine = 1;
				case Engine_SourceSDK2006: g_iIdEngine = 2;
			}
		}

		switch(g_iIdEngine)
		{
			case 0:
			{
				Format(szBuffer, sizeof(szBuffer), " \x01%s", szMessage);
				VFormat(szNewMessage, sizeof(szNewMessage), szBuffer, 3);

				for(int i = 0; i < 12; i++)
				{
					ReplaceString(szNewMessage, sizeof(szNewMessage), g_sColorsBefore[i], g_sColorsCSGO[i]);
				}
				ReplaceString(szNewMessage, sizeof(szNewMessage), "{TEAM}", "\x03");
			}

			case 1:
			{
				char sBuff[64];
				Format(szBuffer, sizeof(szBuffer), "\x01%s", szMessage);
				VFormat(szNewMessage, sizeof(szNewMessage), szBuffer, 3);

				switch(GetClientTeam(iClient))
				{
					case 1: Format(sBuff, sizeof(sBuff), "\x07%06X", g_iColorsCSSOB[6]);
					case 2: Format(sBuff, sizeof(sBuff), "\x07%06X", g_iColorsCSSOB[5]);
					case 3: Format(sBuff, sizeof(sBuff), "\x07%06X", g_iColorsCSSOB[9]);
				}
				ReplaceString(szNewMessage, sizeof(szNewMessage), "{TEAM}", sBuff);

				for(int i = 0; i < 12; i++)
				{
					Format(sBuff, sizeof(sBuff), "\x07%06X", g_iColorsCSSOB[i]);
					ReplaceString(szNewMessage, sizeof(szNewMessage), g_sColorsBefore[i], sBuff);
				}
			}

			case 2:
			{
				Format(szBuffer, sizeof(szBuffer), "\x01%s", szMessage);
				VFormat(szNewMessage, sizeof(szNewMessage), szBuffer, 3);

				for(int i = 0; i < 3; i++)
				{
					ReplaceString(szNewMessage, sizeof(szNewMessage), g_sColorsOldBefore[i], g_sColorsOldCSS[i]);
				}
			}
		}

		Handle hBf = StartMessageOne("SayText2", iClient, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
		if(hBf != null)
		{
			if(GetUserMessageType() == UM_Protobuf)
			{
				Protobuf hProtoBuffer = UserMessageToProtobuf(hBf);
				hProtoBuffer.SetInt("ent_idx", iClient);
				hProtoBuffer.SetBool("chat", true);
				hProtoBuffer.SetString("msg_name", szNewMessage);
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
				hProtoBuffer.AddString("params", "");
			}
			else
			{
				BfWrite hBfBuffer = UserMessageToBfWrite(hBf);
				hBfBuffer.WriteByte(iClient);
				hBfBuffer.WriteByte(true);
				hBfBuffer.WriteString(szNewMessage);
			}
		}
		EndMessage();
	}
}

public SharedPlugin __pl_levelsranks = 
{
	name = "levelsranks",
	file = "levelsranks.smx",

	#if defined REQUIRE_PLUGIN
		required = 1,
	#else
		required = 0,
	#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_levelsranks_SetNTVOptional()
{
	MarkNativeAsOptional("LR_GetDatabase");
	MarkNativeAsOptional("LR_GetDatabaseType");
	MarkNativeAsOptional("LR_GetTableName");
	MarkNativeAsOptional("LR_CheckCountPlayers");
	MarkNativeAsOptional("LR_GetTypeStatistics");
	MarkNativeAsOptional("LR_GetClientPos");
	MarkNativeAsOptional("LR_GetClientInfo");
	MarkNativeAsOptional("LR_ChangeClientValue");
	MarkNativeAsOptional("LR_SetMultiplierValue");
	MarkNativeAsOptional("LR_RoundWithoutValue");
	MarkNativeAsOptional("LR_MenuInventory");
	MarkNativeAsOptional("LR_MenuTopMenu");
	MarkNativeAsOptional("LR_MenuAdminPanel");
}
#endif