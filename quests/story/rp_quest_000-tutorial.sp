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
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define QUEST_UNIQID	"000-tutorial"
#define	QUEST_NAME		"Tutorial"
#define	QUEST_TYPE		quest_story

public Plugin myinfo = {
	name = "Quête: Tutorial", author = "KoSSoLaX",
	description = "RolePlay - Quête: Tutorial",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest;

public void OnPluginStart() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	rp_QuestAddStep(g_iQuest, Q1_Start, Q1_Abort, Q1_Done);
	rp_QuestAddStep(g_iQuest, Q1_Start, Q1_Abort, Q1_Done);
	rp_QuestAddStep(g_iQuest, Q1_Start, Q1_Abort, Q1_Done);
	
}
public bool fwdCanStart(int client) {
	return true;
}

public void Q1_Start(int client) {
	PrintToServer("started");
}
public void Q1_Abort(int client) {
	PrintToServer("abort");
}
public void Q1_Done(int client) {
	PrintToServer("done");
}

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
public Action PostKillHandle(Handle timer, any data) {
	if( data!= INVALID_HANDLE )
		CloseHandle(data);
}