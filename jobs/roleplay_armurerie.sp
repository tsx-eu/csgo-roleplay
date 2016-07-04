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
#define MAX_GROUPS				150

public Plugin myinfo = {
	name = "Jobs: Armurerier", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Armurerier",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

float vecNull[3];
int g_cBeam;
int g_iClientColor[65][4];
// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	RegServerCmd("rp_giveitem",			Cmd_GiveItem,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_giveitem_pvp",		Cmd_GiveItemPvP,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_balltype",	Cmd_ItemBallType,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_redraw",		Cmd_ItemRedraw,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_sanandreas",	Cmd_ItemSanAndreas,		"RP-ITEM",	FCVAR_UNREGISTERED);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
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
	
	if( StrEqual(Arg1, "weapon_usp") || StrEqual(Arg1, "weapon_p228") || StrEqual(Arg1, "weapon_m3") || StrEqual(Arg1, "weapon_galil") || StrEqual(Arg1, "weapon_scout") )
		return Plugin_Handled;
	if( StrEqual(Arg1, "weapon_sg552") || StrEqual(Arg1, "weapon_sg550") || StrEqual(Arg1, "weapon_tmp") || StrEqual(Arg1, "weapon_mp5navy") )
		return Plugin_Handled;
	
	
	int client = GetCmdArgInt(2);
	GivePlayerItem(client, Arg1);
	return Plugin_Handled;
}
public Action Cmd_GiveItemPvP(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_GiveItemPvP");
	#endif
	
	char Arg1[64];
	GetCmdArg(1, Arg1, sizeof(Arg1));
	
	int client = GetCmdArgInt(2);
	int wpnID = GivePlayerItem(client, Arg1);	
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
	
	if( rp_GetWeaponBallType(wepid) == ball_type_braquage ) {
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
	else if( StrEqual(arg1, "revitalisante") ) {
		rp_SetWeaponBallType(wepid, ball_type_revitalisante);
	}
	else if( StrEqual(arg1, "nosteal") ) {
		rp_SetWeaponBallType(wepid, ball_type_nosteal);
	}
	else if( StrEqual(arg1, "notk") ) {
		rp_SetWeaponBallType(wepid, ball_type_notk);
	}
	
	return Plugin_Handled;
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_PostTakeDamageWeapon, fwdWeapon);
	rp_HookEvent(client, RP_OnPlayerBuild, fwdOnPlayerBuild);
}
public Action fwdOnPlayerBuild(int client, float& cooldown){
	if( rp_GetClientJobID(client) != 111 )
		return Plugin_Continue;

	int wep_id = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	char wep_name[32];
	GetEdictClassname(wep_id, wep_name, 31);
	if( StrContains(wep_name, "weapon_bayonet") == 0 || StrContains(wep_name, "weapon_knife") == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez prendre une arme en main pour la modifier.");
		return Plugin_Handled;
	}

	Handle menu = CreateMenu(ModifyWeapon);
	SetMenuTitle(menu, "Modifier l'arme");
	AddMenuItem(menu, "reload_50", "Recharger l'arme (50$)");
	AddMenuItem(menu, "sanandreas_150", "Ajouter 1000 balles (150$)");

	if(rp_GetWeaponGroupID(wep_id) != 0)
		AddMenuItem(menu, "pvp_250", "Transformer en arme PvP (250$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "pvp_250", "Transformer en arme PvP (250$)");

	if(rp_GetWeaponBallType(wep_id) == ball_type_fire)
		AddMenuItem(menu, "fire_250", "Ajouter des cartouches incendiaires (250$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "fire_250", "Ajouter des cartouches incendiaires (250$)");

	if(rp_GetWeaponBallType(wep_id) == ball_type_caoutchouc)
		AddMenuItem(menu, "caoutchouc_200", "Ajouter des cartouches en caoutchouc (200$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "caoutchouc_200", "Ajouter des cartouches en caoutchouc (200$)");

	if(rp_GetWeaponBallType(wep_id) == ball_type_poison)
		AddMenuItem(menu, "poison_200", "Ajouter des cartouches empoisonnées (200$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "poison_200", "Ajouter des cartouches empoisonnées (200$)");

	if(rp_GetWeaponBallType(wep_id) == ball_type_vampire)
		AddMenuItem(menu, "vampire_200", "Ajouter des cartouches vampiriques (200$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "vampire_200", "Ajouter des cartouches vampiriques (200$)");

	if(rp_GetWeaponBallType(wep_id) == ball_type_reflexive)
		AddMenuItem(menu, "reflexive_200", "Ajouter des cartouches rebondissantes (200$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "reflexive_200", "Ajouter des cartouches rebondissantes (200$)");

	if(rp_GetWeaponBallType(wep_id) == ball_type_explode)
		AddMenuItem(menu, "explode_300", "Ajouter des cartouches explosives (300$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "explode_300", "Ajouter des cartouches explosives (300$)");

	if(rp_GetWeaponBallType(wep_id) == ball_type_revitalisante)
		AddMenuItem(menu, "revitalisante_200", "Ajouter des cartouches revitalisantes (200$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "revitalisante_200", "Ajouter des cartouches revitalisantes (200$)");

	if(rp_GetWeaponBallType(wep_id) == ball_type_paintball)
		AddMenuItem(menu, "paintball_50", "Ajouter des cartouches de paintball (50$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "paintball_50", "Ajouter des cartouches de paintball (50$)");

	if(rp_GetWeaponBallType(wep_id) == ball_type_nosteal)
		AddMenuItem(menu, "nosteal_75", "Ajouter des cartouches antivol (75$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "nosteal_75", "Ajouter des cartouches antivol (75$)");

	if(rp_GetWeaponBallType(wep_id) == ball_type_notk)
		AddMenuItem(menu, "notk_50", "Ajouter des cartouches anti team-kill (50$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "notk_50", "Ajouter des cartouches anti team-kill (50$)");

	DisplayMenu(menu, client, 60);
	cooldown = 5.0;
	
	return Plugin_Stop;
}

public int ModifyWeapon(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("ModifyWeapon Menu");
	#endif

	if (p_oAction == MenuAction_Select) {
		char szMenuItem[32];
		if (GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem))){

			char data[2][32];
			ExplodeString(szMenuItem, "_", data, sizeof(data), sizeof(data[]));

			char type[32];
			strcopy(type, 31, data[0]);
			int price = StringToInt(data[1]);
			int wep_id = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			char wep_name[32];
			GetEdictClassname(wep_id, wep_name, 31);

			if( StrContains(wep_name, "weapon_bayonet") == 0 || StrContains(wep_name, "weapon_knife") == 0 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez prendre une arme en main pour la modifier");
				return;
			}

			if(StrEqual(type, "pvp")){
				Handle menupvp = CreateMenu(ModifyWeaponPVP);
				char tmp[64], tmp2[64];
				SetMenuTitle(menupvp, "A quel groupe attribuer l'arme?");
				for(int i=1; i<MAX_GROUPS; i+=10){
					for(int j=1;j< MAXPLAYERS+1;j++){
						if( !IsValidClient(j) )
							continue;
						if(rp_GetClientGroupID(j)==i){
							rp_GetGroupData(i, group_type_name, tmp, 63);
							Format(tmp2,63,"%i_%i",i,price);
							AddMenuItem(menupvp, tmp2, tmp);
							break;
						}
					}
				}
				DisplayMenu(menupvp, client, 60);
			}
			else{
				if((rp_GetClientInt(client, i_Bank)+rp_GetClientInt(client, i_Money)) >= price){
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money)-price);
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} La modification a été appliquée à votre arme.");	
					rp_SetClientStat(client, i_TotalBuild, rp_GetClientStat(client, i_TotalBuild)+1);
				}
				else{
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas assez d'argent.");
					return;
				}

				if(StrEqual(type, "fire")){
					rp_SetWeaponBallType(wep_id, ball_type_fire);
				}
				else if(StrEqual(type, "caoutchouc")){
					rp_SetWeaponBallType(wep_id, ball_type_caoutchouc);
				}
				else if(StrEqual(type, "poison")){
					rp_SetWeaponBallType(wep_id, ball_type_poison);
				}
				else if(StrEqual(type, "vampire")){
					rp_SetWeaponBallType(wep_id, ball_type_vampire);
				}
				else if(StrEqual(type, "reflexive")){
					rp_SetWeaponBallType(wep_id, ball_type_reflexive);
				}
				else if(StrEqual(type, "explode")){
					rp_SetWeaponBallType(wep_id, ball_type_explode);
				}
				else if(StrEqual(type, "revitalisante")){
					rp_SetWeaponBallType(wep_id, ball_type_revitalisante);
				}
				else if(StrEqual(type, "paintball")){
					rp_SetWeaponBallType(wep_id, ball_type_paintball);
				}
				else if(StrEqual(type, "nosteal")){
					rp_SetWeaponBallType(wep_id, ball_type_nosteal);
				}
				else if(StrEqual(type, "notk")){
					rp_SetWeaponBallType(wep_id, ball_type_notk);
				}
				else if(StrEqual(type, "reload")){
					ServerCommand("rp_item_redraw %i 74", client);
				}
				else if(StrEqual(type, "sanandreas")){
					int ammo = Weapon_GetPrimaryClip(wep_id);
					if( ammo >= 150 ) {
						CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre arme a déjà un San Andreas, il vous reste %d balles dans le chargeur.", ammo);
						return;
					}
					ammo += 1000; if( ammo > 5000 ) ammo = 5000;
					Weapon_SetPrimaryClip(wep_id, ammo);
					SDKHook(wep_id, SDKHook_Reload, OnWeaponReload);
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre arme possède maintenant %i balles", ammo);
				}
				rp_SetJobCapital( 111, rp_GetJobCapital(111)+price );
				FakeClientCommand(client, "say /build");

			}
		}
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hItemMenu);
	}
}

public Action OnWeaponReload(int wepid) {
	static float cache[65];
	
	int ammo = Weapon_GetPrimaryClip(wepid);
	if( ammo >= 150 ) {
		int client = Weapon_GetOwner(wepid);
		
		if( cache[client] < GetGameTime() ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre arme a un San Andreas, il vous reste %d balles dans le chargeur.", ammo);
			cache[client] = GetGameTime() + 1.0;
		}
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public int ModifyWeaponPVP(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2){
	#if defined DEBUG
	PrintToServer("ModifyWeaponPVP");
	#endif

	if (p_oAction == MenuAction_Select) {
		char szMenuItem[32];
		if (GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem))){

			char data[2][32];
			ExplodeString(szMenuItem, "_", data, sizeof(data), sizeof(data[]));

			int groupid = StringToInt(data[0]);
			int price = StringToInt(data[1]);
			int wep_id = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			char wep_name[32];
			GetEdictClassname(wep_id, wep_name, 31);

			if( StrContains(wep_name, "weapon_bayonet") == 0 || StrContains(wep_name, "weapon_knife") == 0 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez prendre une arme en main pour la modifier.");
				return;
			}

			if((rp_GetClientInt(client, i_Bank)+rp_GetClientInt(client, i_Money)) >= price){
				rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money)-price);
				rp_SetJobCapital( 111, rp_GetJobCapital(111)+price );
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} La modification a été appliquée à votre arme.");	
			}
			else{
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas assez d'argent.");
				return;
			}

			rp_SetWeaponGroupID(wep_id, groupid);
		}
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hItemMenu);
	}
}

public Action fwdWeapon(int victim, int attacker, float &damage, int wepID, float pos[3]) {
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
				
				rp_SetClientFloat(victim, fl_FrozenTime, GetGameTime() + 1.5);
				if(!rp_GetClientBool(victim, ch_Yeux))
					ServerCommand("sm_effect_flash %d 1.5 180", victim);
			}
			else {
				if( !rp_ClientFloodTriggered(attacker, victim, fd_flash) ) {
					rp_ClientFloodIncrement(attacker, victim, fd_flash, 1.0);
					
					rp_SetClientFloat(victim, fl_FrozenTime, GetGameTime() + 1.5);
					if(!rp_GetClientBool(victim, ch_Yeux))
						ServerCommand("sm_effect_flash %d 1.5 180", victim);
				}
			}
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
			
			g_iClientColor[victim][0] = Math_GetRandomInt(50, 255);
			g_iClientColor[victim][1] = Math_GetRandomInt(50, 255);
			g_iClientColor[victim][2] = Math_GetRandomInt(50, 255);
			g_iClientColor[victim][3] = Math_GetRandomInt(100, 240);

			rp_HookEvent(victim, RP_PreHUDColorize, fwdColorize, 5.0);
		}
		case ball_type_reflexive: {
			damage = 0.9;
		}
		case ball_type_explode: {
			damage *= 0.8;
		}
		case ball_type_revitalisante: {
			int current = GetClientHealth(victim);
			if( current < 500 ) {
				current += RoundToCeil(damage*0.1); // On rend environ 10% des degats infligés sous forme de vie

				if( current > 500 )
					current = 500;

				SetEntityHealth(victim, current);
				
				float vecOrigin[3], vecOrigin2[3];
				GetClientEyePosition(attacker, vecOrigin);
				GetClientEyePosition(victim, vecOrigin2);
				
				vecOrigin[2] -= 20.0; vecOrigin2[2] -= 20.0;
				
				TE_SetupBeamPoints(vecOrigin, vecOrigin2, g_cBeam, 0, 0, 0, 0.1, 10.0, 10.0, 0, 10.0, {0, 255, 0, 250}, 10); // Laser vert entre les deux
				TE_SendToAll();
			}
			damage = 0.0; // L'arme ne fait pas de dégats
		}
		case ball_type_notk: {
			if(rp_GetClientGroupID(attacker) != rp_GetClientGroupID(victim)){
				changed = false;
			}
			else{
				damage *= 0.0;
			}
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
public Action fwdColorize(int client, int color[4]) {
	for (int i = 0; i < 4; i++)
		color[i] += g_iClientColor[client][i];
	return Plugin_Changed;
}
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
	rp_SetWeaponBallType(wep_id, wep_type);
	rp_SetWeaponGroupID(wep_id, g);
	rp_SetWeaponStorage(wep_id, s);
	
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
	if( ammo >= 5000 ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous aviez déjà 5000 balles.");
		return Plugin_Handled;
	}
	ammo += 1000;
	if( ammo > 5000 )
		ammo = 5000;
	Weapon_SetPrimaryClip(wepid, ammo);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre arme a maintenant %i balles", ammo);
	
	SDKHook(wepid, SDKHook_Reload, OnWeaponReload);
	return Plugin_Handled;
}
