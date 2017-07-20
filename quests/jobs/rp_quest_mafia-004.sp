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


#define QUEST_UNIQID	"mafia-004"
#define	QUEST_NAME		"Trafic d'arme"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		91
#define	QUEST_RESUME	"Récupérer les armes"

public Plugin myinfo = {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX",
	description = "RolePlay - Quête Mafia: "...QUEST_NAME,
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iStep[MAXPLAYERS + 1], g_iDoing[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	Q1_Frame,	Q1_Abort,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q3_Start,	Q3_Frame,	Q1_Abort,	Q3_End);
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
		
	for(int i=1; i<MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetClientBool(i, b_IsAFK) )
			continue;
		
		if( GetClientTeam(i) == CS_TEAM_CT || (rp_GetClientInt(i, i_Job) >= 1 && rp_GetClientInt(i, i_Job) <= 7) )
			return true;
	}
	return false;
}
public void OnClientPostAdminCheck(int client) {
	g_iStep[client] = 0;
}
public Action fwdPiedDeBiche(int client, int type) {
	if( type == 3 && g_iDoing[client] > 0 ) {
		rp_QuestStepComplete(client, g_iDoing[client]);
	}
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Mon frère, Nous avons besoin de toi.", ITEMDRAW_DISABLED);
	menu.AddItem("", "La police a acheté des nouveaux", ITEMDRAW_DISABLED);
	menu.AddItem("", "prototype d'arme.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Vol les.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60;
	g_iStep[client] = 0;
	g_iDoing[client] = objectiveID;
	rp_HookEvent(client, RP_PostPiedBiche, fwdPiedDeBiche);
}
public void Q1_Frame(int objectiveID, int client) {
	
	g_iDuration[client]--;
	if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s %d/3", QUEST_NAME, g_iDuration[client], QUEST_RESUME, g_iStep[client]);
	}
}
public void Q2_Start(int objectiveID, int client) {
	g_iDoing[client] = objectiveID;
	g_iDuration[client] = 12 * 60;
	g_iStep[client]++;
}
public void Q3_Start(int objectiveID, int client) {
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Interlocuteur anonyme : Tu as les armes, rapporte les nous au plus vite à la planque !");

	g_iDuration[client] = 6 * 60;
	g_iStep[client] = 0;
}
public void Q3_Frame(int objectiveID, int client) {
	static float dst[3] =  { -316.2, 3204.1, -2119.9 };
	float vec[3];
	GetClientAbsOrigin(client, vec);
	
	g_iDuration[client]--;
	if( rp_GetPlayerZone(client) == rp_GetZoneFromPoint(dst) ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: Retourner à la planque", QUEST_NAME, g_iDuration[client]);
		ServerCommand("sm_effect_gps %d %f %f %f", client, dst[0], dst[1], dst[2]);
	}
}
public void Q3_End(int objectiveID, int client) {
	Q1_Abort(objectiveID, client);
	
	int cap = rp_GetRandomCapital(91);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 2500);
	rp_ClientMoney(client, i_AddToPay, 2500);
	
	rp_ClientXPIncrement(client, 1250);
}
public void Q1_Abort(int objectiveID, int client) {
	g_iDoing[client] = 0;
	rp_UnhookEvent(client, RP_PostPiedBiche, fwdPiedDeBiche);
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
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
