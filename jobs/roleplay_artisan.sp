/*
 * Cette oeuvre, création, site ou texte est sous licence Creative Commons Attribution
 * - Pas d’Utilisation Commerciale
 * - Partage dans les Mêmes Conditions 4.0 International. 
 * Pour accéder à une copie de cette licence, merci de vous rendre à l'adresse suivante
 * http://creativecommons.org/licenses/by-nc-sa/4.0/ .
 *
 * Merci de respecter le travail fourni par le ou les auteurs 
 * https://www.ts-x.eu/ - kossolax@ts-x.eu
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

enum craft_type {
	craft_raw,
	craft_amount,
	craft_rate,
	craft_type_max
}
enum craft_book {
	Float:book_xp,
	Float:book_sleep,
	Float:book_focus,
	Float:book_speed,
	Float:book_steal,
	Float:book_luck,
	book_max
}

StringMap g_hReceipe;
bool g_bCanCraft[65][MAX_ITEMS];
bool g_bInCraft[65];
float g_flClientBook[65][book_max];

//#define DEBUG
#define MODEL_TABLE1 	"models/props/de_boathouse/table_drafting01.mdl"
#define MODEL_TABLE2	"models/props/de_boathouse/table_drafting02.mdl"

int lstJOB[] =  { 11, 21, 31, 41, 51, 61, 71, 81, 111, 131, 171, 191, 211, 221 };

public Plugin myinfo = {
	name = "Jobs: ARTISAN", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Artisan",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};
// ----------------------------------------------------------------------------
//forward RP_CanClientCraftForFree(int client, int itemID);
//forward RP_ClientCraftOver(int client, int itemID);
Handle g_hForward_RP_CanClientCraftForFree, g_hForward_RP_CanClientCraftOver;
int doRP_CanClientCraftForFree(int client, int itemID) {
	int a;
	Call_StartForward(g_hForward_RP_CanClientCraftForFree);
	Call_PushCell(client);
	Call_PushCell(itemID);
	Call_Finish(a);
	return a;
}
bool doRP_ClientCraftOver(int client, int itemID) {
	Call_StartForward(g_hForward_RP_CanClientCraftOver);
	Call_PushCell(client);
	Call_PushCell(itemID);
	Call_Finish();
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);	
	RegServerCmd("rp_item_crafttable",		Cmd_ItemCraftTable,		"RP-ITEM", 	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_craftbook",		Cmd_ItemCraftBook,		"RP-ITEM", 	FCVAR_UNREGISTERED);
	RegAdminCmd("rp_fatigue", CmdSetFatigue, ADMFLAG_ROOT);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnAllPluginsLoaded() {
	SQL_TQuery(rp_GetDatabase(), SQL_LoadReceipe, "SELECT `itemid`, `raw`, `amount`, REPLACE(`extra_cmd`, 'rp_item_primal ', '') `rate` FROM `rp_csgo`.`rp_craft` C INNER JOIN `rp_items` I ON C.`raw`=I.`id` ORDER BY `itemid`, `raw`", 0, DBPrio_Low);
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {	
	g_hForward_RP_CanClientCraftForFree = CreateGlobalForward("RP_CanClientCraftForFree", ET_Event, Param_Cell, Param_Cell);
	g_hForward_RP_CanClientCraftOver = CreateGlobalForward("RP_ClientCraftOver", ET_Event, Param_Cell, Param_Cell);
}
public Action CmdSetFatigue(int client, int args) {
	rp_SetClientFloat(GetCmdArgInt(1), fl_ArtisanFatigue, GetCmdArgFloat(2) / 100.0);
}
public void OnMapStart() {
	PrecacheModel(MODEL_TABLE1);
	PrecacheModel(MODEL_TABLE2);
}
public Action Cmd_ItemCraftTable(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCraftTable");
	#endif
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( BuidlingTABLE(client) == 0 ) {
		ITEM_CANCEL(client, item_id);
	}
	
	return Plugin_Handled;
}
public Action Cmd_ItemCraftBook(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCraftBook");
	#endif
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	int client = GetCmdArgInt(2);
	
	craft_book type;
	
	if( StrEqual(arg, "level") ) {
		ClientGiveXP(client, 2500);
		displayStatsMenu(client);
		return Plugin_Handled;
	}
	else if( StrEqual(arg, "point") ) {
		rp_SetClientInt(client, i_ArtisanPoints, rp_GetClientInt(client, i_ArtisanPoints) + Math_GetRandomInt(1, 5));
		displayStatsMenu(client);
		return Plugin_Handled;
	}
	else if( StrEqual(arg, "xp") )
		type = book_xp;
	else if( StrEqual(arg, "sleep") )
		type = book_sleep;
	else if( StrEqual(arg, "focus") )
		type = book_focus;
	else if( StrEqual(arg, "speed") )
		type = book_sleep;
	else if( StrEqual(arg, "steal") )
		type = book_steal;
	else if( StrEqual(arg, "luck") )
		type = book_luck;
	
	if( g_flClientBook[client][type] > GetTickedTime() )
		g_flClientBook[client][type] += (60.0 * 6.0);
	else
		g_flClientBook[client][type] = GetTickedTime() + (60.0 * 6.0);
	
	displayStatsMenu(client);
	return Plugin_Handled;
}
public void SQL_LoadReceipe(Handle owner, Handle hQuery, const char[] error, any client) {
	if( g_hReceipe ) {
		g_hReceipe.Clear();
		delete g_hReceipe;
	}
	g_hReceipe = new StringMap();
	
	int data[craft_type_max];
	char itemID[12];
	ArrayList magic;
	
	while( SQL_FetchRow(hQuery) ) {
		SQL_FetchString(hQuery, 0, itemID, sizeof(itemID));
		data[craft_raw] = SQL_FetchInt(hQuery, 1);
		data[craft_amount] = SQL_FetchInt(hQuery, 2);
		data[craft_rate] = SQL_FetchInt(hQuery, 3);
		
		if( !g_hReceipe.GetValue(itemID, magic) ) {
			magic = new ArrayList(sizeof(data), 0);
			g_hReceipe.SetValue(itemID, magic);
		}
		magic.PushArray(data, sizeof(data));
	}
	return;
}
public void OnClientPostAdminCheck(int client) {
	#if defined DEBUG
	PrintToServer("OnClientPostAdminCheck");
	#endif
	
	rp_HookEvent(client, RP_OnPlayerUse, 	fwdUse);
	rp_HookEvent(client, RP_OnPlayerBuild,	fwdOnPlayerBuild);
	
	for(int i = 0; i < view_as<int>(book_max); i++)
		g_flClientBook[client][i] = 0.0;
	for(int i = 0; i < MAX_ITEMS; i++)
		g_bCanCraft[client][i] = false;
	g_bInCraft[client] = false;
	
	char szSteamID[65], query[1024];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	Format(query, sizeof(query), "SELECT `itemid` FROM `rp_craft_book` WHERE `steamid`='%s' AND `itemid`>0 AND `itemid`<%d;", szSteamID, MAX_ITEMS);
	SQL_TQuery(rp_GetDatabase(), SQL_LoadCraftbook, query, client);
}
public void SQL_LoadCraftbook(Handle owner, Handle hQuery, const char[] error, any client) {
	while( SQL_FetchRow(hQuery) ) {
		g_bCanCraft[client][SQL_FetchInt(hQuery, 0)] = true;
	}
}
// ----------------------------------------------------------------------------
public Action fwdFrozen(int client, float& speed, float& gravity) {
	speed = 0.0;
	gravity = 0.0; 
	return Plugin_Stop;
}
public Action fwdUse(int client) {
	if( isNearTable(client) && !g_bInCraft[client] ) {
		displayArtisanMenu(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action fwdOnPlayerBuild(int client, float& cooldown) {
	if( rp_GetClientJobID(client) != 31 )
		return Plugin_Continue;
	
	int ent = BuidlingTABLE(client);
	
	if( ent > 0 ) {
		rp_SetClientStat(client, i_TotalBuild, rp_GetClientStat(client, i_TotalBuild)+1);
		rp_ScheduleEntityInput(ent, 300.0, "Kill");
		cooldown = 120.0;
	}
	else 
		cooldown = 3.0;
	
	return Plugin_Stop;
}
public Action RP_CanClientStealItem(int client, int target) {
	if( isNearTable(target) && g_flClientBook[target][book_steal] > GetTickedTime() ) {
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
void displayArtisanMenu(int client) {
	#if defined DEBUG
	PrintToServer("displayArtisanMenu");
	#endif
	
	Handle menu = CreateMenu(eventArtisanMenu);
	SetMenuTitle(menu, "== Artisanat ==");
	
	AddMenuItem(menu, "build", 	"Construire");
	AddMenuItem(menu, "recycl", "Recycler");
	AddMenuItem(menu, "learn", 	"Apprendre");
	AddMenuItem(menu, "book", 	"Livre des recettes");
	AddMenuItem(menu, "stats", 	"Vos informations"); // Niveau, XP, fatigue, ... 
	
	DisplayMenu(menu, client, 30);
}
void displayBuildMenu(int client, int jobID, int itemID) {
	
	int clientItem[MAX_ITEMS], data[craft_type_max];
	for(int i = 0; i < MAX_ITEMS; i++)
		clientItem[i] = rp_GetClientItem(client, i);
	
	char tmp[64], tmp2[64], prettyJob[2][64];
	bool can;
	ArrayList magic;
	
	Handle menu = CreateMenu(eventArtisanMenu);
	if( jobID == 0 ) {
		SetMenuTitle(menu, "== Artisanat: Construire");
		AddMenuItem(menu, "build -1", "Tous les jobs");
		
		for (int i = 0; i < sizeof(lstJOB); i++) {
			
			rp_GetJobData(lstJOB[i], job_type_name, tmp, sizeof(tmp));
			ExplodeString(tmp, " - ", prettyJob, sizeof(prettyJob), sizeof(prettyJob[]));
			Format(tmp, sizeof(tmp), "build %d", lstJOB[i]);
			AddMenuItem(menu, tmp, prettyJob[1]);
		}
	}
	else if( itemID == 0 ) {
		SetMenuTitle(menu, "== Artisanat: Construire");
		
		for(int i = 0; i < MAX_ITEMS; i++) {
			if( !g_bCanCraft[client][i] && !doRP_CanClientCraftForFree(client, i) )
				continue;
			if( rp_GetItemInt(i, item_type_job_id) != jobID && jobID != -1 )
				continue;
			Format(tmp, sizeof(tmp), "%d", i);
			if( !g_hReceipe.GetValue(tmp, magic) )
				continue;
			
			can = true;
			
			for (int j = 0; j < magic.Length; j++) {
				magic.GetArray(j, data);
				
				if( clientItem[data[craft_raw]] < data[craft_amount] ) {
					can = false;
					break;
				}
			}
			
			rp_GetItemData(i, item_type_name, tmp2, sizeof(tmp2)); 
			if( can || doRP_CanClientCraftForFree(client, i) ) {
				Format(tmp, sizeof(tmp), "build %d %d", jobID, i);
				Format(tmp2, sizeof(tmp2), "[> %s <]", tmp2);
			}
			else {
				Format(tmp, sizeof(tmp), "book %d %d", jobID, i);
				Format(tmp2, sizeof(tmp2), "%s", tmp2);
			}
			
			AddMenuItem(menu, tmp, tmp2);
		}
	}
	else {
		
		rp_GetItemData(itemID, item_type_name, tmp2, sizeof(tmp2));
		Format(tmp2, sizeof(tmp2), "== Artisanat: Construire: %s", tmp2);
		SetMenuTitle(menu, tmp2);
		
		Format(tmp, sizeof(tmp), "%d", itemID);
		if( !g_hReceipe.GetValue(tmp, magic) )
			return;
		
		int min = 999999999, delta;
		float duration = getDuration(client, itemID);
		
		for (int j = 0; j < magic.Length; j++) { // Pour chaque items de la recette:
			magic.GetArray(j, data);
			
			delta = clientItem[data[craft_raw]] / data[craft_amount];
			if( delta < min )
				min = delta;
		}
		
		min += doRP_CanClientCraftForFree(client, itemID);
		
		Format(tmp, sizeof(tmp), "build %d %d %d", jobID, itemID, min);
		Format(tmp2, sizeof(tmp2), "Tout Construire (%d) (%.1fsec)", min, duration*min + (min*GetTickInterval()));
		AddMenuItem(menu, tmp, tmp2);
			
		for (int i = 1; i <= min; i++) {
			Format(tmp, sizeof(tmp), "build %d %d %d", jobID, itemID, i);
			Format(tmp2, sizeof(tmp2), "Construire %d (%.1fsec)", i, duration*i + (i*GetTickInterval()));
			AddMenuItem(menu, tmp, tmp2);
		}
	}
	
	DisplayMenu(menu, client, 30);
}
void displayRecyclingMenu(int client, int itemID) {
	
	if( rp_GetClientInt(client, i_ItemCount) == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez aucun item à recycler.");
		return;
	}
	
	Handle menu = CreateMenu(eventArtisanMenu);
	char tmp[64], tmp2[64];
	
	if( itemID == 0 ) {
		SetMenuTitle(menu, "== Artisanat: Recycler");
		
		for(int i = 0; i < MAX_ITEMS; i++) {
			if( rp_GetClientItem(client, i) <= 0 )
				continue;
			if( getDuration(client, i) <= -0.1 )
				continue;
			
			rp_GetItemData(i, item_type_name, tmp2, sizeof(tmp2));
			Format(tmp, sizeof(tmp), "recycle %d", i);
			Format(tmp2, sizeof(tmp2), "%s (%i)",tmp2,rp_GetClientItem(client, i));
			AddMenuItem(menu, tmp, tmp2);
		}
	}
	else {
		rp_GetItemData(itemID, item_type_name, tmp2, sizeof(tmp2));
		Format(tmp2, sizeof(tmp2), "== Artisanat: Recycler: %s", tmp2);
		SetMenuTitle(menu, tmp2);
		
		float duration = getDuration(client, itemID);
		Format(tmp, sizeof(tmp), "recycle %d %d", itemID, rp_GetClientItem(client, itemID));
		Format(tmp2, sizeof(tmp2), "Tout recycler (%d) (%.1fsec)", rp_GetClientItem(client, itemID), duration*rp_GetClientItem(client, itemID) + (rp_GetClientItem(client, itemID)*GetTickInterval()));
		AddMenuItem(menu, tmp, tmp2);
		
		for(int i = 1; i <= rp_GetClientItem(client, itemID); i++) {
			
			Format(tmp, sizeof(tmp), "recycle %d %d", itemID, i);
			Format(tmp2, sizeof(tmp2), "Recycler %d (%.1fsec)", i, duration*i + (i*GetTickInterval()));
			
			AddMenuItem(menu, tmp, tmp2);
		}
	}
	

	DisplayMenu(menu, client, 30);
}
void displayLearngMenu(char[] type, int client, int jobID, int itemID) {
	
	char tmp[64], tmp2[64], prettyJob[2][64];
	ArrayList magic;
	Handle menu = CreateMenu(eventArtisanMenu);
	int count = rp_GetClientInt(client, i_ArtisanPoints);
	int data[craft_type_max];
	bool can, skip = StrEqual(type, "learn") ? false : true;
	if( !skip && count == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez aucun point d'apprentissage. Pour en avoir vous pouvez gagner un niveau d'artisanat ou acheter et lire un livre de sagesse.");
		return;
	}
	
	if( !skip )
		SetMenuTitle(menu, "== Artisanat: Apprendre (%d)", count);
	else
		SetMenuTitle(menu, "== Artisanat: Livre des recettes", count);
	
	if( jobID == 0 ) {
		for (int i = 0; i < sizeof(lstJOB); i++) {
			
			rp_GetJobData(lstJOB[i], job_type_name, tmp, sizeof(tmp));
			ExplodeString(tmp, " - ", prettyJob, sizeof(prettyJob), sizeof(prettyJob[]));
			Format(tmp, sizeof(tmp), "%s %d", type, lstJOB[i]);
			AddMenuItem(menu, tmp, prettyJob[1]);
		}
	}
	else if( itemID == 0 ) {
		for(int i = 0; i < MAX_ITEMS; i++) {
			if( g_bCanCraft[client][i]  && !skip )
				continue;
//			if( !g_bCanCraft[client][i]  && skip )
//				continue;
			if( rp_GetItemInt(i, item_type_job_id) != jobID )
				continue;
			Format(tmp, sizeof(tmp), "%d", i);
			if( !g_hReceipe.GetValue(tmp, magic) )
				continue;
			can = true;
			if( count*250 < rp_GetItemInt(i, item_type_prix) && !skip )
				can = false;
			
			rp_GetItemData(i, item_type_name, tmp2, sizeof(tmp2));
			if( StrContains(tmp2, "MISSING") == 0 )
				continue;
			Format(tmp, sizeof(tmp), "%s %d %d", type, jobID, i);
			Format(tmp2, sizeof(tmp2), "%s (%i)",tmp2, RoundToCeil(float(rp_GetItemInt(i, item_type_prix)) / 250.0));
			
			AddMenuItem(menu, tmp, tmp2, (can?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED));
		}
	}
	else {
		rp_GetItemData(itemID, item_type_name, tmp, sizeof(tmp));
		SetMenuTitle(menu, "== Artisanat: Livre: %s", tmp);
		
		Format(tmp, sizeof(tmp), "%d", itemID);
		g_hReceipe.GetValue(tmp, magic);
		
		for (int j = 0; j < magic.Length; j++) { // Pour chaque items de la recette:
			magic.GetArray(j, data);
			
			rp_GetItemData(data[craft_raw], item_type_name, tmp, sizeof(tmp));
			Format(tmp2, sizeof(tmp2), "%dx%s (%d%%)", data[craft_amount], tmp, data[craft_rate]);
			AddMenuItem(menu, tmp2, tmp2, ITEMDRAW_DISABLED);
		}
		if( !skip )  {
			Format(tmp, sizeof(tmp), "%s %d %d 1", type, jobID, itemID);
			AddMenuItem(menu, tmp, "Apprendre");
		}
	}
	
	DisplayMenu(menu, client, 30);
}
void displayStatsMenu(int client) {
	Handle menu = CreateMenu(eventArtisanMenu);
	SetMenuTitle(menu, "== Artisanat: Votre profil");
	
	addStatsToMenu(client, menu);
	
	char tmp[64];
	
	if( g_flClientBook[client][book_xp] > GetTickedTime() ) {
		Format(tmp, sizeof(tmp), "Bonus: +50%% d'expérience: %.1f minute(s).", (g_flClientBook[client][book_xp] - GetTickedTime())/60.0);
		AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	}
	if( g_flClientBook[client][book_sleep] > GetTickedTime() ) {
		Format(tmp, sizeof(tmp), "Bonus: -50%% de fatigue: %.1f minute(s).", (g_flClientBook[client][book_sleep] - GetTickedTime()) / 60.0);
		AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	}
	if( g_flClientBook[client][book_focus] > GetTickedTime() ) {
		Format(tmp, sizeof(tmp), "Bonus: +50%% de concentration: %.1f minute(s).", (g_flClientBook[client][book_focus] - GetTickedTime()) / 60.0);
		AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	}
	if( g_flClientBook[client][book_speed] > GetTickedTime() ) {
		Format(tmp, sizeof(tmp), "Bonus: +100%% de vitesse: %.1f minute(s).", (g_flClientBook[client][book_speed] - GetTickedTime()) / 60.0);
		AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	}
	if( g_flClientBook[client][book_luck] > GetTickedTime() ) {
		Format(tmp, sizeof(tmp), "Bonus: +5%% de chance: %.1f minute(s).", (g_flClientBook[client][book_luck] - GetTickedTime()) / 60.0);
		AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	}
	if( g_flClientBook[client][book_steal] > GetTickedTime() ) {
		Format(tmp, sizeof(tmp), "Protection vol d'inventaire: %.1f minute(s).", (g_flClientBook[client][book_steal] - GetTickedTime()) / 60.0);
		AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	}
	
	
	DisplayMenu(menu, client, 30);
}
public int eventArtisanMenu(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventArtisanMenu");
	#endif
	
	if( action == MenuAction_Select ) {
		char options[64], buffer[4][16];
		ArrayList magic;
		
		GetMenuItem(menu, param2, options, sizeof(options));
		ExplodeString(options, " ", buffer, sizeof(buffer), sizeof(buffer[]));
		
		if( StrContains(options, "build", false) == 0 ) {
			if( StringToInt(buffer[3]) == 0 )
				displayBuildMenu(client, StringToInt(buffer[1]), StringToInt(buffer[2]));
			else if( g_hReceipe.GetValue(buffer[2], magic) )		
				startBuilding(client, StringToInt(buffer[2]), StringToInt(buffer[3]), StringToInt(buffer[3]), 1);
		}
		else if( StrContains(options, "recycl", false) == 0 ) {
			if( StringToInt(buffer[2]) == 0 )
				displayRecyclingMenu(client, StringToInt(buffer[1]));
			else if( g_hReceipe.GetValue(buffer[1], magic) )
				startBuilding(client, StringToInt(buffer[1]), StringToInt(buffer[2]), StringToInt(buffer[2]), -1);
		}
		else if( StrContains(options, "learn", false) == 0 ) {
			if( StringToInt(buffer[3]) == 0 )
				displayLearngMenu("learn", client, StringToInt(buffer[1]), StringToInt(buffer[2]));
			else {
				int itemID = StringToInt(buffer[2]);
				int count = rp_GetClientInt(client, i_ArtisanPoints);
				if( count*250 < rp_GetItemInt(itemID, item_type_prix) ) {
					return;
				}
				
				g_bCanCraft[client][itemID] = true;
				rp_SetClientInt(client, i_ArtisanPoints, count - RoundToCeil(float(rp_GetItemInt(itemID, item_type_prix)) / 250.0));
				char query[1024], szSteamID[32];
				GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
				Format(query, sizeof(query), "INSERT INTO `rp_craft_book` (`steamid`, `itemid`) VALUES ('%s', '%d');", szSteamID, itemID);
				SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
			}
		}
		else if( StrContains(options, "book", false) == 0 ) {
			if( StringToInt(buffer[3]) == 0 )
				displayLearngMenu("book", client, StringToInt(buffer[1]), StringToInt(buffer[2]));
		}
		else if( StrContains(options, "stats", false) == 0 ) {
			displayStatsMenu(client);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
// ----------------------------------------------------------------------------
void startBuilding(int client, int itemID, int total, int amount, int positive) {
	
	float duration = getDuration(client, itemID);
	g_bInCraft[client] = true;
//	ServerCommand("sm_effect_particles %d dust_embers %f facemask", client, duration);
	
	MENU_ShowCraftin(client, total, amount, positive, 0);
	
	if( amount > 0 && duration >= -0.0001 ) {
		Handle dp;
		CreateDataTimer(duration, stopBuilding, dp, TIMER_DATA_HNDL_CLOSE|TIMER_REPEAT);
		WritePackCell(dp, client);
		WritePackCell(dp, itemID);
		WritePackCell(dp, total);
		WritePackCell(dp, amount);
		WritePackCell(dp, positive);
		WritePackCell(dp, 0);
	}
}
public Action stopBuilding(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int itemID = ReadPackCell(dp);
	int total = ReadPackCell(dp);
	int amount = ReadPackCell(dp);
	int positive = ReadPackCell(dp);
	int fatigue = ReadPackCell(dp);
	bool failed = false;
	bool free = (doRP_CanClientCraftForFree(client, itemID) > 0);
	
	if( !IsValidClient(client) ) {
		return Plugin_Stop;
	}
	if( !isNearTable(client) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes plus à coté d'une table de craft.");
		g_bInCraft[client] = false;
		return Plugin_Stop;
	}
	
	int pc = RoundFloat(rp_GetClientFloat(client, fl_ArtisanFatigue) * 100.0) * RoundFloat(rp_GetClientFloat(client, fl_ArtisanFatigue) * 100.0);
	if( Math_GetRandomInt(1, 100*100) <= pc ) {
		
		fatigue++;
		failed = true;
		
		if( g_flClientBook[client][book_focus] > GetTickedTime() && Math_GetRandomInt(1, 4) == 4 ) {
			fatigue--;
			failed = false;
		}
	}
	
	ArrayList magic;
	int data[craft_type_max];
	char tmp[64];
	Format(tmp, sizeof(tmp), "%d", itemID);
	
	if( !g_hReceipe.GetValue(tmp, magic) ) {
		g_bInCraft[client] = false;
		return Plugin_Stop;
	}
		
	if( positive > 0 ) {
		if( !free ) {
			for (int j = 0; j < magic.Length; j++) { // Pour chaque items de la recette:
				magic.GetArray(j, data);
				
				if( data[craft_amount] > rp_GetClientItem(client,data[craft_raw]) ) {
					g_bInCraft[client] = false;
					return Plugin_Stop;
				}
			}
		}
	}
	else {
		if( rp_GetClientItem(client, itemID) <= 0 ) {
			g_bInCraft[client] = false;
			return Plugin_Stop;
		}
	}
	int level = rp_GetClientInt(client, i_ArtisanLevel);
	float flFatigue = rp_GetClientFloat(client, fl_ArtisanFatigue);
	float f = float(rp_GetItemInt(itemID, item_type_prix)) / 41100.0 / Logarithm(float(level+1), 1.33);
	if( g_flClientBook[client][book_sleep] > GetTickedTime() )
		f -= (f / 2.0);
	
	flFatigue += f;
	
	if( flFatigue > 1.0 )
		flFatigue = 1.0;
	rp_SetClientFloat(client, fl_ArtisanFatigue, flFatigue);
	
	if( positive > 0 ) { // Craft
		if( !failed ) { // Si on échoue pas on give l'item
			rp_ClientGiveItem(client, itemID, positive);
			doRP_ClientCraftOver(client, itemID);
		}
		
		if( g_flClientBook[client][book_luck] > GetTickedTime() && Math_GetRandomInt(0, 1000) < 50 )
			rp_ClientGiveItem(client, itemID, positive);
		
		for (int i = 0; i < magic.Length; i++) {  // Pour chaque items de la recette:
			magic.GetArray(i, data);
				
			ClientGiveXP(client, rp_GetItemInt(data[craft_raw], item_type_prix));
			if( !free )
				rp_ClientGiveItem(client, data[craft_raw], -data[craft_amount]);		
		}
	}
	else if( !failed ) { // Recyclage, si on le rate pas on prend l'item.
		rp_ClientGiveItem(client, itemID, positive);
		if( g_flClientBook[client][book_luck] > GetTickedTime() && Math_GetRandomInt(0, 1000) < 50 )
			rp_ClientGiveItem(client, itemID, -positive);
		
		int focus = 0;
		if( g_flClientBook[client][book_focus] > GetTickedTime() )
			focus += 25;
		
		for (int i = 0; i < magic.Length; i++) {  // Pour chaque items de la recette:
			magic.GetArray(i, data);
				
			for (int j = 0; j < data[craft_amount]; j++) { // Pour chaque quantité nécessaire de la recette
				if( (data[craft_rate]+level+focus) >= Math_GetRandomInt(0, 100) ) { // De facon aléatoire
					ClientGiveXP(client, rp_GetItemInt(data[craft_raw], item_type_prix));
					rp_ClientGiveItem(client, data[craft_raw]);
				}
			}	
		}
	}
	
	ResetPack(dp);
	WritePackCell(dp, client);
	WritePackCell(dp, itemID);
	WritePackCell(dp, total);
	WritePackCell(dp, --amount);
	WritePackCell(dp, positive);
	WritePackCell(dp, fatigue);
	
	MENU_ShowCraftin(client, total, amount, positive, fatigue);
	
	if( amount <= 0 ) {
		g_bInCraft[client] = false;
		return Plugin_Stop;
	}
//	ServerCommand("sm_effect_particles %d dust_embers %f facemask", client, getDuration(client, itemID));
	
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
void MENU_ShowCraftin(int client, int total, int amount, int positive, int fatigue) {
	char tmp[64];
	Handle menu = CreateMenu(eventArtisanMenu);
	if( positive > 0 )
		SetMenuTitle(menu, "== Artisanat: Construction");
	else
		SetMenuTitle(menu, "== Artisanat: Recyclage");
	
	float percent = (float(total) - float(amount)) / float(total);
	
	rp_Effect_LoadingBar(tmp, sizeof(tmp), percent );
	AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	
	Format(tmp, sizeof(tmp), "%d / %d réussi%s, %d échec%s", total-amount-fatigue, total, total-amount-fatigue>1?"s":"", fatigue, fatigue > 1 ? "s":"");
	AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	
	addStatsToMenu(client, menu);
	
	DisplayMenu(menu, client, 1);
}
float getDuration(int client, int itemID) {
	if( rp_GetItemInt(itemID, item_type_job_id) == 91 )
		return -1.0;
	char tmp[12];
	int data[craft_type_max];
	Format(tmp, sizeof(tmp), "%d", itemID);
	
	ArrayList magic;
	if( !g_hReceipe.GetValue(tmp, magic) )
		return -1.0;
	
	
	float duration = 0.0;
	for (int i = 0; i < magic.Length; i++) {
		magic.GetArray(i, data);
		duration += 0.02 * data[craft_amount];
	}
	
	if( g_flClientBook[client][book_speed] > GetTickedTime() )
		duration -= (duration / 2.0);
	
	return duration;
}
int getNextLevel(int level) {
	if( level >= 75 )
		return level * level * 750;
	else if( level >= 50 )
		return RoundToFloor(Pow(float(level), 1.8) * 750.0);
	else
		return RoundToFloor(Pow(float(level), 1.6) * 750.0);
}
int ClientGiveXP(int client, int xp) {
	if( g_flClientBook[client][book_xp] > GetTickedTime() )
		xp += (xp / 2);
	
	int baseXP = rp_GetClientInt(client, i_ArtisanXP) + xp;
	int baseLVL = rp_GetClientInt(client, i_ArtisanLevel);
	int basePoint = rp_GetClientInt(client, i_ArtisanPoints);
	
	while( baseXP >= getNextLevel(baseLVL) ) {
		baseXP -= getNextLevel(baseLVL);
		baseLVL++;
		basePoint += Math_GetRandomInt(1, 3);
	}
	
	rp_SetClientInt(client, i_ArtisanXP, baseXP);
	rp_SetClientInt(client, i_ArtisanLevel, baseLVL);
	rp_SetClientInt(client, i_ArtisanPoints, basePoint);
	
}
bool isNearTable(int client) {
	char classname[65];
	int target = rp_GetClientTarget(client);
	if( IsValidEdict(target) && IsValidEntity(target) ) {
		GetEdictClassname(target, classname, sizeof(classname));
		if( StrContains(classname, "rp_table") == 0 && rp_IsEntitiesNear(client, target, true) )
			return true;
	}
	return false;
}
void addStatsToMenu(int client, Handle menu) {
	char tmp[128], tmp2[32];
	Format(tmp, sizeof(tmp), "Niveau: %d", rp_GetClientInt(client, i_ArtisanLevel));
	AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	
	float pc = rp_GetClientInt(client, i_ArtisanXP) / float(getNextLevel(rp_GetClientInt(client, i_ArtisanLevel)));
	rp_Effect_LoadingBar(tmp2, sizeof(tmp2),  pc );
	Format(tmp, sizeof(tmp), "Expérience: %s %.1f%%", tmp2, pc*100.0 );
	AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	
	tmp2[0] = 0; pc = rp_GetClientFloat(client, fl_ArtisanFatigue);
	rp_Effect_LoadingBar(tmp2, sizeof(tmp2),  pc );
	Format(tmp, sizeof(tmp), "Fatigue: %s %.1f%%", tmp2, pc*100.0 );
	AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	
	Format(tmp, sizeof(tmp), "Points de compétence: %d", rp_GetClientInt(client, i_ArtisanPoints));
	AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
}
// ----------------------------------------------------------------------------
int BuidlingTABLE(int client) {
	#if defined DEBUG
	PrintToServer("BuidlingTABLE");
	#endif
	
	if( !rp_IsBuildingAllowed(client) )
		return 0;	
	
	char classname[64], tmp[64];
	
	Format(classname, sizeof(classname), "rp_table", client);	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	int count;
	for(int i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, sizeof(tmp));
		
		if( StrEqual(classname, tmp) && rp_GetBuildingData(i, BD_owner) == client ) {
			count++;
			if( count >= 1 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà une table de placée.");
				return 0;
			}
		}
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Construction en cours...");

	EmitSoundToAllAny("player/ammo_pack_use.wav", client);
	
	int ent = CreateEntityByName("prop_physics_override");
	count = Math_GetRandomInt(0, 1);
	DispatchKeyValue(ent, "classname", classname);
	if( count )
		DispatchKeyValue(ent, "model", MODEL_TABLE1);
	else
		DispatchKeyValue(ent, "model", MODEL_TABLE2);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	if( count )
		DispatchKeyValue(ent, "model", MODEL_TABLE1);
	else
		DispatchKeyValue(ent, "model", MODEL_TABLE2);
	
	SetEntProp( ent, Prop_Data, "m_iHealth", 10000);
	SetEntProp( ent, Prop_Data, "m_takedamage", 0);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	float vecAngles[3]; GetClientEyeAngles(client, vecAngles); vecAngles[0] = vecAngles[2] = 0.0;
	TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
	
	SetEntityRenderMode(ent, RENDER_NONE);
	ServerCommand("sm_effect_fading \"%i\" \"3.0\" \"0\"", ent);
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	
	CreateTimer(3.0, BuildingTABLE_post, ent);
	rp_SetBuildingData(ent, BD_owner, client);
	return ent;
}
public Action BuildingTABLE_post(Handle timer, any entity) {
	#if defined DEBUG
	PrintToServer("BuildingTABLE_post");
	#endif
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	rp_Effect_BeamBox(client, entity, NULL_VECTOR, 255, 255, 0);
	
	SetEntProp(entity, Prop_Data, "m_takedamage", 2);
	HookSingleEntityOutput(entity, "OnBreak", BuildingTABLE_break);
	return Plugin_Handled;
}
public void BuildingTABLE_break(const char[] output, int caller, int activator, float delay) {
	#if defined DEBUG
	PrintToServer("BuildingTABLE_break");
	#endif
	
	int owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
	if( IsValidClient(owner) ) {
		CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Votre table de craft a été détruite.");
	}
}
