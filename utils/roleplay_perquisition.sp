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

int g_cBeam;
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
	
	if( type == 0 ) {
		DataPack dp = new DataPack();
		CreateDataTimer(1.0, TIMER_PERQUIZ_LOOKUP, dp, TIMER_REPEAT);
		dp.WriteCell(client);
		dp.WriteCell(zone);
		dp.WriteCell(type);
		dp.WriteCell(60);
	}
	else if( type == 0 ) {
		DataPack dp = new DataPack();
		CreateDataTimer(1.0, TIMER_PERQUIZ, dp, TIMER_REPEAT);
		dp.WriteCell(client);
		dp.WriteCell(zone);
		dp.WriteCell(type);
		dp.WriteCell(0);
	}
}
public Action TIMER_PERQUIZ(Handle timer, DataPack dp) {
	dp.Reset();
	int client = dp.ReadCell();
	int zone = dp.ReadCell();
	int type = dp.ReadCell();
	int resp = dp.ReadCell();
	
	Effect_DrawPerqui(zone);
	PrintToChatAll("%N -> %d -> %N -> %N", client, zone, type, resp);
}

public Action TIMER_PERQUIZ_LOOKUP(Handle timer, DataPack dp) {
	dp.Reset();
	int client = dp.ReadCell();
	int zone = dp.ReadCell();
	int type = dp.ReadCell();
	int timeleft = dp.ReadCell();
	int resp = GetPerquizResp(zone);
	Effect_DrawPerqui(zone);
	bool canStart = (timeleft <= 0 || !IsValidClient(resp));
	
	if( IsValidClient(resp) ) {
		char tmp[128], tmp2[128];
		
		if( timeleft % 10 == 0 && timeleft != 0 ) {
			rp_GetZoneData(zone, zone_type_name, tmp, sizeof(tmp));
			
			PrintToChatPoliceSearch(resp, "{red} ================================== {default}");
			PrintToChatPoliceSearch(resp, "{red}[TSX-RP] [POLICE]{default} une perquisition commencera dans: %i secondes", timeleft);
			PrintToChatPoliceSearch(resp, "{red}[TSX-RP] [POLICE]{default} %N {default}est prié de se présenter à %s.", resp, tmp);
			PrintToChatPoliceSearch(resp, "{red} ================================== {default}");
		}
		
		rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
		rp_GetZoneData(rp_GetPlayerZone(resp), zone_type_type, tmp2, sizeof(tmp2));
		
		if( StrEqual(tmp, tmp2) )
			canStart = true;
	}
	
	
	if( canStart ) {
		DataPack dp2 = new DataPack();
		CreateDataTimer(1.0, TIMER_PERQUIZ, dp, TIMER_REPEAT);
		dp2.WriteCell(client);
		dp2.WriteCell(zone);
		dp2.WriteCell(type);
		dp2.WriteCell(resp);
		return Plugin_Stop;
	}
			
	dp.Reset();
	dp.WriteCell(client);
	dp.WriteCell(zone);
	dp.WriteCell(type);
	dp.WriteCell(timeleft - 1);
	return Plugin_Continue;
}

int GetPerquizResp(int zone) {
	char tmp[128];
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
	char tmp[128], tmp2[128];
	rp_GetZoneData(zone, zone_type_type, tmp, sizeof(tmp));
	
	for (int i = 0; i <= 310; i++) {
		
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
void Effect_DrawPane(float bottomCorner[3], float upperCorner[3], int subDivision, char tmp[128]) {
	float corners[8][3], start[3], end[3], median[3];
	char tmp2[128];
	
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
