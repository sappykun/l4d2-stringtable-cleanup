#include <dhooks>

#pragma newdecls required
#pragma semicolon 1

ConVar cvar_EnableSceneTableBlock;
ConVar cvar_EnableDownloadablesBlock;
ConVar cvar_EnableModelPrecacheCheck;

DynamicHook dhook_AddString;

ArrayList g_Filenames;

public Plugin myinfo =
{
	name		= "L4D2 Stringtable Cleanup",
	author	  = "Sappykun",
	description = "Prevents clutter in L4D2's stringtables",
	version	 = "1.0.0"
};

public void OnPluginStart()
{
	cvar_EnableSceneTableBlock = CreateConVar("stringtablecleanup_sceneblock_enabled", "1", "Prevents the Scenes table from being populated", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_EnableDownloadablesBlock = CreateConVar("stringtablecleanup_downloadablesblock_enabled", "1", "Prevents the downloadables table from being populated with vanilla assets", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_EnableModelPrecacheCheck = CreateConVar("stringtablecleanup_modelprecachecheck_enabled", "0",	"Enables the modelprecache table check, not recommended\n\t0 - Disabled\n\t1 - Print warning to console when an invalid file is added to the modelprecache table\n\t2 - Block invalid files from being added to the modelprecache table; this will most likely crash your server", FCVAR_NOTIFY, true, 0.0, true, 2.0);

	Handle conf = LoadGameConfigFile("l4d2.stringtablecleanup");
	if (conf == null) SetFailState("Failed to load gamedata/l4d2.stringtablecleanup.txt");

	dhook_AddString = DynamicHook.FromConf(conf, "CNetworkStringTable::AddString");
	if (dhook_AddString == null) SetFailState("Failed to create dhook_AddString");
	if (!DHookEnableDetour(dhook_AddString, false, AddString_Pre)) SetFailState("Couldn't set up detour for CNetworkStringTable::AddString");
	
	delete conf;
	
	LoadDownloadsTableBlacklist();
}

void LoadDownloadsTableBlacklist()
{
    g_Filenames = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));

    char fullPath[PLATFORM_MAX_PATH];
	char folder[PLATFORM_MAX_PATH];
	GetGameFolderName(folder, PLATFORM_MAX_PATH);
    BuildPath(Path_SM, fullPath, sizeof(fullPath), "configs/stringtablecleanup/%s.txt", folder);

    File cleanupFile = OpenFile(fullPath, "r");
    if (cleanupFile == null) {
        PrintToServer("Failed to open file: %s", fullPath);
        return;
    }

    char line[PLATFORM_MAX_PATH];
    while (!cleanupFile.EndOfFile() && cleanupFile.ReadLine(line, sizeof(line))) {
        TrimString(line);

        if (line[0] == '\0' || (line[0] == '/' && line[1] == '/'))
            continue;

        g_Filenames.PushString(line);
    }

    delete cleanupFile;
}

/*
	The first entry in the modelprecachetable is the map name.
	The *number entries are brush-based models for the current map.
	The vanilla game doen't add any files that aren't .mdl, .vmt, or .spr,
	all of which will crash the server if blocked.  On map change, the engine
	also tries to add a blank entry "", probably for index 0.
	
	TODO: The downloadables table adds 5 VPK files and one steam.inf file.
	Can we trim those? Should we? 
*/
public MRESReturn AddString_Pre(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	char tableName[64];
	char string[PLATFORM_MAX_PATH];
	char ext[5];
	hParams.GetString(2, string, PLATFORM_MAX_PATH);
	
	int tableId = LoadFromAddress(pThis + view_as<Address>(4), NumberType_Int8);
	GetStringTableName(tableId, tableName, 64);
	
	int len = strlen(string);
	if (len >= 4)
		strcopy(ext, sizeof(ext), string[len - 4]);

	if (cvar_EnableSceneTableBlock.BoolValue && StrEqual(tableName, "Scenes")) {
		DHookSetReturn(hReturn, -1);
		return MRES_Supercede;
	}
	
	if (cvar_EnableDownloadablesBlock.BoolValue && StrEqual(tableName, "downloadables") && g_Filenames.FindString(string) > -1) {
		DHookSetReturn(hReturn, -1);
		return MRES_Supercede;
	}
	
	// For the precache tables only, index 0 means invalid entry
	// -1 means it's full, which will crash the server, so return 0.
	if (cvar_EnableModelPrecacheCheck.BoolValue && StrEqual(tableName, "modelprecache")) {
		if (!(StrEqual(ext, ".bsp") || StrEqual(ext, NULL_STRING) || string[0] == '*' || 
			StrEqual(ext, ".mdl") || StrEqual(ext, ".vmt") || StrEqual(ext, ".spr") )) {
				if (cvar_EnableModelPrecacheCheck.IntValue == 2) {
					LogError("Blocking addition of file to modelprecache table, check your plugins: %s", string); 
					DHookSetReturn(hReturn, 0);
					return MRES_Supercede;
				} else {
					LogError("Adding invalid file to modelprecache table, check your plugins: %s", string); 
				}
		}
	}
	
	return MRES_Ignored;
}
