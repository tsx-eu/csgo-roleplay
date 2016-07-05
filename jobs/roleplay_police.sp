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
#include <sdkhooks>
#include <cstrike>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045
#include <csgo_items>   // https://forums.alliedmods.net/showthread.php?t=243009
#include <advanced_motd>// https://forums.alliedmods.net/showthread.php?t=232476
#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define ITEM_MANDAT			4
#define	ITEM_GPS			144

#define	MENU_TIME_DURATION	60
#define MAX_AREA_DIST		500
#define	MAX_LOCATIONS		150
#define	MAX_ZONES			300
#define MODEL_PRISONNIER	"models/player/custom_player/legacy/sprisioner/sprisioner.mdl"
#define MODEL_BARRIERE		"models/props_fortifications/police_barrier001_128_reference.mdl"


public Plugin myinfo = {
	name = "Jobs: Police", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Police",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

// TODO: Utiliser des TQuery pour le /perquiz.
// TODO: Trouver une manière plus propre que d'utiliser int g_iCancel[65];
// TODO: Améliorer le cache du JobToZoneID
// TODO: Les avocat dans la DB.

enum jail_raison_type {
	jail_raison = 0,
	jail_temps,
	jail_temps_nopay,
	jail_amende,
	
	jail_type_max
};
char g_szJailRaison[][][128] = {
	{ "Garde à vue",						"12", 	"12",	"0"},
	{ "Meurtre",							"-1", 	"-1",	"-1"},
	{ "Agression physique",					"1", 	"6",	"250"},
	{ "Intrusion propriété privée",			"0", 	"3",	"100"},
	{ "Vol, tentative de vol",				"0", 	"3",	"50"},
	{ "Fuite, refus d'obtempérer",			"0", 	"6",	"200"},
	{ "Insultes, Irrespect",				"1", 	"6",	"250"},
	{ "Trafique illégal",					"0", 	"6",	"100"},
	{ "Nuisance sonore",					"0", 	"6",	"100"},
	{ "Tir dans la rue",					"0", 	"6",	"100"},
	{ "Conduite dangereuse",				"0", 	"6",	"150"},
	{ "Mutinerie, évasion",					"-2", 	"-2",	"50"}	
};
int g_iCancel[65];
enum tribunal_type {
	tribunal_steamid = 0,
	tribunal_duration,
	tribunal_code,
	tribunal_option,
	tribunal_uniqID,
	
	tribunal_max
}
enum tribunal_search_data {
	tribunal_search_status = 0,
	tribunal_search_where,
	tribunal_search_starttime,
	
	tribunal_search_max
}

int g_TribunalSearch[MAXPLAYERS+1][tribunal_search_max];
char g_szTribunal_DATA[65][tribunal_max][64];
DataPack g_hBuyMenu;

//forward RP_OnClientTazedItem(int attacker, int reward);
Handle g_hForward_RP_OnClientTazedItem, g_hForward_RP_OnClientSendJail, g_hForward_RP_OnMarchePolice;
bool doRP_OnClientSendJail(int client, int target) {
	Action a;
	Call_StartForward(g_hForward_RP_OnClientSendJail);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_Finish(a);
	if( a == Plugin_Handled || a == Plugin_Stop )
		return false;
	return true;
}
void doRP_OnClientTazedItem(int client, int reward) {
	Call_StartForward(g_hForward_RP_OnClientTazedItem);
	Call_PushCell(client);
	Call_PushCell(reward);
	Call_Finish();
}
void doRP_RP_OnMarchePolice(int client, int prix, int realPrice) {
	
	Call_StartForward(g_hForward_RP_OnMarchePolice);
	Call_PushCell(client);
	Call_PushCell(prix);
	Call_PushCell(realPrice);
	Call_Finish();
}

// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	RegConsoleCmd("sm_jugement",	Cmd_Jugement);
	
	RegServerCmd("rp_item_mandat", 		Cmd_ItemPickLock,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_ratio",		Cmd_ItemRatio,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_SendToJail",		Cmd_SendToJail,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_GetStoreWeapon",	Cmd_GetStoreWeapon,		"RP-ITEM",	FCVAR_UNREGISTERED);
	

	HookEvent("bullet_impact", Event_Bullet_Impact);
	HookEvent("weapon_fire", Event_Weapon_Fire);

	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnAllPluginsLoaded() {
	g_hBuyMenu = rp_WeaponMenu_Create();
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_hForward_RP_OnClientTazedItem = CreateGlobalForward("RP_OnClientTazedItem", ET_Event, Param_Cell, Param_Cell);
	g_hForward_RP_OnClientSendJail = CreateGlobalForward("RP_OnClientSendJail", ET_Event, Param_Cell, Param_Cell);
	g_hForward_RP_OnMarchePolice = CreateGlobalForward("RP_OnMarchePolice", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	
}
public void OnPluginEnd() {
	if( g_hBuyMenu )
		rp_WeaponMenu_Clear(g_hBuyMenu);
}
public Action Cmd_GetStoreWeapon(int args) {
	Cmd_BuyWeapon(GetCmdArgInt(1), true);
}
public Action Cmd_SendToJail(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_SendToJail");
	#endif
	SendPlayerToJail(GetCmdArgInt(1));
}
public void OnMapStart() {
	PrecacheModel(MODEL_PRISONNIER, true);
	PrecacheModel(MODEL_BARRIERE, true);
}
// ----------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	#if defined DEBUG
	PrintToServer("OnClientPostAdminCheck");
	#endif
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
	rp_HookEvent(client, RP_OnPlayerSpawn, fwdSpawn);
	rp_HookEvent(client, RP_OnPlayerBuild, fwdOnPlayerBuild);
	rp_HookEvent(client, RP_PreGiveDamage, fwdDmg);
	rp_HookEvent(client, RP_OnPlayerZoneChange, fwdOnZoneChange);
	rp_HookEvent(client, RP_OnPlayerUse, fwdOnPlayerUse);
	rp_SetClientBool(client, b_IsSearchByTribunal, false);
	g_TribunalSearch[client][tribunal_search_status] = -1;
	
	CreateTimer(0.01, AllowStealing, client);
}
public Action fwdOnZoneChange(int client, int newZone, int oldZone) {
	
	if( rp_GetClientJobID(client) == 1 || rp_GetClientJobID(client) == 101 ) {
		int oldBIT = rp_GetZoneBit(oldZone);
		int newBIT = rp_GetZoneBit(newZone);
		
		if( GetClientTeam(client) == CS_TEAM_CT ) {
			if( (newBIT & BITZONE_PVP) && !(oldBIT & BITZONE_PVP) ) {
				EmitSoundToClientAny(client, "UI/arm_bomb.wav", client);
			}
			if( newBIT & BITZONE_EVENT ) {
				SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
			}
		}
		
	}
}
public Action fwdSpawn(int client) {
	#if defined DEBUG
	PrintToServer("fwdSpawn");
	#endif
	if( rp_GetClientInt(client, i_JailTime) > 0 )
		SendPlayerToJail(client, 0);

	if( GetClientTeam(client) == CS_TEAM_CT )
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	else
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);

	return Plugin_Continue;
}
public Action fwdCommand(int client, char[] command, char[] arg) {
	#if defined DEBUG
	PrintToServer("fwdCommand");
	#endif
	if( StrEqual(command, "cop") || StrEqual(command, "cops") ) {
		return Cmd_Cop(client);
	}
	else if( StrEqual(command, "vis") || StrEqual(command, "invis") ) {
		return Cmd_Vis(client);
	}
	else if( StrEqual(command, "tazer") || StrEqual(command, "tazeur") || StrEqual(command, "taser") ) {
		return Cmd_Tazer(client);
	}
	else if( StrEqual(command, "enjail") || StrEqual(command, "injail") || StrEqual(command, "jaillist") ) {
		return Cmd_InJail(client);
	}
	else if( StrEqual(command, "jail") || StrEqual(command, "prison") ) {
		return Cmd_Jail(client);
	}
	else if( StrEqual(command, "perquiz") || StrEqual(command, "perqui") ) {
		return Cmd_Perquiz(client);
	}
	else if( StrEqual(command, "tribunal") ) {
		return Cmd_Tribunal(client);
	}
	else if( StrEqual(command, "mandat") ) {
		return Cmd_Mandat(client);
	}
	else if( StrEqual(command, "push") ) {
		return Cmd_Push(client);
	}
	else if( StrEqual(command, "conv") ) {
		return Cmd_Conv(client);
	}
	else if( StrEqual(command, "amende") || StrEqual(command, "amande") ) {
		return Cmd_Amende(client, arg);
	}
	else if( StrEqual(command, "audience") || StrEqual(command, "audiance") ) {
		return Cmd_Audience(client);
	}
	else if( StrEqual(command, "avocat") || StrEqual(command, "avocat") ) {
		return Cmd_Avocat(client, arg);
	}
	
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action Cmd_Avocat(int client, const char[] arg) {
	FakeClientCommand(client, "say /job");
	return Plugin_Handled;
}
public Action Cmd_Amende(int client, const char[] arg) {
	#if defined DEBUG
	PrintToServer("Cmd_Amende");
	#endif
	int job = rp_GetClientInt(client, i_Job);
		
	if( job != 101 && job != 102 && job != 103 && job != 104 && job != 105 && job != 106 ) {
		ACCESS_DENIED(client);
	}
	
	if( !rp_GetClientBool(client, b_MaySteal) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible pour le moment.");
		return Plugin_Handled;
	}
	int target = rp_GetClientTarget(client);

	if( !IsValidClient(target) )
		return Plugin_Handled;

	if( !IsPlayerAlive(target) )
		return Plugin_Handled;
	
	if( rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) != 101 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être dans le tribunal pour utiliser cette commande.");
		return Plugin_Handled;
	}
		
	int amount = StringToInt(arg);

	if( amount <= 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas donner une amende de moins de 0$.");
		return Plugin_Handled;
	}
	if( amount > (rp_GetClientInt(target, i_Money)+rp_GetClientInt(target, i_Bank)) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur n'a pas assez d'argent.");
		return Plugin_Handled;
	}

	int maxAmount = 0;
	switch( job ) {
		case 101: maxAmount = 100000000;	// Président
		case 102: maxAmount = 250000;		// Vice Président
		case 103: maxAmount = 100000;		// Haut juge 2
		case 104: maxAmount = 100000;		// Haut juge 1
		case 105: maxAmount = 25000;		// Juge 2
		case 106: maxAmount = 10000;		// Juge 1

	}
	if( amount > maxAmount ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Amende trop élevée.");
		return Plugin_Handled;
	}

	rp_SetJobCapital(101, ( rp_GetJobCapital(101) + (amount/4)*3 ) );

	rp_SetClientStat(client, i_MoneyEarned_Sales, rp_GetClientStat(client, i_MoneyEarned_Sales) + (amount / 4));
	rp_SetClientStat(client, i_MoneySpent_Fines, rp_GetClientStat(client, i_MoneySpent_Fines) + amount);
	rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + (amount / 4));
	rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - amount);
	
	rp_SetClientInt(target, i_LastAmende, amount);
	rp_SetClientInt(target, i_LastAmendeBy, client);
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez pris une amende de %i$ à %N{default}.", amount, target);
	CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N {default} vous a prélevé %i$.", client, amount);

	char SteamID[64], szTarget[64];
		
	GetClientAuthId(client, AuthId_Engine, SteamID, sizeof(SteamID), false);
	GetClientAuthId(target, AuthId_Engine, szTarget, sizeof(szTarget), false);
		
	char szQuery[1024];
	Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
	SteamID, rp_GetClientJobID(client), GetTime(), 0, "Amande", amount/4);

	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);

	
	LogToGame("[TSX-RP] [AMENDE] %N (%s) a pris %i$ a %N (%s).", client, SteamID, amount, target, szTarget);
	rp_SetClientBool(client, b_MaySteal, false);
	
	CreateTimer(30.0, AllowStealing, client);
	return Plugin_Handled;
}
public Action Cmd_Cop(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Cop");
	#endif
	int job = rp_GetClientInt(client, i_Job);
		
	if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 ) {
		ACCESS_DENIED(client);
	}
	int zone = rp_GetPlayerZone(client);
	int bit = rp_GetZoneBit(zone);
		
	if( bit & (BITZONE_BLOCKJAIL|BITZONE_JAIL|BITZONE_HAUTESECU|BITZONE_LACOURS|BITZONE_PVP) ) { // Flic ripoux
		ACCESS_DENIED(client);
	}
	if( rp_GetClientVehiclePassager(client) > 0 || Client_GetVehicle(client) > 0 || rp_GetClientInt(client, i_Sickness) ) { // En voiture, ou très malade
		ACCESS_DENIED(client);
	}
	if( (job == 8 || job == 9) && rp_GetZoneInt(zone, zone_type_type) != 1 ) { // Gardien, policier dans le PDP
		ACCESS_DENIED(client);
	}
	if( (job == 108 || job == 109) && rp_GetZoneInt(zone, zone_type_type) != 1 && rp_GetZoneInt(zone, zone_type_type) != 101 ) { // GOS, Marshall, ONU dans Tribunal
		ACCESS_DENIED(client);
	}
	if( !rp_GetClientBool(client, b_MaySteal) || rp_GetClientBool(client, b_Stealing) ) { // Pendant un vol
		ACCESS_DENIED(client);
	}
	
	if(rp_GetClientInt(client, i_KillingSpread)>= 1 && GetClientTeam(client) == CS_TEAM_T) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez attendre, votre dernier meurtre était il y a moins de 6 minutes.");
		return Plugin_Handled;
	}
	
	float origin[3], vecAngles[3];
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, vecAngles);
	
	if( GetClientTeam(client) == CS_TEAM_CT ) {
		CS_SwitchTeam(client, CS_TEAM_T);
		SetEntityHealth(client, 100);
		Entity_SetMaxHealth(client, 200);
		rp_SetClientInt(client, i_Kevlar, 100);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
		FakeClientCommand(client, "say /shownote");
	}
	else if( GetClientTeam(client) == CS_TEAM_T ) {
		CS_SwitchTeam(client, CS_TEAM_CT);
		SetEntityHealth(client, 500);
		Entity_SetMaxHealth(client, 500);
		rp_SetClientInt(client, i_Kevlar, 250);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	}
		
	rp_ClientResetSkin(client);
	TeleportEntity(client, origin, vecAngles, NULL_VECTOR);
	rp_SetClientBool(client, b_MaySteal, false);
	CreateTimer(5.0, AllowStealing, client);
	return Plugin_Handled;
}
public Action Cmd_Vis(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Vis");
	#endif
	int job = rp_GetClientInt(client, i_Job);
		
	if( job != 1 && job != 2 && job != 4 && job != 5 && job != 6 ) { // Chef, co chef, gti, cia
		ACCESS_DENIED(client);
	}
	int zone = rp_GetPlayerZone(client);
	int bit = rp_GetZoneBit(zone);
		
	if( bit & (BITZONE_BLOCKJAIL|BITZONE_JAIL|BITZONE_HAUTESECU|BITZONE_LACOURS) ) { // Flic ripoux
		ACCESS_DENIED(client);
	}
	if( rp_GetClientVehiclePassager(client) > 0 || Client_GetVehicle(client) > 0 || rp_GetClientInt(client, i_Sickness) ) { // En voiture, ou très malade
		ACCESS_DENIED(client);
	}
	if( !rp_GetClientBool(client, b_MaySteal) || rp_GetClientBool(client, b_Stealing) ) { // Pendant un vol
		ACCESS_DENIED(client);
	}
	if (rp_IsInPVP(client) && GetClientTeam(client) != CS_TEAM_CT) { // Pas de vis si t'es en terro PVP
		ACCESS_DENIED(client);
	}
	
	if( !rp_GetClientBool(client, b_Invisible) ) {
		rp_ClientColorize(client, { 255, 255, 255, 0 } );
		rp_SetClientBool(client, b_Invisible, true);
		rp_SetClientBool(client, b_MaySteal, false);
		
		ClientCommand(client, "r_screenoverlay effects/hsv.vmt");
		
		if( job  == 6 ) {
			rp_SetClientFloat(client, fl_invisibleTime, GetGameTime() + 30.0);
			CreateTimer(120.0, AllowStealing, client);
		}
		else if ( job == 5 ) {
			rp_SetClientFloat(client, fl_invisibleTime, GetGameTime() + 60.0);
			CreateTimer(120.0, AllowStealing, client);
		}
		else if ( job == 4 ) {
			rp_SetClientFloat(client, fl_invisibleTime, GetGameTime() + 60.0);
			rp_SetClientBool(client, b_MaySteal, true);
		}
		else if (job == 1 ||  job== 2 ) {
			rp_SetClientFloat(client, fl_invisibleTime, GetGameTime() + 90.0);
			rp_SetClientBool(client, b_MaySteal, true);
		}
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes maintenant invisible.");
	}
	else {
		rp_ClientReveal(client);
	}
	return Plugin_Handled;
}
public Action Cmd_Tazer(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Tazer");
	#endif
	char tmp[128], tmp2[128], szQuery[1024];
	int job = rp_GetClientInt(client, i_Job);
	int Czone = rp_GetPlayerZone(client);
	
	if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 ) {
		ACCESS_DENIED(client);
	}
	if( rp_GetZoneBit(Czone) & (BITZONE_BLOCKJAIL|BITZONE_EVENT) ) {
		ACCESS_DENIED(client);
	}
	if( rp_GetClientVehiclePassager(client) > 0 || Client_GetVehicle(client) > 0 || rp_GetClientInt(client, i_Sickness) ) { // En voiture, ou très malade
		ACCESS_DENIED(client);
	}
	if( !rp_GetClientBool(client, b_MaySteal) ) {
		ACCESS_DENIED(client);
	}
	
	int target = rp_GetClientTarget(client);
	if( target <= 0 || !IsValidEdict(target) || !IsValidEntity(target) )
		return Plugin_Handled;

	if( GetEntityMoveType(target) == MOVETYPE_NOCLIP )
		return Plugin_Handled;
	
	int Tzone = rp_GetPlayerZone(target);
	
	if( IsValidClient(target) ) {
		// Joueur:
		if( GetClientTeam(client) == CS_TEAM_T && job != 1 && job != 2 && job != 4 && job != 5 && job != 101 && job != 102 ) {
			ACCESS_DENIED(client);
		}
		if( GetClientTeam(target) == CS_TEAM_CT ) {
			ACCESS_DENIED(client);
		}
		if( (job == 103 || job == 104 || job == 105 || job == 106) && (rp_GetZoneInt(Tzone, zone_type_type) != 101) ) { // J et HJ en dehors du tribu
			if( !(rp_GetZoneBit(target, -999.0) & BITZONE_PERQUIZ) ) { // Si perquiz en cours, on doit test le by-pass du cache.
				ACCESS_DENIED(client);
			}
		}
		if( rp_GetClientBool(target, b_Lube) && Math_GetRandomInt(1, 5) != 5) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N vous glisse entre les mains.", target);
			return Plugin_Handled;
		}
		
		if( !doRP_OnClientSendJail(client, target) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N vous glisse entre les mains.", target);
			return Plugin_Handled;
		}
		
		float time;
		rp_Effect_Tazer(client, target);
		rp_HookEvent(target, RP_PreHUDColorize, fwdTazerBlue, 9.0);
		rp_HookEvent(target, RP_PrePlayerPhysic, fwdFrozen, 7.5);
		
		rp_SetClientFloat(target, fl_TazerTime, GetTickedTime()+9.0);
		rp_SetClientFloat(target, fl_FrozenTime, GetGameTime()+7.5);
		
		FakeClientCommand(target, "use weapon_knife");
		FakeClientCommand(target, "use weapon_knifegg");
		

		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez été tazé par %N", client);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez tazé %N", target);
		LogToGame("[TSX-RP] [TAZER] %L a tazé %N dans %d.", client, target, rp_GetPlayerZone(target) );

		rp_SetClientBool(client, b_MaySteal, false);
		switch( job ) {
				case 1:		time = 0.001;
				case 101:	time = 0.001;
				case 2:		time = 0.5;
				case 102:	time = 0.5;
				case 4:		time = 4.0;
				case 5:		time = 6.0;
				case 6:		time = 7.0;
				case 7:		time = 8.0;
				case 107:	time = 8.0;
				case 8:		time = 9.0;
				case 108:	time = 9.0;
				case 9:		time = 10.0;
				case 109:	time = 10.0;
				
				default: time = 10.0;
		}
		CreateTimer(time, 	AllowStealing, client);
	}
	else {
		// Props:
		if( (job == 103 || job == 104 || job == 105 || job == 106) && !(rp_GetZoneBit(Czone) & BITZONE_PERQUIZ) ) {
			ACCESS_DENIED(client);
		}
		if( GetClientTeam(client) == CS_TEAM_T && job != 1 && job != 2 && job != 4 &&  job != 5 && job != 6 && job != 7 ) {
			ACCESS_DENIED(client);
		}
		int reward = -1;
		int owner = rp_GetBuildingData(target, BD_owner);
		if( !IsValidClient(owner) )
			owner = 0;
		
		GetEdictClassname(target, tmp2, sizeof(tmp2));
		
		if( owner != 0 && rp_IsMoveAble(target) && (Tzone == 0 || rp_GetZoneInt(Tzone, zone_type_type) <= 1	) ) {
			// PROPS
			rp_GetZoneData(Tzone, zone_type_name, tmp, sizeof(tmp));
			
			if( IsValidClient( owner ) ){
				CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Un de vos props vient d'être détruit.");
				LogToGame("[TSX-RP] [TAZER] %L a supprimé un props de %L dans %s", client, owner, tmp );
			}
			else{
				LogToGame("[TSX-RP] [TAZER] %L a supprimé un props dans %s", client, tmp );
			}
				
			
			reward = 0;
			if( rp_GetBuildingData(target, BD_started)+120 < GetTime() ) {
				Entity_GetModel(target, tmp, sizeof(tmp));
				if( StrContains(tmp, "popcan01a") == -1 ) {
					reward = 100;
				}
			}
		}
		else if ( StrContains(tmp2, "weapon_") == 0 && GetEntPropEnt(target, Prop_Send, "m_hOwnerEntity") == -1  && GetEntProp(target, Prop_Data, "m_spawnflags") != 1 ) {
			
			rp_GetZoneData(Tzone, zone_type_name, tmp, sizeof(tmp));
			LogToGame("[TSX-RP] [TAZER] %L a supprimé une arme %s dans %s", client, tmp2, tmp);
			
			if( canWeaponBeAddedInPoliceStore(target) )
				rp_WeaponMenu_Add(g_hBuyMenu, target, GetEntProp(target, Prop_Send, "m_OriginalOwnerXuidHigh"));
			int prix = rp_GetWeaponPrice(target); 
			
			reward = prix / 10;
				
			if( rp_GetWeaponBallType(target) != ball_type_none ) {
				reward += 150;
			}
		}
		else if ( StrEqual(tmp2, "rp_cashmachine") ) {
			
			rp_GetZoneData(Tzone, zone_type_name, tmp, sizeof(tmp));
			LogToGame("[TSX-RP] [TAZER] %L a supprimé une machine de %L dans %s", client, owner, tmp);
			
			reward = 25;
			if( rp_GetBuildingData(target, BD_started)+120 < GetTime() ) {
				reward = 100;
				if( owner != client )
					doRP_OnClientTazedItem(client, reward);
			}
			
			if( owner > 0 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez détruit la machine de %N", owner);
				CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Une de vos machines à faux-billets a été détruite par un agent de police.");
			}
			SDKHooks_TakeDamage(target, client, client, 1000.0);
		}
		else if ( StrEqual(tmp2, "rp_bigcashmachine") ) {
			
			rp_GetZoneData(Tzone, zone_type_name, tmp, sizeof(tmp));
			LogToGame("[TSX-RP] [TAZER] %L a supprimé une photocopieuse de %L dans %s", client, owner, tmp);
			
			reward = 25;
			if( rp_GetBuildingData(target, BD_started)+120 < GetTime() ) {
				reward = 1500;
				if( owner != client )
					doRP_OnClientTazedItem(client, reward);
			}
			
			if( owner > 0 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez détruit la photocopieuse de %N", owner);
				CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Votre photocopieuse a été détruite par un agent de police.");
			}
		}
		else if ( StrEqual(tmp2, "rp_plant") ) {
			
			rp_GetZoneData(Tzone, zone_type_name, tmp, sizeof(tmp));
			LogToGame("[TSX-RP] [TAZER] %L a supprimé un plant de %L dans %s", client, owner, tmp);
			
			reward = 100;
			if( (rp_GetBuildingData(target, BD_started)+120 < GetTime() && rp_GetBuildingData(target, BD_FromBuild) == 0) ||
				(rp_GetBuildingData(target, BD_started)+300 < GetTime() && rp_GetBuildingData(target, BD_FromBuild) == 1) ) {
				
				if( rp_GetBuildingData(target, BD_FromBuild) == 1 )
					reward += 50 * rp_GetBuildingData(target, BD_count);
				else
					reward += 200 * rp_GetBuildingData(target, BD_count);
				
				if( owner != client )
					doRP_OnClientTazedItem(client, reward);
			}
			
			if( owner > 0 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez détruit le plant de drogue de %N", owner);
				CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Un de vos plants de drogue a été détruit par un agent de police.");
			}
			
			if(owner == client)
				reward = 0;
		}
		else if( StrContains(tmp2, "rp_barriere") == 0){
			rp_GetZoneData(Tzone, zone_type_name, tmp, sizeof(tmp));
			LogToGame("[TSX-RP] [TAZER] %L a retiré une barrière de %L dans %s", client, owner, tmp);
			
			reward = 0;
			
			if( owner > 0 ) {
				if(client == owner)
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez retiré votre propre barrière.");
				else{
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez retiré la barrière de %N.", owner);
					CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Une de vos barrières a été retirée par un agent de police.");
				}
			}
		}
		if( reward >= 0 )  {
			
			rp_Effect_Tazer(client, target);
			rp_Effect_PropExplode(target, true);
			AcceptEntityInput(target, "Kill");
			
			rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + reward);
			rp_SetJobCapital(1, rp_GetJobCapital(1) + reward*2);
						
				
			GetClientAuthId(client, AuthId_Engine, tmp, sizeof(tmp), false);
			Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '3', '%i', '%s', '%i');",
			tmp, rp_GetClientJobID(client), GetTime(), 1, "TAZER", reward);

			SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		}
	}
	return Plugin_Handled;
}
public Action Cmd_InJail(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_InJail");
	#endif
	char tmp[256];
	
	int zone;
	
	Handle menu = CreateMenu(MenuNothing);
	SetMenuTitle(menu, "Liste des joueurs en prison:");
	
	for( int i=1;i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
			
		zone = rp_GetZoneBit(rp_GetPlayerZone(i));
		if( zone & (BITZONE_JAIL|BITZONE_LACOURS|BITZONE_HAUTESECU) ) {
			
			Format(tmp, sizeof(tmp), "%N  - %.1f heures", i, rp_GetClientInt(i, i_JailTime)/60.0 );
			AddMenuItem(menu, tmp, tmp,	ITEMDRAW_DISABLED);
		}
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
		
	return Plugin_Handled;
}
public Action Cmd_Jail(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Jail");
	#endif
	int job = rp_GetClientInt(client, i_Job);

	if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 ) {
		ACCESS_DENIED(client);
	}	
	if( GetClientTeam(client) == CS_TEAM_T && (job == 8 || job == 9 || job == 107 || job == 108 || job == 109 ) ) {
		ACCESS_DENIED(client);
	}
	
	float time = GetGameTime();
		
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) || IsPlayerAlive(i) )
			continue;
		if( rp_GetClientFloat(i, fl_RespawnTime) > time )
			continue;
		
		int ragdoll = GetEntPropEnt(i, Prop_Send, "m_hRagdoll");

		if( !IsValidEdict(ragdoll) || !IsValidEntity(ragdoll) )
			ragdoll = i;
		if( Entity_GetDistance(client, ragdoll) < MAX_AREA_DIST ) {
			CS_RespawnPlayer(i);
		}
	}
	
	int target = rp_GetClientTarget(client);

	if( IsValidClient(target) && rp_GetClientFloat(target, fl_Invincible) > GetGameTime() ) { //le target utilise une poupée gonflable
		ACCESS_DENIED(client);
	}
	if( rp_GetClientFloat(client, fl_Invincible) > GetGameTime() ) { //le flic utilise une poupée gonflable
		ACCESS_DENIED(client);
	}

	if( target <= 0 || !IsValidEdict(target) || !IsValidEntity(target) )
		return Plugin_Handled;

	int Czone = rp_GetPlayerZone(client);
	int Cbit = rp_GetZoneBit(Czone);
	
	int Tzone = rp_GetPlayerZone(target);
	int Tbit = rp_GetZoneBit(Tzone);
	
	if( Entity_GetDistance(client, target) > MAX_AREA_DIST*3 ) {
		ACCESS_DENIED(client);
	}
	
	if( Cbit & BITZONE_BLOCKJAIL || Tbit & BITZONE_BLOCKJAIL ) {
		ACCESS_DENIED(client);
	}
	
	if( (rp_GetZoneInt(Czone, zone_type_type) == 101) // On check si le CT est bien dans le tribunal
			&& (job == 101 || job == 102 || job == 103 || job == 104 || job == 105 || job == 106) ) {

		if (rp_GetZoneInt(Tzone, zone_type_type) != 101){ // On check si la cible est bien dans le tribunal (ticket #1029)
			ACCESS_DENIED(client);
		}

		if(job == 106 && GetClientTeam(target) == CS_TEAM_CT ){
			ACCESS_DENIED(client);
		}
		if( !IsValidClient(target) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser un joueur.");
			return Plugin_Handled;
		}

		int maxAmount = 0;
		switch( job ) {
			case 101: maxAmount = 1000;		// Président
			case 102: maxAmount = 300;		// Vice Président
			case 103: maxAmount = 100;		// Haut juge 2
			case 104: maxAmount = 100;		// Haut juge 1
			case 105: maxAmount = 36;		// Juge 2
			case 106: maxAmount = 24;		// Juge 1
		}

		// Setup menu
		Handle menu = CreateMenu(eventAskJail2Time);
		char tmp[256], tmp2[256];
		Format(tmp, 255, "Combien de temps doit rester %N?", target);
		SetMenuTitle(menu, tmp);

		Format(tmp, 255, "%i_-1", target);
		AddMenuItem(menu, tmp, "Prédéfinie");

		for(int i=6; i<=600; i += 6) {

			if( i > maxAmount )
				break;

			Format(tmp, 255, "%i_%i", target, i);
			Format(tmp2, 255, "%i Heures", i);

			AddMenuItem(menu, tmp, tmp2);
		}

		if(job == 104 || job == 103 || job == 101){
			Format(tmp, 255, "%i_%i", target, maxAmount);
			Format(tmp2, 255, "%i Heures", maxAmount);

			AddMenuItem(menu, tmp, tmp2);
		}

		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_DURATION);
			
		
		return Plugin_Handled;
	}
	else if( (job == 103 || job == 104 || job == 105 || job == 106) && (rp_GetZoneInt(Czone, zone_type_type) != 101 || rp_GetZoneInt(Czone, zone_type_type) != 1)) {
		ACCESS_DENIED(client);
	}

	if( rp_IsValidVehicle(target) ) {
		int client2 = GetEntPropEnt(target, Prop_Send, "m_hPlayer");
		
		if( !doRP_OnClientSendJail(client, client2) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N ne pas peut être mis en prison pour le moment à cause d'une quête.", client2);
			return Plugin_Handled;
		}
		if( IsValidClient(client2) ) {
			rp_ClientVehicleExit(client2, target, true);
			CPrintToChat(client2, "{lightblue}[TSX-RP]{default} %N vous a sorti de votre voiture.", client);
		}
		return Plugin_Handled;
	}
	else if( !IsValidClient(target) ) {
		return Plugin_Handled;
	}

	if ( Client_GetVehicle(target) > 0 ) {
		if( IsValidClient(target) ) {
			if( !doRP_OnClientSendJail(client, target) ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N ne pas peut être mis en prison pour le moment à cause d'une quête.", target);
				return Plugin_Handled;
			}
			rp_ClientVehicleExit(target, Client_GetVehicle(target), true);
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N vous a sorti de votre voiture.", client);
		}
		return Plugin_Handled;
	}
	
	if( GetClientTeam(target) == CS_TEAM_CT && !(job == 101 || job == 102 || job == 103 ) ) {
		ACCESS_DENIED(client);
	}
	
	if( !doRP_OnClientSendJail(client, target) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N ne pas peut être mis en prison pour le moment à cause d'une quête.", target);
		return Plugin_Handled;
	}
	
	if( rp_GetClientInt(target, i_JailTime) <= 60 )
		rp_SetClientInt(target, i_JailTime, 60);
	
	SendPlayerToJail(target, client);
	// g_iUserMission[target][mission_type] = -1; 
	
	return Plugin_Handled;
}
public Action Cmd_Perquiz(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Perquiz");
	#endif
	int job = rp_GetClientInt(client, i_Job);
	
	if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 ) {
		ACCESS_DENIED(client);
	}
	if( job == 8 || job == 9 || job == 109 || job == 108 ) {
		ACCESS_DENIED(client);
	}
	if( GetClientTeam(client) == CS_TEAM_T ) {
		ACCESS_DENIED(client);
	}
	
	if( rp_GetClientFloat(client, fl_CoolDown) > GetGameTime() ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez rien utiliser pour encore %.2f seconde(s).", (rp_GetClientFloat(client, fl_CoolDown)-GetGameTime()) );
		return Plugin_Handled;
	}

	rp_SetClientFloat(client, fl_CoolDown, GetGameTime() + 5.0);
	
	int job_id = 0;
	int zone = rp_GetPlayerZone( rp_GetClientTarget(client) );
	if( zone > 0 ) {
		job_id = rp_GetZoneInt(zone, zone_type_type);
	}
	if( job_id <= 0 || job_id > 250 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cette porte ne peut pas être perquisitionnée.");
		return Plugin_Handled;
	}

	if( job_id == 1 || job_id == 151 || job_id == 101 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cette porte ne peut pas être perquisitionnée.");
		return Plugin_Handled;
	}
	
	
	Handle menu = CreateMenu(MenuPerquiz);
	SetMenuTitle(menu, "Gestion des perquisitions");
	Handle DB = rp_GetDatabase();
	SQL_LockDatabase( DB ); // !!!!!!!!!!!
	char szQuery[1024];
	Format(szQuery, sizeof(szQuery), "SELECT `time` FROM  `rp_perquiz` WHERE `job`='%i' ORDER BY `id` DESC LIMIT 1;", job_id);
	Handle row = SQL_Query(DB, szQuery);
	if( row != INVALID_HANDLE ) {
		if( SQL_FetchRow(row) ) {
			char tmp[128];
			Format(tmp, sizeof(tmp), "Il y a %d minutes", (GetTime()-SQL_FetchInt(row, 0))/60 );
			AddMenuItem(menu, "", tmp,		ITEMDRAW_DISABLED);
		}
		else {
			AddMenuItem(menu, "", "Pas encore perqui",		ITEMDRAW_DISABLED);
		}
	}
	SQL_UnlockDatabase( DB );

	char szResp[128];
	Format(szResp, sizeof(szResp), "Responsable: %N", GetPerquizResp(job_id));

	AddMenuItem(menu, "", szResp,		ITEMDRAW_DISABLED);
	AddMenuItem(menu, "start",	"Debuter");
	AddMenuItem(menu, "cancel", "Annuler");
	AddMenuItem(menu, "stop",	"Terminer");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
	
	return Plugin_Handled;
}
public Action Cmd_Mandat(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Mandat");
	#endif
	int job = rp_GetClientInt(client, i_Job);
		
	if( job != 101 && job != 102 && job != 103 && job != 104 && job != 105 && job != 106 ) {
		ACCESS_DENIED(client);
	}
	int target = rp_GetClientTarget(client);
	if( target <= 0 || !IsValidEdict(target) || !IsValidEntity(target) )
		return Plugin_Handled;
	
	if( rp_GetClientJobID(target) != 1 && rp_GetClientJobID(target) != 101 ) {
		ACCESS_DENIED(client);
	}
	
	if(!IsValidClient(target)){	
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser un joueur.");
		return Plugin_Handled;
	}
	
	if( rp_GetClientItem(target, ITEM_MANDAT) < 10 ) {
		rp_ClientGiveItem(target, ITEM_MANDAT);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez donné un mandat à: %N", target);
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez reçu un mandat de: %N", client);
	}
	return Plugin_Handled;
}
public Action Cmd_Push(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Push");
	#endif
	int job = rp_GetClientInt(client, i_Job);
		
	if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 ) {
		ACCESS_DENIED(client);
	}
	int Czone = rp_GetPlayerZone(client);
	if( rp_GetZoneBit(Czone) & (BITZONE_BLOCKJAIL|BITZONE_EVENT) ) {
		ACCESS_DENIED(client);
	}

	if( GetClientTeam(client) == CS_TEAM_T && (job == 8 || job == 9 || job == 103 || job == 104 || job == 105 || job == 106 || job == 107 || job == 108 || job == 109 ) ) {
		ACCESS_DENIED(client);
	}
		
	int target = rp_GetClientTarget(client);
	if( target <= 0 || !IsValidEdict(target) || !IsValidEntity(target) )
		return Plugin_Handled;
	if(!IsValidClient(target)) {
		ACCESS_DENIED(client);
	}
	
	if( Entity_GetDistance(client, target) > MAX_AREA_DIST*3 ) {
		ACCESS_DENIED(client);
	}
	
	if( !rp_GetClientBool(client, b_MaySteal) ) {
		ACCESS_DENIED(client);
	}
	rp_SetClientBool(client, b_MaySteal, false);
	CreateTimer(7.5, AllowStealing, client);
	
	float cOrigin[3], tOrigin[3];
	GetClientAbsOrigin(client, cOrigin);
	GetClientAbsOrigin(target, tOrigin);

	cOrigin[2] -= 100.0;

	float f_Velocity[3];
	SubtractVectors(tOrigin, cOrigin, f_Velocity);
	NormalizeVector(f_Velocity, f_Velocity);
	ScaleVector(f_Velocity, 500.0);

	TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, f_Velocity);
	
	
	LogToGame("[TSX-RP] [TAZER] %L a tazé %N dans %d.", client, target, rp_GetPlayerZone(target) );
	
	return Plugin_Handled;
}
public Action Cmd_Audience(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Audience");
	#endif
	int job = rp_GetClientInt(client, i_Job);
		
	if( job != 101 && job != 102 && job != 103 && job != 104 && job != 105 && job != 106 ) {
		ACCESS_DENIED(client);
	}
	
	char tmp[2048], tmp2[128];
	rp_GetJobData(job, job_type_name, tmp2, sizeof(tmp2));
	Format(tmp, sizeof(tmp), "https://www.ts-x.eu/popup.php?url=https://docs.google.com/forms/d/1u4PFUsNBtVphggSyF3McU0gkA_o-6jEMSk0qmp0epFU/viewform?entry.249878658=%N%20-%20%s",
	client, tmp2);
		
		
	QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(ClientConVar), client);
	AdvMOTD_ShowMOTDPanel(client, "Role-Play: Audience", tmp, MOTDPANEL_TYPE_URL);
	return Plugin_Handled;
}
public void ClientConVar(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue) {
	#if defined DEBUG
	PrintToServer("ClientConVar");
	#endif
	if( StrEqual(cvarName, "cl_disablehtmlmotd", false) ) {
		if( StrEqual(cvarValue, "0") == false ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Des problèmes d'affichage ? Entrez cl_disablehtmlmotd 0 dans votre console puis relancez CS:GO.");
		}
	}
}
// ----------------------------------------------------------------------------
public Action Cmd_Jugement(int client, int args) {
	#if defined DEBUG
	PrintToServer("Cmd_Jugement");
	#endif
	int amende = 0;
	char arg1[12];

	if(StringToInt(g_szTribunal_DATA[client][tribunal_duration]) > 0){
		amende = GetCmdArgInt(1);
		GetCmdArg(2, arg1, sizeof(arg1));
	}
	else{
		GetCmdArg(1, arg1, sizeof(arg1));
	}
	
	int job = rp_GetClientInt(client, i_Job);
	char random[6];
	
	if( job != 101 && job != 102 && job != 103 && job != 104 ) {
		ACCESS_DENIED(client);
	}
	
	Handle DB = rp_GetDatabase();
	
	if( StrEqual(g_szTribunal_DATA[client][tribunal_code], arg1, false) ) {
		if( StrEqual(g_szTribunal_DATA[client][tribunal_option], "unknown") ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Erreur: Pas de jugement en cours.");
			return Plugin_Handled;
		}

		char SteamID[64], UserName[64];

		GetClientAuthId(client, AuthId_Engine, SteamID, sizeof(SteamID), false);
		GetClientName(client,UserName,63);

		char szReason[128], tmp[64];

		if(StringToInt(g_szTribunal_DATA[client][tribunal_duration]) > 0){
			for(int i=3; i<=args; i++) {
				GetCmdArg(i, tmp, sizeof(tmp));
				Format(szReason, sizeof(szReason), "%s%s ", szReason, tmp);
			}
		}
		else{
			for(int i=2; i<=args; i++) {
				GetCmdArg(i, tmp, sizeof(tmp));
				Format(szReason, sizeof(szReason), "%s%s ", szReason, tmp);
			}
		}

		char buffer_name[ sizeof(UserName)*2+1 ];
		SQL_EscapeString(DB, UserName, buffer_name, sizeof(buffer_name));
		
		char buffer_reason[ sizeof(szReason)*2+1 ];
		SQL_EscapeString(DB, szReason, buffer_reason, sizeof(buffer_reason));
		
		char szQuery[2048];
		if( StringToInt(g_szTribunal_DATA[client][tribunal_duration]) > 0 ) {

			if(amende >= 1){
				int maxAmount;
				switch( job ) {
					case 101: maxAmount = 1000000;		// Président
					case 102: maxAmount = 300000;		// Vice Président
					case 103: maxAmount = 100000;		// Haut juge 2
					case 104: maxAmount = 100000;		// Haut juge 1
				}

				if(amende > maxAmount){
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} L'amende excède le montant maximum autorisé.");
					String_GetRandom(random, sizeof(random), sizeof(random) - 1, "23456789abcdefg");

					Format(g_szTribunal_DATA[client][tribunal_code], 63, random);
					Format(g_szTribunal_DATA[client][tribunal_option], 63, "unknown");

					return Plugin_Handled;
				}
				int playermoney=-1;

				SQL_LockDatabase( DB );
				Format(szQuery, sizeof(szQuery), "SELECT (`money`+`bank`) FROM  `rp_users` WHERE `steamid`='%s';", g_szTribunal_DATA[client][tribunal_steamid]);
				Handle row = SQL_Query(DB, szQuery);
				if( row != INVALID_HANDLE ) {
					if( SQL_FetchRow(row) ) {
						playermoney=SQL_FetchInt(row, 0);
					}
				}
				SQL_UnlockDatabase( DB );

				if(playermoney == -1){
					PrintToServer("Erreur SQL: Impossible de relever l'argent du joueur (Amende jugement)");
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Erreur: Impossible de relever l'argent du joueur.", playermoney);
					String_GetRandom(random, sizeof(random), sizeof(random) - 1, "23456789abcdefg");

					Format(g_szTribunal_DATA[client][tribunal_code], 63, random);
					Format(g_szTribunal_DATA[client][tribunal_option], 63, "unknown");

					return Plugin_Handled;
				}
				else if(amende > playermoney){
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le joueur n'a que %i$, le jugement a été annulé.", playermoney);
					String_GetRandom(random, sizeof(random), sizeof(random) - 1, "23456789abcdefg");

					Format(g_szTribunal_DATA[client][tribunal_code], 63, random);
					Format(g_szTribunal_DATA[client][tribunal_option], 63, "unknown");

					return Plugin_Handled;
				}

				rp_SetJobCapital(101, rp_GetJobCapital(101) + (amende/4 * 3));
				rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + (amende / 4));
			}
			else{
				amende = 0;
			}


			Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_users2` (`id`, `steamid`, `jail`, `pseudo`, `steamid2`, `raison`, `money`) VALUES", szQuery);
			Format(szQuery, sizeof(szQuery), "%s (NULL, '%s', '%i', '%s', '%s', '%s', '-%i');", 
				szQuery,
				g_szTribunal_DATA[client][tribunal_steamid],
				StringToInt(g_szTribunal_DATA[client][tribunal_duration])*60,
				buffer_name,
				SteamID,
				buffer_reason,
				amende
			);

			SQL_TQuery(DB, SQL_QueryCallBack, szQuery);

			LogToGame("[TSX-RP] [TRIBUNAL-FORUM] le juge %L a condamné %s à faire %s heures de prison et à payer %i$ pour %s.",
				client,
				g_szTribunal_DATA[client][tribunal_steamid],
				g_szTribunal_DATA[client][tribunal_duration],
				amende,
				szReason
			);

			CPrintToChatAll("{lightblue}[TSX-RP]{default} Le juge %N a condamné %s à faire %s heures de prison et à payer %i$ pour %s.",
				client,
				g_szTribunal_DATA[client][tribunal_steamid],
				g_szTribunal_DATA[client][tribunal_duration],
				amende,
				szReason
			);
		}
		else{
			LogToGame("[TSX-RP] [TRIBUNAL-FORUM] le juge %L a acquitté %s pour %s.",
				client, g_szTribunal_DATA[client][tribunal_steamid], szReason);

			CPrintToChatAll("{lightblue}[TSX-RP]{default} Le juge %N a acquitté %s pour %s.",
				client, g_szTribunal_DATA[client][tribunal_steamid], szReason);
		}

		if( StrEqual(g_szTribunal_DATA[client][tribunal_option], "forum") ) {
			
			char reason[sizeof(szReason) * 2 + 1];
			SQL_EscapeString(rp_GetDatabase(), szReason, reason, sizeof(reason));
			
			Format(szQuery, sizeof(szQuery), "UPDATE `ts-x`.`site_report` SET `jail`='%s', `amende`='%d', `juge`='%s', `reason`='%s' WHERE `id`='%s';",
				g_szTribunal_DATA[client][tribunal_duration], amende, SteamID, reason, g_szTribunal_DATA[client][tribunal_uniqID]);
			SQL_TQuery(DB, SQL_QueryCallBack, szQuery);
		}
		
	}
	else{
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le code est incorrect, le jugement a été annulé.");
	}
	
	String_GetRandom(random, sizeof(random), sizeof(random) - 1, "23456789abcdefg");
	
	Format(g_szTribunal_DATA[client][tribunal_code], 63, random);
	Format(g_szTribunal_DATA[client][tribunal_option], 63, "unknown");
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action Cmd_Conv(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Conv");
	#endif
	int job = rp_GetClientInt(client, i_Job);
		
	if( rp_GetClientJobID(client) != 101 ) {
		ACCESS_DENIED(client);
	}
	if( job == 109 || job == 108 || job == 107 ) {
		ACCESS_DENIED(client);
	}

	// Setup menu
	Handle menu = CreateMenu(eventConvocation);
	SetMenuTitle(menu, "Liste des joueurs:");
	char tmp[24], tmp2[64];

	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;

		Format(tmp, sizeof(tmp), "%i", i);
		if(rp_IsClientNew(i))
			Format(tmp2, sizeof(tmp2), "[NEW] %N", i);
		else
			Format(tmp2, sizeof(tmp2), "%N", i);

		AddMenuItem(menu, tmp, tmp2);
	}

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);

	return Plugin_Handled;
}
public int eventConvocation(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventConvocation");
	#endif
	if( action == MenuAction_Select ) {
		char options[128];
		GetMenuItem(menu, param2, options, sizeof(options));
		int target = StringToInt(options);

		// Setup menu
		Handle menu2 = CreateMenu(eventConvocation_2);
		Format(options, sizeof(options), "Que faire pour %N", target);
		SetMenuTitle(menu2, options);
		if(g_TribunalSearch[target][tribunal_search_status] == -1){
			Format(options, sizeof(options), "%i_1", target);
			AddMenuItem(menu2, options, "Lancer la convocation");
			
			Format(options, sizeof(options), "%i_-1", target);
			AddMenuItem(menu2, options, "Anuler la convocation", ITEMDRAW_DISABLED);

			Format(options, sizeof(options), "%i_4", target);
			AddMenuItem(menu2, options, "Forcer la recherche");
		}
		else{
			Format(options, sizeof(options), "%i_1", target);
			AddMenuItem(menu2, options, "Lancer la convocation", ITEMDRAW_DISABLED);
			
			Format(options, sizeof(options), "%i_-1", target);
			AddMenuItem(menu2, options, "Anuler la convocation");

			Format(options, sizeof(options), "%i_4", target);
			AddMenuItem(menu2, options, "Forcer la recherche", ITEMDRAW_DISABLED);
		}
		
		SetMenuExitButton(menu2, true);
		DisplayMenu(menu2, client, 60);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public int eventConvocation_2(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventConvocation_2");
	#endif
	if( action == MenuAction_Select ) {

		char options[64], optionsBuff[2][64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		ExplodeString(options, "_", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
		
		int target = StringToInt(optionsBuff[0]);
		int etat = StringToInt(optionsBuff[1]);
		rp_GetZoneData(rp_GetPlayerZone(client), zone_type_name, options, sizeof(options));
		
		if( etat == -1 ) {
			PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
			PrintToChatPoliceSearch(target, "{lightblue}[TSX-RP] [TRIBUNAL]{default} %N {default}n'est plus recherché par le Tribunal.", target);
			PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
			g_TribunalSearch[target][tribunal_search_status] = -1;
			PrintToChatPoliceSearch(target, "{lightblue}[TSX-RP]{default} La recherche sur le joueur %N à durée %.1f minutes.", target, (GetTime()-g_TribunalSearch[target][tribunal_search_starttime])/60.0);
			LogToGame("[TSX-RP] [RECHERCHE] %L a mis fin à la convocation de %L.", client, target);
			rp_SetClientBool(target, b_IsSearchByTribunal, false);

		}
		else if( etat == 1 ) {
			g_TribunalSearch[target][tribunal_search_status] = 1;
			g_TribunalSearch[target][tribunal_search_starttime] = GetTime();
			g_TribunalSearch[target][tribunal_search_where] = FindCharInString(options,'1') != -1 ? 1 : 2;
			PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
			PrintToChatPoliceSearch(target, "{lightblue}[TSX-RP] [TRIBUNAL]{default} %N {default}est convoqué dans le Tribunal N°%i. [%i/3]", target, g_TribunalSearch[target][tribunal_search_where], etat);
			PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
			LogToGame("[TSX-RP] [RECHERCHE] %L convoqué %L au tribunal n°%i.", client, target, g_TribunalSearch[target][tribunal_search_where]);
			CreateTimer(30.0, Timer_ConvTribu, target, TIMER_REPEAT);
			rp_SetClientBool(target, b_IsSearchByTribunal, true);
		}
		else if( etat == 4 ) {
			g_TribunalSearch[target][tribunal_search_status] = 4;
			g_TribunalSearch[target][tribunal_search_starttime] = GetTime();
			g_TribunalSearch[target][tribunal_search_where] = FindCharInString(options,'1') != -1 ? 1 : 2;
			PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
			PrintToChatPoliceSearch(target, "{lightblue}[TSX-RP] [TRIBUNAL]{default} %N {default}est recherché par le Tribunal.", target);
			PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
			LogToGame("[TSX-RP] [RECHERCHE] %L a lancé une recherche sur %L", client, target);
			CreateTimer(60.0, Timer_ConvTribu, target, TIMER_REPEAT);
			rp_SetClientBool(target, b_IsSearchByTribunal, true);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public Action Timer_ConvTribu(Handle timer, any target) {
	if(!IsValidClient(target) || g_TribunalSearch[target][tribunal_search_status] == -1){
		return Plugin_Stop;
	}
	float vecOrigin[3];
	Entity_GetAbsOrigin(target, vecOrigin);
	if( GetVectorDistance(vecOrigin, view_as<float>({496.0, -1787.0, -1997.0})) < 64.0 || GetVectorDistance(vecOrigin, view_as<float>({-782.0, -476.0, -2000.0})) < 64.0 ){
		PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
		PrintToChatPoliceSearch(target, "{lightblue}[TSX-RP] [TRIBUNAL]{default} %N {default}n'est plus recherché par le Tribunal.", target);
		PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
		g_TribunalSearch[target][tribunal_search_status] = -1;
		LogToGame("[TSX-RP] [RECHERCHE] %L a été détecté comme présent au tribunal.", target);
		PrintToChatZone(rp_GetPlayerZone(target), "{lightblue}[TSX-RP]{default} La recherche sur le joueur %N a durée %.1f minutes.", target, (GetTime()-g_TribunalSearch[target][tribunal_search_starttime])/60.0);
		rp_SetClientBool(target, b_IsSearchByTribunal, false);
		return Plugin_Stop;
	}
	g_TribunalSearch[target][tribunal_search_status]++;
	if(g_TribunalSearch[target][tribunal_search_status] > 3){
		PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
		PrintToChatPoliceSearch(target, "{lightblue}[TSX-RP] [TRIBUNAL]{default} %N {default}est recherché par le Tribunal.", target);
		PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
	}
	else if(g_TribunalSearch[target][tribunal_search_status] == 4){
		PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
		PrintToChatPoliceSearch(target, "{lightblue}[TSX-RP] [TRIBUNAL]{default} %N {default}est convoqué dans le Tribunal N°%i. [%i/3]", target, g_TribunalSearch[target][tribunal_search_where], g_TribunalSearch[target][tribunal_search_status]);
		PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
		CreateTimer(60.0, Timer_ConvTribu, target, TIMER_REPEAT);
		return Plugin_Stop;
	}
	else{
		PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
		PrintToChatPoliceSearch(target, "{lightblue}[TSX-RP] [TRIBUNAL]{default} %N {default}est convoqué dans le Tribunal N°%i. [%i/3]", target, g_TribunalSearch[target][tribunal_search_where], g_TribunalSearch[target][tribunal_search_status]);
		PrintToChatPoliceSearch(target, "{lightblue} ================================== {default}");
	}
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action Cmd_Tribunal(int client) {
	#if defined DEBUG
	PrintToServer("Cmd_Tribunal");
	#endif
	int job = rp_GetClientInt(client, i_Job);
		
	if( job != 1 && job != 2 && job != 101 && job != 102 && job != 103 && job != 104 && job != 105 && job != 106 ) {
		ACCESS_DENIED(client);
	}
	if( rp_GetZoneInt( rp_GetPlayerZone(client), zone_type_type) != 101 ) {
		ACCESS_DENIED(client);
	}
	
	// Setup menu
	Handle menu = CreateMenu(MenuTribunal_main);

	SetMenuTitle(menu, "  Tribunal \n--------------------");

	if( job == 101 || job == 102 || job == 103 || job == 104 ) {
		if( GetConVarInt(FindConVar("hostport")) == 27015 )
			AddMenuItem(menu, "forum",		"Juger les cas du forum");
		else
			AddMenuItem(menu, "forum", "Juger les cas du forum", ITEMDRAW_DISABLED);
			
		AddMenuItem(menu, "connected",	"Juger un joueur présent");
		AddMenuItem(menu, "disconnect",	"Juger un joueur récemment déconnecté");
	}
	if( GetConVarInt(FindConVar("hostport")) == 27015 )
		AddMenuItem(menu, "stats",		"Voir les stats d'un joueur");
	else
		AddMenuItem(menu, "stats", 	"Voir les stats d'un joueur", ITEMDRAW_DISABLED);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);

	return Plugin_Handled;
}
public int MenuTribunal_main(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("MenuTribunal_main");
	#endif
	if( p_oAction == MenuAction_Select && client != 0) {
		char options[64];
		GetMenuItem(p_hItemMenu, p_iParam2, options, 63);
		
		Handle menu = CreateMenu(MenuTribunal_selectplayer);
		Handle DB = rp_GetDatabase();
		
		if( StrEqual( options, "forum", false) ) {
			
			SetMenuTitle(menu, "  Tribunal - Cas Forum \n--------------------");
			PrintToServer("LOCK-2");
			SQL_LockDatabase(DB);
			
			char szQuery[1024];
			Format(szQuery, sizeof(szQuery), "SELECT R.`id`, `report_steamid`, COUNT(`vote`) vote FROM `ts-x`.`site_report` R");
			Format(szQuery, sizeof(szQuery), "%s LEFT JOIN `ts-x`.`site_report_votes` V ON V.`reportid`=R.`id`", szQuery);
			Format(szQuery, sizeof(szQuery), "%s WHERE V.`vote`='1' AND R.`jail`=-1 GROUP BY R.`id` ORDER BY vote DESC;", szQuery);
			
			Handle hQuery = SQL_Query(DB, szQuery);
			
			if( hQuery != INVALID_HANDLE ) {
				while( SQL_FetchRow(hQuery) ) {
					
					char tmp[255], tmp2[255], szSteam[32];
					int id = SQL_FetchInt(hQuery, 0);
					SQL_FetchString(hQuery, 1, szSteam, sizeof(szSteam));
					int count=SQL_FetchInt(hQuery, 2);
					
					Format(tmp, sizeof(tmp), "%s %s %d", options, szSteam, id);
					
					Format(tmp2, sizeof(tmp2), "[%i] %s", count, szSteam);
					AddMenuItem(menu, tmp, tmp2);
				}
			}
			
			if( hQuery != INVALID_HANDLE )
				CloseHandle(hQuery);
			
			SQL_UnlockDatabase(DB);
			PrintToServer("UNLOCK-2");
		}
		else if( StrEqual( options, "connected", false) ) {
			
			SetMenuTitle(menu, "  Tribunal - Cas connecté \n--------------------");
			char tmp[255], tmp2[255], szSteam[32];
			
			for(int i = 1; i <= MaxClients; i++) {
				if( !IsValidClient(i) )
					continue;
				
				if( rp_GetZoneInt( rp_GetPlayerZone(i), zone_type_type) != 101 ) 
					continue;				
				
				GetClientAuthId(i, AuthId_Engine, szSteam, sizeof(szSteam), false);
				Format(tmp, sizeof(tmp), "%s %s %s", options, szSteam, szSteam);
				
				Format(tmp2, sizeof(tmp2), "%N - %s", i, szSteam);
				AddMenuItem(menu, tmp, tmp2);
			}
		}
		else if( StrEqual( options, "disconnect", false) ) {
			
			SetMenuTitle(menu, "  Tribunal - Cas déconnecté \n--------------------");
			PrintToServer("LOCK-3");
			SQL_LockDatabase(DB);
			Handle hQuery = SQL_Query(DB, "SELECT `steamid`, `name` FROM `rp_users` ORDER BY `rp_users`.`last_connected` DESC LIMIT 100;");
			char tmp[255], tmp2[255], szSteam[32], buffer_szSteam[32];
			
			if( hQuery != INVALID_HANDLE ) {
				while( SQL_FetchRow(hQuery) ) {
				
					SQL_FetchString(hQuery, 0, szSteam, sizeof(szSteam));
					SQL_FetchString(hQuery, 1, tmp2, sizeof(tmp2));
					
					bool found = false;
					for(int i = 1; i <= MaxClients; i++) {
						if( !IsValidClient(i) )
							continue;
						
						
						GetClientAuthId(i, AuthId_Engine, buffer_szSteam, sizeof(buffer_szSteam), false);
						
						if( StrEqual(szSteam, buffer_szSteam) ) {
							found = true;
							break;
						}
					}
					
					if( found )
						continue;
					
					Format(tmp, sizeof(tmp), "%s %s %s", options, szSteam, szSteam);
					Format(tmp2, sizeof(tmp2), "%s - %s", tmp2, szSteam);
					AddMenuItem(menu, tmp, tmp2);
				}
			}
			
			if( hQuery != INVALID_HANDLE )
				CloseHandle(hQuery);
			SQL_UnlockDatabase(DB);
			PrintToServer("UNLOCK-3");
		}
		else if( StrEqual( options, "stats", false) ) {
			
			SetMenuTitle(menu, "  Tribunal - Stats joueur \n--------------------");
			char tmp[255], tmp2[255], szSteam[32];
			
			for(int i = 1; i <= MaxClients; i++) {
				if( !IsValidClient(i) )
					continue;
				
				if( rp_GetZoneInt( rp_GetPlayerZone(i), zone_type_type) != 101 ) 
					continue;
				
				GetClientAuthId(i, AuthId_Engine, szSteam, sizeof(szSteam), false);
				
				Format(tmp, sizeof(tmp), "%s %s %s", options, szSteam, szSteam);
				
				Format(tmp2, sizeof(tmp2), "%N - %s", i, szSteam);
				AddMenuItem(menu, tmp, tmp2);
			}
		}
		
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, MENU_TIME_DURATION);
	}
	else if( p_oAction == MenuAction_End ) {
		
		CloseHandle(p_hItemMenu);
	}
}
public int MenuTribunal_selectplayer(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("MenuTribunal_selectplayer");
	#endif
	if( p_oAction == MenuAction_Select && client != 0) {
		char buff_options[255], options[3][64], tmp[255], tmp2[255], szTitle[128], szURL[512];
		GetMenuItem(p_hItemMenu, p_iParam2, buff_options, 254);
		ExplodeString(buff_options, " ", options, sizeof(options), sizeof(options[]));
		
		Format(szTitle, sizeof(szTitle), "Tribunal: %s", options[1]);
		Format(szURL, sizeof(szURL), "https://www.ts-x.eu/popup.php?url=/index.php?page=roleplay2&sharp=/tribunal/case/%s", options[2]);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Si la page ne s'ouvre pas, un lien est disponible dans votre console.");
		PrintToConsole(client, "https://www.ts-x.eu/index.php?page=roleplay2#/tribunal/case/%s", options[2]);
		
		AdvMOTD_ShowMOTDPanel(client, szTitle, szURL, MOTDPANEL_TYPE_URL);
		
		if( !StrEqual(options[0], "stats") ) {
			
			Handle menu = CreateMenu(MenuTribunal_Apply);
			SetMenuTitle(menu, "  Tribunal - Sélection de la peine \n--------------------");
			
			for(int i=0; i<=100; i+=2) {
				Format(tmp, sizeof(tmp), "%s %s %s %i", options[0], options[1], options[2], i);
				Format(tmp2, sizeof(tmp2), "%i heures", i);
				AddMenuItem(menu, tmp, tmp2);
			}
			
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, MENU_TIME_DURATION*2*10);
		}
	}
	else if( p_oAction == MenuAction_End ) {
		
		CloseHandle(p_hItemMenu);
	}
	
}
public int MenuTribunal_Apply(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("MenuTribunal_Apply");
	#endif
	if( p_oAction == MenuAction_Select && client != 0) {
		char buff_options[255], options[4][64];
		GetMenuItem(p_hItemMenu, p_iParam2, buff_options, 254);
		
		ExplodeString(buff_options, " ", options, sizeof(options), sizeof(options[]));
		
		char random[6];
		String_GetRandom(random, sizeof(random), sizeof(random) - 1, "23456789abcdefg");
		
		strcopy(g_szTribunal_DATA[client][tribunal_option], 63, options[0]);
		strcopy(g_szTribunal_DATA[client][tribunal_steamid], 63, options[1]);
		strcopy(g_szTribunal_DATA[client][tribunal_uniqID], 63, options[2]);
		strcopy(g_szTribunal_DATA[client][tribunal_duration], 63, options[3]);
		strcopy(g_szTribunal_DATA[client][tribunal_code], 63, random);
		if(StringToInt(g_szTribunal_DATA[client][tribunal_duration]) > 0)
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Afin de confirmer votre jugement, tappez maintenant /jugement amende %s raison", random);
		else
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Afin de confirmer votre jugement, tappez maintenant /jugement %s raison", random);
	}
	else if( p_oAction == MenuAction_End ) {
		
		CloseHandle(p_hItemMenu);
	}
}
public int MenuTribunal(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("MenuTribunal");
	#endif
	if (p_oAction == MenuAction_Select) {
		
		char szMenuItem[64];
		if( GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem)) ) {
			
			int target = StringToInt(szMenuItem);
			if( !IsValidClient(target) ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le joueur s'est déconnecté.");
				return;
			}
			
			char uniqID[64], szSteamID[64], szIP[64], szQuery[1024];
			
			String_GetRandom(uniqID, sizeof(uniqID), 32, "23456789abcdefg");
			GetClientAuthId(target, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
			GetClientIP(client, szIP, sizeof(szIP));
			
			Handle DB = rp_GetDatabase();
			
			Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_tribunal` (`uniqID`, `timestamp`, `steamid`, `IP`) VALUES ('%s', '%i', '%s', '%s');", uniqID, GetTime(), szSteamID, szIP);
			PrintToServer("LOCK-4");
			SQL_LockDatabase(DB);
			SQL_Query(DB, szQuery);
			SQL_UnlockDatabase(DB);
			PrintToServer("UNLOCK-4");
			char szTitle[128], szURL[512];
			Format(szTitle, sizeof(szTitle), "Tribunal: %N", target);
			Format(szURL, sizeof(szURL), "https://www.ts-x.eu/popup.php?url=/index.php?page=tribunal&action=case&steamid=%s&tokken=%s", szSteamID, uniqID);
			
			AdvMOTD_ShowMOTDPanel(client, szTitle, szURL, MOTDPANEL_TYPE_URL);
			return;
		}		
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hItemMenu);
	}
}
// ----------------------------------------------------------------------------
void SendPlayerToJail(int target, int client = 0) {
	#if defined DEBUG
	PrintToServer("SendPlayerToJail");
	#endif
	static float fLocation[MAX_LOCATIONS][3];
	char tmp[128];
	
	#if defined DEBUG
	PrintToServer("SendPlayerToJail: %d %d", target, client);
	#endif
	
	rp_ClientGiveItem(client, 1, -rp_GetClientItem(client, 1));
	rp_ClientGiveItem(client, 2, -rp_GetClientItem(client, 2));
	rp_ClientGiveItem(client, 3, -rp_GetClientItem(client, 3));
	
	int MaxJail = 0;	
	float MinHull[3], MaxHull[3];
	GetEntPropVector(target, Prop_Send, "m_vecMins", MinHull);
	GetEntPropVector(target, Prop_Send, "m_vecMaxs", MaxHull);
	
	for (int j = 0; j <= 1; j++) {
		for( int i=0; i<MAX_LOCATIONS; i++ ) {
			rp_GetLocationData(i, location_type_base, tmp, sizeof(tmp));
			if( StrEqual(tmp, "jail", false) ) {
				
				fLocation[MaxJail][0] = float(rp_GetLocationInt(i, location_type_origin_x));
				fLocation[MaxJail][1] = float(rp_GetLocationInt(i, location_type_origin_y));
				fLocation[MaxJail][2] = float(rp_GetLocationInt(i, location_type_origin_z)) + 5.0;
				
				MaxJail++;
				
				if( j == 0 ) {
					Handle tr = TR_TraceHullFilterEx(fLocation[MaxJail], fLocation[MaxJail], MinHull, MaxHull, MASK_PLAYERSOLID, TraceRayDontHitSelf, target);
					if( TR_DidHit(tr) ) {
						CloseHandle(tr);
						MaxJail--;
						continue;
					}
					CloseHandle(tr);
				}
			}
		}
		if( MaxJail > 0 )
			break;
	}
	
	if( MaxJail == 0 ) {
		LogToGame("DEBUG ---> AUCUNE JAIL DISPO TROUVEE OMG");
	}
	
	if( GetClientTeam(target) == CS_TEAM_CT ) {
		CS_SwitchTeam(target, CS_TEAM_T);
	}
	
	Entity_SetModel(target, MODEL_PRISONNIER);
	rp_ClientColorize(target); // Remet la couleur normale au prisonnier si jamais il est coloré
	SetEntProp(target, Prop_Send, "m_nSkin", Math_GetRandomInt(0, 14));
	
	if( IsValidClient(client) ) {
		
		
		if( !IsValidClient(rp_GetClientInt(target, i_JailledBy)) )
			rp_SetClientInt(target, i_JailledBy, client);
		
		
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N {default}vous a mis en prison.", client);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez mis %N {default}en prison.", target);
		
		AskJailTime(client, target);
		LogToGame("[TSX-RP] [JAIL-0] %L (%d) a mis %L (%d) en prison.", client, rp_GetPlayerZone(client, 1.0), target, rp_GetPlayerZone(target, 1.0));
		
	}
	
	int rand = Math_GetRandomInt(0, (MaxJail-1));
	TeleportEntity(target, fLocation[rand], NULL_VECTOR, NULL_VECTOR);
	FakeClientCommandEx(target, "sm_stuck");
	
	
	SDKHook(target, SDKHook_WeaponDrop, OnWeaponDrop);
	CreateTimer(MENU_TIME_DURATION.0, AllowWeaponDrop, target);
}
public Action AllowWeaponDrop(Handle timer, any client) {
	SDKUnhook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}
public Action OnWeaponDrop(int client, int weapon) {
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
void AskJailTime(int client, int target) {
	#if defined DEBUG
	PrintToServer("AskJailTime");
	#endif
	char tmp[256], tmp2[12];
	
	GetClientAuthId(target, AuthId_Engine, g_szTribunal_DATA[client][tribunal_steamid], sizeof(g_szTribunal_DATA[][]), false);

	Handle menu = CreateMenu(eventSetJailTime);
	Format(tmp, 255, "Combien de temps doit rester %N?", target);	
	SetMenuTitle(menu, tmp);
	
	Format(tmp, 255, "%d_-1", target);
	AddMenuItem(menu, tmp, "Annuler la peine / Liberer");
	
	if( rp_GetClientJobID(client) == 101 || rp_GetClientBool(target, b_IsSearchByTribunal)) {
		Format(tmp, 255, "%d_-3", target);
		AddMenuItem(menu, tmp, "Jail Tribunal N°1");
		Format(tmp, 255, "%d_-2", target);
		AddMenuItem(menu, tmp, "Jail Tribunal N°2");
	}
	
	if(rp_GetClientInt(target, i_JailTime) <= 6*60){
		for(int i=0; i<sizeof(g_szJailRaison); i++) {

			Format(tmp2, sizeof(tmp2), "%d_%d", target, i);
			AddMenuItem(menu, tmp2, g_szJailRaison[i][jail_raison]);
		}
	}
	else{
		Format(tmp2, sizeof(tmp2), "%d_%d", target, sizeof(g_szJailRaison)-1);
		AddMenuItem(menu, tmp2, g_szJailRaison[sizeof(g_szJailRaison)-1][jail_raison]);
	}
	
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, MENU_TIME_DURATION);	
}
public int eventAskJail2Time(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventAskJail2Time");
	#endif
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, 63);
		
		char data[2][32];
		
		ExplodeString(options, "_", data, sizeof(data), sizeof(data[]));
		
		int iTarget = StringToInt(data[0]);
		int iTime = StringToInt(data[1]);
		
		if( iTime < 0 ) {
			AskJailTime(client, iTarget);
			
			
			if( rp_GetClientInt(iTarget, i_JailTime) <= 60 )
				rp_SetClientInt(iTarget, i_JailTime, 1*60);
			
			SendPlayerToJail(iTarget);
		}
		else {
			
			SendPlayerToJail(iTarget);
			rp_SetClientInt(iTarget, i_JailTime, (iTime*60) + 20);		
			rp_SetClientInt(iTarget, i_JailledBy, client);
			
			CPrintToChatAll("{lightblue}[TSX-RP]{default} %N {default}a été condamné à faire %i heures de prison par le juge %N{default}.", iTarget, iTime, client);
			LogToGame("[TSX-RP] [JUGE] %L a été condamné à faire %i heures de prison par le juge %L.", iTarget, iTime, client);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public int eventSetJailTime(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventSetJailTime");
	#endif
	char options[64], data[2][32], szQuery[1024];
	
	if( action == MenuAction_Select ) {
		
		
		GetMenuItem(menu, param2, options, 63);		
		ExplodeString(options, "_", data, sizeof(data), sizeof(data[]));
		
		int target = StringToInt(data[0]);
		int type = StringToInt(data[1]);
		int time_to_spend;
		int jobID = rp_GetClientJobID(client);
		//FORCE_Release(iTarget);
		
		if( type == -1 ) {
			rp_SetClientInt(target, i_JailTime, 0);
			rp_SetClientInt(target, i_jailTime_Last, 0);
			rp_SetClientInt(target, i_JailledBy, 0);
			
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez libéré %N{default}.", target);
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N {default}vous a liberé.", client);
			
			LogToGame("[TSX-RP] [JAIL] [LIBERATION] %L a liberé %L", client, target);
			
			rp_ClientResetSkin(target);
			rp_ClientSendToSpawn(target, true);
			return;
		}
		if( type == -2 || type == -3 ) {
			
			if( type == -3 )
				TeleportEntity(target, view_as<float>({-276.0, -276.0, -1980.0}), NULL_VECTOR, NULL_VECTOR);
			else
				TeleportEntity(target, view_as<float>({632.0, -1258.0, -1980.0}), NULL_VECTOR, NULL_VECTOR);
			
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez été mis en prison, en attente de jugement par: %N", client);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez mis: %N {default}dans la prison du Tribunal.", target);
			
			if( rp_GetClientInt(target, i_JailTime) <= 360 )
				rp_SetClientInt(target, i_JailTime, 360);
			
			LogToGame("[TSX-RP] [TRIBUNAL] %L a mis %L dans la prison du Tribunal.", client, target);
			return;
		}
		if( StrEqual(g_szJailRaison[type][jail_raison],"Agression physique") 
			&& !(rp_GetClientInt(client, i_Job) >= 101 || rp_GetClientInt(client, i_Job) >= 106) ) { // Agression physique
			if(rp_GetClientInt(target, i_LastAgression)+30 < GetTime()){
				rp_SetClientInt(target, i_JailTime, 0);
				rp_SetClientInt(target, i_jailTime_Last, 0);
				rp_SetClientInt(target, i_JailledBy, 0);
				
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N{default} a été libéré car il n'a pas commis d'agression.", target);
				CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez été libéré car vous n'avez pas commis d'agression.", client);
				
				LogToGame("[TSX-RP] [JAIL] %L a été libéré car il n'avait pas commis d'agression", target);
				
				rp_ClientResetSkin(target);
				rp_ClientSendToSpawn(target, true);
				return;
			}
		}
		if( StrEqual(g_szJailRaison[type][jail_raison],"Tir dans la rue") 
			&& !(rp_GetClientInt(client, i_Job) >= 101 || rp_GetClientInt(client, i_Job) >= 106) ) { // Tir dans la rue
			if(rp_GetClientInt(target, i_LastShot)+30 < GetTime()){
				rp_SetClientInt(target, i_JailTime, 0);
				rp_SetClientInt(target, i_jailTime_Last, 0);
				rp_SetClientInt(target, i_JailledBy, 0);
				
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N{default} a été libéré car il n'a pas effectué de tir.", target);
				CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez été libéré car vous n'avez pas effectué de tir.", client);
				
				LogToGame("[TSX-RP] [JAIL] %L a été libéré car il n'avait pas effectué de tir", target);
				
				rp_ClientResetSkin(target);
				rp_ClientSendToSpawn(target, true);
				return;
			}
		}
		int amende = StringToInt(g_szJailRaison[type][jail_amende]);
		
		if( amende == -1 )
			amende = rp_GetClientInt(target, i_KillingSpread) * 200;
		
		if( String_StartsWith(g_szJailRaison[type][jail_raison], "Vol") ) {
			if(rp_GetClientInt(target, i_LastVolVehicleTime)+300 > GetTime()){
				if(rp_IsValidVehicle(rp_GetClientInt(target, i_LastVolVehicle))){
					rp_SetClientKeyVehicle(target, rp_GetClientInt(target, i_LastVolVehicle), false);
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N{default} a perdu les clés de la voiture qu'il a volé.", target);
					CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez perdu les clés de la voiture que vous avez volé.", client);
				}
			}
			else if(rp_GetClientInt(target, i_LastVolTime)+30 < GetTime()){
				rp_SetClientInt(target, i_JailTime, 0);
				rp_SetClientInt(target, i_jailTime_Last, 0);
				rp_SetClientInt(target, i_JailledBy, 0);
				
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N{default} a été libéré car il n'a pas commis de vol.", target);
				CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez été libéré car vous n'avez pas commis de vol.", client);
				
				LogToGame("[TSX-RP] [JAIL] %L a été libéré car il n'avait pas commis de vol", target);
				
				rp_ClientResetSkin(target);
				rp_ClientSendToSpawn(target, true);
				return;
			}
			if( IsValidClient( rp_GetClientInt(target, i_LastVolTarget) ) ) {
				int tg = rp_GetClientInt(target, i_LastVolTarget);
				rp_SetClientInt(tg, i_Money, rp_GetClientInt(tg, i_Money) + rp_GetClientInt(target, i_LastVolAmount));
				rp_SetClientInt(target, i_AddToPay, rp_GetClientInt(target, i_AddToPay) - rp_GetClientInt(target, i_LastVolAmount));
				
				CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez remboursé votre victime de %d$.", rp_GetClientInt(target, i_LastVolAmount));
				CPrintToChat(tg, "{lightblue}[TSX-RP]{default} Le voleur a été mis en prison. Vous avez été remboursé de %d$.", rp_GetClientInt(target, i_LastVolAmount));
			}
			else{
				amende += rp_GetClientInt(target, i_LastVolAmount); // Cas tentative de vol ou distrib...
			}
		}
		else {
			amendeCalculation(target, amende);
		}
		
		if( rp_GetClientInt(target, i_Money) >= amende || (
			(rp_GetClientInt(target, i_Money)+rp_GetClientInt(target, i_Bank)) >= amende*250 && amende <= 2500) ) {
			
			rp_SetClientStat(target, i_MoneySpent_Fines, rp_GetClientStat(target, i_MoneySpent_Fines) + amende);
			rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - amende);
			rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + (amende / 4));
			rp_SetJobCapital(jobID, rp_GetJobCapital(jobID) + (amende/4 * 3));
			
			GetClientAuthId(client, AuthId_Engine, options, sizeof(options), false);
			
			Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
			options, jobID, GetTime(), 0, "Caution", amende/4);
			
			SQL_TQuery( rp_GetDatabase(), SQL_QueryCallBack, szQuery);
			
			time_to_spend = StringToInt(g_szJailRaison[type][jail_temps]);
			if( time_to_spend == -1 ) {
				float kill = float(rp_GetClientInt(target, i_KillingSpread));
				time_to_spend = RoundToCeil(Logarithm(kill + 1.0) * 4.0 * kill + 4.0); // Mais oui, c'est claire !
				
				if( kill <= 0.0 )
					time_to_spend = 2;
				rp_SetClientInt(target, i_FreekillSick, 0);
				
				for(int i=1; i<MAXPLAYERS+1; i++){
					if(!IsValidClient(i))
						continue;
					if(rp_GetClientInt(i, i_LastKilled_Reverse) != target)
						continue;
					CPrintToChat(i, "{lightblue}[TSX-RP]{default} Votre assassin a été mis en prison.");
				}
				time_to_spend /= 2;
			}
			
			
			if( amende > 0 ) {
				
				if( IsValidClient(target) ) {
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Une amende de %i$ a été prélevée à %N{default}.", amende, target);
					CPrintToChat(target, "{lightblue}[TSX-RP]{default} Une caution de %i$ vous a été prelevée.", amende);
				}
			}
		}
		else {
			time_to_spend = StringToInt(g_szJailRaison[type][jail_temps_nopay]);
			if( time_to_spend == -1 ) {
				float kill = float(rp_GetClientInt(target, i_KillingSpread));
				time_to_spend = RoundToCeil(Logarithm(kill + 1.0) * 4.0 * kill + 4.0); // Mais oui, c'est claire !
				
				if( kill <= 0.0 )
					time_to_spend = 2;
				rp_SetClientInt(target, i_FreekillSick, 0);	
				
				for(int i=1; i<MAXPLAYERS+1; i++){
					if(!IsValidClient(i))
						continue;
					if(rp_GetClientInt(i, i_LastKilled_Reverse) != target)
						continue;
					CPrintToChat(i, "{lightblue}[TSX-RP]{default} Votre assassin a été mis en prison.");
				}
			}
			
			
			else if ( rp_GetClientInt(target, i_Bank) >= amende && time_to_spend != -2 ) {
				WantPayForLeaving(target, client, type, amende);
			}
		}
		
		if( time_to_spend < 0 ) {
			time_to_spend = rp_GetClientInt(target, i_JailTime) + (6 * 60);
		}
		else {
			rp_SetClientInt(target, i_jailTime_Reason, type);
			time_to_spend *= 60;
		}
		
		rp_SetClientInt(target, i_JailTime, time_to_spend);
		rp_SetClientInt(target, i_jailTime_Last, time_to_spend);
		 
		if( IsValidClient(client) && IsValidClient(target) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N {default}restera en prison %.1f heures pour \"%s\"", target, time_to_spend/60.0, g_szJailRaison[type][jail_raison]);
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N {default}vous a mis %.1f heures de prison pour \"%s\"", client, time_to_spend/60.0, g_szJailRaison[type][jail_raison]);
			explainJail(target, type, client);
		}
		else {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le joueur s'est déconnecté mais il fera %.1f heures de prison", time_to_spend / 60.0);
			
			Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_users2` (`id`, `steamid`, `jail` ) VALUES", szQuery);
			Format(szQuery, sizeof(szQuery), "%s (NULL, '%s', '%i' );", szQuery, g_szTribunal_DATA[client][tribunal_steamid], time_to_spend );
			
			SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);			
		}
		
		LogToGame("[TSX-RP] [JAIL-1] %L (%d) a mis %L (%d) en prison: Raison %s.", client, rp_GetPlayerZone(client, 1.0), target, rp_GetPlayerZone(target, 1.0), g_szJailRaison[type][jail_raison]);
		
		if( time_to_spend <= 1 ) {
			rp_ClientResetSkin(target);
			rp_ClientSendToSpawn(target, true);
		}
		StripWeapons(target);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
void WantPayForLeaving(int client, int police, int type, int amende) {
	#if defined DEBUG
	PrintToServer("WantPayForLeaving");
	#endif

	// Setup menu
	Handle menu = CreateMenu(eventPayForLeaving);
	char tmp[256];
	Format(tmp, 255, "Vous avez été mis en prison pour \n %s\nUne caution de %i$ vous est demandé", g_szJailRaison[type][jail_raison], amende);	
	SetMenuTitle(menu, tmp);
	
	Format(tmp, 255, "%i_%i_%i", police, type, amende);
	AddMenuItem(menu, tmp, "Oui, je souhaite payer ma caution");
	
	Format(tmp, 255, "0_0_0");
	AddMenuItem(menu, tmp, "Non, je veux rester plus longtemps");
	
	
	SetMenuExitButton(menu, false);
	
	DisplayMenu(menu, client, MENU_TIME_DURATION);
}
public int eventPayForLeaving(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("eventPayForLeaving");
	#endif
	if( action == MenuAction_Select ) {
		char options[64], data[3][32], szQuery[2048];
		
		GetMenuItem(menu, param2, options, 63);
		
		ExplodeString(options, "_", data, sizeof(data), sizeof(data[]));
		
		
		int target = StringToInt(data[0]);
		int type = StringToInt(data[1]);
		int amende = StringToInt(data[2]);
		int jobID = rp_GetClientJobID(target);
		
		if( target == 0 && type == 0 && amende == 0)
			return;
		
		int time_to_spend = 0;
		rp_SetClientStat(client, i_MoneySpent_Fines, rp_GetClientStat(client, i_MoneySpent_Fines) + amende);
		rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - amende);
		rp_SetClientInt(target, i_AddToPay, rp_GetClientInt(target, i_AddToPay) + (amende / 4));
		rp_SetJobCapital(jobID, rp_GetJobCapital(jobID) + (amende/4 * 3));
			
		GetClientAuthId(client, AuthId_Engine, options, sizeof(options), false);
			
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
		options, jobID, GetTime(), 0, "Caution", amende/4);
			
		SQL_TQuery( rp_GetDatabase(), SQL_QueryCallBack, szQuery);
			
		time_to_spend = StringToInt(g_szJailRaison[type][jail_temps]);
		if( time_to_spend == -1 ) {
			float kill = float(rp_GetClientInt(target, i_KillingSpread));
			time_to_spend = RoundToCeil(Logarithm(kill + 1.0) * 4.0 * kill + 4.0); // Mais oui, c'est claire !
			
			if( kill <= 0.0 )
				time_to_spend = 2;
			rp_SetClientInt(target, i_FreekillSick, 0);
			
			time_to_spend /= 2;
		}
			
			
		if( IsValidClient(target) ) {
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} Une amende de %i$ a été prélevée à %N.", amende, client);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Une caution de %i$ vous a été prelevée.", amende);
		}
		
		time_to_spend *= 60;
		rp_SetClientInt(client, i_JailTime, time_to_spend);
		rp_SetClientInt(client, i_jailTime_Last, time_to_spend);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
// ----------------------------------------------------------------------------
void amendeCalculation(int client, int& amende) {
	#if defined DEBUG
	PrintToServer("amendeCalculation");
	#endif
	float ratio = float(rp_GetClientInt(client, i_Kill31Days)+1) / float(rp_GetClientInt(client, i_Death31Days)+1);
	if( ratio < 0.25 )
		ratio = 0.25;
	
	amende =  RoundFloat(float(amende) * ratio);
}
int GetPerquizResp(int job_id) {
	#if defined DEBUG
	PrintToServer("GetPerquizResp");
	#endif
	int zone;
	
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
			
		zone = rp_GetZoneBit(rp_GetPlayerZone(i));
		if( zone & (BITZONE_JAIL|BITZONE_LACOURS|BITZONE_HAUTESECU) )
			continue;
		
		if( job_id == rp_GetClientInt(i, i_Job) )
			return i;
	}
	
	int min = 9999;
	int res = 0;
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		zone = rp_GetZoneBit(rp_GetPlayerZone(i));
		if( zone & (BITZONE_JAIL|BITZONE_LACOURS|BITZONE_HAUTESECU) )
			continue;
			
		if( job_id == rp_GetJobInt( rp_GetClientInt(i, i_Job),  job_type_ownboss) ) {
			if( min > rp_GetClientInt(i, i_Job) ) {
				min = rp_GetClientInt(i, i_Job);
				res = i;
			}
		}
	}
	
	
	return res;
}
// ----------------------------------------------------------------------------
public int MenuPerquiz(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("MenuPerquiz");
	#endif
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, 63);
		int job_id = rp_GetZoneInt(rp_GetPlayerZone(rp_GetClientTarget(client)), zone_type_type);
		
		if( job_id <= 0 || job_id > 250 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cette porte ne peut pas être perquisitionnée.");
			return;
		}
		
		if( StrEqual(options, "start") ) {
			g_iCancel[client] = 0;
			if(rp_GetClientJobID(client) == 1)
				start_perquiz(client, job_id);
			else
				begin_perquiz(client, job_id);
		}
		else if( StrEqual(options, "cancel") ) {
			cancel_perquiz(client, job_id);
			g_iCancel[client] = 1;
		}
		else if( StrEqual(options, "stop") ) {
			end_perquiz(client, job_id);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
void start_perquiz(int client, int job) {
	#if defined DEBUG
	PrintToServer("start_perquiz");
	#endif
	int REP = GetPerquizResp(job);
	
	Handle dp;
	CreateDataTimer(10.0, PerquizFrame, dp, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dp, (60*1) + 10);
	WritePackCell(dp, client);
	WritePackCell(dp, job);
	WritePackCell(dp, REP);
	
	char tmp[255];
	rp_GetZoneData(JobToZoneID(job), zone_type_name, tmp, sizeof(tmp));
	
	PrintToChatPoliceJob(job, "{lightblue} ================================== {default}");
	PrintToChatPoliceJob(job, "{lightblue}[TSX-RP] [POLICE]{default} Début d'une perquisition dans: %s.", tmp);
	LogToGame("[TSX-RP] [POLICE] %N débute une perquisition dans %s.",client, tmp);
	
	if( REP > 0 )
		PrintToChatPoliceJob(job, "{lightblue}[TSX-RP] [POLICE]{default} %N {default}est prié de se présenter sur les lieux.", REP);
	PrintToChatPoliceJob(job, "{lightblue} ================================== {default}");
	
	rp_SetJobCapital(1, rp_GetJobCapital(1) + 250);
}
void begin_perquiz(int client, int job) {
	#if defined DEBUG
	PrintToServer("begin_perquiz");
	#endif
	char tmp[255];
	rp_GetZoneData(JobToZoneID(job), zone_type_name, tmp, sizeof(tmp));
	
	PrintToChatPoliceJob(job, "{lightblue} ================================== {default}");
	if(rp_GetClientJobID(client) == 1){
		PrintToChatPoliceJob(job, "{lightblue}[TSX-RP] [POLICE]{default} Début d'une perquisition dans %s.", tmp);
		LogToGame("[TSX-RP] [POLICE] La perquisition commence dans %s.", tmp);
		rp_SetJobCapital(1, rp_GetJobCapital(1) + 250);
	}
	else{
		PrintToChatPoliceJob(job, "{lightblue}[TSX-RP] [JUSTICE]{default} Début d'une perquisition dans %s.", tmp);
		LogToGame("[TSX-RP] [JUSTICE] %N débute une perquisition dans %s.", client, tmp);
		rp_SetJobCapital(101, rp_GetJobCapital(101) + 250);
	}
	PrintToChatPoliceJob(job, "{lightblue} ================================== {default}");
	
	
	rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + 500);
}
void end_perquiz(int client, int job) {
	#if defined DEBUG
	PrintToServer("end_perquiz");
	#endif
	char tmp[255];
	rp_GetZoneData(JobToZoneID(job), zone_type_name, tmp, sizeof(tmp));
	
	PrintToChatPoliceJob(job, "{lightblue} ================================== {default}");
	if(rp_GetClientJobID(client) == 1){
		PrintToChatPoliceJob(job, "{lightblue}[TSX-RP] [POLICE]{default} Fin de la perquisition dans %s.", tmp);
		rp_SetJobCapital(1, rp_GetJobCapital(1) + 500);
	}
	else{
		PrintToChatPoliceJob(job, "{lightblue}[TSX-RP] [JUSTICE]{default} Fin de la perquisition dans %s.", tmp);
		rp_SetJobCapital(101, rp_GetJobCapital(101) + 500);
	}
	LogToGame("[TSX-RP] [POLICE] %N a mis fin à la perquisition dans %s.",client, tmp);
	
	PrintToChatPoliceJob(job, "{lightblue} ================================== {default}");
	
	rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + 500);
	
	char szQuery[1024], szSteamID[64];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
	
	Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_perquiz` (`id`, `job`, `time`, `steamid`) VALUES (NULL, '%i', UNIX_TIMESTAMP(), '%s');", job, szSteamID);
	
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
}
void cancel_perquiz(int client, int job) {
	#if defined DEBUG
	PrintToServer("cancel_perquiz");
	#endif
	char tmp[255];
	rp_GetZoneData(JobToZoneID(job), zone_type_name, tmp, sizeof(tmp));
	
	PrintToChatPoliceJob(job, "{lightblue} ================================== {default}");
	if(rp_GetClientJobID(client) == 1){
		PrintToChatPoliceJob(job, "{lightblue}[TSX-RP] [POLICE]{default} Annulation de la perquisition dans %s.", tmp);
		rp_SetJobCapital(1, rp_GetJobCapital(1) - 250);
	}
	else{
		PrintToChatPoliceJob(job, "{lightblue}[TSX-RP] [JUSTICE]{default} Annulation de la perquisition dans %s.", tmp);
		rp_SetJobCapital(101, rp_GetJobCapital(101) - 250);
	}
	LogToGame("[TSX-RP] [POLICE] %N a annulé la perquisition dans %s.",client, tmp);
	
	PrintToChatPoliceJob(job, "{lightblue} ================================== {default}");
	
	rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) - 500);
}
public Action PerquizFrame(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("PerquizFrame");
	#endif
	ResetPack(dp);
	int time = ReadPackCell(dp) - 10;
	int client = ReadPackCell(dp);
	int job = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	
	char tmp[255];
	rp_GetZoneData(JobToZoneID(job), zone_type_name, tmp, sizeof(tmp));
	
	if( !IsValidClient(client) ) {
		cancel_perquiz(0, job);
		return Plugin_Handled;
	}
	
	if( g_iCancel[client] ) {
		g_iCancel[client] = 0;
		return Plugin_Handled;
	}
	if( !IsValidClient(target) || target == 0 ) {
		begin_perquiz(client, job);
		return Plugin_Handled;
	}
	
	int zone = rp_GetZoneInt(rp_GetPlayerZone(target), zone_type_type);
	
	if( zone == job || rp_IsEntitiesNear(client, target) || time <= 0 ) {
		begin_perquiz( client, job );
		return Plugin_Handled;
	}
		
	CPrintToChat(target, "{lightblue} ================================== {default}");
	CPrintToChat(target, "{lightblue}[TSX-RP] [POLICE]{default} une perquisition commencera dans: %i secondes", time);
	CPrintToChat(target, "{lightblue}[TSX-RP] [POLICE]{default} %N {default}est prié de se présenter à %s.", target, tmp);
	CPrintToChat(target, "{lightblue} ================================== {default}");
	
	CPrintToChat(client, "{lightblue} ================================== {default}");
	CPrintToChat(client, "{lightblue}[TSX-RP] [POLICE]{default} une perquisition commencera dans: %i secondes", time);
	CPrintToChat(client, "{lightblue}[TSX-RP] [POLICE]{default} %N {default}est prié de se présenter à %s", target, tmp);
	CPrintToChat(client, "{lightblue} ================================== {default}");
	
	
	CreateDataTimer(10.0, PerquizFrame, dp, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dp, time);
	WritePackCell(dp, client);
	WritePackCell(dp, job);
	WritePackCell(dp, GetPerquizResp(job));
	
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action AllowStealing(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("AllowStealing");
	#endif
	rp_SetClientBool(client, b_MaySteal, true);
}
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("MenuNothing");
	#endif
	if( action == MenuAction_Select ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}
public Action fwdFrozen(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdFrozen");
	#endif
	speed = 0.0;
	
	return Plugin_Stop;
}
public Action fwdTazerBlue(int client, int color[4]) {
	#if defined DEBUG
	PrintToServer("fwdTazerBlue");
	#endif
	color[0] -= 50;
	color[1] -= 50;
	color[2] += 255;
	color[3] += 50;
	return Plugin_Changed;
}
public bool TraceRayDontHitSelf(int entity, int mask, any data) {
	#if defined DEBUG
	PrintToServer("TraceRayDontHitSelf");
	#endif
	if(entity == data) {
		return false;
	}
	return true;
}
int JobToZoneID(int job) {
	#if defined DEBUG
	PrintToServer("JobToZoneID");
	#endif
	static int last;
	
	if( rp_GetZoneInt(last, zone_type_type) == job ) {
		return last;
	}
	
	for(int i=1; i<300; i++) {	
		if( rp_GetZoneInt(i, zone_type_type) == job  ) {
			last = i;
			return i;
		}
	}
	return 0;
}
// ----------------------------------------------------------------------------
public Action fwdOnPlayerBuild(int client, float& cooldown) {
	#if defined DEBUG
	PrintToServer("fwdOnPlayerBuild_Barriere");
	#endif
	
	if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 )
		return Plugin_Continue;
		
	if( rp_IsInPVP(client) ){
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas poser une barrière en PVP.");
		return Plugin_Continue;
	}

	int Tzone = rp_GetPlayerZone(client);
	if(Tzone==24 || Tzone==25){
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas poser une barrière dans les conduits.");
		return Plugin_Continue;
	}

	int ent = BuildingBarriere(client);
	
	if(ent > 0){
		rp_SetClientStat(client, i_TotalBuild, rp_GetClientStat(client, i_TotalBuild)+1);
		rp_ScheduleEntityInput(ent, 120.0, "Kill");
		cooldown = 7.0;
	}
	else 
		cooldown = 3.0;
	
	return Plugin_Stop;
}
int BuildingBarriere(int client) {
	#if defined DEBUG
	PrintToServer("BuildingBarriere");
	#endif
	
	if( !rp_IsBuildingAllowed(client) )
		return 0;	
	
	char classname[64], tmp[64];
	
	Format(classname, sizeof(classname), "rp_barriere");	
	
	int count, job = rp_GetClientInt(client, i_Job), max = 0;
	
	switch( job ) {
		case 1:	max = 7;	//Chef
		case 2: max = 6;	//Co-chef
		case 5: max = 5;	//GTI
		case 6: max = 4;	//CIA
		case 7: max = 3;	//FBI
		case 8: max = 2;	//Policier
		case 9: max = 1;	//Gardien
		
		case 101: max = 7;	// Président
		case 102: max = 6;	// Vice président
		case 103: max = 6;	// HJ2
		case 104: max = 5;	// HJ1
		case 105: max = 4;	// J2
		case 106: max = 3;	// J1
		case 107: max = 5;	// GOS
		case 108: max = 3;	// US
		case 109: max = 1;	// gONU
		
		
		default:max = 0;
		
	}
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	for(int i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, sizeof(tmp));
		
		if( StrEqual(classname, tmp) ) {
			count++;
			if( count >= max ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez posé trop de barrières.");
				return 0;
			}
		}
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous posez une barrière...");

	EmitSoundToAllAny("player/ammo_pack_use.wav", client);
	
	int ent = CreateEntityByName("prop_physics_override");
	
	DispatchKeyValue(ent, "classname", classname);
	DispatchKeyValue(ent, "model", MODEL_BARRIERE);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	SetEntityModel(ent, MODEL_BARRIERE);
	
	SetEntProp( ent, Prop_Data, "m_iHealth", 1000);
	SetEntProp( ent, Prop_Data, "m_takedamage", 0);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	float vecAngles[3]; GetClientEyeAngles(client, vecAngles); vecAngles[0] = vecAngles[2] = 0.0;
	TeleportEntity(ent, vecOrigin, vecAngles, NULL_VECTOR);
	
	SetEntityRenderMode(ent, RENDER_NONE);
	ServerCommand("sm_effect_fading \"%i\" \"2.0\" \"0\"", ent);
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	
	CreateTimer(2.0, BuildingBarriere_post, ent);
	CreateTimer(2.0, BuildingBarriere_client_post, client);
	rp_SetBuildingData(ent, BD_owner, client);
	return ent;
}
public Action BuildingBarriere_client_post(Handle timer, any client) {
	SetEntityMoveType(client, MOVETYPE_WALK);
	return Plugin_Handled;
}
public Action BuildingBarriere_post(Handle timer, any entity) {
	#if defined DEBUG
	PrintToServer("BuildingBarriere_post");
	#endif
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	rp_Effect_BeamBox(client, entity, NULL_VECTOR, 255, 255, 0);
	
	SetEntProp(entity, Prop_Data, "m_takedamage", 2);
	HookSingleEntityOutput(entity, "OnBreak", BuildingBarriere_break);
	return Plugin_Handled;
}
public void BuildingBarriere_break(const char[] output, int caller, int activator, float delay) {
	#if defined DEBUG
	PrintToServer("BuildingBarriere_break");
	#endif
	
	int owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
	if( IsValidClient(owner) ) {
		CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Votre barrière a été détruite.");
	}
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemRatio(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemRatio");
	#endif
	char arg1[12];
	GetCmdArg(1, arg1, sizeof(arg1));
	int client = GetCmdArgInt(2);

	if( StrEqual(arg1, "own") ) {
		char steamid[64];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid), false);
		displayTribunal(client, steamid);
	}
	else if( StrEqual(arg1, "target") ) {
		if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est réservé aux forces de l'ordre.");
			return;
		}
		CreateTimer(0.25, task_RatioTarget, client);
	}
	else if( StrEqual(arg1, "gps") ) {
		rp_ClientGiveItem(client, ITEM_GPS);
		CreateTimer(0.25, task_GPS, client);
	}
}
public Action task_RatioTarget(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("task_RatioTarget");
	#endif
	
	Handle menu = CreateMenu(MenuTribunal_selectplayer);
	SetMenuTitle(menu, "  Tribunal - Stats joueur \n--------------------");
	char tmp[255], tmp2[255], szSteam[32];
	
	for(int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		if( Entity_GetDistance(client, i) > MAX_AREA_DIST.0 )
			continue;
		
		GetClientAuthId(i, AuthId_Engine, szSteam, sizeof(szSteam), false);
		
		Format(tmp, sizeof(tmp), "stats %s", szSteam);
		
		Format(tmp2, sizeof(tmp2), "%N - %s", i, szSteam);
		AddMenuItem(menu, tmp, tmp2);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
}
public Action task_GPS(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("task_GPS");
	#endif
	Handle menu = CreateMenu(MenuTribunal_GPS);
	SetMenuTitle(menu, "  GPS \n--------------------");
	char tmp[255], tmp2[255];
	
	for(int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) || i == client )
			continue;
		
		Format(tmp, sizeof(tmp), "%d", i);
		Format(tmp2, sizeof(tmp2), "%N", i);
		
		AddMenuItem(menu, tmp, tmp2);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
}
public int MenuTribunal_GPS(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("MenuTribunal_GPS");
	#endif
	
	if( p_oAction == MenuAction_Select && client != 0) {
		char option[32];
		GetMenuItem(p_hItemMenu, p_iParam2, option, sizeof(option));
		int target = StringToInt(option);
		
		
		if( rp_GetClientItem(client, ITEM_GPS) <= 0 ) {
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous n'avez plus de GPS.");
			return;
		}
		
		rp_ClientGiveItem(client, ITEM_GPS, -1);
		
		if( Math_GetRandomInt(1, 100) < rp_GetClientInt(target, i_Cryptage)*20 ) {
			
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} Votre pot de vin envers un mercenaire vient de vous sauver.");
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Un pot de vin envers un mercenaire vient de le sauver...");
			
		}
		else {
			
			if( rp_GetClientInt(client, i_GPS) <= 0 )
				CreateTimer(0.1, GPS_LOOP, client);
			rp_SetClientInt(client, i_GPS, target);
		}
	}
	else if( p_oAction == MenuAction_End ) {
		CloseHandle(p_hItemMenu);
	}
}
public Action GPS_LOOP(Handle timer, any client) {
	
	if( !IsValidClient(client) )
		return Plugin_Handled;
	
	int target = rp_GetClientInt(client, i_GPS);
	float vecOrigin[3], vecOrigin2[3];
	if( target == 0 || !IsValidClient(target) ) {
		rp_SetClientInt(client, i_GPS, 0);
		return Plugin_Handled;
	}
	
	GetClientAbsOrigin(client, vecOrigin);
	GetClientAbsOrigin(target, vecOrigin2);
	
	if( GetVectorDistance(vecOrigin, vecOrigin2) <= 200.0 ) {
		rp_SetClientInt(client, i_GPS, 0);
		return Plugin_Handled;
	}
	
	ServerCommand("sm_effect_gps %d %d", client, target);
	CreateTimer(1.0, GPS_LOOP, client);
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
void displayTribunal(int client, const char szSteamID[64]) {
	#if defined DEBUG
	PrintToServer("displayTribunal");
	#endif
	char szTitle[128], szURL[512], szQuery[1024], steamid[64], sso[256];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid), false);
	
	Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_tribunal` (`uniqID`, `timestamp`, `steamid`) VALUES ('%s', '%i', '%s');", steamid, GetTime(), szSteamID);
	
	Handle DB = rp_GetDatabase();
	
	SQL_LockDatabase(DB);
	SQL_Query(DB, szQuery);
	SQL_UnlockDatabase(DB);
	
	rp_GetClientSSO(client, sso, sizeof(sso));
	Format(szTitle, sizeof(szTitle), "Tribunal: %s", szSteamID);
	Format(szURL, sizeof(szURL), "https://www.ts-x.eu/popup.php?&url=/index.php?page=roleplay2%s&hashh=/tribunal/case/%s", sso, szSteamID);
	PrintToConsole(client, "https://www.ts-x.eu/index.php?page=roleplay2#/tribunal/case/%s", szSteamID);
	

	
	AdvMOTD_ShowMOTDPanel(client, szTitle, szURL, MOTDPANEL_TYPE_URL);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPickLock(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPickLock");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	rp_ClientReveal(client);
	
	if( rp_GetClientJobID(client) != 1 &&  rp_GetClientJobID(client) != 101 ) {
		return Plugin_Continue;
	}
	
	int door = GetClientAimTarget(client, false);
	
	if( !rp_IsValidDoor(door) && IsValidEdict(door) && rp_IsValidDoor(Entity_GetParent(door)) )
		door = Entity_GetParent(door);
		

		
	if( !rp_IsValidDoor(door) || !rp_IsEntitiesNear(client, door, true) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser une porte.");
		return Plugin_Handled;
	}
	
	float time = 0.5;
	
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, time);
	ServerCommand("sm_effect_panel %d %f \"Ouverture de la porte...\"", client, time);
	
	rp_ClientColorize(client, { 255, 0, 0, 190} );
	rp_ClientReveal(client);
	
	Handle dp;
	CreateDataTimer(time-0.25, ItemPickLockOver_mandat, dp, TIMER_DATA_HNDL_CLOSE); 
	WritePackCell(dp, client);
	WritePackCell(dp, door);
	
	return Plugin_Handled;
}
public Action ItemPickLockOver_mandat(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("ItemPickLockOver_mandat");
	#endif
	if( dp == INVALID_HANDLE ) {
		return Plugin_Handled;
	}
	
	ResetPack(dp);
	int client 	 = ReadPackCell(dp);
	int door = ReadPackCell(dp);
	int doorID = rp_GetDoorID(door);
	
	rp_ClientColorize(client);
	
	if( !rp_IsEntitiesNear(client, door, true) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} ~ [ECHEC] ~ Rapprochez-vous de la porte pour utiliser votre mandat");
		return Plugin_Handled;
	}

	rp_SetDoorLock(doorID, false); 
	rp_ClientOpenDoor(client, doorID, true);

	float vecOrigin[3], vecOrigin2[3];
	Entity_GetAbsOrigin(door, vecOrigin);
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		Entity_GetAbsOrigin(i, vecOrigin2);
		
		if( GetVectorDistance(vecOrigin, vecOrigin2) > MAX_AREA_DIST.0 )
			continue;
		
		CPrintToChat(i, "{lightblue}[TSX-RP]{default} La porte a été ouverte avec un mandat.");
	}
	
	return Plugin_Continue;
}

public Action fwdDmg(int attacker, int victim, float& damage) {
	if( !rp_GetClientBool(attacker, b_Stealing) && !rp_IsInPVP(attacker))
		rp_SetClientInt(attacker, i_LastAgression, GetTime());

	return Plugin_Continue;
}
public void Event_Bullet_Impact(Event event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(event.GetInt("userid"));
		
	rp_SetClientInt(client, i_LastShot, GetTime());
}
public void Event_Weapon_Fire(Event event, const char[] name, bool dontBroadcast){
	int client = GetClientOfUserId(event.GetInt("userid"));
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	if( StrContains(weapon, "weapon_bayonet") == 0 || StrContains(weapon, "weapon_knife") == 0 )
		return;

	rp_SetClientInt(client, i_LastShot, GetTime());
}
// ----------------------------------------------------------------------------
void StripWeapons(int client ) {
	#if defined DEBUG
	PrintToServer("StripWeapons");
	#endif
	
	int wepIdx;
	
	for( int i = 0; i < 5; i++ ){
		if( i == CS_SLOT_KNIFE ) continue; 
		
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ) {
			
			if( canWeaponBeAddedInPoliceStore(wepIdx) )
				rp_WeaponMenu_Add(g_hBuyMenu, wepIdx, GetEntProp(wepIdx, Prop_Send, "m_OriginalOwnerXuidHigh"));
			
			RemovePlayerItem( client, wepIdx );
			RemoveEdict( wepIdx );
		}
	}
	
	FakeClientCommand(client, "use weapon_knife");
}

public Action fwdOnPlayerUse(int client) {
	#if defined DEBUG
	PrintToServer("fwdOnPlayerUse");
	#endif
	float vecOrigin[3];
	
	GetClientAbsOrigin(client, vecOrigin);
	
	if( GetVectorDistance(vecOrigin, view_as<float>({ 2550.8, 1663.1, -2015.96 })) < 40.0 ) {
		Cmd_BuyWeapon(client, false);
	}
	return Plugin_Continue;
}
void Cmd_BuyWeapon(int client, bool free) {
	DataPackPos max = rp_WeaponMenu_GetMax(g_hBuyMenu);
	DataPackPos position = rp_WeaponMenu_GetPosition(g_hBuyMenu);
	char name[65], tmp[8], tmp2[129];
	int data[BM_Max];
	
	if( position >= max ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Désolé, aucune arme n'est disponible pour le moment.");
		return;
	}
	
	Menu menu = new Menu(Menu_BuyWeapon);
	menu.SetTitle("Armes trouvées par la police:");
	
	while( position < max ) {
		
		rp_WeaponMenu_Get(g_hBuyMenu, position, name, data);
		Format(tmp, sizeof(tmp), "%d %d", position, free);

		if(data[BM_PvP] > 0)
			Format(tmp2, sizeof(tmp2), "[PvP] ");
		else
			Format(tmp2, sizeof(tmp2), "");
		
		if( data[BM_Munition] == -1 )
			Format(tmp2, sizeof(tmp2), "%s %s (1) ", tmp2, name);
		else
			Format(tmp2, sizeof(tmp2), "%s %s (%d/%d) ", tmp2, name, data[BM_Munition] , data[BM_Chargeur]);
			
		switch(view_as<enum_ball_type>(data[BM_Type])){
			case ball_type_fire          : Format(tmp2, sizeof(tmp2), "%s Incendiaire", tmp2);
			case ball_type_caoutchouc    : Format(tmp2, sizeof(tmp2), "%s Caoutchouc", tmp2);
			case ball_type_poison        : Format(tmp2, sizeof(tmp2), "%s Poison", tmp2);
			case ball_type_vampire       : Format(tmp2, sizeof(tmp2), "%s Vampirique", tmp2);
			case ball_type_paintball     : Format(tmp2, sizeof(tmp2), "%s PaintBall", tmp2);
			case ball_type_reflexive     : Format(tmp2, sizeof(tmp2), "%s Rebondissante", tmp2);
			case ball_type_explode       : Format(tmp2, sizeof(tmp2), "%s Explosive", tmp2);
			case ball_type_revitalisante : Format(tmp2, sizeof(tmp2), "%s Revitalisante", tmp2);
			case ball_type_nosteal       : Format(tmp2, sizeof(tmp2), "%s Anti-Vol", tmp2);
			case ball_type_notk          : Format(tmp2, sizeof(tmp2), "%s Anti-TK", tmp2);
		}
		
		Format(tmp2, sizeof(tmp2), "%s pour %d$", tmp2, (free?0:data[BM_Prix]));
		menu.AddItem(tmp, tmp2);
		
		position = rp_WeaponMenu_GetPosition(g_hBuyMenu);
	}

	menu.Display(client, 60);
	return;
}
public int Menu_BuyWeapon(Handle p_hMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("Menu_BuyWeapon");
	#endif
	if (p_oAction == MenuAction_Select) {
		
		char szMenu[64], buffer[2][32];
		if( GetMenuItem(p_hMenu, p_iParam2, szMenu, sizeof(szMenu)) ) {
			ExplodeString(szMenu, " ", buffer, sizeof(buffer), sizeof(buffer[]));
			
			char name[65];
			int data[BM_Max];
			DataPackPos position = view_as<DataPackPos>(StringToInt(buffer[0]));
			rp_WeaponMenu_Get(g_hBuyMenu, position, name, data);
			
			float vecOrigin[3];
			GetClientAbsOrigin(client, vecOrigin);
			
			if( GetVectorDistance(vecOrigin, view_as<float>({ 2550.8, 1663.1, -2015.96 })) > 40.0 )
				return 0;
			
			if( StringToInt(buffer[1]) == 1 ) {
				rp_SetClientInt(client, i_LastVolAmount, 100+data[BM_Prix]); 
				data[BM_Prix] = 0;
			}
			
			if( rp_GetClientInt(client, i_Bank) < data[BM_Prix] )
				return 0;
			
			Format(name, sizeof(name), "weapon_%s", name);			
			int wepid = GivePlayerItem(client, name);
			rp_SetWeaponBallType(wepid, view_as<enum_ball_type>(data[BM_Type]));
			if(data[BM_PvP] > 0)
				rp_SetWeaponGroupID(wepid, rp_GetClientGroupID(client));
			
			if( data[BM_Munition] != -1 ) {
				Weapon_SetPrimaryClip(wepid, data[BM_Munition]);
				Weapon_SetPrimaryAmmoCount(wepid, data[BM_Chargeur]);
				Client_SetWeaponPlayerAmmoEx(client, wepid, data[BM_Chargeur]);
			}
			
			rp_WeaponMenu_Delete(g_hBuyMenu, position);
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) - data[BM_Prix]);
			
			int rnd = rp_GetRandomCapital(1);			
			rp_SetJobCapital(1, RoundFloat(float(rp_GetJobCapital(1)) + float(data[BM_Prix]) * 0.75));
			rp_SetJobCapital(101, RoundFloat(float(rp_GetJobCapital(101)) + float(data[BM_Prix]) * 0.25));
			
			rp_SetJobCapital(rnd, rp_GetJobCapital(rnd) - data[BM_Prix]);
			LogToGame("[TSX-RP] [ITEM-VENDRE] %L a vendu 1 %s a %L", client, name, client);
			
			doRP_RP_OnMarchePolice(client, data[BM_Prix], rp_GetClientInt(client, i_LastVolAmount)-100);
		}
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hMenu);
	}
	return 0;
}

void explainJail(int client, int jailReason, int cop) {
	
	if( StrContains(g_szJailRaison[jailReason][jail_raison], "Garde ") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} La raison de votre garde à vue est que vous avez fait des actions interdites lors d'une perquisition; ou que vous étiez convoqué au Tribunal.");
		if( rp_GetClientInt(cop, i_Job) <= 7 )
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il est possible aussi qu'un haut gradé de la police vous ait fait plusieurs sommations vous demandant d'arrêter vos bétises.");
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Meurtre") == 0 ) {
		if( IsValidClient(rp_GetClientInt(client, i_LastKilled_Reverse)) )
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez tué {red}%N{default} en présence du policier %N. Que ce soit de la légitime défense, ou non {red}un meurtre reste illégal{default}.", rp_GetClientInt(client, i_LastKilled_Reverse), cop);
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Agression ") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez agressé un autre citoyen en présence du policier %N.", cop);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Que ce soit de la légitime défense ou non; que vous ayez fait des dégâts ou non: une agression reste une agression et est toujours punie de la même façon."); 
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Sachez que {red}cette peine vous libère automatiquement si aucune agression n'a été détectée{default} dans les 30 dernières secondes.");
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Intrusion ") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas entrer dans certains endroits sans autorisation.");
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Vol, ") == 0 ) {
		if( IsValidClient( rp_GetClientInt(client, i_LastVolTarget) ) )
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez volé %N en présence du policier %N.", rp_GetClientInt(client, i_LastVolTarget), cop);
		else
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas le droit de voler ou même essayer de voler que ce soit un citoyen, un distributeur ou même une voiture en présence d'un policier.");
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Fuite, ") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous vous êtes enfuit, ou vous avez désobéi à un ordre direct de %N. Cela est interdit.", cop);
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Insultes, ") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez insulté un citoyen ou un agent des forces de l'ordre.");
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Trafique ") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez posé des plants de drogue, imprimante(s) à faux billet, ou demandé à quelqu'un de vous aider pour une mission. Cela est interdit.");
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Nuisance ") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez fait trop de bruit sur un lieu public.");
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Tir dans ") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez tiré dans la rue ou sur un autre citoyen en présence du policier %N. Que vous ayez touché ou non votre cible, il est interdit de tirer dans la rue.", cop); 
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Conduite ") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez roulé sur le trottoire en présence du policier %N.", cop);
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Mutinerie, ") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes sorti de votre cellule sans autorisation. Un agent des forces de l'ordre s'est chargé de vous rajouter 6heures de prison supplémentaires.");
	}
	else if( StrContains(g_szJailRaison[jailReason][jail_raison], "Vol de voiture") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Après enquête, %N vous a mis en prison pour le vol de la voiture que vous conduisiez.");
	}
}
bool canWeaponBeAddedInPoliceStore(int weaponID) {
	int owner = GetEntPropEnt(weaponID, Prop_Send, "m_hPrevOwner");
	if( IsValidClient(owner) && (rp_GetClientJobID(owner) == 1 || rp_GetClientJobID(owner) == 101) )
		return false;
	owner = rp_WeaponMenu_GetOwner(weaponID);
	if( IsValidClient(owner) && (rp_GetClientJobID(owner) == 1 || rp_GetClientJobID(owner) == 101) )
		return false;
		
	return true;
}
