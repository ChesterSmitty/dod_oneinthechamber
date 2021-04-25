////////////////////////////////////////////////////////
//
// SourceMod Script
//
// DoD RealismMatch Helper
//
// Developed by FeuerSturm for the Realism Community!
//
////////////////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "pub-beta5"

#define NOTEAM	0
#define SPEC	1
#define ALLIES	2
#define AXIS	3

#define MAXCLASSES		14
#define MAXWEAPONS		22
#define MAXVOICECMDS	39
#define BLINDOVERLAY	"Effects/tp_eyefx/tp_black"
#define HIDEHUD_ALL		( 1<<2 )

#define MATCHCFG		"cfg/dod_realismmatch_helper/dod_realismmatch_helper.ini"
#define INITCFG			"dod_realismmatch_helper/init.cfg"
#define STARTCFG		"dod_realismmatch_helper/start.cfg"
#define CANCELCFG		"dod_realismmatch_helper/cancel.cfg"

public Plugin:myinfo =
{
	name = "DoD RealismMatch Helper",
	author = "FeuerSturm",
	description = "Completely automatic RealismMatch!",
	version = PLUGIN_VERSION,
	url = "http://www.dodsourceplugins.net"
}

new Handle:SetupTime = INVALID_HANDLE
new Handle:AvASetupTime = INVALID_HANDLE
new Handle:AvARiflesOnly = INVALID_HANDLE
new Handle:LiveTime = INVALID_HANDLE
new Handle:DelayLiveCmd = INVALID_HANDLE
new Handle:PubChat = INVALID_HANDLE
new Handle:SpecBlackOut = INVALID_HANDLE
new Handle:SpecShowHUD = INVALID_HANDLE
new Handle:AllowRifleGrenPrime = INVALID_HANDLE
new Handle:DisableDeathMsgs = INVALID_HANDLE
new Handle:AllowObjectives = INVALID_HANDLE
new Handle:AllowDroppingAmmo = INVALID_HANDLE
new Handle:AllowDroppingGun = INVALID_HANDLE
new Handle:AllowTNTUsage = INVALID_HANDLE
new Handle:OnlyTeamPickup = INVALID_HANDLE
new Handle:AllowShooting = INVALID_HANDLE
new Handle:AllowVoiceCmds = INVALID_HANDLE
new Handle:AllowDamage = INVALID_HANDLE
new Handle:AttackerSpawnArea = INVALID_HANDLE
new Handle:LiveAFKKiller = INVALID_HANDLE
new Handle:AllowStuckCmd = INVALID_HANDLE
new Handle:GameTimer = INVALID_HANDLE
new g_PluginSwitched[MAXPLAYERS+1]
new bool:g_PrimedNade[MAXPLAYERS+1]
new g_PluginClass[MAXPLAYERS+1]
new g_PlayerTeam[MAXPLAYERS+1]
new Float:g_PlayerSpawnPos[MAXPLAYERS+1][3]
new Handle:AFKTimer[MAXPLAYERS+1] = INVALID_HANDLE
new g_Started = 0, g_Live = 0, g_RoundCount = 0, g_AVA = 0, g_Init = 0
new Float:g_StartTime = 0.0
new CPM = -1
new Score[2]
new g_MatchWinner, g_CmdsAvailable
new g_iAmmo, g_iClip1
new Float:g_LastStuck[MAXPLAYERS+1]
new Kills[MAXPLAYERS+1]
new Deaths[MAXPLAYERS+1]
new InitialTeam, InitMinPlayers
new String:ChangeToMap[256]
new g_AlliedLeader = 0, g_AxisLeader = 0

new OpTeam[4] =
{
	NOTEAM, SPEC, AXIS, ALLIES
}

new DefendingTeam[6] =
{
	NOTEAM, AXIS, ALLIES, AXIS, ALLIES, NOTEAM
}

new EndWinnerUnit[5] =
{
	-1, 0, 1, 1, 0
}

new RoundScoreTeam[6] =
{
	-1, AXIS, AXIS, ALLIES, ALLIES, AXIS
}

new String:AlliesDefendSnd[3][] =
{
	"player/american/startround/us_defense.wav",
	"player/american/startround/us_defense2.wav",
	"player/american/startround/us_defense3.wav"
}

new String:AlliesAttackSnd[3][] =
{
	"player/american/startround/us_flags.wav",
	"player/american/startround/us_flags3.wav",
	"player/american/startround/us_flags6.wav"
}

new String:AxisDefendSnd[3][] =
{
	"player/german/startround/ger_defense.wav",
	"player/german/startround/ger_defense2.wav",
	"player/german/startround/ger_defense3.wav"
}

new String:AxisAttackSnd[3][] =
{
	"player/german/startround/ger_flags.wav",
	"player/german/startround/ger_flags2.wav",
	"player/german/startround/ger_flags3.wav"
}

new String:ClassCmd[MAXCLASSES][] =
{
	"cls_garand", "cls_tommy", "cls_bar", "cls_spring", "cls_30cal", "cls_bazooka",
	"cls_k98", "cls_mp40", "cls_mp44", "cls_k98s", "cls_mg42", "cls_pschreck",
	"cls_random", "joinclass"
}

new String:g_Weapon[MAXWEAPONS][] =
{
	"weapon_colt", "weapon_p38", "weapon_m1carbine", "weapon_c96",
	"weapon_garand", "weapon_k98", "weapon_thompson", "weapon_mp40", "weapon_bar", "weapon_mp44",
	"weapon_spring", "weapon_k98_scoped", "weapon_30cal", "weapon_mg42", "weapon_bazooka", "weapon_pschreck",
	"weapon_riflegren_us", "weapon_riflegren_ger", "weapon_frag_us", "weapon_frag_ger", "weapon_smoke_us", "weapon_smoke_ger"
}

new String:WeaponPickup[4][] =
{
	"", "",
	"weapon_garand,weapon_thompson,weapon_bar,weapon_spring,weapon_30cal,weapon_bazooka",
	"weapon_k98,weapon_mp40,weapon_mp44,weapon_k98_scoped,weapon_mg42,weapon_pschreck"
}

new String:LiveRifleGren[4][] =
{
	"", "",
	"weapon_riflegren_us_live",
	"weapon_riflegren_ger_live"
}

new g_AmmoOffs[MAXWEAPONS] =
{
	4, 8, 24, 12, 16, 20, 32, 32, 36, 32, 28, 20, 40, 44, 48, 48, 84, 88, 52, 56, 68, 72
}

new String:VoiceCmd[MAXVOICECMDS][]=
{
	"voice_attack", "voice_hold", "voice_left", "voice_right", "voice_sticktogether",
	"voice_cover", "voice_usesmoke", "voice_usegrens", "voice_ceasefire", "voice_yessir",
	"voice_negative", "voice_backup", "voice_fireinhole", "voice_grenade", "voice_sniper",
	"voice_niceshot", "voice_thanks", "voice_areaclear", "voice_dropweapons", "voice_displace",
	"voice_mgahead", "voice_enemybehind", "voice_wegothim", "voice_moveupmg", "voice_needammo",
	"voice_usebazooka", "voice_bazookaspotted", "voice_gogogo", "voice_wtf", "voice_medic",
	"voice_fireleft", "voice_fireright", "voice_coverflanks", "voice_cover", "voice_fallback",
	"voice_movewithtank", "voice_takeammo", "voice_tank", "voice_enemyahead"
}

public OnPluginStart()
{
	CreateConVar("dod_realismmatch_helper", PLUGIN_VERSION, "DoD RealismMatch Helper Version (DO NOT CHANGE!)", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_realismmatch_helper"), PLUGIN_VERSION)
	SetupTime = CreateConVar("dod_rmhelper_setuptime", "5", "<#> = time in minutes for Setup", FCVAR_PLUGIN, true, 1.0, true, 15.0)
	PubChat = CreateConVar("dod_rmhelper_pubchat", "1", "<1/0> = enable/disable Public Chat", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	SpecBlackOut = CreateConVar("dod_rmhelper_specblackout", "0", "<1/2/0> = blacking out when spectating  -  1 = only enemies  -  2 = all players  -  0 = no blackout", FCVAR_PLUGIN, true, 0.0, true, 2.0)
	SpecShowHUD = CreateConVar("dod_rmhelper_specshowhud", "1", "<1/0> = enable/disable HUD when spectating", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	AllowShooting = CreateConVar("dod_rmhelper_allowshooting", "0", "<1/0> = enable/disable Shooting on Init/Start", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	AllowVoiceCmds = CreateConVar("dod_rmhelper_allowvcmds", "0", "<1/0> = enable/disable VoiceCommands on Init/Start", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	AllowObjectives = CreateConVar("dod_rmhelper_allowobjectives", "0", "<1/0> = allow/disallow CaptureAreas and ControlPoints to be active", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	AllowTNTUsage = CreateConVar("dod_rmhelper_allowtntusage", "0", "<1/0> = allow/disallow using TNT to bomb obstacles", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	AllowDroppingAmmo = CreateConVar("dod_rmhelper_allowammodrop", "0", "<1/0> = allow/disallow dropping Ammo before live", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	AllowDroppingGun = CreateConVar("dod_rmhelper_allowgundrop", "0", "<1/0> = allow/disallow dropping your Gun before live", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	DisableDeathMsgs = CreateConVar("dod_rmhelper_disabledeathmsgs", "0", "<1/0> = disable/enable displaying Death Messages", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	AllowDamage = CreateConVar("dod_rmhelper_allowdamage", "0", "<1/0> = enable/disable taking Damage on Init/Start", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	OnlyTeamPickup = CreateConVar("dod_rmhelper_teampickupsonly", "0", "<1/0> = enable/disable only allowing team pickups", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	AllowRifleGrenPrime = CreateConVar("dod_rmhelper_allowriflegrenprime", "0", "<1/0> = enable/disable allowing rifle grenades to be primed", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	AttackerSpawnArea = CreateConVar("dod_rmhelper_spawnarea", "1500", "<#> = size of the SpawnArea that Attackers cannot leave", FCVAR_PLUGIN, true, 500.0, true, 2000.0)
	AvASetupTime = CreateConVar("dod_rmhelper_avasetuptime", "10", "<#> = time in seconds for Attackers vs Attackers Setup", FCVAR_PLUGIN, true, 1.0, true, 30.0)
	LiveAFKKiller = CreateConVar("dod_rmhelper_liveafkkiller", "30", "<#/0> = time in seconds after that AFKs are killed after live!  -  0 = disable", FCVAR_PLUGIN, true, 0.0, true, 120.0)
	DelayLiveCmd = CreateConVar("dod_rmhelper_delaylivecmd", "60", "<#/0> = time in seconds after that the round can be lived!  -  0 = no delay", FCVAR_PLUGIN, true, 0.0, true, 300.0)
	AvARiflesOnly = CreateConVar("dod_rmhelper_avariflesonly", "1", "<1/0> = enable/disable Rifles ONLY on AvA", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	AllowStuckCmd = CreateConVar("dod_rmhelper_allowstuckcmd", "0", "<1/0> = allow/disallow using the !stuck command", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	LiveTime = CreateConVar("dod_rmhelper_livetime", "15", "<#> = time in minutes for live round", FCVAR_PLUGIN, true, 1.0, true, 30.0)
	HookEvent("player_team", OnJoinTeam, EventHookMode_Pre)
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre)
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
	HookEventEx("dod_round_active", RoundActive, EventHookMode_Post)
	HookEventEx("dod_round_start", RoundStart, EventHookMode_Post)
	AddNormalSoundHook(NormalSHook:BlockStartVoice)
	for(new i = 0; i < MAXCLASSES; i++)
	{
		RegAdminCmd(ClassCmd[i], cmd_ClassSelect, 0)
	}
	for(new i = 0; i < MAXVOICECMDS; i++)
	{
		RegConsoleCmd(VoiceCmd[i], cmd_voice)
	}
	RegAdminCmd("say", cmd_say, 0)
	RegAdminCmd("drop", cmd_drop, 0)
	RegAdminCmd("dropammo", cmd_dropammo, 0)
	RegAdminCmd("kill", cmd_kill, 0)
	RegAdminCmd("explode", cmd_kill, 0)
	RegAdminCmd("jointeam", cmd_jointeam, 0)
	RegAdminCmd("sm_init", cmdInit, ADMFLAG_KICK)
	RegAdminCmd("sm_start", cmdStart, ADMFLAG_KICK)
	RegAdminCmd("sm_cancel", cmdCancel, ADMFLAG_KICK)
	RegAdminCmd("sm_replay", cmdReplay, ADMFLAG_KICK)
	RegAdminCmd("sm_suicide", cmdSuicide, 0)
	RegAdminCmd("sm_stuck", cmdStuck, 0)
	RegAdminCmd("sm_dq", cmdDq, ADMFLAG_KICK, "<team> = disqualify team (allies/axis)")
	RegAdminCmd("sm_pubchat", cmdPubChat, ADMFLAG_KICK, "<choice> = enable/disable PublicChat (on/off)")
	RegAdminCmd("sm_live", cmdLive, 0)
	RegAdminCmd("sm_info", cmdInfo, 0)
	AutoExecConfig(true,"dod_realismmatch_helper", "dod_realismmatch_helper")
}

public Action:BlockStartVoice(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(g_Init == 0 && g_Started == 0)
	{
		return Plugin_Continue
	}
	if((g_Started == 1 || g_Init == 1) && g_Live == 0 && StrContains(sample, "player") != -1 && (StrContains(sample, "american") != -1 || StrContains(sample, "german") != -1) && StrContains(sample, "startround") != -1)
	{
		return Plugin_Stop
	}
	return Plugin_Continue
}

public OnMapStart()
{
	g_Init = 0
	g_CmdsAvailable = 0
	g_AlliedLeader = 0
	g_AxisLeader = 0
	if(FileExists(MATCHCFG, true))
	{
		new Handle:KeyValues = CreateKeyValues("RealismMatchConfig")
		FileToKeyValues(KeyValues, MATCHCFG)
		if(KvJumpToKey(KeyValues, "TeamSetup"))
		{
			InitialTeam = KvGetNum(KeyValues, "InitialTeam", ALLIES)
			DefendingTeam[1] = KvGetNum(KeyValues, "DefenderRound1", AXIS)
			DefendingTeam[2] = KvGetNum(KeyValues, "DefenderRound2", ALLIES)
			DefendingTeam[3] = KvGetNum(KeyValues, "DefenderRound3", AXIS)
			DefendingTeam[4] = KvGetNum(KeyValues, "DefenderRound4", ALLIES)
		}
		KvRewind(KeyValues)
		if(KvJumpToKey(KeyValues, "MatchSetup"))
		{
			InitMinPlayers = KvGetNum(KeyValues, "InitMinPlayers", 0)
			g_Init = KvGetNum(KeyValues, "MapStartAutoOn", 0)
		}
		KvRewind(KeyValues)
		if(KvJumpToKey(KeyValues, "CancelSetup"))
		{
			KvGetString(KeyValues, "ChangeToMap", ChangeToMap, sizeof(ChangeToMap))
		}
		CloseHandle(KeyValues)
		EndWinnerUnit[1] = DefendingTeam[1] == AXIS ? 0 : 1
		EndWinnerUnit[2] = DefendingTeam[2] == ALLIES ? 1 : 0
		EndWinnerUnit[3] = DefendingTeam[3] == AXIS ? 1 : 0
		EndWinnerUnit[4] = DefendingTeam[4] == ALLIES ? 0 : 1
	}
	ResetRealism()
	for(new i = 0; i < 3; i++)
	{
		PrecacheSound(AlliesDefendSnd[i], true)
		PrecacheSound(AlliesAttackSnd[i], true)
		PrecacheSound(AxisDefendSnd[i], true)
		PrecacheSound(AxisAttackSnd[i], true)
	}
	g_iAmmo = FindSendPropOffs("CDODPlayer", "m_iAmmo")
	g_iClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1")
}

public OnPreThink(client)
{
	if(g_Init == 1 || (g_Started == 1 && g_Live == 0))
	{
		if(IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > SPEC)
		{
			if(DefendingTeam[g_RoundCount] != GetClientTeam(client) && g_Init == 0 && g_Started == 1 && g_Live == 0)
			{
				decl Float:CurrentPos[3]
				GetClientAbsOrigin(client, CurrentPos)
				if(GetVectorDistance(CurrentPos, g_PlayerSpawnPos[client]) > GetConVarInt(AttackerSpawnArea))
				{
					TeleportEntity(client, g_PlayerSpawnPos[client], NULL_VECTOR, NULL_VECTOR)
					PrintHintText(client, "You are ATTACKING this Round!\n\nPlease stay in your SpawnArea\nand ONLY move out on LIVE!")
				}
			}
			if(GetConVarInt(AllowShooting) == 0)
			{
				SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+0.5)
			}
		}
	}
	else if(g_Live == 1)
	{
		new blindspec = GetConVarInt(SpecBlackOut)
		new teampickup = GetConVarInt(OnlyTeamPickup)
		new riflegrenprime = GetConVarInt(AllowRifleGrenPrime)
		if(blindspec == 1 || teampickup == 1 || riflegrenprime == 0)
		{
			if(IsClientInGame(client))
			{
				new currteam = GetClientTeam(client)
				if(!IsPlayerAlive(client) && currteam == SPEC && blindspec == 1)
				{
					new mode = GetEntProp(client, Prop_Send, "m_iObserverMode")
					if(mode != 4 && mode != 5)
					{
						SetEntProp(client, Prop_Send, "m_iObserverMode", 4)
					}
					new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget")
					if(target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target))
					{
						if(GetClientTeam(target) != g_PlayerTeam[client])
						{
							ClientCommand(client, "r_screenoverlay %s", BLINDOVERLAY)
						}
						else
						{
							ClientCommand(client, "r_screenoverlay 0")
						}
					}
					else
					{
						ClientCommand(client, "r_screenoverlay %s", BLINDOVERLAY)
					}
				}
				else if(IsPlayerAlive(client) && currteam > SPEC && (teampickup == 1 || riflegrenprime == 0))
				{
					decl String:CurrWeapon[32]
					GetClientWeapon(client, CurrWeapon, sizeof(CurrWeapon))
					if(teampickup == 1)
					{
						if(StrContains(WeaponPickup[OpTeam[currteam]], CurrWeapon, true) != -1)
						{
							FakeClientCommandEx(client, "drop")
						}
					}
					if(riflegrenprime == 0)
					{
						if(StrEqual(CurrWeapon, LiveRifleGren[currteam], true))
						{
							SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+0.5)
							g_PrimedNade[client] = true
						}
					}
				}
			}
		}
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if((g_Init == 1 || (g_Started == 1 && g_Live ==0)) && GetConVarInt(AllowDamage) == 0)
	{
		damage *= 0.0
		return Plugin_Changed
	}
	if(g_Live == 1 && GetConVarInt(AllowRifleGrenPrime) == 0 && IsClientInGame(attacker) && IsClientInGame(victim))
	{
		decl String:WeaponName[32]
		if(GetEdictClassname(inflictor, WeaponName, sizeof(WeaponName)))
		{
			if((StrEqual(WeaponName, "grenade_riflegren_ger") && g_PlayerTeam[attacker] == AXIS && g_PrimedNade[attacker]) || (StrEqual(WeaponName, "grenade_riflegren_us") && g_PlayerTeam[attacker] == ALLIES && g_PrimedNade[attacker]))
			damage *= 0.0
			return Plugin_Changed
		}
	}
	return Plugin_Continue
}

stock ResetRealism()
{
	g_Live = 0
	g_Started = 0
	g_StartTime = 0.0
	g_RoundCount = 0
	g_AVA = 0
	g_MatchWinner = 0
	Score[0] = Score[1] = 0
}

public Action:cmd_dropammo(client, args)
{
	if(g_Init == 1 || (g_Started == 1 && g_Live == 0 && GetConVarInt(AllowDroppingAmmo) == 0))
	{
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:cmd_drop(client, args)
{
	if(g_Init == 1 || (g_Started == 1 && g_Live == 0 && GetConVarInt(AllowDroppingGun) == 0))
	{
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:cmd_voice(client, args)
{
	if((g_Init == 1 || (g_Started == 1 && g_Live == 0)) && GetConVarInt(AllowVoiceCmds) == 0)
	{
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:cmd_say(client, args)
{
	new AdminId:Admin = GetUserAdmin(client)
	if(g_Started == 1 && (Admin == INVALID_ADMIN_ID || !GetAdminFlag(Admin, Admin_Kick, Access_Effective)) && GetConVarInt(PubChat) == 0)
	{
		decl String:ChatText[256]
		GetCmdArg(1, ChatText, sizeof(ChatText))
		if(StrEqual(ChatText, "!medic") || StrEqual(ChatText, "!info") || StrEqual(ChatText, "!live") || StrEqual(ChatText, "!stuck") || StrEqual(ChatText, "!suicide") || StrEqual(ChatText, "*Salute*", false))
		{
			return Plugin_Continue
		}
		PrintToChat(client, "\x04Sorry, \x01Global Chat \x04is \x01DISABLED \x04!")
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:cmd_kill(client, args)
{
	if(g_Init == 1 || g_Started == 1)
	{
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:cmdSuicide(client, args)
{
	if(g_Started == 1 && IsPlayerAlive(client))
	{
		KillPlayer(client)
	}
	return Plugin_Handled
}

public Action:cmdStuck(client, args)
{
	if(g_Started == 1 && IsPlayerAlive(client) && GetGameTime() > g_LastStuck[client] + 3.0 && GetConVarInt(AllowStuckCmd) == 1)
	{
		g_LastStuck[client] = GetGameTime()
		SlapPlayer(client, 0, true)
	}
	return Plugin_Handled
}

public Action:cmdInfo(client, args)
{
	new team = g_PlayerTeam[client]
	if(g_Init == 0 && (g_Started == 1 || g_Live == 1) && team > SPEC)
	{
		PrintToChat(client, "\x04Round \x01%i  \x04-  You are \x01%s \x04this round!", g_RoundCount, DefendingTeam[g_RoundCount] == team ? "DEFENDING" : "ATTACKING")
		PrintToChat(client, "\x01Scores: \x04Your Team \x01%i\x04:\x01%i \x04Enemy Team", RoundScoreTeam[g_RoundCount] == team ? Score[0] : Score[1], RoundScoreTeam[g_RoundCount] != team ? Score[0] : Score[1])
	}
	return Plugin_Handled
}

public Action:cmd_ClassSelect(client, args)
{
	new team = GetClientTeam(client)
	if(team == SPEC || team == NOTEAM || g_PluginClass[client] == 1 || !IsPlayerAlive(client))
	{
		g_PluginClass[client] = 0
		return Plugin_Continue
	}
	if(g_Live == 1)
	{
		return Plugin_Handled
	}
	decl String:cls_cmd[13]
	GetCmdArg(0,cls_cmd,sizeof(cls_cmd))
	if(!StrEqual(cls_cmd, "cls_garand") && !StrEqual(cls_cmd, "cls_k98") && ((g_AVA == 1 && GetConVarInt(AvARiflesOnly) == 1) || g_Init == 1))
	{
		return Plugin_Handled
	}
	if(g_Started == 1 && g_Live == 0 && g_Init == 0)
	{
		new class = -1
		for(new chosenclass = 0; chosenclass < MAXCLASSES; chosenclass++)
		{
			if(StrEqual(cls_cmd, ClassCmd[chosenclass]))
			{
				class = chosenclass
				break
			}
		}
		if(class == 12 || class == 13 || class == -1)
		{
			return Plugin_Handled
		}
		if(team == AXIS)
		{
			class -= 6
		}
		new currclass = GetEntProp(client, Prop_Send, "m_iPlayerClass")
		if(currclass == class)
		{
			return Plugin_Handled
		}
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", class)
		for(new slot = 0; slot < 5; slot++)
		{
			new Weapon = GetPlayerWeaponSlot(client, slot)
			if(Weapon != -1)
			{
				decl String:WeaponName[32]
				if(GetEdictClassname(Weapon, WeaponName, sizeof(WeaponName)))
				{
					for(new weap = 0; weap < MAXWEAPONS; weap++)
					{
						if(StrEqual(WeaponName, g_Weapon[weap]))
						{
							SetEntData(client, g_iAmmo + g_AmmoOffs[weap], 0)
							if(weap < 19)
							{
								SetEntData(Weapon, g_iClip1, 0)
							}
						}
					}
					RemovePlayerItem(client, Weapon)
					RemoveEdict(Weapon)
				}
			}
		}
		new Float:CurrentPos[3], Float:CurrentAngles[3]
		GetClientAbsOrigin(client, CurrentPos)
		GetClientAbsAngles(client, CurrentAngles)
		if(DispatchSpawn(client))
		{
			TeleportEntity(client, CurrentPos, CurrentAngles, NULL_VECTOR)
		}
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_CmdsAvailable = 0
	return Plugin_Continue
}

public Action:RoundActive(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_StartTime = GetGameTime()
	g_CmdsAvailable = 1
	if(g_Started == 1 && g_Live == 0)
	{
		g_RoundCount++
		g_Init = 0
		if(g_RoundCount == 5 && g_AVA == 1)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i))
				{
					g_PrimedNade[i] = false
					new team = GetClientTeam(i)
					if(team > SPEC)
					{
						PrintHintText(i, "Round 5\n\nBoth Teams are ATTACKING this round!\nScores: Your Team %i:%i Enemy Team", RoundScoreTeam[g_RoundCount] == team ? Score[0] : Score[1], RoundScoreTeam[g_RoundCount] != team ? Score[0] : Score[1])
						PrintToChat(i, "\x04Round \x015  \x04-  Both Teams are \x01ATTACKING \x04this round!")
						PrintToChat(i, "\x01Scores: \x04Your Team \x01%i\x04:\x01%i \x04Enemy Team", RoundScoreTeam[g_RoundCount] == team ? Score[0] : Score[1], RoundScoreTeam[g_RoundCount] != team ? Score[0] : Score[1])
					}
				}
			}
			SetPlayerMovement(0.0)
			new Float:warmuptimer = GetConVarFloat(AvASetupTime)
			GameTimer = CreateTimer(warmuptimer, TimerLive, _, TIMER_FLAG_NO_MAPCHANGE)
			return Plugin_Continue
		}
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				g_PrimedNade[i] = false
				new team = GetClientTeam(i)
				if(team > SPEC)
				{
					PrintHintText(i, "Round %i\n\nYou are %s this round!\nScores: Your Team %i:%i Enemy Team", g_RoundCount, DefendingTeam[g_RoundCount] == team ? "DEFENDING" : "ATTACKING", RoundScoreTeam[g_RoundCount] == team ? Score[0] : Score[1], RoundScoreTeam[g_RoundCount] != team ? Score[0] : Score[1])
					PrintToChat(i, "\x04Round \x01%i  \x04-  You are \x01%s \x04this round!", g_RoundCount, DefendingTeam[g_RoundCount] == team ? "DEFENDING" : "ATTACKING")
					PrintToChat(i, "\x01Scores: \x04Your Team \x01%i\x04:\x01%i \x04Enemy Team", RoundScoreTeam[g_RoundCount] == team ? Score[0] : Score[1], RoundScoreTeam[g_RoundCount] != team ? Score[0] : Score[1])
				}
			}
		}
		new Float:warmuptimer = (GetConVarFloat(SetupTime)*60.0)
		GameTimer = CreateTimer(warmuptimer, TimerLive, _, TIMER_FLAG_NO_MAPCHANGE)
	}
	return Plugin_Continue
}

stock SetPlayerMovement(Float:speed)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", speed)
		}
	}
}

public Action:cmd_jointeam(client, args)
{
	decl String:teamnumber[2]
	GetCmdArg(1,teamnumber,2)
	new team = StringToInt(teamnumber)
	new currteam = GetClientTeam(client)
	if((team == ALLIES || team == AXIS || team == NOTEAM) && g_Live == 1)
	{
		if(currteam == NOTEAM)
		{
			FakeClientCommandEx(client, "jointeam %i", SPEC)
		}
		if(team != SPEC && GetConVarInt(SpecBlackOut) != 2)
		{
			PrintHintText(client, "Match is LIVE, you CANNOT join/change a team!")
		}
		CreateTimer(0.1, HideHud, client, TIMER_FLAG_NO_MAPCHANGE)
		return Plugin_Handled
	}
	if(team == SPEC && g_Live == 1)
	{
		if(GetConVarInt(SpecBlackOut) == 2)
		{
			ClientCommand(client, "r_screenoverlay Effects/tp_eyefx/tp_black")
		}
		CreateTimer(0.1, HideHud, client, TIMER_FLAG_NO_MAPCHANGE)
		return Plugin_Continue
	}
	if((team == ALLIES || team == AXIS) && g_Live == 0 && (g_Init == 1 || g_Started == 1))
	{
		if(currteam != SPEC && currteam != NOTEAM)
		{
			g_PluginSwitched[client] = 1
			ChangeClientTeam(client, SPEC)
		}
		if(g_Init == 1 && team == ALLIES && currteam == NOTEAM)
		{
			team = AXIS
		}
		ChangeClientTeam(client, team)
		ShowVGUIPanel(client, team == AXIS ? "class_ger" : "class_us", INVALID_HANDLE, false)
		g_PluginClass[client] = 1
		FakeClientCommand(client, "%s", team == AXIS ? "cls_k98" : "cls_garand")
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:HideHud(Handle:Timer, any:client)
{
	if(IsClientInGame(client) && (GetClientTeam(client) == SPEC || GetClientTeam(client) == NOTEAM))
	{
		if(GetConVarInt(SpecShowHUD) == 0)
		{
			new hudflags = GetEntProp(client, Prop_Send, "m_iHideHUD")
			hudflags |= HIDEHUD_ALL
			SetEntProp(client, Prop_Send, "m_iHideHUD", hudflags)
		}
		if(GetConVarInt(SpecBlackOut) == 2)
		{
			ClientCommand(client, "r_screenoverlay Effects/tp_eyefx/tp_black")
		}
	}
	return Plugin_Handled
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PreThink, OnPreThink)
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage)
	g_PluginClass[client] = 0
	g_PluginSwitched[client] = 0
	g_LastStuck[client] = 0.0
	if(AFKTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(AFKTimer[client])
	}
	AFKTimer[client] = INVALID_HANDLE
	Kills[client] = 0
	Deaths[client] = 0
	g_PrimedNade[client] = false
	if(g_Live == 1)
	{
		CreateTimer(0.1, HideHud, client, TIMER_FLAG_NO_MAPCHANGE)
	}
}

public OnClientDisconnect(client)
{
	g_PluginClass[client] = 0
	g_PluginSwitched[client] = 0
	g_LastStuck[client] = 0.0
	if(AFKTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(AFKTimer[client])
	}
	AFKTimer[client] = INVALID_HANDLE
	Kills[client] = 0
	Deaths[client] = 0
	g_PrimedNade[client] = false
	if(client == g_AlliedLeader)
	{
		g_AlliedLeader = 0
	}
	if(client == g_AxisLeader)
	{
		g_AxisLeader = 0
	}
	if(g_Live == 1)
	{
		CreateTimer(1.0, SoldierDown, client, TIMER_FLAG_NO_MAPCHANGE)
	}
}

public Action:cmdInit(client, args)
{
	if(g_CmdsAvailable != 0)
	{
		if(g_Started == 1 || g_Init == 1)
		{
			if(GameTimer != INVALID_HANDLE)
			{
				CloseHandle(GameTimer)
				GameTimer = INVALID_HANDLE
			}
			ResetRealism()
			PrintHintTextToAll("RESTARTING Realism!")
			PrintToChatAll("\x01RESTARTING \x04Realism \x01!")
		}
		if((GetTeamClientCount(ALLIES) + GetTeamClientCount(AXIS)) < InitMinPlayers)
		{
			ReplyToCommand(client, "Sorry, at least %i active players needed to init a realism!", InitMinPlayers)
			return Plugin_Handled
		}
		AllPlayersInit()
	}
	else
	{
		ReplyToCommand(client, "Please try again once the current round is active!")
	}
	return Plugin_Handled
}

public Action:cmdStart(client, args)
{
	if(g_Started == 0 && g_Live == 0 && g_Init == 1)
	{
		if(g_CmdsAvailable != 0)
		{
			g_AlliedLeader = 0
			g_AxisLeader = 0
			SelectAlliedLeader(client)
		}
		else
		{
			ReplyToCommand(client, "Please try again once the current round is active!")
		}
		return Plugin_Handled
	}
	return Plugin_Handled
}

RealismStartNow()
{
	ServerCommand("exec %s", STARTCFG)
	g_Started = 1
	g_Init = 0
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Deaths[i] = 0
			Kills[i] = 0
		}
	}
	AllPlayersStart()
}

public Action:SelectAlliedLeader(client)
{
	new Handle:AlliedLeaderMenu = CreateMenu(Handle_AlliedLeaderMenu)
	decl String:menutitle[256]
	Format(menutitle, sizeof(menutitle), "Select Allied Team Leader!")
	SetMenuTitle(AlliedLeaderMenu, menutitle)
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			new currteam = GetClientTeam(i)
			if(currteam == ALLIES)
			{
				decl String:TargetName[32]
				GetClientName(i, TargetName, sizeof(TargetName))
				new userid = GetClientUserId(i)
				decl String:userid_str[32]
				IntToString(userid, userid_str, sizeof(userid_str))
				AddMenuItem(AlliedLeaderMenu, userid_str, TargetName)
			}
		}
	}
	SetMenuExitButton(AlliedLeaderMenu, true)
	SetMenuExitBackButton(AlliedLeaderMenu, false)
	DisplayMenu(AlliedLeaderMenu, client, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Handle_AlliedLeaderMenu(Handle:AlliedLeaderMenu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		new String:userid[MAX_TARGET_LENGTH]
		GetMenuItem(AlliedLeaderMenu, itemNum, userid, sizeof(userid))
		new target = GetClientOfUserId(StringToInt(userid))
		g_AlliedLeader = target
		PrintToChat(client, "\x01Player \x04%N \x01has been choosen as \x04Allied Team Leader\x01!", target)
		SelectAxisLeader(client)
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_Exit)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}
			g_AlliedLeader = 0
			PrintToChat(client, "\x01Realism will \x04NOT \x01be started until you choose the Team Leaders!")
		}
	}
}

public Action:SelectAxisLeader(client)
{
	new Handle:AxisLeaderMenu = CreateMenu(Handle_AxisLeaderMenu)
	decl String:menutitle[256]
	Format(menutitle, sizeof(menutitle), "Select Axis Team Leader!")
	SetMenuTitle(AxisLeaderMenu, menutitle)
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			new currteam = GetClientTeam(i)
			if(currteam == AXIS)
			{
				decl String:TargetName[32]
				GetClientName(i, TargetName, sizeof(TargetName))
				new userid = GetClientUserId(i)
				decl String:userid_str[32]
				IntToString(userid, userid_str, sizeof(userid_str))
				AddMenuItem(AxisLeaderMenu, userid_str, TargetName)
			}
		}
	}
	SetMenuExitButton(AxisLeaderMenu, true)
	SetMenuExitBackButton(AxisLeaderMenu, true)
	DisplayMenu(AxisLeaderMenu, client, MENU_TIME_FOREVER)
	return Plugin_Handled
}

public Handle_AxisLeaderMenu(Handle:AxisLeaderMenu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		new String:userid[MAX_TARGET_LENGTH]
		GetMenuItem(AxisLeaderMenu, itemNum, userid, sizeof(userid))
		new target = GetClientOfUserId(StringToInt(userid))
		g_AxisLeader = target
		PrintToChat(client, "\x01Player \x04%N \x01has been choosen as \x04Axis Team Leader\x01!", target)
		ConfirmLeaders(client)
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_ExitBack)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}
			g_AlliedLeader = 0
			SelectAlliedLeader(client)
		}
		else if(itemNum == MenuCancel_Exit)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}
			g_AxisLeader = 0
			PrintToChat(client, "\x01Realism will \x04NOT \x01be started until you choose the Team Leaders!")
		}
	}
}

public Action:ConfirmLeaders(client)
{
	new Handle:ConfirmLeadersMenu = CreateMenu(Handle_ConfirmLeadersMenu)
	decl String:menutitle[256]
	Format(menutitle, sizeof(menutitle), "Confirm Team Leaders and start Realism!\n \nAllied Leader: %N\nAxis Leader: %N\n ", g_AlliedLeader, g_AxisLeader)
	SetMenuTitle(ConfirmLeadersMenu, menutitle)
	decl String:Selection[256]
	Format(Selection, sizeof(Selection), "Start Realism!!")
	AddMenuItem(ConfirmLeadersMenu, "rmh_Start", Selection, ITEMDRAW_DEFAULT)
	Format(Selection, sizeof(Selection), "Change Team Leaders!")
	AddMenuItem(ConfirmLeadersMenu, "rmh_Change", Selection, ITEMDRAW_DEFAULT)
	SetMenuExitButton(ConfirmLeadersMenu, true)
	SetMenuExitBackButton(ConfirmLeadersMenu, false)
	DisplayMenu(ConfirmLeadersMenu, client, MENU_TIME_FOREVER)
}

public Handle_ConfirmLeadersMenu(Handle:ConfirmLeadersMenu, MenuAction:action, client, itemNum)
{
	if(action == MenuAction_Select)
	{
		decl String:menuchoice[256]
		GetMenuItem(ConfirmLeadersMenu, itemNum, menuchoice, sizeof(menuchoice))
		if(strcmp(menuchoice, "rmh_Start", true) == 0)
		{
			PrintToChatAll("\x01Starting Realism!")
			PrintToChatAll("\x04Allied Leader: %N  \x01-  \x04Axis Leader: %N", g_AlliedLeader, g_AxisLeader)
			RealismStartNow()
		}
		else if(strcmp(menuchoice, "rmh_Change", true) == 0)
		{
			g_AlliedLeader = 0
			g_AxisLeader = 0
			SelectAlliedLeader(client)
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(itemNum == MenuCancel_Exit)
		{
			if(GetClientMenu(client))
			{
				CancelClientMenu(client)
			}
			g_AlliedLeader = 0
			g_AxisLeader = 0
			PrintToChat(client, "\x01Realism will \x04NOT \x01be started until you choose the Team Leaders!")
		}
	}
}

public Action:cmdLive(client, args)
{
	if(g_Started == 1 && g_Live == 0 && g_RoundCount != 5)
	{
		if(g_CmdsAvailable != 0)
		{
			new plteam = GetClientTeam(client)
			if(plteam != DefendingTeam[g_RoundCount])
			{
				PrintToChat(client, "\x04Sorry, \x01ONLY \x04the DEFENDING team can call 'live'!")
				return Plugin_Handled
			}
			if((DefendingTeam[g_RoundCount] == ALLIES && plteam == ALLIES && g_AlliedLeader != 0 && client != g_AlliedLeader) || (DefendingTeam[g_RoundCount] == AXIS && plteam == AXIS && g_AxisLeader != 0 && client != g_AxisLeader))
			{
				PrintToChat(client, "\x04Sorry, \x01ONLY \x04the Team Leader can call 'live'!")
				return Plugin_Handled
			}
			new Float:GameTime = GetGameTime()
			if(GameTime < g_StartTime + GetConVarFloat(DelayLiveCmd))
			{
				PrintToChat(client, "\x04Sorry, you \x01CANNOT \x04call 'live' before at least \x01%isec of setup time \x04have passed!", GetConVarInt(DelayLiveCmd))
				return Plugin_Handled
			}
			if(GameTimer != INVALID_HANDLE)
			{
				if(CloseHandle(GameTimer))
				{
					GameTimer = INVALID_HANDLE
				}
			}
			HandleRoundLive()
			PrintToChatAll("\x01Player \x04%N \x01has lived the round!", client)
		}
		else
		{
			ReplyToCommand(client, "Please try again once the current round is active!")
		}
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:cmdReplay(client, args)
{
	if(g_Live == 1)
	{
		g_Live = 0
		if(GameTimer != INVALID_HANDLE)
		{
			CloseHandle(GameTimer)
			GameTimer = INVALID_HANDLE
		}
		AllPlayersPrevTeam()
		PrintHintTextToAll("Round %i will be REPLAYED now!", g_RoundCount)
		PrintToChatAll("\x04Round \x01%i \x04will be \x01REPLAYED \x04now!", g_RoundCount)
		g_RoundCount--
	}
	return Plugin_Handled
}

public Action:cmdDq(client, args)
{
	if(g_Live == 1)
	{
		decl String:dqteam[7]
		GetCmdArg(1, dqteam, 7)
		if(StrEqual(dqteam, "allies", false))
		{
			if(g_RoundCount == 1 || g_RoundCount == 2 || g_RoundCount == 5)
			{
				Score[0]++
			}
			else
			{
				Score[1]++
			}
			PrintHintTextToAll("Round is over! Allies have been disqualified!")
			PrintToChatAll("\x04Round is over! \x01Allies \x04have been disqualified!")
		}
		else if(StrEqual(dqteam, "axis", false))
		{
			if(g_RoundCount == 1 || g_RoundCount == 2 || g_RoundCount == 5)
			{
				Score[1]++
			}
			else
			{
				Score[0]++
			}
			PrintHintTextToAll("Round is over! Axis have been disqualified!")
			PrintToChatAll("\x04Round is over! \x01Axis \x04have been disqualified!")
		}
		else
		{
			ReplyToCommand(client, "Usage: 'say !dq <team>' to disqualify (allies/axis)")
			return Plugin_Handled
		}
		g_Live = 0
		g_AVA = 0
		if(GameTimer != INVALID_HANDLE)
		{
			CloseHandle(GameTimer)
			GameTimer = INVALID_HANDLE
		}
		HandleRoundEnd()
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:cmdPubChat(client, args)
{
	if(g_Live == 1 || g_Started == 1)
	{
		decl String:onoff[4]
		GetCmdArg(1, onoff, 4)
		if(StrEqual(onoff, "on", false))
		{
			if(GetConVarInt(PubChat) == 1)
			{
				PrintToChatAll("\x04Global Chat is \x01already ENABLED \x04!")
			}
			else
			{
				SetConVarInt(PubChat, 1)
				PrintToChatAll("\x04Global Chat has been \x01ENABLED \x04!")
			}
			return Plugin_Handled
		}
		else if(StrEqual(onoff, "off", false))
		{
			if(GetConVarInt(PubChat) == 0)
			{
				PrintToChatAll("\x04Global Chat is \x01already DISABLED \x04!")
			}
			else
			{
				SetConVarInt(PubChat, 0)
				PrintToChatAll("\x04Global Chat has been \x01DISABLED \x04!")
			}
			return Plugin_Handled
		}
		else
		{
			return Plugin_Handled
		}
	}
	return Plugin_Handled
}

stock ZeroTimerWarmup()
{
	new Float:time = (GetConVarFloat(SetupTime)*60) - (GetGameTime() - g_StartTime)
	decl String:timestr[12]
	FloatToString(time, timestr, sizeof(timestr))
	Format(timestr, sizeof(timestr), "-%s", timestr)
	SetVariantString(timestr)
	AcceptEntityInput(CPM, "AddTimerSeconds")
}

stock StartLiveTimer()
{
	new Float:time = GetConVarFloat(LiveTime) * 60
	decl String:timestr[12]
	FloatToString(time, timestr, sizeof(timestr))
	Format(timestr, sizeof(timestr), "+%s", timestr)
	SetVariantString(timestr)
	AcceptEntityInput(CPM, "AddTimerSeconds")
}

public Action:cmdCancel(client, args)
{
	if(g_Started == 1 || g_Live == 1 || g_Init == 1)
	{
		ServerCommand("exec %s", CANCELCFG)
		if(GameTimer != INVALID_HANDLE)
		{
			CloseHandle(GameTimer)
			GameTimer = INVALID_HANDLE
		}
		decl String:CurrentMap[256]
		GetCurrentMap(CurrentMap, sizeof(CurrentMap))
		if(!IsMapValid(ChangeToMap))
		{
			strcopy(ChangeToMap, sizeof(ChangeToMap), CurrentMap)
		}
		if(StrEqual(CurrentMap, ChangeToMap, true))
		{
			PrintHintTextToAll("Sorry, Realism has been CANCELED!\nRestarting Map %s!", ChangeToMap)
			PrintToChatAll("\x04Sorry, Realism has been \x01CANCELED \x04! Restarting Map %s", ChangeToMap)
		}
		else
		{
			PrintHintTextToAll("Sorry, Realism has been CANCELED!\nChanging to Map %s!", ChangeToMap)
			PrintToChatAll("\x04Sorry, Realism has been \x01CANCELED \x04! Changing to Map %s", ChangeToMap)
		}
		CreateTimer(5.0, ChangeLevel, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE)
		return Plugin_Handled
	}
	return Plugin_Handled
}

public Action:ChangeLevel(Handle:timer)
{
	ServerCommand("changelevel %s", ChangeToMap)
	return Plugin_Handled
}

public Action:TimerEnd(Handle:timer)
{
	g_Live = 0
	g_AVA = 0
	PrintHintTextToAll("Round is over! %s have won!", DefendingTeam[g_RoundCount] == AXIS ? "Axis" : "Allies")
	PrintToChatAll("\x04Round is over! \x01%s \x04have won!", DefendingTeam[g_RoundCount] == AXIS ? "Axis" : "Allies")
	Score[EndWinnerUnit[g_RoundCount]]++
	GameTimer = INVALID_HANDLE
	HandleRoundEnd()
	return Plugin_Handled
}

public Action:TimerLive(Handle:timer)
{
	if(g_Started == 1 && g_Live == 0)
	{
		HandleRoundLive()
	}
	return Plugin_Handled
}

public Action:HandleRoundLive()
{
	g_Live = 1
	new LiveAFKTime = GetConVarInt(LiveAFKKiller)
	PrintHintTextToAll("Round is LIVE!!!")
	PrintToChatAll("\x04Round is \x01LIVE\x04!!!")
	if(g_RoundCount == 5 && g_AVA == 1)
	{
		SetPlayerMovement(1.0)
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				new team = GetClientTeam(i)
				if(team == AXIS)
				{
					EmitSoundToClient(i, AxisAttackSnd[GetRandomInt(0, 2)])
				}
				else if(team == ALLIES)
				{
					EmitSoundToClient(i, AlliesAttackSnd[GetRandomInt(0, 2)])
				}
				if(LiveAFKTime > 0)
				{
					AFKTimer[i] = CreateTimer(float(LiveAFKTime), CheckAFK, i, TIMER_FLAG_NO_MAPCHANGE)
				}
				else
				{
					AFKTimer[i] = INVALID_HANDLE
				}
			}
		}
		new Timer = FindEntityByClassname(-1, "dod_round_timer")
		AcceptEntityInput(Timer, "Kill")
		GameTimer = INVALID_HANDLE
		return Plugin_Handled
	}
	new Float:livetimer = (GetConVarFloat(LiveTime)*60.0)
	GameTimer = CreateTimer(livetimer, TimerEnd, _, TIMER_FLAG_NO_MAPCHANGE)
	ZeroTimerWarmup()
	StartLiveTimer()
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			new team = GetClientTeam(i)
			if(DefendingTeam[g_RoundCount] == ALLIES)
			{
				if(team == ALLIES)
				{
					EmitSoundToClient(i, AlliesDefendSnd[GetRandomInt(0, 2)])
				}
				else if(team == AXIS)
				{
					EmitSoundToClient(i, AxisAttackSnd[GetRandomInt(0, 2)])
				}
			}
			else if(DefendingTeam[g_RoundCount] == AXIS)
			{
				if(team == AXIS)
				{
					EmitSoundToClient(i, AxisDefendSnd[GetRandomInt(0, 2)])
				}
				else if(team == ALLIES)
				{
					EmitSoundToClient(i, AlliesAttackSnd[GetRandomInt(0, 2)])
				}
			}
			if(LiveAFKTime > 0)
			{
				AFKTimer[i] = CreateTimer(float(LiveAFKTime), CheckAFK, i, TIMER_FLAG_NO_MAPCHANGE)
			}
			else
			{
				AFKTimer[i] = INVALID_HANDLE
			}
		}
	}
	new TeamWall = -1
	while((TeamWall = FindEntityByClassname(TeamWall, "func_team_wall")) != -1)
	{
		AcceptEntityInput(TeamWall, "Kill")
	}
	new TeamBlocker = -1
	while((TeamBlocker = FindEntityByClassname(TeamBlocker, "func_teamblocker")) != -1)
	{
		AcceptEntityInput(TeamBlocker, "Kill")
	}
	return Plugin_Handled
}

public Action:CheckAFK(Handle:timer, any:client)
{
	AFKTimer[client] = INVALID_HANDLE
	if(IsClientInGame(client) && IsPlayerAlive(client) && g_Live == 1 && GetConVarInt(LiveAFKKiller) != 0)
	{
		new Float:CurrentPos[3]
		GetClientAbsOrigin(client, CurrentPos)
		if(GetVectorDistance(CurrentPos, g_PlayerSpawnPos[client]) <= 400.0)
		{
			KillPlayer(client)
		}
	}
	return Plugin_Handled
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(client < 1 || !IsClientInGame(client) || GetClientTeam(client) <= SPEC || g_Live == 0)
	{
		return Plugin_Continue
	}
	if(AFKTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(AFKTimer[client])
	}
	g_PluginClass[client] = 0
	AFKTimer[client] = INVALID_HANDLE
	CreateTimer(1.0, SoldierDown, client, TIMER_FLAG_NO_MAPCHANGE)
	if(GetConVarInt(DisableDeathMsgs) == 1)
	{
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(client < 1 || client > MaxClients || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= SPEC)
	{
		return Plugin_Continue
	}
	ClientCommand(client, "r_screenoverlay 0")
	g_LastStuck[client] = 0.0
	g_PrimedNade[client] = false
	if(g_Started == 0)
	{
		return Plugin_Continue
	}
	if(AFKTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(AFKTimer[client])
	}
	AFKTimer[client] = INVALID_HANDLE
	GetClientAbsOrigin(client, g_PlayerSpawnPos[client])
	g_PlayerTeam[client] = GetClientTeam(client)
	if(g_Started == 1)
	{
		SetEntProp(client, Prop_Data, "m_iDeaths", Deaths[client])
		SetEntProp(client, Prop_Data, "m_iFrags", Kills[client])
		if(g_RoundCount == 5 && g_AVA == 1)
		{
			SetPlayerMovement(0.0)
		}
	}
	return Plugin_Continue
}

stock AllPlayersInit()
{
	g_Init = 1
	ServerCommand("exec %s", INITCFG)
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if(GetClientTeam(i) != SPEC)
			{
				g_PluginSwitched[i] = 1
				ChangeClientTeam(i, SPEC)
			}
			g_PluginSwitched[i] = 1
			ChangeClientTeam(i, InitialTeam)
			ShowVGUIPanel(i, InitialTeam == AXIS ? "class_ger" : "class_us", INVALID_HANDLE, false)
			g_PluginClass[i] = 1
			FakeClientCommand(i, "%s", InitialTeam == AXIS ? "cls_k98" : "cls_garand")
		}
	}
	SetConVarInt(FindConVar("mp_clan_restartround"), 1, true, false)
}

stock AllPlayersOpTeam()
{
	new AlliedLeader = g_AlliedLeader
	new AxisLeader = g_AxisLeader
	g_AlliedLeader = AxisLeader
	g_AxisLeader = AlliedLeader
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			Deaths[i] = GetEntProp(i, Prop_Data, "m_iDeaths")
			Kills[i] = GetEntProp(i, Prop_Data, "m_iFrags")
			new currteam = GetClientTeam(i)
			if(currteam != SPEC)
			{
				g_PluginSwitched[i] = 1
				ChangeClientTeam(i, SPEC)
			}
			if(currteam != OpTeam[g_PlayerTeam[i]])
			{
				g_PluginSwitched[i] = 1
				ChangeClientTeam(i, OpTeam[g_PlayerTeam[i]])
				ShowVGUIPanel(i, OpTeam[g_PlayerTeam[i]] == AXIS ? "class_ger" : "class_us", INVALID_HANDLE, false)
				g_PluginClass[i] = 1
				FakeClientCommand(i, "%s", OpTeam[g_PlayerTeam[i]] == AXIS ? "cls_k98" : "cls_garand")
			}
		}
	}
	SetConVarInt(FindConVar("mp_clan_restartround"), 1, true, false)
}

stock AllPlayersPrevTeam()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			Deaths[i] = GetEntProp(i, Prop_Data, "m_iDeaths")
			Kills[i] = GetEntProp(i, Prop_Data, "m_iFrags")
			if(GetClientTeam(i) != SPEC)
			{
				g_PluginSwitched[i] = 1
				ChangeClientTeam(i,SPEC)
			}
			g_PluginSwitched[i] = 1
			ChangeClientTeam(i, g_PlayerTeam[i])
			ShowVGUIPanel(i, g_PlayerTeam[i] == AXIS ? "class_ger" : "class_us", INVALID_HANDLE, false)
			g_PluginClass[i] = 1
			FakeClientCommand(i, "%s", g_PlayerTeam[i] == AXIS ? "cls_k98" : "cls_garand")
		}
	}
	SetConVarInt(FindConVar("mp_clan_restartround"), 1, true, false)
}

stock AllPlayersStart()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			Deaths[i] = GetEntProp(i, Prop_Data, "m_iDeaths")
			Kills[i] = GetEntProp(i, Prop_Data, "m_iFrags")
			new team = GetClientTeam(i)
			if(team != SPEC)
			{
				g_PluginSwitched[i] = 1
				ChangeClientTeam(i,SPEC)
				g_PluginSwitched[i] = 1
				ChangeClientTeam(i, team)
				ShowVGUIPanel(i, team == AXIS ? "class_ger" : "class_us", INVALID_HANDLE, false)
				g_PluginClass[i] = 1
				FakeClientCommand(i, "%s", team == AXIS ? "cls_k98" : "cls_garand")
			}
		}
	}
	SetConVarInt(FindConVar("mp_clan_restartround"), 1, true, false)
}

public Action:SoldierDown(Handle:timer, any:client)
{
	if(IsClientInGame(client) && GetClientTeam(client) > SPEC)
	{
		g_PluginSwitched[client] = 1
		ChangeClientTeam(client,SPEC)
		if(GetConVarInt(SpecBlackOut) > 0)
		{
			ClientCommand(client, "r_screenoverlay Effects/tp_eyefx/tp_black")
		}
		if(GetConVarInt(SpecShowHUD) == 0)
		{
			new hudflags = GetEntProp(client, Prop_Send, "m_iHideHUD")
			hudflags |= HIDEHUD_ALL
			SetEntProp(client, Prop_Send, "m_iHideHUD", hudflags)
		}
	}
	new alliescount = GetTeamClientCount(ALLIES)
	new axiscount = GetTeamClientCount(AXIS)
	if(alliescount == 0 || axiscount == 0 && g_Live == 1)
	{
		if(GameTimer != INVALID_HANDLE)
		{
			CloseHandle(GameTimer)
			GameTimer = INVALID_HANDLE
		}
		g_Live = 0
		if(alliescount == 0 && axiscount != 0)
		{
			PrintHintTextToAll("Round is over! Axis have won!")
			PrintToChatAll("\x04Round is over! \x01Axis \x04have won!")
			if(g_RoundCount == 1 || g_RoundCount == 2 || g_RoundCount == 5)
			{
				Score[0]++
			}
			else
			{
				Score[1]++
			}
		}
		else if(alliescount != 0 && axiscount == 0)
		{
			PrintHintTextToAll("Round is over! Allies have won!")
			PrintToChatAll("\x04Round is over! \x01Allies \x04have won!")
			if(g_RoundCount == 1 || g_RoundCount == 2 || g_RoundCount == 5)
			{
				Score[1]++
			}
			else
			{
				Score[0]++
			}
		}
		HandleRoundEnd()
	}
	return Plugin_Handled
}

public Action:HandleRoundEnd()
{
	g_CmdsAvailable = 0
	if(g_RoundCount == 2)
	{
		AllPlayersOpTeam()
		return Plugin_Handled
	}
	else if(g_RoundCount == 4)
	{
		if(Score[0] > Score[1] || Score[0] < Score[1])
		{
			if(Score[0] > Score[1])
			{
				g_MatchWinner = ALLIES
			}
			else
			{
				g_MatchWinner = AXIS
			}
			PrintMatchResult()
			ResetRealism()
			AllPlayersInit()
			return Plugin_Handled
		}
		else
		{
			g_AVA = 1
			AllPlayersOpTeam()
			return Plugin_Handled
		}
	}
	else if(g_RoundCount == 5)
	{
		if(Score[0] > Score[1])
		{
			g_MatchWinner = AXIS
		}
		else
		{
			g_MatchWinner = ALLIES
		}
		PrintMatchResult()
		ResetRealism()
		AllPlayersInit()
		return Plugin_Handled
	}
	else
	{
		if(g_RoundCount == 3 && Score[0] == 3 || Score[1] == 3)
		{
			if(Score[0] == 3)
			{
				g_MatchWinner = ALLIES
			}
			else
			{
				g_MatchWinner = AXIS
			}
			PrintMatchResult()
			ResetRealism()
			AllPlayersInit()
			return Plugin_Handled
		}
		AllPlayersPrevTeam()
		return Plugin_Handled
	}
}

stock PrintMatchResult()
{
	new EndScore[4]
	if(Score[0] > Score[1])
	{
		EndScore[g_MatchWinner] = Score[0]
		EndScore[OpTeam[g_MatchWinner]] = Score[1]
	}
	else
	{
		EndScore[g_MatchWinner] = Score[1]
		EndScore[OpTeam[g_MatchWinner]] = Score[0]
	}
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && g_PlayerTeam[i] > SPEC)
		{
			PrintHintText(i, "MATCH IS OVER!\n\nYour Team %s the Match %i:%i", g_MatchWinner == g_PlayerTeam[i] ? "WON" : "LOST", g_MatchWinner == g_PlayerTeam[i] ? EndScore[g_MatchWinner] : EndScore[OpTeam[g_MatchWinner]], g_MatchWinner == g_PlayerTeam[i] ? EndScore[OpTeam[g_MatchWinner]] : EndScore[g_MatchWinner])
			PrintToChat(i, "\x01MATCH IS OVER! \x04Your Team \x01%s \x04the Match \x01%i\x04:\x01%i \x04!", g_MatchWinner == g_PlayerTeam[i] ? "WON" : "LOST", g_MatchWinner == g_PlayerTeam[i] ? EndScore[g_MatchWinner] : EndScore[OpTeam[g_MatchWinner]], g_MatchWinner == g_PlayerTeam[i] ? EndScore[OpTeam[g_MatchWinner]] : EndScore[g_MatchWinner])
		}
	}
}

public Action:OnJoinTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(client < 1)
	{
		return Plugin_Continue
	}
	new team = GetEventInt(event, "team")
	if(IsClientInGame(client) && g_PluginSwitched[client] == 1)
	{
		if(team == SPEC)
		{
			g_PluginSwitched[client] = 0
		}
		else if(team == ALLIES || team == AXIS)
		{
			g_PluginSwitched[client] = 0
			return Plugin_Handled
		}
		return Plugin_Handled
	}
	return Plugin_Continue
}

public OnEntityCreated(entity, const String:classname[])
{
    SDKHook(entity, SDKHook_Spawn, OnEntitySpawned)
}

public OnEntitySpawned(entity)
{
	decl String:classname[128]
	GetEdictClassname(entity, classname, sizeof(classname))
	if(g_Started == 1)
	{
		if(StrEqual(classname, "dod_control_point_master"))
		{
			CPM = entity
			new Float:time
			decl String:timestr[12]
			DispatchKeyValue(CPM, "cpm_use_timer", "1")
			if(g_RoundCount != 4)
			{
				time = GetConVarFloat(SetupTime) * 60
				FloatToString(time, timestr, sizeof(timestr))
				DispatchKeyValue(CPM, "cpm_timer_length", timestr)
			}
			else
			{
				time = GetConVarFloat(AvASetupTime)
				FloatToString(time, timestr, sizeof(timestr))
				DispatchKeyValue(CPM, "cpm_timer_length", timestr)
			}
			DispatchKeyValue(CPM, "cpm_timer_team", "0")
		}
		else if(StrEqual(classname, "func_teamblocker"))
		{
			decl String:BlockTeam[2]
			IntToString(OpTeam[DefendingTeam[g_RoundCount+1]], BlockTeam, sizeof(BlockTeam))
			DispatchKeyValue(entity, "TeamNum", BlockTeam)
		}
		else if(StrEqual(classname, "func_team_wall"))
		{
			decl String:BlockTeam[2]
			IntToString(OpTeam[DefendingTeam[g_RoundCount+1]], BlockTeam, sizeof(BlockTeam))
			DispatchKeyValue(entity, "blockteam", BlockTeam)
		}
		else if(StrEqual(classname, "dod_capture_area") || StrEqual(classname, "dod_control_point"))
		{
			if(GetConVarInt(AllowObjectives) == 0)
			{
				AcceptEntityInput(entity, "Disable")
			}
			else
			{
				AcceptEntityInput(entity, "Enable")
			}
		}
		else if(StrEqual(classname, "dod_bomb_target") || StrEqual(classname, "dod_bomb_dispenser") || StrEqual(classname, "dod_bomb_dispenser_icon"))
		{
			if(GetConVarInt(AllowTNTUsage) == 0)
			{
				AcceptEntityInput(entity, "Disable")
			}
			else
			{
				if(StrEqual(classname, "dod_bomb_target"))
				{
					DispatchKeyValue(entity, "add_timer_seconds", "0")
				}
				AcceptEntityInput(entity, "Enable")
			}
		}
	}
	else if(g_Init == 1)
	{
		if(StrEqual(classname, "dod_capture_area") || StrEqual(classname, "dod_control_point") || StrEqual(classname, "dod_bomb_target") || StrEqual(classname, "dod_bomb_dispenser") || StrEqual(classname, "dod_bomb_dispenser_icon"))
		{
			AcceptEntityInput(entity, "Disable")
		}
		else if(StrEqual(classname, "dod_control_point_master"))
		{
			DispatchKeyValue(entity, "cpm_use_timer", "0")
		}
	}
}

DealDamage(victim, damage, attacker = 0, dmg_type = DMG_GENERIC, String:weapon[]="")
{
	if(victim > 0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage > 0)
	{
		new String:dmg_str[16]
		IntToString(damage, dmg_str, 16)
		new String:dmg_type_str[32]
		IntToString(dmg_type,dmg_type_str, 32)
		new pointHurt = CreateEntityByName("point_hurt")
		if(pointHurt)
		{
			DispatchKeyValue(victim, "targetname", "killme")
			DispatchKeyValue(pointHurt, "DamageTarget", "killme")
			DispatchKeyValue(pointHurt, "Damage", dmg_str)
			DispatchKeyValue(pointHurt, "DamageType", dmg_type_str)
			if(!StrEqual(weapon, ""))
			{
				DispatchKeyValue(pointHurt, "classname", weapon)
			}
			DispatchSpawn(pointHurt)
			AcceptEntityInput(pointHurt, "Hurt", (attacker>0)?attacker:-1)
			DispatchKeyValue(pointHurt, "classname", "point_hurt")
			DispatchKeyValue(victim, "targetname", "dontkillme")
			RemoveEdict(pointHurt)
		}
	}
}

KillPlayer(client)
{
	new health = GetClientHealth(client)
	DealDamage(client, health+1, client, DMG_BULLET)
}
