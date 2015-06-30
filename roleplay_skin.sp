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
#include <cstrike>
#include <sdkhooks>
#include <csgo_items>   // https://forums.alliedmods.net/showthread.php?t=243009
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MENU_TIME_DURATION 60

// TODO: Parser le fichier scripts/items/items_game.txt pour automatiser la liste des skins (+mettre en cache bien évidement !) cf: csgo_items.

public Plugin myinfo = {
	name = "Jobs: V. Skin", author = "KoSSoLaX",
	description = "RolePlay - Jobs: v. Skin",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_choseSkin",	Cmd_ItemChooseSkin,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_mask",		CmdItemMask,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_giveskin",			Cmd_ItemGiveSkin,		"RP-ITEM",  FCVAR_UNREGISTERED);
	RegServerCmd("rp_giveknife",		Cmd_GiveKnife,			"RP-ITEM",	FCVAR_UNREGISTERED);
}
// ----------------------------------------------------------------------------
public Action Cmd_GiveKnife(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_GiveKnife");
	#endif
	char arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	
	if( item_id > 0 ) {
		char tmp[128];
		rp_GetItemData(item_id, item_type_extra_cmd, tmp, sizeof(tmp));
		
		if( StrContains(tmp, "rp_giveknife weapon") == 0 ) {
			// Skin is valid applying permanantly.	
			rp_SetClientInt(client, i_KnifeSkin, item_id);
		}
	}
	
	int iWeapon = GetPlayerWeaponSlot(client, 2);
	if( iWeapon > 0 ) {
		RemovePlayerItem(client, iWeapon);
		RemoveEdict(iWeapon);
	}
	int iItem = GivePlayerItem(client, arg1);
	EquipPlayerWeapon(client, iItem);
	rp_SetClientWeaponSkin(client, iItem);
}
public Action Cmd_ItemGiveSkin(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemGiveSkin");
	#endif
	
	char arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	int client = GetCmdArgInt(2);
	int item = GetCmdArgInt(3); // WHAT? Ca sert à quoi déjà ça?
	int item_id = GetCmdArgInt(args);
	
	if( !IsModelPrecached(arg1) ) {
		if( PrecacheModel(arg1) == 0 ) {
			return;
		}
	}
	
	if( item_id > 0 ) {
		char tmp[128];
		rp_GetItemData(item_id, item_type_extra_cmd, tmp, sizeof(tmp));
		
		if( StrContains(tmp, "rp_giveskin models") == 0 ) {
			// Skin is valid applying permanantly.	
			rp_SetClientString(client, sz_Skin, arg1, strlen(arg1) + 1);
			rp_IncrementSuccess(client, success_list_vetement);
		}
	}
	
	if( GetClientTeam(client) == CS_TEAM_T ) {
		if( item > 0 ) {
			ServerCommand("sm_effect_setmodel \"%i\" \"%s\"", client, arg1);
			rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, 1.1);
		}
		else {
			SetEntityModel(client, arg1);
		}
	}
	
}
public Action fwdFrozen(int client, float& speed, float& gravity) {
	speed = 0.0;
	return Plugin_Stop;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemChooseSkin(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemChooseSkin");
	#endif
	
	CreateTimer(0.25, taskChooseSkin, GetCmdArgInt(1));
}
public Action taskChooseSkin(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("taskChooseSkin");
	#endif
	
	OpenItemSkin(client, 0);
}
void OpenItemSkin(int client, int page=0) {
	#if defined DEBUG
	PrintToServer("OpenItemSkin");
	#endif
	
	Handle menu = CreateMenu(eventChooseSkin);
	SetMenuTitle(menu, "Selection skin d'arme:");
	
	char tmp[12], tmp2[128];
	for(int i=0; i<512; i++) {
		rp_GetWeaponSkinData(i, skin_id, tmp, sizeof(tmp));
		if( strlen(tmp) <= 0 )
			continue;
		
		rp_GetWeaponSkinData(i, skin_name, tmp2, sizeof(tmp2));
		AddMenuItem(menu, tmp, tmp2);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenuAtItem(menu, client, page, MENU_TIME_DURATION*3);
}
public int eventChooseSkin(Handle menu, MenuAction action, int client, int param ) {
	#if defined DEBUG
	PrintToServer("eventChooseSkin");
	#endif
	
	if( action == MenuAction_Select ) {
		char szMenuItem[64], classname[64];
		
		if( GetMenuItem(menu, param, szMenuItem, sizeof(szMenuItem)) ) {

			rp_SetClientInt(client, i_Skin, StringToInt(szMenuItem));
			
			int windex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int index = GetEntProp(windex, Prop_Send, "m_iItemDefinitionIndex");
			CSGO_GetItemDefinitionNameByIndex(index, classname, sizeof(classname));
			
			int ammo = Weapon_GetPrimaryClip(windex);
			int ammo1;
			Client_GetWeaponPlayerAmmoEx(client, windex, ammo1);
			
			enum_ball_type t = rp_GetWeaponBallType(windex);
			int g = rp_GetWeaponGroupID(windex);
			bool s = rp_GetWeaponStorage(windex);
			
			RemovePlayerItem(client, windex);
			AcceptEntityInput(windex, "Kill");
			
			int entity = GivePlayerItem(client, classname);
			EquipPlayerWeapon(client, entity);
			rp_SetClientWeaponSkin(client, entity);
			
			Weapon_SetPrimaryClip(entity, ammo);
			Client_SetWeaponPlayerAmmoEx(client, entity, ammo1);
			
			rp_SetWeaponGroupID(entity, g);
			rp_SetWeaponBallType(entity, t);
			rp_SetWeaponStorage(entity, s);
			
			OpenItemSkin(client, RoundToFloor(param/6.0) * 6);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
// ----------------------------------------------------------------------------
public Action CmdItemMask(int args) {
	#if defined DEBUG
	PrintToServer("CmdItemMask");
	#endif
	char arg1[12];
	
	GetCmdArg(1, arg1, sizeof(arg1));	int client = StringToInt(arg1);
	int item_id = GetCmdArgInt(args);
	
	
	if( rp_GetClientInt(client, i_Mask) != 0) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous portez déjà un masque.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	if(rp_GetClientJobID(client) == 1 || rp_GetClientJobID(client) == 101){
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit aux forces de l'ordre.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	int rand = Math_GetRandomInt(1, 7);
	char model[128];
		
	switch(rand) {
		case 1: Entity_SetModel(client, "models/player/tm_separatist.mdl");
		case 2: Entity_SetModel(client, "models/player/tm_professional.mdl");
		case 3: Entity_SetModel(client, "models/player/tm_pirate.mdl");
		case 4: Entity_SetModel(client, "models/player/tm_phoenix.mdl");
		case 5: Entity_SetModel(client, "models/player/tm_leet_varianta.mdl");
		case 6: Entity_SetModel(client, "models/player/tm_balkan_varianta.mdl");
		case 7: Entity_SetModel(client, "models/player/tm_anarchist.mdl");
	}
	rand = Math_GetRandomInt(1, 7);
	switch(rand) {
		case 1: Format(model, sizeof(model), "models/player/holiday/facemasks/facemask_skull.mdl");
		case 2: Format(model, sizeof(model), "models/player/holiday/facemasks/facemask_wolf.mdl");
		case 3: Format(model, sizeof(model), "models/player/holiday/facemasks/facemask_tiki.mdl");
		case 4: Format(model, sizeof(model), "models/player/holiday/facemasks/facemask_samurai.mdl");
		case 5: Format(model, sizeof(model), "models/player/holiday/facemasks/facemask_hoxton.mdl");
		case 6: Format(model, sizeof(model), "models/player/holiday/facemasks/facemask_dallas.mdl");
		case 7: Format(model, sizeof(model), "models/player/holiday/facemasks/facemask_chains.mdl");
	}
	
	int ent = CreateEntityByName("prop_dynamic");
	DispatchKeyValue(ent, "model", model);
	DispatchSpawn(ent);
	
	Entity_SetModel(ent, model);
	Entity_SetOwner(ent, client);
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, client);
		
	SetVariantString("facemask");
	AcceptEntityInput(ent, "SetParentAttachment");
	
	SDKHook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
	
	rp_SetClientInt(client, i_Mask, ent);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous portez maintenant un masque.");
		
	return Plugin_Handled;
}
public Action Hook_SetTransmit(int entity, int client) {
	if( Entity_GetOwner(entity) == client ) 
		return Plugin_Handled;
	return Plugin_Continue;
}



