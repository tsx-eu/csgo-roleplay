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
#define		TEAM_BRAQUEUR_DEAD	3
#define		TEAM_POLICE			4
#define		TEAM_NAME1		"Braqueur"
#define		TEAM_NAME2		"Police"
#define 	REQUIRED_T			2
#define 	REQUIRED_CT			0
#define		MAX_ZONES			310


public Plugin myinfo =  {
	name = "Quête: Braquage", author = "KoSSoLaX", 
	description = "RolePlay - Quête Braquage", 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest;
bool g_bDoingQuest, g_bByPassDoor, g_bHasHelmet;
int g_iVehicle, g_iPlanque, g_iPlanqueZone, g_iQuestGain;
int g_iPlayerTeam[MAXPLAYERS + 1], g_stkTeam[QUEST_TEAMS + 1][MAXPLAYERS+1], g_stkTeamCount[QUEST_TEAMS + 1], g_iJobs[MAX_JOBS];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
		
	int i;
	rp_QuestAddStep(g_iQuest, i++, Q1_Start,	Q1_Frame,	Q_Abort, QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q2_Start,	Q2_Frame,	Q_Abort, QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q3_Frame,	Q_Abort, QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q4_Start,	Q4_Frame,	Q_Abort, QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q5_Start,	Q5_Frame,	Q_Abort, QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q6_Start,	Q6_Frame,	Q_Abort, QUEST_NULL);
	
}
public void OnMapStart() {
	PrecacheSoundAny("ui/beep22.wav");
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
	
	if( ct < REQUIRED_CT )
		return false;
	
	return true;
}
public void OnClientPostAdminCheck(int client) {
	g_iPlayerTeam[client] = TEAM_NONE;
	if( g_bHasHelmet ) {
		rp_HookEvent(client, RP_OnPlayerDead, fwdDead);
	}
}
public void OnClientDisconnect(int client) {
	removeClientTeam(client);
}
// ----------------------------------------------------------------------------
public void Q_Abort(int objectiveID, int client) {
	
	for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++) {
		if( g_bByPassDoor )
			rp_UnhookEvent(g_stkTeam[TEAM_BRAQUEUR][i], RP_OnPlayerCheckKey, fwdGotKey);
		if( g_bHasHelmet )
			SetEntProp(g_stkTeam[TEAM_BRAQUEUR][i], Prop_Send, "m_bHasHelmet", 0);
	}
	
	if( g_bHasHelmet ) {
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			rp_UnhookEvent(i, RP_OnPlayerDead, fwdDead);
		}
	}
	g_bByPassDoor = false;
	g_bHasHelmet = false;
}

public void Q1_Start(int objectiveID, int client) {
	g_bDoingQuest = true;
	addClientToTeam(client, TEAM_BRAQUEUR);
}
public void Q1_Frame(int objectiveID, int client) {
	if( g_stkTeamCount[TEAM_BRAQUEUR] >= REQUIRED_T && g_stkTeamCount[TEAM_BRAQUEUR] >= REQUIRED_CT ) {
		rp_QuestStepComplete(client, objectiveID);
		return;
	}
	for (int i = 0; i < g_stkTeamCount[TEAM_INVITATION]; i++) {
		DrawMenu_Invitation(client, g_stkTeam[TEAM_INVITATION][i]);
	}
	PrintHintText(client, "<b>Quête</b>: %s\n<b>Objectif</b>: Inviter des collègues.", QUEST_NAME);
	
	if( rp_ClientCanDrawPanel(client) ) {
		char tmp[64], tmp2[64];
		
		
		Menu menu = new Menu(MenuInviterBraqueur);
		menu.SetTitle("Quète: %s", QUEST_NAME);
		menu.AddItem("", "Braqueur confirmé:", ITEMDRAW_DISABLED);
		for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++) {
			Format(tmp, sizeof(tmp), "%N", g_stkTeam[TEAM_BRAQUEUR][i]);
			menu.AddItem("", tmp, ITEMDRAW_DISABLED);
		}
		
		menu.AddItem("", "------------\nBraqueur en attente:", ITEMDRAW_DISABLED);
		for (int i = 0; i < g_stkTeamCount[TEAM_INVITATION]; i++) {
			Format(tmp, sizeof(tmp), "%N", g_stkTeam[TEAM_INVITATION][i]);
			menu.AddItem("", tmp, ITEMDRAW_DISABLED);
		}
		
		menu.AddItem("", "------------\nEnvoyer invitation:", ITEMDRAW_DISABLED);
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( g_iPlayerTeam[i] != TEAM_POLICE && (rp_GetClientJobID(i) == 1 || rp_GetClientJobID(i) == 101) ) {
				addClientToTeam(i, TEAM_POLICE);
				continue;
			}
			if( g_iPlayerTeam[i] == TEAM_POLICE && rp_GetClientJobID(i) != 1 && rp_GetClientJobID(i) != 101 ) {
				removeClientTeam(i);
			}
			if( g_iPlayerTeam[i] != TEAM_NONE )
				continue;
			
			Format(tmp, sizeof(tmp), "%d", i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			menu.AddItem(tmp, tmp2);
		}
		
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
}
public void Q2_Start(int objectiveID, int client) {
	g_iVehicle = spawnVehicle(client);
}
public void Q2_Frame(int objectiveID, int client) {
	if( !rp_IsValidVehicle(g_iVehicle) ) {
		g_iVehicle = spawnVehicle(client);
	}
	
	bool allIn = true;
	
	for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++) {
		if( allIn ) allIn = isInVehicle(g_stkTeam[TEAM_BRAQUEUR][i]);
		ServerCommand("sm_effect_gps %d %d", g_stkTeam[TEAM_BRAQUEUR][i], g_iVehicle);
		PrintHintText(g_stkTeam[TEAM_BRAQUEUR][i], "<b>Quête</b>: %s\n<b>Objectif</b>: Récupérer la voiture blindée.", QUEST_NAME);
	}
	
	if( allIn )
		rp_QuestStepComplete(client, objectiveID);
}
int g_iQ3 = -1;
public void Q3_Frame(int objectiveID, int client) {
	
	PrintHintText(client, "<b>Quête</b>: %s\n<b>Objectif</b>: Choisir le lieux du braquage.", QUEST_NAME);
	
	if( rp_ClientCanDrawPanel(client) ) {
		char tmp[64], tmp2[2][64];
		Menu menu = new Menu(MenuSelectPlanque);
		menu.SetTitle("Quète: %s", QUEST_NAME);
		
		if( g_iJobs[1] == 0 ) {
			g_iQ3 = objectiveID;
			for (int i = 1; i < MAX_ZONES; i++) {
				int job = rp_GetZoneInt(i, zone_type_type);
				if( job <= 0 || job >= MAX_JOBS || job == 14 || job == 101 )
					continue;
				if( g_iJobs[job] > 0 )
					continue;
				g_iJobs[job] = i;
			}
		}
		
		for (int i = 1; i < MAX_JOBS; i+=10) {
			if( g_iJobs[i] == 0 )
				continue;
			
			rp_GetZoneData(g_iJobs[i], zone_type_name, tmp, sizeof(tmp));
			ExplodeString(tmp, ": ", tmp2, sizeof(tmp2), sizeof(tmp2[]));
			Format(tmp, sizeof(tmp), "%d", g_iJobs[i]);
			Format(tmp2[0], sizeof(tmp2[]), "%s %d$", tmp2[0], rp_GetJobCapital(i) / 1000);
			menu.AddItem(tmp, tmp2[0]);
		}
		
		menu.ExitButton = false;
		menu.Display(client, 30);
	}
}
public void Q4_Start(int objectiveID, int client) {
	for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++)
		rp_HookEvent(g_stkTeam[TEAM_BRAQUEUR][i], RP_OnPlayerCheckKey, fwdGotKey);
	g_bByPassDoor = true;
}

public Action fwdGotKey(int client, int doorID) {
	float pos[3];
	Entity_GetAbsOrigin(doorID, pos);
	
	int zone = rp_GetZoneInt(rp_GetZoneFromPoint(pos), zone_type_type);
	if( zone == g_iPlanque )
		return Plugin_Changed;
	if( zone == 0 && rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) == g_iPlanque && rp_IsEntitiesNear(client, doorID) )
		return Plugin_Changed;
	
	return Plugin_Continue;
}
public void Q4_Frame(int objectiveID, int client) {
	bool allIn = true;
	float min[3], max[3], pos[3];
	char tmp[64], tmp2[2][64];
	min[0] = rp_GetZoneFloat(g_iPlanqueZone, zone_type_min_x);
	min[1] = rp_GetZoneFloat(g_iPlanqueZone, zone_type_min_y);
	min[2] = rp_GetZoneFloat(g_iPlanqueZone, zone_type_min_z);
	max[0] = rp_GetZoneFloat(g_iPlanqueZone, zone_type_max_x);
	max[1] = rp_GetZoneFloat(g_iPlanqueZone, zone_type_max_y);
	max[2] = rp_GetZoneFloat(g_iPlanqueZone, zone_type_max_z);
	rp_GetZoneData(g_iPlanqueZone, zone_type_name, tmp, sizeof(tmp));
	ExplodeString(tmp, ": ", tmp2, sizeof(tmp2), sizeof(tmp2[]));
	
	for (int i = 0; i <= 2; i++)
		pos[i] = (min[i] + max[i]) / 2.0;
		
	for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++) {
		bool inside = (rp_GetZoneInt(rp_GetPlayerZone(g_stkTeam[TEAM_BRAQUEUR][i]), zone_type_type) == g_iPlanque);
		if (allIn) allIn = inside;
		if( !inside ) ServerCommand("sm_effect_gps %d %f %f %f", g_stkTeam[TEAM_BRAQUEUR][i], pos[0], pos[1], pos[2]);
		
		PrintHintText(g_stkTeam[TEAM_BRAQUEUR][i], "<b>Quête</b>: %s\n<b>Objectif</b>: Entrez tous dans: %s.", QUEST_NAME, tmp2[0]);
	}
	
	if( allIn )
		rp_QuestStepComplete(client, objectiveID);
}
public void Q5_Start(int objectiveID, int client) {
	
	g_bHasHelmet = true;
	
	for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++) {
		if( Client_GetWeaponBySlot(g_stkTeam[TEAM_BRAQUEUR][i], CS_SLOT_PRIMARY) < 0 )
			Client_GiveWeapon(client, "weapon_ak47", true);
		if( Client_GetWeaponBySlot(g_stkTeam[TEAM_BRAQUEUR][i], CS_SLOT_SECONDARY) < 0 )
			Client_GiveWeapon(client, "weapon_revolver", false);
		SetEntProp(g_stkTeam[TEAM_BRAQUEUR][i], Prop_Send, "m_bHasHelmet", 1);
	}
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		rp_HookEvent(i, RP_OnPlayerDead, fwdDead);
	}
}
public void Q5_Frame(int objectiveID, int client) {
	char tmp[64], tmp2[2][64];
	rp_GetZoneData(g_iPlanqueZone, zone_type_name, tmp, sizeof(tmp));
	ExplodeString(tmp, ": ", tmp2, sizeof(tmp2), sizeof(tmp2[]));
	
	int cpt = countPlayerInZone(g_iPlanque);
	if( cpt == 0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++) {
			PrintHintText(g_stkTeam[TEAM_BRAQUEUR][i], "<b>Quête</b>: %s\n<b>Objectif</b>: Soyez seul dans %s.\n Il reste %d personne%s.", QUEST_NAME, tmp2[0], cpt, (cpt>1?"s":""));
		}
	}
}
public void Q6_Start(int objectiveID, int client) {
	g_iQuestGain = 1000;
	
	for (float i = 0.0; i <= 20.0; i += 1.5)
		CreateTimer(i, alarm);
}
public Action alarm(Handle timer, any client) {
	for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++) {
		EmitSoundToAllAny("ui/beep22.wav", g_stkTeam[TEAM_BRAQUEUR][i]);
	}
}
public Action fwdDead(int client, int attacker) {	
	if( g_iPlayerTeam[attacker] == TEAM_BRAQUEUR && g_bHasHelmet ) {
		PrintToChatAll("Meurtre de la part d'un braqueur");
		return Plugin_Handled;
	}
	if( g_iPlayerTeam[client] == TEAM_BRAQUEUR ) {
		PrintToChatAll("Un braqueur a été tué.");
		addClientToTeam(client, TEAM_BRAQUEUR_DEAD);
		if( g_bByPassDoor )
			rp_UnhookEvent(client, RP_OnPlayerCheckKey, fwdGotKey);
		if( g_bHasHelmet )
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void Q6_Frame(int objectiveID, int client) {
	int GainMax = (rp_GetJobCapital(g_iPlanque) / 1000);
	char tmp[64], tmp2[2][64];
	rp_GetZoneData(g_iPlanqueZone, zone_type_name, tmp, sizeof(tmp));
	ExplodeString(tmp, ": ", tmp2, sizeof(tmp2), sizeof(tmp2[]));
	
	for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++) {
		int heal = GetClientHealth(g_stkTeam[TEAM_BRAQUEUR][i]) + Math_GetRandomInt(0, 5);
		int kevlar = rp_GetClientInt(client, i_Kevlar) + 1;
		if( heal > 500 )
			heal = 500;
		if( kevlar > 250 )
			kevlar = 250;
		SetEntityHealth(g_stkTeam[TEAM_BRAQUEUR][i], heal);
		rp_SetClientInt(g_stkTeam[TEAM_BRAQUEUR][i], i_Kevlar, kevlar);
		
		if(rp_GetZoneInt(rp_GetPlayerZone(g_stkTeam[TEAM_BRAQUEUR][i]), zone_type_type) == g_iPlanque) {
			g_iQuestGain += Math_GetRandomInt(0, 50);
			if( g_iQuestGain >= GainMax )
				g_iQuestGain = GainMax;
		}
		
		PrintHintText(g_stkTeam[TEAM_BRAQUEUR][i], "<b>Objectif</b>: Restez vivant. Prennez la fuite avec votre voiture quand vous le souhaiter. <b>Gain</b>: %d$", g_iQuestGain);
	}
	
	for (int j = 0; j < g_stkTeamCount[TEAM_POLICE]; j++) {
		PrintHintText(g_stkTeam[TEAM_POLICE][j], "<b>Alerte</b>: Un braquage est en cours dans %s, tuer les braqueurs. <b>Gain</b>: %d$, <b>Amende</b>: %d$.", tmp2[0], (GainMax - g_iQuestGain)/4, g_iQuestGain/4);
		
		for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++) {
			rp_Effect_BeamBox(g_stkTeam[TEAM_POLICE][j], g_stkTeam[TEAM_BRAQUEUR][i], NULL_VECTOR, 255, 0, 0);
		}
	}
}
// ----------------------------------------------------------------------------
void DrawMenu_Invitation(int client, int target) {
	Menu menu = new Menu(MenuInviterBraqueur);
	menu.SetTitle("%N souhaite participer\nà la quète %s\n avec vous dans l'équipe: %s.\n \n Acceptez-vous son invitation?", client, QUEST_NAME, TEAM_NAME1);
	menu.AddItem("oui", "Oui");
	menu.AddItem("non", "Non");
	menu.ExitButton = false;
	
	menu.Display(target, 10);
}
public int MenuInviterBraqueur(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		if( StrEqual(options, "oui") ) {
			addClientToTeam(client, TEAM_BRAQUEUR);
		}
		else if( StrEqual(options, "non") ) {
			removeClientTeam(client);
		}
		else {
			int target = StringToInt(options);
			if( IsValidClient(target) ) {
				addClientToTeam(target, TEAM_INVITATION);
			}
		}
		
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public int MenuSelectPlanque(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		int target = StringToInt(options);
		if( target > 0 ) {
			g_iPlanque = rp_GetZoneInt(target, zone_type_type);
			g_iPlanqueZone = target;
			
			rp_QuestStepComplete(client, g_iQ3);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
// ----------------------------------------------------------------------------
void addClientToTeam(int client, int team) {
	removeClientTeam(client);
	
	if( team != TEAM_NONE )
		g_stkTeam[team][ g_stkTeamCount[team]++ ] = client;
	
	g_iPlayerTeam[client] = team;
}
void removeClientTeam(int client) {
	if( g_iPlayerTeam[client] != TEAM_NONE ) {
		for (int i = 0; i < g_stkTeamCount[g_iPlayerTeam[client]]; i++) {
			if( g_stkTeam[ g_iPlayerTeam[client] ][ i ] == client ) {
				for (; i < g_stkTeamCount[g_iPlayerTeam[client]]; i++) {
					g_stkTeam[g_iPlayerTeam[client]][i] = g_stkTeam[g_iPlayerTeam[client]][i + 1];
				}
				g_stkTeamCount[g_iPlayerTeam[client]]--;
				break;
			}
		}
		
		g_iPlayerTeam[client] = TEAM_NONE;
	}
}
int countPlayerInZone(int jobID) {
	int ret;
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( g_iPlayerTeam[i] == TEAM_BRAQUEUR )
			continue;
		if( !IsPlayerAlive(i) )
			continue;
		if( rp_GetZoneInt(rp_GetPlayerZone(i), zone_type_type) == jobID )
			ret++;
	}
	return ret;
}
int spawnVehicle(int client) {
	static float g_flStartPos[][3] = {
		{672.0, -4340.0, -2010.0},
		{822.0, -4340.0, -2010.0},
		{977.0, -4340.0, -2010.0},
		{1160.0, -4340.0, -2010.0},
		{1860.0, -4340.0, -2010.0},
		{1990.0, -4340.0, -2010.0},
		{-2440.0, 1000.0, -2440.0},
		{-2440.0, 1200.0, -2440.0},
		{-2440.0, 1400.0, -2440.0},
		{-2440.0, 1600.0, -2440.0},
		{-2945.0, 1600.0, -2440.0},
		{-2945.0, 1400.0, -2440.0},
		{-2945.0, 1200.0, -2440.0},
		{-2945.0, 1000.0, -2440.0}
	};
	int[] rnd = new int[sizeof(g_flStartPos)];
	int ent = 0;
	for (int i = 0; i < sizeof(g_flStartPos); i++)
		rnd[i] = i;
	SortIntegers(rnd, sizeof(g_flStartPos), Sort_Random);
	
	for (int i = 0; i < sizeof(g_flStartPos); i++) {
		ent = rp_CreateVehicle(g_flStartPos[rnd[i]], view_as<float>({0.0, 0.0, 0.0}), "models/natalya/vehicles/natalya_mustang_csgo_2016.mdl", 1, 0);
		if( ent > 0 && rp_IsValidVehicle(ent) ) {
			break;
		}
	}
	if( ent > 0 && rp_IsValidVehicle(ent) ) {
		rp_SetVehicleInt(ent, car_owner, client);
		rp_SetVehicleInt(ent, car_maxPassager, 3);
		rp_SetVehicleInt(ent, car_health, 10000);
		rp_SetClientKeyVehicle(client, ent, true);
		ServerCommand("sm_effect_colorize %d 0 0 0 255", ent);
		
		for (int i = 0; i < g_stkTeamCount[TEAM_BRAQUEUR]; i++) {
			rp_SetClientKeyVehicle(g_stkTeam[TEAM_BRAQUEUR][i], ent, true);
		}
		
		return ent;
	}
	
	return 0;
}
bool isInVehicle(int client) {
	return (rp_GetClientVehicle(client) == g_iVehicle || rp_GetClientVehiclePassager(client) == g_iVehicle);
}