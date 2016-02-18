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
#include <topmenus>

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

// TODO: Ajouter les TAG.

//#define DEBUG
#define MAX_GROUPS		150
#define MAX_ZONES		310
#define	MAX_ENTITIES	2048
#define	ZONE_BUNKER		235
#define ZONE_RESPAWN	230
#define	FLAG_SPEED		250.0
#define	FLAG_POINTS		200
#define ELO_FACTEUR_K	40.0

// -----------------------------------------------------------------------------------------------------------------
enum flag_data { data_group, data_skin, data_red, data_green, data_blue, data_time, data_owner, data_lastOwner, flag_data_max };
int g_iClientFlag[65];
float g_fLastDrop[65];
int g_iFlagData[MAX_ENTITIES+1][flag_data_max];
// -----------------------------------------------------------------------------------------------------------------
Handle g_hCapturable = INVALID_HANDLE;
Handle g_hGodTimer[65];
int g_iCapture_POINT[MAX_GROUPS];
bool g_bIsInCaptureMode = false;
int g_cBeam;
StringMap g_hGlobalDamage, g_hGlobalSteamID;
enum damage_data { gdm_shot, gdm_touch, gdm_damage, gdm_hitbox, gdm_elo, gdm_flag, gdm_max };
TopMenu g_hStatsMenu;
TopMenuObject g_hStatsMenu_Shoot, g_hStatsMenu_Head, g_hStatsMenu_Damage, g_hStatsMenu_Flag, g_hStatsMenu_ELO;
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
	g_hGlobalSteamID = new StringMap();
	
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
		rp_HookEvent(client, RP_OnFrameSeconde, fwdFrame);
		rp_HookEvent(client, RP_PostPlayerPhysic, fwdPhysics);
		rp_HookEvent(client, RP_PostTakeDamageWeapon, fwdTakeDamage);
		rp_HookEvent(client, RP_PostTakeDamageKnife, fwdTakeDamage);
		rp_HookEvent(client, RP_OnPlayerZoneChange, fwdZoneChange);
		rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
		SDKHook(client, SDKHook_SetTransmit, fwdGodHide2);
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
	if( rp_GetZoneBit(rp_GetPlayerZone(client)) & BITZONE_PVP ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être hors du bunker.");
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
			
			if( count >= 3 ) {
				
				if( gID == rp_GetClientInt(client, i_Group) ) {
					if( IsValidClient(g_iFlagData[i][data_owner]) ) {
						g_iClientFlag[g_iFlagData[i][data_owner]] = 0;
					}
					
					AcceptEntityInput(i, "KillHierarchy");
				}
				else {
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il y a déjà 3 drapeaux pour votre équipe sur le terrain.");
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
			
			if( rp_GetCaptureInt(cap_bunker) != g_iFlagData[entity][data_group] ) {
				g_iCapture_POINT[g_iFlagData[entity][data_group]] += FLAG_POINTS;
				g_iCapture_POINT[rp_GetCaptureInt(cap_bunker)] -= FLAG_POINTS;
				
				GDM_RegisterFlag(g_iFlagData[entity][data_lastOwner]);
				
				PrintHintText(g_iFlagData[entity][data_lastOwner], "<b>Drapeau posé !</b>\n <font color='#33ff33'>+%d</span> points !", FLAG_POINTS);
			}
			
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
	
	CAPTURE_UpdateLight();
	
	int wall = Entity_FindByName("job=201__-pvp_wall", "func_brush");
	if( wall > 0 )
		AcceptEntityInput(wall, "Disable");
	
	
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
		rp_HookEvent(i, RP_PostPlayerPhysic, fwdPhysics);
		rp_HookEvent(i, RP_OnFrameSeconde, fwdFrame);
		rp_HookEvent(i, RP_PostTakeDamageWeapon, fwdTakeDamage);
		rp_HookEvent(i, RP_PostTakeDamageKnife, fwdTakeDamage);
		rp_HookEvent(i, RP_OnPlayerZoneChange, fwdZoneChange);
		rp_HookEvent(i, RP_OnPlayerCommand, fwdCommand);
		SDKHook(i, SDKHook_SetTransmit, fwdGodHide2);
		
		gID = rp_GetClientGroupID(i);
		g_iCapture_POINT[gID] += 50;
		if( rp_GetClientInt(i, i_Group) == gID ) 
			g_iCapture_POINT[gID] += 100;
		
		
		if( !(rp_GetZoneBit(rp_GetPlayerZone(i)) & BITZONE_PVP) )
			continue;
		
		int v = Client_GetVehicle(i);
		if( v > 0 )
			rp_ClientVehicleExit(i, v, true);
		
		rp_ClientDamage(i, 10000,  i);
		ForcePlayerSuicide(i);
		if( g_iClientFlag[i] > 0 ) {
			AcceptEntityInput(g_iClientFlag[i], "KillHierarchy");
			g_iClientFlag[i] = 0;
		}
		
		ClientCommand(i, "play *tsx/roleplay/bombing.mp3");
	}
	
	g_iCapture_POINT[rp_GetCaptureInt(cap_bunker)] += 1000;
			
	for(int i=1; i<MAX_ZONES; i++) {
		if( rp_GetZoneBit(i) & BITZONE_PVP ) {
			ServerCommand("rp_force_clean %d full", i);
		}
	}
	
	CreateTimer(1.0, CAPTURE_Tick);
	
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("weapon_fire", Event_PlayerShoot, EventHookMode_Post);
	HookEvent("player_hurt", fwdGod_PlayerHurt, EventHookMode_Pre);
	HookEvent("weapon_fire", fwdGod_PlayerShoot, EventHookMode_Pre);	
}
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrEqual(command, "pvp") ) {
		if( g_hStatsMenu != INVALID_HANDLE )
			g_hStatsMenu.Display(client, TopMenuPosition_Start);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
void CAPTURE_Stop() {
	#if defined DEBUG
	PrintToServer("CAPTURE_Stop");
	#endif
	int winner, maxPoint = 0;
	char optionsBuff[4][32], tmp[256];
	
	CPrintToChatAll("{lightblue} ================================== {default}");
	CPrintToChatAll("{lightblue} Le bunker ne peut plus être capturé. {default}");
	CPrintToChatAll("{lightblue} ================================== {default}");
	
	int wall = Entity_FindByName("job=201__-pvp_wall", "func_brush");
	if( wall > 0 )
		AcceptEntityInput(wall, "Enable");
	
	g_bIsInCaptureMode = false;
	
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		rp_UnhookEvent(i, RP_OnPlayerDead, fwdDead);
		rp_UnhookEvent(i, RP_OnPlayerHUD, fwdHUD);
		rp_UnhookEvent(i, RP_OnPlayerSpawn, fwdSpawn);
		rp_UnhookEvent(i, RP_PostPlayerPhysic, fwdPhysics);
		rp_UnhookEvent(i, RP_OnFrameSeconde, fwdFrame);
		rp_UnhookEvent(i, RP_PostTakeDamageWeapon, fwdTakeDamage);
		rp_UnhookEvent(i, RP_PostTakeDamageKnife, fwdTakeDamage);
		rp_UnhookEvent(i, RP_OnPlayerZoneChange, fwdZoneChange);
		rp_UnhookEvent(i, RP_OnPlayerCommand, fwdCommand);
		SDKUnhook(i, SDKHook_SetTransmit, fwdGodHide2);
		if( IsPlayerAlive(i) )
			rp_ClientColorize(i);
	}
	
	int totalPoints = 0;
	for(int i=1; i<MAX_GROUPS; i++) {
		if( maxPoint > g_iCapture_POINT[i] )
			continue;

		winner = i;
		maxPoint = g_iCapture_POINT[i];
		totalPoints += g_iCapture_POINT[i];
	}
			
	rp_GetGroupData(winner, group_type_name, tmp, sizeof(tmp));
	ExplodeString(tmp, " - ", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
			
	char fmt[1024];
	Format(fmt, sizeof(fmt), "UPDATE `rp_servers` SET `bunkerCap`='%i', `capVilla`='%i';", winner, winner);
	SQL_TQuery( rp_GetDatabase(), SQL_QueryCallBack, fmt);
	rp_SetCaptureInt(cap_bunker, winner);
	rp_SetCaptureInt(cap_villa, winner);
			
	CPrintToChatAll("{lightblue} Le bunker appartient maintenant à... %s !", optionsBuff[1]);			
	CPrintToChatAll("{lightblue} ================================== {default}");
	
	UnhookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	UnhookEvent("weapon_fire", Event_PlayerShoot, EventHookMode_Post);
	UnhookEvent("player_hurt", fwdGod_PlayerHurt, EventHookMode_Pre);
	UnhookEvent("weapon_fire", fwdGod_PlayerShoot, EventHookMode_Pre);	
	
	CAPTURE_Reward(totalPoints);
	GDM_Resume();
}
void CAPTURE_UpdateLight() {
	char strBuffer[4][32], tmp[64], tmp2[64];
	int color[4],  defense = rp_GetCaptureInt(cap_bunker);
	
	rp_GetGroupData(defense, group_type_color, tmp, sizeof(tmp));
	ExplodeString(tmp, ",", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));
	color[0] = StringToInt(strBuffer[0]);
	color[1] = StringToInt(strBuffer[1]);
	color[2] = StringToInt(strBuffer[2]);
	color[3] = 255;
	
	Format(tmp2, sizeof(tmp2), "%d %d %d", color[0], color[1], color[2]);
	
	for (int i = MaxClients; i <= MAX_ENTITIES; i++) {
		if( !IsValidEdict(i) || !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, sizeof(tmp));
		if( StrEqual(tmp, "point_spotlight") && rp_IsInPVP(i) ) {
			SetVariantString(tmp2);
			AcceptEntityInput(i, "SetColor");
		}
	}
}
void CAPTURE_Reward(int totalPoints) {
	#if defined DEBUG
	PrintToServer("CAPTURE_Reward");
	#endif
	int amount;
	char tmp[128];
	
	for(int client=1; client<=GetMaxClients(); client++) {
		if( !IsValidClient(client) || rp_GetClientGroupID(client) == 0 )
			continue;
		
		
		int gID = rp_GetClientGroupID(client);
		int bonus = RoundToCeil(g_iCapture_POINT[gID] / 250.0);
		
		if( gID == rp_GetCaptureInt(cap_bunker) ) {
			amount = 10;
			rp_IncrementSuccess(client, success_list_pvpkill, 100);
			bonus += RoundToCeil(totalPoints-g_iCapture_POINT[gID] / 250.0);
		}
		else {
			amount = 1;
		}
		
		rp_ClientGiveItem(client, 309, amount + 3 + bonus, true);
		rp_GetItemData(309, item_type_name, tmp, sizeof(tmp));
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu %d %s, en récompense de la capture.", amount+3+bonus, tmp);
	}	
}
public Action CAPTURE_Tick(Handle timer, any none) {
	if( !g_bIsInCaptureMode )
		return Plugin_Handled;
	
	char strBuffer[4][32], tmp[64];
	int color[4], maxPoint, winner, defense = rp_GetCaptureInt(cap_bunker);
	float mins[3], maxs[3];
	mins[0] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_min_x);
	mins[1] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_min_y);
	mins[2] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_min_z);
	maxs[0] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_max_x);
	maxs[1] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_max_y);
	maxs[2] = rp_GetZoneFloat(ZONE_BUNKER, zone_type_max_z);
	
	for(int i=1; i<MAX_GROUPS; i++) {
		if( maxPoint > g_iCapture_POINT[i] )
			continue;

		winner = i;
		maxPoint = g_iCapture_POINT[i];
	}

	if( maxPoint-(FLAG_POINTS*4) >= g_iCapture_POINT[defense] && winner != defense ) {
		rp_GetGroupData(winner, group_type_name, tmp, sizeof(tmp));
		ExplodeString(tmp, " - ", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));
		CPrintToChatAll("{lightblue} ================================== {default}");
		CPrintToChatAll("{lightblue} Le bunker est maintenant défendu par les %s! {default}", strBuffer[1]);
		CPrintToChatAll("{lightblue} ================================== {default}");
		defense = winner;
		rp_SetCaptureInt(cap_bunker, defense);
		CAPTURE_UpdateLight();
	}
	
	rp_GetGroupData(defense, group_type_color, tmp, sizeof(tmp));
	ExplodeString(tmp, ",", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));
	color[0] = StringToInt(strBuffer[0]);
	color[1] = StringToInt(strBuffer[1]);
	color[2] = StringToInt(strBuffer[2]);
	color[3] = 255;
	
	Effect_DrawBeamBoxToAll(mins, maxs, g_cBeam, g_cBeam, 0, 30, 2.0, 5.0, 5.0, 2, 1.0, color, 0);
	
	CreateTimer(1.0, CAPTURE_Tick);
	return Plugin_Handled;
}
// -----------------------------------------------------------------------------------------------------------------
public Action fwdSpawn(int client) {
	Client_SetSpawnProtect(client, true);
	SetEntityHealth(client, 500);
	rp_SetClientInt(client, i_Kevlar, 250);
	rp_SetClientFloat(client, fl_CoolDown, 0.0);
	
	if( rp_GetClientGroupID(client) == rp_GetCaptureInt(cap_bunker) )
		CreateTimer(0.01, fwdSpawn_ToRespawn, client);
	
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
		rand[2] = mins[2] + 32.0;
		
		TeleportEntity(client, rand, NULL_VECTOR, NULL_VECTOR);
		FakeClientCommand(client, "sm_stuck");
	}
}
public Action fwdDead(int victim, int attacker, float& respawn) {
	if( g_iClientFlag[victim] > 0 ) {
		CTF_DropFlag(victim, false);
	}
	if( victim != attacker ) {
		int points = GDM_ELOKill(attacker, victim);
		PrintHintText(attacker, "<b>Kill !</b>\n <font color='#33ff33'>+%d</span> points !", points);
		rp_IncrementSuccess(attacker, success_list_killpvp2);
	}
	if( rp_GetClientGroupID(victim) == rp_GetCaptureInt(cap_bunker) )
		respawn = 0.25;
	return Plugin_Handled;
}
public Action fwdHUD(int client, char[] szHUD, const int size) {
	int gID = rp_GetClientGroupID(client);
	int defTeam = rp_GetCaptureInt(cap_bunker);
	char optionsBuff[4][32], tmp[128];
	
	if( g_bIsInCaptureMode && gID > 0 ) {
		
		Format(szHUD, size, "PvP: ");
		if( gID == defTeam )
			Format(szHUD, size, "%s Défense du Bunker\n", szHUD);
		else
			Format(szHUD, size, "%s Attaque du Bunker\n", szHUD);
			
		for(int i=1; i<MAX_GROUPS; i++) {
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
public Action fwdFrame(int client) {
	
	if( g_hGodTimer[client] != INVALID_HANDLE ) {
		PrintHintText(client, "Vous êtes en spawn-protection");
	}
	else if( rp_GetCaptureInt(cap_bunker) == rp_GetClientGroupID(client) ) {
		rp_ClientColorize(client, { 64, 64, 255, 255 } );
		PrintHintText(client, "Vous êtes en défense.\n     <font color='#ff3333'>Tuez les <b>ROUGES</b></font>");
	}
	else {
		rp_ClientColorize(client, { 255, 64, 64, 255 } );
		PrintHintText(client, "Vous êtes en attaque.\n     <font color='#3333ff'>Tuez les <b>BLEUS</b></font>");
	}
	
	
	
	int vehicle = Client_GetVehicle(client);
	if( rp_IsValidVehicle(vehicle) ) {
		if( rp_GetPlayerZone(vehicle) == ZONE_RESPAWN ) {
			rp_SetVehicleInt(vehicle, car_health, rp_GetVehicleInt(vehicle, car_health) - 100);
		}
	}
		
	return Plugin_Continue;
}
public Action fwdPhysics(int client, float& speed, float& gravity) {
	speed = (speed > 1.5 ? 1.5:speed);
	gravity = (gravity < 0.66 ? 0.66:gravity);
	return Plugin_Stop;
}
public Action Event_PlayerShoot(Handle event, char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	GDM_RegisterShoot(client);
	
	return Plugin_Continue;
}
public Action Event_PlayerHurt(Handle event, char[] name, bool dontBroadcast) {
	char weapon[64];
	int attacker, damage, hitgroup;
	
	attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	damage = GetEventInt(event, "dmg_health");	
	hitgroup = GetEventInt(event, "hitgroup");
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if( hitgroup > 0 )
		GDM_RegisterHit(attacker, damage, hitgroup);
	
	return Plugin_Continue;
}
public Action fwdTakeDamage(int victim, int attacker, float& damage, int wepID, float pos[3]) {
	if( rp_GetClientGroupID(victim) == rp_GetClientGroupID(attacker) )
		return Plugin_Handled;
	if( rp_GetClientGroupID(attacker) != rp_GetCaptureInt(cap_bunker) && rp_GetClientGroupID(victim) != rp_GetCaptureInt(cap_bunker) )
		return Plugin_Handled;
	if( rp_GetClientGroupID(victim) == 0 || rp_GetClientGroupID(attacker) == 0  )
		return Plugin_Handled;
	return Plugin_Continue;
}
public Action fwdZoneChange(int client, int newZone, int oldZone) {
	if( newZone == ZONE_RESPAWN &&  rp_GetCaptureInt(cap_bunker) != rp_GetClientGroupID(client) ) {
		rp_ClientDamage(client, 10000, client);
		ForcePlayerSuicide(client);
	}
	return Plugin_Continue;
}
// -----------------------------------------------------------------------------------------------------------------
public Action SwitchToFirst(Handle timer, any client) {
	if( rp_GetClientInt(client, i_ThirdPerson) == 0 )
		ClientCommand(client, "firstperson");
}
// -----------------------------------------------------------------------------------------------------------------
int CTF_SpawnFlag(float vecOrigin[3], int skin, int color[3]) {
	char szSkin[12], szColor[32];
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
	CreateTimer(0.01, CTF_SpawnFlag_Delay, ent2);
	
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
	
	int flag, color[3], gID, skin;
	float vecOrigin[3], vecAngles[3], vecPush[3];
	
	flag = g_iClientFlag[client];
	g_iClientFlag[client] = 0;
	g_fLastDrop[client] = GetGameTime();
	skin = g_iFlagData[flag][data_skin];
	color[0] = g_iFlagData[flag][data_red];
	color[1] = g_iFlagData[flag][data_green];
	color[2] = g_iFlagData[flag][data_blue];
	gID = g_iFlagData[flag][data_group];
	
	AcceptEntityInput(flag, "KillHierarchy");
	
	GetClientEyeAngles(client, vecAngles);
	GetClientEyePosition(client, vecOrigin);
	vecAngles[0] += 10.0;
	
	flag = CTF_SpawnFlag(vecOrigin, skin, color);
	g_iFlagData[flag][data_group] = gID;
	g_iFlagData[flag][data_lastOwner] = client;
	
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
	char szSteamID[32], tmp[65];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	GetClientName(client, tmp, sizeof(tmp));
	
	int array[gdm_max];
	
	if( !g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array)) ) {
		array[gdm_elo] = 1500;
		g_hGlobalDamage.SetArray(szSteamID, array, sizeof(array));
	}
	
	g_hGlobalSteamID.SetString(szSteamID, tmp, true);
}
void GDM_RegisterHit(int client, int damage=0, int hitbox=0) {
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	
	int array[gdm_max];
	g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array));
	array[gdm_touch]++;
	array[gdm_damage] += damage;
	array[gdm_hitbox] += (hitbox == 1 ? 1:0);
	
	g_hGlobalDamage.SetArray(szSteamID, array, sizeof(array));
}
void GDM_RegisterFlag(int client) {
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	
	int array[gdm_max];
	g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array));
	array[gdm_flag]++;
	g_hGlobalDamage.SetArray(szSteamID, array, sizeof(array));
}
void GDM_RegisterShoot(int client) {
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	
	int array[gdm_max];
	g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array));
	array[gdm_shot]++;
	g_hGlobalDamage.SetArray(szSteamID, array, sizeof(array));
}
int GDM_ELOKill(int client, int target) {
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
	
	attacker[gdm_elo] = cElo;
	victim[gdm_elo] = tElo;
	
	g_hGlobalDamage.SetArray(szSteamID, attacker, sizeof(attacker));
	g_hGlobalDamage.SetArray(szSteamID2, victim, sizeof(victim));
	
	return cElo;
}
void GDM_Resume() {
	StringMapSnapshot KeyList = g_hGlobalDamage.Snapshot();
	int array[gdm_max], delta, nbrParticipant = KeyList.Length;
	char szSteamID[32], tmp[64], key[64], name[64];
	
	if( g_hStatsMenu != INVALID_HANDLE )
		delete g_hStatsMenu;
	g_hStatsMenu = new TopMenu (MenuPvPResume);
	g_hStatsMenu.CacheTitles = true;
	
	g_hStatsMenu_Shoot = g_hStatsMenu.AddCategory("shoot", MenuPvPResume);
	g_hStatsMenu_Head = g_hStatsMenu.AddCategory("head", MenuPvPResume);
	g_hStatsMenu_Damage = g_hStatsMenu.AddCategory("damage", MenuPvPResume);
	g_hStatsMenu_Flag = g_hStatsMenu.AddCategory("flag", MenuPvPResume);
	g_hStatsMenu_ELO = g_hStatsMenu.AddCategory("elo", MenuPvPResume);
	
	for (int i = 0; i < nbrParticipant; i++) {
		KeyList.GetKey(i, szSteamID, sizeof(szSteamID));
		g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array));
		g_hGlobalSteamID.GetString(szSteamID, name, sizeof(name));
		
		if( array[gdm_touch] != 0 && array[gdm_shot] != 0  ) {
			delta = RoundFloat(float(array[gdm_touch]) / float(array[gdm_shot]+1) * 1000.0);
			Format(key, sizeof(key), "s%06d_%s", 1000000-delta, szSteamID); 
			Format(tmp, sizeof(tmp), "%4.1f - %s", float(delta)/10.0, name);
			g_hStatsMenu.AddItem(key, MenuPvPResume, g_hStatsMenu_Shoot, "", 0, tmp);
			
			delta = RoundFloat(float(array[gdm_hitbox]) / float(array[gdm_touch]+1) * 1000.0);
			Format(key, sizeof(key), "h%06d_%s", 1000000 - delta, szSteamID); 
			Format(tmp, sizeof(tmp), "%4.1f - %s", float(delta)/10.0, name);
			g_hStatsMenu.AddItem(key, MenuPvPResume, g_hStatsMenu_Head, "", 0, tmp);
			
			delta = array[gdm_elo];
			Format(key, sizeof(key), "e%06d_%s", 1000000 - delta, szSteamID); 
			Format(tmp, sizeof(tmp), "%6d - %s", delta, name);
			g_hStatsMenu.AddItem(key, MenuPvPResume, g_hStatsMenu_ELO, "", 0, tmp);
		}
		if( array[gdm_touch] != 0 ) {
			delta = array[gdm_damage];
			Format(key, sizeof(key), "d%06d_%s", 1000000 - delta, szSteamID); 
			Format(tmp, sizeof(tmp), "%6d - %s", delta, name);
			g_hStatsMenu.AddItem(key, MenuPvPResume, g_hStatsMenu_Damage, "", 0, tmp);
			
		}		
		if( array[gdm_flag] != 0 ) {
			delta = array[gdm_flag];
			Format(key, sizeof(key), "f%06d_%s", 1000000 - delta, szSteamID); 
			Format(tmp, sizeof(tmp), "%6d - %s", delta, name);
			g_hStatsMenu.AddItem(key, MenuPvPResume, g_hStatsMenu_Flag, "", 0, tmp);
		}
		
		
	}
	
	for (int client = 1; client <= MaxClients; client++) {
		if( !IsValidClient(client) )
			continue;
		g_hStatsMenu.Display(client, TopMenuPosition_Start);
	}
}
// -----------------------------------------------------------------------------------------------------------------
void Client_SetSpawnProtect(int client, bool status) {
	if( status == true ) {
		rp_HookEvent(client, RP_OnPlayerDead, fwdGodPlayerDead);
		SDKHook(client, SDKHook_SetTransmit, fwdGodHideMe);
		g_hGodTimer[client] = CreateTimer(10.0, GOD_Expire, client);
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		SDKHook(client, SDKHook_SetTransmit, fwdGodHideMe);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez 10 secondes de spawn-protection.");
		
		int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( wep > 0 && IsValidEdict(wep) && IsValidEntity(wep) ) {
			SetEntPropFloat(wep, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 10.0);
			SetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 10.0);
		}
	}
	else {
		rp_UnhookEvent(client, RP_OnPlayerDead, fwdGodPlayerDead);
		SDKUnhook(client, SDKHook_SetTransmit, fwdGodHideMe);
		if( g_hGodTimer[client] != INVALID_HANDLE )
			delete g_hGodTimer[client];
		g_hGodTimer[client] = INVALID_HANDLE; 
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre spawn-protection a expirée.");
		
		int wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( wep > 0 && IsValidEdict(wep) && IsValidEntity(wep) ) {
			SetEntPropFloat(wep, Prop_Send, "m_flNextPrimaryAttack", GetGameTime());
			SetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack", GetGameTime());
		}
	}
}
public Action fwdGodHideMe(int client, int target) {
	if( client != target )
		return Plugin_Handled;
	return Plugin_Continue;
}
public Action fwdGodHide2(int client, int target) {
	if( g_hGodTimer[target] != INVALID_HANDLE && client != target )
		return Plugin_Handled;
	return Plugin_Continue;
}
public Action fwdGodPlayerDead(int client, int attacker, float& respawn) {
	Client_SetSpawnProtect(client, false);
}
public Action fwdGod_PlayerHurt(Handle event, char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(  g_hGodTimer[attacker] != INVALID_HANDLE ) {
		Client_SetSpawnProtect(attacker, false);
	}
}
public Action fwdGod_PlayerShoot(Handle event, char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(  g_hGodTimer[client] != INVALID_HANDLE ) {
		Client_SetSpawnProtect(client, false);
	}
	return Plugin_Continue;
}
public Action GOD_Expire(Handle timer, any client) {
	if( g_hGodTimer[client] != INVALID_HANDLE )
		Client_SetSpawnProtect(client, false);
}
// -----------------------------------------------------------------------------------------------------------------
public void MenuPvPResume(Handle topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength) {
	if (action == TopMenuAction_DisplayTitle || action == TopMenuAction_DisplayOption) {
		if( topobj_id == INVALID_TOPMENUOBJECT ) 
			Format(buffer, maxlength, "Statistiques PvP:");
		else if( topobj_id == g_hStatsMenu_Shoot )
			Format(buffer, maxlength, "Meilleur précisions de tir");
		else if( topobj_id == g_hStatsMenu_Head )
			Format(buffer, maxlength, "Le plus de tir dans la tête");
		else if( topobj_id == g_hStatsMenu_Damage )
			Format(buffer, maxlength, "Le plus de dégâts");
		else if( topobj_id == g_hStatsMenu_Flag )
			Format(buffer, maxlength, "Le plus de drapeaux posés");
		else if( topobj_id == g_hStatsMenu_ELO )
			Format(buffer, maxlength, "Le meilleur en PvP");
		else 
			GetTopMenuInfoString(topmenu, topobj_id, buffer, maxlength);
	}
	else if (action == TopMenuAction_SelectOption) {
		g_hStatsMenu.Display(param, TopMenuPosition_Start);
	}
}
