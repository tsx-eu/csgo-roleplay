/*
 * Cette oeuvre, création, site ou texte est sous licence Creative Commons Attribution
 * - Pas d’Utilisation Commerciale
 * - Partage dans les Mêmes Conditions 4.0 International. 
 * Pour accéder à une copie de cette licence, merci de vous rendre à l'adresse suivante
 * http://creativecommons.org/licenses/by-nc-sa/4.0/ .
 *
 * Merci de respecter le travail fournis par le ou les auteurs 
 * https://www.ts-x.eu/ - kossolax@ts-x.eu
 */
#pragma semicolon 1

#include <sourcemod>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define DRUG_DURATION 90.0

public Plugin myinfo = {
	name = "Jobs: DEALER", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Dealer",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};


Handle g_hDrugTimer[65];
// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_drug", 		Cmd_ItemDrugs,			"RP-ITEM",	FCVAR_UNREGISTERED);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemDrugs(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemDrugs");
	#endif
	
	char arg0[64];
	GetCmdArg(1, arg0, sizeof(arg0));
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	
	if( StrEqual(arg0, "lsd2") ) {
		int target = GetClientTarget(client);
		if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) ) {
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		if( !rp_IsEntitiesNear(client, target) ) {
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		if( !rp_IsTutorialOver(target) ) {
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N n'a pas terminé le tutorial.", target);
			return Plugin_Handled;
		}
		
		rp_Effect_VisionTrouble(target);
		client = target;
	}
	else if( StrEqual(arg0, "pcp2") ) {
		int target = GetClientTarget(client);
		if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) ) {
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		if( !rp_IsEntitiesNear(client, target) ) {
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		if( !rp_IsTutorialOver(target) ) {
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N n'a pas terminé le tutorial.", target);
			return Plugin_Handled;
		}
		
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdPCP, DRUG_DURATION);
		client = target;
	}
	else if( StrEqual(arg0, "crack2") ) {
		rp_HookEvent(client, RP_PreTakeDamage, fwdCrack, DRUG_DURATION);
		rp_Effect_ShakingVision(client);
	}
	else if( StrEqual(arg0, "cannabis2") ) {
		rp_setClientFloat(client, fl_invisibleTime, GetGameTime() + DRUG_DURATION);
	}
	else if( StrEqual(arg0, "heroine") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdHeroine, DRUG_DURATION);
		rp_HookEvent(client, RP_PreHUDColorize, fwdHeroine2, DRUG_DURATION);
	}
	else if( StrEqual(arg0, "cocaine") ) {
		rp_HookEvent(client, RP_PreHUDColorize, fwdCocaine, DRUG_DURATION);

		SetEntityHealth(client, 500);
	}
	else if( StrEqual(arg0, "champigions") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdChampi, DRUG_DURATION);
		
		rp_setClientFloat(client, fl_HallucinationTime, GetGameTime() + DRUG_DURATION);
	}
	else if( StrEqual(arg0, "crystal") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdCrystal, DRUG_DURATION);
		rp_HookEvent(client, RP_PreHUDColorize, fwdCrystal2, DRUG_DURATION);
	}
	else if( StrEqual(arg0, "ecstasy") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdEcstasy, DRUG_DURATION);
		
		int kevlar;
		rp_getClientInt(client, i_Kevlar, kevlar);
		kevlar += 120; if (kevlar > 250)kevlar = 250;
		
		rp_setClientInt(client, i_Kevlar, kevlar);
		rp_setClientBool(client, b_KeyReverse, true);
		
	}
	else if( StrEqual(arg0, "beuh") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdBeuh, DRUG_DURATION);
		
		SetEntityHealth(client, GetClientHealth(client)+100);
		
		rp_Effect_Smoke(client, DRUG_DURATION);
	}
	
	bool drugged;
	rp_getClientBool(client, b_Drugged, drugged);
	
	if( drugged ) {
		
		if( !g_hDrugTimer[client] ) {
			delete g_hDrugTimer[client];
			
			if( Math_GetRandomInt(1, 100) >= 80 ) {
				rp_IncrementSuccess(client, success_list_dealer);
				
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes en état d'overdose.");			
				
				rp_setClientInt(client, i_Sick, Math_GetRandomInt((view_as<int>sick_type_none)+1, (view_as<int>sick_type_max)-1));
				
			}
		}
	}
	
	rp_setClientBool(client, b_Drugged, true);
	g_hDrugTimer[client] = CreateTimer( 0.001, ItemDrugStop, client);
	
	return Plugin_Handled;
}
public Action ItemDrugStop(Handle time, any client) {
	#if defined DEBUG
	PrintToServer("ItemDrugStop");
	#endif
	if( !IsValidClient(client) )
		return Plugin_Continue;

	rp_setClientBool(client, b_Drugged, false);
	rp_setClientBool(client, b_KeyReverse, false);
	
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------




// ----------------------------------------------------------------------------
public Action fwdCrack(int attacker, int victim, float& damage) {
	#if defined DEBUG
	PrintToServer("fwdCrack");
	#endif
	damage /= 2.0;
	
	return Plugin_Changed;
}
public Action fwdPCP(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdPCP");
	#endif
	speed -= 0.25;
	
	return Plugin_Changed;
}
public Action fwdHeroine(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdHeroine");
	#endif
	speed += 0.75;
	gravity -= 0.2;
	
	return Plugin_Changed;
}
public Action fwdHeroine2(int client, int color[4]) {
	#if defined DEBUG
	PrintToServer("fwdHeroine2");
	#endif
	
	color[0] -= 50;
	color[1] += 100;
	color[2] -= 50;
	color[3] += 50;
	return Plugin_Changed;
}
public Action fwdCocaine(int client, int color[4]) {
	#if defined DEBUG
	PrintToServer("fwdCocaine");
	#endif
	color[0] -= 50;
	color[1] += 50;
	color[2] += 100;
	color[3] += 50;
	return Plugin_Changed;
}
public Action fwdChampi(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdChampi");
	#endif
	speed -= 0.2;
	gravity -= 0.6;
	
	return Plugin_Changed;
}
public Action fwdCrystal(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdCrystal");
	#endif
	speed += 0.25;
	gravity -= 0.4;
	
	return Plugin_Changed;
}
public Action fwdCrystal2(int client, int color[4]) {
	#if defined DEBUG
	PrintToServer("fwdCrystal2");
	#endif
	color[0] += 100;
	color[1] += 100;
	color[2] += 100;
	color[3] += 50;
	return Plugin_Changed;
}
public Action fwdEcstasy(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdEcstasy");
	#endif
	speed += 0.25;
	gravity -= 0.2;
	
	return Plugin_Changed;
}
public Action fwdBeuh(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdBeuh");
	#endif
	gravity -= 0.4;
	
	return Plugin_Changed;
}


