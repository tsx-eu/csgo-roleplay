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
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045



#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define QUEST_UNIQID	"loto-001"
#define	QUEST_NAME		"Vidange des machines à sous"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		171

public Plugin myinfo = {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX",
	description = "RolePlay - Quête Loto: "...QUEST_NAME,
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iStep[MAXPLAYERS + 1], g_iDone[MAXPLAYERS + 1][11];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q2_Frame,	Q1_Abort,	Q2_End);
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	if( rp_GetClientJobID(client) != QUEST_JOBID )
		return false;
		
	return true;
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Cher colègue, nous avons besoin de toi.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Les machines à sous sont pleine à", ITEMDRAW_DISABLED);
	menu.AddItem("", "craquer. Il faut que tu les vides et dépose", ITEMDRAW_DISABLED);
	menu.AddItem("", "tous l'argent à la banque.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60;
	g_iStep[client] = 0;
	
	for (int i = 0; i <= sizeof(g_iDone[]); i++) 
		g_iDone[client][i] = 0;
}
public void Q1_Frame(int objectiveID, int client) {
	g_iDuration[client]--;
	
	if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else if( g_iStep[client] >= 10 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		
		int n = rp_PlayerIsInCasinoMachine(client);
		if( n >= 0 && g_iDone[client][n] == 0 ) {
			g_iStep[client]++;
			g_iDone[client][n] = 1;
		}
		
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: Vider les machines à sous: %d/10", QUEST_NAME, g_iDuration[client], g_iStep[client]);
	}
}
public void Q2_Start(int objectiveID, int client) {
	g_iDuration[client] = 12 * 60;
}
public void Q2_Frame(int objectiveID, int client) {
	g_iDuration[client]--;
	
	if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else if( rp_GetZoneInt( rp_GetPlayerZone(client), zone_type_type) == 211 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {		
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: Déposer l'argent à la banque", QUEST_NAME, g_iDuration[client]);
	}
}
public void Q2_End(int objectiveID, int client) {
	
	int cap = rp_GetRandomCapital(91);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 500);
	rp_ClientMoney(client, i_AddToPay, 500);
	
	rp_ClientXPIncrement(client, 1000);
}
public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
}
// ----------------------------------------------------------------------------
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}
