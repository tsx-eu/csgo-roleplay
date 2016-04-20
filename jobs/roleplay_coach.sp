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
#include <cstrike>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MODEL_KNIFE	"models/weapons/w_knife_flip.mdl"

public Plugin myinfo = {
	name = "Jobs: Coach", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Coach",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_cBeam;
int g_iKnifeThrowID = -1;
int g_iRiotShield[65];
// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	RegServerCmd("rp_item_cut",			Cmd_ItemCut,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_lancercut",	Cmd_ItemCutThrow,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cutnone",		Cmd_ItemCutRemove,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_esquive",		Cmd_ItemCut_Esquive,	"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_knifetype",	Cmd_ItemKnifeType,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_permi_tir",	Cmd_ItemPermiTir,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_shoes", 		Cmd_ItemShoes, 			"RP-ITEM", 	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_packequipement", Cmd_ItemPackEquipement, "RP-ITEM", FCVAR_UNREGISTERED);
	
	RegServerCmd("rp_item_riotshield",	Cmd_ItemRiotShield,		"RP-ITEM",	FCVAR_UNREGISTERED);
	
	for (int i = 1; i <= MaxClients; i++) 
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i); 

}
	
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	PrecacheModel(MODEL_KNIFE, true);
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_PostTakeDamageKnife, fwdWeapon);
	rp_HookEvent(client, RP_OnPlayerBuild, fwdOnPlayerBuild);
}
public void OnClientDisconnect(int client) {
	removeShield(client);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPackEquipement(int args){
	#if defined DEBUG
	PrintToServer("Cmd_ItemPackEquipement");
	#endif									

	int client = GetCmdArgInt(1);

	rp_SetClientInt(client, i_KnifeTrain, 100);
	rp_SetClientInt(client, i_Esquive, 100);
	rp_SetClientFloat(client, fl_WeaponTrain, 5.0);

	FakeClientCommand(client, "say /item");

	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemCut(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCut");
	#endif

	int amount = GetCmdArgInt(1);
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	int item_id_1, item_id_10;
	
	switch(amount){
		case 1: {
			item_id_10= item_id+1;
			item_id_1= item_id;
		}
		case 10: {
			item_id_10= item_id;
			item_id_1= item_id-1;
		}
		case 100: {
			item_id_10= item_id-1;
			item_id_1= item_id-2;
		}
		default: {
			return Plugin_Handled;
		}
	}

	rp_SetClientInt(client, i_KnifeTrain, rp_GetClientInt(client, i_KnifeTrain) + amount);

	if( rp_GetClientInt(client, i_KnifeTrain) > 100 ) {	

		int add = rp_GetClientInt(client, i_KnifeTrain) - 100;

		int add10 = RoundToFloor(float(add) / 10.0);
		int add1 = add % 10;

		if(add10 > 0)
			rp_ClientGiveItem(client, item_id_10 , add10);

		rp_ClientGiveItem(client, item_id_1 , add1);
		
		rp_IncrementSuccess(client, success_list_coach, amount-add);
		rp_SetClientInt(client, i_KnifeTrain, 100);
		if(add10 == 0 && add1 == 1)
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est de 100/100, un niveau d'entrainement vous a été remboursé.");
		else
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est de 100/100, %i niveaux d'entrainement vous ont été remboursés.", add10 * 10 + add1);
		
		return Plugin_Handled;
	}

	rp_IncrementSuccess(client, success_list_coach, amount);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est maintenent de %i/100.", rp_GetClientInt(client, i_KnifeTrain));
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemCut_Esquive(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCut_Esquive");
	#endif
	
	int amount = GetCmdArgInt(1);
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	
	rp_SetClientInt(client, i_Esquive, rp_GetClientInt(client, i_Esquive) + amount);
	
	if( rp_GetClientInt(client, i_Esquive) > 100 ) {
		int add = rp_GetClientInt(client, i_Esquive) - 100;
		if( amount == 1 ) 
			rp_ClientGiveItem(client, item_id, add);
		else
			rp_ClientGiveItem(client, item_id - 1, add);
			
		rp_SetClientInt(client, i_Esquive, 100);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est déjà maximal.");
		return Plugin_Handled;
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est maintenent de %i/100.", rp_GetClientInt(client, i_Esquive));
	return Plugin_Handled;
}
public Action Cmd_ItemCutRemove(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCutRemove");
	#endif

	int client = GetCmdArgInt(1);
	rp_SetClientInt(client, i_KnifeTrain, 0);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est maintenant à 0.");
}

public Action Cmd_ItemCutThrow(int args) {	
	#if defined DEBUG
	PrintToServer("Cmd_ItemCutThrow");
	#endif
	
	int client = GetCmdArgInt(1);
	rp_SetClientInt(client, i_LastShot, GetTime());
	g_iKnifeThrowID = GetCmdArgInt(args);
	
	rp_SetClientInt(client, i_LastAgression, GetTime());
	
	float fPos[3], fAng[3], fVel[3], fPVel[3];
	GetClientEyePosition(client, fPos);
	GetClientEyeAngles(client, fAng);
	GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fVel, 2000.0);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVel);
	AddVectors(fVel, fPVel, fVel);
	
	
	int entity = CreateEntityByName("hegrenade_projectile");
	DispatchSpawn(entity);
	
	SetEntityModel(entity, MODEL_KNIFE);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
	SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.2);
	
	TeleportEntity(entity, fPos, fAng, fVel);
	
	TE_SetupBeamFollow(entity, g_cBeam, 0, 0.7, 7.7, 7.7, 3, {177, 177, 177, 117});
	TE_SendToAll();
	
	SDKHook(entity, SDKHook_Touch, Cmd_ItemCutThrow_TOUCH);
	
}
public void Cmd_ItemCutThrow_TOUCH(int rocket, int entity) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCutThrow_TOUCH");
	#endif
	
	char classname[64];
	int attacker = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
	bool touched = false;
	
	if( entity > 0 && IsValidEdict(entity) && IsValidEntity(entity) ) {
		
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if( StrContains(classname, "trigger_") == 0 )
			return;
		
		if( IsValidClient(entity) && rp_IsTutorialOver(entity) ) {
			float dmg = float(rp_GetClientInt(attacker, i_KnifeTrain));
			wpnCutDamage(entity, attacker, dmg);
			rp_ClientDamage(entity, RoundFloat(dmg), attacker, "weapon_knife_throw");
			touched = true;
		}
	}
	
	if( !touched) {
		rp_GetItemData(g_iKnifeThrowID, item_type_name, classname, sizeof(classname));
		rp_ClientGiveItem(attacker, g_iKnifeThrowID);
		CPrintToChat(attacker, "{lightblue}[TSX-RP]{default} Vous avez récupéré votre couteau.");
	}
	
	SDKUnhook(rocket, SDKHook_Touch, Cmd_ItemCutThrow_TOUCH);	// Prevent TWICE touch.
	AcceptEntityInput(rocket, "Kill");
}

// ----------------------------------------------------------------------------
public Action Cmd_ItemKnifeType(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemKnifeType");
	#endif
	char arg1[12];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	
	enum_ball_type ball_type_type = ball_type_none;

	if( StrEqual(arg1, "fire") ) {
		ball_type_type = ball_type_fire;
	}
	else if( StrEqual(arg1, "caoutchouc") ) {
		ball_type_type = ball_type_caoutchouc;
	}
	else if( StrEqual(arg1, "poison") ) {
		ball_type_type = ball_type_poison;
	}
	else if( StrEqual(arg1, "vampire") ) {
		ball_type_type = ball_type_vampire;
	}
	else if (StrEqual(arg1, "anti-kevlar") ){
		ball_type_type = ball_type_antikevlar;
	}
	if( rp_GetClientKnifeType(client) == ball_type_type ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà un couteau de ce type.");
		return Plugin_Handled;
	}
	
	rp_SetClientKnifeType(client, ball_type_type);
	
	return Plugin_Handled;
}
public Action fwdWeapon(int victim, int attacker, float &damage) {
	bool changed = wpnCutDamage(victim, attacker, damage);
	
	if( changed )
		return Plugin_Changed;
	return Plugin_Continue;
}
bool wpnCutDamage(int victim, int attacker, float &damage) {
	bool changed = true;
	switch( rp_GetClientKnifeType(attacker) ) {
		case ball_type_fire: {
			rp_ClientIgnite(victim, 10.0, attacker);
			changed = false;
		}
		case ball_type_caoutchouc: {
			damage *= 0.0;
			
			if( rp_IsInPVP(victim) ) {
				rp_SetClientFloat(victim, fl_FrozenTime, GetGameTime() + 1.5);
				if( !rp_GetClientBool(victim, b_ChiruYeux) )
					ServerCommand("sm_effect_flash %d 1.5 180", victim);
			}
			else {
				if( !rp_ClientFloodTriggered(attacker, victim, fd_flash) ) {
					rp_ClientFloodIncrement(attacker, victim, fd_flash, 1.0);
					rp_SetClientFloat(victim, fl_FrozenTime, GetGameTime() + 1.5);
					if( !rp_GetClientBool(victim, b_ChiruYeux) )
						ServerCommand("sm_effect_flash %d 1.5 180", victim);
				}
			}
		}
		case ball_type_antikevlar: {
			int kevlar = rp_GetClientInt(victim, i_Kevlar);
			if (kevlar > 0){
				damage *= 0.50;
				kevlar *= 0.7;
				kevlar -= 20;
				
				kevlar = kevlar>0 ? kevlar : 0;
				rp_SetClientInt(victim, i_Kevlar, kevlar);
			}
		}
		case ball_type_poison: {
			damage *= 0.40;
			rp_ClientPoison(victim, 20.0, attacker);
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
		default: {
			changed = false;
		}
	}
	return changed;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPermiTir(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPermiTir");
	#endif
	
	int client = GetCmdArgInt(1);
	
	float train = rp_GetClientFloat(client, fl_WeaponTrain) + 4.0;
	train = Math_Clamp(train, 0.0, 8.0);
	
	rp_SetClientFloat(client, fl_WeaponTrain, train);
	
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est maintenant de %.2f%%", (train/5.0*100.0));
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemRiotShield(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemRiotShield");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( g_iRiotShield[client] > 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà un bouclier anti-émeute.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	removeShield(client);
	
	int ent = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(ent, "classname", "notsolid");
	DispatchKeyValue(ent, "model", "models/weapons/melee/w_riotshield.mdl");
	DispatchSpawn(ent);
	Entity_SetOwner(ent, client);
	
	SetEntityMoveType(ent, MOVETYPE_NONE);
	SetEntProp(ent, Prop_Data, "m_CollisionGroup", 2);  
	
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, client);
	
	FakeClientCommand(client, "use weapon_knife");
	FakeClientCommand(client, "use weapon_bayonet");
	
	SetVariantString("weapon_hand_L");
	AcceptEntityInput(ent, "SetParentAttachment");
	TeleportEntity(ent, view_as<float>({ 2.0, 4.0, 0.0 }), view_as<float>({ 300.0, 90.0, 20.0}), NULL_VECTOR);
	rp_HookEvent(client, RP_OnAssurance,	fwdAssurance2);
	rp_HookEvent(client, RP_PostTakeDamageWeapon, fwdTakeDamage);
	rp_HookEvent(client, RP_OnPlayerDead, fwdPlayerDead);
	
	g_iRiotShield[client] = ent;
	SDKHook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKHook(client, SDKHook_WeaponSwitch, Hook_WeaponSwitch);
	
	return Plugin_Handled;
}
public Action fwdAssurance2(int client, int& amount) {
		amount += 250;
}
public Action Hook_WeaponSwitch(int client, int weapon) {
	char wepname[64];
	if (g_iRiotShield[client] > 0) {
		GetEdictClassname(weapon, wepname, sizeof(wepname));
		
		if( StrContains(wepname, "weapon_knife") == 0 || StrContains(wepname, "weapon_bayonet") == 0 ) {
			SetVariantString("weapon_hand_L");
			AcceptEntityInput(g_iRiotShield[client], "SetParentAttachment");
			
			TeleportEntity(g_iRiotShield[client], view_as<float>({ 2.0, 4.0, 0.0 }), view_as<float>({ 300.0, 90.0, 20.0}), NULL_VECTOR);
		}
		else {
			
			SetVariantString("primary");
			AcceptEntityInput(g_iRiotShield[client], "SetParentAttachment");
			
			TeleportEntity(g_iRiotShield[client], view_as<float>({ 10.0, 20.0, 0.0 }), view_as<float>({ 150.0, 270.0, 120.0 }), NULL_VECTOR);
		}
	}
}
public Action fwdTakeDamage(int victim, int attacker, float& damage, int wepID, float pos[3]) {
	#if defined DEBUG
	PrintToServer("fwdTakeDamage");
	#endif
	float start[3];
	GetClientEyePosition(attacker, start);
	
	Handle tr = TR_TraceRayFilterEx(start, pos, MASK_ALL, RayType_EndPoint, TEF_ExcludeEntity, victim);
	
	if( TR_DidHit(tr) ) {
		TR_GetEndPosition(pos, tr);
		
		if( g_iRiotShield[victim] > 0 && TR_GetEntityIndex(tr) == g_iRiotShield[victim] ) {
			damage = 0.0;
			CloseHandle(tr);
			
			#if defined DEBUG
			TE_SetupBeamPoints(start, pos, g_cBeam, g_cBeam, 0, 10, 5.0, 1.0, 1.0, 1, 0.0, { 0, 255, 0, 255 }, 5);
			TE_SendToAll();
			#endif
			
			return Plugin_Stop;
		}
		
		#if defined DEBUG
		TE_SetupBeamPoints(start, pos, g_cBeam, g_cBeam, 0, 10, 5.0, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 5);
		TE_SendToAll();
		#endif
	}
	CloseHandle(tr);
	
	return Plugin_Continue;
}
public Action fwdPlayerDead(int victim, int attacker, float& respawn) {
	#if defined DEBUG
	PrintToServer("fwdPlayerDead");
	#endif
	
	removeShield(victim);
}
public Action Hook_SetTransmit(int entity, int client) {
	if( Entity_GetOwner(entity) == client && rp_GetClientInt(client, i_ThirdPerson) == 0 ) 
		return Plugin_Handled;
	return Plugin_Continue;
}
public bool TEF_ExcludeEntity(int entity, int contentsMask, any data) {
	if( entity == data )
		return true;
	if( entity == g_iRiotShield[data] )
		return true;
		
	return false;
}
void removeShield(int client) {
	
	if( g_iRiotShield[client] > 0 ) {
		
		
		rp_UnhookEvent(client, RP_OnPlayerDead, fwdPlayerDead);
		rp_UnhookEvent(client, RP_PostTakeDamageWeapon, fwdTakeDamage);
		rp_UnhookEvent(client, RP_OnAssurance,	fwdAssurance2);
		SDKUnhook(g_iRiotShield[client], SDKHook_SetTransmit, Hook_SetTransmit);
		SDKUnhook(client, SDKHook_WeaponSwitch, Hook_WeaponSwitch);
		
		AcceptEntityInput( g_iRiotShield[client], "Kill");
		g_iRiotShield[client] = 0;
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez perdu votre bouclier anti-émeute.");
	}
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemShoes(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemShoes");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);


	if(	rp_GetClientBool(client, b_HasShoes) ){
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà des chaussures voyons!");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	rp_SetClientBool(client, b_HasShoes, true);
	
	rp_HookEvent(client, RP_OnAssurance,	fwdAssurance);
	rp_HookEvent(client, RP_OnFrameSeconde, fwdVitalite);
	SDKHook(client, SDKHook_OnTakeDamage, fwdNoFallDamage);
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez maintenant la classe avec votre nouvelle paire de baskets!");
	return Plugin_Handled;
}
public Action fwdAssurance(int client, int& amount) {
	if( rp_GetClientBool(client, b_HasShoes) )
		amount += 250;
}
public Action fwdVitalite(int client) {
	#if defined DEBUG
	PrintToServer("fwdVitalite");
	#endif
	static float fLast[65][3];
	static count[65];
	
	float fNow[3];
	GetClientAbsOrigin(client, fNow);	
	
	
	if( GetVectorDistance(fNow, fLast[client]) > 50.0 && !rp_GetClientBool(client, b_IsAFK) ) { // Si le joueur marche
		count[client]++;
		if( count[client] > 60 ) {
			count[client] = 0;
		
			float vita = rp_GetClientFloat(client, fl_Vitality);
			rp_SetClientFloat(client, fl_Vitality, vita + 5.0);
			
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ressentez votre vitalité s'augmenter grâce à vos baskets (%.1f -> %.1f).", vita, vita + 5.0);
		}
	}
	
	for (int i = 0; i < 3; i++)
		fLast[client][i] = fNow[i];
}
public Action fwdNoFallDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	#if defined DEBUG
	PrintToServer("fwdNoFallDamage");
	#endif
	
	if( damagetype & DMG_FALL && !(rp_GetZoneBit(rp_GetPlayerZone(victim)) & BITZONE_EVENT)) {
		damage = 0.0;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action fwdOnPlayerBuild(int client, float& cooldown){
	if( rp_GetClientJobID(client) != 71 )
		return Plugin_Continue;

	int wep_id = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	char wep_name[32];
	GetEdictClassname(wep_id, wep_name, 31);
	if( StrContains(wep_name, "weapon_bayonet") != 0 && StrContains(wep_name, "weapon_knife") != 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez prendre votre couteau en main pour le modifier");
		return Plugin_Handled;
	}

	Handle menu = CreateMenu(ModifyWeapon);
	SetMenuTitle(menu, "Modifier le couteau");

	if(rp_GetClientKnifeType(client) == ball_type_fire)
		AddMenuItem(menu, "fire", "Changer pour un couteau incendiaire (50$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "fire", "Changer pour un couteau incendiaire (50$)");

	if(rp_GetClientKnifeType(client) == ball_type_caoutchouc)
		AddMenuItem(menu, "caoutchouc", "Changer pour un couteau en caoutchouc (50$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "caoutchouc", "Changer pour un couteau en caoutchouc (50$)");

	if(rp_GetClientKnifeType(client) == ball_type_poison)
		AddMenuItem(menu, "poison", "Changer pour un couteau empoisonné (50$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "poison", "Changer pour un couteau empoisonné (50$)");

	if(rp_GetClientKnifeType(client) == ball_type_vampire)
		AddMenuItem(menu, "vampire", "Changer pour un couteau vampirique (50$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "vampire", "Changer pour un couteau vampirique (50$)");

	if(rp_GetClientKnifeType(client) == ball_type_antikevlar)
		AddMenuItem(menu, "kevlar", "Changer pour un couteau anti kevlar (50$)", ITEMDRAW_DISABLED);
	else
		AddMenuItem(menu, "kevlar", "Changer pour un couteau anti kevlar (50$)");

	if(rp_GetClientInt(client, i_KnifeTrain) == 100)
		AddMenuItem(menu, "full", "Me mettre à 100 niveaux d'entrainement (0$)", ITEMDRAW_DISABLED);
	else{
		char tmp[64];
		Format(tmp, sizeof(tmp), "Me mettre à 100 niveaux d'entrainement (%i$)", (100 - rp_GetClientInt(client, i_KnifeTrain))*10 );
		AddMenuItem(menu, "full", tmp);
	}	

	if(rp_GetClientInt(client, i_Esquive) == 100)
		AddMenuItem(menu, "esquive", "Me mettre à 100 niveaux d'esquive (0$)", ITEMDRAW_DISABLED);
	else{
		char tmp[64];
		Format(tmp, sizeof(tmp), "Me mettre à 100 niveaux d'esquive (%i$)", (100 - rp_GetClientInt(client, i_Esquive))*10 );
		AddMenuItem(menu, "esquive", tmp);
	}
	DisplayMenu(menu, client, 60);
	return Plugin_Handled;
}

public int ModifyWeapon(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("ModifyWeapon Menu");
	#endif

	if (p_oAction == MenuAction_Select) {
		char szMenuItem[32];
		if (GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem))){

			int wep_id = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			char wep_name[32];
			int price = 50;
			GetEdictClassname(wep_id, wep_name, 31);

			if( StrContains(wep_name, "weapon_bayonet") != 0 && StrContains(wep_name, "weapon_knife") != 0 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez prendre une arme en main pour la modifier");
				return;
			}

			if(StrEqual(szMenuItem, "full")){
				price = (100 - rp_GetClientInt(client, i_KnifeTrain))*10;
				if((rp_GetClientInt(client, i_Bank)+rp_GetClientInt(client, i_Money)) >= price){
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money)-price);
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entrainement au couteau est maintenant maximal.");
					rp_SetClientInt(client, i_KnifeTrain, 100);
				}
				else{
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas assez d'argent.");
					return;
				}
			}			
			else if(StrEqual(szMenuItem, "esquive")){
				price = (100 - rp_GetClientInt(client, i_Esquive))*10;
				if((rp_GetClientInt(client, i_Bank)+rp_GetClientInt(client, i_Money)) >= price){
					rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money)-price);
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre esquive est maintenant maximale.");
					rp_SetClientInt(client, i_Esquive, 100);
				}
				else{
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas assez d'argent.");
					return;
				}
			}
			else if((rp_GetClientInt(client, i_Bank)+rp_GetClientInt(client, i_Money)) >= price){
				rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money)-price);
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} La modification à été appliquée à votre couteau.");
				if(StrEqual(szMenuItem, "fire")){
					rp_SetClientKnifeType(client, ball_type_fire);
				}
				else if(StrEqual(szMenuItem, "caoutchouc")){
					rp_SetClientKnifeType(client, ball_type_caoutchouc);
				}
				else if(StrEqual(szMenuItem, "poison")){
					rp_SetClientKnifeType(client, ball_type_poison);
				}
				else if(StrEqual(szMenuItem, "vampire")){
					rp_SetClientKnifeType(client, ball_type_vampire);
				}
				else if(StrEqual(szMenuItem, "kevlar")){
					rp_SetClientKnifeType(client, ball_type_antikevlar);
				}
			}
			else{
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas assez d'argent.");
				return;
			}
			rp_SetClientStat(client, i_TotalBuild, rp_GetClientStat(client, i_TotalBuild)+1);
			rp_SetJobCapital( 71, rp_GetJobCapital(71)+price );
			FakeClientCommand(client, "say /build");
		}
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hItemMenu);
	}

}