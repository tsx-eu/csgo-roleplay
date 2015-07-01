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
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.2.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define DRUG_DURATION 	90.0
#define MODEL_PLANT		"models/props/cs_office/plant01_static.mdl"
#define ITEM_PIEDBICHE	1

public Plugin myinfo = {
	name = "Jobs: DEALER", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Dealer",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_cBeam, g_cExplode;
Handle g_hDrugTimer[65];
// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_drug", 		Cmd_ItemDrugs,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_engrais",		Cmd_ItemEngrais,		"RP-ITEM",	FCVAR_UNREGISTERED);
	
	RegServerCmd("rp_item_plant",		Cmd_ItemPlant,			"RP-ITEM",	FCVAR_UNREGISTERED);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cExplode = PrecacheModel("materials/sprites/muzzleflash4.vmt", true);
	PrecacheModel(MODEL_PLANT, true);
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerBuild,	fwdOnPlayerBuild);
	rp_HookEvent(client, RP_OnPlayerUse,	fwdOnPlayerUse);
}
public void OnClientDisconnect(int client) {
	rp_UnhookEvent(client, RP_OnPlayerBuild,fwdOnPlayerBuild);
	rp_UnhookEvent(client, RP_OnPlayerUse,	fwdOnPlayerUse);
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
	
	if( StrEqual(arg0, "lsd2") || StrEqual(arg0, "pcp2") ){
		int target = GetClientTarget(client);
	
		if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_PEACEFULL ) {
			ITEM_CANCEL(client, item_id);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit où vous êtes.");
			return Plugin_Handled;
		}
		
		if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) || client == target ) {
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		if( !rp_IsEntitiesNear(client, target) ) {
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		if( !rp_IsTutorialOver(target) ) {
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N n'a pas terminé le tutorial.", target);
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		
		//Initialisation des positions pour le laser (cf. laser des chiru)
		float pos1[3], pos2[3];
		GetClientEyePosition(client, pos1);
		GetClientEyePosition(target, pos2);
		pos1[2] -= 20.0; pos2[2] -= 20.0;
		
		//Effets des drogues
		if( StrEqual(arg0, "lsd2")) rp_Effect_VisionTrouble(target);  //Si c'est de la LSD
		else rp_HookEvent(target, RP_PrePlayerPhysic, fwdPCP, DRUG_DURATION); //Si c'est du PCP
	
		//Affichage du laser entre le client et la cible (cf. laser des chiru)
		TE_SetupBeamPoints(pos1, pos2, g_cBeam, 0, 0, 0, 0.5, 10.0, 10.0, 1, 0.5, {255, 155, 0, 250}, 0);
		TE_SendToAll(0.1);
		
		//Envoie de messages d'information
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez drogué %N.", target);
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez été drogué.");
		client = target;
	}
	else if( StrEqual(arg0, "crack2") ) {
		rp_HookEvent(client, RP_PreTakeDamage, fwdCrack, DRUG_DURATION);
		rp_Effect_ShakingVision(client);
	}
	else if( StrEqual(arg0, "cannabis2") ) {
		rp_SetClientFloat(client, fl_invisibleTime, GetGameTime() + DRUG_DURATION);
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
		
		rp_SetClientFloat(client, fl_HallucinationTime, GetGameTime() + DRUG_DURATION);
	}
	else if( StrEqual(arg0, "crystal") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdCrystal, DRUG_DURATION);
		rp_HookEvent(client, RP_PreHUDColorize, fwdCrystal2, DRUG_DURATION);
	}
	else if( StrEqual(arg0, "ecstasy") ) {
		int kevlar = rp_GetClientInt(client, i_Kevlar);
		if ( kevlar >= 250 ) {
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdEcstasy, DRUG_DURATION);
		kevlar += 120; if (kevlar > 250)kevlar = 250;
		
		rp_SetClientInt(client, i_Kevlar, kevlar);
		rp_SetClientBool(client, b_KeyReverse, true);
	}
	else if( StrEqual(arg0, "beuh") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdBeuh, DRUG_DURATION);
		
		SetEntityHealth(client, GetClientHealth(client)+100);
		
		rp_Effect_Smoke(client, DRUG_DURATION);
	}
	
	bool drugged = rp_GetClientBool(client, b_Drugged);
	
	if( drugged ) {
		
		if( !g_hDrugTimer[client] ) {
			delete g_hDrugTimer[client];
			
			if( Math_GetRandomInt(1, 100) >= 80 ) {
				rp_IncrementSuccess(client, success_list_dealer);
				
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes en état d'overdose.");			
				
				rp_SetClientInt(client, i_Sick, Math_GetRandomInt((view_as<int>sick_type_none)+1, (view_as<int>sick_type_max)-1));
			}
		}
	}
	
	rp_SetClientBool(client, b_Drugged, true);
	g_hDrugTimer[client] = CreateTimer( DRUG_DURATION, ItemDrugStop, client);
	
	return Plugin_Handled;
}
public Action ItemDrugStop(Handle time, any client) {
	#if defined DEBUG
	PrintToServer("ItemDrugStop");
	#endif
	if( !IsValidClient(client) )
		return Plugin_Continue;

	rp_SetClientBool(client, b_Drugged, false);
	rp_SetClientBool(client, b_KeyReverse, false);
	
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action fwdCrack(int victim, int attacker, float& damage) {
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
// ----------------------------------------------------------------------------
public Action Cmd_ItemEngrais(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemEngrais");
	#endif
	int client = GetCmdArgInt(1);
	int target = GetClientTarget(client);
	int item_id = GetCmdArgInt(args);
	
	if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	char classname[64];
	GetEdictClassname(target, classname, sizeof(classname));
	if( StrContains(classname, "rp_plant_") != 0 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	int cpt = rp_GetBuildingData(target, BD_max);
	
	if( cpt >= 10 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	cpt++;
	rp_SetBuildingData(target, BD_max, cpt);
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce plant peut maintenant contenir %d drogues", cpt );
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPlant(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPlant");
	#endif
	
	int type = GetCmdArgInt(1);
	int client = GetCmdArgInt(2);
	
	if( BuildingPlant(client, type) == 0 ) {
		int item_id = GetCmdArgInt(args);
		ITEM_CANCEL(client, item_id);
	}
	
	return Plugin_Handled;
}

int BuildingPlant(int client, int type) {
	#if defined DEBUG
	PrintToServer("BuildingPlant");
	#endif
	
	if( !rp_IsBuildingAllowed(client) )
		return 0;
	
	char classname[64];
	Format(classname, sizeof(classname), "rp_plant_%i_%i", client, type);
	char tmp2[64];
	Format(tmp2, sizeof(tmp2), "rp_plant_%i_", client);
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	
	int count, max = 3;
	
	switch( rp_GetClientInt(client, i_Job) ) {
		case 81: max = 14;
		case 82: max = 10;
		case 83: max = 6;
		case 84: max = 4;
		case 85: max = 2;
	}
	for(int i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		char tmp[64];
		GetEdictClassname(i, tmp, 63);
		
		
		if( StrContains(tmp, tmp2) == 0 ) {
			count++;
			
			float vecOrigin2[3];
			Entity_GetAbsOrigin(i, vecOrigin2);
			
			
			if( GetVectorDistance(vecOrigin, vecOrigin2) <= 24 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas construire aussi proche d'une autre plante à vous.");
				return 0;
			}
		}
	}
	
	// TODO
	/*
	int appart = getZoneAppart(client);
	if( appart > 0 && g_iDoorOwner_v2[client][appart] ) {
		if( g_iAppartBonus[appart][appart_bonus_coffre] == 1 ) {
			max += 1;
		}
	}*/
	
	if( count >= max ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez trop de plants actifs.");
		return 0;
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Construction en cours...");
	
	EmitSoundToAllAny("player/ammo_pack_use.wav", client, _, _, _, 0.66);
	
	int ent = CreateEntityByName("prop_physics");
	
	DispatchKeyValue(ent, "classname", classname);
	DispatchKeyValue(ent, "model", MODEL_PLANT);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	SetEntityModel(ent, MODEL_PLANT);
	
	SetEntProp( ent, Prop_Data, "m_iHealth", 250);
	SetEntProp( ent, Prop_Data, "m_takedamage", 0);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityRenderMode(ent, RENDER_NONE);
	ServerCommand("sm_effect_fading \"%i\" \"3.0\" \"0\"", ent);
	
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	
	
	rp_SetBuildingData(ent, BD_started, GetTime());
	rp_SetBuildingData(ent, BD_max, 3);
	rp_SetBuildingData(ent, BD_owner, client);
	
	CreateTimer(3.0, BuildingPlant_post, ent);
	
	return 1;
}
public Action BuildingPlant_post(Handle timer, any entity) {
	#if defined DEBUG
	PrintToServer("BuildingPlant_post");
	#endif
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	rp_Effect_BeamBox(client, entity, NULL_VECTOR, 255, 255, 0);
	SetEntProp(entity, Prop_Data, "m_takedamage", 2);
	
	
	rp_SetBuildingData(entity, BD_max, 3);
	HookSingleEntityOutput(entity, "OnBreak", BuildingPlant_break);
	
	SDKHook(entity, SDKHook_OnTakeDamage, DamagePlant);
	CreateTimer(10.0, Frame_BuildingPlant, EntIndexToEntRef(entity));
	return Plugin_Handled;
}
public Action DamagePlant(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	#if defined DEBUG
	PrintToServer("DamagePlant");
	#endif
	if( IsValidClient(attacker) && attacker == inflictor ) {
		
		char sWeapon[32];
		GetClientWeapon(attacker, sWeapon, sizeof(sWeapon));
		int wep_id = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		
		
		if( StrContains(sWeapon, "weapon_knife") == 0 ||
			StrContains(sWeapon, "weapon_bayonet") == 0 ) {
			if( rp_GetClientKnifeType(attacker) == ball_type_fire ) {
				damage = float( rp_GetClientInt(attacker, i_KnifeTrain) );
				damage *= 0.5;
				
				if( damage >= 0.1 ) {
					IgniteEntity(victim, damage/10.0);
				}
				
				return Plugin_Changed;
			}
			else {
				return Plugin_Handled;
			}
		}
		else if( StrContains(sWeapon, "weapon_") == 0 && StrContains(sWeapon, "weapon_knife") == -1 ) {
			if( rp_GetWeaponBallType(wep_id) == ball_type_fire ) {
				
				if( damage >= 0.1 ) {
					IgniteEntity(victim, damage/10.0);
				}
				
				return Plugin_Continue;
			}
			else {
				return Plugin_Handled;
			}
		}
	}
	else {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
public void BuildingPlant_break(const char[] output, int caller, int activator, float delay) {
	#if defined DEBUG
	PrintToServer("BuildingPlant_break");
	#endif
	Plant_Destroy(caller);
	
	if( IsValidClient(activator) ) {
		rp_IncrementSuccess(activator, success_list_no_tech);
		
		if( rp_IsInPVP(caller) ) {
			int owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
			if( rp_GetClientGroupID(activator) > 0 && rp_GetClientGroupID(owner) > 0 && rp_GetClientGroupID(activator) != rp_GetClientGroupID(owner) ) {
				Plant_Destroy(caller);
			}
		}
	}
}
void Plant_Destroy(int entity) {
	#if defined DEBUG
	PrintToServer("Plant_Destroy");
	#endif
	float vecOrigin[3];
	Entity_GetAbsOrigin(entity, vecOrigin);
	
	if( rp_GetBuildingData(entity, BD_started)+120 < GetTime() ) {
		rp_Effect_SpawnMoney(vecOrigin, true);
	}
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 0.5, 2, 1, 25, 25);
	TE_SendToAll();
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if( IsValidClient(owner) ) {
		CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Une de vos plantations a été detruite.");
		if( rp_GetBuildingData(entity, BD_started)+120 < GetTime() ) {
			rp_SetClientInt(owner, i_Bank, rp_GetClientInt(owner, i_Bank)-125);
		}
	}
}

public Action Frame_BuildingPlant(Handle timer, any ent) {
	ent = EntRefToEntIndex(ent); if( ent == -1 ) { return Plugin_Handled; }
	#if defined DEBUG
	PrintToServer("Frame_BuildingPlant");
	#endif
	
	int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if( !IsValidClient(client) ) {
		AcceptEntityInput(ent, "Kill");
		return Plugin_Handled;
	}
	
	if( !rp_GetClientBool(client, b_IsAFK) && rp_GetClientInt(client, i_TimeAFK) <= 60 ) {
		
		int cpt = rp_GetBuildingData(ent, BD_count);
		
		if( cpt < rp_GetBuildingData(ent, BD_max) )
			cpt++;
		
		rp_SetBuildingData(ent, BD_count, cpt);
		
		rp_Effect_BeamBox(client, ent, NULL_VECTOR, 255, 255, 0);
		
		char tmp2[64];
		Format(tmp2, sizeof(tmp2), "rp_plant_%i_", client);
		char tmp[64];
		GetEdictClassname(ent, tmp, sizeof(tmp));
		
		ReplaceString(tmp, sizeof(tmp), tmp2, "");
		ReplaceString(tmp, sizeof(tmp), "_", "");
		
		int sub = StringToInt(tmp);
		
		rp_GetItemData(sub, item_type_name, tmp, sizeof(tmp));
		
		if( cpt == 0 ) 
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le plant %s est prêt pour 1 utilisation.", tmp);
		else
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le plant %s est prêt pour %i utilisations.", tmp, cpt);
	}
	
	CreateTimer(Math_GetRandomFloat(110.0, 120.0), Frame_BuildingPlant, EntIndexToEntRef(ent));
	
	return Plugin_Handled;
}
public Action fwdOnPlayerUse(int client) {
	#if defined DEBUG
	PrintToServer("BuildingPlant_use");
	#endif
	
	static char tmp[64], tmp2[64];
	
	if( rp_GetClientJobID(client) == 81 && rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) == 81 ) {
		int itemID = ITEM_PIEDBICHE;
		int mnt = rp_GetClientItem(client, itemID);
		int max = 1;
		if( mnt <  max ) {
			rp_ClientGiveItem(client, itemID, max - mnt);
			rp_GetItemData(itemID, item_type_name, tmp, sizeof(tmp));
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez récupéré %i %s.", max - mnt, tmp);
			
			FakeClientCommand(client, "say /item");
		}
	}
	
	
	Format(tmp2, sizeof(tmp2), "rp_plant_%i_", client);
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	
	for(int i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		
		GetEdictClassname(i, tmp, 63);
		
		
		if( StrContains(tmp, tmp2) == 0 ) {
			float vecOrigin2[3];
			Entity_GetAbsOrigin(i, vecOrigin2);
			if( GetVectorDistance(vecOrigin, vecOrigin2) <= 50 && rp_GetBuildingData(i, BD_count) > 0.0 ) {
				
				ReplaceString(tmp, sizeof(tmp), tmp2, "");
				ReplaceString(tmp, sizeof(tmp), "_", "");
				
				int sub = StringToInt(tmp);
				if( sub <= 0 && sub > MAX_ITEMS )
					continue;
					
				rp_IncrementSuccess(client, success_list_trafiquant, rp_GetBuildingData(i, BD_count) );
				rp_ClientGiveItem(client, sub, rp_GetBuildingData(i, BD_count));
				rp_SetBuildingData(i, BD_count, 0);
				
				rp_Effect_BeamBox(client, i, NULL_VECTOR, 255, 255, 0);
				FakeClientCommand(client, "say /item");
			}
		}
	}
}

public Action fwdOnPlayerBuild(int client, float& cooldown) {
	if( rp_GetClientJobID(client) != 81 )
		return Plugin_Continue;
	
	Handle menu = CreateMenu(MenuBuildingDealer);
	char tmp[12], tmp2[64];
			
	SetMenuTitle(menu, " Menu des dealers");
	
	for(int i = 0; i < MAX_ITEMS; i++) {
		
		rp_GetItemData(i, item_type_extra_cmd, tmp2, sizeof(tmp2));
		
		if( StrContains(tmp2, "rp_item_drug") != 0 )
			continue;
		
		rp_GetItemData(i, item_type_name, tmp2, sizeof(tmp2));
		
		
		Format(tmp, sizeof(tmp), "%d", i);
		Format(tmp2, sizeof(tmp2), "%s %d$", tmp2, rp_GetItemInt(i, item_type_prix) * 3);
		AddMenuItem(menu, tmp, tmp2);
		
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
	
	cooldown = 10.0;
	return Plugin_Stop;
}
public int MenuBuildingDealer(Handle menu, MenuAction action, int client, int param ) {
	#if defined DEBUG
	PrintToServer("MenuBuildingDealer");
	#endif
	
	if( action == MenuAction_Select ) {
		char szMenuItem[64];
		
		if( GetMenuItem(menu, param, szMenuItem, sizeof(szMenuItem)) ) {
			int mnt = rp_GetItemInt(StringToInt(szMenuItem), item_type_prix) * 3;
			
			if( rp_GetClientInt(client, i_Money) + rp_GetClientInt(client, i_Bank) < mnt ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas assez d'argent.");
				return;
			}
			
			int ent = BuildingPlant(client, StringToInt(szMenuItem));
			if( ent > 0 ) {
				
				rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - mnt);
				rp_SetJobCapital(81, rp_GetJobCapital(81) + mnt);
			}
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
