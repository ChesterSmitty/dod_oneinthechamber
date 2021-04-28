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



new String:g_szGameSound_Intro[PLATFORM_MAX_PATH];

LoadSound(const String:sFile[])
{
	decl String:sPath[PLATFORM_MAX_PATH];
	Format(sPath, sizeof(sPath), "sound/%s", sFile);
	PrecacheSound(sFile, true);
	AddFileToDownloadsTable(sPath);
}


LoadConfig()
{
	decl String:sPath[PLATFORM_MAX_PATH];
	new Handle:hConfig          = CreateKeyValues("dod_oneinthechamber");
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/oneinthechamber_sound.txt");
	if (FileExists(sPath))
	{
		FileToKeyValues(hConfig, sPath);
		KvRewind(hConfig);
		KvJumpToKey(hConfig, "Sounds");
		KvGetString(hConfig, "Join",       g_sSoundJoin,       PLATFORM_MAX_PATH);
	if (!StrEqual(g_sSoundJoin,       ""))
	{
		LoadSound(g_sSoundJoin);
	}
}
