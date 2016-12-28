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
#define QUEST_UNIQID	"justice-002"
#define	QUEST_NAME		"La justice express"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		101
#define	QUEST_RESUME	"Condamnez un joueur à au moins 3h/100$"

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
	rp_QuestAddStep(g_iQuest, i++,	Q_Start,	Q_Frame,	Q_Abort,	Q_Done);
	rp_QuestAddStep(g_iQuest, i++,	Q_Start,	Q_Frame,	Q_Abort,	Q_Done);
	rp_QuestAddStep(g_iQuest, i++,	Q_Start,	Q_Frame,	Q_Abort,	Q_Done);
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
	if( job >= 101 && job <= 106 )
		return true;
	
	return false;
}
public Action fwdJugementOver(int client, int data[6], int charges[28]) {
	if( data[2] >= 3 && data[3] >= 100 ) {
		rp_QuestStepComplete(client, g_iDoing[client]);
	}
}
public void Q_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Maître, nous vous accordons un bonus pour", ITEMDRAW_DISABLED);
	menu.AddItem("", "vos 3 prochaines condamnations.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Pendant ces 24 prochaines heures condamnez.", ITEMDRAW_DISABLED);
	menu.AddItem("", "3 joueurs différents dans votre Tribunal.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Ils devront avoir une amende d'au moins 100$.", ITEMDRAW_DISABLED);
	menu.AddItem("", "ainsi que 3 heures de prison, chacun.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDoing[client] = objectiveID;
	rp_HookEvent(client, RP_OnJugementOver, fwdJugementOver);	
	g_iDuration[client] = 24 * 60;
}
public void Q_Frame(int objectiveID, int client) {
	g_iDuration[client]--;
	if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {			
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME);
	}
}
public void Q_Abort(int objectiveID, int client) {
	rp_UnhookEvent(client, RP_OnJugementOver, fwdJugementOver);
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée", QUEST_NAME);
}
public void Q_Done(int objectiveID, int client) {
	Q_Abort(objectiveID, client);
	
	int cap = rp_GetRandomCapital(101);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 500);
	rp_ClientMoney(client, i_AddToPay, 500);
	
	rp_ClientXPIncrement(client, 750);
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