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
#define QUEST_UNIQID	"justice-001"
#define	QUEST_NAME		"La justice sournoise"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		101
#define	QUEST_RESUME	"Condamner un citoyen pour un double homicide"

public Plugin myinfo = {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX",
	description = "RolePlay - Quête Justice: "...QUEST_NAME,
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDoing[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q_Start,	Q_Frame,	Q_Abort,	Q_End);
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
		return (getSerialKillerCount(client)>=2);
	
	return false;
}
public void Q_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Maître, nos informations indiquent qu'un meurtrier", ITEMDRAW_DISABLED);
	menu.AddItem("", "en série fait rage en ville.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Veuillez condamner à citoyen pour double homicide.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDoing[client] = objectiveID;
	rp_HookEvent(client, RP_OnJugementOver, fwdJugementOver);
}
public Action fwdJugementOver(int client, int data[6], int charges[28]) {
	if( data[2] >= 1 && data[3] >= 1 && charges[0] >= 2 ) {
		rp_QuestStepComplete(client, g_iDoing[client]);
	}
}
public void Q_Frame(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\n<b>Objectif</b>: %s", QUEST_NAME, QUEST_RESUME);
}
public void Q_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	rp_UnhookEvent(client, RP_OnJugementOver, fwdJugementOver);
}
public void Q_End(int objectiveID, int client) {
	Q_Abort(objectiveID, client);
	
	int cap = rp_GetRandomCapital(101);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 2500);
	rp_ClientMoney(client, i_AddToPay, 2500);
	
	rp_ClientXPIncrement(client, 2500);
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
int getSerialKillerCount(int client) {
	int cpt = 0;
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( i == client )
			continue;
		if( rp_GetClientBool(i, b_IsAFK) )
			continue;
		if( rp_GetZoneBit( rp_GetPlayerZone(i) ) & (BITZONE_JAIL|BITZONE_HAUTESECU|BITZONE_LACOURS|BITZONE_EVENT) )
			continue;
		
		if( rp_GetClientInt(i, i_KillingSpread) >= 1 )
			cpt++;
		
	}
	
	return cpt;
}
