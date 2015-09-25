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
#define QUEST_UNIQID	"mafia-002"
#define	QUEST_NAME		"Où est Charlie?"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		91
#define	QUEST_RESUME	"Infiltrer:"

#define	MAX_ZONES		300

public Plugin myinfo = {
	name = "Quête: Où est Charlie?", author = "KoSSoLaX",
	description = "RolePlay - Quête Mafia: Où est Charlie?",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iGoing[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	Q1_Abort);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	Q1_Abort);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	Q1_Abort);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	Q1_Abort);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	Q1_Abort);
	
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
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Mon frère, l'un de nos hommes a disparu.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Nous avons besoin de toi.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "Vous devez enquêtez sur ses traces pour le retrouver.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Infiltrez-vous dans les bâtiments suivants.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Nous t'offrons 1000$ par bâtiments infiltrés.", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Pendant toute la durée de votre mission, ", ITEMDRAW_DISABLED);
	menu.AddItem("", "nous t'environs du matériel nécéessaire à votre réussite.", ITEMDRAW_DISABLED);
	menu.AddItem("", " Vous avez 6 heures.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	Q2_Start(objectiveID, client);
}
public void Q2_Start(int objectiveID, int client) {
	g_iDuration[client] = 6 * 60;
	g_iGoing[client] = getRandomLocation();
}
public void Q1_Frame(int objectiveID, int client) {
	
	char buffer[128];
	float min[3], max[3], dst[3];
	rp_GetZoneData(g_iGoing[client], zone_type_name, buffer, sizeof(buffer));
	min[0] = float(rp_GetZoneInt(g_iGoing[client], zone_type_min_x));
	min[1] = float(rp_GetZoneInt(g_iGoing[client], zone_type_min_y));
	min[2] = float(rp_GetZoneInt(g_iGoing[client], zone_type_min_z));
	max[0] = float(rp_GetZoneInt(g_iGoing[client], zone_type_min_x));
	max[1] = float(rp_GetZoneInt(g_iGoing[client], zone_type_min_y));
	max[2] = float(rp_GetZoneInt(g_iGoing[client], zone_type_min_z));
	
	for (int i = 0; i < 3; i++) 
		dst[i] = (min[i] + max[i]) / 2.0;
	
	GetClientAbsOrigin(client, min);
	GetClientEyePosition(client, max);
	
	g_iDuration[client]--;
	
	if( GetVectorDistance(dst, min) < 60.0 || GetVectorDistance(dst, max) < 60.0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if( g_iDuration[client] <= 0 ) {
		// TODO: ECHEC MISSION :(
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME, buffer);
		rp_Effect_BeamBox(client, -1, dst, 255, 255, 255);
	}
	
	if( rp_GetZoneInt( rp_GetPlayerZone(client), zone_type_type ) == 1 ) {
		if( rp_GetClientItem(client, 3) == 0 ) {
			char item[64];
			rp_GetItemData(3, item_type_name, item, sizeof(item));
			rp_ClientGiveItem(client, 2);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu: %s", item);
		}
	}
}
public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée", QUEST_NAME);
}
int getRandomLocation() {
	int stack[MAX_ZONES], cpt, tmp;
	char buffer[32];
	
	for (int i = 0; i < MAX_ZONES; i++) {
		rp_GetZoneData(i, zone_type_type, buffer, sizeof(buffer));
		
		tmp = StringToInt(buffer);
		
		if( ( tmp>0 && tmp != 91 && tmp != 181 ) || StrContains(buffer, "appart_") == 0 ) {
			stack[cpt++] = i;
		}
	}
	
	return stack[Math_GetRandomInt(0, --cpt)];
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
