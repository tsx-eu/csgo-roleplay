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
#include <smlib>
#include <colors_csgo>
#include <basecomm>
#include <topmenus>

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define	MAX_ENTITIES	2048

public Plugin myinfo = {
	name = "Utils: Perquisition", author = "KoSSoLaX",
	description = "RolePlay - Utils: Perquisition",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};
public void OnPluginStart() {	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrEqual(command, "perquisition") ) {
		return Cmd_Perquiz(client);
	}
	return Plugin_Continue;
}
public Action Cmd_Perquiz(int client) {
	
	if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 && GetClientTeam(client) != CS_TEAM_CT ) {
		ACCESS_DENIED(client);
	}
	
	float dst[3];
	char tmp[64], tmp2[64];
	rp_GetClientTarget(client, dst);
	rp_GetZoneData(rp_GetZoneFromPoint(dst), zone_type_type, tmp, sizeof(tmp));
	if( strlen(tmp) == 0 )
		return Plugin_Handled;
	
	
	Menu menu = new Menu(MenuPerquiz);
	menu.SetTitle("Quel est le motif de perquisition?\n ");
	Format(tmp2, sizeof(tmp2), "search %s", tmp);	menu.AddItem(tmp2, "Un recherché");
	Format(tmp2, sizeof(tmp2), "trafic %s", tmp);	menu.AddItem(tmp2, "Du traffic illégal", rp_GetClientJobID(client) == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
	
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}
public int MenuPerquiz(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64], expl[4][32], tmp[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		ExplodeString(options, " ", expl, sizeof(expl), sizeof(expl[]));
		
		float dst[3];
		rp_GetClientTarget(client, dst);
		int zone = rp_GetZoneFromPoint(dst);
		rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
		if( !StrEqual(tmp, expl[1]) )
			return 0;
		
		if( StrEqual(expl[0], "search") ) {
			
			if( StringToInt(expl[2]) == 0 ) {
				Menu subMenu = new Menu(MenuPerquiz);
				subMenu.SetTitle("Qui est recherché?\n ");
				
				for (int i = 1; i <= MaxClients; i++) {
					if( !IsValidClient(i) || !IsPlayerAlive(i) || i == client )
						continue;
					
					rp_GetZoneData(rp_GetPlayerZone(i), zone_type_type, options, sizeof(options));
					if( !StrEqual(options, expl[1]) )
						continue;
					
					Format(options, sizeof(options), "search %s %d", expl[1], i);
					PrintToChatAll(options);
					Format(tmp, sizeof(tmp), "%N", i);
					
					subMenu.AddItem(options, tmp);
				}
				
				subMenu.Display(client, MENU_TIME_FOREVER);
			}
			else {
				START_PERQUIZ(client, zone, StringToInt(expl[2]));
			}
		}
		else if( StrEqual(expl[0], "trafic") ) {
			int weapon, machine, plant;
			
			for (int i = MaxClients; i <= MAX_ENTITIES; i++) {
				if( !IsValidEdict(i) || !IsValidEntity(i) )
					continue;
				
				rp_GetZoneData(rp_GetPlayerZone(i), zone_type_type, options, sizeof(options));
				if( !StrEqual(options, expl[1]) )
					continue;
				
				GetEdictClassname(i, options, sizeof(options));
				
				if( StrContains(options, "weapon_") == 0 && StrContains(options, "knife") == -1 )
					weapon++;
				if( StrContains(options, "rp_plant") == 0 )
					plant++;
				if( StrContains(options, "rp_cash") == 0 )
					machine++;
				if( StrContains(options, "rp_bigcash") == 0 )
					machine+=15;
			}
			
			if( weapon > 3 || machine > 2 || plant > 2 )
				START_PERQUIZ(client, zone, 0);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return 0;
}
void START_PERQUIZ(int client, int zone, int type) {
	
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	PrintToChatAll("%N veut faire une perquiz dans %s pour %d", client, tmp, type);
}
