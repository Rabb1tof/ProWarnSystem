#if defined _warnsystem_included
  #endinput
#endif

#define _warnsystem_included
#define APIVERSION "1.5.2.3-pro"

public SharedPlugin __pl_WarnSystem = {
    name = "WarnSystem",
    file = "WarnSystem.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_DynamicMOTD_SetNTVOptional() {
    MarkNativeAsOptional("WarnSystem_Warn");
    MarkNativeAsOptional("WarnSystem_UnWarn");
    MarkNativeAsOptional("WarnSystem_ResetWarn");
    MarkNativeAsOptional("WarnSystem_GetDatabase");
    MarkNativeAsOptional("WarnSystem_GetPlayerInfo");
	MarkNativeAsOptional("WarnSystem_GetMaxWarns");
	MarkNativeAsOptional("WarnSystem_GetMaxScore");
	MarkNativeAsOptional("WarnSystem_PrintToAdmins");
}
#endif

/*********************************************************
 * Issue a warning on a player
 *
 * @param iClient		The admin who issued a warning
 * @param iTarget		The client to issue a warning on
 * @param iScore		Amount of points awarded
 * @param sReason		The reason why you issue a warning on client
 * @noreturn		
 *********************************************************/
native void WarnSystem_Warn(int iClient, int iTarget, int iScore, int iTime, char sReason[129]);

/*********************************************************
 * Remove a warning on a player
 *
 * @param iClient		The admin who issued a warning
 * @param iId		    The ID of warning to remove the warning on
 * @param sReason		The reason why you remove the warning
 * @noreturn		
 *********************************************************/
native void WarnSystem_UnWarn(int iClient, int iId, char sReason[129]);

/*********************************************************
 * Reset a players warnings
 *
 * @param iClient		The admin who issued a warning
 * @param iTarget		The client to reset the warnings on
 * @param sReason		The reason why you reset the warnings
 * @noreturn		
 *********************************************************/
native void WarnSystem_ResetWarn(int iClient, int iTarget, char sReason[129]);

/*********************************************************
* Returns database handle
*
* @noparam
* @return Database	handle	
*********************************************************/
native Database WarnSystem_GetDatabase();

/*********************************************************
* Returns count of player warns
*
* @param 	iTarget     Index of client
* @param    iType       Type of information, where: 1 - amount warns, 2 - amount score
* @return 	Count of client warnings
*********************************************************/
native int WarnSystem_GetPlayerInfo(int iTarget, int iType);

/*********************************************************
* Returns count of max score
*
* @noparam
* @return 	Count of max score
*********************************************************/
native int WarnSystem_GetMaxScore();

/*********************************************************
* Returns count of max warns
*
* @noparam
* @return 	Count of max warnings
*********************************************************/
native int WarnSystem_GetMaxWarns();

/*********************************************************
* Prints message to admins.
*
* @param 	sMessage
* @noreturn
*********************************************************/
native void WarnSystem_PrintToAdmins(char sMessage[256]);

/*********************************************************
* Calling then client data loaded successfully
*
* @param iTarget		Client
* @param iWarnings		Count of client warns
* @param g_iMaxWarns	Count of max allowed warns
* @noreturn
*********************************************************/
forward void WarnSystem_OnClientLoaded(int iTarget, int iWarnings, int g_iMaxWarns);

/*********************************************************
* Calling then admin issues a warn
*
* @param iClient		The admin who issued a warning
* @param iTarget		The client to warn
* @param sReason		The reason why he warns
* @noreturn	
*********************************************************/
forward void WarnSystem_OnClientWarn(int iClient, int iTarget, int iScore, int iTime, char sReason[129], bool bIsAdmin);

/*********************************************************
* Calling after admin give a warn
*
* @param iClient		The admin who give a warning
* @param iTarget		The client to warn
* @param iTime          Time of warning
* @param iScore         Amount score of warning
* @param sReason		The reason why he be warned
* @noreturn	
*********************************************************/
forward Action WarnSystem_OnClientWarnPre(int iClient, int iTarget, int iTime, int iScore, char sReason[129]);

/*********************************************************
* Calling then admin issues a unwarn
*
* @param iClient		The admin who issued a unwarning
* @param iTarget		The client to unwarn
* @param iId            Id of warning
* @param iScore         Amount score of warning
* @param sReason		The reason why he be unwarned
* @noreturn	
*********************************************************/
forward void WarnSystem_OnClientUnWarn(int iClient, int iTarget, int iId, int iScore, char sReason[129]);

/*********************************************************
* Calling after admin issues a unwarn
*
* @param iClient		The admin who issued a unwarning
* @param iTarget		The client to unwarn
* @param iId            Id of warning
* @param iScore         Amount score of warning
* @param sReason		The reason why he unwarns
* @noreturn	
*********************************************************/
forward Action WarnSystem_OnClientUnWarnPre(int iClient, int iTarget, int iId, int iScore, char sReason[129]);

/*********************************************************
* Calling then admin issues a warn reset
*
* @param iClient		The admin who issued a warn reset
* @param iTarget		The client to reset warns
* @param sReason		The reason why he reset warns
* @noreturn	
*********************************************************/
forward void WarnSystem_OnClientResetWarns(int iClient, int iTarget, char sReason[129]);

/*********************************************************
* Calling before admin issues a warn reset
*
* @param iClient		The admin who issued a warn reset
* @param iTarget		The client to reset warns
* @param sReason		The reason why he reset warns
* @noreturn	
*********************************************************/
forward Action WarnSystem_OnClientResetWarnsPre(int iClient, int iTarget, char sReason[129]);

/*********************************************************
* Calling on warn to punish player
*
* @param iClient		The admin who issued warn
* @param iTarget		The client
* @param sReason		The ban reason
* @return Return Plugin_Stop or core will log error
*********************************************************/
forward Action WarnSystem_WarnPunishment(int iClient, int iTarget, int iBanLenght, char sReason[129]);

/*********************************************************
* Calling on maxwarns to punish player
*
* @param iClient		The admin who issued warn
* @param iTarget		The client
* @param sReason		The ban reason
* @return Return Plugin_Stop or core will log error
*********************************************************/
forward Action WarnSystem_WarnMaxPunishment(int iClient, int iTarget, int iBanLenght, char sReason[129]);