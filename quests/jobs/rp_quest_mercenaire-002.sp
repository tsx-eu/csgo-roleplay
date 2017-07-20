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


#define QUEST_UNIQID	"mercenaire-002"
#define	QUEST_NAME		"Un coup de main pour la justice"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		41
#define	QUEST_RESUME1	"Capturez un recherché"


public Plugin myinfo = {
	name = "Quête: "...QUEST_NAME, author = "Leethium",
	description = "RolePlay - Quête Mercenaire: "...QUEST_NAME,
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iToKill[MAXPLAYERS + 1], g_ObjectiveID;
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
	
	g_hDoing = CreateArray(MAXPLAYERS);
}

public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}

public bool fwdCanStart(int client) {
	if( rp_GetClientJobID(client) != QUEST_JOBID )
		return false;

	if(getToKill(client) == -1){
		return false;
	}

	if(rp_GetClientInt(client, i_ToKill) > 0)
		return false;

	return true;
}

public void Q1_Start(int objectiveID, int client) {
	g_ObjectiveID = objectiveID;
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "La justice a besoin de vous,", ITEMDRAW_DISABLED);
	menu.AddItem("", "une personne est actuellement recherchée.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Votre mission si vous l'acceptez est de la capturer", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Vous avez 12 heures pour capturer le recherché.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60 + 5;
	PushArrayCell(g_hDoing, client);

	CreateTimer(5.0, timerStartQuest, client); 
}

public Action timerStartQuest(Handle timer, any client) {
	int tokill = getToKill(client);
	if(tokill == -1){
		rp_QuestStepFail(client, g_ObjectiveID);
	}
	else{
		g_iToKill[client] = tokill;
		ServerCommand("rp_item_contrat justice %d %d %d 0", client, tokill, client);
		rp_HookEvent(client, RP_OnPlayerDead, fwdTueurDead);
		rp_HookEvent(tokill, RP_OnPlayerDead, fwdTueurKill);
		rp_HookEvent(tokill, RP_PostTakeDamageWeapon, fwdWeapon);
	}
	if(!IsValidClient(g_iToKill[client]))
		rp_QuestStepFail(client, g_ObjectiveID);
}
public Action fwdTueurDead(int client, int attacker, float& respawn) {
    int target = rp_GetClientInt(client, i_ToKill);
    if( target > 0  && attacker == target) {
        rp_QuestStepFail(client, g_ObjectiveID);
    }
}
public Action fwdTueurKill(int client, int attacker, float& respawn) {
	
	if(g_iToKill[attacker] == client){
		rp_QuestStepComplete(attacker, g_ObjectiveID);
	}
}

public void Q1_Frame(int objectiveID, int client) {
	g_iDuration[client]--;

	if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME1);
	}
}

public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	RemoveFromArray(g_hDoing, FindValueInArray(g_hDoing, client));
	rp_UnhookEvent(client, RP_OnPlayerDead, fwdTueurDead);
	rp_UnhookEvent(g_iToKill[client], RP_OnPlayerDead, fwdTueurKill);
	rp_UnhookEvent(g_iToKill[client], RP_PostTakeDamageWeapon, fwdWeapon);
	g_iToKill[client] = 0;
}

public void Q1_Done(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	rp_UnhookEvent(client, RP_OnPlayerDead, fwdTueurDead);
	rp_UnhookEvent(g_iToKill[client], RP_OnPlayerDead, fwdTueurKill);
	rp_UnhookEvent(g_iToKill[client], RP_PostTakeDamageWeapon, fwdWeapon);
	g_iToKill[client] = 0;
	
	int cap = rp_GetRandomCapital(QUEST_JOBID);
	
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 1000);
	rp_ClientMoney(client, i_AddToPay, 1000);
	rp_ClientXPIncrement(client, 750);
}

public int getToKill(int client){
	for (int i = 1; i <= MaxClients; i++){
		if(client == i)
			continue;
		if(!IsValidClient(i))
			continue;
		if(rp_GetClientBool(i, b_IsSearchByTribunal)){
			if( rp_GetZoneBit( rp_GetPlayerZone(i) ) & BITZONE_JAIL )
				continue;

			return i;
		}
	}
	return -1;
}

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

public Action fwdWeapon(int victim, int attacker, float &damage, int wepID, float pos[3]) {
	if(g_iToKill[attacker] == victim){
		damage *= 2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
