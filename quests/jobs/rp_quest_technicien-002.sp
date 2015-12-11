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
#define QUEST_UNIQID	"tech-002"
#define	QUEST_NAME		"Surveillance des machines"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		221
#define	QUEST_RESUME1	"Déposer 10 machines"
#define	QUEST_RESUME2	"Protège tes machines"


public Plugin myinfo = {
	name = "Quête: Surveillance des machines", author = "KoSSoLaX",
	description = "RolePlay - Quête Technicien: Surveillance des machines",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1];
Handle g_hDoing;

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	Q1_Abort);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q2_Frame,	Q2_Abort,	Q2_Done);
	
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
	
	return true;
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Hey gros, on a un nouveau prototype d'imprimante et nous", ITEMDRAW_DISABLED);
	menu.AddItem("", "avons besoin de toi pour les essayer !", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Tu as 12 heures pour poser 10 imprimantes", ITEMDRAW_DISABLED);
	menu.AddItem("", "dans ta planque.", ITEMDRAW_DISABLED);
	
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60;
	PushArrayCell(g_hDoing, client);
}
public void Q1_Frame(int objectiveID, int client) {
	g_iDuration[client]--;
	int count = countMachine(client);
	
	if( count >= 10 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s %d/10", QUEST_NAME, g_iDuration[client], QUEST_RESUME1, count);
	}
}
public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	RemoveFromArray(g_hDoing, FindValueInArray(g_hDoing, client));
}
public void Q2_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Parfait, assure toi que ces machines produisent", ITEMDRAW_DISABLED);
	menu.AddItem("", "suffisamment longtemps.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Protège tes machines durant 24 heures.", ITEMDRAW_DISABLED);
	
	
	menu.ExitButton = false;
	menu.Display(client, 30);
	g_iDuration[client] = 24 * 60;
}
public void RP_OnClientMaxMachineCount(int client, int& max) {
	int length = GetArraySize(g_hDoing);
	for (int i = 0; i < length; i++) {
		if( GetArrayCell(g_hDoing, i) == client && rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) == QUEST_JOBID ) {
			max += 10000;
		}
	}
}
public void Q2_Frame(int objectiveID, int client) {
	g_iDuration[client]--;
	
	if( countMachine(client) == 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else if( g_iDuration[client] <= 0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME2);
	}
}
public void Q2_Done(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	
	int cap = rp_GetRandomCapital(QUEST_JOBID);
	int amount = countMachine(client) * 500;
	
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - amount);
	rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + amount);	
}
public void Q2_Abort(int objectiveID, int client) {
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
int countMachine(int client) {
	int count = 0;
	char classname[64];
	
	for (int i = MaxClients; i <= 2048; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( StrContains(classname, "rp_cashmachine_") == 0 && rp_GetBuildingData(i, BD_owner) == client ) {
			if( rp_GetZoneInt(rp_GetPlayerZone(i), zone_type_type) == QUEST_JOBID )
				count++;
		}
	}
	return count;
}
