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
#include <colors_csgo>   // https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>      // https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__       "v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>   // https://www.ts-x.eu

//#define DEBUG
#define		QUEST_UNIQID   	"braquage"
#define		QUEST_NAME      "Braquage"
#define		QUEST_TYPE     	quest_group
#define		QUEST_TEAMS			2
#define		TEAM_NONE			-1
#define		TEAM_INVITATION		0
#define		TEAM_BRAQUEUR		1
#define		TEAM_POLICE			2
#define		QUEST_TEAM1		"Braqueur"
#define		QUEST_TEAM2		"Police"


public Plugin myinfo =  {
	name = "Quête: Braquage", author = "KoSSoLaX", 
	description = "RolePlay - Quête Braquage", 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest;
int g_iPlayerTeam[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
		
	int i;
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL, Q1_Frame, QUEST_NULL, QUEST_NULL);
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	return false;
}
public void OnClientPostAdminCheck(int client) {
	g_iPlayerTeam[client] = TEAM_NONE;
}
public void OnClientDisconnect(int client) {
	g_iPlayerTeam[client] = TEAM_NONE;
}
// ----------------------------------------------------------------------------
public void Q1_Frame(int objectiveID, int client) {
	
	if( rp_ClientCanDrawPanel(client) ) {
		char tmp[64];
		
		int countB = 0, countP = 0;
		int stkBraqueur[MAXPLAYERS + 1], stkPolice[MAXPLAYERS + 1];
		
		
		Menu menu = new Menu(MenuInviterBraqueur);
		menu.SetTitle("Quète: %s", QUEST_NAME);
		menu.AddItem("", "------------\nBraqueur confirmé:", ITEMDRAW_DISABLED);
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( g_iPlayerTeam[i] == TEAM_POLICE ) {
				stkPolice[countP++] = i;
				continue;
			}
			if( g_iPlayerTeam[i] == TEAM_BRAQUEUR ) {
				Format(tmp, sizeof(tmp), "%N", i);
				menu.AddItem("", tmp, ITEMDRAW_DISABLED);
				stkBraqueur[countB++] = i;
				continue;
			}
		}
		
		if( countB >= 4 && countP >= 4 ) {
			delete menu;
			rp_QuestSetGroup(g_iQuest, TEAM_BRAQUEUR, stkBraqueur, countB - 1);
			rp_QuestSetGroup(g_iQuest, TEAM_POLICE, stkPolice, countP - 1);
			rp_QuestStepComplete(client, objectiveID);
		}
		
		menu.AddItem("", "------------\nBraqueur en attente:", ITEMDRAW_DISABLED);
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( g_iPlayerTeam[i] != TEAM_INVITATION )
				continue;
		
			Format(tmp, sizeof(tmp), "%N", i);
			menu.AddItem("", tmp, ITEMDRAW_DISABLED);
			DrawMenu_Invitation(client, i);
		}
		
		menu.AddItem("", "------------\nEnvoyer invitation:", ITEMDRAW_DISABLED);
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( rp_GetClientJobID(i) == 1 || rp_GetClientJobID(i) == 101 ) {
				g_iPlayerTeam[i] = TEAM_POLICE;
				continue;
			}
			if( g_iPlayerTeam[i] == 0 )
				continue;
			
			Format(tmp, sizeof(tmp), "%N", i);
			menu.AddItem("", tmp);
		}
		
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
}
void DrawMenu_Invitation(int client, int target) {
	Menu menu = new Menu(MenuInviterBraqueur);
	menu.SetTitle("%N souhaite participer\nà la quète %s\n avec vous dans l'équipe: %s.\n \n Acceptez-vous son invitation?", client, QUEST_NAME);
	menu.AddItem("oui", "Oui");
	menu.AddItem("oui", "Non");
	menu.ExitButton = false;
	
	menu.Display(target, 10);
}
public int MenuInviterBraqueur(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		if( StrEqual(options, "oui") ) {
			g_iPlayerTeam[client] = TEAM_INVITATION;
		}
		else if( StrEqual(options, "oui") ) {
			g_iPlayerTeam[client] = TEAM_NONE;
		}
		else {
			int target = StringToInt(options);
			if( IsValidClient(target) )
				g_iPlayerTeam[target] = TEAM_INVITATION;
		}
		
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
