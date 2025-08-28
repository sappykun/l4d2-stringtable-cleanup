#include <dhooks>

#pragma newdecls required
#pragma semicolon 1

DynamicHook dhook_AddString;

public Plugin myinfo =
{
	name		= "L4D2 Stringtable Cleanup",
	author	  = "Sappykun",
	description = "Prevents clutter in L4D2's stringtables",
	version	 = "0.0.1"
};

public void OnPluginStart()
{
	Handle conf = LoadGameConfigFile("l4d2.stringtablecleanup");
	if (conf == null) SetFailState("Failed to load gamedata/l4d2.stringtablecleanup.txt");

	dhook_AddString = DynamicHook.FromConf(conf, "CNetworkStringTable::AddString");
	if (dhook_AddString == null) SetFailState("Failed to create dhook_AddString");
	
	if (!DHookEnableDetour(dhook_AddString, false, AddString_Pre)) SetFailState("Couldn't set up detour for CNetworkStringTable::AddString");
}

/*
	Implementation is rather inefficient, but the bulk of stringtable
	operations only run once per map start.
	Basically, we prevent almost the entirety of the Scenes table from being
	populated.  This doesn't have any observable negative impact on gameplay
	while providing a LOT of bandwidth for downloadables.
	
	I attempted to block wav and mp3 files from populating the soundprecache
	table, but this crashes the server because it'll still try to precache
	the now invalid entry. You have to block CEngineSoundServer::PrecacheSound
	too, and doing that prevents a lot of sounds from playing on the client, 
	as well as a lot of console spam.
	
	TODO: Instead of blanket-banning all .vcd files, find the address of the
	Scenes stringtable and block anything going into that.
*/

public MRESReturn AddString_Pre(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	char string[PLATFORM_MAX_PATH];
	char ext[5];
	hParams.GetString(2, string, PLATFORM_MAX_PATH);
	
	int len = strlen(string);
	if (len >= 4)
		strcopy(ext, sizeof(ext), string[len - 4]);

	if (StrEqual(ext, ".vcd")) {
		DHookSetReturn(hReturn, -1);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}
