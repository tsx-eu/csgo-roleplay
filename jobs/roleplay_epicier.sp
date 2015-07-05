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
	name = "Jobs: EPICIER", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Epicier",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

Handle g_hCigarette[65];
int g_cBeam;

// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_cig", 		Cmd_ItemCigarette,		"RP-ITEM",	FCVAR_UNREGISTERED);	
	RegServerCmd("rp_item_sanandreas",	Cmd_ItemSanAndreas,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_needforspeed",Cmd_ItemNeedForSpeed,	"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_lessive",		Cmd_ItemLessive,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cafe",		Cmd_ItemCafe,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_crayons",		Cmd_ItemCrayons,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_map",			Cmd_ItemMaps,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_ruban",		Cmd_ItemRuban,			"RP-ITEM",	FCVAR_UNREGISTERED);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemCigarette(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCigarette");
	#endif
	
	char Arg1[32];
	GetCmdArg(1, Arg1, 31);
	int client = GetCmdArgInt(2);
	
	
	if( StrEqual(Arg1, "deg") ) {
		int item_id = GetCmdArgInt(args);
		if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_PEACEFULL ) {
			ITEM_CANCEL(client, item_id);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit où vous êtes.");
			return Plugin_Handled;
		}
		
		float origin[3];
		GetClientAbsOrigin(client, origin);
		origin[2] -= 1.0;
		rp_Effect_Push(origin, 500.0, 1000.0, client);
	}
	else if( StrEqual(Arg1, "flame") ) {
		UningiteEntity(client);
		for(float i=0.1; i<=30.0; i+= 0.50) {
			CreateTimer(i, Task_UningiteEntity, client);
		}
	}
	else if( StrEqual(Arg1, "light") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigGravity, 30.0);
	}
	else if( StrEqual(Arg1, "choco") ) {
		// Ne fait absolument rien.
	}
	else { // WHAT IS THAT KIND OF SORCELERY?
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 30.0);
	}
	
	rp_Effect_Smoke(client, 30.0);
	
	if( g_hCigarette[client] )
		delete g_hCigarette[client];
	
	g_hCigarette[client] = CreateTimer( 30.0, ItemStopCig, client);
	rp_SetClientBool(client, b_Smoking, true);
	
	return Plugin_Handled;
}
public Action Task_UningiteEntity(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Task_UningiteEntity");
	#endif
	UningiteEntity(client);
}
public Action ItemStopCig(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("ItemStopCig");
	#endif
	
	rp_SetClientBool(client, b_Smoking, false);
}
public Action fwdCigSpeed(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdCigSpeed");
	#endif
	speed += 0.15;
	
	return Plugin_Changed;
}
public Action fwdCigGravity(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdCigGravity");
	#endif
	gravity -= 0.15;
	
	return Plugin_Changed;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemRuban(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemRuban");
	#endif

	int color[4];
	color[0] = GetCmdArgInt(1);
	color[1] = GetCmdArgInt(2);
	color[2] = GetCmdArgInt(3);
	color[3] = 200;
	
	int client = GetCmdArgInt(4);
	int target = GetClientAimTarget(client, false);

	int item_id = GetCmdArgInt(args);
	
	if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	char classname[64];
	GetEdictClassname(target, classname, sizeof(classname));
	
	if( StrContains("chicken|player|weapon|prop_physics|", classname) == -1 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	if( !rp_IsEntitiesNear(client, target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	TE_SetupBeamFollow(target, g_cBeam, 0, 180.0, 4.0, 0.1, 5, color);
	TE_SendToAll();
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemSanAndreas(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemSanAndreas");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int wepid = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	char classname[64];
	
	if( !IsValidEntity(wepid) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	GetEdictClassname(wepid, classname, sizeof(classname));
		
	if( StrContains(classname, "weapon_bayonet") == 0 || StrContains(classname, "weapon_knife") == 0 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
		
	int ammo = Weapon_GetPrimaryClip(wepid);
	ammo += 1000; if( ammo > 5000 ) ammo = 5000;
	Weapon_SetPrimaryClip(wepid, ammo);
			
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre arme à maintenant %i balles", ammo);
	return Plugin_Handled;
}
public Action Cmd_ItemNeedForSpeed(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemNeedForSpeed");
	#endif
	
	int client = GetCmdArgInt(1);
	
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 60.0);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 10.0);
	
}
public Action Cmd_ItemLessive(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemLessive");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( rp_IsInPVP(client) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit en PvP.");
		return Plugin_Handled;
	}
	
	SDKHooks_TakeDamage(client, client, client, 5000.0);
	ForcePlayerSuicide(client);
	
	rp_ClientRespawn(client);
	return Plugin_Handled;
}
public Action Cmd_ItemCafe(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCafe");
	#endif
	
	int client = GetCmdArgInt(1);
	
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 10.0);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 10.0);
	
	rp_IncrementSuccess(client, success_list_cafeine);
}
public Action Cmd_ItemCrayons(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCrayons");
	#endif
	
	int client = GetCmdArgInt(1);
	
	bool crayon = rp_GetClientBool(client, b_Crayon);
	
	if( !crayon ) {
		rp_IncrementSuccess(client, success_list_rainbow);
	}
	
	rp_SetClientBool(client, b_Crayon, true);
}
public Action Cmd_ItemMaps(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemMaps");
	#endif
	
	int client = GetCmdArgInt(1);
	rp_SetClientBool(client, b_Map, true);
}
// ----------------------------------------------------------------------------
void UningiteEntity(int entity) {
	
	int ent = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
	if( IsValidEdict(ent) )
		SetEntPropFloat(ent, Prop_Data, "m_flLifetime", 0.0); 
}
