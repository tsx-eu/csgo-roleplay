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
#include <basecomm>
#include <topmenus>
#include <smlib>		// https://github.com/bcserv/smlib
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MAX_GROUPS		150
#define MAX_ZONES		310
#define	MAX_ENTITIES	2048
#define	ZONE_BUNKER		235
#define ZONE_RESPAWN	231
#define ZONE_VILLA		286
#define	FLAG_SPEED		280.0
#define	FLAG_POINT_MAX	150
#define FLAG_MAX		10
#define FLAG_POINT_MIN	50
#define ELO_FACTEUR_K	40.0
#define MAX_ANNOUNCES	32
#define ANNONCES_DELAY	12
#define	ANNONCES_VOLUME 0.33
// -----------------------------------------------------------------------------------------------------------------
enum flag_data { data_group, data_skin, data_red, data_green, data_blue, data_time, data_owner, data_lastOwner, flag_data_max };
int g_iClientFlag[65];
float g_fLastDrop[65], g_flClientLastScore[65];
int g_iFlagData[MAX_ENTITIES+1][flag_data_max];
// -----------------------------------------------------------------------------------------------------------------
Handle g_hCapturable = INVALID_HANDLE;
Handle g_hGodTimer[65], g_hKillTimer[65];
int g_iCapture_POINT[MAX_GROUPS];
int g_iCaptureStart;
bool g_bIsInCaptureMode = false;
int g_cBeam;
int g_iLastGroup;
StringMap g_hGlobalDamage, g_hGlobalSteamID;
enum damage_data { gdm_shot, gdm_touch, gdm_damage, gdm_hitbox, gdm_elo, gdm_flag, gdm_kill, gdm_max };
TopMenu g_hStatsMenu;
TopMenuObject g_hStatsMenu_Shoot, g_hStatsMenu_Head, g_hStatsMenu_Damage, g_hStatsMenu_Flag, g_hStatsMenu_ELO, g_hStatsMenu_KILL;
// -----------------------------------------------------------------------------------------------------------------
enum soundList {
	snd_YouHaveTheFlag,
	snd_YouAreOnBlue, snd_YouAreOnRed,
	snd_1MinuteRemain, snd_5MinutesRemain,
	snd_EndOfRound,
	snd_Congratulations, snd_YouHaveLostTheMatch, snd_FlawlessVictory, snd_HumiliatingDefeat,
	snd_YouAreLeavingTheBattlefield,
	snd_FirstBlood,
	snd_DoubleKill, snd_MultiKill, snd_MegaKill, snd_UltraKill, snd_MonsterKill,
	snd_KillingSpree, snd_Unstopppable, snd_Dominating, snd_Godlike
};
enum announcerData {
	ann_Client,
	ann_SoundID,
	ann_Time,
	ann_max
};
char g_szSoundList[soundList][] = {
	"DeadlyDesire/announce/YouHaveTheFlag.mp3",
	"DeadlyDesire/announce/YouAreOnBlue.mp3",
	"DeadlyDesire/announce/YouAreOnRed.mp3",

	"DeadlyDesire/announce/1MinutesRemain.mp3",
	"DeadlyDesire/announce/5MinutesRemain.mp3",
	
	"DeadlyDesire/announce/EndOfRound.mp3",
	"DeadlyDesire/announce/Congratulations.mp3",
	"DeadlyDesire/announce/YouHaveLostTheMatch.mp3",
	"DeadlyDesire/announce/FlawlessVictory.mp3",
	"DeadlyDesire/announce/HumiliatingDefeat.mp3",
	
	"DeadlyDesire/announce/YouAreLeavingTheBattlefield.mp3",
	
	"DeadlyDesire/announce/FristBlood.mp3",
	
	"DeadlyDesire/announce/DoubleKill.mp3",
	"DeadlyDesire/announce/MultiKill.mp3",
	"DeadlyDesire/announce/MegaKill.mp3",
	"DeadlyDesire/announce/UltraKill.mp3",
	"DeadlyDesire/announce/MonsterKill.mp3",
	
	"DeadlyDesire/announce/KillingSpree.mp3",
	"DeadlyDesire/announce/Unstopppable.mp3",
	"DeadlyDesire/announce/Dominating.mp3",
	"DeadlyDesire/announce/Godlike.mp3"
};
int g_CyclAnnouncer[MAX_ANNOUNCES][announcerData], g_CyclAnnouncer_start, g_CyclAnnouncer_end;
int g_iKillingSpree[65], g_iKilling[65];
bool g_bStopSound[65];
bool g_bFirstBlood, g_b5MinutesLeft, g_b1MinuteLeft;
// -----------------------------------------------------------------------------------------------------------------
public Plugin myinfo = {
	name = "Utils: PvP", author = "KoSSoLaX",
	description = "RolePlay - Utils: PvP",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};
public void OnPluginStart() {
	RegConsoleCmd("drop", FlagDrop);
	RegServerCmd("rp_item_spawnflag", 	Cmd_ItemFlag,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_spawntag",	Cmd_SpawnTag,			"RP-ITEM",	FCVAR_UNREGISTERED);
	
	g_hGlobalDamage = new StringMap();
	g_hGlobalSteamID = new StringMap();
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
	
	char szDayOfWeek[12];
	FormatTime(szDayOfWeek, 11, "%w");
	if( StringToInt(szDayOfWeek) == 3 || StringToInt(szDayOfWeek) == 5 ) { // Mercredi & Vendredi
		ServerCommand("tv_enable 1");
	}
}
public void OnConfigsExecuted() {
	if( g_hCapturable == INVALID_HANDLE ) {
		g_hCapturable = FindConVar("rp_capture");
		HookConVarChange(g_hCapturable, OnCvarChange);
	}
	char szDayOfWeek[12];
	FormatTime(szDayOfWeek, 11, "%w");
	if( StringToInt(szDayOfWeek) == 3 || StringToInt(szDayOfWeek) == 5 ) { // Mercredi & Vendredi
		ServerCommand("tv_enable 1");
		ServerCommand("mp_restartgame 1");
		ServerCommand("spec_replay_enable 1");
		ServerCommand("tv_snapshotrate 64");
		ServerCommand("rp_wallhack 0");
	}
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	
	char tmp[PLATFORM_MAX_PATH];
	for (int i = 0; i < sizeof(g_szSoundList); i++) {
		PrecacheSoundAny(g_szSoundList[i]);
		Format(tmp, sizeof(tmp), "sound/%s", g_szSoundList[i]);
		AddFileToDownloadsTable(tmp);
	}
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
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
	g_bStopSound[client] = false;
	
	if( g_bIsInCaptureMode ) {
		GDM_Init(client);
		rp_HookEvent(client, RP_OnPlayerDead, fwdDead);
		rp_HookEvent(client, RP_OnPlayerHUD, fwdHUD);
		rp_HookEvent(client, RP_OnPlayerSpawn, fwdSpawn);
		rp_HookEvent(client, RP_OnFrameSeconde, fwdFrame);
		rp_HookEvent(client, RP_PreTakeDamage, fwdTakeDamage);
		rp_HookEvent(client, RP_OnPlayerZoneChange, fwdZoneChange);
	}
}
// -----------------------------------------------------------------------------------------------------------------
public Action Cmd_SpawnTag(int args) {
	static iPrecached[MAX_GROUPS];
	#if defined DEBUG
	PrintToServer("Cmd_SpawnTag");
	#endif
	
	char gang[64], path[128];	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int groupID = rp_GetClientGroupID(client);
	
	if( groupID == 0 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	rp_GetGroupData(groupID, group_type_tag, gang, sizeof(gang));
	
	Format(path, sizeof(path), "deadlydesire/groups/princeton/%s_small.vmt", gang);
	
	if( !IsDecalPrecached(path) || iPrecached[groupID] < 0 ) {
		iPrecached[groupID] = PrecacheDecal(path);
	}
	
	float origin[3], origin2[3], angles[3];
	GetClientEyeAngles(client, angles);
	GetClientEyePosition(client, origin);
	
	Handle tr = TR_TraceRayFilterEx(origin, angles, MASK_SOLID, RayType_Infinite, FilterToOne, client);
	if( tr && TR_DidHit(tr) ) {
		TR_GetEndPosition(origin2, tr);
		if( GetVectorDistance(origin, origin2) <= 128.0 ) {
			
			TE_Start("World Decal");
			TE_WriteVector("m_vecOrigin",origin2);
			TE_WriteNum("m_nIndex", iPrecached[groupID]);
			TE_SendToAll();
			
			rp_IncrementSuccess(client, success_list_graffiti);
		}
		else {
			ITEM_CANCEL(client, item_id);
		}
	}
	else {
		ITEM_CANCEL(client, item_id);
	}
	CloseHandle(tr);
	return Plugin_Handled;
}
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
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être en dehors du bunker.");
		return;
	}
	
	if( g_iClientFlag[client] > 0 && IsValidEdict(g_iClientFlag[client]) && IsValidEntity(g_iClientFlag[client]) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà un drapeau.");
		return;
	}
	
	if( GDM_GetFlagCount(client) >= FLAG_MAX ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà planté %d drapeaux.", FLAG_MAX);
		return;
	}
	
	char classname[64];
	int stackDrapeau[MAX_ENTITIES], stackCount;

	for(int i=MaxClients; i<MAX_ENTITIES; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( !StrEqual(classname, "ctf_flag") )
			continue;
		
		if( g_iFlagData[i][data_group] == gID ) {
			stackDrapeau[stackCount++] = i;
		}
	}
	if( stackCount >= 2 ) {
		bool can = false;
		for (int i = 0; i < stackCount; i++) {
			if( IsValidClient(g_iFlagData[ stackDrapeau[i] ][data_owner]) )
				continue;
			AcceptEntityInput(stackDrapeau[i], "KillHierarchy");
			can = true;
			break;
		}
		
		if( !can ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il y a déjà 2 drapeaux pour votre équipe sur le terrain.");
			ITEM_CANCEL(client, item_id);
			return;
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
	
	float vecOrigin[3];
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
				int point = RoundFloat(FLAG_POINT_MAX - ((FLAG_POINT_MAX - FLAG_POINT_MIN) * float(GetTime() - g_iCaptureStart) / (30.0 * 60.0)));
				
				g_iCapture_POINT[g_iFlagData[entity][data_group]] += point;
				g_iCapture_POINT[rp_GetCaptureInt(cap_bunker)] -= point;
				
				GDM_RegisterFlag(g_iFlagData[entity][data_lastOwner]);
				
				PrintHintText(g_iFlagData[entity][data_lastOwner], "<b>Drapeau posé !</b>\n <font color='#33ff33'>+%d</span> points !", point);
				g_flClientLastScore[g_iFlagData[entity][data_lastOwner]] = GetGameTime();
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
	
	CreateTimer(0.25, FlagThink, data);
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
	
	
	g_iCaptureStart = GetTime();
	CAPTURE_UpdateLight();
	
	int wall = Entity_FindByName("job=201__-pvp_wall", "func_brush");
	if( wall > 0 )
		AcceptEntityInput(wall, "Disable");
	
	
	g_bIsInCaptureMode = true;
	int gID;
	bool botFound = false;
			
	for(int i=1; i<MAX_GROUPS; i++) {
		g_iCapture_POINT[i] = 0;
	}
	
	int rowPoint = 100 - ((rp_GetCaptureInt(cap_pvpRow) - 1) * 10);
	if( rowPoint < 0 )
		rowPoint = 0;
	
	g_iLastGroup = rp_GetCaptureInt(cap_bunker);
	g_bFirstBlood = g_b5MinutesLeft = g_b1MinuteLeft = false;

	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		if( IsClientSourceTV(i) ) {
			botFound = true;
			continue;
		}
		
		GDM_Init(i);
		rp_HookEvent(i, RP_OnPlayerDead, fwdDead);
		rp_HookEvent(i, RP_OnPlayerHUD, fwdHUD);
		rp_HookEvent(i, RP_OnPlayerSpawn, fwdSpawn);
		rp_HookEvent(i, RP_OnFrameSeconde, fwdFrame);
		rp_HookEvent(i, RP_PreTakeDamage, fwdTakeDamage);
		rp_HookEvent(i, RP_OnPlayerZoneChange, fwdZoneChange);
		
		gID = rp_GetClientGroupID(i);
		g_iCapture_POINT[gID] += 100;
		if( gID == rp_GetCaptureInt(cap_bunker) ) {
			g_iCapture_POINT[gID] += rowPoint;
			EmitSoundToClientAny(i, g_szSoundList[snd_YouAreOnBlue], _, 6, _, _, 1.0);
		}
		else {
			EmitSoundToClientAny(i, g_szSoundList[snd_YouAreOnRed], _, 6, _, _, 1.0);
		}
		
		if( !(rp_GetZoneBit(rp_GetPlayerZone(i)) & BITZONE_PVP) )
			continue;
		if( gID == rp_GetCaptureInt(cap_bunker) )
			continue;
		
		int v = Client_GetVehicle(i);
		if( v > 0 )
			rp_ClientVehicleExit(i, v, true);
		
		rp_ClientSendToSpawn(i, true);
	}
	for(int i=MaxClients; i<=2048; i++) {
		if( rp_IsValidVehicle(i) && rp_GetVehicleInt(i, car_health) >= 2500 )
			rp_SetVehicleInt(i, car_health, 2500);
		if( IsValidEdict(i) && IsValidEntity(i) && rp_GetWeaponBallType(i) == ball_type_braquage ) {
			
			if( Weapon_GetOwner(i) > 0 )
				RemovePlayerItem(Weapon_GetOwner(i), i);
			AcceptEntityInput(i, "Kill");
		}
	}
	
	CreateTimer(1.0, CAPTURE_Tick);
	
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("weapon_fire", Event_PlayerShoot, EventHookMode_Post);
	HookEvent("player_hurt", fwdGod_PlayerHurt, EventHookMode_Pre);
	HookEvent("weapon_fire", fwdGod_PlayerShoot, EventHookMode_Pre);
	
	char szDayOfWeek[64];
	FormatTime(szDayOfWeek, sizeof(szDayOfWeek), "tv/pvp_%d-%m-%y");
	ServerCommand("tv_record %s", szDayOfWeek);
	ServerCommand("rp_wallhack 1");
	if( botFound ) {
//		CPrintToChatAll("{lightblue} Cette capture est enregistrée à cette adresse: https://www.ts-x.eu/tv/%s.dem", szDayOfWeek);
	}
	CPrintToChatAll("{lightblue} ================================== {default}");
}
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrEqual(command, "pvp") ) {
		if( g_hStatsMenu != INVALID_HANDLE )
			g_hStatsMenu.Display(client, TopMenuPosition_Start);
		return Plugin_Handled;
	}
	if( StrEqual(command, "stopsound") ) {
		g_bStopSound[client] = !g_bStopSound[client];
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
		rp_UnhookEvent(i, RP_OnFrameSeconde, fwdFrame);
		rp_UnhookEvent(i, RP_PreTakeDamage, fwdTakeDamage);
		rp_UnhookEvent(i, RP_OnPlayerZoneChange, fwdZoneChange);

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
	
	if( g_iLastGroup != winner ) {
		rp_SetCaptureInt(cap_pvpRow, 1);
	}
	else {
		rp_SetCaptureInt(cap_pvpRow, rp_GetCaptureInt(cap_pvpRow)+1);
	}
	
	char fmt[1024];
	Format(fmt, sizeof(fmt), "UPDATE `rp_servers` SET `bunkerCap`='%i', `capVilla`='%i', `pvpRow`='%i';", winner, winner, rp_GetCaptureInt(cap_pvpRow));
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
	
	ServerCommand("tv_stoprecord");
	ServerCommand("rp_wallhack 0");
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
	char tmp[128], szSteamID[32], optionsBuff[4][32];
	
	for(int i=1; i<MAX_GROUPS; i+=10) {
		rp_GetGroupData(i, group_type_name, tmp, sizeof(tmp));
		ExplodeString(tmp, " - ", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
		
		LogToGame("[CAPTURE] %s - %d", optionsBuff[1], g_iCapture_POINT[i]);
	}
	
	for(int client=1; client<=GetMaxClients(); client++) {
		if( !IsValidClient(client) || rp_GetClientGroupID(client) == 0 )
			continue;
		
		
		int gID = rp_GetClientGroupID(client);
		int bonus = RoundToCeil(g_iCapture_POINT[gID] / 200.0);
		
		GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
		int array[gdm_max];
		g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array));
		
		if( gID == rp_GetCaptureInt(cap_bunker) ) {
			amount = 10;
			rp_IncrementSuccess(client, success_list_pvpkill, 100);
			bonus += RoundToCeil((totalPoints-g_iCapture_POINT[gID]) / 200.0);
			
			if( array[gdm_elo] >= 1600 )
				EmitSoundToClientAny(client, g_szSoundList[snd_FlawlessVictory], _, 6, _, _, 1.0);
			else
				EmitSoundToClientAny(client, g_szSoundList[snd_Congratulations], _, 6, _, _, 1.0);
		}
		else {
			amount = 1;
			
			if( array[gdm_damage] >= 500 || array[gdm_flag] >= 1 || array[gdm_kill] >= 3 ) {
				EmitSoundToClientAny(client, g_szSoundList[snd_YouHaveLostTheMatch], _, 6, _, _, 1.0);
			}
			else {
				EmitSoundToClientAny(client, g_szSoundList[snd_HumiliatingDefeat], _, 6, _, _, 1.0);
			}
		}
		
		amount = RoundFloat( float(array[gdm_elo]) / 1500.0 * float(amount) );
		
		if( array[gdm_damage] >= 500 || array[gdm_flag] >= 1 || array[gdm_kill] >= 3 ) {
			rp_ClientGiveItem(client, 215, amount + 3 + bonus, true);
			rp_GetItemData(215, item_type_name, tmp, sizeof(tmp));
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu %d %s, en récompense de la capture.", amount+3+bonus, tmp);
		}
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
	
	for(int i=1; i<MAX_GROUPS; i+=10) {
		if( maxPoint > g_iCapture_POINT[i] )
			continue;

		winner = i;
		maxPoint = g_iCapture_POINT[i];
	}

	if( maxPoint-250 >= g_iCapture_POINT[defense] && winner != defense ) {
		rp_GetGroupData(winner, group_type_name, tmp, sizeof(tmp));
		ExplodeString(tmp, " - ", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));
		CPrintToChatAll("{lightblue} ================================== {default}");
		CPrintToChatAll("{lightblue} Le bunker est maintenant défendu par les %s! {default}", strBuffer[1]);
		CPrintToChatAll("{lightblue} ================================== {default}");
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( rp_GetClientGroupID(i) != defense ) {
				if( rp_GetClientGroupID(i) == winner )
					EmitSoundToClientAny(i, g_szSoundList[snd_YouAreOnBlue], _, 6, _, _, 1.0);
				continue;
			}
			
			EmitSoundToClientAny(i, g_szSoundList[snd_YouAreOnRed], _, 6, _, _, 1.0);
			if( rp_GetPlayerZone(i) != ZONE_RESPAWN )
				continue;
			rp_ClientSendToSpawn(i, true);
		}
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
	
	
	if( GetTime() % 3 == 0 ) {
		bool found = CyclAnnouncer_Empty();
		int NowTime = RoundToCeil(GetGameTime());
		int time, soundID, target;
		int timeLeft = g_iCaptureStart + (30 * 60) - GetTime();
	
		if( !g_b5MinutesLeft && timeLeft <= 5*60 ) {
			EmitSoundToAllAny(g_szSoundList[snd_5MinutesRemain], _, 6, _, _, 1.0);
			g_b5MinutesLeft = true;
		}
		if( !g_b1MinuteLeft && timeLeft <= 1*60 ) {
			EmitSoundToAllAny(g_szSoundList[snd_1MinuteRemain], _, 6, _, _, 1.0);
			g_b1MinuteLeft = true;
		}
		
		while( !found  ) {
			time = g_CyclAnnouncer[g_CyclAnnouncer_end][ann_Time];
			soundID = g_CyclAnnouncer[g_CyclAnnouncer_end][ann_SoundID];
			target = g_CyclAnnouncer[g_CyclAnnouncer_end][ann_Client];
			
			g_CyclAnnouncer_end = (g_CyclAnnouncer_end+1) % MAX_ANNOUNCES;
			
			if( (time+ANNONCES_DELAY) >= NowTime && IsValidClient(target) ) {
				announceSound(target, soundID);
				found = true;
			}
			else {
				found = CyclAnnouncer_Empty();
			}
		}
	}
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
		bool found = false;
		mins[0] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_min_x);
		mins[1] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_min_y);
		mins[2] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_min_z);
		maxs[0] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_max_x);
		maxs[1] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_max_y);
		maxs[2] = rp_GetZoneFloat(ZONE_RESPAWN, zone_type_max_z);
		
		for(int i=0; i<16; i++){
			
			rand[0] = Math_GetRandomFloat(mins[0] + 64.0, maxs[0] - 64.0);
			rand[1] = Math_GetRandomFloat(mins[1] + 64.0, maxs[1] - 64.0);
			rand[2] = Math_GetRandomFloat(mins[2] + 32.0, maxs[2] - 64.0);
			
			if( !CanTP(rand, client) )
				continue;
			
			found = true;
			break;
		}
		if( !found ) {
			mins[0] = rp_GetZoneFloat(ZONE_RESPAWN-1, zone_type_min_x);
			mins[1] = rp_GetZoneFloat(ZONE_RESPAWN-1, zone_type_min_y);
			mins[2] = rp_GetZoneFloat(ZONE_RESPAWN-1, zone_type_min_z);
			maxs[0] = rp_GetZoneFloat(ZONE_RESPAWN-1, zone_type_max_x);
			maxs[1] = rp_GetZoneFloat(ZONE_RESPAWN-1, zone_type_max_y);
			maxs[2] = rp_GetZoneFloat(ZONE_RESPAWN-1, zone_type_max_z);
			
			rand[0] = Math_GetRandomFloat(mins[0] + 64.0, maxs[0] - 64.0);
			rand[1] = Math_GetRandomFloat(mins[1] + 64.0, maxs[1] - 64.0);
			rand[2] = mins[2] + 32.0;
		}
		
		TeleportEntity(client, rand, NULL_VECTOR, NULL_VECTOR);
		FakeClientCommand(client, "sm_stuck");
	}
}
bool CanTP(float pos[3], int client) {
	static float mins[3], maxs[3];
	static bool init = false;
	bool ret;
	
	if( !init ) {
		GetClientMins(client, mins);
		GetClientMaxs(client, maxs);
		init = true;
	}
	
	Handle tr;
	tr = TR_TraceHullEx(pos, pos, mins, maxs, MASK_PLAYERSOLID);
	ret = !TR_DidHit(tr);
	CloseHandle(tr);
    #if defined DEBUG
		if( !ret ) {
			TR_GetEndPosition(maxs, tr);
			TE_SetupBeamRingPoint(maxs, 1.0, 1.5, g_cBeam, g_cBeam, 0, 30, 10.0, 1.0, 1.0, { 255, 255, 255, 255 }, 10, 0);
			TE_SendToAll();
		}
	#endif
	return ret;
}
public Action fwdDead(int victim, int attacker, float& respawn) {
	bool dropped = false;
	if( g_iClientFlag[victim] > 0 ) {
		CTF_DropFlag(victim, false);
		dropped = true;
	}
	
	g_iKillingSpree[victim] = 0;
	if( victim != attacker ) {
		GDM_RegisterKill(attacker);
		
		int points = GDM_ELOKill(attacker, victim);
		if( dropped )
			points += RoundFloat(float(points)*0.25);
			
		if( rp_GetCaptureInt(cap_bunker) == rp_GetClientGroupID(attacker) ) {
			g_iCapture_POINT[rp_GetClientGroupID(attacker)] += RoundFloat(float(points)*0.4);
			PrintHintText(attacker, "<b>Kill !</b>\n <font color='#33ff33'>+%d</span> points !", points+(points/2));
		}
		else {
			PrintHintText(attacker, "<b>Kill !</b>\n <font color='#33ff33'>+%d</span> points !", points);
		}
		g_flClientLastScore[attacker] = GetGameTime();
		rp_IncrementSuccess(attacker, success_list_killpvp2);
		
		if( g_bFirstBlood == false ) {
			g_bFirstBlood = true;
			CyclAnnouncer_Push(attacker, snd_FirstBlood);
		}
		g_iKillingSpree[attacker]++;
		g_iKilling[attacker]++;
		if( g_hKillTimer[attacker] != INVALID_HANDLE )
			delete g_hKillTimer[attacker];
		g_hKillTimer[attacker] = CreateTimer(10.0, ResetKillCount, attacker);
		CyclAnnouncer(attacker);
	}
	if( victim == attacker ) {
		GDM_ELOSuicide(victim);
	}
	
	if( rp_GetClientGroupID(victim) == rp_GetCaptureInt(cap_bunker) && rp_GetClientGroupID(victim) == g_iLastGroup ) {
		respawn = 1.0 + (rp_GetCaptureInt(cap_pvpRow)-1);
	}
	return Plugin_Handled;
}
public Action fwdHUD(int client, char[] szHUD, const int size) {
	int gID = rp_GetClientGroupID(client);
	static char optionsBuff[4][32], tmp[128], loading[64], cache[512];
	static float lastGen;
	
	if( g_bIsInCaptureMode && gID > 0 ) {
		if( lastGen > GetGameTime() ) {
			strcopy(szHUD, size, cache);
		}
		else {	
			int timeLeft = g_iCaptureStart + (30 * 60) - GetTime();
			
			if( timeLeft > 10 )
				rp_Effect_LoadingBar(loading, sizeof(loading), float(GetTime() - g_iCaptureStart) / (30.0 * 60.0));
			else
				Format(loading, sizeof(loading), "Il reste %d seconde%s", timeLeft, timeLeft >= 2 ? "s": "");
			
			Format(szHUD, size, "PvP: Capture du Bunker\n%s\n", loading);
				
			for(int i=1; i<MAX_GROUPS; i+=10) {
				if( g_iCapture_POINT[i] == 0 )
					continue;
				
				rp_GetGroupData(i, group_type_name, tmp, sizeof(tmp));
				ExplodeString(tmp, " - ", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
					
				Format(szHUD, size, "%s %s: %d\n", szHUD, optionsBuff[1], g_iCapture_POINT[i]);
			}
			
			lastGen = GetGameTime() + 0.66;
			strcopy(cache, sizeof(cache), szHUD);
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public Action fwdFrame(int client) {
	
	if( rp_GetClientGroupID(client) ) {
		
		if( rp_GetClientVehicle(client) <= 0 ) {
			ClientCommand(client, "firstperson");
			rp_SetClientInt(client, i_ThirdPerson, 0);
		}
		
		if( g_flClientLastScore[client]+3.0 > GetGameTime() ) {
			//
		}
		else if( g_hGodTimer[client] != INVALID_HANDLE ) {
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
	}
	else {
		PrintHintText(client, "Un event PVP est en cours.\n Vous n'y participez pas.");
	}
	
	int vehicle = Client_GetVehicle(client);
	if( rp_IsValidVehicle(vehicle) ) {
		if( rp_GetPlayerZone(vehicle) == ZONE_RESPAWN ) {
			rp_SetVehicleInt(vehicle, car_health, rp_GetVehicleInt(vehicle, car_health) - 100);
		}
	}
		
	return Plugin_Continue;
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
	if( !(rp_GetZoneBit(rp_GetPlayerZone(victim)) & BITZONE_PVP || rp_GetZoneBit(rp_GetPlayerZone(attacker)) & BITZONE_PVP) )
		return Plugin_Handled;
	
	return Plugin_Continue;
}
public Action fwdZoneChange(int client, int newZone, int oldZone) {
	if( newZone == ZONE_RESPAWN &&  rp_GetCaptureInt(cap_bunker) != rp_GetClientGroupID(client) ) {
		rp_ClientDamage(client, 10000, client);
		ForcePlayerSuicide(client);
	}
	if (rp_IsTutorialOver(client) == false && (rp_GetZoneBit(newZone) & BITZONE_PVP) ) {
		ForcePlayerSuicide(client);
	}
	if( newZone == ZONE_VILLA && !rp_GetClientKeyAppartement(client, 50) ) {
		rp_ClientSendToSpawn(client, true);
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
	SetEntProp(ent1, Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER);
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
	
	SDKHook(ent1, SDKHook_Touch, SDKTouch);
	
	CreateTimer(0.01, FlagThink, EntIndexToEntRef(ent1));
	
	return ent1;
}
public Action SDKTouch(int entity, int client) {
	if( !IsValidClient(client) )
		return Plugin_Continue;
	if( g_iClientFlag[client] > 0 )
		return Plugin_Continue;
	if( g_iFlagData[entity][data_group] != rp_GetClientGroupID(client) )
		return Plugin_Continue;
	CTF_FlagTouched(client, entity);
	return Plugin_Continue;
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
	if( GDM_GetFlagCount(client) >= FLAG_MAX ) {
		g_fLastDrop[client] = GetGameTime() + 10.0;
		return;
	}
	
	SDKUnhook(flag, SDKHook_Touch, SDKTouch);
	
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
	
	EmitSoundToClientAny(client, g_szSoundList[snd_YouHaveTheFlag], _, _, _, _, ANNONCES_VOLUME);
	
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
void GDM_RegisterKill(int client) {
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	
	int array[gdm_max];
	g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array));
	array[gdm_kill]++;
	g_hGlobalDamage.SetArray(szSteamID, array, sizeof(array));
}
int GDM_GetFlagCount(int client) {
	char szSteamID[32];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	
	int array[gdm_max];
	g_hGlobalDamage.GetArray(szSteamID, array, sizeof(array));
	return array[gdm_flag];
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
	
	int tmp = cElo - attacker[gdm_elo];
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
	
	return tmp;
}
int GDM_ELOSuicide(int client) {
	#if defined DEBUG
	PrintToServer("GDM_ELOSuicide");
	#endif
	
	char szSteamID[32];
	int attacker[gdm_max], cgID, cElo;
	float cDelta;
	
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	g_hGlobalDamage.GetArray(szSteamID, attacker, sizeof(attacker));
	
	cDelta = 1.0/((Pow(10.0, - (1500 - attacker[gdm_elo]) / 400.0)) + 1.0);
	cElo = RoundFloat(float(attacker[gdm_elo]) + ELO_FACTEUR_K * (0.0 - cDelta));
	cgID = rp_GetClientGroupID(client);
	
	int tmp = cElo - attacker[gdm_elo];
	g_iCapture_POINT[ cgID ] += cElo - attacker[gdm_elo];
	if( g_iCapture_POINT[ cgID ] < 0 ) {
		g_iCapture_POINT[ cgID ] = 0;
	}
	
	attacker[gdm_elo] = cElo;
	g_hGlobalDamage.SetArray(szSteamID, attacker, sizeof(attacker));
	
	return tmp;
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
	g_hStatsMenu_KILL = g_hStatsMenu.AddCategory("kill", MenuPvPResume);
	
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
		if( array[gdm_kill] != 0 ) {
			delta = array[gdm_kill];
			Format(key, sizeof(key), "f%06d_%s", 1000000 - delta, szSteamID); 
			Format(tmp, sizeof(tmp), "%6d - %s", delta, name);
			g_hStatsMenu.AddItem(key, MenuPvPResume, g_hStatsMenu_KILL, "", 0, tmp);
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
		SDKHook(client, SDKHook_PreThink, fwdGodThink);
		float duration = 10.0;
		if( rp_GetCaptureInt(cap_bunker) == rp_GetClientGroupID(client) )
			duration = 15.0;
		if( g_hGodTimer[client] != INVALID_HANDLE )
			delete g_hGodTimer[client];
		g_hGodTimer[client] = CreateTimer(duration, GOD_Expire, client);
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez %d secondes de spawn-protection.", RoundFloat(duration));
	}
	else {
		rp_UnhookEvent(client, RP_OnPlayerDead, fwdGodPlayerDead);
		SDKUnhook(client, SDKHook_SetTransmit, fwdGodHideMe);
		SDKUnhook(client, SDKHook_PreThink, fwdGodThink);
		if( g_hGodTimer[client] != INVALID_HANDLE )
			delete g_hGodTimer[client];
		g_hGodTimer[client] = INVALID_HANDLE; 
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre spawn-protection a expirée.");
		
		if( rp_GetCaptureInt(cap_bunker) == rp_GetClientGroupID(client) )
			rp_ClientColorize(client, { 64, 64, 255, 255 } );
		else if( rp_GetClientGroupID(client) != 0 )
			rp_ClientColorize(client, { 255, 64, 64, 255 } );
		else
			rp_ClientColorize(client);
	}
}
public Action fwdGodThink(int client) {
	int wep = Client_GetWeapon(client, "weapon_knife");
	if( wep > 0 && IsValidEdict(wep) && IsValidEntity(wep) ) {
		SetEntPropFloat(wep, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.25);
		SetEntPropFloat(wep, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 0.25);
	}
}
public Action fwdGodHideMe(int client, int target) {
	if( client != target )
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
	g_hGodTimer[client] = INVALID_HANDLE;
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
		else if( topobj_id == g_hStatsMenu_KILL )
			Format(buffer, maxlength, "Le plus de meurtre");
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
// -----------------------------------------------------------------------------------------------------------------
void announceSound(int client, int sound) {
	int clients[65], clientCount = 0;
	char msg[128];
	
	switch( sound ) {
		case snd_FirstBlood: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>a versé le premier sang !</b></font>", client);
		case snd_DoubleKill: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>   Double kill</b></font>", client);
		case snd_MultiKill: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>   MULTI kill</b></font>", client);
		case snd_MegaKill: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>   MEGA KILL</b></font>", client);
		case snd_UltraKill: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>   ULTRAAA-KILL !</b></font>", client);
		case snd_MonsterKill: Format(msg, sizeof(msg), 	"%N\n<font color='#33ff33'><b>MOOOONSTER KILL !</b></font>", client);
		case snd_KillingSpree: Format(msg, sizeof(msg),	"%N\n<font color='#33ff33'><b>fait une série meurtrière</b></font>", client);
		case snd_Unstopppable: Format(msg, sizeof(msg),	"%N\n<font color='#33ff33'><b> est inarrêtable!</b></font>", client);
		case snd_Dominating: Format(msg, sizeof(msg),	"%N\n<font color='#33ff33'><b>   DOMINE !</b></font>", client);
		case snd_Godlike: Format(msg, sizeof(msg),		"%N\n<font color='#33ff33'><b> EST DIVIN !</b></font>", client);
	}
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetClientGroupID(i) <= 0 )
			continue;
		
		g_flClientLastScore[i] = GetGameTime();
		PrintHintText(i, msg);
		
		if( !g_bStopSound[client] )
			clients[clientCount++] = i;
	}
	EmitSoundAny(clients, clientCount, g_szSoundList[sound], _, _, _, _, ANNONCES_VOLUME);
}
void CyclAnnouncer(int client) {
	bool sound = false;
	
	switch( g_iKilling[client] ) {
		case 2: sound = CyclAnnouncer_Push(client, snd_DoubleKill);
		case 3: sound = CyclAnnouncer_Push(client, snd_MultiKill);
		case 4: sound = CyclAnnouncer_Push(client, snd_MegaKill);
		case 5: sound = CyclAnnouncer_Push(client, snd_UltraKill);
		case 6: sound = CyclAnnouncer_Push(client, snd_MonsterKill);
		default: {
			if( g_iKilling[client] >= 6 && g_iKilling[client] % 2)
				sound = CyclAnnouncer_Push(client, snd_MonsterKill);
		}
	}
	
	if( !sound ) {
		switch( g_iKillingSpree[client] ) {
			case 4: sound = CyclAnnouncer_Push(client, snd_KillingSpree);
			case 6: sound = CyclAnnouncer_Push(client, snd_Dominating);
			case 8: sound = CyclAnnouncer_Push(client, snd_Unstopppable);
			case 10: sound = CyclAnnouncer_Push(client, snd_Godlike);
			default: {
				if( g_iKillingSpree[client] >= 12 && g_iKillingSpree[client] % 2 )
					sound = CyclAnnouncer_Push(client, snd_Godlike);
			}
		}
	}
}
bool CyclAnnouncer_Push(int client, int soundID) {
	
	if( !CyclAnnouncer_Empty() ) {
		int i = g_CyclAnnouncer_end;
		
		while( i != g_CyclAnnouncer_start ) {
			if( g_CyclAnnouncer[i][ann_Client] == client ) {
				g_CyclAnnouncer[i][ann_SoundID] = soundID;
				g_CyclAnnouncer[i][ann_Time] = RoundToCeil(GetGameTime());
				return true;
			}
			
			i = (i + 1) % MAX_ANNOUNCES;
		}
	}
	if( CyclAnnouncer_Full() )
		return false;
	
	g_CyclAnnouncer[g_CyclAnnouncer_start][ann_Client] = client;
	g_CyclAnnouncer[g_CyclAnnouncer_start][ann_SoundID] = soundID;
	g_CyclAnnouncer[g_CyclAnnouncer_start][ann_Time] = RoundToCeil(GetGameTime());
	
	g_CyclAnnouncer_start = (g_CyclAnnouncer_start+1) % MAX_ANNOUNCES;
	
	return true;
}
bool CyclAnnouncer_Full() {
	return ((g_CyclAnnouncer_end + 1) % MAX_ANNOUNCES == g_CyclAnnouncer_start);
}
bool CyclAnnouncer_Empty() {
	return (g_CyclAnnouncer_end == g_CyclAnnouncer_start);
}
public Action ResetKillCount(Handle timer, any client) {
	if( g_hKillTimer[client] != INVALID_HANDLE )
		g_iKilling[client] = 0;
	g_hKillTimer[client] = INVALID_HANDLE;
}