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
#define QUEST_UNIQID	"police-001"
#define	QUEST_NAME		"Suivez le lapin blanc"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		1
#define	QUEST_RESUME1	"Pourchasser le tueur en série"
#define	QUEST_RESUME2	"Arrêtez-le"


// TODO: Gérer le cas ou le mec à 5tdm puis 4 :c

public Plugin myinfo = {
	name = "Quête: Suivez le lapin blanc", author = "KoSSoLaX",
	description = "RolePlay - Quête Police: Suivez le lapin blanc",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1];

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
	return false;/*
	int job = rp_GetClientInt(client, i_Job);
	
	if( job >= 1 && job <= 9 || job == 107 || job == 108 || job == 109 ) // Police + marshall + gonu + gos
		return (findNearestSerialKiller(client)>=1);
	
	return false;
	*/
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Collègue, nos informations indiquent qu'un meurtrier", ITEMDRAW_DISABLED);
	menu.AddItem("", "en série fait rage en ville.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Nous avons besoin de le prendre en flagrant délit.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Prends le en filature, jusqu'à ce qu'il commette", ITEMDRAW_DISABLED);
	menu.AddItem("", "un meurtre. Ensuite, arrête le.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Il est important de ne pas te faire répérer,", ITEMDRAW_DISABLED);
	menu.AddItem("", "si l'assassin te voit, il ne commettra pas de crime.", ITEMDRAW_DISABLED); 
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Tu as 12 heures pour le prendre en flagrant délit.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60;
}
public void Q1_Frame(int objectiveID, int client) {
	
	g_iDuration[client]--;
	int nearest = findNearestSerialKiller(client);
	
	
	if( rp_IsTargetSeen(client, nearest) && rp_GetZoneInt(rp_GetPlayerZone(nearest), zone_type_private) == 0 && rp_GetClientInt(nearest, i_LastKillTime)+3 > GetTime() ) { 
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
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
}
public void Q2_Start(int objectiveID, int client) {
	
	if( rp_ClientCanDrawPanel(client) ) {
		Menu menu = new Menu(MenuNothing);
		
		menu.SetTitle("Quète: %s", QUEST_NAME);
		menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
		menu.AddItem("", "Il a tué ! Arrêtez le !", ITEMDRAW_DISABLED);
		menu.AddItem("", "Quoi qu'il en coûte !", ITEMDRAW_DISABLED);
		
		
		menu.ExitButton = false;
		menu.Display(client, 10);
	}
	
	g_iDuration[client] = 1 * 60;
}
public void Q2_Frame(int objectiveID, int client) {
	
	g_iDuration[client]--;
	int nearest = findNearestSerialKiller(client);
	
	if( rp_GetClientInt(nearest, i_JailledBy) == client ) {
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
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	
	int cap = rp_GetRandomCapital(1);
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
		if( rp_GetClientBool(i, b_IsAFK) )
			continue;
		if( rp_GetZoneBit( rp_GetPlayerZone(i) ) & BITZONE_JAIL )
			continue;
		if( rp_GetZoneBit( rp_GetPlayerZone(i) ) & BITZONE_HAUTESECU )
			continue;
		if( rp_GetZoneBit( rp_GetPlayerZone(i) ) & BITZONE_LACOURS )
			continue;
		if( rp_GetZoneBit( rp_GetPlayerZone(i) ) & BITZONE_EVENT )
			continue;
		
		if( rp_GetClientInt(i, i_KillingSpread) < 5 )
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
