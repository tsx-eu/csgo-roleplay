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
#define QUEST_UNIQID	"justice-001"
#define	QUEST_NAME		"La justice sournoise"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		101
#define	QUEST_RESUME1	"Tendez lui un piège"
#define	QUEST_RESUME2	"Condamnez-le"

// TODO: Pouvoir sélectionner un complice

public Plugin myinfo = {
	name = "Quête: La justice sournoise", author = "KoSSoLaX",
	description = "RolePlay - Quête Justice: La justice sournoise",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iDoing[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	Q1_Abort);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q2_Frame,	Q1_Abort,	Q2_Done);
	
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
		return (findNearestSerialKiller(client)>=1);
	
	return false;
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Maitre, nos informations indiquent qu'un meurtrier", ITEMDRAW_DISABLED);
	menu.AddItem("", "en série fait rage en ville.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Nous avons besoin qu'il aille pourrir en taule.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Assurez-vous, qu'un joueur se fasse tuer par lui.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Ensuite, ce joueur porte plainte contre ce meurtrier.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Après quoi, il vous serra possible de faire régner", ITEMDRAW_DISABLED);
	menu.AddItem("", "la justice.", ITEMDRAW_DISABLED); 
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", " Tu as 24 heures pour faire condamner ce joueur.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Il doit avoir une amende d'au moins 100$.", ITEMDRAW_DISABLED);
	menu.AddItem("", "ainsi que 3heures de prison.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 24 * 60;
}
public void Q1_Frame(int objectiveID, int client) {
	
	g_iDuration[client]--;
	int nearest = findNearestSerialKiller(client);
	
	if( nearest >= 1 && rp_GetZoneInt(rp_GetPlayerZone(nearest), zone_type_type) == 101 ) {
		g_iDoing[client] = nearest;
		rp_QuestStepComplete(client, objectiveID);
	}
	else if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		if( nearest > 0 )
			rp_Effect_BeamBox(client, nearest, NULL_VECTOR, 255, 255, 255);
			
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME1);
	}
}
public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée", QUEST_NAME);
}
public void Q2_Start(int objectiveID, int client) {
	
	if( rp_ClientCanDrawPanel(client) ) {
		Menu menu = new Menu(MenuNothing);
		
		menu.SetTitle("Quète: %s", QUEST_NAME);
		menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
		menu.AddItem("", "Il est dans le Tribunal!", ITEMDRAW_DISABLED);
		menu.AddItem("", "Condamner le avec au moins 100$ d'amende", ITEMDRAW_DISABLED);
		menu.AddItem("", "et de 3 heures de prison.", ITEMDRAW_DISABLED);
		
		menu.ExitButton = false;
		menu.Display(client, 10);
	}
	
	g_iDuration[client] = 6 * 60;
}
public void Q2_Frame(int objectiveID, int client) {
	
	g_iDuration[client]--;
	int nearest = g_iDoing[client];
	
	if( rp_GetClientInt(nearest, i_LastAmende) > 100 && rp_GetClientInt(nearest, i_LastAmendeBy) == client && 
		rp_GetClientInt(nearest, i_JailledBy) == client && rp_GetClientInt(nearest, i_JailTime) >= (3*60)-10 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME1);
	}
}
public void Q2_Done(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée", QUEST_NAME);
	
	int cap = rp_GetRandomCapital(101);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 5000);
	rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + 5000);
	
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
int findNearestSerialKiller(int client) {
	float vecOrigin[3], vecDestination[3], vecMaxDIST = 999999999.9, tmp;
	Entity_GetAbsOrigin(client, vecOrigin);
	
	int val = -1;
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( i == client )
			continue;
		if( rp_GetClientInt(i, i_KillingSpread) < 5 )
			continue;
		if( rp_GetZoneBit( rp_GetPlayerZone(i) ) & BITZONE_JAIL )
			continue;
		
		Entity_GetAbsOrigin(i, vecDestination);
		tmp = GetVectorDistance(vecOrigin, vecDestination);
		if( tmp < vecMaxDIST ) {
			vecMaxDIST = tmp;
			val = i;
		}
	}
	
	return val;
}
