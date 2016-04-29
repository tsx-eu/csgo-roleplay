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
#define QUEST_UNIQID   "18th-001"
#define   QUEST_NAME      "Blanchiment d'argent"
#define   QUEST_TYPE      quest_daily
#define   QUEST_JOBID      181
#define   QUEST_RESUME1   "Voler une arme de la police"
#define   QUEST_RESUME2   "Rapporter l'arme au chef"
#define   QUEST_RESUME3   "Déposer l'argent à la banque"

public Plugin myinfo =  {
	name = "Quête: Blanchiment d'argent", author = "KoSSoLaX", 
	description = "RolePlay - Quête 18th: Blanchiment d'argent", 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++, Q1_Start, Q1_Frame, Q1_Abort, QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q2_Start, Q2_Frame, Q1_Abort, QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q3_Start, Q3_Frame, Q1_Abort, Q3_End);
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	if (rp_GetClientJobID(client) != QUEST_JOBID)
		return false;
	
	return (countWeapon() >= 3);
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Yo man, on a de nouveaux projets pour toi.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Voles une arme de la police, puis ramène", ITEMDRAW_DISABLED);
	menu.AddItem("", "la nous.", ITEMDRAW_DISABLED);
	
	menu.AddItem("", "Pendant toute la durée de ta mission,", ITEMDRAW_DISABLED);
	menu.AddItem("", "nous t'enverrons du matériel nécessaire à ta réussite.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Tu as 12 heures, bonne chance.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 12 * 60;
}
public void Q1_Frame(int objectiveID, int client) {
	
	g_iDuration[client]--;
	int wep = Client_GetActiveWeapon(client);
	int nearest = nearestWeapon(client);
	
	int owner = Weapon_GetOwner(nearest);
	if (owner > 0)
		nearest = owner;
	
	if (wep > 0 && rp_GetWeaponStorage(wep) == true) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if (g_iDuration[client] <= 0) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME1);
		
		if (nearest > 0)
			rp_Effect_BeamBox(client, nearest, NULL_VECTOR, 255, 0, 0);
		
		if (rp_GetClientItem(client, 2) == 0) {
			char item[64];
			rp_GetItemData(2, item_type_name, item, sizeof(item));
			rp_ClientGiveItem(client, 2);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu: %s", item);
		}
	}
}
public void Q2_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Bien joué, tu l'as ! Rapporte la nous !", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 30);
	
	g_iDuration[client] = 24 * 60;
}
public void Q2_Frame(int objectiveID, int client) {
	static int zoneDest = 114;
	static float dst[3] =  { -2458.9, -3741.6, -1839.1 };
	float vec[3];
	GetClientAbsOrigin(client, vec);
	
	int wep = Client_GetActiveWeapon(client);
	g_iDuration[client]--;
	
	if (wep > 0 && rp_GetWeaponStorage(wep) == true && rp_GetPlayerZone(client) == zoneDest) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if (g_iDuration[client] <= 0) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME2);
		rp_Effect_BeamBox(client, -1, dst, 255, 255, 255);
	}
}

public void Q3_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Bien joué !", ITEMDRAW_DISABLED);
	menu.AddItem("", "Vas déposer cet argent en banque,", ITEMDRAW_DISABLED);
	menu.AddItem("", "tu pourras garder la moitié.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 30);
	
	g_iDuration[client] = 24 * 60;
}
public void Q3_Frame(int objectiveID, int client) {
	static float dst[3] =  { 2766.5, -86.3, -2058.5 };
	float vec[3];
	GetClientAbsOrigin(client, vec);
	
	g_iDuration[client]--;
	if (GetVectorDistance(vec, dst) < 64.0) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if (g_iDuration[client] <= 0) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME3);
		rp_Effect_BeamBox(client, -1, dst, 255, 255, 255);
	}
}
public void Q3_End(int objectiveID, int client) {
	
	Q1_Abort(objectiveID, client);
	
	int cap = rp_GetRandomCapital(181);
	rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 5000);
	rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + 5000);
	
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Interlocuteur anonyme :", ITEMDRAW_DISABLED);
	menu.AddItem("", "Les 18th te remercient pour ta rapidité d'action", ITEMDRAW_DISABLED);
	menu.AddItem("", "et t'offrent: [PvP] AK-47.", ITEMDRAW_DISABLED);
	
	menu.ExitButton = false;
	menu.Display(client, 30);
	
	char item[64]; rp_GetItemData(64, item_type_name, item, sizeof(item)); rp_ClientGiveItem(client, 236); // [PvP] AK-47
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu: %s", item);
}
public void Q1_Abort(int objectiveID, int client) {
	PrintHintText(client, "<b>Quête</b>: %s\nLa quête est terminée", QUEST_NAME);
}
// ----------------------------------------------------------------------------
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		if (menu != INVALID_HANDLE)
			CloseHandle(menu);
	}
	else if (action == MenuAction_End) {
		if (menu != INVALID_HANDLE)
			CloseHandle(menu);
	}
}
int countWeapon() {
	char classname[64];
	int amount = 0;
	
	for (int i = MaxClients; i <= 2048; i++) {
		if (!IsValidEdict(i) || !IsValidEntity(i))
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if (StrContains(classname, "weapon_") == 0 && rp_GetWeaponStorage(i) == true) {
			amount++;
		}
	}
	return amount;
}
int nearestWeapon(int client) {
	float vecOrigin[3], vecDestination[3], vecMaxDIST = 999999999.9, tmp;
	char classname[64];
	int val = -1, owner;
	Entity_GetAbsOrigin(client, vecOrigin);
	
	for (int i = MaxClients; i <= 2048; i++) {
		if (!IsValidEdict(i) || !IsValidEntity(i))
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if (StrContains(classname, "weapon_") == 0 && rp_GetWeaponStorage(i) == true) {
			owner = Weapon_GetOwner(i);
			if (owner <= 0)
				continue;
			
			Entity_GetAbsOrigin(owner, vecDestination);
			tmp = GetVectorDistance(vecOrigin, vecDestination);
			if (tmp < vecMaxDIST) {
				vecMaxDIST = tmp;
				val = i;
			}
		}
	}
	return val;
}
