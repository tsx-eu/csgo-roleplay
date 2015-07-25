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
#include <colors_csgo>
#include <basecomm>

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG

public Plugin myinfo = {
	name = "Utils: VoiceProximity", author = "KoSSoLaX",
	description = "RolePlay - Utils: VoiceProximity",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}

public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerHear, fwdHear);
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public void OnClientDisconnect(int client) {
	rp_UnhookEvent(client, RP_OnPlayerHear, fwdHear);
	rp_UnhookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public Action fwdCommand(int client, char[] command, char[] arg) {
	#if defined DEBUG
	PrintToServer("fwdCommand");
	#endif
	if( StrEqual(command, "me") || StrEqual(command, "annonce") ) {
		
		if( !rp_GetClientBool(client, b_IsNoPyj) ) {
			ACCESS_DENIED(client);
		}
		if( BaseComm_IsClientGagged(client) || rp_GetClientBool(client, b_IsMuteGlobal) ) {
			PrintToChat(client, "\x04[\x02MUTE\x01]\x01: Vous avez été interdit d'utiliser le chat global.");
			return Plugin_Handled;
		}
		if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 ) {
			if( !rp_GetClientBool(client, b_MaySteal) ) {
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez attendre encore quelques secondes, avant d'utiliser à nouveau le chat annonce.");
			}
			
			rp_SetClientBool(client, b_MaySteal, false);
			CreateTimer(10.0, AllowStealing, client);
		}

		CPrintToChatAll("{lightblue}%N{default} ({olive}ANNONCE{default}): %s", client, arg);
		LogToGame("[TSX-RP] [ANNONCES] %L: %s", client, arg);

		return Plugin_Handled;
	}
	else if( StrEqual(command, "c") || StrEqual(command, "coloc") || StrEqual(command, "colloc") ) {
		if( rp_GetClientInt(client, i_AppartCount) == 0 ) {
			ACCESS_DENIED(client);
		}
		if( BaseComm_IsClientGagged(client) || rp_GetClientBool(client, b_IsMuteLocal) ) {
			PrintToChat(client, "\x04[\x02MUTE\x01]\x01: Vous avez été interdit d'utiliser le chat local.");
			return Plugin_Handled;
		}
		
		for (int i = 1; i <= 48; i++) {
			if( !rp_GetClientKeyAppartement(client, i) )
				continue;
			
			for(int j=1; j<=MaxClients; j++) {
				if( !IsValidClient(j) )
					continue;
				if( !rp_GetClientKeyAppartement(j, i) )
					continue;
					
				CPrintToChatEx(j, client, "{lightblue}%N{default} ({purple}COLOC{default}): %s", client, arg);
			}
		}
		return Plugin_Handled;
	}
	else if( StrEqual(command, "t") || StrEqual(command, "team") ) {
		
		if( rp_GetClientJobID(client) == 0 ) {
			ACCESS_DENIED(client);
		}

		if( BaseComm_IsClientGagged(client) || rp_GetClientBool(client, b_IsMuteLocal) ) {
			PrintToChat(client, "\x04[\x02MUTE\x01]\x01: Vous avez été interdit d'utiliser le chat local.");
			return Plugin_Handled;
		}

		int j = rp_GetClientJobID(client);
		if( j == 101 )
			j = 1;

		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;

			int j2 = rp_GetClientJobID(i);
			if( j2 == 101 )
				j2 = 1;

			if( j == j2 ) {
				CPrintToChatEx(i, client, "{lightblue}%N{default} ({orange}TEAM{default}): %s", client, arg);
			}
		}

		return Plugin_Handled;
	}
	else if( StrEqual(command, "m") || StrEqual(command, "marie") ) {
		
		int mari = rp_GetClientInt(client, i_MarriedTo);
		if( mari == 0 ) {
			ACCESS_DENIED(client);
		}
		
		CPrintToChatEx(mari, client, "{lightblue}%N{default} ({red}MARIÉ{default}): %s", client, arg);
		CPrintToChatEx(client, client, "{lightblue}%N{default} ({red}MARIÉ{default}): %s", client, arg);
		

		return Plugin_Handled;
	}
	else if( StrEqual(command, "g") || StrEqual(command, "group") ) {
		if( rp_GetClientGroupID(client) == 0 ) {
			ACCESS_DENIED(client);
		}

		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;

			if( rp_GetClientGroupID(i) == rp_GetClientGroupID(client) ) {
				CPrintToChatEx(i, client, "{lightblue}%N{default} ({red}GROUP{default}): %s", client, arg);
			}
		}

		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
public Action fwdHear(int client, int target, float& dist, bool local) {
	
	int Czone = rp_GetPlayerZone(client), Ctype = rp_GetZoneInt(Czone, zone_type_type);
	int Tzone = rp_GetPlayerZone(target), Ttype = rp_GetZoneInt(Tzone, zone_type_type), Tbit = rp_GetZoneBit(Tzone);
	
	if( !local ) {
		if( IsValidClient(target) ) {
			if( rp_GetClientBool(target, b_IsMuteVocal) )
				return Plugin_Stop;
		}
		else if( rp_IsValidVehicle(target) ) {
			if( rp_GetClientBool(Vehicle_GetDriver(target), b_IsMuteVocal) )
				return Plugin_Stop;
		}
	}
		
	if( !local && (Tbit & BITZONE_JAIL || Tbit & BITZONE_HAUTESECU) ) { 
		return Plugin_Stop;
	}
	
	if( Ctype != Ttype && (Czone==0||Tzone==0) ) {
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}
public Action AllowStealing(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("AllowStealing");
	#endif
	rp_SetClientBool(client, b_MaySteal, true);
}
