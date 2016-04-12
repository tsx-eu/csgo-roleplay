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
#define		QUEST_TEAMS			3
#define		TEAM_NONE			0
#define		TEAM_INVITATION		1
#define		TEAM_BRAQUEUR		2
#define		TEAM_POLICE			3
#define		QUEST_TEAM1		"Braqueur"
#define		QUEST_TEAM2		"Police"


// TODO: Retirer du stack en cas de déconnexion de quelqu'un dans une équipe.

public Plugin myinfo =  {
	name = "Quête: Braquage", author = "KoSSoLaX", 
	description = "RolePlay - Quête Braquage", 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};


int g_iQuest;
bool g_bDoingQuest = false;
int g_iVehicle = 0;
int g_iPlayerTeam[MAXPLAYERS + 1], g_stkTeam[QUEST_TEAMS + 1][MAXPLAYERS+1], g_stkTeamCount[QUEST_TEAMS + 1];
float g_flStartPos[][3] = {
	{672.069213, -4349.562011, -2015.968750},
	{822.723144, -4342.318359, -2015.968750},
	{977.277099, -4335.911132, -2015.968750},
	{1166.882812, -4342.825683, -2015.968750},
	{1861.286865, -4362.259277, -2015.968750},
	{1994.302856, -4354.254882, -2015.968750},
	{-2440.774658, 1009.366882, -2447.968750},
	{-2439.078613, 1216.398925, -2447.968750},
	{-2439.977783, 1399.208740, -2447.968750},
	{-2441.483154, 1630.000366, -2447.968750},
	{-2945.136962, 1639.538940, -2447.968750},
	{-2947.626708, 1423.449951, -2447.968750},
	{-2923.718750, 1205.253051, -2447.968750},
	{-2911.954345, 1015.363891, -2447.968750}
};

int spawnVehicle(int client) {
	int[] rnd = new int[sizeof(g_flStartPos)];
	int ent = 0;
	for (int i = 0; i < sizeof(g_flStartPos); i++)
		rnd[i] = i;
	SortIntegers(rnd, sizeof(g_flStartPos), Sort_Random);
	
	for (int i = 0; i < sizeof(g_flStartPos); i++) {
		ent = rp_CreateVehicle(g_flStartPos[rnd[i]], view_as<float>({0.0, 0.0, 0.0}), "models/natalya/vehicles/natalya_mustang_csgo_2016.md", 1, 0);
		if( ent > 0 && rp_IsValidVehicle(ent) ) {
			break;
		}
	}
	if( ent > 0 && rp_IsValidVehicle(ent) ) {
		rp_SetVehicleInt(ent, car_owner, client);
		rp_SetClientKeyVehicle(ent, client, true);
		ServerCommand("sm_effect_colorize %d 0 0 0 255", ent);
		
		for (int i = 1; i <= MaxClients; i++) {
			if( g_iPlayerTeam[i] == TEAM_BRAQUEUR ) {
				rp_SetClientKeyVehicle(ent, client, true);
			}
		}
		
		return ent;
	}
	
	return 0;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
		
	int i;
	rp_QuestAddStep(g_iQuest, i++, Q1_Start, Q1_Frame, QUEST_NULL, QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q2_Start, Q2_Frame, QUEST_NULL, QUEST_NULL);
	
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	if( g_bDoingQuest == true )
		return false;
	if( GetClientCount() <= 32 && GetConVarInt(FindConVar("hostport")) != 27025 )
		return false;
	
	char szDayOfWeek[12], szHours[12];
	FormatTime(szDayOfWeek, 11, "%w");
	FormatTime(szHours, 11, "%H");
	
	if( StringToInt(szDayOfWeek) == 3 ) { // Mercredi
		if( StringToInt(szHours) >= 17 && StringToInt(szHours) <= 19  ) {	// 18h00m00s
			return false;
		}
	}
	if( StringToInt(szDayOfWeek) == 5 ) { // Vendredi
		if( StringToInt(szHours) >= 20 && StringToInt(szHours) <= 22) {	// 21h00m00s
			return false;
		}
	}
	int ct = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetClientJobID(i) == 1 || rp_GetClientJobID(i) == 101 )
			ct++;
	}
	if( ct <= 3 )
		return false;
	
	return true;
}
public void OnClientPostAdminCheck(int client) {
	g_iPlayerTeam[client] = TEAM_NONE;
}
public void OnClientDisconnect(int client) {
	g_iPlayerTeam[client] = TEAM_NONE;
}
// ----------------------------------------------------------------------------
public void Q1_Start(int objectiveID, int client) {
	g_bDoingQuest = true;
}
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
			//rp_QuestSetGroup(g_iQuest, TEAM_BRAQUEUR, stkBraqueur, countB - 1);
			//rp_QuestSetGroup(g_iQuest, TEAM_POLICE, stkPolice, countP - 1);
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
public void Q2_Start(int objectiveID, int client) {
	
	for (int i = 1; i <= MaxClients; i++) {
		g_stkTeam[ g_iPlayerTeam[i] ][ g_stkTeamCount[ g_iPlayerTeam[i] ]++ ] = i;
	}
	
	g_iVehicle = spawnVehicle(client);
}
public void Q2_Frame(int objectiveID, int client) {
	ServerCommand("sm_effect_gps %d %d", client, g_iVehicle);
}
// ----------------------------------------------------------------------------

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
		else if( StrEqual(options, "non") ) {
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
