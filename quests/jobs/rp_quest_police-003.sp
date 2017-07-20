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


#define QUEST_UNIQID	"police-003"
#define	QUEST_NAME		"Non à la contrebande"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		1
#define	QUEST_RESUME1	"Tazez les objets illégaux"

public Plugin myinfo = {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX",
	description = "RolePlay - Quête Police: "...QUEST_NAME,
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
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	Q1_Abort);
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
	if( rp_GetClientInt(client, i_Job) == 8 || rp_GetClientInt(client, i_Job) == 9 )
		return false;

	return (countBlackMarket(client)>5);
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Collègue, nous avons besoin que vous ", ITEMDRAW_DISABLED);
	menu.AddItem("", "tasiez un maximum d'objets illégaux en ville.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Pendant les 24 prochaines heures, nous doublons tes gains", ITEMDRAW_DISABLED);
	menu.AddItem("", "de chaque plants de drogue et machines détruites.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 24 * 60;
	g_iDoing[client] = true;
	rp_HookEvent(client, RP_OnClientTazedItem, fwdTazedItem);
}
public void Q1_Frame(int objectiveID, int client) {
	g_iDuration[client]--;
	
	if( g_iDuration[client] <= 0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		int v = nearestBlackMarket(client);
		if( v > 0 )
			rp_Effect_BeamBox(client, v, NULL_VECTOR, 255, 255, 255);
		
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME1);
	}
}
public void Q1_Abort(int objectiveID, int client) {
	rp_UnhookEvent(client, RP_OnClientTazedItem, fwdTazedItem);
	g_iDoing[client] = false;
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
}
public Action fwdTazedItem(int client, int reward) {
	if( g_iDoing[client] ) {
		rp_ClientMoney(client, i_AddToPay, reward);
		rp_ClientXPIncrement(client, reward / 10);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez gagnez %d$ supplémentaires grace à la quête %s.", reward, QUEST_NAME);
	}
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


int countBlackMarket(int client) {
	char classname[64];
	int amount = 0;
	
	for (int i = MaxClients; i <= 2048; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( StrEqual(classname, "rp_cashmachine") || StrEqual(classname, "rp_bigcashmachine") || StrEqual(classname, "rp_plant") ) {
			if( rp_GetBuildingData(i, BD_started)+120 < GetTime() && rp_GetBuildingData(i, BD_owner) != client )
				amount++;
		}
	}
	return amount;
}
int nearestBlackMarket(int client) {
	float vecOrigin[3], vecDestination[3], vecMaxDIST = 999999999.9, tmp;
	char classname[64];
	int val = -1;
	Entity_GetAbsOrigin(client, vecOrigin);
	
	for (int i = MaxClients; i <= 2048; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( StrEqual(classname, "rp_cashmachine") || StrEqual(classname, "rp_bigcashmachine") || StrEqual(classname, "rp_plant") ) {
			if( rp_GetBuildingData(i, BD_started)+120 < GetTime() && rp_GetBuildingData(i, BD_owner) != client ) {
			
				Entity_GetAbsOrigin(i, vecDestination);
				tmp = GetVectorDistance(vecOrigin, vecDestination);
				if( tmp < vecMaxDIST ) {
					vecMaxDIST = tmp;
					val = i;
				}
			}
		}
	}
	return val;
}
