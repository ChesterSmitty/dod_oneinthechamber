/*	=============================================================================
*
*	One in the Chamber for Day of Defeat: Source
*
*	=============================================================================
*
*	This program is free software; you can redistribute it and/or modify it under
*	the terms of the GNU General Public License, version 3.0, as published by the
*	Free Software Foundation.
*
*	This program is distributed in the hope that it will be useful, but WITHOUT
*	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
*	FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
*	details.
*
*	You should have received a copy of the GNU General Public License along with
*	this program. If not, see <http://www.gnu.org/licenses/>
*
* =============================================================================
*/

static const String:g_szKillEntities[][] =
{
	"dod_scoring",
	"trigger_hurt",
	"func_team_wall",
	"dod_round_timer",
	"dod_bomb_target",
	"dod_capture_area",
	"func_teamblocker"
};

LoadEvents()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_team",  Event_PlayerTeam, EventHookMode_Pre);

	HookEvent("dod_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("dod_round_active", Event_RoundActive, EventHookMode_PostNoCopy);
}

public Action:Event_PlayerTeam(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (g_bModRunning)
	{
		new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

		switch (GetEventInt(hEvent, "team"))
		{
			case Team_Hiders:
			{
				PrintToChatAll("*%N joined the Hiders", iClient);

				return Plugin_Handled;
			}

			case Team_Seekers:
			{
				if (g_bHideTime && !g_bPlayerBlinded[iClient])
				{
					BlindPlayer(iClient, true);
				}

				PrintToChatAll("*%N joined the Seekers", iClient);

				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (GetConVarInt(g_ConVar[Enabled]))
	{
		if (!g_bModRunning)
		{
			if (GetTeamClientCount(Team_Hiders) + GetTeamClientCount(Team_Seekers) >= GetConVarInt(g_ConVar[MinPlayers]))
			{
				g_bModRunning = true;

				PrintToChatAll("%s Game commencing in 15 seconds!", HIDENSEEK_PREFIX);
				CreateTimer(15.0, Timer_RestartRound, _, TIMER_FLAG_NO_MAPCHANGE);

				SetRoundState(RoundState_Restart);
			}
		}
		else
		{
			new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

			switch (GetClientTeam(iClient))
			{
				case Team_Hiders:
				{
					ThirdPerson(iClient);
					RemoveWeapons(iClient);

					new iRandomModel = GetRandomInt(1, g_iNumModels) - 1;

					SetEntData(iClient, g_iOffset_ModelIndex, g_iModelIndex[iRandomModel]);
					SetEntityRenderColor(iClient, 255, 255, 255, 255);

					PrintToChat(iClient, "%s You are now disguised as a \x05%s\x01", HIDENSEEK_PREFIX, g_szModelPrintName[iRandomModel]);

					new iWeapon = GivePlayerItem(iClient, "weapon_amerknife");
					SetEntData(iWeapon, g_iOffset_Effects, EF_NODRAW);
				}

				case Team_Seekers:
				{
					RemoveWeapons(iClient);
					GivePlayerItem(iClient, "weapon_spade");
				}
			}

			FixViewOffset(iClient);
		}
	}
}

public Event_PlayerDeath(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (g_bRoundActive)
	{
		new iUserID = GetEventInt(hEvent, "userid");
		new iClient = GetClientOfUserId(iUserID);

		if (GetClientTeam(iClient) == Team_Hiders)
		{
			new iRagdoll = GetEntDataEnt2(iClient, g_iOffset_Ragdoll);

			if (iRagdoll != -1)
			{
				AcceptEntityInput(iRagdoll, "Kill");
			}

			CreateTimer(0.1, Timer_SwitchToSeekerTeam, iUserID, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Timer_SwitchToSeekerTeam(Handle:hEvent, any:iClient)
{
	if ((iClient = GetClientOfUserId(iClient)) != 0)
	{
		ChangeClientTeam(iClient, Team_Seekers);
	}

	CheckWin();
}

FlashTimer(iTimeRemaining)
{
	new Handle:hEvent = CreateEvent("dod_timer_flash");

	if (hEvent != INVALID_HANDLE)
	{
		SetEventInt(hEvent, "time_remaining", iTimeRemaining);

		FireEvent(hEvent);
	}
}

public Event_RoundStart(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (g_bModRunning && g_bRoundActive)
	{
		SetNumControlPoints(0);

		new iEntity = -1;

		for (new i = 0; i < sizeof(g_szKillEntities); i++)
		{
			while ((iEntity = FindEntityByClassname(iEntity, g_szKillEntities[i])) != -1)
			{
				AcceptEntityInput(iEntity, "Kill");
			}
		}

		if ((iEntity = FindEntityByClassname(iEntity, "dod_bomb_dispenser")) != -1)
		{
			AcceptEntityInput(iEntity, "Disable");
		}

		CreateTimer(0.1, Timer_CreateRoundTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_CreateRoundTimer(Handle:hTimer)
{
	if ((g_iRoundTimer = CreateEntityByName("dod_round_timer")) != -1)
	{
		SetTimeRemaining(g_iRoundTimer, GetConVarInt(g_ConVar[HideTime]));
		PauseTimer(g_iRoundTimer);
	}
	else
	{
		LogError("Error: Unable to create entity: \"dod_round_timer\"!");
	}
}

public Event_RoundActive(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (g_bModRunning && g_bRoundActive && g_iRoundTimer != -1)
	{
		ResumeTimer(g_iRoundTimer);

		g_hRoundTimer = CreateTimer(1.0, RoundTimer_Think, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}
