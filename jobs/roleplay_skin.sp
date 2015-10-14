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
#define	ZONE_CABINE 284
#define MENU_TIME_DURATION 60

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
	
	RegServerCmd("rp_skin_separatist",	Cmd_ItemSeparatist);
	RegServerCmd("rp_skin_professional",Cmd_ItemProfessional);
	RegServerCmd("rp_skin_pirate",		Cmd_ItemPirate);
	RegServerCmd("rp_skin_phoenix",		Cmd_ItemPhoenix);
	RegServerCmd("rp_skin_leet",		Cmd_ItemLeet);
	RegServerCmd("rp_skin_balkan",		Cmd_ItemBalkan);
	RegServerCmd("rp_skin_anarchist",	Cmd_ItemAnarchist);

	for (int i = 1; i <= MaxClients; i++) 
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerUse, fwdUse);
}
public Action Cmd_ItemAnarchist(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemLeet");
	#endif
	int client = GetCmdArgInt(1);
	
	CreateTimer(0.25, task_ItemAnarchist, client);
}
public Action task_ItemAnarchist(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("task_ItemAnarchist");
	#endif
	
	Handle menu = CreateMenu(MenuSetSkin);
	SetMenuTitle(menu, "Choisissez un skin:");
	
	AddMenuItem(menu, "models/player/tm_anarchist.mdl", 			"Anarchist");
	AddMenuItem(menu, "models/player/tm_anarchist_varianta.mdl", 	"Anarchist - A");
	AddMenuItem(menu, "models/player/tm_anarchist_variantb.mdl",	"Anarchist - B");
	AddMenuItem(menu, "models/player/tm_anarchist_variantc.mdl", 	"Anarchist - C");
	AddMenuItem(menu, "models/player/tm_anarchist_variantd.mdl", 	"Anarchist - D");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
	
	return Plugin_Handled;
}
public Action Cmd_ItemBalkan(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemLeet");
	#endif
	int client = GetCmdArgInt(1);
	
	CreateTimer(0.25, task_ItemBalkan, client);
}
public Action task_ItemBalkan(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("task_ItemBalkan");
	#endif
	
	Handle menu = CreateMenu(MenuSetSkin);
	SetMenuTitle(menu, "Choisissez un skin:");
	
	AddMenuItem(menu, "models/player/tm_balkan_varianta.mdl", 	"Balkan");
	AddMenuItem(menu, "models/player/tm_balkan_variantb.mdl", 	"Balkan - A");
	AddMenuItem(menu, "models/player/tm_balkan_variantc.mdl",	"Balkan - B");
	AddMenuItem(menu, "models/player/tm_balkan_variantd.mdl", 	"Balkan - C");
	AddMenuItem(menu, "models/player/tm_balkan_variante.mdl", 	"Balkan - D");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
	
	return Plugin_Handled;
}
public Action Cmd_ItemLeet(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemLeet");
	#endif
	int client = GetCmdArgInt(1);
	
	CreateTimer(0.25, task_ItemLeet, client);
}
public Action task_ItemLeet(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("task_ItemLeet");
	#endif
	
	Handle menu = CreateMenu(MenuSetSkin);
	SetMenuTitle(menu, "Choisissez un skin:");
	
	AddMenuItem(menu, "models/player/tm_leet_varianta.mdl", 	"Phoenix");
	AddMenuItem(menu, "models/player/tm_leet_variantb.mdl", 	"Phoenix - A");
	AddMenuItem(menu, "models/player/tm_leet_variantc.mdl",		"Phoenix - B");
	AddMenuItem(menu, "models/player/tm_leet_variantd.mdl", 	"Phoenix - C");
	AddMenuItem(menu, "models/player/tm_leet_variante.mdl", 	"Phoenix - D");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
	
	return Plugin_Handled;
}
public Action Cmd_ItemPhoenix(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPhoenix");
	#endif
	int client = GetCmdArgInt(1);
	
	CreateTimer(0.25, task_ItemPhoenix, client);
}
public Action task_ItemPhoenix(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("task_ItemPhoenix");
	#endif
	
	Handle menu = CreateMenu(MenuSetSkin);
	SetMenuTitle(menu, "Choisissez un skin:");
	
	AddMenuItem(menu, "models/player/tm_phoenix.mdl", 			"Phoenix");
	AddMenuItem(menu, "models/player/tm_phoenix_varianta.mdl", 	"Phoenix - A");
	AddMenuItem(menu, "models/player/tm_phoenix_variantb.mdl",	"Phoenix - B");
	AddMenuItem(menu, "models/player/tm_phoenix_variantc.mdl", 	"Phoenix - C");
	AddMenuItem(menu, "models/player/tm_phoenix_variantd.mdl", 	"Phoenix - D");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
	
	return Plugin_Handled;
}
public Action Cmd_ItemPirate(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPirate");
	#endif
	int client = GetCmdArgInt(1);
	
	CreateTimer(0.25, task_ItemPirate, client);
}
public Action task_ItemPirate(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("task_ItemPirate");
	#endif
	
	Handle menu = CreateMenu(MenuSetSkin);
	SetMenuTitle(menu, "Choisissez un skin:");
	
	AddMenuItem(menu, "models/player/tm_pirate.mdl", 			"Pirate");
	AddMenuItem(menu, "models/player/tm_pirate_varianta.mdl", 	"Pirate - A");
	AddMenuItem(menu, "models/player/tm_pirate_variantb.mdl",	"Pirate - B");
	AddMenuItem(menu, "models/player/tm_pirate_variantc.mdl", 	"Pirate - C");
	AddMenuItem(menu, "models/player/tm_pirate_variantd.mdl", 	"Pirate - D");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
	
	return Plugin_Handled;
}
public Action Cmd_ItemProfessional(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemProfessional");
	#endif
	int client = GetCmdArgInt(1);
	
	CreateTimer(0.25, task_ItemProfessional, client);
}
public Action task_ItemProfessional(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("task_Cmd_ItemSeparatist");
	#endif
	
	Handle menu = CreateMenu(MenuSetSkin);
	SetMenuTitle(menu, "Choisissez un skin:");
	
	AddMenuItem(menu, "models/player/tm_professional.mdl", 			"Professional");
	AddMenuItem(menu, "models/player/tm_professional_var1.mdl", 	"Professional - A");
	AddMenuItem(menu, "models/player/tm_professional_var2.mdl",		"Professional - B");
	AddMenuItem(menu, "models/player/tm_professional_var3.mdl", 	"Professional - C");
	AddMenuItem(menu, "models/player/tm_professional_var4.mdl", 	"Professional - D");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
	
	return Plugin_Handled;
}
public Action Cmd_ItemSeparatist(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemSeparatist");
	#endif
	int client = GetCmdArgInt(1);
	
	CreateTimer(0.25, task_ItemSeparatist, client);
}
public Action task_ItemSeparatist(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("task_Cmd_ItemSeparatist");
	#endif
	
	Handle menu = CreateMenu(MenuSetSkin);
	SetMenuTitle(menu, "Choisissez un skin:");
	
	AddMenuItem(menu, "models/player/tm_separatist.mdl", 			"Séparatist");
	AddMenuItem(menu, "models/player/tm_separatist_varianta.mdl", 	"Séparatist - A");
	AddMenuItem(menu, "models/player/tm_separatist_variantb.mdl",	"Séparatist - B");
	AddMenuItem(menu, "models/player/tm_separatist_variantc.mdl", 	"Séparatist - C");
	AddMenuItem(menu, "models/player/tm_separatist_variantd.mdl", 	"Séparatist - D");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
	
	return Plugin_Handled;
}
public int MenuSetSkin(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("MenuSetSkin");
	#endif
	if( action == MenuAction_Select ) {
		char options[128];
		GetMenuItem(menu, param2, options, sizeof(options));
		ServerCommand("rp_giveskin %s %d", options, client);
		rp_SetClientString(client, sz_Skin, options, strlen(options) + 1);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
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
		char szMenuItem[64];
		
		if( GetMenuItem(menu, param, szMenuItem, sizeof(szMenuItem)) ) {

			rp_SetClientInt(client, i_Skin, StringToInt(szMenuItem));
			
			int windex = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			rp_ClientSwitchWeapon(client, windex);
			
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
	if( Entity_GetOwner(entity) == client && rp_GetClientInt(client, i_ThirdPerson) == 0 ) 
		return Plugin_Handled;
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action fwdUse(int client) {
	int zoneid = rp_GetPlayerZone(client);
	if(zoneid != ZONE_CABINE)
		return Plugin_Continue;

	Handle menu = CreateMenu(MenuTrySkin);
	SetMenuTitle(menu, "Selection du skin à essayer:");

	AddMenuItem(menu, "models/player/custom/hitman/hitman.mdl", 	"Hitman");
	AddMenuItem(menu, "models/player/custom/max/max.mdl", 			"Max");
	AddMenuItem(menu, "models/player/custom/johnny/johnny.mdl", 	"Johnny");
	AddMenuItem(menu, "models/player/kuristaja/duke/duke.mdl", 		"Duke Nukem");
	
	AddMenuItem(menu, "models/player/custom/zoey/zoey.mdl", 		"Zoey");
	AddMenuItem(menu, "models/player/custom/francis/francis.mdl", 	"Francis");
	AddMenuItem(menu, "models/player/custom/ellis/ellis.mdl", 		"Ellis");
	AddMenuItem(menu, "models/player/custom/nick/nick.mdl", 		"Nick");
	
	AddMenuItem(menu, "models/player/resident/sherry6/sherry6.mdl", "Sherry");
	AddMenuItem(menu, "models/player/resident/leon6/leon6.mdl", 	"Leon");
	AddMenuItem(menu, "models/player/dr.valencia/dr.valencia.mdl", 	"Dr. Valencia");
	AddMenuItem(menu, "models/player/domino/domino.mdl", 			"Domino");
	
	AddMenuItem(menu, "models/player/tm_anarchist.mdl", 			"Anarchist");
	AddMenuItem(menu, "models/player/tm_anarchist_varianta.mdl", 	"Anarchist - A");
	AddMenuItem(menu, "models/player/tm_anarchist_variantb.mdl",	"Anarchist - B");
	AddMenuItem(menu, "models/player/tm_anarchist_variantc.mdl", 	"Anarchist - C");
	AddMenuItem(menu, "models/player/tm_anarchist_variantd.mdl", 	"Anarchist - D");
	
	AddMenuItem(menu, "models/player/tm_balkan_varianta.mdl", 		"Balkan");
	AddMenuItem(menu, "models/player/tm_balkan_variantb.mdl", 		"Balkan - A");
	AddMenuItem(menu, "models/player/tm_balkan_variantc.mdl",		"Balkan - B");
	AddMenuItem(menu, "models/player/tm_balkan_variantd.mdl", 		"Balkan - C");
	AddMenuItem(menu, "models/player/tm_balkan_variante.mdl", 		"Balkan - D");
	
	AddMenuItem(menu, "models/player/tm_leet_varianta.mdl", 		"Phoenix");
	AddMenuItem(menu, "models/player/tm_leet_variantb.mdl", 		"Phoenix - A");
	AddMenuItem(menu, "models/player/tm_leet_variantc.mdl",			"Phoenix - B");
	AddMenuItem(menu, "models/player/tm_leet_variantd.mdl", 		"Phoenix - C");
	AddMenuItem(menu, "models/player/tm_leet_variante.mdl", 		"Phoenix - D");
	
	AddMenuItem(menu, "models/player/tm_phoenix.mdl", 				"Phoenix");
	AddMenuItem(menu, "models/player/tm_phoenix_varianta.mdl", 		"Phoenix - A");
	AddMenuItem(menu, "models/player/tm_phoenix_variantb.mdl",		"Phoenix - B");
	AddMenuItem(menu, "models/player/tm_phoenix_variantc.mdl", 		"Phoenix - C");
	AddMenuItem(menu, "models/player/tm_phoenix_variantd.mdl", 		"Phoenix - D");
	
	AddMenuItem(menu, "models/player/tm_pirate.mdl", 				"Pirate");
	AddMenuItem(menu, "models/player/tm_pirate_varianta.mdl", 		"Pirate - A");
	AddMenuItem(menu, "models/player/tm_pirate_variantb.mdl",		"Pirate - B");
	AddMenuItem(menu, "models/player/tm_pirate_variantc.mdl", 		"Pirate - C");
	AddMenuItem(menu, "models/player/tm_pirate_variantd.mdl", 		"Pirate - D");
	
	AddMenuItem(menu, "models/player/tm_professional.mdl", 			"Professional");
	AddMenuItem(menu, "models/player/tm_professional_var1.mdl", 	"Professional - A");
	AddMenuItem(menu, "models/player/tm_professional_var2.mdl",		"Professional - B");
	AddMenuItem(menu, "models/player/tm_professional_var3.mdl", 	"Professional - C");
	AddMenuItem(menu, "models/player/tm_professional_var4.mdl", 	"Professional - D");
	
	AddMenuItem(menu, "models/player/tm_separatist.mdl", 			"Séparatist");
	AddMenuItem(menu, "models/player/tm_separatist_varianta.mdl", 	"Séparatist - A");
	AddMenuItem(menu, "models/player/tm_separatist_variantb.mdl",	"Séparatist - B");
	AddMenuItem(menu, "models/player/tm_separatist_variantc.mdl", 	"Séparatist - C");
	AddMenuItem(menu, "models/player/tm_separatist_variantd.mdl", 	"Séparatist - D");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}

public int MenuTrySkin(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("MenuTrySkin");
	#endif
	
	if( action == MenuAction_Select ) {
		char szMenuItem[128];
		if( GetMenuItem(menu, param2, szMenuItem, sizeof(szMenuItem)) ) {
			if(rp_GetPlayerZone(client) != ZONE_CABINE){
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes sorti des cabines d'essayage.");
				return;
			}
			if( GetClientTeam(client) == CS_TEAM_CT ){
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas essayer cela en CT.");
				return;
			}
			char clientModel[128];
			GetClientModel(client, clientModel, sizeof(clientModel));
			if( StrEqual(clientModel, "models/player/rgmodels/rginmate/rginmate.mdl") ){
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas essayer cela en tant qu'évadé.");
				return;
			}
			if( !IsModelPrecached(szMenuItem) ) {
				if( PrecacheModel(szMenuItem) == 0 ) {
					return;
				}
			}
			ServerCommand("sm_effect_setmodel \"%i\" \"%s\"", client, szMenuItem);
			rp_UnhookEvent(client, RP_OnPlayerZoneChange, fwdOnZoneChange);
			CreateTimer(3.0, CheckTrySkin, client);
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public Action CheckTrySkin(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("CheckTrySkin");
	#endif
	if(rp_GetPlayerZone(client) != ZONE_CABINE)
		rp_ClientResetSkin(client);
	else
		rp_HookEvent(client, RP_OnPlayerZoneChange, fwdOnZoneChange);

}

public Action fwdOnZoneChange(int client, int newZone, int oldZone) {
	rp_ClientResetSkin(client);
	rp_UnhookEvent(client, RP_OnPlayerZoneChange, fwdOnZoneChange);
}