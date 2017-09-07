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
#include <sdktools>
#include <cstrike>
#include <colors_csgo>   // https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>      // https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#pragma newdecls required
#include <roleplay.inc>   // https://www.ts-x.eu

public Plugin myinfo =  {
	name = "mini-hg", author = "KoSSoLaX", 
	description = "mini hg", 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

#define		TEAM_NONE		0
#define		TEAM_ATK		1
#define		TEAM_DEF		2
#define		TEAM_VIP		3
#define		TEAM_MAX		4

int g_iPlayerTeam[MAXPLAYERS], g_stkTeam[TEAM_MAX][MAXPLAYERS + 1], g_stkTeamCount[TEAM_MAX];
int g_cBeam;

public void OnPluginStart() {
	RegAdminCmd("rp_hg", Cmd_HG, ADMFLAG_BAN);
	CreateTimer(0.5, OnFrameSecond, _, TIMER_REPEAT);
	LoadTranslations("common.phrases");
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}
public void OnClientDisconnect(int client) {
	removeClientTeam(client);
}
// ----------------------------------------------------------------------------
public Action OnFrameSecond(Handle timer, any none) {
	float pos[3];
	
	for (int i = 0; i < g_stkTeamCount[TEAM_DEF]; i++) {
		int client = g_stkTeam[TEAM_DEF][i];
		
		GetClientAbsOrigin(client, pos);
		pos[2] += 8.0;
		
		TE_SetupBeamRingPoint(pos, 8.0, 42.0, g_cBeam, g_cBeam, 0, 0, 1.0, 4.0, 0.0, {0, 0, 255, 255}, 0, 0);
		TE_Send(g_stkTeam[TEAM_DEF], g_stkTeamCount[TEAM_DEF]);
	}
	for (int i = 0; i < g_stkTeamCount[TEAM_VIP]; i++) {
		int client = g_stkTeam[TEAM_VIP][i];
		
		GetClientAbsOrigin(client, pos);
		pos[2] += 8.0;
		
		TE_SetupBeamRingPoint(pos, 8.0, 42.0, g_cBeam, g_cBeam, 0, 0, 1.0, 4.0, 0.0, {0, 255, 0, 255}, 0, 0);
		TE_Send(g_stkTeam[TEAM_DEF], g_stkTeamCount[TEAM_DEF]);
	}
	for (int i = 0; i < g_stkTeamCount[TEAM_ATK]; i++) {
		int client = g_stkTeam[TEAM_ATK][i];
		
		GetClientAbsOrigin(client, pos);
		pos[2] += 8.0;
		
		TE_SetupBeamRingPoint(pos, 8.0, 42.0, g_cBeam, g_cBeam, 0, 0, 1.0, 4.0, 0.0, {255, 0, 0, 255}, 0, 0);
		TE_Send(g_stkTeam[TEAM_ATK], g_stkTeamCount[TEAM_ATK]);
	}
}
// ----------------------------------------------------------------------------
public Action Cmd_HG(int client, int args) {
	char arg[12], trg[32], name[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));
	
	int team = -1;
	
	if( StrContains(arg, "non") >= 0 )
		team = TEAM_NONE;
	if( StrContains(arg, "vip") >= 0)
		team = TEAM_VIP;
	if( StrContains(arg, "atk") >= 0 || StrContains(arg, "att") >= 0 )
		team = TEAM_ATK;
	if( StrContains(arg, "def") >= 0 )
		team = TEAM_DEF;
	
	if( team != -1 ) {
		if( args >= 2 ) {
			GetCmdArg(2, trg, sizeof(trg));
			
			int stkTarget[MAXPLAYERS], stkCpt;
			bool tn_is_ml;
			
			if( (stkCpt = ProcessTargetString(trg, client, stkTarget, MAXPLAYERS, COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_MULTI, name, sizeof(name), tn_is_ml)) <= 0) {
				ReplyToTargetError(client, stkCpt);
				return Plugin_Handled;
			}
			
			for (int i = 0; i < stkCpt; i++)
				addClientToTeam(stkTarget[i], team);
		}
		else {
			for (int i = 0; i < g_stkTeamCount[team]; i++) {
				int target = g_stkTeam[team][i];
				ReplyToCommand(client, "     - %N", target);
			}
		}
	}
	else {
		if( StrContains(arg, "start") >= 0) {
			// TODO
		}
		if( StrContains(arg, "stop") >= 0) {
			// TODO
		}
	}
	
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
void addClientToTeam(int client, int team) {
	removeClientTeam(client);
	
	if( team != TEAM_NONE )
		g_stkTeam[team][ g_stkTeamCount[team]++ ] = client;
	
	g_iPlayerTeam[client] = team;
}
void removeClientTeam(int client) {
	
	if( g_iPlayerTeam[client] != TEAM_NONE ) {
		for (int i = 0; i < g_stkTeamCount[g_iPlayerTeam[client]]; i++) {
			if( g_stkTeam[ g_iPlayerTeam[client] ][ i ] == client ) {
				for (; i < g_stkTeamCount[g_iPlayerTeam[client]]; i++) {
					g_stkTeam[g_iPlayerTeam[client]][i] = g_stkTeam[g_iPlayerTeam[client]][i + 1];
				}
				g_stkTeamCount[g_iPlayerTeam[client]]--;
				break;
			}
		}
		
		g_iPlayerTeam[client] = TEAM_NONE;
	}
}