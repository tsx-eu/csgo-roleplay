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
	name = "Jobs: Mc'Do", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Mc'Donalds",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_cBeam, g_cGlow;
// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_hamburger",	Cmd_ItemHamburger,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_banane",		Cmd_ItemBanane,			"RP-ITEM",	FCVAR_UNREGISTERED);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_cGlow = PrecacheModel("materials/sprites/glow01.vmt");
}
// ------------------------------------------------------------------------------
public Action Cmd_ItemHamburger(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemHamburger");
	#endif
	
	char arg1[12];
	GetCmdArg(1, arg1, 11);
	
	int client = GetCmdArgInt(2);
	
	if( StrEqual(arg1, "vital") || StrEqual(arg1, "max") ) {
		float vita = rp_GetClientFloat(client, fl_Vitality);
		
		rp_SetClientFloat(client, fl_Vitality, vita + 256.0);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ressentez votre vitalité s'augmenter (%.1f -> %.1f).", vita, vita+256.0);
	}
	if( StrEqual(arg1, "energy") || StrEqual(arg1, "max") ) {
		rp_SetClientFloat(client, fl_Energy, 100.0);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ressentez votre énergie s'augmenter.");
	}
	
	if( StrEqual(arg1, "fat") ) {
		float size = rp_GetClientFloat(client, fl_Size);
		
		rp_SetClientInt(client, i_Kevlar, 100);
		
		if( size < 1.6 ) {
			rp_SetClientFloat(client, fl_Size, size + 0.05);
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", size + 0.05);
		}
	}
	else if( StrEqual(arg1, "mac") ) {
		
		if( rp_IsInPVP(client) ) {
			rp_SetClientFloat(client, fl_CoolDown, rp_GetClientFloat(client, fl_CoolDown) + 5.0);
			rp_SetClientFloat(client, fl_Reflect, GetGameTime() + 3.0);
		}
		else {
			rp_SetClientFloat(client, fl_Reflect, GetGameTime() + 5.0);
		}
		
		float vecTarget[3];
		GetClientAbsOrigin(client, vecTarget);
		
		TE_SetupBeamRingPoint(vecTarget, 10.0, 300.0, g_cBeam, g_cGlow, 0, 15, 0.5, 50.0, 0.0, {255, 255, 0, 50}, 10, 0);
		TE_SendToAll();
	}
	else if( StrEqual(arg1, "chicken") ) {
		
		if( Math_GetRandomInt(1, 4) == 4 ) {
			int wepID = GivePlayerItem(client, "weapon_mac10");
			rp_SetClientWeaponSkin(client, wepID);
		}
		else {
			int ent = CreateEntityByName("chicken");
			DispatchSpawn(ent);
			float vecOrigin[3];
			GetClientAbsOrigin(client, vecOrigin);
			vecOrigin[2] += 20.0;
			
			TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
		}
	}
	else if( StrEqual(arg1, "happy") ) {
		
		int amount = 0;
		
		int iItemRand[MAX_ITEMS*2];
		
		int jobID;
		char cmd[128];
		bool lucky = rp_IsClientLucky(client);
		
		
		for(int i = 0; i < MAX_ITEMS; i++) {
			
			if( rp_GetItemInt(i, item_type_prix) <= 0 )
				continue;
			if( rp_GetItemInt(i, item_type_auto) == 1 )
				continue;
			
			jobID = rp_GetItemInt(i, item_type_job_id);
			
			if( jobID <= 0 || jobID == 61 || jobID == 91 ) // Aucun, Appart, Mafia
				continue;
			if( jobID == 51 && Math_GetRandomInt(0, 1) ) // Moins de chance pour carshop stp
				continue;
			
			
			
			rp_GetItemData(i, item_type_extra_cmd, cmd, sizeof(cmd));
			if( strlen(cmd) <= 1 ) // UNKNOWN
				continue;
			if( StrContains(cmd, "rp_chirurgie") == 0 )
				continue;
			
			iItemRand[amount] = i;
			amount++;
			
			if( StrContains(cmd, "rp_giveitem weapon_") == 0 ) { // 2x plus de chance d'avoir une arme
				iItemRand[amount] = i;
				amount++;
			}
			if( lucky && rp_GetItemInt(i, item_type_prix) > 2000 ) { // 2x plus de chance... Si on a de la chance grâce aux portes bonheures
				iItemRand[amount] = i;
				amount++;
			}
		}
		
		int item_id = iItemRand[ Math_GetRandomInt(0, amount-1) ];
		rp_ClientGiveItem(client, item_id, 1, true);
		
		rp_GetItemData(item_id, item_type_name, cmd, sizeof(cmd));
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu comme cadeau: %s", cmd);
		
		if( item_id == GetCmdArgInt(args) )
			rp_IncrementSuccess(client, success_list_mcdo);
	}
	else if( StrEqual(arg1, "box") ) { // TODO: Move to roleplay_armurerie
		
		int amount = 0;
		int iItemRand[MAX_ITEMS];
		bool lucky = rp_IsClientLucky(client);
		
		for(int i = 0; i < MAX_ITEMS; i++) {
			if( rp_GetItemInt(i, item_type_job_id) != 111 )
				continue;			
			
			iItemRand[amount] = i;
			amount++;
			
			if( !lucky && rp_GetItemInt(i, item_type_prix) <= 1000 ) { // 2x plus de chance... Si on a de la chance grâce aux portes bonheures
				iItemRand[amount] = i;
				amount++;
			}
		}
		
		char cmd[128];
		int item_id = iItemRand[ Math_GetRandomInt(0, amount-1) ];
		rp_ClientGiveItem(client, item_id, 1, true);
		rp_GetItemData(item_id, item_type_name, cmd, sizeof(cmd));
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu comme cadeau: %s", cmd);
	}
	else if( StrEqual(arg1, "drugs") ) { // TODO: Move to roleplay_dealer
		
		int amount = 0;		
		int iItemRand[MAX_ITEMS];
		char cmd[128];
		
		for(int i = 0; i < MAX_ITEMS; i++) {
			
			rp_GetItemData(i, item_type_extra_cmd, cmd, sizeof(cmd));
			if( StrContains(cmd, "rp_item_drug") != 0 )
				continue;
			
			iItemRand[amount] = i;
			amount++;
		}
		
		int item_id = iItemRand[ Math_GetRandomInt(0, amount-1) ];
		int rnd = 7+Math_GetRandomPow(1, 5);
		rp_ClientGiveItem(client, item_id, rnd, true);
		
		rp_GetItemData(item_id, item_type_name, cmd, sizeof(cmd));
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu comme cadeau: %dx %s", rnd, cmd);
	}
	else if( StrEqual(arg1, "spacy") ) {
		rp_SetClientKnifeType(client, ball_type_fire);
	}
	
	
	
	return Plugin_Handled;
}
public Action Cmd_ItemBanane(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemBanane");
	#endif
	char arg1[12];
	GetCmdArg(1, arg1, 11);
	
	int client = StringToInt(arg1);
	
	char classname[64];
	Format(classname, sizeof(classname), "rp_banana_%i", client);
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	
	int ent = CreateEntityByName("prop_physics_override");
	
	DispatchKeyValue(ent, "classname", classname);
	DispatchKeyValue(ent, "model", "models/props/cs_italy/bananna.mdl");
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	SetEntityModel(ent, "models/props/cs_italy/bananna.mdl");
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	SetEntityRenderMode(client, RENDER_NONE);
	
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	Entity_SetOwner(ent, client);
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);
	
	ServerCommand("sm_effect_fading \"%i\" \"0.5\" \"0\"", ent);
	rp_ScheduleEntityInput(ent, 60.0, "Kill");
	
	SDKHook(ent, SDKHook_Touch, BuildingBanana_touch);
	return Plugin_Handled;
}
public Action BuildingBanana_touch(int index, int client) {
	#if defined DEBUG
	PrintToServer("BuildingBanana_touch");
	#endif
	if( !IsValidClient(client) )
		return Plugin_Continue;
	
	char sound[128];
	Format(sound, sizeof(sound), "hostage/hpain/hpain%i.wav", Math_GetRandomInt(1, 6));
	EmitSoundToAll(sound, client);

	rp_ClientDamage(client, 25, Entity_GetOwner(index));
	
	float vecPlayerOrigin[3];
	vecPlayerOrigin[2] += 1.0;
	GetClientAbsOrigin(client, vecPlayerOrigin);
	
	if(GetEntityFlags(client) & FL_ONGROUND) {
		
		int flags = GetEntityFlags(client);
		SetEntityFlags(client, (flags&~FL_ONGROUND) );
		SetEntPropEnt(client, Prop_Send, "m_hGroundEntity", -1);
	}
	
	float vecVelocity[3];
	vecVelocity[0] = GetRandomFloat(400.0, 500.0);
	vecVelocity[1] = GetRandomFloat(400.0, 500.0);
	vecVelocity[2] = GetRandomFloat(600.0, 800.0);
	TeleportEntity(client, vecPlayerOrigin, NULL_VECTOR, vecVelocity);	
	
	AcceptEntityInput(index, "Kill");
	SDKUnhook(index, SDKHook_Touch, BuildingBanana_touch);
	
	return Plugin_Continue;
}
