StringMap g_smTrie;

enum ReasonState 
{
	State_None,
	State_Main,
	State_Name
}
ReasonState g_iState = State_None;

void InitializeConfig()
{
	UTIL_CleanMemory();

	bool bResult =	UTIL_ParseConfig("WarnReasons.cfg", OnKV_WReasons, OnNewSection, OnLS_WReasons) &&
					UTIL_ParseConfig("UnwarnReasons.cfg", OnKV_UReasons, OnNewSection, OnLS_UReasons) &&
					UTIL_ParseConfig("ResetWarnReasons.cfg", OnKV_RReasons, OnNewSection, OnLS_RReasons);
	BuildPath(Path_SM, g_sPathAgreePanel, sizeof(g_sPathAgreePanel), "configs/warnsystem/WarnAgreement.cfg");
					//UTIL_ParseConfig("WarnAgreement.cfg", OnKV_Agreement, OnNewSection, OnEndSection);

	if (!bResult)
	{
		SetFailState("Something went wrong. Check logs.");
	}
}

bool UTIL_ParseConfig(const char[] szFileName,
    SMC_KeyValue fnOnKv,
    SMC_NewSection fnOnES,
    SMC_EndSection fnOnLS)
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/warnsystem/%s", szFileName);

	if (!FileExists(szPath))
		return false;

	g_iState = State_None;
	SMCParser hSMC = new SMCParser();
	SMC_SetReaders(hSMC, fnOnES, fnOnKv, fnOnLS);

	int iLine, iCol;
	SMCError iErr = hSMC.ParseFile(szPath, iLine, iCol);
	CloseHandle(hSMC);

	if (iErr != SMCError_Okay)
	{
		char szErrorDescription[256];
		SMC_GetErrorString(iErr, szErrorDescription, sizeof(szErrorDescription));

		LogWarnings("Couldn't parse file (%s, line %d, col %d): %s", szFileName, iLine, iCol, szErrorDescription);
	}

	return (iErr == SMCError_Okay);
}

public SMCResult OnNewSection(SMCParser hParser, const char[] szName, bool bOpt_quotes) {
	if (g_iState != State_Main && g_iState != State_None)
	{
		// WUT
		return SMCParse_HaltFail;
	}

	if (g_iState == State_None)
	{
		g_iState = State_Main;
		return SMCParse_Continue;
	}

	g_iState = State_Name;
	g_smTrie = new StringMap();
	return SMCParse_Continue;
}

/**
 * KV Parser defines
 */
#define SMC_KVREADER(%0)			public SMCResult %0(SMCParser hSMC, const char[] szKey, const char[] szValue, bool bKeyQuotes, bool bValueQuotes)
#define SMC_LSREADER(%0)			public SMCResult %0(SMCParser hSMC)

#define SMC_KV_CHECKSTATE(%0,%1)	if (g_iState != %0) { LogError(%1); return SMCParse_HaltFail; }
#define SMC_KV_CHECKNAME()			SMC_KV_CHECKSTATE(State_Name, "OnKV(): Unexpected KeyValue pair. Stopping...")
#define SMC_KV_RETURN()				return SMCParse_Continue

#define PARSE_GENERIC(%0,%1,%2,%3)	if (!strcmp(szKey, %0)) { g_smTrie.%2(%1, %3, true); }
#define PARSE_STR(%0,%1,%2)			PARSE_GENERIC(%0,%1, SetString, %2)
#define PARSE_INT(%0,%1,%2)			PARSE_GENERIC(%0,%1, SetValue, StringToInt(%2))

#define PARSE_REASON(%0)			PARSE_STR("Reason", %0, szValue)
#define PARSE_TIME()				PARSE_INT("Time", "time", szValue)
#define PARSE_FLAGS(%0)				PARSE_STR("Flags", "flags_" ... %0, szValue)
#define PARSE_SCORE()				PARSE_INT("Score", "score", szValue)

SMC_KVREADER(OnKV_WReasons)
{
	SMC_KV_CHECKNAME()

	PARSE_REASON("warn")
	PARSE_TIME()
	PARSE_FLAGS("warn")
	PARSE_SCORE()

	SMC_KV_RETURN();
}

SMC_KVREADER(OnKV_UReasons)
{
	SMC_KV_CHECKNAME()

	PARSE_REASON("unwarn")
	PARSE_FLAGS("unwarn")

	SMC_KV_RETURN();
}

SMC_KVREADER(OnKV_RReasons)
{
	SMC_KV_CHECKNAME()

	PARSE_REASON("resetwarn")
	PARSE_FLAGS("resetwarn")

	SMC_KV_RETURN();
}

/*SMC_KVREADER(OnKV_Agreement)
{}*/

SMC_LSREADER(OnLS_WReasons)
{
	PushWhenLeavedReason(g_aWarn);
}

SMC_LSREADER(OnLS_UReasons)
{
	PushWhenLeavedReason(g_aUnwarn);
}

SMC_LSREADER(OnLS_RReasons)
{
	PushWhenLeavedReason(g_aResetWarn);
}

SMC_LSREADER(OnEndSection)
{
	SMC_KV_RETURN();
}

void PushWhenLeavedReason(ArrayList hArray)
{
	PushOnCondition(State_Name, State_Main, hArray);
}

void PushOnCondition(ReasonState iRequiredState, ReasonState iNewState, ArrayList hArray)
{
	if (g_iState == iRequiredState)
	{
		g_iState = iNewState;
		hArray.Push(g_smTrie);
	}
}