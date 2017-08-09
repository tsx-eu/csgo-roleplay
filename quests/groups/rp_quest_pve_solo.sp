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


#define		QUEST_UNIQID   	"PVE_SOLO"
#define		QUEST_NAME      "PVE: Solo"
#define		QUEST_TYPE     	quest_group
#define		QUEST_POOL		2
#define		QUEST_ARENA		{310, 311}
#define		QUEST_TEAMS		3
#define		TEAM_NONE		0
#define		TEAM_PLAYERS	1
#define		TEAM_NPC		2
#define 	QUEST_MID		view_as<float>({0.0, 0.0, 0.0})

char g_szSpawnQueue[][] = {
	{"5", "zombie"},
	{"1", "skeleton"},
	{"2", "skeleton_arrow"},
	{"1", "skeleton_heavy"},
};
ArrayList g_hQueue[QUEST_POOL];

public Plugin myinfo =  {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX", 
	description = "RolePlay - Quête "...QUEST_NAME, 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest;
int g_iPlayerTeam[QUEST_POOL][2049], g_stkTeam[QUEST_POOL][QUEST_TEAMS + 1][MAXPLAYERS + 1], g_stkTeamCount[QUEST_POOL][QUEST_TEAMS];
int g_iEntityPool[2049];
bool g_bCanMakeQuest[QUEST_POOL];

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
		
	int i;
	rp_QuestAddStep(g_iQuest, i++, Q1_Start,	Q1_Frame,	Q_Abort, QUEST_NULL);
	
	for (int j = 0; j < QUEST_POOL; j++) {
		g_hQueue[j] = new ArrayList(1, 1024);
		g_bCanMakeQuest[j] = true;
	}
}
public void OnMapStart() {
	
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	if( g_bCanMakeQuest[0] == false && g_bCanMakeQuest[1] == false )
		return false;
	if( rp_GetClientInt(client, i_PlayerLVL) < 210 )
		return false;
	
	char szDayOfWeek[12], szHours[12];
	FormatTime(szDayOfWeek, 11, "%w");
	FormatTime(szHours, 11, "%H");
	
	if( StringToInt(szDayOfWeek) == 3 ) { // Mercredi
		if( StringToInt(szHours) >= 17 && StringToInt(szHours) < 19  ) {	// 18h00m00s
			return false;
		}
	}
	if( StringToInt(szDayOfWeek) == 5 ) { // Vendredi
		if( StringToInt(szHours) >= 20 && StringToInt(szHours) < 22) {	// 21h00m00s
			return false;
		}
	}
	
	// Uniquement sur le serveur TEST
	if( GetConVarInt(FindConVar("hostport")) == 27015 )
		return false;
	
	return true;
}
// ----------------------------------------------------------------------------
public void Q_Abort(int objectiveID, int client) {	
	Q_Clean();
}
void Q_Clean() {
	CreateTimer(15.0 * 60.0, newAttempt);
}
public Action newAttempt(Handle timer, any attempt) {
	g_bCanMakeQuest = true;
}
public void Q1_Start(int objectiveID, int client) {
	
	g_iEntityPool[client] = 0;
	
	g_bCanMakeQuest[g_iEntityPool[client]] = false;
	addClientToTeam(client, TEAM_PLAYERS, g_iEntityPool[client]);
	
	g_hQueue[g_iEntityPool[client]].Clear();
	for (int i = 0; i < sizeof(g_szSpawnQueue); i++) {
		int cpt = StringToInt(g_szSpawnQueue[i][0]);
		int id = PVE_GetId(g_szSpawnQueue[i][1]);
		
		if( id >= 0 ) {
			for (int j = 0; j < cpt; j++)
				g_hQueue[g_iEntityPool[client]].Push(id);
		}
	}
}
public void Q1_Frame(int objectiveID, int client) {
	float pos[3];
	if( g_hQueue[g_iEntityPool[client]].Length > 0 ) {
		if( SQ_Pop(pos, g_iEntityPool[client]) ) {
			
			int id = g_hQueue[g_iEntityPool[client]].Get(0);
			g_hQueue[g_iEntityPool[client]].Erase(0);
			
			// TODO AIM TO PLAYER
			// TODO: THINK HOOK
			// TODO: ATTACK FORWARD
			// TODO: MOVETO FORWARD
			int entity = PVE_Spawn(id, pos, NULL_VECTOR);
			g_iEntityPool[entity] = g_iEntityPool[client];
			addClientToTeam(entity, TEAM_NPC, g_iEntityPool[client]);
		}
	}
	else {
		rp_QuestStepComplete(client, objectiveID);
	}
}
int SQ_GetArena(int pool) {
	static int poolZone[QUEST_POOL] = QUEST_ARENA;
	return poolZone[pool];
}
bool SQ_Pop(float pos[3], int pool) {
	static const int attempt = 10;
	static float min[QUEST_POOL][3], max[QUEST_POOL][3];
	static bool init[QUEST_POOL];
	
	if( !init ) {
		int area = SQ_GetArena(pool);
		min[pool][0] = rp_GetZoneFloat(area, zone_type_min_x);
		min[pool][1] = rp_GetZoneFloat(area, zone_type_min_y);
		min[pool][2] = rp_GetZoneFloat(area, zone_type_min_z);
		
		max[pool][0] = rp_GetZoneFloat(area, zone_type_max_x);
		max[pool][1] = rp_GetZoneFloat(area, zone_type_max_y);
		max[pool][2] = rp_GetZoneFloat(area, zone_type_max_z);
		init[pool] = true;
	}
	
	for (int i = 0; i < attempt; i++) {
		if( PHUN_Nav_GetAreaHidingSpot(min[pool], max[pool], pos) )
			if( SQ_Valid(pos, pool) )
				return true;
	}
	return false;
}
bool SQ_Valid(float pos[3], int pool) {
	float threshold = GetVectorDistance(pos, QUEST_MID) / 512.0;
	if( GetRandomFloat(0.5, 1.0) < threshold )
		return false;
	// TODO will not be stuck
	for (int i = 0; i < g_stkTeamCount[pool][TEAM_PLAYERS]; i++) {
		int client = g_stkTeam[pool][TEAM_PLAYERS][i];
		
		if( IsAbleToSee(client, pos, pool) )
			return false;
	}
	
	return true;
}
// ----------------------------------------------------------------------------
stock bool IsAbleToSee(int client, float dst[3], int pool) {
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
public bool TraceEntityFilterPlayers(int entity, int contentsMask, any data ) {
	return entity > MaxClients && entity != data;
}
// ----------------------------------------------------------------------------
void addClientToTeam(int client, int team, int pool) {
	removeClientTeam(client, pool);
	
	if( team != TEAM_NONE )
		g_stkTeam[pool][team][ g_stkTeamCount[pool][team]++ ] = client;
	
	g_iPlayerTeam[pool][client] = team;
}
void removeClientTeam(int client, int pool) { 
	if( g_iPlayerTeam[pool][client] != TEAM_NONE ) {
		for (int i = 0; i < g_stkTeamCount[pool][g_iPlayerTeam[pool][client]]; i++) {
			if( g_stkTeam[pool][ g_iPlayerTeam[pool][client] ][ i ] == client ) {
				for (; i < g_stkTeamCount[pool][g_iPlayerTeam[pool][client]]; i++) {
					g_stkTeam[pool][g_iPlayerTeam[pool][client]][i] = g_stkTeam[pool][g_iPlayerTeam[pool][client]][i + 1];
				}
				g_stkTeamCount[pool][g_iPlayerTeam[pool][client]]--;
				break;
			}
		}
		
		g_iPlayerTeam[pool][client] = TEAM_NONE;
	}
}