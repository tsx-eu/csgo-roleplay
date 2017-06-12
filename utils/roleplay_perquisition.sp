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

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

StringMap g_hPerquisition;
enum perquiz_data { PQ_client, PQ_zone, PQ_target, PQ_resp, PQ_type, PQ_timeout, PQ_Max};
int g_cBeam, g_cGlow;
float g_flLastPos[65][3];
bool g_bCanPerquiz[65];

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
//	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_cGlow = PrecacheModel("materials/sprites/glow01.vmt");
}
public void OnClientPostAdminCheck(int client) {
	g_bCanPerquiz[client] = true;
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
	rp_HookEvent(client, RP_OnPlayerZoneChange, fwdOnZoneChange);
}
// ----------------------------------------------------------------------------
public Action fwdOnZoneChange(int client, int newZone, int oldZone) {
	
	if( !g_bCanPerquiz[client] && (rp_GetClientJobID(client) == 1 || rp_GetClientJobID(client) == 101) ) {
		if( GetClientTeam(client) == CS_TEAM_CT && rp_GetZoneInt(newZone, zone_type_type) == rp_GetClientJobID(client) ) {
			g_bCanPerquiz[client] = true;
			if( rp_GetClientInt(client, i_Job) != 9 && rp_GetClientInt(client, i_Job) != 8 )
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous pouvez maintenant effectuer une perquisition");
		}
	}
}
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrContains(command, "perqui") == 0 || StrContains(command, "perquiz") == 0 ) {
		return Cmd_Perquiz(client);
	}
	return Plugin_Continue;
}
public Action Cmd_Perquiz(int client) {
	
	if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 ) {
		ACCESS_DENIED(client);
	}
	if( rp_GetClientInt(client, i_Job) == 9 || rp_GetClientInt(client, i_Job) == 8 ) {
		ACCESS_DENIED(client);
	}
	if( GetClientTeam(client) != CS_TEAM_CT ) {
		ACCESS_DENIED(client);
	}
	
	int array[PQ_Max];
	float dst[3];
	char tmp[64], tmp2[64];
	rp_GetClientTarget(client, dst);
	rp_GetZoneData(rp_GetZoneFromPoint(dst), zone_type_type, tmp, sizeof(tmp));
	if( strlen(tmp) == 0 )
		return Plugin_Handled;
	
	if( !g_bCanPerquiz[client] && !g_hPerquisition.GetArray(tmp, array, sizeof(array))) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez retourner à votre lieu de travail, avant de pouvoir faire une autre perquisition.");
		return Plugin_Handled;
	}
	
	Menu menu = new Menu(MenuPerquiz);
	menu.SetTitle("Quel est le motif de perquisition?\n ");
	
	
	if( g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		Format(tmp2, sizeof(tmp2), "cancel %s", tmp);	menu.AddItem(tmp2, "Annuler la perquisition");
	}
	else {
		Format(tmp2, sizeof(tmp2), "search %s", tmp);	menu.AddItem(tmp2, "Un recherché");
		Format(tmp2, sizeof(tmp2), "trafic %s", tmp);	menu.AddItem(tmp2, "Du traffic illégal", rp_GetClientJobID(client) == 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
		Format(tmp2, sizeof(tmp2), "kidnap %s", tmp);	menu.AddItem(tmp2, "Un kidnappé");
	}
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
		int nbRecherche = 0;
		rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
		if( !StrEqual(tmp, expl[1]) )
			return 0;
		
		if( StrEqual(expl[0], "search") || StrEqual(expl[0], "kidnap") ) {
			
			if( StringToInt(expl[2]) == 0 ) {
				Menu subMenu = new Menu(MenuPerquiz);
				subMenu.SetTitle("Qui est recherché?\n ");
				
				for (int i = 1; i <= MaxClients; i++) {
					if( !IsValidClient(i) || !IsPlayerAlive(i) || i == client )
						continue;
					if( StrEqual(expl[0], "kidnap") && rp_GetClientInt(i, i_KidnappedBy) == 0 )
						continue;
					
					rp_GetZoneData(rp_GetPlayerZone(i), zone_type_type, options, sizeof(options));
					if( !StrEqual(options, expl[1]) )
						continue;
					
					Format(options, sizeof(options), "%s %s %d", expl[0], expl[1], i);
					Format(tmp, sizeof(tmp), "%N", i);
					
					GetClientAbsOrigin(i, g_flLastPos[i]);
					
					subMenu.AddItem(options, tmp);
					nbRecherche++;
				}
				if(nbRecherche <= 0) {
					delete subMenu;
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il n'y a pas de personne recherchée dans cette planque.");
				} else {
					subMenu.Display(client, MENU_TIME_FOREVER);
				}
				g_bCanPerquiz[client] = false;
			}
			else {
				INIT_PERQUIZ(client, zone, StringToInt(expl[2]), StrEqual(expl[0], "search") ? 1 : 2 );
			}
		}
		else if( StrEqual(expl[0], "trafic") ) {
			int weapon, machine, plant;
			
			countBadThing(expl[1], weapon, plant, machine);
			
			g_bCanPerquiz[client] = false;
			
			if( weapon > 3 || machine > 2 || plant > 2 )
				INIT_PERQUIZ(client, zone, 0, 0);
			else
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il n'y a pas de trafic illégal dans cette planque.");
				
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
// ----------------------------------------------------------------------------
void INIT_PERQUIZ(int client, int zone, int target, int type) {	
	
	char tmp[64], query[512];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	int array[PQ_Max];
	
	if( g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		return;
	}
	
	setPerquizData(client, zone, target, 0, type, 0);
	
	Format(query, sizeof(query), "SELECT `time` FROM `rp_perquiz` WHERE `type`='%s' AND `job_id`='%d' AND `zone`='%s' ORDER BY `time` DESC;", target > 0 ? "search" : "trafic", rp_GetClientJobID(client), tmp);
	
	SQL_TQuery(rp_GetDatabase(), VERIF_PERQUIZ, query, zone);
}
public void VERIF_PERQUIZ(Handle owner, Handle row, const char[] error, any zone) {
	
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	int array[PQ_Max];
	
	if( !g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {	
		return;
	}
	
	int cd = getCooldown(array[PQ_client], zone);
	if( row != INVALID_HANDLE && SQL_FetchRow(row) ) {
		
		if( SQL_FetchInt(row, 0) + cd > GetTime() ) {
			g_bCanPerquiz[array[PQ_client]] = true;
			
			CPrintToChat(array[PQ_client], "{lightblue}[TSX-RP]{default} Impossible de perquisitionner ici avant %d minutes.", ((SQL_FetchInt(row, 0) + cd - GetTime())/60) + 1);
			g_hPerquisition.Remove(tmp);
			return;
		}
	}
	
	changeZoneState(zone, true);
	
	if( array[PQ_target] == 0 ) {
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
	
	
	
	if( array[PQ_resp] == 0 && IsValidClient(array[PQ_target]) )
		array[PQ_resp] = array[PQ_target];
		
	array[PQ_timeout] = 0;
	updatePerquizData(zone, array);
	
	
	rp_GetZoneData(zone, zone_type_name, tmp, sizeof(tmp));
	LogToGame("[PERQUIZ] Une perquisition est lancée dans %s.", tmp);
	
	PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");
	if( IsValidClient(array[PQ_target]) )
		PrintToChatPoliceSearch(array[PQ_resp], "{red}[TSX-RP] [POLICE]{default} La perquisition dans %s pour un recherché %N commence.", tmp, array[PQ_resp]);
	else
		PrintToChatPoliceSearch(array[PQ_resp], "{red}[TSX-RP] [POLICE]{default} La perquisition dans %s pour du traffic illégal commence, %N est le responsable.", tmp, array[PQ_resp]);
	PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");	
	
	if( IsValidClient(array[PQ_target]) ) {
		rp_HookEvent(array[PQ_target], RP_OnPlayerDead, fwdHookDead);
		rp_HookEvent(array[PQ_target], RP_PreClientSendToJail, fwdHookJail);
	}
	CreateTimer(1.0, TIMER_PERQUIZ, zone, TIMER_REPEAT);
}
void END_PERQUIZ(int zone, bool abort) {
	int array[PQ_Max];
	char tmp[64], date[64], query[512];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	if( !g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		return;
	}
	g_hPerquisition.Remove(tmp);
	changeZoneState(zone, false);
	TeleportCT(zone);
	DoorLock(zone);
	
	if( IsValidClient(array[PQ_target]) ) {
		rp_UnhookEvent(array[PQ_target], RP_OnPlayerDead, fwdHookDead);
		rp_UnhookEvent(array[PQ_target], RP_PreClientSendToJail, fwdHookJail);
	}
	
	rp_GetDate(date, sizeof(date));
	
	rp_GetZoneData(zone, zone_type_name, tmp, sizeof(tmp));
	LogToGame("[PERQUIZ] Une perquisition est terminée dans %s.", tmp);
	PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");
	PrintToChatPoliceSearch(array[PQ_resp], "{red}[TSX-RP] [POLICE]{default} La perquisition dans %s est %s.", tmp, abort ? "annulée" : "terminée");
	PrintToChatPoliceSearch(array[PQ_resp], "{red} ================================== {default}");
	
	if( !abort ) {
		FakeClientCommand(array[PQ_client], "say /addnote %s - %s - %s", tmp, date, array[PQ_target] > 0 ? "recherché" : "traffic");
		
		rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
		GetClientAuthId(array[PQ_client], AuthId_Engine, date, sizeof(date));
		Format(query, sizeof(query), "INSERT INTO `rp_perquiz` (`id`, `zone`, `time`, `steamid`, `type`, `job_id`) VALUES (NULL, '%s', UNIX_TIMESTAMP(), '%s', '%s', '%d');", tmp, date, array[PQ_target] > 0 ? "search" : "trafic", rp_GetClientJobID(array[PQ_client]));
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
		
		rp_ClientMoney(array[PQ_client], i_AddToPay, 500);
	}
	else if( abort ) {
		FakeClientCommand(array[PQ_client], "say /addnote %s - %s - %s",  tmp, date, "annulée");
		
		rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
		GetClientAuthId(array[PQ_client], AuthId_Engine, date, sizeof(date));
		Format(query, sizeof(query), "INSERT INTO `rp_perquiz` (`id`, `zone`, `time`, `steamid`, `type`, `job_id`) VALUES (NULL, '%s', UNIX_TIMESTAMP()-%d, '%s', '%s', '%d');", tmp, getCooldown(array[PQ_client], zone)*60+6*60, date, array[PQ_target] > 0 ? "search" : "trafic", rp_GetClientJobID(array[PQ_client]));
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
	}
}
// ----------------------------------------------------------------------------
public Action fwdHookJail(int attacker, int victim) {
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
	
	if( array[PQ_type] != 2 ) {
		ServerCommand("rp_SendToJail %d %d", victim, array[PQ_client]);
		rp_SetClientInt(victim, i_JailTime, (rp_GetClientInt(victim, i_JailTime) + 6 * 60));
		END_PERQUIZ(zone, false);
	}
	else
		END_PERQUIZ(zone, true);
	
	CreateTimer(0.1, respawn, victim);
	
	
	
	return Plugin_Continue;
}
public Action respawn(Handle timer, any client) {
	rp_ClientRespawn(client);
}
public Action TIMER_PERQUIZ(Handle timer, any zone) {
	int array[PQ_Max];
	char tmp[64], tmp2[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	if( !g_hPerquisition.GetArray(tmp, array, sizeof(array)) ) {
		return Plugin_Stop;
	}
	
	if( array[PQ_target] > 0 ) {
		if( !IsValidClient(array[PQ_target]) ) {
			END_PERQUIZ(zone, true);
			return Plugin_Stop;
		}
		
		if( array[PQ_type] == 2 && rp_GetClientInt(array[PQ_target], i_KidnappedBy) == 0 ) {
			END_PERQUIZ(zone, false);
			return Plugin_Stop;
		}
		
		rp_GetZoneData( rp_GetPlayerZone(array[PQ_target]) , zone_type_type, tmp2, sizeof(tmp2));
		if( !StrEqual(tmp, tmp2) ) {		
			rp_ClientTeleport(array[PQ_target], g_flLastPos[array[PQ_target]]);
		}
		else
			GetClientAbsOrigin(array[PQ_target], g_flLastPos[array[PQ_target]]);
	}
	else {
		int weapon, machine, plant;
			
		countBadThing(tmp, weapon, plant, machine);
		if( (weapon + plant + machine) == 0 ) {
			END_PERQUIZ(zone, false);
			return Plugin_Stop;
		}
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
// ----------------------------------------------------------------------------
int GetPerquizResp(int zone) {
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	if( StrEqual(tmp, "bunker") )
		return GetPerquizRespByGroup( rp_GetCaptureInt(cap_bunker) );
	else if( StrEqual(tmp, "villa") )
		return GetPerquizRespByGroup( rp_GetCaptureInt(cap_villa) );
	else if( StrEqual(tmp, "mairie") )
		return GetPerquizRespMaire();
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
		
		if( owner == i )
			return i;
		
		if( zone & (BITZONE_JAIL|BITZONE_LACOURS|BITZONE_HAUTESECU) )
			continue;
		
		if( rp_GetClientKeyAppartement(i, appartID)  )
			res = i;
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
int GetPerquizRespMaire() {
	char tmp[32], tmp2[32];
	rp_GetServerString(mairieID, tmp, sizeof(tmp));
	
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		GetClientAuthId(i, AuthId_Engine, tmp2, sizeof(tmp2));
		if( StrEqual(tmp, tmp2) )
			return i;
	}
	
	return 0;
}
// ----------------------------------------------------------------------------
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
		
		Effect_DrawPane(min, max, RoundFloat((max[2] - min[2]) / 128.0), tmp);
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
			
			TE_SetupBeamPoints(end, start, g_cBeam, 0, 0, 0, 1.0, 8.0, 8.0, 0, 0.0, {255, 255, 0, 128}, 0);
			TE_SendToAll();
		}
	}
}
// ----------------------------------------------------------------------------
void DoorLock(int zone) {
	char tmp[64], tmp2[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	for (int i = MaxClients; i <= MAX_ENTITIES; i++) {
		if( !rp_IsValidDoor(i) )
			continue;
		
		rp_GetZoneData(rp_GetPlayerZone(i), zone_type_type, tmp2, sizeof(tmp2));
		
		if( StrEqual(tmp, tmp2) ) {
			AcceptEntityInput(i, "Close");
			AcceptEntityInput(i, "Lock");
		}
	}
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
		
		if( enabled && !(bits & BITZONE_PERQUIZ) ) {
			bits |= BITZONE_PERQUIZ;
		}
		else if( !enabled && (bits & BITZONE_PERQUIZ) ) {
			bits &= ~BITZONE_PERQUIZ;
		}
		
		rp_SetZoneBit(i, bits);
	}
	
	float vecOrigin[3];
	
	for (int i = 1; i <= 2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, sizeof(tmp));
		
		if( StrEqual(tmp, "rp_plant") || StrEqual(tmp, "rp_cashmachine") || StrEqual(tmp, "rp_bigcashmachine") ) {
			
			Entity_GetAbsOrigin(i, vecOrigin);
			vecOrigin[2] += 16.0;
			
			rp_GetZoneData(rp_GetZoneFromPoint(vecOrigin), zone_type_type, tmp2, sizeof(tmp2));
			if( !StrEqual(tmp, tmp2) )
				continue;
			
			SetEntProp(i, Prop_Data, "m_takedamage", enabled ? 0 : 2);
		}
	}
}
// ----------------------------------------------------------------------------
void setPerquizData(int client, int zone, int target, int resp, int type, int timeout) {
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	int array[PQ_Max];
	
	array[PQ_client] = client;
	array[PQ_zone] = zone;
	array[PQ_target] = target;
	array[PQ_resp] = resp;
	array[PQ_type] = type;
	array[PQ_timeout] = timeout;
	
	g_hPerquisition.SetArray(tmp, array, sizeof(array));
}
void updatePerquizData(int zone, int array[PQ_Max]) {
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	g_hPerquisition.SetArray(tmp, array, sizeof(array));
}
// ----------------------------------------------------------------------------
void countBadThing(char[] zone, int& weapon, int& plant, int& machine) {
	char tmp[64], tmp2[64];
	
	float vecOrigin[3];
	
	for (int i = MaxClients; i <= MAX_ENTITIES; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, sizeof(tmp));
		if( StrContains(tmp, "weapon_") == -1 && StrContains(tmp, "rp_") == -1 )
			continue;
		
		Entity_GetAbsOrigin(i, vecOrigin);
		vecOrigin[2] += 16.0;
		
		rp_GetZoneData(rp_GetZoneFromPoint(vecOrigin), zone_type_type, tmp2, sizeof(tmp2));
		if( StrEqual(tmp2, "14") )
			tmp2[1] = '1';
		
		if( !StrEqual(tmp2, zone) )
			continue;
		
		if( StrContains(tmp, "weapon_") == 0 && StrContains(tmp, "knife") == -1 &&  Weapon_GetOwner(i) <= 0 )
			weapon++;
		if( StrContains(tmp, "rp_plant") == 0 )
			plant++;
		if( StrContains(tmp, "rp_cash") == 0 )
			machine++;
		if( StrContains(tmp, "rp_bigcash") == 0 )
			machine+=15;
	}
	
}
void TeleportCT(int zone) {
	char tmp[64], tmp2[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) || !IsPlayerAlive(i) )
			continue;
		if( GetClientTeam(i) == CS_TEAM_T )
			continue;
		rp_GetZoneData(rp_GetPlayerZone(i), zone_type_type, tmp2, sizeof(tmp2));
		
		if( StrEqual(tmp, tmp2) ) {
			rp_ClientSendToSpawn(i, true);
		}
	}
}
int getCooldown(int client, int zone) {
	char tmp[64];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	if( rp_GetClientJobID(client) == 1 && (StrEqual(tmp, "bunker") || StrEqual(tmp, "villa") || StrEqual(tmp, "appart_50") ) )
		return 6 * 60 * 60;
	else if( rp_GetClientJobID(client) == 101 && (StrEqual(tmp, "bunker") || StrEqual(tmp, "villa") || StrEqual(tmp, "appart_50") ) )
		return 1 * 60 * 60;
	else
		return 24 * 60;
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
