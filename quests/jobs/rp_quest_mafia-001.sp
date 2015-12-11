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
#define QUEST_UNIQID	"mafia-001"
#define	QUEST_NAME		"Délivrance"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		91
#define	QUEST_RESUME	"Libérez les prisonniers"

public Plugin myinfo = {
	name = "Quête: Délivrance", author = "KoSSoLaX",
	description = "RolePlay - Quête Mafia: Délivrance",
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
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetClientInt(i, i_JailTime) >= (3*60) ) {
			count++;
		}
	}
	
	if( count >= 2 ) {
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( rp_GetClientInt(i, i_JailTime) >= (12*60) ) {
				int z = rp_GetZoneBit(rp_GetPlayerZone(i));
				if( z & BITZONE_JAIL || z & BITZONE_LACOURS ) 
					return true;
			}
		}
	}
	
	
	return false;
}
public void Q1_Start(int objectiveID, int client) {

	Menu menu = new Menu(MenuNothing);
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Mon frère, l'un de nos hommes a été arrêté.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Nous avons besoin de toi.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "Afin de faire sortir notre homme et qu'il passe", ITEMDRAW_DISABLED);
	menu.AddItem("", "inaperçu, fait sortir un maximum de détenus.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Nous t'offrons 1000$ par personne libérée", ITEMDRAW_DISABLED);
	menu.AddItem("", "Grâce à toi. Pendant toute la durée de ta mission, ", ITEMDRAW_DISABLED);
	menu.AddItem("", "nous t'enverrons du matériel nécessaire à tes opérations.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Tu as 12 heures.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60;
	
	PushArrayCell(g_hDoing, client);
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) || i == client )
			continue;
		rp_HookEvent(i, RP_OnPlayerZoneChange, fwdOnZoneChange);
	}
}
public void Q1_Frame(int objectiveID, int client) {
	
	g_iDuration[client]--;
	
	if( g_iDuration[client] <= 0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME);
	}
	
	if( rp_GetZoneInt( rp_GetPlayerZone(client), zone_type_type ) == 1 ) {
		if( rp_GetClientItem(client, 3) == 0 ) {
			char item[64];
			rp_GetItemData(3, item_type_name, item, sizeof(item));
			rp_ClientGiveItem(client, 3);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu: %s", item);
		}
	}
}
public void Q1_Abort(int objectiveID, int client) {
	RemoveFromArray(g_hDoing, FindValueInArray(g_hDoing, client));
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) || i == client )
			continue;
		rp_UnhookEvent(i, RP_OnPlayerZoneChange, fwdOnZoneChange);
	}
	
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
}
public Action fwdOnZoneChange(int client, int newZone, int oldZone) {
	static zoneID[3] =  { 20, 257, 291 };
	static lastFree[65];
	
	if( lastFree[client] > GetTime() )
		return Plugin_Continue;
	
	
	int length = GetArraySize(g_hDoing);
	for (int i = 0; i < length; i++) {
		int target = GetArrayCell(g_hDoing, i);
		int z = rp_GetPlayerZone(target);
		
		if( target == client )
			continue;
		
		for (int j = 0; j < sizeof(zoneID); j++) {
			if( z == zoneID[j] ) {
				for (int k = 0; k < sizeof(zoneID); k++) {
					if( rp_GetZoneBit(oldZone) & BITZONE_JAIL &&  zoneID[k] == newZone ) {
						
						int cap = rp_GetRandomCapital(91);
						rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 1000);
						rp_SetClientInt(target, i_AddToPay, rp_GetClientInt(target, i_AddToPay) + 1000);
						
						rp_ClientSendToSpawn(client, false);
						
						CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N vous a libéré.", target);
						CPrintToChat(target, "{lightblue}[TSX-RP]{default} vous avez libéré %N et reçu une récompense de 1000$.", client);
						
						lastFree[client] = GetTime() + g_iDuration[client] + 1;
					}
				}
			}
		}
	}
	return Plugin_Continue;
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
