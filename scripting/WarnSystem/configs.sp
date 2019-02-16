SMCParser g_smcCfgWarnParser, g_smcCfgUnwarnParser, g_smcCfgResetParser;
StringMap g_smTrie;

enum ReasonState 
{
	State_None,
	State_Main,
	State_ReasonName
}
ReasonState g_iWarnState = State_None, g_iUnwarnState = State_None, g_iResetState = State_None;

bool InitializeConfig()
{
	UTIL_CleanMemory();
	BuildPath(Path_SM, g_sPathWarnReasons, sizeof(g_sPathWarnReasons), "configs/WarnSystem/WarnReasons.cfg");
	BuildPath(Path_SM, g_sPathUnwarnReasons, sizeof(g_sPathUnwarnReasons), "configs/WarnSystem/UnwarnReasons.cfg");
	BuildPath(Path_SM, g_sPathResetReasons, sizeof(g_sPathResetReasons), "configs/WarnSystem/ResetWarnReasons.cfg");
	BuildPath(Path_SM, g_sPathAgreePanel, sizeof(g_sPathAgreePanel), "configs/WarnSystem/WarnAgreement.cfg");
	
	
	//------------------------------------------Warnings Parser---------------------------------------------
	if (g_smcCfgWarnParser == null)
		g_smcCfgWarnParser = new SMCParser();
	if (FileExists(g_sPathWarnReasons)) 
	{
		g_iWarnState = State_None;
		SMC_SetReaders(g_smcCfgWarnParser, Warn_NewSection, Warn_KeyValue, Config_EndSection);
		SMC_SetParseEnd(g_smcCfgWarnParser, Config_End);
		int iLine, iCol;
		SMCError err = g_smcCfgWarnParser.ParseFile(g_sPathWarnReasons, iLine, iCol);
		
		if (err != SMCError_Okay)
		{
			char sError[256];
			g_smcCfgWarnParser.GetErrorString(err, sError, sizeof(sError));
			LogWarnings("Could not parse file (line %d, col %d    file \"%s\"):", iLine, iCol, g_sPathWarnReasons);
			LogToFile("Parser encountered error: %s", sError);
		}
		CloseHandle(g_smcCfgWarnParser);
		g_smcCfgWarnParser = null;
		return (err == SMCError_Okay);
	}
	
	//------------------------------------------Unwarnings Parser---------------------------------------------
	if(g_smcCfgUnwarnParser == null)
		g_smcCfgUnwarnParser = new SMCParser();
	if(FileExists(g_sPathUnwarnReasons))
	{
		g_iUnwarnState = State_None;
		SMC_SetReaders(g_smcCfgUnwarnParser, Unwarn_NewSection, Unwarn_KeyValue, Config_EndSection);
		SMC_SetParseEnd(g_smcCfgUnwarnParser, Config_End);
		int iLine, iCol;
		SMCError err = g_smcCfgUnwarnParser.ParseFile(g_sPathUnwarnReasons, iLine, iCol);
		
		if (err != SMCError_Okay)
		{
			char sError[256];
			g_smcCfgUnwarnParser.GetErrorString(err, sError, sizeof(sError));
			LogWarnings("Could not parse file (line %d, col %d    file \"%s\"):", iLine, iCol, g_sPathUnwarnReasons);
			LogToFile("Parser encountered error: %s", sError);
		}
		CloseHandle(g_smcCfgUnwarnParser);
		g_smcCfgUnwarnParser = null;
		return (err == SMCError_Okay);
	}
	
	//------------------------------------------Reset Warnings Parser---------------------------------------------
	if(g_smcCfgResetParser == null)
		g_smcCfgResetParser = new SMCParser();
	if(FileExists(g_sPathResetReasons))
	{
		g_iUnwarnState = State_None;
		SMC_SetReaders(g_smcCfgResetParser, Resetwarn_NewSection, Resetwarn_KeyValue, Config_EndSection);
		SMC_SetParseEnd(g_smcCfgResetParser, Config_End);
		int iLine, iCol;
		SMCError err = g_smcCfgResetParser.ParseFile(g_sPathResetReasons, iLine, iCol);
		
		if (err != SMCError_Okay)
		{
			char sError[256];
			g_smcCfgResetParser.GetErrorString(err, sError, sizeof(sError));
			LogWarnings("Could not parse file (line %d, col %d    file \"%s\"):", iLine, iCol, g_sPathResetReasons);
			LogToFile("Parser encountered error: %s", sError);
		}
		CloseHandle(g_smcCfgResetParser);
		g_smcCfgResetParser = null;
		return (err == SMCError_Okay);
	}
	return false;
}

public SMCResult Warn_NewSection(SMCParser hParser, const char[] szName, bool bOpt_quotes) {
	
	if (StrEqual(szName, "Warn Reasons"))	
		g_iWarnState = State_Main;
	else if (g_iWarnState == State_Main) {
		g_iWarnState = State_ReasonName;
		g_smTrie = new StringMap();
	}
	return SMCParse_Continue;
}

public SMCResult Warn_KeyValue(SMCParser hParser, const char[] szKey, const char[] szValue, bool bKey_quotes, bool bValue_quotes)
{
	if (g_iWarnState != State_ReasonName) {
		LogError("Warn_KeyValue(): Unexpected KeyValue. Stopping...");
		return SMCParse_HaltFail;
	}

	if (StrEqual(szKey, "Reason")) {
		g_smTrie.SetString("warn", szValue, true);
	} else if (StrEqual(szKey, "Time")) {
		g_smTrie.SetValue("time", StringToInt(szValue), true);
	} else if (StrEqual(szKey, "Flags")) {
		g_smTrie.SetString("flags_warn", szValue, true);
		//g_smTrie.SetValue("Translation", true);
	} else if (StrEqual(szKey, "Score")) {
		g_smTrie.SetValue("score", StringToInt(szValue), true);
	} else {
		g_smTrie.SetString(szKey, szValue, true);
	}

	return SMCParse_Continue;
}

public SMCResult Unwarn_NewSection(SMCParser hParser, const char[] szName, bool bOpt_quotes) {
	
	if (StrEqual(szName, "Unwarn Reasons"))	
		g_iUnwarnState = State_Main;
	else if (g_iUnwarnState == State_Main) {
		g_iUnwarnState = State_ReasonName;
		g_smTrie = new StringMap();
	}
	return SMCParse_Continue;
}

public SMCResult Unwarn_KeyValue(SMCParser hParser, const char[] szKey, const char[] szValue, bool bKey_quotes, bool bValue_quotes)
{
	if (g_iUnwarnState != State_ReasonName) {
		LogError("Unwarn_KeyValue(): Unexpected KeyValue. Stopping...");
		return SMCParse_HaltFail;
	}

	if (StrEqual(szKey, "Reason")) {
		g_smTrie.SetString("unwarn", szValue, true);
	} else if (StrEqual(szKey, "Flags")) {
		g_smTrie.SetString("flags_unwarn", szValue, true);
		//g_smTrie.SetValue("Translation", true);
	} else {
		g_smTrie.SetString(szKey, szValue, true);
	}

	return SMCParse_Continue;
}

public SMCResult Resetwarn_NewSection(SMCParser hParser, const char[] szName, bool bOpt_quotes) {
	
	if (StrEqual(szName, "Resetwarn Reasons"))	
		g_iResetState = State_Main;
	else if (g_iResetState == State_Main) {
		g_iResetState = State_ReasonName;
		g_smTrie = new StringMap();
	}
	return SMCParse_Continue;
}

public SMCResult Resetwarn_KeyValue(SMCParser hParser, const char[] szKey, const char[] szValue, bool bKey_quotes, bool bValue_quotes)
{
	if (g_iResetState != State_ReasonName) {
		LogError("Resetwarn_KeyValue(): Unexpected KeyValue. Stopping...");
		return SMCParse_HaltFail;
	}

	if (StrEqual(szKey, "Reason")) {
		g_smTrie.SetString("resetwarn", szValue, true);
	} else if (StrEqual(szKey, "Flags")) {
		g_smTrie.SetString("flags_resetwarn", szValue, true);
		//g_smTrie.SetValue("Translation", true);
	} else {
		g_smTrie.SetString(szKey, szValue, true);
	}

	return SMCParse_Continue;
}

public SMCResult Config_EndSection(SMCParser hParser) 
{
	if (g_iWarnState == State_Main)
		g_iWarnState = State_None;
	else if (g_iWarnState == State_ReasonName) {
		g_iWarnState = State_Main;
		g_aWarn.Push(g_smTrie);
	}
	else if (g_iUnwarnState == State_Main)
		g_iUnwarnState = State_None;
	else if (g_iUnwarnState == State_ReasonName) {
		g_iUnwarnState = State_Main;
		g_aUnwarn.Push(g_smTrie);
	}
	else if (g_iResetState == State_Main)
		g_iResetState = State_None;
	else if (g_iResetState == State_ReasonName) {
		g_iResetState = State_Main;
		g_aResetWarn.Push(g_smTrie);
	}
	CloseHandle(g_smTrie);
	g_smTrie = null;
}

public void Config_End(SMCParser hParser, bool bHalted, bool bFailed) 
{
	if (bFailed)
		SetFailState("Plugin configuration error");
}  