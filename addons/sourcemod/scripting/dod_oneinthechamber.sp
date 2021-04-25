#include <sourcemod>
#include <sdktools>
//#include <dodhooks>
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

new Handle:v_TextEnabled = INVALID_HANDLE;

enum Slots
{
Slot_Primary,
Slot_Secondary,
Slot_Melee,
Slot_Grenade
};

//##################
//# Variables
//##################
new m_iAmmo;

//##################
//# Config
//##################

//##################
//# Actions
//##################

public void OnPluginStart()
{
	m_iAmmo = FindSendPropOffs("CDODPlayer", "m_iAmmo");
	HookEvent("player_spawn", OnPlayerSpawn);
	CreateConVar("sm_setammo_version", PLUGIN_VERSION, "Set Ammo Version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	RegAdminCmd("sm_setammo", CommandSetAmmo, ADMFLAG_ROOT, "sm_setammo <Player> <Slot> <Offhand Ammo>");
	RegAdminCmd("sm_setclip", CommandSetClip, ADMFLAG_ROOT, "sm_setclip <Player> <Slot> <Ammo>");
	v_TextEnabled = CreateConVar("sm_setammo_showtext", "1", "Enable/Disable Text <1/0>", 0, true, 0.0, true, 1.0);
	//PrintToServer("Sgt. Smith's One in the Chamber Plugin here!");
  //RegAdminCmd("sm_oneinthechamber", Command_OneInTheChamber, ADMFLAG_SLAY);
	//LoadTranslations("common.phrases.txt");
	//AutoExecConfig(true, "plugin_oneinthechamber");
}



public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GivePlayerItem(client, "weapon_colt");
	SetAmmo(client, Slot_Secondary, 1);
}



public Action:CommandOneInTheChamber(int client, int args)
{
	PrintToServer("Sgt. Smith's One in the Chamber Plugin here!");
	return Plugin_Handled;
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
		//SetAmmo(target_list[i], Slot, Ammo, client)
		SetAmmo(target_list[i], Slot, Ammo)
	}

	return Plugin_Handled;
}

public Action:CommandSetClip(client, args)
{
	if (args != 3)
	{
		ReplyToCommand(client, "Usage: sm_setclip <Player> <Slot> <Ammo>");
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
		ShowActivity2(client, "\x04[\x03SetAmmo\x04] "," \x01gave \x05%s\x01 a clip size of \x04%i\x01 in weapon slot \x04%i\x01!", target_name, Ammo, Slot+1);
	}
	for (new i = 0; i < target_count; i ++)
	{
		//SetClip(target_list[i], Slot, Ammo, client)
		SetClip(target_list[i], Slot, Ammo)
	}

	return Plugin_Handled;
}



//##################
//# Functions
//##################
//stock SetClip(client, wepslot, newAmmo, admin)
stock SetClip(client, wepslot, newAmmo)
{
	new weapon = GetPlayerWeaponSlot(client, wepslot);
	//if (!IsValidEntity(weapon))
	//{
	//	ReplyToCommand(admin, "\x04[\x03SetAmmo\x04]:\x01 Invalid weapon slot")
	//}
	if (IsValidEntity(weapon))
	{
		//new iAmmoTable = FindSendPropInfo("CDODWeaponBase", "m_iClip1");
		new iAmmoTable = FindSendPropInfo("CDODPlayer", "m_iClip1");
		SetEntData(weapon, iAmmoTable, newAmmo, 4, true);
	}
}


//stock SetAmmo(client, wepslot, newAmmo, admin)
stock SetAmmo(client, wepslot, newAmmo)
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
}

/* SetAmmo()
 *
 * Adds magazines to a specified weapons.
 * ----------------------------------------------------------------------*/
/*
SetAmmo(client, Slots:slot)
{
	// Returns the weapon in a player's slot
	new weapon = GetPlayerWeaponSlot(client, _:slot);

	// Checking if weapon is valid
	if (IsValidEdict(weapon))
	{
		// I dont know how its working, but its working very well!
		switch (GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"))
		{*/
			//case 1:  SetEntData(client, m_iAmmo + 4,   1); /* Colt */
			//case 2:  SetEntData(client, m_iAmmo + 8,   0); /* P38 */
			//case 3:  SetEntData(client, m_iAmmo + 12,  0); /* C96 */
			//case 4:  SetEntData(client, m_iAmmo + 16,  0); /* Garand */
			//case 5:  SetEntData(client, m_iAmmo + 20,  0); /* K98+scoped */
			//case 6:  SetEntData(client, m_iAmmo + 24,  0); /* M1 Carbine */
			//case 7:  SetEntData(client, m_iAmmo + 28,  0); /* Spring */
			//case 8:  SetEntData(client, m_iAmmo + 32,  0); /* Thompson, MP40 and STG44 */
			//case 9:  SetEntData(client, m_iAmmo + 36,  0); /* BAR */
			//case 10: SetEntData(client, m_iAmmo + 40,  0); /* 30cal */
			//case 11: SetEntData(client, m_iAmmo + 44,  0); /* MG42 */
			//case 12: SetEntData(client, m_iAmmo + 48,  0); /* Bazooka, Panzerschreck */
			//case 13: SetEntData(client, m_iAmmo + 52,  0); /* US frag gren */
			//case 14: SetEntData(client, m_iAmmo + 56,  0); /* Stick gren */
			//case 15: SetEntData(client, m_iAmmo + 68,  0); /* US Smoke */
			//case 16: SetEntData(client, m_iAmmo + 72,  0); /* Stick smoke */
			//case 17: SetEntData(client, m_iAmmo + 84,  0); /* Riflegren US */
			//case 18: SetEntData(client, m_iAmmo + 88,  0); /* Riflegren GER */
		//}
	//}
//}

/* RemoveWeaponBySlot()
 *
 * Remove's player weapon by slot.
 * ---------------------------------------------------------------------- */
/*RemoveWeaponBySlot(client, Slots:slot)
{
	// Get slot which should be removed
	new weapon = GetPlayerWeaponSlot(client, _:slot);

	// Checking if weapon is valid
	if (IsValidEdict(weapon))
	{
		// Proper weapon removing
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
}*/
