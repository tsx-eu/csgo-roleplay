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
#include <colors_csgo>  // https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>      	// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#pragma newdecls required
#include <roleplay.inc>   // https://www.ts-x.eu
#include <pve.inc>
#include <phun_nav.inc>
#include <custom_weapon_mod.inc>


#define		QUEST_UNIQID   	"PVE_SOLO"
#define		QUEST_NAME      "PVE: Solo - BETA"
#define		QUEST_TYPE     	quest_group
#define		QUEST_ARENA		310
#define		QUEST_TEAMS		3
#define		TEAM_NONE		0
#define		TEAM_PLAYERS	1
#define		TEAM_NPC		2
#define 	QUEST_MID		view_as<float>({-4378.0, -10705.0, -7703.0})
#define		QUEST_BONUS		view_as<float>({-4494.0, -9573.0, -7828.0})

char g_szSpawnQueue[][][PLATFORM_MAX_PATH] = {
	{"1", "zombie"}, {"4", "skeleton"},
	{"1", "zombie"}, {"4", "skeleton"},
	{"1", "zombie"}, {"9", "skeleton_arrow"},
	{"5", "zombie"},
	{"1", "zombie"}, {"4", "skeleton_heavy"},
	{"5", "zombie"}
};
ArrayList g_hQueue;

public Plugin myinfo =  {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX", 
	description = "RolePlay - Quête "...QUEST_NAME, 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest;
int g_iPlayerTeam[2049], g_stkTeam[QUEST_TEAMS + 1][MAXPLAYERS + 1], g_stkTeamCount[QUEST_TEAMS];
bool g_bCanMakeQuest;
int g_iPlayerObjective[MAXPLAYERS + 1];
int g_cBeam;
int g_iPort;

enum QuestConfig {
	QC_Killed = 0,
	QC_Remainning,
	QC_Alive,
	QC_Health,
	QC_Difficulty,
	QC_Time,
	QC_DeadTime,
	QC_Bonus,
	QC_Light,
	QC_Alert,
	QC_Max
};
int g_iQuestConfig[QC_Max];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_PluginReloadSelf);
	g_iPort = GetConVarInt(FindConVar("hostport"));
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
		
	int i;
	rp_QuestAddStep(g_iQuest, i++, Q0_Start,	Q01_Frame,	Q0_Abort, 	QUEST_NULL);
	
	if ( g_iPort == 27015) {
		rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q02_Frame,	Q0_Abort, 	QUEST_NULL);
		rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q03_Frame,	Q0_Abort, 	QUEST_NULL);
		rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q04_Frame,	Q0_Abort, 	QUEST_NULL);
		rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q05_Frame,	Q0_Abort, 	QUEST_NULL);
		rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q06_Frame,	Q0_Abort, 	QUEST_NULL);
	}
	
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q1_Frame,	Q0_Abort, 	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q2_Start,	Q2_Frame,	Q_Abort, 	Q_Abort);
	rp_QuestAddStep(g_iQuest, i++, Q3_Start,	Q3_Frame,	QUEST_NULL, QUEST_NULL);
	
	g_hQueue = new ArrayList(1, 1024);
	g_bCanMakeQuest = true;
}
public void OnMapStart() {
	AddFileToDownloadsTable("models/DeadlyDesire/props/udamage.mdl");
	AddFileToDownloadsTable("models/DeadlyDesire/props/udamage.dx90.vtx");
	AddFileToDownloadsTable("models/DeadlyDesire/props/udamage.phy");
	AddFileToDownloadsTable("models/DeadlyDesire/props/udamage.vvd");
	AddFileToDownloadsTable("materials/DeadlyDesire/props/studmap.vmt");
	AddFileToDownloadsTable("materials/DeadlyDesire/props/studmap.vtf");
	PrecacheModel("models/DeadlyDesire/props/udamage.mdl", true);
	
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheSound("player/heartbeatloop.wav");
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	
	if( g_bCanMakeQuest == false )
		return false;
	if ( g_iPort == 27015) {
		if( rp_GetClientInt(client, i_PlayerLVL) < 100 )
			return false;
		if( rp_GetClientFloat(client, fl_MonthTime) < 14.0 )
			return false;
	}
	return true;
}
// ----------------------------------------------------------------------------
public void Q0_Start(int objectiveID, int client) {
	g_bCanMakeQuest = false;
}
public void Q0_Abort(int objectiveID, int client) {
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Désolé, vous ne pouvez pas essayer la PVE pour le moment.");
	CreateTimer(10.0, newAttempt);
}
public void Q01_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle("Cette quête est toujours en développement.\nNous avons besoin de vous, pour l'améliorer.\nÉtant donné qu'il ne s'agit encore que d'un\nbref aperçu de la version final, la quête\nest réservée aux joueurs sachant à quoi\ns'attendre.\n \nRépondez correctement aux questions suivantes\npour tenter l'expérience.\n ");
	menu.AddItem("0", "J'ai bien compris, mais j'y participe pas.");
	menu.AddItem("0", "J'ai besoin de plus d'info.");
	menu.AddItem("1", "Lancez le questionnaire!");
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public void Q02_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nLe projet PVE sur le roleplay c'est...");
	
	menu.AddItem("0", "Un nouveau système de PVP beaucoup plus équilibré");
	menu.AddItem("0", "Une nouvelle quête qui fait gagner plein de thune");
	menu.AddItem("0", "Une nouvelle quête qui fait gagner plein d'expérience");
	menu.AddItem("0", "Un défis pour devenir admin");
	menu.AddItem("1", "Des combats en équipe contres des monstres dans une arène");
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public void Q03_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nOù se situe l'affrontement de la PVE?");
	
	menu.AddItem("0", "Dans la mairie dans des locaux aménagés");
	menu.AddItem("0", "Dans le BUNKER en face de la villa immo");
	menu.AddItem("0", "Dans le cimetière de Princeton");
	menu.AddItem("1", "Dans une arène, hors map");
	
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public void Q04_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nQuelle aptitude les mobs PVE ne sont t-ils pas capable\nde réaliser, pour le moment?");
	
	menu.AddItem("0", "Monter une échelle");
	menu.AddItem("0", "Envoyer des projectiles (ex: flèche)");
	menu.AddItem("1", "Contourner un props posé par un joueur");
	menu.AddItem("0", "Monter ou descendre une pente");
	menu.AddItem("0", "Trouver leur chemin dans Princeton");	
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public void Q05_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nQuand a été annoncé le projet PVE?");
	
	menu.AddItem("0", "Janvier 2016");
	menu.AddItem("1", "Mars 2017");
	menu.AddItem("0", "Mai 2017");
	menu.AddItem("0", "Juillet 2017");	
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public void Q06_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q0_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nQuel mob n'existe pas dans la PVE?");
	
	menu.AddItem("1", "Squelette armé d'une lance");
	menu.AddItem("0", "Squelette armé d'une épée et d'un bouclier");
	menu.AddItem("0", "Squelette armé d'un arc");
	menu.AddItem("0", "Squelette armé d'une hache");
	
	
	menu.Display(client, MENU_TIME_FOREVER);
}
public int Q0_MenuComplete(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ne donnez pas les réponses aux autres ;-)");
		
		if( StringToInt(options) == 1 )
			rp_QuestStepComplete(client, g_iPlayerObjective[client]);
		else
			rp_QuestStepFail(client, g_iPlayerObjective[client]);

	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return 0;
}
// ----------------------------------------------------------------------------
public void Q_Abort(int objectiveID, int client) {
	
	CreateTimer(5.0 * 60.0, newAttempt);
	
	rp_UnhookEvent(client, RP_OnPlayerDead, fwdDead);
	rp_UnhookEvent(client, RP_OnPlayerZoneChange, fwdZone);
	rp_UnhookEvent(client, RP_PlayerCanUseItem, fwdItem);
	rp_UnhookEvent(client, RP_PrePlayerPhysic, fwdPhysics);
	
	removeClientTeam(client);
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Merci pour votre test! Donnez vos suggestions sur pve.ts-x.eu <3");
	
	for (int i = 0; i < g_stkTeamCount[TEAM_NPC]; i++) {
		int entity = g_stkTeam[TEAM_NPC][i];
		
		rp_ScheduleEntityInput(entity, 0.1, "Kill");
	}
	
	char classname[64];
	for (int i = MaxClients; i < MAX_ENTITIES; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		if( !HasEntProp(i, Prop_Send, "m_vecOrigin") )
			continue;
		if( rp_GetPlayerZone(i) != QUEST_ARENA )
			continue;
			
		if( IsMonster(i) )
			AcceptEntityInput(i, "Kill");
		if( rp_IsValidVehicle(i) )
			rp_SetVehicleInt(i, car_health, -1);
		if( rp_GetBuildingData(i, BD_owner) > 0 && Entity_GetHealth(i) > 0 )
			Entity_Hurt(i, Entity_GetHealth(i));
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( StrContains(classname, "weapon_") == 0 )
			AcceptEntityInput(i, "Kill");
	}
	
	int parent;
	parent = EntRefToEntIndex(g_iQuestConfig[QC_Bonus]);
	if( parent != INVALID_ENT_REFERENCE )
		AcceptEntityInput(parent, "KillHierarchy");
	parent = EntRefToEntIndex(g_iQuestConfig[QC_Light]);
	if( parent != INVALID_ENT_REFERENCE )
		AcceptEntityInput(parent, "KillHierarchy");
}
public int Q1_MenuComplete(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		g_iQuestConfig[QC_Difficulty] = StringToInt(options);
		rp_QuestStepComplete(client, g_iPlayerObjective[client]);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return 0;
}
public void Q1_Frame(int objectiveID, int client) {
	g_iPlayerObjective[client] = objectiveID;
	
	if( !rp_ClientCanDrawPanel(client) )
		return;
	
	Menu menu = new Menu(Q1_MenuComplete);
	menu.SetTitle(QUEST_NAME ... " - BETA\n \nQuel doit être votre niveau de difficulté?\n ");
	
	menu.AddItem("0", "Je suis trop jeune pour mourir\n- Les pillules sont désactivées");
	menu.AddItem("1", "Hey, pas si fort\n- Les boosts sont désactivés\n- Les items de regénération sont désactivés\n- Les fusées propulseurs sont désactivés");
	menu.AddItem("2", "Fais-moi mal\n- Les boosts sont désactivés\n- Tous les items sont désactivés");
	menu.AddItem("3", "Laisse moi mourir\n- Les boost de gravité et de vitesses sont désactivés- Tous les items sont désactivés\n- Les monstres sont plus fort",	ITEMDRAW_DISABLED);
	
	
	menu.Display(client, MENU_TIME_FOREVER);
}
// ----------------------------------------------------------------------------
public void Q2_Start(int objectiveID, int client) {
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Bonne chance pour ce test!");
	
	addClientToTeam(client, TEAM_PLAYERS);
	rp_HookEvent(client, RP_OnPlayerDead, fwdDead);
	rp_HookEvent(client, RP_OnPlayerZoneChange, fwdZone);
	rp_HookEvent(client, RP_PlayerCanUseItem, fwdItem);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdPhysics);
	
	g_hQueue.Clear();
	for (int i = 0; i < sizeof(g_szSpawnQueue); i++) {
		int cpt = StringToInt(g_szSpawnQueue[i][0]);
		int id = PVE_GetId(g_szSpawnQueue[i][1]);
		
		if( id >= 0 ) {
			for (int j = 0; j < cpt; j++)
				g_hQueue.Push(id);
		}
	}
	
	int bonus = SQ_SpawnBonus();
	int light = SQ_SpawnLight();
	
	g_iQuestConfig[QC_Time] = g_iQuestConfig[QC_Killed] = g_iQuestConfig[QC_Alive] = 0;
	g_iQuestConfig[QC_Health] = 5;
	g_iQuestConfig[QC_DeadTime] = 60;
	g_iQuestConfig[QC_Remainning] = g_hQueue.Length;
	g_iQuestConfig[QC_Bonus] = EntIndexToEntRef(bonus);
	g_iQuestConfig[QC_Light] = EntIndexToEntRef(light);
}
public void Q2_Frame(int objectiveID, int client) {
	float pos[3];
	
	if( g_iQuestConfig[QC_Remainning] <= 0 )
		rp_QuestStepComplete(client, objectiveID);
	else if( g_iQuestConfig[QC_Health] <= 0 )
		rp_QuestStepFail(client, objectiveID);
	
	if( rp_GetPlayerZone(client) == QUEST_ARENA ) {
		g_iQuestConfig[QC_Time]++;
		
		PrintHintText(client, "Arène SOLO\nZombie restant: %d\nPV restant: %d - Temps: %d secondes", 
			g_iQuestConfig[QC_Remainning], g_iQuestConfig[QC_Health], g_iQuestConfig[QC_Time]
		);
		
		if( g_hQueue.Length > 0  && g_iQuestConfig[QC_Alive] < (5+g_iQuestConfig[QC_Difficulty]) ) {
			if( SQ_Pop(pos) ) {
				int id = g_hQueue.Get(0);
				g_hQueue.Erase(0);
				
				int entity = PVE_Spawn(id, pos, NULL_VECTOR);
				addClientToTeam(entity, TEAM_NPC);
				
				g_iQuestConfig[QC_Alive]++;
				
				PVE_RegEvent(entity, ESE_Dead, OnDead);
				PVE_RegEvent(entity, ESE_FollowChange, OnFollowChange);
				PVE_RegEvent(entity, ESE_Think, OnThink);
				SDKHook(entity, SDKHook_Touch, OnTouch);
			}
		}
		
		int health = GetClientHealth(client);
		int light = EntRefToEntIndex(g_iQuestConfig[QC_Light]);
		
		if( light != INVALID_ENT_REFERENCE ) { // n'est normalement pas sensé arrivé.
			
			if( health < 100 && g_iQuestConfig[QC_Alert] == 0 ) {
				SetVariantColor({255, 50, 50,8});
				AcceptEntityInput(light, "LightColor");
				EmitSoundToClient(client, "player/heartbeatloop.wav", client, SNDCHAN_BODY);
			}
			else if( health > 100 && g_iQuestConfig[QC_Alert] == 1 ) {
				SetVariantColor({255,150,100,5});
				AcceptEntityInput(light, "LightColor");
				StopSound(client, SNDCHAN_BODY, "player/heartbeatloop.wav");
			}
			
			g_iQuestConfig[QC_Alert] = (health < 100) ? 1 : 0;
		}
		
		if( GetClientTeam(client) == CS_TEAM_CT )
			ForcePlayerSuicide(client);
	}
	else if( g_iQuestConfig[QC_Health] > 0 ) {
		
		if( IsPlayerAlive(client) ) {
			if( g_iQuestConfig[QC_DeadTime] > 0 )
				g_iQuestConfig[QC_DeadTime]--;
			else
				g_iQuestConfig[QC_Time]++;
		}
		
		PrintHintText(client, "Retournez dans un métro avec du stuff pour reprendre la partie.\nIl vous reste %d vie - Temps: %d secondes", g_iQuestConfig[QC_Health], g_iQuestConfig[QC_Time]);
	}
}
public void Q3_Start(int objectiveID, int client) {
	g_iQuestConfig[QC_DeadTime] = 3;
}
public void Q3_Frame(int objectiveID, int client) {
	g_iQuestConfig[QC_DeadTime]--;
	
	PrintHintText(client, "Fin de la partie.\n Vous allez être téléporté dans quelques instants.");
	
	if( g_iQuestConfig[QC_DeadTime] < 0 ) {
		if( rp_GetPlayerZone(client) == QUEST_ARENA )
			rp_ClientSendToSpawn(client);
		else
			rp_QuestStepComplete(client, objectiveID);
	}
}
// ----------------------------------------------------------------------------
public void OnDead(int id, int entity) {
	removeClientTeam(entity);
	g_iQuestConfig[QC_Remainning]--;
	g_iQuestConfig[QC_Alive]--;
	g_iQuestConfig[QC_Killed]++;
}
public Action OnFollowChange(int id, int entity, int& target) {

	if( target > 0 ) {
		if( !IsPlayerAlive(target) || rp_GetPlayerZone(entity) != rp_GetPlayerZone(target) )
			target = 0;
	}
	
	float tmp, dist = FLT_MAX, src[3], dst[3];
	Entity_GetAbsOrigin(entity, src);
	
	int area = PHUN_Nav_GetAreaId(src);
	int client;
	
	for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++) {
		client = g_stkTeam[TEAM_PLAYERS][i];
		
		if( !IsValidClient(client) )
			continue;
		if( !IsPlayerAlive(client) )
			continue;
		if( rp_GetPlayerZone(entity) != rp_GetPlayerZone(client) )
			continue;
		
		GetClientEyePosition(client, dst);
		tmp = GetVectorDistance(src, dst);
		
		if( area == PHUN_Nav_GetAreaId(dst) )
			tmp /= 4.0;
		if( IsAbleToSee(client, src) )
			tmp /= 4.0;
				
		if (tmp < dist) {
			dist = tmp;
			target = client;
		}
	}
	
	return Plugin_Changed;
}
public void OnThink(int id, int entity, PVE_EntityState& state) {
	// TODO: Check stuck
}
public void OnTouch(int entity, int target) {
	static char classname[32];
	float pos[3];
	
	if( target > MaxClients ) {
		
		GetEdictClassname(target, classname, sizeof(classname));
		if( StrEqual(classname, "trigger_hurt") ) {
			if( SQ_Pop(pos) ) {
				TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}
// ----------------------------------------------------------------------------
public void fwdThink(int entity) {
	float ang[3];
	Entity_GetAbsAngles(entity, ang);
	ang[1] += 1.0;
	if( ang[1] > 180.0 )
		ang[1] -= 360.0;
	TeleportEntity(entity, NULL_VECTOR, ang, NULL_VECTOR);
}
public void fwdTouch(int entity, int target) {
	
	if( target > 0 && target < MaxClients ) {
		int parent = EntRefToEntIndex(g_iQuestConfig[QC_Bonus]);
		if( parent != INVALID_ENT_REFERENCE )
			AcceptEntityInput(parent, "KillHierarchy");
		else // Comment est-ce possible?
			AcceptEntityInput(entity, "KillHierarchy");
		
		for (float size = 256.0; size <= 2048.0; size *= 2.0) { // 256, 512, 1024, 2048.
			TE_SetupBeamRingPoint(QUEST_BONUS, 32.0, size, g_cBeam, g_cBeam, 0, 30, 1.0, Logarithm(size, 2.0) * 8.0, 0.0, {100, 50, 100, 200}, 0, 0);
			TE_SendToAll();
		}
		
		for (int i = MaxClients; i < MAX_ENTITIES; i++) {
			if( !IsValidEdict(i) || !IsValidEntity(i) )
				continue;
			if( !HasEntProp(i, Prop_Send, "m_vecOrigin") )
				continue;
			if( rp_GetPlayerZone(i) != QUEST_ARENA )
				continue;
			if( IsMonster(i) )
				Entity_Hurt(i, 5000, target);
		}
		
		SetEntityHealth(target, 500);
		rp_SetClientInt(target, i_Kevlar, 250);
	}
}
public Action fwdItem(int client, int itemID) {
	
	
	if( rp_GetPlayerZone(client) == QUEST_ARENA ) {
		
		if( itemID == 294 || itemID == 295 )
			return Plugin_Stop;
		
		if( g_iQuestConfig[QC_Difficulty] == 1 ) {
			// Les items de heal, médishoot, propu, fusée...
			if( itemID == 48 || itemID == 89 || itemID == 258 )
				return Plugin_Stop;
			if( rp_GetItemInt(itemID, item_type_give_hp) > 0 )
				return Plugin_Stop;
		}
		else if( g_iQuestConfig[QC_Difficulty] >= 2 ) {
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}
public Action fwdPhysics(int client, float& speed, float& gravity) {
	
	if( g_iQuestConfig[QC_Difficulty] >= 1 ) {
		gravity = 1.0;
		speed = 1.0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
public Action fwdDead(int client) {

	if( rp_GetPlayerZone(client) == QUEST_ARENA ) {
		g_iQuestConfig[QC_Health]--;
		g_iQuestConfig[QC_DeadTime] = 60;
	}
}
public Action fwdZone(int client, int newZone, int oldZone) {
	if( newZone == 59 || newZone == 57 || newZone == 58 || newZone == 200 )
		if ( g_iQuestConfig[QC_Health] > 0) {
			if( GetClientTeam(client) == CS_TEAM_T )
				TeleportEntity(client, QUEST_MID, NULL_VECTOR, NULL_VECTOR);
			else
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être civil pour participer à la quête.");
		}
}
// ----------------------------------------------------------------------------
bool SQ_Pop(float pos[3], float size = 32.0) {
	static const int attempt = 10;
	static float min[3], max[3];
	static bool init;
	
	if( !init ) {
		min[0] = rp_GetZoneFloat(QUEST_ARENA, zone_type_min_x);
		min[1] = rp_GetZoneFloat(QUEST_ARENA, zone_type_min_y);
		min[2] = rp_GetZoneFloat(QUEST_ARENA, zone_type_min_z);
		
		max[0] = rp_GetZoneFloat(QUEST_ARENA, zone_type_max_x);
		max[1] = rp_GetZoneFloat(QUEST_ARENA, zone_type_max_y);
		max[2] = rp_GetZoneFloat(QUEST_ARENA, zone_type_max_z);
		init = true;
	}
	
	for (int i = 0; i < attempt; i++) {
		if( PHUN_Nav_GetAreaHidingSpot(min, max, pos) )
			if( SQ_Valid(pos, size) )
				return true;
	}
	return false;
}
bool SQ_Valid(float pos[3], float size) {
	float abs[3], min[3], max[3];
	
	float threshold = GetVectorDistance(pos, QUEST_MID);
	// TODO : Augmenter les chances de pop loins du mid
	if( threshold < 800.0 )
		return false;
	
	// Pas si un joueur nous vois.
	for (int i = 0; i < g_stkTeamCount[TEAM_PLAYERS]; i++) {
		int client = g_stkTeam[TEAM_PLAYERS][i];
		
		if( IsAbleToSee(client, pos) ) {
			return false;
		}
	}
	
	// Pas sur un navmesh plus petit que la taille
	int id = PHUN_Nav_GetAreaId(pos);
	PHUN_Nav_AreaIdToPosition(id, abs, min, max);
	SubtractVectors(max, min, abs);
	
	float length = GetVectorLength(abs);
	if( length < size )
		return false;
	
	// Ni sur un truc qui semble bloqué
	for (int i = 0; i < 2; i ++) {
		min[i] = -size / 2.0;
		max[i] =  size / 2.0;
	}
	min[2] = 0.0;
	max[2] = size * 2.0;
	
	Handle tr = TR_TraceHullEx(pos, pos, min, max, MASK_SOLID);
	if (TR_DidHit(tr)) {
		CloseHandle(tr);
		return false;
	}
	CloseHandle(tr);
	return true;
}
// ----------------------------------------------------------------------------
int SQ_SpawnLight() {
	float pos[3];
	pos = QUEST_BONUS;
	pos[0] = (rp_GetZoneFloat(QUEST_ARENA, zone_type_min_x) + rp_GetZoneFloat(QUEST_ARENA, zone_type_max_x)) / 2.0;
	pos[1] = (rp_GetZoneFloat(QUEST_ARENA, zone_type_min_y) + rp_GetZoneFloat(QUEST_ARENA, zone_type_max_y)) / 2.0;
	pos[2] += 1024.0;
	
	int ent = CreateEntityByName("env_projectedtexture");
	DispatchKeyValue(ent, "targetname", "toto");
	DispatchKeyValue(ent, "farz", "2048");
	DispatchKeyValue(ent, "texturename", "effects/flashlight001_intro");
	DispatchKeyValue(ent, "lightcolor", "255 150 100 5");
	DispatchKeyValue(ent, "spawnflags", "1");
	DispatchKeyValue(ent, "lightfov", "170");
	DispatchKeyValue(ent, "brightnessscale", "50");
	DispatchKeyValue(ent, "lightworld", "1");
	
	DispatchSpawn(ent);
	TeleportEntity(ent, pos, view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);
	
	return ent;
}
int SQ_SpawnBonus() {
	int parent = CreateEntityByName("func_rotating");
	DispatchKeyValueVector(parent, "origin", QUEST_BONUS);
	DispatchKeyValue(parent, "maxspeed", "128");
	DispatchKeyValue(parent, "friction", "0");
	DispatchKeyValue(parent, "solid", "0");
	DispatchKeyValue(parent, "spawnflags", "64");
	DispatchSpawn(parent);
	TeleportEntity(parent, QUEST_BONUS, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(parent, "Start");
	
	int ent = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(ent, "model", "models/DeadlyDesire/props/udamage.mdl");
	DispatchSpawn(ent);
	TeleportEntity(ent, QUEST_BONUS, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", parent);
	
	Entity_SetSolidFlags(ent, FSOLID_TRIGGER);
	Entity_SetCollisionGroup(ent, COLLISION_GROUP_PLAYER);
	
	SDKHook(ent, SDKHook_Touch, fwdTouch);
	
	SetEntityRenderMode(ent, RENDER_TRANSALPHA);
	SetEntityRenderColor(ent, 255, 0, 255, 200);
	
	int sub = CreateEntityByName("env_projectedtexture");
	DispatchKeyValue(sub, "farz", "128");
	DispatchKeyValue(sub, "texturename", "effects/flashlight001_intro");
	DispatchKeyValue(sub, "lightcolor", "255 0 255 50");
	DispatchKeyValue(sub, "spawnflags", "1");
	DispatchKeyValue(sub, "lightfov", "160");
	DispatchKeyValue(sub, "brightnessscale", "5");
	DispatchKeyValue(sub, "lightworld", "1");
	DispatchSpawn(sub);
	SetVariantString("!activator");
	AcceptEntityInput(sub, "SetParent", parent);
	TeleportEntity(sub, view_as<float>({0.0, 0.0, 64.0}), view_as<float>({ 90.0, 0.0, 0.0 }), NULL_VECTOR);
	
	return parent;
}
stock bool IsAbleToSee(int client, float dst[3]) {
	static float src[3], ang[3], v_dir[3], d_dir[3];
	static float threshold = 0.73;
	GetClientEyePosition(client, src);
	GetClientEyeAngles(client, ang);
	ang[0] = ang[2] = 0.0;
	// ang[0] needed?
	
	//
	if( PHUN_Nav_GetAreaId(src) == PHUN_Nav_GetAreaId(dst) )
		return true;
	
	//
	GetAngleVectors(ang, v_dir, NULL_VECTOR, NULL_VECTOR);
	SubtractVectors(dst, src, d_dir);
	NormalizeVector(d_dir, d_dir);
	if( GetVectorDotProduct(v_dir, d_dir) < threshold) 
		return false;
	
	//
	Handle tr = TR_TraceRayFilterEx(src, dst, MASK_SOLID, RayType_EndPoint, TraceEntityFilterPlayers, client);
	if( TR_DidHit(tr) ) {
		delete tr;
		return false;
	}
	delete tr;
	return true;
}
stock bool IsMonster(int ent) {
	static char classname[64];
	GetEdictClassname(ent, classname, sizeof(classname));
	return StrEqual(classname, "monster_generic");
}
public bool TraceEntityFilterPlayers(int entity, int contentsMask, any data ) {
	return entity > MaxClients && entity != data;
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
// ----------------------------------------------------------------------------
public Action newAttempt(Handle timer, any zboub) {
	g_bCanMakeQuest = true;
}