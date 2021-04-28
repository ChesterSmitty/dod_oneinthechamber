#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <dodhooks>
//#pragma semicolon 1
//#pragma newdecls required
//LOOK AT FindSendPropInfo
#define PLUGIN_VERSION		"1.0"
//##################
//# Plugin Details
//##################
public Plugin myinfo =
{
	name = "DOD:S One in the Chamber",
	author = "ChesterSmitty",
	description = "One in the Chamber game from CoD BlackOps implemented in DOD:S",
	version = PLUGIN_VERSION,
	url = "https://github.com/ChesterSmitty/dod_oneinthechamber"
};

//##################
//# Constants
//##################
#define DOD_MAXPLAYERS	33

#define TEAM_SPECTATOR  1
#define TEAM_ALLIES  		2
#define TEAM_AXIS  			3
#define TEAM_RANDOM  		4

#define MAXCLASSES		14
#define MAXWEAPONS		22

new Handle:v_TextEnabled = INVALID_HANDLE;

//##################
//# Variables
//##################
new Handle:ScoreToWin = INVALID_HANDLE
new bool:g_bModRunning = true;
new bool:g_bRoundActive = true ;

new g_scoreallies = 0
new g_scoreaxis = 0


//##################
//# Config
//##################
new Handle:SetupTime = INVALID_HANDLE
//##################
//# Actions
//##################

public void OnPluginStart()
{
	//m_iAmmo = FindSendPropOffs("CDODPlayer", "m_iAmmo");
	HookEvent("player_spawn", OnPlayerSpawn);
	//HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	CreateConVar("dod_oneinthechamber_version", PLUGIN_VERSION, "DoD OneInTheChamber", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)
	ScoreToWin = CreateConVar("dod_oneinthechamber_scoretowin", "5", "<#> = Number of rounds to win the map", FCVAR_PLUGIN, true, 1.0, true, 15.0)
	RegAdminCmd("sm_setammo", CommandSetAmmo, ADMFLAG_ROOT, "sm_setammo <Player> <Slot> <Offhand Ammo>");
	//RegAdminCmd("sm_setclip", CommandSetClip, ADMFLAG_ROOT, "sm_setclip <Player> <Slot> <Ammo>");
	RegAdminCmd("sm_oneinthechamber", CommandOneInTheChamber, ADMFLAG_ROOT, "sm_oneinthechamber");
	v_TextEnabled = CreateConVar("sm_setammo_showtext", "1", "Enable/Disable Text <1/0>", 0, true, 0.0, true, 1.0);
	LoadTranslations("common.phrases.txt");
	//AutoExecConfig(true, "plugin_oneinthechamber");
}


public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	RemoveWeapons(client)
	//Give Colt with single bullet in clip and Knife
	new iWeapon = GivePlayerItem(client, "weapon_colt");
	new jWeapon = GivePlayerItem(client, "weapon_amerknife");
	//new m_iClip1 = GetEntProp(iWeapon, Prop_Send, "m_iClip1");
	SetEntProp(iWeapon, Prop_Send, "m_iClip1", 1);
	//SetAmmo(client, iWeapon, 0);
	SetAmmo(client, 2, 0)
}


/*public Event_PlayerDeath(Handle:event, const String:szName[], bool:bDontBroadcast)
{
	if (g_bRoundActive)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		//Move to Specate
		ChangeClientTeam(client, TEAM_SPECTATOR)
		//Lookup player who killed other player
		new attacker   = GetClientOfUserId(GetEventInt(event, "attacker"))
		//Give one bullet for colt
		SetAmmo(attacker, 2, 1)
	}
}*/

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

}



public Action:CommandOneInTheChamber(int client, int args)
{
	ReplyToCommand(client, "Sgt. Smith's One in the Chamber Plugin here!");
	return Plugin_Handled;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	//PrintToChatAll("Victim: %N, Attacker: %N, Inflictor: %N, Damage: %f, DamageType: %i", victim, attacker, inflictor, damage, damagetype)
	if( (attacker < 1) || (attacker > MaxClients))
	{
		//PrintToChatAll("Attacker value not valid player, skipping!")
		return Plugin_Handled;
	}
	damage = 300.0;
	SetAmmo(attacker, 1, 1)
	return Plugin_Changed
}


public Action:CommandSetAmmo(client, args)
{
	if (args != 3)
	{
		ReplyToCommand(client, "Usage: sm_setammo <Player> <Slot> <Ammo>");
		return Plugin_Handled;
	}

	//Create strings
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;

	//Get target
	GetCmdArg(1, buffer, sizeof(buffer));

	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	//Get weapon slot
	GetCmdArg(2, buffer, sizeof(buffer));
	new Slot = StringToInt(buffer);
	Slot--

	//Get ammo
	GetCmdArg(3, buffer, sizeof(buffer));
	new Ammo = StringToInt(buffer);

	if (GetConVarBool(v_TextEnabled))
	{
		ShowActivity2(client, "\x04[\x03SetAmmo\x04] "," \x01gave \x05%s \x04%i\x01 offhand ammo for the weapon in slot \x04%i\x01!", target_name, Ammo, Slot+1);
	}
	for (new i = 0; i < target_count; i ++)
	{
		SetAmmo(target_list[i], Slot, Ammo)
	}

	return Plugin_Handled;
}


//##################
//# Functions
//##################

//stock SetAmmo(client, wepslot, newAmmo, admin)
/*stock SetAmmo(client, wepslot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	//if (!IsValidEntity(weapon))
	//{
	//	ReplyToCommand(admin, "\x04[\x03SetAmmo\x04]:\x01 Invalid weapon slot")
	//}
	if (IsValidEntity(weapon))
	{
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		new iAmmoTable = FindSendPropInfo("CDODPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, newAmmo, 4, true);
	}
}*/
stock SetAmmo(client, slot, amount)
{
    new weapon = GetPlayerWeaponSlot(client, slot);
    if (weapon == -1)
        return 0;

    new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
    if (ammotype == -1)
        return 0;

    return GivePlayerAmmo(client, amount, ammotype);
}


RemoveWeapons(client)
{
	for (new i = 0, iWeapon; i < 5; i++)
	{
		if ((iWeapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, iWeapon);
			RemoveEdict(iWeapon);
		}
	}
}
