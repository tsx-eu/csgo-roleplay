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
#define QUEST_UNIQID	"dealer-002"
#define	QUEST_NAME		"Récolte des plants"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		81
#define	QUEST_RESUME	"Récolter des drogues sur la place"


public Plugin myinfo = {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX",
	description = "RolePlay - Quête Dealer: "...QUEST_NAME,
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iCount[MAXPLAYERS + 1], g_iStep[MAXPLAYERS + 1];
Handle g_hDoing;

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	Q1_Done);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	Q1_Done);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	Q1_Done);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	Q1_Done);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	Q2_Done);
	
	
	g_hDoing = CreateArray(MAXPLAYERS);
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
	
	int count = 0;
	for(int i=1; i<MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetClientBool(i, b_IsAFK) )
			continue;
			
		if( GetClientTeam(i) == CS_TEAM_CT || (rp_GetClientInt(i, i_Job) >= 1 && rp_GetClientInt(i, i_Job) <= 7 ) )
			count++;
	}
	
	return (count>=1);
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Hey gros, on a un nouveau gros client et nous", ITEMDRAW_DISABLED);
	menu.AddItem("", "avons besoin de toi pour une nouvelle fournée.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Tu as 5x6 heures pour déraciner", ITEMDRAW_DISABLED);
	menu.AddItem("", "5 plants sur la place de l'indépendance.", ITEMDRAW_DISABLED);
	
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 6 * 60;
	g_iCount[client] = 5;
	PushArrayCell(g_hDoing, client);
}
public void Q1_Frame(int objectiveID, int client) {
	g_iDuration[client]--;
	g_iStep[client] = objectiveID;
	
	if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s %d/5", QUEST_NAME, g_iDuration[client], QUEST_RESUME, g_iCount[client]-5);
	}
}
public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	RemoveFromArray(g_hDoing, FindValueInArray(g_hDoing, client));
}
public void RP_OnClientPiedBiche(int client) {
	int length = GetArraySize(g_hDoing);
	for (int i = 0; i < length; i++) {
		if( GetArrayCell(g_hDoing, i) == client ) {
			rp_QuestStepComplete(client, g_iStep[client]);
		}
	}
}
public void Q1_Done(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	
	int cap = rp_GetRandomCapital(QUEST_JOBID);
	
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 1000);
	rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + 1000);	
}
public void Q2_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Tu as 6 heures pour déraciner", ITEMDRAW_DISABLED);
	menu.AddItem("", "un autre plant sur la place de l'indépendance.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 6 * 60;
	g_iCount[client]--;
}
public void Q2_Done(int objectiveID, int client) {
	Q1_Done(objectiveID, client);
	RemoveFromArray(g_hDoing, FindValueInArray(g_hDoing, client));
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
