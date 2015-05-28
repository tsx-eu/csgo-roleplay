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
#define MODEL_KNIFE	"models/weapons/w_knife_flip.mdl"

public Plugin myinfo = {
	name = "Jobs: Coach", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Coach",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_cBeam;
int g_iKnifeThrowID = -1;
// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_cut_1",		Cmd_ItemCut_1,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cut_10",		Cmd_ItemCut_10,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_lancercut",	Cmd_ItemCutThrow,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cutnone",		Cmd_ItemCutRemove,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_esquive",		Cmd_ItemCut_Esquive,	"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_knifetype",	Cmd_ItemKnifeType,		"RP-ITEM",	FCVAR_UNREGISTERED);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	PrecacheModel(MODEL_KNIFE);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemCut_1(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCut_1");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	rp_SetClientInt(client, i_KnifeTrain, rp_GetClientInt(client, i_KnifeTrain) + 1);
	
	if( rp_GetClientInt(client, i_KnifeTrain) > 100 ) {
		rp_SetClientInt(client, i_KnifeTrain, 100);
		
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est déjà maximal.");
		return Plugin_Handled;
	}
	
	rp_IncrementSuccess(client, success_list_coach);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est maintenent de %i/100.", rp_GetClientInt(client, i_KnifeTrain));
	return Plugin_Handled;
}
public Action Cmd_ItemCut_10(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCut_10");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	rp_SetClientInt(client, i_KnifeTrain, rp_GetClientInt(client, i_KnifeTrain) + 10);

	if( rp_GetClientInt(client, i_KnifeTrain) > 100 ) {
		int add = rp_GetClientInt(client, i_KnifeTrain) - 100;
		rp_ClientGiveItem(client, item_id - 1, add);
		
		rp_SetClientInt(client, i_KnifeTrain, 100);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est déjà maximal.");
		return Plugin_Handled;
	}
	
	rp_IncrementSuccess(client, success_list_coach, 10);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre entraînement est maintenent de %i/100.", rp_GetClientInt(client, i_KnifeTrain));
	return Plugin_Handled;
}
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
	g_iKnifeThrowID = GetCmdArgInt(args);
	
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
	SetEntPropVector(entity, Prop_Data, "m_vecAngVelocity", view_as<float>{4500.0, 0.0, 0.0});
	
	TeleportEntity(entity, fPos, fAng, fVel);
	
	TE_SetupBeamFollow(entity, g_cBeam, 0, 0.7, 7.7, 7.7, 3, {177, 177, 177, 117});
	TE_SendToAll();
	
	SDKHook(entity, SDKHook_Touch, Cmd_ItemCutThrow_TOUCH);
	
}
public void Cmd_ItemCutThrow_TOUCH(int rocket, int entity) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCutThrow_TOUCH");
	#endif
	
	int attacker = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
	
	if( IsValidEdict(entity) && IsValidEntity(entity) ) {
		
		char classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));
		
		if( StrContains(classname, "trigger_", false) == 0) // WHAT?
			return;
		
		rp_ClientDamage(entity, rp_GetClientInt(attacker, i_KnifeTrain), attacker, "weapon_knife_throw");
	}
	else {
		rp_ClientGiveItem(attacker, g_iKnifeThrowID);
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
	
	if( StrEqual(arg1, "fire") ) {
		rp_SetClientKnifeType(client, ball_type_fire);
	}
	else if( StrEqual(arg1, "caoutchouc") ) {
		rp_SetClientKnifeType(client, ball_type_caoutchouc);
	}
	else if( StrEqual(arg1, "poison") ) {
		rp_SetClientKnifeType(client, ball_type_poison);
	}
	else if( StrEqual(arg1, "vampire") ) {
		rp_SetClientKnifeType(client, ball_type_vampire);
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
	
	switch( rp_GetClientKnifeType(attacker) ) {
		case ball_type_fire: {
			rp_ClientIgnite(victim, 10.0, attacker);
			changed = false;
		}
		case ball_type_caoutchouc: {
			damage *= 0.0;

			rp_SetClientFloat(victim, fl_FrozenTime, GetGameTime() + 1.5);
			ServerCommand("sm_effect_flash %d 1.5 180", victim);
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
	
	if( changed )
		return Plugin_Changed;
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------