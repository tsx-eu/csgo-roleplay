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
#include <smlib>

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG

public Plugin myinfo = {
	name = "Utils: VoiceProximity", author = "KoSSoLaX",
	description = "RolePlay - Utils: VoiceProximity",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerHear, fwdHear);
}
public void OnClientDisconnect(int client) {
	rp_UnhookEvent(client, RP_OnPlayerHear, fwdHear);
}

public Action fwdHear(int client, int target, float& dist) {
	
	int Czone = rp_GetPlayerZone(client), Ctype = rp_GetZoneInt(Czone, zone_type_type);
	int Tzone = rp_GetPlayerZone(target), Ttype = rp_GetZoneInt(Tzone, zone_type_type), Tbit = rp_GetZoneBit(Tzone);
	
	if( Tbit & BITZONE_JAIL || Tbit & BITZONE_HAUTESECU ) { 
		return Plugin_Stop;
	}
	
	if( Czone > 0 && Tzone > 0 && Ctype != Ttype ) {
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
