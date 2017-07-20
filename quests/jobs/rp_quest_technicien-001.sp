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


#define QUEST_UNIQID	"tech-001"
#define	QUEST_NAME		"Sous écoute"
#define	QUEST_TYPE		quest_daily
#define	QUEST_JOBID		221
#define	QUEST_RESUME	"Retirer les mouchards"

public Plugin myinfo = {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX",
	description = "RolePlay - Quête Technicien: "...QUEST_NAME,
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iCurrent[MAXPLAYERS+1], g_iMarked[MAXPLAYERS + 1][64];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	Q1_Abort,	Q1_Done);
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
	menu.AddItem("", "Interlocuteur anonyme :-", ITEMDRAW_DISABLED);
	menu.AddItem("", "Mec! On a besoin de toi au plus vite!", ITEMDRAW_DISABLED);
	menu.AddItem("", "Notre contact nous informe que la police", ITEMDRAW_DISABLED);
	menu.AddItem("", "a dissimulé des mouchards sur tous les", ITEMDRAW_DISABLED);
	menu.AddItem("", "téléphones de la ville.", ITEMDRAW_DISABLED);
	menu.AddItem("", "-----------------", ITEMDRAW_DISABLED);
	menu.AddItem("", "Tu as 12 heures pour tous les arracher", ITEMDRAW_DISABLED);	
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60;
	g_iCurrent[client] = 0;
}
public void Q1_Frame(int objectiveID, int client) {
	g_iDuration[client]--;
	int count = getMaxPhone();
	float dst = 999999999.9;
	int target = getNearestPhone(client, dst);
	
	if( target > 0 && dst < 48.0 ) {
		g_iMarked[client][g_iCurrent[client]++] = target;
	}
	else if( g_iCurrent[client] >= count ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if( g_iDuration[client] <= 0 ) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		if( target > 0 )
			rp_Effect_BeamBox(client, target, NULL_VECTOR, 255, 255, 255);
		
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s %d/%d", QUEST_NAME, g_iDuration[client], QUEST_RESUME, g_iCurrent[client], count);
	}
}
public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
}
public void Q1_Done(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée.", QUEST_NAME);
	
	int cap = rp_GetRandomCapital(221);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 2500);
	rp_ClientMoney(client, i_AddToPay, 2500);
	rp_ClientXPIncrement(client, 1250);
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
int getMaxPhone() {
	static int lastRes, lastTime;
	if( lastTime > GetTime() )
		return lastRes;
	
	lastRes = 0;
	char classname[64];
	
	for (int i = MaxClients; i <= 2048; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( StrContains(classname, "rp_phone") == 0)
			lastRes++;
	}
	
	lastTime = GetTime() + 30;
	return lastRes;
}
int getNearestPhone(int client, float& nearest) {
	int ID;
	float src[3], dst[3], tmp;
	char classname[64];
	bool skip;
	
	GetClientAbsOrigin(client, src);
	
	for (int i = MaxClients; i <= 2048; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( StrContains(classname, "rp_phone") == 0) {
			skip = false;
			for (int j = 0; j <= g_iCurrent[client]; j++) {
				if( g_iMarked[client][j] == i )
					skip = true;
			}
			if( skip )
				continue;
			
			Entity_GetAbsOrigin(i, dst);
			tmp = GetVectorDistance(src, dst);
			if( tmp < nearest ) {
				nearest = tmp;
				ID = i;
			}
		}
	}
	return ID;
}
