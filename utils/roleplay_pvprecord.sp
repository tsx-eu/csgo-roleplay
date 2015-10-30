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
#include <botmimic>
#include <colors_csgo>

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
Handle g_vCapture = INVALID_HANDLE;
bool g_bEnabled = false;
public Plugin myinfo = {
	name = "Utils: Pvp Record", author = "KoSSoLaX",
	description = "RolePlay - Utils: Pvp Record",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnConfigsExecuted() {
	g_vCapture =  FindConVar("rp_capture");
	HookConVarChange(g_vCapture, OnCvarChange);
}
public void OnCvarChange(Handle cvar, const char[] oldVal, const char[] newVal) {
	#if defined DEBUG
	PrintToServer("OnCvarChange");
	#endif
	
	if( cvar == g_vCapture ) {
		if( StrEqual(oldVal, "none") && StrEqual(newVal, "active") )
			g_bEnabled = true;
		else 
			g_bEnabled = false;
	}
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerZoneChange, fwdOnZoneChange);
}
public Action fwdOnZoneChange(int client, int oldZone, int newZone) {

	bool oldPVP = view_as<bool>(rp_GetZoneBit(oldZone) & BITZONE_PVP);
	bool newPVP = view_as<bool>(rp_GetZoneBit(newZone) & BITZONE_PVP);
	
	
	if( g_bEnabled && oldPVP && !newPVP ) {		
		char name[128], today[32];
		FormatTime(today, sizeof(today), "%F");
		Format(name, sizeof(name), "pvp_%s_%d-%d", today, client, GetGameTickCount());
		BotMimic_StartRecording(client, name);
		
		PrintToConsole(client, "[TSX-RP] [PVP] Vos mouvements sont maintenant enregistré.");
	}
	else if( newPVP && !oldPVP && BotMimic_IsPlayerRecording(client) ) {
		BotMimic_StopRecording(client, true);
		PrintToConsole(client, "[TSX-RP] [PVP] Vos mouvements ne sont plus enregistré.");
	}
	
	return Plugin_Continue;
}