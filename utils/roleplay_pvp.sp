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
#include <sdkhooks>
#include <smlib>
#include <colors_csgo>
#include <basecomm>

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

// TODO: Un attaquant passe défenseur s'il a 100 points de plus que le défenseur actuel.
// TODO: Dégat divisé par 2 entre chaque gang attaquant
// TODO: Dégat divisé par 2 entre quelqu'un du même gang
// TODO: Vérifier à quoi sert: CTF_SpawnFlag_Delay
// TODO: Configuration d'item sauvegardée pour retrait rapide en banque
// TODO: Corrigé big-mac
// TODO: Ajouter les TAG.

//#define DEBUG
#define MAX_GROUPS		150
#define MAX_ZONES		310
#define	MAX_ENTITIES	2048
#define	ZONE_BUNKER		235
#define ZONE_RESPAWN	230
#define	FLAG_SPEED		250.0
#define	FLAG_POINTS		250
#define ELO_FACTEUR_K	40.0

// -----------------------------------------------------------------------------------------------------------------
enum flag_data { data_group, data_skin, data_red, data_green, data_blue, data_time, data_owner, flag_data_max };
int g_iClientFlag[65];
float g_fLastDrop[65];
int g_iFlagData[MAX_ENTITIES+1][flag_data_max];
// -----------------------------------------------------------------------------------------------------------------
Handle g_hCapturable = INVALID_HANDLE;
Handle g_hGodTimer[65];
int g_iCapture_POINT[MAX_GROUPS];
bool g_bIsInCaptureMode = false;
int g_cBeam;
StringMap g_hGlobalDamage;
enum damage_data { gdm_shot, gdm_damage, gdm_hitbox, gdm_elo, gdm_max };
// -----------------------------------------------------------------------------------------------------------------

public Plugin myinfo = {
	name = "Utils: PvP", author = "KoSSoLaX",
	description = "RolePlay - Utils: PvP",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};
public void OnPluginStart() {
	RegConsoleCmd("drop", FlagDrop);
	RegServerCmd("rp_item_spawnflag", 	Cmd_ItemFlag,			"RP-ITEM",	FCVAR_UNREGISTERED);
	g_hGlobalDamage = new StringMap();
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnConfigsExecuted() {
	if( g_hCapturable == INVALID_HANDLE ) {
		g_hCapturable = FindConVar("rp_capture");
		HookConVarChange(g_hCapturable, OnCvarChange);
	}
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}
public void OnCvarChange(Handle cvar, const char[] oldVal, const char[] newVal) {
	#if defined DEBUG
	PrintToServer("OnCvarChange");
	#endif	
	if( cvar == g_hCapturable ) {
		if( !g_bIsInCaptureMode && StrEqual(oldVal, "none") && StrEqual(newVal, "active") ) {
			CAPTURE_Start();
		}
		else if( g_bIsInCaptureMode && StrEqual(oldVal, "active") && StrEqual(newVal, "none") ) {
			CAPTURE_Stop();
		}
	}
}
public void OnClientPostAdminCheck(int client) {
	if( g_bIsInCaptureMode ) {
		GDM_Init(client);
		rp_HookEvent(client, RP_OnPlayerDead, fwdDead);
		rp_HookEvent(client, RP_OnPlayerHUD, fwdHUD);
		rp_HookEvent(client, RP_OnPlayerSpawn, fwdSpawn);
		SDKHook(client, SDKHook_FireBulletsPost, fwdFireBullet);
	}
}
// -----------------------------------------------------------------------------------------------------------------
public Action Cmd_ItemFlag(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemFlag");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int gID = rp_GetClientGroupID(client);
	
	if( gID == 0 ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas de groupe.");
		return;
	}
	if( rp_GetCaptureInt(cap_bunker) == gID ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le gang défenseur ne peut pas utiliser de drapeau.");
		return;
	}
	if( rp_IsInPVP(client) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être hors de la PvP.");
		return;
	}
	
	if( g_iClientFlag[client] > 0 && IsValidEdict(g_iClientFlag[client]) && IsValidEntity(g_iClientFlag[client]) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà un drapeau.");
		return;
	}
	
	char classname[64];
	int count = 0;
	
	for(int i=1; i<MAX_ENTITIES; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( !StrEqual(classname, "ctf_flag") )
			continue;
		
		
		if( g_iFlagData[i][data_group] == gID ) {
			count++;
			
			if( count >= 2 ) {
				
				if( gID == rp_GetClientInt(client, i_Group) ) {
					if( IsValidClient(g_iFlagData[i][data_owner]) ) {
						g_iClientFlag[g_iFlagData[i][data_owner]] = 0;
					}
					
					AcceptEntityInput(i, "KillHierarchy");
				}
				else {
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il y a déjà 2 drapeaux pour votre équipe sur le terrain.");
					ITEM_CANCEL(client, item_id);
					return;
				}
			}
		}
	}
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin); vecOrigin[2] += 10.0;
	
	int color[3];
	char strBuffer[4][8];
	rp_GetGroupData(gID, group_type_color, classname, sizeof(classname));
	ExplodeString(classname, ",", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));
	color[0] = StringToInt(strBuffer[0]);
	color[1] = StringToInt(strBuffer[1]);
	color[2] = StringToInt(strBuffer[2]);
	
	int flag = CTF_SpawnFlag(vecOrigin, Math_GetRandomInt(0, 1), color);
	g_iFlagData[flag][data_group] = gID;
}
public Action FlagDrop(int client, int args) {
	if( g_iClientFlag[client] > 0 ) {
		
		CTF_DropFlag(client, true);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
public Action FlagThink(Handle timer, any data) {
	int entity = EntRefToEntIndex(data);
	
	if( !IsValidEdict(entity) )
		return Plugin_Handled;
	
	float vecFlag[3], vecOrigin[3], vecOrigin2[3];
	int color[4];
	color[0] = g_iFlagData[entity][data_red];
	color[1] = g_iFlagData[entity][data_green];
	color[2] = g_iFlagData[entity][data_blue];
	color[3] = 200;
	
	if( IsValidClient(g_iFlagData[entity][data_owner]) ) {
		return Plugin_Handled;
	}
	
	if( g_bIsInCaptureMode ) {
		if( rp_GetPlayerZone(entity) == ZONE_BUNKER ) {
			
			if( rp_GetCaptureInt(cap_bunker) != g_iFlagData[entity][data_group] )
				g_iCapture_POINT[g_iFlagData[entity][data_group]] += FLAG_POINTS;
			
			Entity_GetAbsOrigin(entity, vecOrigin);
			
			TE_SetupBeamRingPoint(vecOrigin, 1.0, 50.0, g_cBeam, g_cBeam, 0, 30, 2.0, 5.0, 1.0, color, 10, 0);
			TE_SendToAll();
			
			AcceptEntityInput(entity, "KillHierarchy");
			return Plugin_Handled;
		}
	}
	
	if( g_iFlagData[entity][data_time]+60 < GetTime() ) {
		int gID = g_iFlagData[entity][data_group];
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( gID == rp_GetClientGroupID(i) )
				ClientCommand(i, "play common/warning");
		}
		AcceptEntityInput(entity, "KillHierarchy");
		return Plugin_Handled;
	}	
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecFlag);
	vecFlag[2] += 25.0;
	
	for(int client=1; client<=MaxClients; client++) {
		if( !IsValidClient(client) || !IsPlayerAlive(client) )
			continue;
		if( g_iClientFlag[client] > 0 )
			continue;		
		if( g_iFlagData[entity][data_group] != rp_GetClientGroupID(client) )
			continue;
			
		GetClientAbsOrigin(client, vecOrigin);
		GetClientEyePosition(client, vecOrigin2);
		
		TE_SetupBeamPoints(vecOrigin, vecFlag, g_cBeam, g_cBeam, 0, 30, 0.2, 1.0, 1.0, 1, 0.0, color, 10);
		TE_SendToClient(client);
		
		if( GetVectorDistance(vecOrigin, vecFlag) <= 52.0 || GetVectorDistance(vecOrigin2, vecFlag) <= 52.0 ) {
			CTF_FlagTouched(client, entity);
		}
	}
	
	CreateTimer(0.1, FlagThink, data);
	return Plugin_Handled;
}
public Action SDKHideFlag(int from, int to ) {
	if( g_iFlagData[from][data_owner] == to && rp_GetClientInt(to, i_ThirdPerson) == 0) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
// -----------------------------------------------------------------------------------------------------------------
void CAPTURE_Start() {
	#if defined DEBUG
	PrintToServer("CAPTURE_Start");
	#endif
	CPrintToChatAll("{lightblue} ================================== {default}");
	CPrintToChatAll("{lightblue} Le bunker peut maintenant être capturé! {default}");
	CPrintToChatAll("{lightblue} ================================== {default}");
	
	g_bIsInCaptureMode = true;
	int gID;
			
	for(int i=1; i<MAX_GROUPS; i++) {
		g_iCapture_POINT[i] = 0;			
	}

	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		GDM_Init(i);
		rp_HookEvent(i, RP_OnPlayerDead, fwdDead);
		rp_HookEvent(i, RP_OnPlayerHUD, fwdHUD);
		rp_HookEvent(i, RP_OnPlayerSpawn, fwdSpawn);
		SDKHook(i, SDKHook_FireBulletsPost, fwdFireBullet);
		gID = rp_GetClientGroupID(i);
		g_iCapture_POINT[gID] += 50;
		
		
		if( !rp_IsInPVP(i) )
			continue;
		
		int v = Client_GetVehicle(i);
		if( v > 0 )
			rp_ClientVehicleExit(i, v, true);
		
		rp_ClientDamage(i, 10000, 1);
		if( g_iClientFlag[i] > 0 ) {
			AcceptEntityInput(g_iClientFlag[i], "KillHierarchy");
			g_iClientFlag[i] = 0;
		}
		
		ClientCommand(i, "play *tsx/roleplay/bombing.mp3");
	}
	
	g_iCapture_POINT[rp_GetCaptureInt(cap_bunker)] += 2000;
			
	for(int i=1; i<MAX_ZONES; i++) {
		if( rp_GetZoneBit(i) & BITZONE_PVP ) {
			ServerCommand("rp_force_clean %d full", i);
		}
	}
	
	CreateTimer(1.0, CAPTURE_Tick);
	
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_hurt", fwdGod_PlayerHurt, EventHookMode_Pre);
	
}
void CAPTURE_Stop() {
	#if defined DEBUG
	PrintToServer("CAPTURE_Stop");
	#endif
	int winner, maxPoint = 0;
	char optionsBuff[4][32], tmp[256];
	
	CPrintToChatAll("{lightblue} ================================== {default}");
	CPrintToChatAll("{lightblue} Le bunker ne peut plus être capturés. {default}");
	CPrintToChatAll("{lightblue} ================================== {default}");
	
	g_bIsInCaptureMode = false;
	
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		rp_UnhookEvent(i, RP_OnPlayerDead, fwdDead);
		rp_UnhookEvent(i, RP_OnPlayerHUD, fwdHUD);
		rp_UnhookEvent(i, RP_OnPlayerSpawn, fwdSpawn);
		SDKUnhook(i, SDKHook_FireBulletsPost, fwdFireBullet);
	}
	
	for(int i=1; i<MAX_GROUPS; i++) {
		if( rp_GetGroupInt(i, group_type_chef)!= 1 )
			continue;
		if( maxPoint > g_iCapture_POINT[i] )
			continue;

		winner = i;
		maxPoint = g_iCapture_POINT[i];
	}
			
	rp_GetGroupData(winner, group_type_name, tmp, sizeof(tmp));
	ExplodeString(tmp, " - ", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
			
	char fmt[1024];
	Format(fmt, sizeof(fmt), "UPDATE `rp_servers` SET `bunkerCap`='%i';';", winner);
	SQL_TQuery( rp_GetDatabase(), SQL_QueryCallBack, fmt);
	rp_SetCaptureInt(cap_bunker, winner);
			
	CPrintToChatAll("{lightblue} Le bunker appartient maintenant à... %s !", optionsBuff[1]);			
	CPrintToChatAll("{lightblue} ================================== {default}");
	
	UnhookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	UnhookEvent("player_hurt", fwdGod_PlayerHurt, EventHookMode_Pre);
	
	
	CAPTURE_Reward();
}
void CAPTURE_Reward() {
	#if defined DEBUG
	PrintToServer("CAPTURE_Reward");
	#endif
	int amount;
	char tmp[128];
	
	for(int client=1; client<=GetMaxClients(); client++) {
		if( !IsValidClient(client) || rp_GetClientGroupID(client) == 0 )
			continue;
		
		if( rp_GetClientGroupID(client) == rp_GetCaptureInt(cap_bunker) ) {
			amount = 10;
			rp_IncrementSuccess(client, success_list_pvpkill, 100);
		}
		else {
			amount = 1;
		}

		int gID = rp_GetClientGroupID(client);
		int bonus = RoundToCeil(g_iCapture_POINT[gID] / 200.0);
		
		rp_ClientGiveItem(client, 309, amount + 3 + bonus, true);
		rp_GetItemData(309, item_type_name, tmp, sizeof(tmp));
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu %d %s, en récompense de la capture.", amount+3+bonus, tmp);
	}	
}
public Action CAPTURE_Tick(Handle timer, any none) {
	static int lastGang = -1;
	
	if( !g_bIsInCaptureMode )
		return Plugin_Handled;
	
	char strBuffer[4][8], tmp[64], tmp2[64];
	int color[4], defense = rp_GetCaptureInt(cap_bunker);
	float mins[3], maxs[3];
	mins[0] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_min_x);
	mins[1] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_min_y);
	mins[2] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_min_z);
	maxs[0] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_max_x);
	maxs[1] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_max_y);
	maxs[2] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_max_z);
	
	rp_GetGroupData(defense, group_type_color, tmp, sizeof(tmp));
	ExplodeString(tmp, ",", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));
	color[0] = StringToInt(strBuffer[0]);
	color[1] = StringToInt(strBuffer[1]);
	color[2] = StringToInt(strBuffer[2]);
	color[3] = 255;
	
	Effect_DrawBeamBoxToAll(mins, maxs, g_cBeam, g_cBeam, 0, 30, 2.0, 5.0, 5.0, 2, 1.0, color, 0);
	
	if( lastGang != defense ) {
		Format(tmp2, sizeof(tmp2), "%d %d %d", color[0], color[1], color[2]);
		
		
		for (int i = MaxClients; i <= MAX_ENTITIES; i++) {
			if( !IsValidEdict(i) || !IsValidEntity(i) )
				continue;
			if( !rp_IsInPVP(i) )
				continue;
			
			GetEdictClassname(i, tmp, sizeof(tmp));
			if( StrEqual(tmp, "point_spotlight") ) {
				SetVariantString(tmp2);
				AcceptEntityInput(i, "SetColor");
			}
		}
	}
	lastGang = defense;
	
	CreateTimer(1.0, CAPTURE_Tick);
	return Plugin_Handled;
}
// -----------------------------------------------------------------------------------------------------------------
public Action fwdSpawn(int client) {
	if( rp_GetClientGroupID(client) == rp_GetCaptureInt(cap_bunker) )
		CreateTimer(0.25, fwdSpawn_ToRespawn, client);
	
	return Plugin_Continue;
}
public Action fwdSpawn_ToRespawn(Handle timer, any client) {
	if( rp_GetClientGroupID(client) == rp_GetCaptureInt(cap_bunker) && IsValidClient(client) ) {
		float mins[3], maxs[3], rand[3];
		mins[0] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_min_x);
		mins[1] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_min_y);
		mins[2] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_min_z);
		maxs[0] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_max_x);
		maxs[1] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_max_y);
		maxs[2] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_max_z);
		
		rand[0] = Math_GetRandomFloat(mins[0] + 64.0, maxs[0] - 64.0);
		rand[1] = Math_GetRandomFloat(mins[1] + 64.0, maxs[1] - 64.0);
		rand[2] = mins[0] + 32.0;
		
		TeleportEntity(client, rand, NULL_VECTOR, NULL_VECTOR);
		FakeClientCommand(client, "say /stuck");
		Client_SetSpawnProtect(client, true);
	}
}
public Action fwdDead(int victim, int attacker, float& respawn) {
	if( g_iClientFlag[victim] > 0 ) {
		CTF_DropFlag(victim, false);
	}
	
	GDM_ELOKill(attacker, victim);
	rp_IncrementSuccess(attacker, success_list_killpvp2);
	respawn = 0.25;
	return Plugin_Handled;
}
public Action fwdHUD(int client, char[] szHUD, const int size) {
	
	int gID = rp_GetClientGroupID(client);
	int defTeam = rp_GetCaptureInt(cap_bunker);
	char optionsBuff[4][32], tmp[128];
	
	if( g_bIsInCaptureMode && gID > 0 ) {
		
		Format(szHUD, size, "PvP: Capture du bunker");
		if( gID == defTeam )
			Format(szHUD, size, " - Défense");
		else
			Format(szHUD, size, " - Attaque");
		
		for(int i=1; i<MAX_GROUPS; i++) {
			if(rp_GetGroupInt(i, group_type_chef) != 1 )
				continue;
				
			if( g_iCapture_POINT[i] == 0 && gID != i )
				continue;
			
			rp_GetGroupData(i, group_type_name, tmp, sizeof(tmp));
			ExplodeString(tmp, " - ", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
				
			if( gID == i )
				Format(szHUD, size, "%s [%s]: %d\n", szHUD, optionsBuff[1], g_iCapture_POINT[i]);
			else
				Format(szHUD, size, "%s %s: %d\n", szHUD, optionsBuff[1], g_iCapture_POINT[i]);
				
		}
		
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public void fwdFireBullet(int client, int shot, const char[] weaponname) {
	PrintToChatAll("--> Client: %d shot: %d, Weapon: %s", client, shot, weaponname);
	GDM_Add(client, shot);
}
public Action Event_PlayerHurt(Handle event, char[] name, bool dontBroadcast) {
	char weapon[64];
	int victim, attacker, damage, hitgroup;
	
	victim 	= GetClientOfUserId(GetEventInt(event, "userid"));
	attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	damage = GetEventInt(event, "dmg_health");	
	hitgroup = GetEventInt(event, "hitgroup");
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if( StrEqual(weapon, "inferno") || StrEqual(weapon, "hegrenade") ) { // TODO: Ajouter les explosifs du rp
		return Plugin_Continue;
	}
	
	PrintToChatAll("--> Victime: %d Attaquant: %d Dégat: %d, Hitbox: %d", victim, attacker, damage, hitgroup);
	
	GDM_Add(attacker, 0, damage, hitgroup);
	return Plugin_Continue;
}
// -----------------------------------------------------------------------------------------------------------------
public Action SwitchToFirst(Handle timer, any client) {
	if( rp_GetClientInt(client, i_ThirdPerson) == 0 )
		ClientCommand(client, "firstperson");
}
// -----------------------------------------------------------------------------------------------------------------
int CTF_SpawnFlag(float vecOrigin[3], int skin, int color[3]) {
	
	char szSkin[12];
	char szColor[32];
	Format(szSkin, sizeof(szSkin), "%d", skin);
	Format(szColor, sizeof(szColor), "%d %d %d", color[0], color[1], color[2]);
	
	
	int ent1 = CreateEntityByName("hegrenade_projectile");
	if( !IsValidEdict(ent1) )
		return -1;
	int ent2 = CreateEntityByName("prop_dynamic_override");
	if( !IsValidEdict(ent2) )
		return -1;
	int ent3 = CreateEntityByName("light_dynamic");
	if( !IsValidEdict(ent3) )
		return -1;
	
	//
	DispatchKeyValue(ent1, "classname", "ctf_flag");
	//
	DispatchKeyValue(ent3, "brightness", "3");
	DispatchKeyValue(ent3, "distance", "128");
	
	DispatchKeyValue(ent2, "Skin", szSkin);
	DispatchKeyValue(ent2, "model", "models/flag/briefcase.mdl");
	DispatchKeyValue(ent3, "_light", szColor);
	
	DispatchSpawn(ent1);
	DispatchSpawn(ent2);
	DispatchSpawn(ent3);
	
	SetEntityMoveType(ent1, MOVETYPE_FLYGRAVITY);
	
	
	SetEntProp(ent1, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	SetEntProp(ent1, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);
	SetEntProp(ent2, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	SetEntProp(ent2, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);
	
	
	SetEntPropFloat(ent1, Prop_Send, "m_flElasticity", 0.1);
	
	vecOrigin[2] += 10.0;
	TeleportEntity(ent1, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(ent3, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	//
	SetVariantString("!activator");
	AcceptEntityInput(ent2, "SetParent", ent1);
	//
	SetVariantString("!activator");
	AcceptEntityInput(ent3, "SetParent", ent1);
	
	SetEntityRenderMode(ent1, RENDER_TRANSALPHA);
	SetEntityRenderMode(ent2, RENDER_TRANSALPHA);
	SetEntityRenderColor(ent1, 0, 0, 0, 0);
	SetEntityRenderColor(ent2, color[0], color[1], color[2],  255);
	
	CreateTimer(0.1, CTF_SpawnFlag_Delay, ent2);
	
	g_iFlagData[ent1][data_skin] = skin;
	g_iFlagData[ent1][data_red] = color[0];
	g_iFlagData[ent1][data_green] = color[1];
	g_iFlagData[ent1][data_blue] = color[2];
	g_iFlagData[ent1][data_time] = GetTime();
	g_iFlagData[ent1][data_owner] = 0;
	
	CreateTimer(0.01, FlagThink, EntIndexToEntRef(ent1));
	
	return ent1;
}
void CTF_DropFlag(int client, int thrown) {
	
	int flag = g_iClientFlag[client];
	g_iClientFlag[client] = 0;
	g_fLastDrop[client] = GetGameTime();
	
	int skin = g_iFlagData[flag][data_skin];
	int color[3];
	color[0] = g_iFlagData[flag][data_red];
	color[1] = g_iFlagData[flag][data_green];
	color[2] = g_iFlagData[flag][data_blue];
	int gID = g_iFlagData[flag][data_group];
	
	AcceptEntityInput(flag, "KillHierarchy");
	
	float vecOrigin[3], vecAngles[3], vecPush[3];
	GetClientEyeAngles(client, vecAngles);
	GetClientEyePosition(client, vecOrigin);
	vecAngles[0] += 10.0;
	
	flag = CTF_SpawnFlag(vecOrigin, skin, color);
	g_iFlagData[flag][data_group] = gID;
	
	if( thrown ) {
		
		vecOrigin[0] = (vecOrigin[0] + (60.0 * Cosine( DegToRad( vecAngles[1] ) ) ) );
		vecOrigin[1] = (vecOrigin[1] + (60.0 * Sine( DegToRad( vecAngles[1] ) ) ) );
		vecOrigin[2] = (vecOrigin[2] - 20.0);
		
		Entity_GetAbsVelocity(client, vecPush);
		
		
		vecPush[0] = vecPush[0]*0.5 + ( FLAG_SPEED * Cosine( DegToRad(vecAngles[1]) ) );
		vecPush[1] = vecPush[1]*0.5 + ( FLAG_SPEED * Sine( DegToRad(vecAngles[1]) ) );
		vecPush[2] = vecPush[2]*0.5 + ( (FLAG_SPEED/2.0) * Cosine( DegToRad( vecAngles[0] ) ) );
	}
	else {
		
		vecOrigin[2] = (vecOrigin[2] - 20.0);
		vecPush[2] = 20.0;
	}
	
	vecPush[2] += 50.0;
	TeleportEntity(flag, vecOrigin, vecAngles, vecPush);
	
}
void CTF_FlagTouched(int client, int flag) {	
	
	if( (g_fLastDrop[client]+3.0) >= GetGameTime() ) {
		return;
	}
	
	g_iFlagData[flag][data_owner] = client;
	g_iClientFlag[client] = flag;
	
	ClientCommand(client, "play common/wpn_hudoff");
	
	SetVariantString("!activator");
	AcceptEntityInput(flag, "SetParent", client);
	
	SetVariantString("grenade2");
	AcceptEntityInput(flag, "SetParentAttachment");
	
	char strBuffer[4][8], tmp[64];
	float vecOrigin[3], ang[3], pos[3];
	Entity_GetAbsOrigin(flag, vecOrigin);
	
	rp_GetGroupData(g_iFlagData[flag][data_group], group_type_color, tmp, sizeof(tmp));
	ExplodeString(tmp, ",", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));
	
	
	ang[0] = -90.0;
	ang[1] = 180.0;
	ang[2] = 90.0;
	
	
	pos[0] = 20.0;
	pos[1] = 5.0;
	pos[2] = 0.0;
	
	TeleportEntity(flag, pos, ang, NULL_VECTOR);
	ClientCommand(client, "thirdperson");
	CreateTimer(0.5, SwitchToFirst, client);
	
	SDKHook(flag, SDKHook_SetTransmit, SDKHideFlag);
}
public Action CTF_SpawnFlag_Delay(Handle timer, any ent2) {
	TeleportEntity(ent2, view_as<float>({30.0, 0.0, 0.0}), view_as<float>({0.0, 90.0, 0.0}), NULL_VECTOR);
}
// -----------------------------------------------------------------------------------------------------------------
void GDM_Init(int client) {
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	
	int array[gdm_max];
	
	if( !g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array)) ) {
		array[gdm_elo] = 1500;
		g_hGlobalDamage.SetArray(szSteamID, array, sizeof(array));
	}
}
void GDM_Add(int client, int shot = 0, int damage=0, int hitbox=0) {
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	
	int array[gdm_max];
	g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array));
	array[gdm_shot] += shot;
	array[gdm_damage] += damage;
	array[gdm_hitbox] += hitbox;
	
	g_hGlobalDamage.SetArray(szSteamID, array, sizeof(array));
}
void GDM_Get(int client, int& shot, int& damage, int& hitbox) {
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	
	int array[gdm_max];
	g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array));
	shot = array[gdm_shot];
	damage = array[gdm_damage];
	hitbox = array[gdm_hitbox];	
}
void GDM_ELOKill(int client, int target) {
	#if defined DEBUG
	PrintToServer("GDM_ELOKill");
	#endif
	
	char szSteamID[32], szSteamID2[32];
	int attacker[gdm_max], victim[gdm_max], cgID, tgID, cElo, tElo;
	float cDelta, tDelta;
	
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	GetClientAuthId(target, AuthId_Engine, szSteamID2, sizeof(szSteamID2));
	
	g_hGlobalDamage.GetArray(szSteamID, attacker, sizeof(attacker));
	g_hGlobalDamage.GetArray(szSteamID2, victim, sizeof(victim));
	
	cDelta = 1.0/((Pow(10.0, - (attacker[gdm_elo] - victim[gdm_elo]) / 400.0)) + 1.0);
	tDelta = 1.0/((Pow(10.0, - (victim[gdm_elo] - attacker[gdm_elo]) / 400.0)) + 1.0);
	cElo = RoundFloat(float(attacker[gdm_elo]) + ELO_FACTEUR_K * (1.0 - cDelta));
	tElo = RoundFloat(float(victim[gdm_elo]) + ELO_FACTEUR_K * (0.0 - tDelta));
	cgID = rp_GetClientGroupID(client);
	tgID = rp_GetClientGroupID(target);
	
	g_iCapture_POINT[ tgID ] += tElo - victim[gdm_elo];
	g_iCapture_POINT[ cgID ] += cElo - attacker[gdm_elo];
	if( g_iCapture_POINT[ tgID ] < 0 ) {
		g_iCapture_POINT[ cgID ] += g_iCapture_POINT[tgID];
		g_iCapture_POINT[ tgID ] = 0;
	}
	
	PrintToChatAll("Attaquant: NOUVEAU %d ANCIEN %d", cElo, attacker[gdm_elo]);
	PrintToChatAll("Victime: NOUVEAU %d ANCIEN %d", tElo, victim[gdm_elo]);	
	
	attacker[gdm_elo] = cElo;
	victim[gdm_elo] = tElo;
	
	g_hGlobalDamage.SetArray(szSteamID, attacker, sizeof(attacker));
	g_hGlobalDamage.SetArray(szSteamID2, victim, sizeof(victim));
	
}
// -----------------------------------------------------------------------------------------------------------------
void Client_SetSpawnProtect(int client, bool status) {
	if( status == true ) {
		rp_HookEvent(client, RP_OnPlayerZoneChange, fwdGODZoneChange);
		rp_HookEvent(client, RP_OnPlayerDead, fwdGodPlayerDead);
		g_hGodTimer[client] = CreateTimer(10.0, GOD_Expire, client);
		rp_ClientColorize(client, view_as<int>({255, 255, 255, 100}));
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez 10 secondes de protection.");
	}
	else {
		rp_UnhookEvent(client, RP_OnPlayerZoneChange, fwdGODZoneChange);
		rp_UnhookEvent(client, RP_OnPlayerDead, fwdGodPlayerDead);
		rp_ClientColorize(client);
		g_hGodTimer[client] = INVALID_HANDLE;
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre protection a expiré.");
	}
}
public Action fwdGODZoneChange(int client, int oldZone, int newZone) {
	if( oldZone == ZONE_RESPAWN && newZone != ZONE_RESPAWN ) {
		Client_SetSpawnProtect(client, false);
	}
}
public Action fwdGodPlayerDead(int client, int attacker, float& respawn) {
	Client_SetSpawnProtect(client, false);
}
public void fwdGodFireBullet(int client, int shot, const char[] weaponname) {
	Client_SetSpawnProtect(client, false);
}
public Action fwdGod_PlayerHurt(Handle event, char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(  g_hGodTimer[attacker] ) {
		Client_SetSpawnProtect(attacker, false);
	}
}
public Action OnPlayerRunCmd(int client, int& buttons) {
	if( (buttons & (IN_ATTACK|IN_ATTACK2)) && g_hGodTimer[client] ) {
		Client_SetSpawnProtect(client, false);
	}
}
public Action GOD_Expire(Handle timer, any client) {
	if( !g_hGodTimer[client] )
		Client_SetSpawnProtect(client, false);
}
