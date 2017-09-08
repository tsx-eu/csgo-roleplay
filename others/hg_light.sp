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
bool g_bStarted;

public void OnPluginStart() {
	RegAdminCmd("rp_hg", Cmd_HG, ADMFLAG_BAN);
	CreateTimer(0.5, OnFrameSecond, _, TIMER_REPEAT);
	LoadTranslations("common.phrases");
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_bStarted = false;
}
public void OnClientDisconnect(int client) {
	removeClientTeam(client);
}
public void OnClientPostAdminCheck(int client) {
	if( g_bStarted ) {
		rp_HookEvent(client, RP_PlayerCanKill,	fwdCanKill);
		rp_HookEvent(client, RP_OnPlayerDead,	fwdOnDead);
		rp_HookEvent(client, RP_PreTakeDamage,	fwdOnDamage);
	} 
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
		TE_SetupBeamRingPoint(pos, 8.0, 42.0, g_cBeam, g_cBeam, 0, 0, 1.0, 4.0, 0.0, {0, 0, 255, 255}, 0, 0);
		TE_Send(g_stkTeam[TEAM_VIP], g_stkTeamCount[TEAM_VIP]);
	}
	for (int i = 0; i < g_stkTeamCount[TEAM_VIP]; i++) {
		int client = g_stkTeam[TEAM_VIP][i];
		
		GetClientAbsOrigin(client, pos);
		pos[2] += 8.0;
		
		TE_SetupBeamRingPoint(pos, 8.0, 42.0, g_cBeam, g_cBeam, 0, 0, 1.0, 4.0, 0.0, {0, 255, 0, 255}, 0, 0);
		TE_Send(g_stkTeam[TEAM_VIP], g_stkTeamCount[TEAM_VIP]);
		TE_SetupBeamRingPoint(pos, 8.0, 42.0, g_cBeam, g_cBeam, 0, 0, 1.0, 4.0, 0.0, {0, 255, 0, 255}, 0, 0);
		TE_Send(g_stkTeam[TEAM_DEF], g_stkTeamCount[TEAM_DEF]);
		TE_SetupBeamRingPoint(pos, 8.0, 42.0, g_cBeam, g_cBeam, 0, 0, 1.0, 4.0, 0.0, {0, 255, 0, 255}, 0, 0);
		TE_Send(g_stkTeam[TEAM_ATK], g_stkTeamCount[TEAM_ATK]);
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
		if( StrContains(arg, "star") >= 0 )
			Game_StartStop(true);
		if( StrContains(arg, "stop") >= 0 ) {
			Game_StartStop(false);
			PrintToChatAll("[HG-VIP] Victoire de la défense");
		}
	}
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action fwdOnDamage(int victim, int attacker, float& damage, int damagetype) {
	if( g_iPlayerTeam[victim] == TEAM_NONE || g_iPlayerTeam[attacker] == TEAM_NONE )
		return Plugin_Continue;
	
	return !IsKillAllowed(attacker, victim) ? Plugin_Stop : Plugin_Continue;
}
public Action fwdCanKill(int attacker, int victim) {
	return IsKillAllowed(attacker, victim) ? Plugin_Stop : Plugin_Continue;
}
public Action fwdOnDead(int victim, int attacker, float& respawn) {
	Action ret = IsKillAllowed(attacker, victim) ? Plugin_Stop : Plugin_Continue;
	
	if( g_iPlayerTeam[victim] == TEAM_VIP && ret == Plugin_Stop ) {
		removeClientTeam(victim);
		if( g_stkTeamCount[TEAM_VIP] == 0 ) {
			Game_StartStop(false);
			PrintToChatAll("[HG-VIP] Victoire des attaquants");
		}
	}
	
	return ret;
}
bool IsKillAllowed(int victim, int attacker) {
	if( g_iPlayerTeam[victim] == TEAM_NONE || g_iPlayerTeam[attacker] == TEAM_NONE )
		return false;
	if( g_iPlayerTeam[attacker] == g_iPlayerTeam[victim] )
		return false;
	if( g_iPlayerTeam[attacker] == TEAM_DEF && g_iPlayerTeam[attacker] == TEAM_VIP )
		return false;
	if( g_iPlayerTeam[attacker] == TEAM_VIP && g_iPlayerTeam[attacker] == TEAM_DEF )
		return false;
	return true;
}
// ----------------------------------------------------------------------------
void Game_StartStop(bool status) {
	if( status == false && g_bStarted == true ) {
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
				
			rp_UnhookEvent(i, RP_PlayerCanKill,	fwdCanKill);
			rp_UnhookEvent(i, RP_OnPlayerDead,	fwdOnDead);
			rp_UnhookEvent(i, RP_PreTakeDamage,	fwdOnDamage);
		}
		
		PrintToChatAll("[HG-VIP] Fin du game.");
		g_bStarted = false;
	}
	else if( status == true && g_bStarted == false ) {
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			
			rp_HookEvent(i, RP_PlayerCanKill,	fwdCanKill);
			rp_HookEvent(i, RP_OnPlayerDead,	fwdOnDead);
			rp_HookEvent(i, RP_PreTakeDamage,	fwdOnDamage);
		}
		PrintToChatAll("[HG-VIP] Début du game.");
		g_bStarted = true;
	}
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