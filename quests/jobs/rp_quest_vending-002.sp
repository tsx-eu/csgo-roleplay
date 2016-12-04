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

//#define DEBUG
#define QUEST_UNIQID   "vending-002"
#define QUEST_NAME      "Employé modèle"
#define QUEST_TYPE      quest_daily
#define QUEST_RESUME   "Vendre pour 10.000$"
#define QUEST_ITEM      236

public Plugin myinfo =  {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX", 
	description = "RolePlay - Quête Vente: "...QUEST_NAME, 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iCurrent[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++, Q1_Start, Q1_Frame, Q1_Abort, Q1_End);
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	int jobList[] =  { 11, 21, 31, 41, 51, 61, 71, 81, 111, 121, 131, 171, 191, 211, 221 };
	int job = rp_GetClientJobID(client);
	
	for (int i = 0; i < sizeof(jobList); i++) {
		if( jobList[i] == job )
			return true;
	}
	
	return false;
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Bonjour collègue, on a de nouveaux projets pour toi.", ITEMDRAW_DISABLED);
	menu.AddItem("", "On t'offre un bonus de 2500$", ITEMDRAW_DISABLED);
	menu.AddItem("", "si tu arrives à vendre pour plus de 10 000$", ITEMDRAW_DISABLED);
	menu.AddItem("", "en moins de 24 heures.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 24 * 60;
	g_iCurrent[client] = 0;
	rp_HookEvent(client, RP_OnPlayerSell, fwdSell);
}
public Action fwdSell(int client, int amount) {
	g_iCurrent[client] += amount;
	return Plugin_Continue;
}
public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	rp_UnhookEvent(client, RP_OnPlayerSell, fwdSell);
}
public void Q1_Frame(int objectiveID, int client) {
	
	g_iDuration[client]--;
	
	if( g_iCurrent[client] >= 10000 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if (g_iDuration[client] <= 0) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s (%d%%)", QUEST_NAME, g_iDuration[client], QUEST_RESUME, RoundToFloor(g_iCurrent[client]/10000.0*100.0));
	}
}
public void Q1_End(int objectiveID, int client) {
	Q1_Abort(objectiveID, client);
	
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Votre chef vous remercie !", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 10);
	
	int cap = rp_GetClientJobID(client);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 1000);
	rp_ClientMoney(client, i_AddToPay, 1000);
	
	rp_ClientXPIncrement(client, 2500);
}
// ----------------------------------------------------------------------------
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		if (menu != INVALID_HANDLE)
			CloseHandle(menu);
	}
	else if (action == MenuAction_End) {
		if (menu != INVALID_HANDLE)
			CloseHandle(menu);
	}
}
