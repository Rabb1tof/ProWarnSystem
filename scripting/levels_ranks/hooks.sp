void MakeHooks()
{
	HookEventEx("weapon_fire", LRHooks);
	HookEventEx("player_death", LRHooks);
	HookEventEx("player_hurt", LRHooks);
	HookEventEx("round_mvp", LRHooks);
	HookEventEx("round_end", LRHooks);
	HookEventEx("round_start", LRHooks);
	HookEventEx("bomb_planted", LRHooks);
	HookEventEx("bomb_defused", LRHooks);
	HookEventEx("bomb_dropped", LRHooks);
	HookEventEx("bomb_pickup", LRHooks);
	HookEventEx("hostage_killed", LRHooks);
	HookEventEx("hostage_rescued", LRHooks);
}

public void LRHooks(Handle hEvent, char[] sEvName, bool bDontBroadcast)
{
	switch(sEvName[0])
	{
		case 'w':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			if(g_bInitialized[iClient])
			{
				g_iShoots[iClient]++;
				g_iClientSessionData[iClient][3]++;
			}
		}

		case 'p':
		{
			switch(sEvName[7])
			{
				case 'h':
				{
					int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
					int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

					if(iAttacker != iClient && g_bInitialized[iClient] && g_bInitialized[iAttacker])
					{
						g_iHits[iAttacker]++;
						g_iClientSessionData[iAttacker][4]++;
					}
				}

				case 'd':
				{
					int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
					int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

					if(!CheckStatus(iAttacker) || !CheckStatus(iClient))
						return;

					if(iAttacker == iClient)
					{
						NotifClient(iClient, -g_iGiveSuicide, "Suicide");
					}
					else
					{
						if(GetClientTeam(iClient) == GetClientTeam(iAttacker))
						{
							NotifClient(iAttacker, -g_iGiveTeamKill, "TeamKill");
						}
						else
						{
							int iWeapon_ID = 0;
							char sBuffer[185], sWeaponName[192];
							GetEventString(hEvent, "weapon", sBuffer, 192);
							FormatEx(sWeaponName, sizeof(sWeaponName), "weapon_%s", sBuffer);

							if(!strncmp(sWeaponName[7], "knife", 5) || !strncmp(sWeaponName[7], "bayon", 5))
							{
								sWeaponName = "weapon_knife";
							}

							for(; iWeapon_ID < 47;)
							{
								iWeapon_ID++;
								if(StrEqual(sWeaponName, g_sWeaponClassname[iWeapon_ID-1]))
								{
									break;
								}
							}

							if(g_iTypeStatistics != 1)
							{
								NotifClient(iAttacker, RoundToNearest(float(g_iGiveKill) * g_fWeaponsCoeff[iWeapon_ID-1]), "Kill");
								NotifClient(iClient, -(RoundToNearest(float(g_iGiveDeath) * g_fWeaponsCoeff[iWeapon_ID-1])), "MyDeath");
							}
							else
							{
								int iExpAttacker = RoundToNearest(float(g_iExp[iClient]) / float(g_iExp[iAttacker]) * 5.0 * g_fWeaponsCoeff[iWeapon_ID-1]);
								int iExpVictim = RoundToNearest(float(iExpAttacker) * g_fKillCoeff);

								if(iExpAttacker < 1) iExpAttacker = 1;
								if(iExpVictim < 1) iExpVictim = 1;

								if(g_iKills[iAttacker] + g_iDeaths[iAttacker] >= g_iMinCountKills) NotifClient(iAttacker, iExpAttacker, "Kill");
								else NotifClient(iAttacker, g_iGiveCalibration, "CalibrationPlus");

								if(g_iKills[iClient] + g_iDeaths[iClient] >= g_iMinCountKills) NotifClient(iClient, -iExpVictim, "MyDeath");
								else NotifClient(iClient, -g_iGiveCalibration, "CalibrationMinus");
							}


							if(GetEventBool(hEvent, "headshot"))
							{
								g_iHeadshots[iAttacker]++;
								g_iClientSessionData[iAttacker][5]++;
								NotifClient(iAttacker, g_iGiveHeadShot, "HeadShotKill");
							}

							if(g_iEngineGame == EngineGameCSGO)
							{
								int iAssister = GetClientOfUserId(GetEventInt(hEvent, "assister"));
								if(CheckStatus(iAssister))
								{
									g_iAssists[iAssister]++;
									g_iClientSessionData[iAssister][6]++;
									NotifClient(iAssister, g_iGiveAssist, "AssisterKill");
								}
							}

							g_iKills[iAttacker]++;
							g_iClientSessionData[iAttacker][1]++;
							g_iKillstreak[iAttacker]++;
						}
					}

					g_iDeaths[iClient]++;
					g_iClientSessionData[iClient][2]++;
					GiveExpForStreakKills(iClient);
				}
			}
		}

		case 'r':
		{
			switch(sEvName[6])
			{
				case 'e':
				{
					g_bRoundWithoutExp = false;
					int iTeam, iCheckteam = GetEventInt(hEvent, "winner");

					if(iCheckteam > 1)
					{
						for(int iClient = 1; iClient <= MaxClients; iClient++)
						{
							if(CheckStatus(iClient))
							{
								if((iTeam = GetClientTeam(iClient)) > 1)
								{
									if(iTeam == iCheckteam)
									{
										NotifClient(iClient, g_iRoundWin, "RoundWin");
										g_iRoundWinStats[iClient] += 1;
										g_iClientSessionData[iClient][7]++;
									}
									else
									{
										NotifClient(iClient, -g_iRoundLose, "RoundLose");
										g_iRoundLoseStats[iClient] += 1;
										g_iClientSessionData[iClient][8]++;
									}
								}

								if(IsPlayerAlive(iClient))
								{
									GiveExpForStreakKills(iClient);
								}
							}
						}
					}
				}

				case 'm': NotifClient(GetClientOfUserId(GetEventInt(hEvent, "userid")), g_iRoundMVP, "RoundMVP");

				case 's':
				{
					g_iCountPlayers = 0;

					for(int i = 1; i <= MaxClients; i++)
					{
						if(CheckStatus(i) && GetClientTeam(i) > 1)
						{
							GetPlacePlayer(i);
							g_iCountPlayers++;
						}
					}

					if(g_bSpawnMessage)
					{
						bool bWarningMessage = false;
						if(g_iCountPlayers < g_iMinimumPlayers)
						{
							bWarningMessage = true;
						}

						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i))
							{
								if(bWarningMessage)
								{
									LR_PrintToChat(i, "%T", "RoundStartCheckCount", i, g_iCountPlayers, g_iMinimumPlayers);
								}

								LR_PrintToChat(i, "%T", "RoundStartMessageRanks", i);
							}
						}
					}
				}
			}
		}

		case 'b':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			switch(sEvName[6])
			{
				case 'l': g_bHaveBomb[iClient] = false, NotifClient(iClient, g_iBombPlanted, "BombPlanted");
				case 'e': NotifClient(iClient, g_iBombDefused, "BombDefused");
				case 'r': if(g_bHaveBomb[iClient]) {g_bHaveBomb[iClient] = false; NotifClient(iClient, -g_iBombDropped, "BombDropped");}
				case 'i': if(!g_bHaveBomb[iClient]) {g_bHaveBomb[iClient] = true; NotifClient(iClient, g_iBombPickup, "BombPickup");}
			}
		}

		case 'h':
		{
			int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
			switch(sEvName[8])
			{
				case 'k': NotifClient(iClient, -g_iHostageKilled, "HostageKilled");
				case 'r': NotifClient(iClient, g_iHostageRescued, "HostageRescued");
			}
		}
	}
}

void GiveExpForStreakKills(int iClient)
{
	if(g_iKillstreak[iClient] > 1)
	{
		switch(g_iKillstreak[iClient])
		{
			case 2: NotifClient(iClient, g_iBonus[0], "DoubleKill");
			case 3: NotifClient(iClient, g_iBonus[1], "TripleKill");
			case 4: NotifClient(iClient, g_iBonus[2], "Domination");
			case 5: NotifClient(iClient, g_iBonus[3], "Rampage");
			case 6: NotifClient(iClient, g_iBonus[4], "MegaKill");
			case 7: NotifClient(iClient, g_iBonus[5], "Ownage");
			case 8: NotifClient(iClient, g_iBonus[6], "UltraKill");
			case 9: NotifClient(iClient, g_iBonus[7], "KillingSpree");
			case 10: NotifClient(iClient, g_iBonus[8], "MonsterKill");
			case 11: NotifClient(iClient, g_iBonus[9], "Unstoppable");
			default: NotifClient(iClient, g_iBonus[10], "GodLike");
		}
	}

	g_iKillstreak[iClient] = 0;
	SaveDataPlayer(iClient);
}