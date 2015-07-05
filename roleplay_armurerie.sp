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
#include <csgo_items>   // https://forums.alliedmods.net/showthread.php?t=243009
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib

#define __LAST_REV__ 		"v:0.1.1"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG

public Plugin myinfo = {
	name = "Jobs: Armurerier", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Armurerier",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

float vecNull[3];
int g_cBeam;
// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_giveitem",			Cmd_GiveItem,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_giveitem_pvp",		Cmd_GiveItemPvP,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_balltype",	Cmd_ItemBallType,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_redraw",		Cmd_ItemRedraw,			"RP-ITEM",	FCVAR_UNREGISTERED);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}
// ----------------------------------------------------------------------------
public Action Cmd_GiveItem(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_GiveItem");
	#endif
	
	char Arg1[64];
	GetCmdArg(1, Arg1, sizeof(Arg1));
	
	int client = GetCmdArgInt(2);
	int wpnID = GivePlayerItem(client, Arg1);
	rp_SetClientWeaponSkin(client, wpnID);
}
public Action Cmd_GiveItemPvP(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_GiveItemPvP");
	#endif
	
	char Arg1[64];
	GetCmdArg(1, Arg1, sizeof(Arg1));
	
	int client = GetCmdArgInt(2);
	int wpnID = GivePlayerItem(client, Arg1);
	
	rp_SetClientWeaponSkin(client, wpnID);
	
	int group = rp_GetClientGroupID(client);
	rp_SetWeaponGroupID(wpnID, group);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemBallType(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemBallType");
	#endif
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int client = GetCmdArgInt(2);
	int wepid = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int item_id = GetCmdArgInt(args);
	
	
	if( !IsValidEntity(wepid) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	char classname[64];
	GetEdictClassname(wepid, classname, sizeof(classname));
	if( StrContains(classname, "weapon_bayonet") == 0 || StrContains(classname, "weapon_knife") == 0 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	if( StrEqual(arg1, "fire") ) {
		rp_SetWeaponBallType(wepid, ball_type_fire);
	}
	else if( StrEqual(arg1, "caoutchouc") ) {
		rp_SetWeaponBallType(wepid, ball_type_caoutchouc);
	}
	else if( StrEqual(arg1, "paintball") ) {
		rp_SetWeaponBallType(wepid, ball_type_paintball);
	}
	else if( StrEqual(arg1, "poison") ) {
		rp_SetWeaponBallType(wepid, ball_type_poison);
	}
	else if( StrEqual(arg1, "vampire") ) {
		rp_SetWeaponBallType(wepid, ball_type_vampire);
	}
	else if( StrEqual(arg1, "reflex") ) {
		rp_SetWeaponBallType(wepid, ball_type_reflexive);
	}
	else if( StrEqual(arg1, "explode") ) {
		rp_SetWeaponBallType(wepid, ball_type_explode);
	}
	
	return Plugin_Handled;
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_PostTakeDamageWeapon, fwdWeapon);
}
public void OnClientDisconnect(int client) {
	rp_UnhookEvent(client, RP_PostTakeDamageWeapon, fwdWeapon);
}
public Action fwdWeapon(int victim, int attacker, float &damage, int wepID) {
	bool changed = true;
	
	switch( rp_GetWeaponBallType(wepID) ) {
		case ball_type_fire: {
			rp_ClientIgnite(victim, 10.0, attacker);
			changed = false;
		}
		case ball_type_caoutchouc: {
			damage *= 0.0;
			if( rp_IsInPVP(victim) ) {
				TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vecNull);
				damage *= 0.5;
			}
			
			rp_SetClientFloat(victim, fl_FrozenTime, GetGameTime() + 1.5);
			ServerCommand("sm_effect_flash %d 1.5 180", victim);
		}
		case ball_type_poison: {
			damage *= 0.66;
			rp_ClientPoison(victim, 30.0, attacker);
		}
		case ball_type_vampire: {
			damage *= 0.75;
			int current = GetClientHealth(attacker);
			if( current < 500 ) {
				current += RoundToFloor(damage*0.2);

				if( current > 500 )
					current = 500;

				SetEntityHealth(attacker, current);
				
				float vecOrigin[3], vecOrigin2[3];
				GetClientEyePosition(attacker, vecOrigin);
				GetClientEyePosition(victim, vecOrigin2);
				
				vecOrigin[2] -= 20.0; vecOrigin2[2] -= 20.0;
				
				TE_SetupBeamPoints(vecOrigin, vecOrigin2, g_cBeam, 0, 0, 0, 0.1, 10.0, 10.0, 0, 10.0, {250, 50, 50, 250}, 10);
				TE_SendToAll();
			}
		}
		case ball_type_paintball: {
			damage *= 1.0;
		}
		case ball_type_reflexive: {
			damage = 0.9;
		}
		case ball_type_explode: {
			damage *= 0.8;
		}
		default: {
			changed = false;
		}
	}
	
	if( changed )
		return Plugin_Changed;
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------

public Action Cmd_ItemRedraw(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemRedraw");
	#endif
	int client = GetCmdArgInt(1);
	
	int wep_id = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int item_id = GetCmdArgInt(args);
	char classname[64];
	
	if( IsValidEntity(wep_id) ) {
		GetEdictClassname(wep_id, classname, sizeof(classname));
		if( StrContains(classname, "weapon_bayonet") == 0 || StrContains(classname, "weapon_knife") == 0 ) {
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
	}
	
	int index = GetEntProp(wep_id, Prop_Send, "m_iItemDefinitionIndex");
	CSGO_GetItemDefinitionNameByIndex(index, classname, sizeof(classname));
	
	enum_ball_type wep_type = rp_GetWeaponBallType(wep_id);
	int g = rp_GetWeaponGroupID(wep_id);
	bool s = rp_GetWeaponStorage(wep_id);
	
	RemovePlayerItem(client, wep_id );
	RemoveEdict( wep_id );
	
	wep_id = GivePlayerItem(client, classname);
	rp_SetClientWeaponSkin(client, wep_id);
	rp_SetWeaponBallType(wep_id, wep_type);
	rp_SetWeaponGroupID(wep_id, g);
	rp_SetWeaponStorage(wep_id, s);
	
	return Plugin_Handled;
}
