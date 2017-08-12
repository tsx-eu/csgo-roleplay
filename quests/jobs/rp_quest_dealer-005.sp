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


#define QUEST_UNIQID	"dealer-005"
#define	QUEST_NAME		"Vandalisme des distributeurs"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		81

#define MAX_ZONES		310

public Plugin myinfo = {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX",
	description = "RolePlay - Quête Mafia: "...QUEST_NAME,
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iStep[MAXPLAYERS + 1], g_iDoing[MAXPLAYERS + 1], g_iDoneDistrib[MAXPLAYERS + 1][MAX_ZONES];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_PluginReloadSelf);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	Q2_End);
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	if( rp_GetClientJobID(client) != QUEST_JOBID )
		return false;
		
	return true;
}
public void OnClientPostAdminCheck(int client) {
	g_iStep[client] = 0;
}
public Action fwdPiedDeBiche(int client, int type) {
	if( type == 2 && g_iDoing[client] > 0 && g_iDoneDistrib[client][rp_GetPlayerZone(client)] == 0) {
		g_iDoneDistrib[client][rp_GetPlayerZone(client)] = 1;
		rp_QuestStepComplete(client, g_iDoing[client]);
	}
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Mon frère, Nous avons une mission de toi.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Nous voulons faire plier les banquiers.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Pour ça, vandalise les distributeurs", ITEMDRAW_DISABLED);
	menu.AddItem("", "présent dans la ville.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60;
	g_iStep[client] = 0;
	g_iDoing[client] = objectiveID;
	for (int i = 0; i < MAX_ZONES; i++)
		g_iDoneDistrib[client][i] = 0;
	
	rp_HookEvent(client, RP_PostPiedBiche, fwdPiedDeBiche);
}
public void Q1_Frame(int objectiveID, int client) {
	
	g_iDuration[client]--;
	if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: Vandaliser les distributeurs: %d/5", QUEST_NAME, g_iDuration[client], g_iStep[client]);
	}
}
public void Q2_Start(int objectiveID, int client) {
	g_iDoing[client] = objectiveID;
	g_iDuration[client] = 12 * 60;
	g_iStep[client]++;
}
public void Q2_End(int objectiveID, int client) {
	Q1_Abort(objectiveID, client);
	
	int cap = rp_GetRandomCapital(81);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 1250);
	rp_ClientMoney(client, i_AddToPay, 1250);
	
	rp_ClientXPIncrement(client, 500);
}
public void Q1_Abort(int objectiveID, int client) {
	rp_UnhookEvent(client, RP_PostPiedBiche, fwdPiedDeBiche);
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
