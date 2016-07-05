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
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.2.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define TP_CD_DURATION 		30.0
#define TP_CHANNEL_DURATION 5.0
#define MAX_AREA_DIST 		500
#define STEAL_TIME			30.0
#define ITEM_PIEDBICHE		1
#define ZONE_ITEMSELL		132
#define DRUG_DURATION 		90.0
#define MODEL_PLANT_0			"models/custom_prop/marijuana/marijuana_0.mdl"
#define MODEL_PLANT_1			"models/custom_prop/marijuana/marijuana_1.mdl"
#define MODEL_PLANT_2			"models/custom_prop/marijuana/marijuana_2.mdl"
#define MODEL_PLANT_3			"models/custom_prop/marijuana/marijuana_3.mdl"


public Plugin myinfo = {
	name = "Jobs: DEALER", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Dealer",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_cExplode;
bool g_bCanSearchPlant[65];
Handle g_hDrugTimer[65];
int g_iWeaponStolen[2049], g_iStolenAmountTime[65];
int g_iMarket[MAX_ITEMS], g_iMarketClient[MAX_ITEMS][65];
Handle g_hForward_RP_OnClientMaxPlantCount, g_hForward_RP_OnClientPiedBiche, g_hForward_RP_ClientCanTP, g_RP_On18thStealWeapon;
// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	RegServerCmd("rp_item_drug", 		Cmd_ItemDrugs,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_engrais",		Cmd_ItemEngrais,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_piedbiche", 	Cmd_ItemPiedBiche,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_plant",		Cmd_ItemPlant,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_pilule",		Cmd_ItemPilule,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_moreplant", 	Cmd_ItemMorePlant, 		"RP-ITEM", 	FCVAR_UNREGISTERED);
	
	for (int j = 1; j <= MaxClients; j++)
		if( IsValidClient(j) )
			OnClientPostAdminCheck(j);
	
	char classname[64];
	for (int i = MaxClients; i <= 2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( StrEqual(classname, "rp_plant") ) {
			
			rp_SetBuildingData(i, BD_started, GetTime());
			rp_SetBuildingData(i, BD_owner, GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") );
			rp_SetBuildingData(i, BD_max, rp_GetBuildingData(i, BD_FromBuild) == 0 ? 3 : 30 );
			
			CreateTimer(Math_GetRandomFloat(0.25, 5.0), BuildingPlant_post, i);
		}
	}
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_hForward_RP_OnClientMaxPlantCount = CreateGlobalForward("RP_OnClientMaxPlantCount", ET_Event, Param_Cell, Param_CellByRef);
	g_hForward_RP_OnClientPiedBiche = CreateGlobalForward("RP_OnClientPiedBiche", ET_Event, Param_Cell, Param_Cell);
	g_hForward_RP_ClientCanTP = CreateGlobalForward("RP_ClientCanTP", ET_Event, Param_Cell);
	g_RP_On18thStealWeapon = CreateGlobalForward("RP_On18thStealWeapon", ET_Event, Param_Cell, Param_Cell, Param_Cell);
}
public void OnMapStart() {
	g_cExplode = PrecacheModel("materials/sprites/muzzleflash4.vmt", true);
}
public void OnEntityCreated(int ent, const char[] classname) {
	if( ent > 0 ) {
		g_iWeaponStolen[ent] = GetTime() - 110;
	}
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerBuild,	fwdOnPlayerBuild);
	rp_HookEvent(client, RP_OnPlayerUse,	fwdOnPlayerUse);
	rp_HookEvent(client, RP_OnPlayerSteal,	fwdOnPlayerSteal);
	g_bCanSearchPlant[client] = true;
	rp_SetClientBool(client, b_MaySteal, true);
	
	for (int i = 0; i < MAX_ITEMS; i++) {
		g_iMarketClient[i][client] = 0;
	}
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
	float dur = DRUG_DURATION;
	
	if( StrEqual(arg0, "ghb") && rp_GetClientInt(client, i_MaskCount) <= 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas utiliser de GHB pour le moment.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	if( StrEqual(arg0, "lsd2") || StrEqual(arg0, "pcp2") || StrEqual(arg0, "ghb") ){
		int target = rp_GetClientTarget(client);
	
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
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N n'a pas terminé le tutoriel.", target);
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		if( rp_IsClientNew(target) ) {
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N est un nouveau joueur.", target);
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		if( rp_GetClientBool(target, b_Lube) ) {
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} %N vous glisse entre les mains.", target);
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		LogToGame("[TSX-RP] [DROGUE] %L a drogué %L.", client, target);
		dur = 30.0;
		
		rp_SetClientInt(client, i_LastAgression, GetTime());
		//Initialisation des positions pour le laser (cf. laser des chiru)
		float pos1[3], pos2[3];
		GetClientEyePosition(client, pos1);
		GetClientEyePosition(target, pos2);
		pos1[2] -= 20.0; pos2[2] -= 20.0;
		
		//Effets des drogues
		if( StrEqual(arg0, "lsd2")) rp_Effect_VisionTrouble(target);  //Si c'est de la LSD
		else if( StrEqual(arg0, "pcp2")) rp_HookEvent(target, RP_PrePlayerPhysic, fwdPCP, dur); //Si c'est du PCP
		else if( StrEqual(arg0, "ghb")) rp_HookEvent(target, RP_OnPlayerDead, fwdGHB, dur); //Si c'est du GHB
		
		if( StrEqual(arg0, "ghb") ) rp_SetClientInt(client, i_MaskCount, rp_GetClientInt(client, i_MaskCount) - 1);
		
		ServerCommand("sm_effect_particles %d Trail9 10", client);
		
		//Envoie de messages d'information
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez drogué %N.", target);
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Vous avez été drogué.");
		client = target;
	}
	else if( StrEqual(arg0, "crack2") ) {
		if( !rp_GetClientBool(client, b_MayUseUltimate) ) {
			ITEM_CANCEL(client, item_id);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas utiliser cet item pour le moment.");
			return Plugin_Handled;
		}
		dur = 60.0;
		rp_SetClientBool(client, b_MayUseUltimate, false);
		CreateTimer(35.0, AllowUltimate, client);
		rp_HookEvent(client, RP_PreTakeDamage, fwdCrack, dur);
		rp_Effect_ShakingVision(client);
	}
	else if( StrEqual(arg0, "cannabis2") ) {
		rp_SetClientFloat(client, fl_invisibleTime, GetGameTime() + dur);
	}
	else if( StrEqual(arg0, "heroine") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdHeroine, dur);
		rp_HookEvent(client, RP_PreHUDColorize, fwdHeroine2, dur);
	}
	else if( StrEqual(arg0, "cocaine") ) {
		rp_HookEvent(client, RP_PreHUDColorize, fwdCocaine, dur);
	}
	else if( StrEqual(arg0, "champigions") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdChampi, dur);
		
		rp_SetClientFloat(client, fl_HallucinationTime, GetGameTime() + dur);
	}
	else if( StrEqual(arg0, "crystal") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdCrystal, dur);
		rp_HookEvent(client, RP_PreHUDColorize, fwdCrystal2, dur);
	}
	else if( StrEqual(arg0, "ecstasy") ) {
		int kevlar = rp_GetClientInt(client, i_Kevlar);
		if ( kevlar >= 250 ) {
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdEcstasy, dur);
		kevlar += 120; if (kevlar > 250)kevlar = 250;
		
		rp_SetClientInt(client, i_Kevlar, kevlar);
		rp_SetClientBool(client, b_KeyReverse, true);
	}
	else if( StrEqual(arg0, "beuh") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdBeuh, dur);
		
		SetEntityHealth(client, GetClientHealth(client)+100);
		
		rp_Effect_Smoke(client, dur);
	}
	
	bool drugged = rp_GetClientBool(client, b_Drugged);
	
	if( drugged ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Attention, vous étiez déjà drogué.");
		
		if( g_hDrugTimer[client] ) {
			delete g_hDrugTimer[client];
			
			if( Math_GetRandomInt(1, 100) >= 80 && !rp_GetClientBool(client, b_HasProtImmu)) {
				rp_IncrementSuccess(client, success_list_dealer);
				
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes en état d'overdose.");			
				
				rp_SetClientInt(client, i_Sick, Math_GetRandomInt((view_as<int>(sick_type_none))+1, (view_as<int>(sick_type_max))-1));
			}
		}
	}
	
	rp_SetClientBool(client, b_Drugged, true);
	g_hDrugTimer[client] = CreateTimer( dur, ItemDrugStop, client);
	
	return Plugin_Handled;
}
public Action fwdGHB(int attacker, int victim, char weapon[64]) {
	if( attacker == victim )
		return Plugin_Continue;
	return Plugin_Handled;
}
public Action Cmd_ItemEngrais(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemEngrais");
	#endif
	int client = GetCmdArgInt(1);
	int target = rp_GetClientTarget(client);
	int item_id = GetCmdArgInt(args);
	
	if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	char classname[64];
	GetEdictClassname(target, classname, sizeof(classname));
	if( !StrEqual(classname, "rp_plant") ) {
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
public Action Cmd_ItemMorePlant(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemMorePlant");
	#endif
	
	int client = GetCmdArgInt(1);
	int amount = rp_GetClientInt(client, i_Plant);
	
	if( amount >= 5 ) {
		int item_id = GetCmdArgInt(args);
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas avoir de plant supplémentaire.");
	}
	else
		rp_SetClientInt(client, i_Plant, amount + 1);
}
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
public Action Cmd_ItemPiedBiche(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPiedBiche");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( rp_GetClientJobID(client) != 81 ) {
		return Plugin_Continue;
	}
	
	if( rp_GetClientBool(client, b_MaySteal) == false ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler pour le moment.");
		return Plugin_Handled;
	}
	
	if( rp_GetClientVehiclePassager(client) > 0 || Client_GetVehicle(client) > 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible d'utiliser cet objet dans une voiture.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	int type;
	int target = getDistrib(client, type);
	if( target <= 0 ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être sur la place, ou viser une voiture.");
		return Plugin_Handled;
	}
	
	if( type == 5 ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen);
	}		
	
	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) + 1);

	rp_ClientGiveItem(client, item_id, -rp_GetClientItem(client, item_id));
	rp_SetClientBool(client, b_MaySteal, false);
	rp_SetClientInt(client, i_LastVolTime, GetTime());
	rp_SetClientInt(client, i_LastVolAmount, 100);
	rp_SetClientInt(client, i_LastVolTarget, -1);	
	rp_ClientReveal(client);
	rp_HookEvent(client, RP_OnPlayerZoneChange, fwdZoneChange);
	
	ServerCommand("sm_effect_particles %d weapon_sensorgren_detonate 1 facemask", client);
	ServerCommand("sm_effect_particles %d Trail2 2 legacy_weapon_bone", client);
	
	Handle dp;
	CreateDataTimer(0.1, ItemPiedBiche_frame, dp, TIMER_DATA_HNDL_CLOSE|TIMER_REPEAT);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
	WritePackCell(dp, 0.0);
	WritePackCell(dp, type);
	
	return Plugin_Handled;
}
public Action Cmd_ItemPilule(int args){
	#if defined DEBUG
	PrintToServer("Cmd_ItemPilule");
	#endif

	int type = GetCmdArgInt(1);	// 1 Pour Appart, 2 pour planque
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	int tptozone = -1;

	if( !rp_GetClientBool(client, b_MayUseUltimate) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas utiliser cet item pour le moment.");
		return Plugin_Handled;
	}
	if( !doRP_ClientCanTP(client) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas utiliser cet item pour le moment.");
		return Plugin_Handled;
	}
	

	if(type == 1) { // Appart
		int appartcount = rp_GetClientInt(client, i_AppartCount);
		if(appartcount == 0){
			ITEM_CANCEL(client, item_id);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas vous téléporter à votre appartement si vous n'en avez pas.");
			return Plugin_Handled;
		}
		else{
			for (int i = 1; i < 200; i++) {
				if( rp_GetClientKeyAppartement(client, i) ) {
					tptozone = appartToZoneID(i);
					break;
				}
			}
		}
	}
	else if (type == 2){ // Planque
		
		if(rp_GetClientJobID(client)==0){
			ITEM_CANCEL(client, item_id);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas vous teleporter à votre planque puisque vous êtes sans-emploi.");
			return Plugin_Handled;
		}
		switch(rp_GetClientJobID(client)){
			case 1:   tptozone = 11;
			case 11:  tptozone = 168;
			case 21:  tptozone = 90;
			case 31:  tptozone = 111;
			case 41:  tptozone = 273;
			case 51:  tptozone = 128;
			case 61:  tptozone = 19;
			case 71:  tptozone = 131;
			case 81:  tptozone = 210;
			case 91:  tptozone = 288;
			case 101: tptozone = 68;
			case 111: tptozone = 200;
			case 121: tptozone = 215;
			case 131: tptozone = 266;
			case 171: tptozone = 75;
			case 181: tptozone = 71;
			case 191: tptozone = 276;
			case 211: tptozone = 179;
			case 221: tptozone = 147;
		}
	}

	if(tptozone == -1){
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Nous n'avons pas trouvé d'endroit où vous téléporter.");
		return Plugin_Handled;
	}

	if(type == 1) {
		ServerCommand("sm_effect_particles %d Aura7 %d", client, RoundFloat(TP_CHANNEL_DURATION));
		rp_ClientColorize(client, { 238, 148, 52, 255} );
	}
	else if( type == 2 ) {
		ServerCommand("sm_effect_particles %d Aura8 %d", client, RoundFloat(TP_CHANNEL_DURATION));
		rp_ClientColorize(client, { 52, 148, 238, 255} );
	}
	
	rp_ClientReveal(client);
	ServerCommand("sm_effect_panel %d %f \"Téléportation en cours...\"", client, TP_CHANNEL_DURATION);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, TP_CHANNEL_DURATION);
	

	Handle dp;
	CreateDataTimer(TP_CHANNEL_DURATION, ItemPiluleOver, dp, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dp, client);
	WritePackCell(dp, item_id);
	WritePackCell(dp, tptozone);
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
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
public Action AllowUltimate(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("AllowUltimate");
	#endif

	rp_SetClientBool(client, b_MayUseUltimate, true);
}
public Action ItemPiluleOver(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int item_id = ReadPackCell(dp);
	int tptozone = ReadPackCell(dp);
	int clientzone = rp_GetPlayerZone(client);
	int clientzonebit = rp_GetZoneBit(clientzone);

	if(!IsValidClient(client) || !IsPlayerAlive(client) || ( clientzonebit & BITZONE_JAIL ||  clientzonebit & BITZONE_LACOURS ||  clientzonebit & BITZONE_HAUTESECU ) ){
		if(IsValidClient(client))
			rp_ClientColorize(client);
		return Plugin_Handled;
	}
	float zonemin[3], zonemax[3], tppos[3];

	zonemin[0] = rp_GetZoneFloat(tptozone, zone_type_min_x);
	zonemin[1] = rp_GetZoneFloat(tptozone, zone_type_min_y);
	zonemin[2] = rp_GetZoneFloat(tptozone, zone_type_min_z)+5.0;
	zonemax[0] = rp_GetZoneFloat(tptozone, zone_type_max_x);
	zonemax[1] = rp_GetZoneFloat(tptozone, zone_type_max_y);
	zonemax[2] = rp_GetZoneFloat(tptozone, zone_type_max_z)-80.0;

	for(int i=0; i<30; i++){
		for(int j=0; j<3; j++)
			tppos[j] = Math_GetRandomFloat(zonemin[j],zonemax[j]);
		
		if( rp_GetZoneFromPoint(tppos) != tptozone ) 
			continue;
		if( !CanTP(tppos, client) )
			continue;
		
		rp_ClientColorize(client, { 255, 255, 255, 255} );
		TeleportEntity(client, tppos, NULL_VECTOR, NULL_VECTOR);
		rp_SetClientBool(client, b_MayUseUltimate, false);
		CreateTimer( TP_CD_DURATION, AllowUltimate, client);
		return Plugin_Handled;
	}
	ITEM_CANCEL(client, item_id);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Nous n'avons pas trouvé d'endroit où vous téléporter.");
	rp_ClientColorize(client, { 255, 255, 255, 255} );
	rp_SetClientBool(client, b_MayUseUltimate, true);
	return Plugin_Handled;
}
public Action timerAlarm(Handle timer, any door) {
	#if defined DEBUG
	PrintToServer("timerAlarm");
	#endif
	
	EmitSoundToAllAny("UI/arm_bomb.wav", door);
	return Plugin_Handled;
}
public Action AllowStealing(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("AllowStealing");
	#endif
	
	rp_SetClientBool(client, b_MaySteal, true);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous pouvez à nouveau voler.");
}
public Action RemoveStealAmount(Handle time, any client) {
	g_iStolenAmountTime[client]--;
}
public Action SpawnMoney(Handle timer, any target) {
	
	target = EntRefToEntIndex(target);
	if( !IsValidEdict(target) )
		return Plugin_Handled;
	
	char classname[64];
	GetEdictClassname(target, classname, sizeof(classname));
	
	float vecOrigin[3], vecAngle[3], vecPos[3], min[3], max[3];
	Entity_GetAbsOrigin(target, vecOrigin);
	Entity_GetAbsAngles(target, vecAngle);
	Entity_GetMinSize(target, min);
	Entity_GetMaxSize(target, max);
	vecOrigin[2] += max[2] - min[2];
		
	vecPos[0] += Math_GetRandomFloat(-100.0, 100.0);
	vecPos[1] += Math_GetRandomFloat(-100.0, 100.0);
	vecPos[2] += Math_GetRandomFloat(200.0, 300.0);
	
	int m = rp_Effect_SpawnMoney(vecOrigin);
	TeleportEntity(m, NULL_VECTOR, NULL_VECTOR, vecPos);
	ServerCommand("sm_effect_particles %d Trail9 3", m);
	return Plugin_Handled;
}
public Action SwitchTrapped(Handle timer, any target) {
	
	target = EntRefToEntIndex(target);
	if( !IsValidEdict(target) )
		return Plugin_Handled;
	
	rp_SetBuildingData(target, BD_Trapped, false);
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
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
			rp_SetClientStat(client, i_DrugPickedUp, rp_GetClientStat(client, i_DrugPickedUp) + (max - mnt));
			FakeClientCommand(client, "say /item");
		}
	}
	
	if( rp_GetPlayerZone(client) == ZONE_ITEMSELL ) {
		openMarketMenu(client);
	}
		
	Format(tmp2, sizeof(tmp2), "rp_plant");
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	
	for(int i=MaxClients; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, sizeof(tmp));
		if( !StrEqual(tmp, tmp2) )
			continue;
		if( rp_GetBuildingData(i, BD_count) <= 0 )
			continue;
		
		float vecOrigin2[3];
		Entity_GetAbsOrigin(i, vecOrigin2);
		if( GetVectorDistance(vecOrigin, vecOrigin2) > 50.0 )
			continue;
		
		int sub = rp_GetBuildingData(i, BD_item_id);
		if( sub < 0 && sub > MAX_ITEMS )
			continue;
		
		rp_IncrementSuccess(client, success_list_trafiquant, rp_GetBuildingData(i, BD_count) );
		
		if( rp_GetBuildingData(i, BD_FromBuild) == 0 ) {
			if( rp_GetBuildingData(i, BD_owner) != client )
				continue;
			
			rp_ClientGiveItem(client, sub, rp_GetBuildingData(i, BD_count));
			FakeClientCommand(client, "say /item");
		}
		else {
			if( rp_GetClientJobID(client) != 81 )
				continue;
			
			addItemToMarket(rp_GetBuildingData(i, BD_owner), sub, rp_GetBuildingData(i, BD_count));
		}
		
		SetEntityModel(i, MODEL_PLANT_0);
		rp_SetBuildingData(i, BD_count, 0);
		rp_Effect_BeamBox(client, i, NULL_VECTOR, 255, 255, 0);
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
		AddMenuItem(menu, tmp, tmp2);
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
	
	cooldown = 10.0;
	return Plugin_Stop;
}
public Action fwdOnPlayerSteal(int client, int target, float& cooldown) {
	if( rp_GetClientJobID(client) != 81 )
		return Plugin_Continue;
	static char tmp[128], szQuery[1024];
	
	if( rp_GetClientJobID(target) == 81 ) {
		ACCESS_DENIED(client);
	}
	if( rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_BLOCKSTEAL ) {
		ACCESS_DENIED(client);
	}
	
	if( rp_GetZoneInt(rp_GetPlayerZone(target), zone_type_type) == 81 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler %N ici.", target);
		return Plugin_Handled;
	}
	
	if( rp_ClientFloodTriggered(client, target, fd_vol) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler %N, pour le moment.", target);
		return Plugin_Handled;
	}
	
	int VOL_MAX, amount, money;
	money = rp_GetClientInt(target, i_Money);
	VOL_MAX = (money+rp_GetClientInt(target, i_Bank)) / 200;
	
	if( rp_IsClientNew(target) )
		amount = Math_GetRandomPow(1, VOL_MAX);
	else
		amount = Math_GetRandomInt(1, VOL_MAX);
	
	if( VOL_MAX > 0 && money <= 0 && rp_GetClientInt(client, i_Job) <= 84 && !rp_IsClientNew(target) /*&& doRP_CanClientStealItem(client, target)*/ ) {

		int wepid = findPlayerWeapon(client, target);
		
		if( wepid == -1 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N n'a pas d'argent, ni d'arme sur lui.", target);
			cooldown = 1.0;
			return Plugin_Stop;
		}
				
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Quelqu'un essaye de vous voler.");
		
		char wepname[64];
		GetEdictClassname(wepid, wepname, sizeof(wepname));
		ReplaceString(wepname, sizeof(wepname), "weapon_", "");	
		int price = rp_GetWeaponPrice(wepid); 
		
		float StealTime = (Logarithm(float(price), 2.0) * 0.5) - 1.0;
		
		if( !rp_IsTargetSeen(target, client) ) {
			StealTime -= 0.5;
		}
		
		rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) + 1);
		rp_SetClientInt(client, i_LastVolVehicleTime, GetTime());
		rp_SetClientInt(client, i_LastVolAmount, 100);
		rp_SetClientInt(client, i_LastVolTarget, target);
		ServerCommand("sm_effect_particles %d Aura1 %d", client, RoundToCeil(StealTime));
		
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdAccelerate, StealTime);
		rp_HookEvent(client, RP_PreTakeDamage, fwdDamage, StealTime);
		
		Handle dp;
		CreateDataTimer(StealTime, ItemPickLockOver_18th, dp, TIMER_DATA_HNDL_CLOSE);
		WritePackCell(dp, client);
		WritePackCell(dp, target);
		WritePackCell(dp, EntIndexToEntRef(wepid));
		
		rp_SetClientBool(client, b_MaySteal, false);
		rp_SetClientBool(target, b_Stealing, true);
		SDKHook(target, SDKHook_WeaponDrop, OnWeaponDrop);
	}
	else if( VOL_MAX > 0 && money >= 1 ) {
		if( amount > money )
			amount = money;
			
		rp_SetClientStat(target, i_MoneySpent_Stolen, rp_GetClientStat(target, i_MoneySpent_Stolen) + amount);
		rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + amount);
		rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - amount);
		rp_SetClientInt(client, i_LastVolTime, GetTime());
		rp_SetClientInt(client, i_LastVolAmount, amount);
		rp_SetClientInt(client, i_LastVolTarget, target);
		rp_SetClientInt(target, i_LastVol, client);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez volé %d$ à %N.", amount, target);
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Quelqu'un vous a volé %d$.", amount);

		//g_iSuccess_last_mafia[client][1] = GetTime();
		//g_iSuccess_last_pas_vu_pas_pris[target] = GetTime();
		LogToGame("[TSX-RP] [VOL] %L a vole %L %i$", client, target, amount);
		
		GetClientAuthId(client, AuthId_Engine, tmp, sizeof(tmp), false);
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
			tmp, rp_GetClientJobID(client), GetTime(), 0, "Vol: Argent", amount);
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		
		if( rp_IsNight() )
			cooldown *= 0.5;
		
		if( amount < 50 )
			cooldown *= 0.5;
		if( amount < 5 )
			cooldown *= 0.5;
			
		if( amount > 500 )
			rp_SetClientFloat(client, fl_LastVente, GetGameTime() + 10.0);
		if( amount > 2000 )
			rp_SetClientFloat(client, fl_LastVente, GetGameTime() + 30.0);
		
		rp_ClientFloodIncrement(client, target, fd_vol, cooldown);
		
		ServerCommand("sm_effect_particles %d Aura2 2", client);
		
		int cpt = rp_GetRandomCapital(81);
		rp_SetJobCapital(81, rp_GetJobCapital(81) + (amount/4));
		rp_SetJobCapital(cpt, rp_GetJobCapital(cpt) - (amount/4));
	}
	else {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N n'a pas d'argent sur lui.", target);
		cooldown = 1.0;
	}
	
	return Plugin_Stop;
}
// ----------------------------------------------------------------------------
public Action fwdDamage(int client, int attacker, float& damage) {
	if( Math_GetRandomInt(0, 4) == 4 && rp_GetClientBool(attacker, b_Stealing) == true ) {
		rp_SetClientBool(attacker, b_Stealing, false);
		rp_ClientColorize(client);
		rp_ClientReveal(client);
	}	
	return Plugin_Continue;
}
public Action OnWeaponDrop(int client, int weapon) {
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas lâcher votre arme pendant qu'un 18th vous vol, tirez lui dessus ou fuyez !");
	return Plugin_Handled;
}
public Action fwdZoneChange(int client, int newZone, int oldZone) {
	int newType = rp_GetZoneInt(newZone, zone_type_type);
	if( newType == 81 && newType == rp_GetClientJobID(client) ) {
		g_bCanSearchPlant[client] = true;
		rp_UnhookEvent(client, RP_OnPlayerZoneChange, fwdZoneChange);
	}
}
// ----------------------------------------------------------------------------
int BuildingPlant(int client, int type) {
	#if defined DEBUG
	PrintToServer("BuildingPlant");
	#endif
	
	if( !rp_IsBuildingAllowed(client) )
		return 0;
	
	char classname[64], tmp[64];
	Format(classname, sizeof(classname), "rp_plant");
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	
	int count, max = 3;
	
	switch( rp_GetClientInt(client, i_Job) ) {
		case 81: max = 10;
		case 82: max = 9;
		case 83: max = 8;
		case 84: max = 7;
		case 85: max = 6;
		case 86: max = 5;
		case 87: max = 4;
		default: max = 3;
	}
	doRP_OnClientMaxPlantCount(client, max);
	
	for(int i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, sizeof(tmp));
		
		if( StrEqual(classname, tmp) && rp_GetBuildingData(i, BD_owner) == client ) {
			count++;
			
			float vecOrigin2[3];
			Entity_GetAbsOrigin(i, vecOrigin2);
			
			if( GetVectorDistance(vecOrigin, vecOrigin2) <= 24 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas construire aussi proche d'une autre plante vous appartenant.");
				return 0;
			}
		}
	}
	
	max += rp_GetClientInt(client, i_Plant);
	
	if(	max > 14 )
		max = 14;
		
	int appart = rp_GetPlayerZoneAppart(client);
	if( appart > 0 && rp_GetAppartementInt(appart, appart_bonus_coffre) ) {
		max += 1;
	}
			
	if(rp_GetClientJobID(client) == 1 || rp_GetClientJobID(client) == 101){
		max = 1;
	}
	
	if( count >= max ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez trop de plants actifs.");
		return 0;
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Construction en cours...");
	
	EmitSoundToAllAny("player/ammo_pack_use.wav", client, _, _, _, 0.66);
	
	int ent = CreateEntityByName("prop_physics");
	
	DispatchKeyValue(ent, "classname", classname);
	DispatchKeyValue(ent, "model", MODEL_PLANT_0);
	DispatchKeyValue(ent, "solid", "0");
	SetEntProp(ent, Prop_Data, "m_nSolidType", 0); 
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1); 
	
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	SetEntityModel(ent, MODEL_PLANT_0);
	
	SetEntProp( ent, Prop_Data, "m_iHealth", 250);
	SetEntProp( ent, Prop_Data, "m_takedamage", 0);
	
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	
	float ang[3];
	ang[1] = Math_GetRandomFloat(-180.0, 180.0);
	
	TeleportEntity(ent, vecOrigin, ang, NULL_VECTOR);
	
	SetEntityRenderMode(ent, RENDER_NONE);
	ServerCommand("sm_effect_fading \"%i\" \"3.0\" \"0\"", ent);
	
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	
	
	rp_SetBuildingData(ent, BD_started, GetTime());
	rp_SetBuildingData(ent, BD_max, 3);
	rp_SetBuildingData(ent, BD_count, 0);
	rp_SetBuildingData(ent, BD_owner, client);
	rp_SetBuildingData(ent, BD_item_id, type);
	rp_SetBuildingData(ent, BD_FromBuild, 0);
	
	CreateTimer(3.0, BuildingPlant_post, ent);
	
	return ent;
}
public Action BuildingPlant_post(Handle timer, any entity) {
	#if defined DEBUG
	PrintToServer("BuildingPlant_post");
	#endif
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	rp_Effect_BeamBox(client, entity, NULL_VECTOR, 255, 255, 0);
	SetEntProp(entity, Prop_Data, "m_takedamage", 2);
	
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
		
		if( cpt < rp_GetBuildingData(ent, BD_max) ) {
			cpt++;
			
			switch( cpt ) {
				case 1: SetEntityModel(ent, MODEL_PLANT_1);
				case 2: SetEntityModel(ent, MODEL_PLANT_2);
				case 3: SetEntityModel(ent, MODEL_PLANT_3);
			}
			
			ServerCommand("sm_effect_particles %d chicken_gone_zombie 1", ent);
			
			rp_SetBuildingData(ent, BD_count, cpt);
			rp_Effect_BeamBox(client, ent, NULL_VECTOR, 255, 255, 0);
			
			int sub = rp_GetBuildingData(ent, BD_item_id);
			char tmp[64];
			
			rp_GetItemData(sub, item_type_name, tmp, sizeof(tmp));
			
			if( rp_GetBuildingData(ent, BD_FromBuild) == 0 || cpt % 5 == 0 )
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le plant %s est prêt pour %d utilisation%s.", tmp, cpt, (cpt>=2?"s":"") );
		}
	}
	
	float time = Math_GetRandomFloat(80.0, 100.0);
	if( rp_GetBuildingData(ent, BD_FromBuild) == 1 )
		time /= 10.0;
	if( !rp_IsTutorialOver(client) )
		time /= 10.0;
	
	CreateTimer(time, Frame_BuildingPlant, EntIndexToEntRef(ent));
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action ItemPiedBiche_frame(Handle timer, Handle dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target = ReadPackCell(dp);
	float percent = ReadPackCell(dp);
	int type = ReadPackCell(dp);
	int type2;
	
	if( !IsValidClient(client ) ) {
		return Plugin_Stop;
	}
	if( getDistrib(client, type2) != target || type2 != type ) {
		MENU_ShowPickLock(client, percent, -1, type);
		rp_ClientColorize(client);
		CreateTimer(0.1, AllowStealing, client);
		rp_ClientGiveItem(client, ITEM_PIEDBICHE, 1);
		
		if( type == 5 )
			rp_UnhookEvent(client, RP_PrePlayerPhysic, fwdFrozen);
		
		return Plugin_Stop;
	}
	if( percent >= 1.0 ) {
		rp_ClientColorize(client);
		
		rp_SetClientStat(client, i_JobSucess, rp_GetClientStat(client, i_JobSucess) + 1);
		rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) - 1);
		
		float time = (rp_IsNight() ? STEAL_TIME:STEAL_TIME*2.0);
		int stealAMount;
		
		doRP_OnClientPiedBiche(client, type);
		
		switch(type) {
			case 1: { // Voiture
				int count = rp_CountPoliceNear(client), rand = 4 + Math_GetRandomPow(0, 4), i;
				
				for (i = 0; i < count; i++)
					rand += (4 + Math_GetRandomPow(0, 12));
				for (i = 0; i < rand; i++)
					CreateTimer(i / 5.0, SpawnMoney, EntIndexToEntRef(target));
				
				stealAMount = 25*rand + 500;
				
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} %d billets ont été sorti de la boite à gant.", rand);
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez maintenant les clés de cette voiture.");
				
				rp_SetClientKeyVehicle(client, target, true);
				rp_SetClientInt(client, i_LastVolVehicle, target);
				rp_SetClientInt(client, i_LastVolVehicleTime, GetTime());
			}
			case 2: {
				rp_SetBuildingData(target, BD_Trapped, true);
				ServerCommand("sm_effect_particles %d env_fire_large 45", target);
				CreateTimer(45.1, SwitchTrapped, EntIndexToEntRef(target));
				
				stealAMount = 100;
				
				rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + 100 ); 
			}
			case 5: { // Place de l'indé
				g_bCanSearchPlant[client] = false;
				rp_UnhookEvent(client, RP_PrePlayerPhysic, fwdFrozen);
				int amount = 0, ItemRand[32];
				
				for(int i = 0; i < MAX_ITEMS; i++) {
					if( rp_GetItemInt(i, item_type_job_id) != 81 )
						continue;
					ItemRand[amount++] = i;
				}
					
				int item_id = ItemRand[ Math_GetRandomInt(0, amount-1) ];
				amount = 1;
				if( rp_GetItemInt(item_id, item_type_prix) < 200 )
					amount = 10;
				
				char tmp[64];
				rp_GetItemData(item_id, item_type_name, tmp, sizeof(tmp));
			
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez trouvé %d %s", amount, tmp);
				rp_ClientGiveItem(client, item_id, amount);
				
				stealAMount = rp_GetItemInt(item_id, item_type_prix) * amount;
			}
			case 6: {
				ServerCommand("rp_GetStoreWeapon %d", client);
				stealAMount = 100;
			}
			case 7: {
				ServerCommand("rp_GetStoreItem %d", client);
				stealAMount = 100;
			}
		}
		
		rp_SetClientInt(client, i_LastVolTime, GetTime());
		rp_SetClientInt(client, i_LastVolTarget, -1);
		rp_SetClientInt(client, i_LastVolAmount, stealAMount); 
		
		CreateTimer(time, AllowStealing, client);
		return Plugin_Stop;
	}
	
	if( Math_GetRandomInt(1, 10) == 8 )
		ServerCommand("sm_effect_particles %d Trail2 2 legacy_weapon_bone", client);
	if( Math_GetRandomInt(1, 30) == 8 )
		ServerCommand("sm_effect_particles %d Aura2 1 footplant_L", client);
	if( Math_GetRandomInt(1, 30) == 8 )
		ServerCommand("sm_effect_particles %d Aura2 1 footplant_R", client);
		
	if( Math_GetRandomInt(1, 500) == 42 )
		CreateTimer(0.01, timerAlarm, client); 
	
	float ratio = 15.0 / 2500.0;
	
	rp_SetClientFloat(client, fl_CoolDown, GetGameTime() + 0.15);
	
	ResetPack(dp);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
	WritePackCell(dp, percent + ratio);
	WritePackCell(dp, type);
	MENU_ShowPickLock(client, percent, 0, type);
	return Plugin_Continue;
}
public Action ItemPickLockOver_18th(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("ItemPickLockOver_18th");
	#endif
	if( dp == INVALID_HANDLE ) {
		return Plugin_Handled;
	}
	
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target 	 = ReadPackCell(dp);
	int wepid = EntRefToEntIndex(ReadPackCell(dp));
	
	rp_ClientColorize(client);
	rp_ClientReveal(client);
	if( IsValidClient(target) )
		SDKUnhook(target, SDKHook_WeaponDrop, OnWeaponDrop);
	
	bool couldSteal = rp_GetClientBool(target, b_Stealing);
	rp_SetClientBool(target, b_Stealing, false);
	
	if( couldSteal == false || !IsPlayerAlive(client) || !IsPlayerAlive(target) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N s'est débattu, le vol a échoué.", target);
		CreateTimer(10.0, AllowStealing, client);
		return Plugin_Handled;
	}
	if( (rp_IsClientNew(target) || (rp_GetClientJobID(target)==41 && rp_GetClientInt(target, i_ToKill) > 0) || (rp_GetWeaponBallType(wepid) == ball_type_nosteal)) && Math_GetRandomInt(0,3) != 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N est plus difficile à voler qu'un autre...", target);
		CreateTimer(5.0, AllowStealing, client);
		return Plugin_Handled;
	}
	
	if ( rp_GetClientFloat(target, fl_Invincible) >= GetGameTime() ) {
		CreateTimer(1.0, AllowStealing, client);
		return Plugin_Handled;
	}
	
	CreateTimer(STEAL_TIME/2.0, AllowStealing, client);	
	g_iStolenAmountTime[target]++;
	CreateTimer(300.0, RemoveStealAmount, target);
	
	if( !rp_IsTargetSeen(target, client) ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdAccelerate, 5.0);
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdAccelerate, 1.0);
	}
	
	char wepname[64];
	GetEdictClassname(wepid, wepname, sizeof(wepname));
	ReplaceString(wepname, sizeof(wepname), "weapon_", "");	
	int price = rp_GetWeaponPrice(wepid);
	
	if( IsValidEdict(wepid) && IsValidEntity(wepid) &&
		IsValidClient(target) && rp_IsEntitiesNear(client, target, false, -1.0) &&
		Entity_GetOwner(wepid) == target
	) {
		
		if( rp_GetClientFloat(target, fl_LastStolen)+(60.0) < GetGameTime() && g_iWeaponStolen[wepid]+(120) < GetTime() ) {
			
			if( !rp_GetClientBool(target, b_IsAFK) && (rp_GetClientJobID(target) == 1 || rp_GetClientJobID(target) == 101) ) {
			
				int button = GetClientButtons(target);
			
				if( button & IN_FORWARD || button & IN_BACK || button & IN_LEFT || button & IN_RIGHT ||
					button & IN_MOVELEFT || button & IN_MOVERIGHT || button & IN_ATTACK || button & IN_JUMP || button & IN_DUCK	) {
					price *= 2;
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vol en action, argent doublé.");
				}
			
				int amount = RoundFloat( (float(price)/100.0) * (25.0) );
				
				if( (rp_GetClientInt(target, i_Money)+rp_GetClientInt(target, i_Bank)) < amount ) {
					amount = rp_GetClientInt(target, i_Money) + rp_GetClientInt(target, i_Bank);
				}
				
				
				rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + amount);
				rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - amount);
			}
			
			int cpt = rp_GetRandomCapital(81);
			rp_SetJobCapital(81, (rp_GetJobCapital(81) +  (price/2) ) );
			rp_SetJobCapital(cpt, (rp_GetJobCapital(cpt) -  (price/2) ) );
			
			Call_StartForward(g_RP_On18thStealWeapon);
			Call_PushCell(client);
			Call_PushCell(target);
			Call_PushCell(wepid);
			Call_Finish();
		}
		else {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} L'arme %s de %N s'est déjà faite volée il y a quelques instants.", wepname, target);
		}
	}
	else {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le joueur n'avait plus son arme sur lui.");
		return Plugin_Handled;
	}
	
	float time = GetGameTime();
	if( rp_GetClientBool(target, b_IsAFK) )
		time += 5.0 * 60.0;
	
	rp_SetClientFloat(target, fl_LastStolen, time);
	rp_SetClientInt(client, i_LastVolTime, GetTime());
	rp_SetClientInt(client, i_LastVolAmount, price/4);
	rp_SetClientInt(client, i_LastVolTarget, target);
	rp_SetClientInt(target, i_LastVol, client);
	
	char SteamID[64], szQuery[1024];
	
	GetClientAuthId(client, AuthId_Engine, SteamID, sizeof(SteamID), false);
	Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
	SteamID, rp_GetClientJobID(client), GetTime(), 0, "Vol: Arme", price/2);
	
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
	
	rp_SetClientStat(client, i_JobSucess, rp_GetClientStat(client, i_JobSucess) + 1);
	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) - 1);
	LogToGame("[TSX-RP] [VOL-18TH] %L a vole %s de %L", client, wepname, target);
	
	RemovePlayerItem(target, wepid);
	EquipPlayerWeapon(client, wepid);
	
	g_iWeaponStolen[wepid] = GetTime();
	//g_iSuccess_last_pas_vu_pas_pris[target] = GetTime();
	
	FakeClientCommand(target, "use weapon_knife");
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public int MenuBuildingDealer(Handle menu, MenuAction action, int client, int param ) {
	#if defined DEBUG
	PrintToServer("MenuBuildingDealer");
	#endif
	
	if( action == MenuAction_Select ) {
		char szMenuItem[64];
		
		if( GetMenuItem(menu, param, szMenuItem, sizeof(szMenuItem)) ) {
			
			int ent = BuildingPlant(client, StringToInt(szMenuItem));
			if( ent > 0 ) {
				rp_SetBuildingData(ent, BD_FromBuild, 1);
				rp_SetBuildingData(ent, BD_max, 30);
			}
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public int Menu_Market(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64], buff[2][16];
		GetMenuItem(menu, param2, options, sizeof(options));
		ExplodeString(options, " ", buff, sizeof(buff), sizeof(buff[]));
		
		int itemID = StringToInt(buff[0]);
		int amount = StringToInt(buff[1]);
		
		if( amount == 0 ) {
			openMarketMenu(client, itemID);
		}
		else {
			if( g_iMarket[itemID] < amount )
				amount = g_iMarket[itemID];
			if( amount == 0 )
				return;
			
			int prix = RoundFloat(float(rp_GetItemInt(itemID, item_type_prix)) * getReduction(itemID) * amount);
			if( (rp_GetClientInt(client, i_Money)+rp_GetClientInt(client, i_Bank)) < prix )
				return;
			
			rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) - prix);
			getItemFromMarket(itemID, amount);
			
			rp_ClientGiveItem(client, itemID, amount);
			
			rp_GetItemData(itemID, item_type_name, options, sizeof(options));
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez acheté %d %s pour %d$.", amount, options, prix);
			
			FakeClientCommand(client, "say /item");
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public int eventMenuNone(Handle menu, MenuAction action, int client, int param2) {	
	if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
// ----------------------------------------------------------------------------
void addItemToMarket(int client, int itemID, int amount) {
	g_iMarket[itemID] += amount;
	g_iMarketClient[itemID][client] += amount;
}
void getItemFromMarket(int itemID, int amount) {
	float prix = float(rp_GetItemInt(itemID, item_type_prix)) * getReduction(itemID);
	
	g_iMarket[itemID] -= amount;
	
	int stackClient[65], stackCpt, cpt, rnd;
	float ratio;
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( g_iMarketClient[itemID][i] <= 0 )
			continue;
		if( rp_GetClientJobID(i) != 81 )
			continue;
		stackClient[stackCpt++] = i;
	}
	stackCpt--;
	
	while( cpt < amount && stackCpt >= 0 ) {
		rnd = Math_GetRandomInt(0, stackCpt);
		
		ratio = getTaxe(stackClient[rnd]);
		
		g_iMarketClient[itemID][stackClient[rnd]]--;
		rp_SetClientInt(stackClient[rnd], i_AddToPay, rp_GetClientInt(stackClient[rnd], i_AddToPay) + RoundFloat(prix*(1.0-ratio)));
		rp_SetJobCapital(81, rp_GetJobCapital(81) + RoundFloat(prix*ratio) );
		
		if( g_iMarketClient[itemID][stackClient[rnd]] == 0 ) {
			for (int i = stackClient[rnd]; i<stackCpt ; i++) 
				g_iMarketClient[itemID][i] = g_iMarketClient[itemID][i + 1];
			stackCpt--;
		}
		
		cpt++;
	}
	
	if( cpt < amount ) {
		rp_SetJobCapital(81, rp_GetJobCapital(81) + ( RoundFloat(prix)*(amount-cpt)) );
	}
}
void openMarketMenu(int client, int itemID = 0) {
	if( rp_GetPlayerZone(client) != ZONE_ITEMSELL )
		return;
	
	char tmp[128], tmp2[32], tmp3[64];
	Menu menu = new Menu(Menu_Market);
	if( itemID == 0 ) {
		menu.SetTitle("Marché noir: Dealers");
		
		for(int i = 0; i < MAX_ITEMS; i++) {
			if( g_iMarket[i] <= 0 )
				continue;
			
			rp_GetItemData(i, item_type_name, tmp, sizeof(tmp));
			Format(tmp2, sizeof(tmp2), "%d 0", i);
			Format(tmp, sizeof(tmp), "%d %s - %d$", g_iMarket[i], tmp, RoundFloat(rp_GetItemInt(i, item_type_prix) * getReduction(i)));
			menu.AddItem(tmp2, tmp);
		}
	}
	else {
		rp_GetItemData(itemID, item_type_name, tmp3, sizeof(tmp3));
		menu.SetTitle("Dealers - %s", tmp3);

		float prix = float(rp_GetItemInt(itemID, item_type_prix)) * getReduction(itemID);
		for(int i = 1; i <= g_iMarket[itemID]; i++) {
			Format(tmp2, sizeof(tmp2), "%d %d", itemID, i);
			Format(tmp, sizeof(tmp), "%d %s - %d$", i, tmp3, RoundFloat(prix*float(i)));
			
			menu.AddItem(tmp2, tmp);
		}
	}
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 30);
}
int findPlayerWeapon(int client, int target) {
	
	if( !rp_IsTutorialOver(target) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur n'a pas terminé le tutoriel.");
		return -1;
	}
	if( rp_GetClientBool(target, b_Stealing) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Quelqu'un d'autre est déjà en train de voler ce joueur.");
		return -1;
	}
	
	if( (g_iStolenAmountTime[target] >= 3 && rp_GetClientFloat(target, fl_LastStolen)+(STEAL_TIME) > GetGameTime()) || (g_iStolenAmountTime[target] >= 5) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur s'est déjà fait volé récemment.");
		return -1;
	}
	if( rp_GetClientFloat(target, fl_Invincible) >= GetGameTime() ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur est invincible.");
		return -1;
	}
	if( rp_GetClientJobID(target) == 81 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler un autre dealer.");
		return -1;
	}
	
	int wepid;
	for( int i = 0; i < 5; i++ ) {
		if( i == 2 )
			continue;
			
		wepid = GetPlayerWeaponSlot( target, i );
		if( !IsValidEdict(wepid) )
			continue;
		if( g_iWeaponStolen[wepid]+120 > GetTime() )
			continue;
		
		return wepid;
	}
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur n'a pas d'arme.");
	return -1;
}
int appartToZoneID(int appartid){
	static int res[128];
	if( res[appartid] != 0 )
		return res[appartid];
	
	char appart[32], tmp[32];
	Format(appart, 31, "appart_%d",appartid);
	for(int i=1;i<300;i++){
		rp_GetZoneData(i, zone_type_type, tmp, sizeof(tmp));
		if(StrEqual(tmp,appart,false)){
			res[appartid] = i;
			return res[appartid];
		}
	}
	res[appartid] = -1;
	return res[appartid];
}
bool CanTP(float pos[3], int client) {
	static float mins[3], maxs[3];
	static bool init = false;
	bool ret;
	
	if( !init ) {
		GetClientMins(client, mins);
		GetClientMaxs(client, maxs);
		init = true;
	}
	
	Handle tr;
	tr = TR_TraceHullEx(pos, pos, mins, maxs, MASK_PLAYERSOLID);
	ret = !TR_DidHit(tr);
	CloseHandle(tr);
    #if defined DEBUG
		if( !ret ) {
			TR_GetEndPosition(maxs, tr);
			TE_SetupBeamRingPoint(maxs, 1.0, 1.5, g_cBeam, g_cBeam, 0, 30, 10.0, 1.0, 1.0, { 255, 255, 255, 255 }, 10, 0);
			TE_SendToAll();
		}
	#endif
	return ret;
}
bool CanStealVehicle(int client, int target) {
	if( (rp_GetZoneBit(rp_GetPlayerZone(target)) & BITZONE_PARKING) )
		return false;
	if( !IsValidClient(rp_GetVehicleInt(target, car_owner)) )
		return false;
	if( client == rp_GetVehicleInt(target, car_owner) )
		return false;
	if( rp_GetClientKeyVehicle(client, target) )
		return false;
	int owner = rp_GetVehicleInt(target, car_owner);
	int appart = rp_GetPlayerZoneAppart(owner);
	if( appart > 0 && rp_GetAppartementInt(appart, appart_bonus_garage) )
		return false;
	return true;
}
// ----------------------------------------------------------------------------
int getDistrib(int client, int& type) {
	if( !IsPlayerAlive(client) )
		return 0;
	
	if( !rp_IsBuildingAllowed(client, true) )
		return 0;
		
	char classname[64];
	int target = rp_GetClientTarget(client);
	if( target ) {
		GetEdictClassname(target, classname, sizeof(classname));
	}
	
	if( target > 0 && rp_IsValidVehicle(target) && CanStealVehicle(client, target) && rp_IsEntitiesNear(client, target, true) )
		type = 1;
	else if( target > 0 && StrEqual(classname, "rp_bank") && rp_GetBuildingData(target, BD_Trapped) == 0  && rp_IsEntitiesNear(client, target, true))
		type = 2;
	else {
		target = client;
		
		char tmp[64];
		rp_GetZoneData(rp_GetPlayerZone(client), zone_type_name, tmp, sizeof(tmp));
		float vecOrigin[3];
		GetClientAbsOrigin(client, vecOrigin);
		
		if( g_bCanSearchPlant[client] == true && vecOrigin[2] <= -2000.0 && StrContains(tmp, "Place de l'ind") == 0 ) {
			type = 5;
		}
		else if( GetVectorDistance(vecOrigin, view_as<float>({ 2550.8, 1663.1, -2015.96 })) < 64.0 ) {
			type = 6;
		}
		else if( GetVectorDistance(vecOrigin, view_as<float>({-144.55,  520.1, -2119.96 })) < 40.0 ) {
			type = 7;
		}
	}
	
	return (type > 0 ? target : 0);
}
void MENU_ShowPickLock(int client, float percent, int difficulte, int type) {

	Handle menu = CreateMenu(eventMenuNone);
	switch( type ) {
		case 1: SetMenuTitle(menu, "== Dealer: Vol d'une voiture");
		case 2: SetMenuTitle(menu, "== Dealer: Vandalisme du distributeur");
		
		case 5: SetMenuTitle(menu, "== Dealer: Déracinage d'un plant");
		case 6: SetMenuTitle(menu, "== Dealer: Vol de l'armurerie police");
		case 7: SetMenuTitle(menu, "== Dealer: Vol du marché noire mafia");
	}
	
	char tmp[64];
	rp_Effect_LoadingBar(tmp, sizeof(tmp), percent );
	AddMenuItem(menu, tmp, tmp, ITEMDRAW_DISABLED);
	
	switch( difficulte ) {
		case -1: AddMenuItem(menu, ".", "Difficulté: Échec", ITEMDRAW_DISABLED);
		case 1: AddMenuItem(menu, ".", "Difficulté: Facile", ITEMDRAW_DISABLED);
		case 2: AddMenuItem(menu, ".", "Difficulté: Moyenne", ITEMDRAW_DISABLED);
		case 3: AddMenuItem(menu, ".", "Difficulté: Difficile", ITEMDRAW_DISABLED);
		case 4: AddMenuItem(menu, ".", "Difficulté: Très difficile", ITEMDRAW_DISABLED);
	}
	
	Format(tmp, sizeof(tmp), "Policier proche: %d", rp_CountPoliceNear(client));
	AddMenuItem(menu, ".", tmp, ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(menu, false);
	DisplayMenu(menu, client, 1);
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
	
	if( speed > 0.5 )
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
public Action fwdFrozen(int client, float& speed, float& gravity) {
	speed = 0.0;
	return Plugin_Stop;
}
public Action fwdAccelerate(int client, float& speed, float& gravity) {
	speed += 0.5;
	return Plugin_Changed;
}
// ----------------------------------------------------------------------------
void doRP_OnClientMaxPlantCount(int client, int& max) {
	Call_StartForward(g_hForward_RP_OnClientMaxPlantCount);
	Call_PushCell(client);
	Call_PushCellRef(max);
	Call_Finish();
}
void doRP_OnClientPiedBiche(int client, int type) {
	Call_StartForward(g_hForward_RP_OnClientPiedBiche);
	Call_PushCell(client);
	Call_PushCell(type);
	Call_Finish();
}
bool doRP_ClientCanTP(int client) {
	Action a;
	Call_StartForward(g_hForward_RP_ClientCanTP);
	Call_PushCell(client);
	Call_Finish(a);
	if( a == Plugin_Handled || a == Plugin_Stop )
		return false;
	return true;
}

float getTaxe(int client) {
	int job = rp_GetClientInt(client, i_Job);
	float val = 0.5;
	switch(job) {
		case 81: val = 0.10;
		case 82: val = 0.15;
		case 83: val = 0.20;
		case 84: val = 0.25;
		case 85: val = 0.30;
		case 86: val = 0.35;
		case 87: val = 0.40;
		case 88: val = 0.45;
	}
	return val;
}
float getReduction(int itemID) {
	if( g_iMarket[itemID] <= 0 )
		return -0.1;
	
	return 1.0-((Logarithm(float(g_iMarket[itemID])) - 1.0) / 10.0);
}