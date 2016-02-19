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

// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	SQL_TQuery(rp_GetDatabase(), SQL_LoadReceipe, "SELECT `itemid`, `raw`, `amount` FROM `rp_csgo`.`rp_craft` ORDER BY `itemid`, `raw`;", 0, DBPrio_Low);
	
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
	
	int data[2];
	char itemID[12];
	ArrayList magic;
	
	if( SQL_FetchRow(hQuery) ) {
		SQL_FetchString(hQuery, 0, itemID, sizeof(itemID));
		data[0] = SQL_FetchInt(hQuery, 1);
		data[1] = SQL_FetchInt(hQuery, 2);
		
		if( !g_hReceipe.GetValue(itemID, magic) )
			magic = new ArrayList(sizeof(data), 32);
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
		
		Format(tmp, sizeof(tmp), "recycle %d %d", itemID, rp_GetClientItem(client, itemID));
		AddMenuItem(menu, tmp, "Tout recycler");
		
		for(int i = 1; i <= rp_GetClientItem(client, itemID); i++) {
			
			Format(tmp, sizeof(tmp), "recycle %d %d", itemID, i);
			Format(tmp2, sizeof(tmp2), "Recycler %d", i);
			
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
		int data[2];
		
		GetMenuItem(menu, param2, options, sizeof(options));
		
		if( StrEqual(options, "build", false) ) {
			
		}
		else if( StrContains(options, "recycl", false) == 0 ) {
			ExplodeString(options, " ", buffer, sizeof(buffer), sizeof(buffer[]));
			
			if( StringToInt(buffer[2]) != 0 )
				displayRecyclingMenu(client, StringToInt(buffer[1]));
			else if( g_hReceipe.GetValue(buffer[1], magic) ) {
				
				rp_GetItemData(StringToInt(buffer[1]), item_type_name, options, sizeof(options));
				PrintToChatAll("pour démonter %s il faut: ", options);
				
				for (int i = 0; i < magic.Length; i++) {
					magic.GetArray(i, data);
					
					rp_GetItemData(data[0], item_type_name, options, sizeof(options));
					PrintToChatAll("%d %s", data[1], options);
				}
			}
			PrintToChatAll("%s %s %s", options, buffer[1], buffer[2]);
		}
		
		else if( StrEqual(options, "learn", false) ) {
			
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
