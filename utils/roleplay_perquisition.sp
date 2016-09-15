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

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define	MAX_ENTITIES	2048

StringMap g_hPerquisition;
enum perquiz_data { PQ_client, PQ_zone, PQ_type, PQ_resp, PQ_timeout, PQ_Max};
int g_cBeam;
float g_flLastPos[65][3];

public Plugin myinfo = {
	name = "Utils: Perquisition", author = "KoSSoLaX",
	description = "RolePlay - Utils: Perquisition",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};
public void OnPluginStart() {
	
	g_hPerquisition = new StringMap();
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/effects/policeline.vmt");
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
	
	int array[PQ_Max];
	float dst[3];
	char tmp[64], tmp2[64];
	rp_GetClientTarget(client, dst);
	rp_GetZoneData(rp_GetZoneFromPoint(dst), zone_type_type, tmp, sizeof(tmp));
	if( strlen(tmp) == 0 )
		return Plugin_Handled;
	
	
	Menu menu = new Menu(MenuPerquiz);
	menu.SetTitle("Quel est le motif de perquisition?\n ");
	
	
	if( g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		Format(tmp2, sizeof(tmp2), "cancel %s", tmp);	menu.AddItem(tmp2, "Annuler la perquisition");
	}
	else {
		Format(tmp2, sizeof(tmp2), "search %s", tmp);	menu.AddItem(tmp2, "Un recherché");
		Format(tmp2, sizeof(tmp2), "trafic %s", tmp);	menu.AddItem(tmp2, "Du traffic illégal", rp_GetClientJobID(client) == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
	}
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}
public int MenuPerquiz(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64], expl[4][32], tmp[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		PrintToChatAll(options);
		
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
					if( !IsValidClient(i) || !IsPlayerAlive(i) /*|| i == client*/ )
						continue;
					
					rp_GetZoneData(rp_GetPlayerZone(i), zone_type_type, options, sizeof(options));
					if( !StrEqual(options, expl[1]) )
						continue;
					
					Format(options, sizeof(options), "search %s %d", expl[1], i);
					Format(tmp, sizeof(tmp), "%N", i);
					
					GetClientAbsOrigin(i, g_flLastPos[i]);
					
					subMenu.AddItem(options, tmp);
				}
				
				subMenu.Display(client, MENU_TIME_FOREVER);
			}
			else {
				INIT_PERQUIZ(client, zone, StringToInt(expl[2]));
			}
		}
		else if( StrEqual(expl[0], "trafic") ) {
			int weapon, machine, plant;
			
			for (int i = MaxClients; i <= MAX_ENTITIES; i++) {
				if( !IsValidEdict(i) || !IsValidEntity(i) )
					continue;
				
				GetEdictClassname(i, tmp, sizeof(tmp));
				if( StrContains(tmp, "weapon_") == -1 && StrContains(tmp, "rp_") == -1 )
					continue;
				
				rp_GetZoneData(rp_GetPlayerZone(i), zone_type_type, options, sizeof(options));
				if( !StrEqual(options, expl[1]) )
					continue;
				
				if( StrContains(tmp, "weapon_") == 0 && StrContains(tmp, "knife") == -1 )
					weapon++;
				if( StrContains(tmp, "rp_plant") == 0 )
					plant++;
				if( StrContains(tmp, "rp_cash") == 0 )
					machine++;
				if( StrContains(tmp, "rp_bigcash") == 0 )
					machine+=15;
			}
			
			if( weapon > 3 || machine > 2 || plant > 2 )
				INIT_PERQUIZ(client, zone, 0);
		}
		else if( StrEqual(expl[0], "cancel") ) {
			END_PERQUIZ(zone, true);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return 0;
}

void INIT_PERQUIZ(int client, int zone, int type) {	
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	int array[PQ_Max];
	
	if( g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {	
		return;
	}
	
	setPerquizData(client, zone, type, 0, 0);
	
	if( type == 0 ) {
		CreateTimer(1.0, TIMER_PERQUIZ_LOOKUP, zone, TIMER_REPEAT);
	}
	else {
	
		START_PERQUIZ(zone);
	}
}

void START_PERQUIZ(int zone) {
	int array[PQ_Max];
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	if( !g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		return;
	}
	
	array[PQ_timeout] = 0;
	updatePerquizData(zone, array);
	changeZoneState(zone, true);
	
	rp_GetZoneData(zone, zone_type_name, tmp, sizeof(tmp));
	PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");
	PrintToChatPoliceSearch(array[PQ_resp], "{red}[TSX-RP] [POLICE]{default} La perquisition dans %s pour %s commence.", tmp, array[PQ_type] > 0 ? "un recherché" : "du traffic illégal");
	PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");	
	
	if( IsValidClient(array[PQ_type]) ) {
		rp_HookEvent(array[PQ_type], RP_OnPlayerDead, fwdHookDead);
		rp_HookEvent(array[PQ_type], RP_PreClientSendToJail, fwdHookJail);
	}
	CreateTimer(1.0, TIMER_PERQUIZ, zone, TIMER_REPEAT);
}
void END_PERQUIZ(int zone, bool abort) {
	int array[PQ_Max];
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	if( !g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		return;
	}
	changeZoneState(zone, false);
	
	if( IsValidClient(array[PQ_type]) ) {
		rp_UnhookEvent(array[PQ_type], RP_OnPlayerDead, fwdHookDead);
		rp_UnhookEvent(array[PQ_type], RP_PreClientSendToJail, fwdHookJail);
	}
	
	g_hPerquisition.Remove(tmp);
	
	rp_GetZoneData(zone, zone_type_name, tmp, sizeof(tmp));
	PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");
	PrintToChatPoliceSearch(array[PQ_resp], "{red}[TSX-RP] [POLICE]{default} La perquisition dans %s est %s.", tmp, abort ? "annulée" : "terminée");
	PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");
}
public Action fwdHookJail(int victim, int attacker) {
	char tmp[64];
	int zone = rp_GetZoneFromPoint(g_flLastPos[victim]);
	int array[PQ_Max];
	rp_GetZoneData( zone, zone_type_type, tmp, sizeof(tmp));
	
	if( !g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		rp_UnhookEvent(victim, RP_PreClientSendToJail, fwdHookJail);
	}
	
	END_PERQUIZ(zone, false);
	
	return Plugin_Continue;
}
public Action fwdHookDead(int victim, int attacker) {
	char tmp[64];
	int zone = rp_GetZoneFromPoint(g_flLastPos[victim]);
	int array[PQ_Max];
	rp_GetZoneData( zone, zone_type_type, tmp, sizeof(tmp));
	
	if( !g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		rp_UnhookEvent(victim, RP_OnPlayerDead, fwdHookDead);
	}
	
	END_PERQUIZ(zone, false);
	
	return Plugin_Continue;
}
public Action TIMER_PERQUIZ(Handle timer, any zone) {
	int array[PQ_Max];
	char tmp[64], tmp2[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	if( !g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		return Plugin_Stop;
	}
	
	if( array[PQ_type] > 0 ) {
		if( !IsValidClient(array[PQ_type]) ) {
			END_PERQUIZ(zone, true);
			return Plugin_Stop;
		}
		
		rp_GetZoneData( rp_GetPlayerZone(array[PQ_type]) , zone_type_type, tmp2, sizeof(tmp2));
		if( !StrEqual(tmp, tmp2) ) {
			TeleportEntity(array[PQ_type], g_flLastPos[array[PQ_type]], NULL_VECTOR, NULL_VECTOR);
			FakeClientCommand(array[PQ_type], "sm_stuck");
		}
		else
			GetClientAbsOrigin(array[PQ_type], g_flLastPos[array[PQ_type]]);
	}
	
	if( hasCopInZone(zone) ) {
		array[PQ_timeout] = 0;
	}
	else {
		array[PQ_timeout]++;
		
		if( array[PQ_timeout] == 20 ) {
			rp_GetZoneData(zone, zone_type_name, tmp, sizeof(tmp));
			PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");
			PrintToChatPoliceSearch(array[PQ_resp], "{red}[TSX-RP] [POLICE]{default} La perquisition dans %s sera annulée, si aucun flic n'est présent dans les 10 secondes.", tmp);
			PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");
		}
		else if( array[PQ_timeout] >= 30 ) {
			END_PERQUIZ(zone, true);
			return Plugin_Stop;
		}
	}
	
	updatePerquizData(zone, array);
	Effect_DrawPerqui(zone);
	
	return Plugin_Continue;
}

public Action TIMER_PERQUIZ_LOOKUP(Handle timer, any zone) {
	int array[PQ_Max];
	char tmp[64], tmp2[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	if( !g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		return Plugin_Stop;
	}
	
	array[PQ_resp] = GetPerquizResp(zone);
	bool canStart = (array[PQ_timeout] >= 60 || !IsValidClient(array[PQ_resp]));
	
	if( IsValidClient(array[PQ_resp]) ) {
		
		if( array[PQ_timeout] % 10 == 0 && array[PQ_timeout] != 60 ) {
			rp_GetZoneData(zone, zone_type_name, tmp, sizeof(tmp));
			
			PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");
			PrintToChatPoliceSearch(array[PQ_resp], "{red}[TSX-RP] [POLICE]{default} une perquisition commencera dans: %i secondes", 60 - array[PQ_timeout]);
			PrintToChatPoliceSearch(array[PQ_resp], "{red}[TSX-RP] [POLICE]{default} %N {default}est prié de se présenter à %s.", array[PQ_resp], tmp);
			PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");
		}
		
		rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
		rp_GetZoneData(rp_GetPlayerZone(array[PQ_resp]), zone_type_type, tmp2, sizeof(tmp2));
		
		if( StrEqual(tmp, tmp2) )
			canStart = true;
	}
	
	
	if( canStart ) {
		START_PERQUIZ(zone);
		return Plugin_Stop;
	}
	array[PQ_timeout]++;
	
	updatePerquizData(zone, array);
	Effect_DrawPerqui(zone);
	return Plugin_Continue;
}
int GetPerquizResp(int zone) {
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	if( StrEqual(tmp, "bunker") )
		return GetPerquizRespByGroup( rp_GetCaptureInt(cap_bunker) );
	else if( StrEqual(tmp, "villa") )
		return GetPerquizRespByGroup( rp_GetCaptureInt(cap_villa) );
	else if( StrContains(tmp, "appart_") == 0 ) {
		ReplaceString(tmp, sizeof(tmp), "appart_", "");
		return GetPerquizRespByAppart(StringToInt(tmp));
	}
	else
		return GetPerquizRespByJob(StringToInt(tmp));
}
int GetPerquizRespByAppart(int appartID) {
	int zone;
	int res = 0;
	int owner = rp_GetAppartementInt(appartID, appart_proprio);
	
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		zone = rp_GetZoneBit(rp_GetPlayerZone(i));
		if( zone & (BITZONE_JAIL|BITZONE_LACOURS|BITZONE_HAUTESECU) )
			continue;
		
		if( owner == i )
			return res;
		
		if( rp_GetClientKeyAppartement(i, appartID)  ) {
			res = i;
		}
	}
	return res;
}
int GetPerquizRespByJob(int job_id) {
	#if defined DEBUG
	PrintToServer("GetPerquizResp");
	#endif
	int zone;	
	int min = 9999;
	int res = 0;
	
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		zone = rp_GetZoneBit(rp_GetPlayerZone(i));
		if( zone & (BITZONE_JAIL|BITZONE_LACOURS|BITZONE_HAUTESECU) )
			continue;
		
		if( job_id == rp_GetClientJobID(i) && min > rp_GetClientInt(i, i_Job) ) {
			min = rp_GetClientInt(i, i_Job);
			res = i;
		}
	}
	
	
	return res;
}
int GetPerquizRespByGroup(int gang_id) {
	#if defined DEBUG
	PrintToServer("GetPerquizResp");
	#endif
	int zone;	
	int min = 9999;
	int res = 0;
	
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		zone = rp_GetZoneBit(rp_GetPlayerZone(i));
		if( zone & (BITZONE_JAIL|BITZONE_LACOURS|BITZONE_HAUTESECU) )
			continue;
		
		if( gang_id == rp_GetClientGroupID(i) && min > rp_GetClientInt(i, i_Group) ) {
			min = rp_GetClientInt(i, i_Job);
			res = i;
		}
	}
	
	
	return res;
}
void Effect_DrawPerqui(int zone) {
	float min[3], max[3];
	char tmp[64], tmp2[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	for (int i = 0; i < 310; i++) {
		
		rp_GetZoneData(i, zone_type_type, tmp2, sizeof(tmp2));
		if( !StrEqual(tmp, tmp2) )
			continue;
		
		min[0] = rp_GetZoneFloat(i, zone_type_min_x) - 16.0;
		min[1] = rp_GetZoneFloat(i, zone_type_min_y) - 16.0;
		min[2] = rp_GetZoneFloat(i, zone_type_min_z) - 16.0;
		
		max[0] = rp_GetZoneFloat(i, zone_type_max_x) + 16.0;
		max[1] = rp_GetZoneFloat(i, zone_type_max_y) + 16.0;
		max[2] = rp_GetZoneFloat(i, zone_type_max_z) + 16.0;
		
		Effect_DrawPane(min, max, RoundFloat((max[2] - min[2]) / 64.0), tmp);
	}
}
void Effect_DrawPane(float bottomCorner[3], float upperCorner[3], int subDivision, char tmp[64]) {
	float corners[8][3], start[3], end[3], median[3];
	char tmp2[64];
	
	for (int i=0; i < 4; i++) {
		Array_Copy(bottomCorner,	corners[i],		3);
		Array_Copy(upperCorner,		corners[i+4],	3);
	}

	corners[1][0] = upperCorner[0];
	corners[2][0] = upperCorner[0]; 
	corners[2][1] = upperCorner[1];
	corners[3][1] = upperCorner[1];
	corners[4][0] = bottomCorner[0]; 
	corners[4][1] = bottomCorner[1];
	corners[5][1] = bottomCorner[1];
	corners[7][0] = bottomCorner[0];

    // Draw all the edges
	// Horizontal Lines
	// Bottom
	for (int i=0; i < 4; i++) {
		int j = ( i == 3 ? 0 : i+1 );
		
		for (int k = 0; k <= 2; k++) {
			start[k] = corners[i][k];
			end[k] = corners[j][k];
		}
		
		for (int k = 0; k < subDivision; k++) {
			start[2] = end[2] = bottomCorner[2] + (  (upperCorner[2] - bottomCorner[2]) / (subDivision+1) * (k+1) );
			
			for (int h = 0; h <= 2; h++)
				median[h] = (start[h] + end[h]) / 2.0;
			
			rp_GetZoneData(rp_GetZoneFromPoint(median), zone_type_type, tmp2, sizeof(tmp2));
			if( StrEqual(tmp, tmp2) )
				continue;
			
			TE_SetupBeamPoints(end, start, g_cBeam, g_cBeam, 0, 0, 1.0, 8.0, 8.0, 0, 0.0, {255, 255, 0, 128}, 0);
			TE_SendToAllInRange(median, RangeType_Audibility);
		}
	}
}
bool hasCopInZone(int zone) {
	char tmp[64], tmp2[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) || !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) == CS_TEAM_T )
			continue;
		rp_GetZoneData(rp_GetPlayerZone(i), zone_type_type, tmp2, sizeof(tmp2));
		if( StrEqual(tmp, tmp2) )
			return true;
	}
	return false;
}

void changeZoneState(int zone, bool enabled) {
	int bits;
	char tmp[64], tmp2[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	for (int i = 0; i < 310; i++) {
		
		rp_GetZoneData(i, zone_type_type, tmp2, sizeof(tmp2));
		if( !StrEqual(tmp, tmp2) )
			continue;
		
		bits = rp_GetZoneBit(i);
		
		if( enabled && !(bits & BITZONE_PERQUIZ) )
			bits |= BITZONE_PERQUIZ;
		else if( !enabled && (bits & BITZONE_PERQUIZ) )
			bits &= ~BITZONE_PERQUIZ;
		
		rp_SetZoneBit(i, bits);
	}
}
void setPerquizData(int client, int zone, int type, int resp, int timeout) {
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	int array[PQ_Max];
	
	array[PQ_client] = client;
	array[PQ_zone] = zone;
	array[PQ_type] = type;
	array[PQ_resp] = resp;
	array[PQ_timeout] = timeout;
	
	g_hPerquisition.SetArray(tmp, array, sizeof(array));
}
void updatePerquizData(int zone, int array[PQ_Max]) {
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	g_hPerquisition.SetArray(tmp, array, sizeof(array));
}
