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


#define QUEST_UNIQID	"dealer-004"
#define	QUEST_NAME		"Razzia"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		81
#define	QUEST_RESUME	""


public Plugin myinfo = {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX",
	description = "RolePlay - Quête Dealer: "...QUEST_NAME,
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDoing[MAXPLAYERS + 1], g_iDuration[MAXPLAYERS + 1], g_iCount[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_PluginReloadSelf);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	Q1_Done);
	
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	if( rp_GetClientJobID(client) != QUEST_JOBID )
		return false;
	
	int count = 0;
	char tmp[64];
	for (int i = MaxClients; i < 2048; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, sizeof(tmp));
		
		if( StrContains(tmp, "weapon_") == 0 && !StrEqual(tmp, "weapon_knife") ) {
			count++;
		}
		
		
	}
	
	return (count>=10);
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Hey gros, il est temps d'éliminer la concurance", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Tu as 12 heures pour voler le marché d'arme", ITEMDRAW_DISABLED);
	menu.AddItem("", "de la police, ou de voler le marché noire", ITEMDRAW_DISABLED);
	menu.AddItem("", "de la mafia ou encore de revendre des armes", ITEMDRAW_DISABLED);
	menu.AddItem("", "au marché noire des dealers.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60;
	g_iDoing[client] = true;
	rp_SetClientInt(client, i_Disposed, rp_GetClientInt(client, i_Disposed) + 1);
	rp_HookEvent(client, RP_OnResellWeapon, fwdResellWeapon);
	rp_HookEvent(client, RP_OnBlackMarket, fwdBlackMarket);
}
public void Q1_Frame(int objectiveID, int client) {
	g_iDuration[client]--;
	
	if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else if( g_iCount[client] >= 10 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s %d/10", QUEST_NAME, g_iDuration[client], QUEST_RESUME, g_iCount[client]);
	}
}
public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	g_iDoing[client] = false;
	
	rp_UnhookEvent(client, RP_OnResellWeapon, fwdResellWeapon);
	rp_UnhookEvent(client, RP_OnBlackMarket, fwdBlackMarket);
}

public Action fwdResellWeapon(int client, int weaponID, int realPrice) {
	int cap = rp_GetRandomCapital(QUEST_JOBID);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - realPrice);
	rp_ClientMoney(client, i_AddToPay, realPrice);
	rp_SetClientInt(client, i_Disposed, rp_GetClientInt(client, i_Disposed) + 1);
	g_iCount[client]++;
}

public Action fwdBlackMarket(int client, int jobID, int target, int victim, int& prix, int arg) {
	if( prix == 0 ) {
		if( jobID == 1 || (jobID == 91 && victim != client ) ) {
			int cap = rp_GetRandomCapital(QUEST_JOBID);
			rp_SetJobCapital(cap, rp_GetJobCapital(cap) - arg);
			rp_ClientMoney(client, i_AddToPay, arg);
			g_iCount[client]++;
		}
	}
}
public void Q1_Done(int objectiveID, int client) {
	Q1_Abort(objectiveID, client);
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
