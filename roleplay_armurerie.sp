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
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG

public Plugin myinfo = {
	name = "Jobs: Armurerier", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Armurerier",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};


// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_giveitem",			Cmd_GiveItem,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_giveitem_pvp",		Cmd_GiveItemPvP,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_balltype",	Cmd_ItemBallType,		"RP-ITEM",	FCVAR_UNREGISTERED);
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
	rp_SetWeaponSkin(wpnID, client);
}
public Action Cmd_GiveItemPvP(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_GiveItemPvP");
	#endif
	
	char Arg1[64];
	GetCmdArg(1, Arg1, sizeof(Arg1));
	
	int client = GetCmdArgInt(2);
	int wpnID = GivePlayerItem(client, Arg1);
	
	rp_SetWeaponSkin(wpnID, client);
	
	int group = rp_GetClientGroupID(client);
	rp_SetWeaponGroupID(wpnID, group);
}


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