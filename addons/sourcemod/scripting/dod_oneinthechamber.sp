#include <sourcemod>
#include <dodhooks>
//##################
//# Config
//##################
ParseConfigFile(const String:file[])
{
	// Create parser with all sections (start & end)
	new Handle:parser = SMC_CreateParser();
	SMC_SetReaders (parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	SMC_SetParseEnd(parser, Config_End);

	// Checking for error
	new String:error[128], line, col, SMCError:result = SMC_ParseFile(parser, file, line, col);

	// Close handle
	CloseHandle(parser);

	// Log an error
	if (result != SMCError_Okay)
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s at line %d, col %d of %s", error, line, col, file);
	}
}

/* Config_NewSection()
 *
 * Called when the parser is entering a new section or sub-section.
 * ---------------------------------------------------------------------- */
public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes)
{
	// Ignore first config level (GunMenu Weapons)
	ParserLevel++;

	if (ParserLevel == 2)
	{
		// Checking if menu names is correct
		if (StrEqual("Primary Guns", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_PrimaryKeyValue, Config_EndSection);

		/* If correct - sets the three main reader functions */
		else if (StrEqual("Secondary Guns", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_SecondaryKeyValue, Config_EndSection);

		/* for specified menu */
		else if (StrEqual("Melee Weapons", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_MeleeKeyValue, Config_EndSection);
		else if (StrEqual("Grenades", section, false))
			SMC_SetReaders(parser, Config_NewSection, Config_GrenadeKeyValue, Config_EndSection);
	}
	// Anyway create pointers
	else SMC_SetReaders(parser, Config_NewSection, Config_UnknownKeyValue, Config_EndSection);
	return SMCParse_Continue;
}

/* Config_UnknownKeyValue()
 *
 * Called when the parser finds a new key/value pair.
 * ---------------------------------------------------------------------- */
public SMCResult:Config_UnknownKeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	// Log an error if unknown key value found in a config file
	SetFailState("Didn't recognize configuration: %s = %s", key, value);
	return SMCParse_Continue;
}

/* Config_PrimaryKeyValue()
 *
 * Called when the parser finds a primary key/value pair.
 * ---------------------------------------------------------------------- */
public SMCResult:Config_PrimaryKeyValue(Handle:parser, const String:weapon_class[], const String:weapon_name[], bool:key_quotes, bool:value_quotes)
{
	// Weapons should not exceed real value
	if (PrimaryGuns_Count > PRIMARY_WEAPON_COUNT)
		SetFailState("Too many weapons declared!");

	decl String:weapon_id[4];

	// Copies one string to another string
	strcopy(PrimaryGuns[PrimaryGuns_Count], sizeof(PrimaryGuns[]), weapon_class);
	FormatEx(weapon_id, sizeof(weapon_id), "%i", PrimaryGuns_Count++);
	AddMenuItem(PrimaryMenu, weapon_id, weapon_name);
	SetTrieValue(WeaponsTrie, weapon_class, StringToInt(weapon_id));
	return SMCParse_Continue;
}
/* Config_End()
 *
 * Called when the config is ready.
 * ---------------------------------------------------------------------- */
public Config_End(Handle:parser, bool:halted, bool:failed)
{
	// Failed to load config. Maybe we missed a braket or something?
	if (failed)
	{
		SetFailState("Plugin configuration error!");
	}
}

//##################
//# Actions
//##################
public Plugin myinfo =
{
	name = "DOD:S One in the Chamber",
	author = "Chaz Smith",
	description = "One in the Chamber game from CoD BlackOps implemented in DOD:S",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	PrintToServer("Sgt. Smith's One in the Chamber Plugin here!");
  RegAdminCmd("sm_oneinthechamber", Command_OneInTheChamber, ADMFLAG_SLAY);
	LoadTranslations("common.phrases.txt");
}

public Action Command_OneInTheChamber(int client, int args)
{
	PrintToServer("Sgt. Smith's One in the Chamber Plugin here!");
  return Plugin_Handled;
}

//##################
//# Functions
//##################
/* SetAmmo()
 *
 * Adds magazines to a specified weapons.
 * ---------------------------------------------------------------------- */
SetAmmo(client, Slots:slot)
{
	// Returns the weapon in a player's slot
	new weapon = GetPlayerWeaponSlot(client, _:slot);

	// Checking if weapon is valid
	if (IsValidEdict(weapon))
	{
		// I dont know how its working, but its working very well!
		switch (GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"))
		{
			case 1:  SetEntData(client, m_iAmmo + 4,   14); /* Colt */
			case 2:  SetEntData(client, m_iAmmo + 8,   16); /* P38 */
			case 3:  SetEntData(client, m_iAmmo + 12,  40); /* C96 */
			case 4:  SetEntData(client, m_iAmmo + 16,  80); /* Garand */
			case 5:  SetEntData(client, m_iAmmo + 20,  60); /* K98+scoped */
			case 6:  SetEntData(client, m_iAmmo + 24,  30); /* M1 Carbine */
			case 7:  SetEntData(client, m_iAmmo + 28,  50); /* Spring */
			case 8:  SetEntData(client, m_iAmmo + 32, 180); /* Thompson, MP40 and STG44 */
			case 9:  SetEntData(client, m_iAmmo + 36, 240); /* BAR */
			case 10: SetEntData(client, m_iAmmo + 40, 300); /* 30cal */
			case 11: SetEntData(client, m_iAmmo + 44, 250); /* MG42 */
			case 12: SetEntData(client, m_iAmmo + 48,   4); /* Bazooka, Panzerschreck */
			case 13: SetEntData(client, m_iAmmo + 52,   2); /* US frag gren */
			case 14: SetEntData(client, m_iAmmo + 56,   2); /* Stick gren */
			case 15: SetEntData(client, m_iAmmo + 68,   1); /* US Smoke */
			case 16: SetEntData(client, m_iAmmo + 72,   1); /* Stick smoke */
			case 17: SetEntData(client, m_iAmmo + 84,   2); /* Riflegren US */
			case 18: SetEntData(client, m_iAmmo + 88,   2); /* Riflegren GER */
		}
	}
}

/* RemoveWeaponBySlot()
 *
 * Remove's player weapon by slot.
 * ---------------------------------------------------------------------- */
RemoveWeaponBySlot(client, Slots:slot)
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
}
