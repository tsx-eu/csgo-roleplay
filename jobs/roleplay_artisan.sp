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

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

StringMap g_hReceipe;

//#define DEBUG

public Plugin myinfo = {
	name = "Jobs: ARTISAN", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Artisan",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

enum craft_type {
	craft_raw,
	craft_amount,
	craft_rate,
	craft_type_max
}
// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	SQL_TQuery(rp_GetDatabase(), SQL_LoadReceipe, "SELECT `itemid`, `raw`, `amount`, REPLACE(`extra_cmd`, 'rp_item_primal ', '') `rate` FROM `rp_csgo`.`rp_craft` C INNER JOIN `rp_items` I ON C.`raw`=I.`id` ORDER BY `itemid`, `raw`", 0, DBPrio_Low);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
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
	
	rp_HookEvent(client, RP_OnPlayerUse, fwdUse);
}
public Action fwdUse(int client) {
	if( rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) == 31 ) {
		if( rp_IsValidDoor(GetClientTarget(client)) )
			return Plugin_Continue;
		
		displayArtisanMenu(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
void displayArtisanMenu(int client) {
	#if defined DEBUG
	PrintToServer("displayArtisanMenu");
	#endif
	
	Handle menu = CreateMenu(eventArtisanMenu);
	SetMenuTitle(menu, "== Artisanat ==");
	
	AddMenuItem(menu, "build", 	"Constuire");
	AddMenuItem(menu, "recycl", "Recycler");
	AddMenuItem(menu, "learn", 	"Apprendre");
	

	DisplayMenu(menu, client, 30);
}
void displayBuildMenu(int client, int itemID) {
	if( rp_GetClientInt(client, i_ItemCount) == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez aucune matière première.");
		return;
	}
	
	int clientItem[MAX_ITEMS];
	for(int i = 0; i < MAX_ITEMS; i++) {
		clientItem[i] = rp_GetClientItem(client, i);
	}
	
	char tmp[64], tmp2[64];
	int data[craft_type_max];
	bool can;
	ArrayList magic;
	
	Handle menu = CreateMenu(eventArtisanMenu);
	if( itemID == 0 ) {
		SetMenuTitle(menu, "== Artisanat: Constuire");
		
		for(int i = 0; i < MAX_ITEMS; i++) {
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
			
			if( can ) {
				rp_GetItemData(i, item_type_name, tmp2, sizeof(tmp2));
				Format(tmp, sizeof(tmp), "build %d", i);
				AddMenuItem(menu, tmp, tmp2);
			}
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
		float duration = getDuration(itemID);
		
		for (int j = 0; j < magic.Length; j++) { // Pour chaque items de la recette:
			magic.GetArray(j, data);
			
			delta = clientItem[data[craft_raw]] / data[craft_amount];
			if( delta < min )
				min = delta;
		}
		
		for (int i = 1; i <= min; i++) {
			Format(tmp, sizeof(tmp), "build %d %d", itemID, i);
			Format(tmp2, sizeof(tmp2), "Constuire %d (%.1fsec)", i, duration*i);
			
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
			if( getDuration(i) <= -0.1 )
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
		
		float duration = getDuration(itemID);
		Format(tmp, sizeof(tmp), "recycle %d %d", itemID, rp_GetClientItem(client, itemID));
		Format(tmp2, sizeof(tmp2), "Tout recycler (%.1fsec)", duration*rp_GetClientItem(client, itemID));
		AddMenuItem(menu, tmp, tmp2);
		
		for(int i = 1; i <= rp_GetClientItem(client, itemID); i++) {
			
			Format(tmp, sizeof(tmp), "recycle %d %d", itemID, i);
			Format(tmp2, sizeof(tmp2), "Recycler %d (%.1fsec)", i, duration*i);
			
			AddMenuItem(menu, tmp, tmp2);
		}
	}
	

	DisplayMenu(menu, client, 30);
}
public int eventArtisanMenu(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventArtisanMenu");
	#endif
	
	if( action == MenuAction_Select ) {
		char options[64], buffer[3][16];
		ArrayList magic;
		int data[craft_type_max];
		
		GetMenuItem(menu, param2, options, sizeof(options));
		ExplodeString(options, " ", buffer, sizeof(buffer), sizeof(buffer[]));
		PrintToChat(client, "%s-->%s,%s,%s", options, buffer[0], buffer[1], buffer[2]);
		
		if( StrContains(options, "build", false) == 0 ) {
			if( StringToInt(buffer[2]) == 0 )
				displayBuildMenu(client, StringToInt(buffer[1]));
			else if( g_hReceipe.GetValue(buffer[1], magic) ) {
				
				int itemID = StringToInt(buffer[1]);
				int amount = StringToInt(buffer[2]);
				float duration = getDuration(itemID) * float(amount);
				
				rp_GetItemData(itemID, item_type_name, options, sizeof(options));
				
				
				int min = 999999999, delta;
				
				for (int j = 0; j < magic.Length; j++) { // Pour chaque items de la recette:
					magic.GetArray(j, data);
					
					delta = rp_GetClientItem(client,data[craft_raw]) / data[craft_amount];
					if( delta < min )
						min = delta;
				}
				if( min < amount )
					amount = min;
				
				rp_ClientGiveItem(client, StringToInt(buffer[1]), amount);
				for (int i = 0; i < magic.Length; i++) {  // Pour chaque items de la recette:
					magic.GetArray(i, data);
					rp_ClientGiveItem(client, data[craft_raw], -(data[craft_amount]*amount));
				}
				
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous commencer à construire %dx %s. Cette opération va durer %.1f seconde%s.", amount, options, duration, duration>=2.0?"s":"");
				ServerCommand("sm_effect_panel %d %f \"Création de %dx %s\"", client, duration, amount, options);
				rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, duration);
				
			}
		}
		else if( StrContains(options, "recycl", false) == 0 ) {
			if( StringToInt(buffer[2]) == 0 )
				displayRecyclingMenu(client, StringToInt(buffer[1]));
			else if( g_hReceipe.GetValue(buffer[1], magic) ) {
				
				int itemID = StringToInt(buffer[1]);
				int amount = StringToInt(buffer[2]);
				if( amount > rp_GetClientItem(client, itemID) )
					amount = rp_GetClientItem(client, itemID);
				float duration = getDuration(itemID) * float(amount);
				
				rp_GetItemData(itemID, item_type_name, options, sizeof(options));
				rp_ClientGiveItem(client, StringToInt(buffer[1]), -amount);
				
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous commencer à recycler %dx %s. Cette opération va durer %.1f seconde%s.", amount, options, duration, duration>=2.0?"s":"");
				
				for (int i = 0; i < magic.Length; i++) {  // Pour chaque items de la recette:
					magic.GetArray(i, data);
					for (int j = 0; j < data[craft_amount]; j++) { // Pour chaque quantité nécessaire de la recette
						for (int k = 0; k < amount; k++) { // On multiplie par la quantité
							if( data[craft_rate] >= Math_GetRandomInt(0, 100) ) // De facon aléatoire
								rp_ClientGiveItem(client, data[craft_raw]);
						}
					}
				}
				
				ServerCommand("sm_effect_panel %d %f \"Recyclage de %dx %s\"", client, duration, amount, options);
				rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, duration);
				return;
			}
		}
		
		else if( StrEqual(options, "learn", false) ) {
			
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public Action fwdFrozen(int client, float& speed, float& gravity) {
	speed = 0.0;
	gravity = 0.0; 
	return Plugin_Stop;
}
float getDuration(int itemID) {
	char tmp[12];
	int data[craft_type_max];
	Format(tmp, sizeof(tmp), "%d", itemID);
	
	ArrayList magic;
	if( !g_hReceipe.GetValue(tmp, magic) )
		return -1.0;
	
	
	float duration = 0.0;
	for (int i = 0; i < magic.Length; i++) {
		magic.GetArray(i, data);
		duration += 0.01 * data[craft_amount];
	}
	return duration;
}
