void NotifClient(int iClient, int iValue, char[] sTitlePhrase)
{
	if(g_bWarmUpCheck && g_iEngineGame == EngineGameCSGO && GameRules_GetProp("m_bWarmupPeriod"))
	{
		return;
	}

	if(!g_bRoundWithoutExp && iValue != 0 && g_iCountPlayers >= g_iMinimumPlayers && CheckStatus(iClient))
	{
		if(g_fCoefficient[iClient] > 1.0 && iValue > 0)
		{
			iValue = RoundToNearest(float(iValue) * g_fCoefficient[iClient]);
		}

		int iExpMin = (g_iTypeStatistics == 0 ? 0 : 400);
		g_iExp[iClient] += iValue;

		if(g_iExp[iClient] < iExpMin)
		{
			g_iExp[iClient] = iExpMin;
		}

		CheckRank(iClient);

		if(g_bUsualMessage)
		{
			char sBuffer[64];
			FormatEx(sBuffer, sizeof(sBuffer), "%s%i", iValue > 0 ? "+" : "-", iValue > 0 ? iValue : -iValue);
			LR_PrintToChat(iClient, "%T", sTitlePhrase, iClient, g_iExp[iClient], sBuffer);
		}
	}
}

bool CheckStatus(int iClient)
{
	if(iClient && IsClientInGame(iClient) && !IsFakeClient(iClient) && g_bInitialized[iClient])
	{
		return true;
	}
	else g_bInitialized[iClient] = false;

	return false;
}

void CheckRank(int iClient)
{
	if(CheckStatus(iClient))
	{
		int iRank = g_iRank[iClient];

		if(g_iKills[iClient] + g_iDeaths[iClient] >= g_iMinCountKills)
		{
			for(int i = 18; i >= 1; i--)
			{
				if(i == 1)
				{
					g_iRank[iClient] = 1;
				}
				else if(g_iShowExp[i] <= g_iExp[iClient])
				{
					g_iRank[iClient] = i;
					break;
				}
			}
		}

		if(g_iRank[iClient] > iRank)
		{
			LR_PrintToChat(iClient, "%T", "LevelUp", iClient, g_sShowRank[g_iRank[iClient]]);
			LR_CallRankForward(iClient, g_iRank[iClient], true);
		}
		else if(g_iRank[iClient] < iRank)
		{
			LR_PrintToChat(iClient, "%T", "LevelDown", iClient, g_sShowRank[g_iRank[iClient]]);
			LR_CallRankForward(iClient, g_iRank[iClient], false);
		}
	}
}

public Action PlayTimeCounter(Handle hTimer)
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(CheckStatus(iClient))
		{
			g_iPlayTime[iClient] += 1;
			g_iClientSessionData[iClient][9] += 1;
		}
	}
}

void LR_CallRankForward(int iClient, int iNewLevel, bool bUp)
{
	Call_StartForward(g_hForward_OnLevelChanged);
	Call_PushCell(iClient);
	Call_PushCell(iNewLevel);
	Call_PushCell(bUp);
	Call_Finish();
}