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

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define QUEST_UNIQID	"justice-003"
#define	QUEST_NAME		"Un homme très recherché"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		1
#define	QUEST_RESUME	"Arrêtez-le"

public Plugin myinfo = {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX",
	description = "RolePlay - Quête Justice: "...QUEST_NAME,
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iDoing[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	Q1_Done);
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	int job = rp_GetClientInt(client, i_Job);
	if( (job == 107 || job == 108 || job == 107) || (job >= 1 && job <= 9))
		return (playerMatch() >= 1);
	
	return false;
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quête: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Collègue, nous vous informons qu'un homme ", ITEMDRAW_DISABLED);
	menu.AddItem("", "est recherché par le Tribunal.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", " Vous avez 12 heures pour le trouver, et l'arrêter.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60;
	g_iDoing[client] = playerMatch();
}
public void Q1_Frame(int objectiveID, int client) {
	
	g_iDuration[client]--;
	int nearest = g_iDoing[client];
	bool found = (rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) || (rp_GetZoneBit(rp_GetPlayerZone(client)) & BITZONE_JAIL));
	
	if( found && rp_GetClientInt(nearest, i_JailledBy) == client ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if( found ) {
		g_iDoing[client] = playerMatch();
		if( g_iDoing[client] == 0 ) 
			rp_QuestStepFail(client, objectiveID);
	}
	else if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		if( nearest > 0 )
			rp_Effect_BeamBox(client, nearest, NULL_VECTOR, 255, 255, 255);
		
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME);
	}
}
public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
}
public void Q1_Done(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	
	int cap = rp_GetRandomCapital(101);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 2500);
	rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + 2500);	
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
int playerMatch() {
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		if( rp_GetClientBool(i, b_IsSearchByTribunal) )
			return i;
	}
	return 0;
}
