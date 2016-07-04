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

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MODEL_CASH		"models/props_mall/cash_register.mdl"
#define MODEL_CASHBIG	"models/props_interiors/copymachine01.mdl"

public Plugin myinfo = {
	name = "Jobs: Technicien", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Technicien",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_cBeam, g_cGlow, g_cExplode;
bool g_bProps_trapped[2049];

//forward RP_OnClientMaxMachineCount(int client, int& max);
Handle g_hForward_RP_OnClientMaxMachineCount;
void doRP_OnClientMaxMachineCount(int client, int& max) {
	Call_StartForward(g_hForward_RP_OnClientMaxMachineCount);
	Call_PushCell(client);
	Call_PushCellRef(max);
	Call_Finish();
}
// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	// Technicien
	RegServerCmd("rp_item_biokev", 		Cmd_ItemBioKev,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_bioyeux", 	Cmd_ItemBioYeux,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_kevlar", 		Cmd_ItemKevlar,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_propulseur", 	Cmd_ItemPropulseur,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_nano",		Cmd_ItemNano,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cash",		Cmd_ItemCash,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cash2",		Cmd_ItemCash,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cashbig",		Cmd_ItemCashBig,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_morecash",	Cmd_ItemMoreCash,		"RP-ITEM",	FCVAR_UNREGISTERED);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
	
	char classname[64];
	for (int i = MaxClients; i <= 2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( StrEqual(classname, "rp_bigcashmachine") ) {
			
			rp_SetBuildingData(i, BD_started, GetTime());
			rp_SetBuildingData(i, BD_owner, GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") );
			
			CreateTimer(Math_GetRandomFloat(0.0, 2.5), BuildingBigCashMachine_post, i);
		}
		else if( StrEqual(classname, "rp_cashmachine") ) {
			rp_SetBuildingData(i, BD_started, GetTime());
			rp_SetBuildingData(i, BD_owner, GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") );
			
			CreateTimer(Math_GetRandomFloat(0.0, 2.5), BuildingCashMachine_post, i);
		}
	}
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_hForward_RP_OnClientMaxMachineCount = CreateGlobalForward("RP_OnClientMaxMachineCount", ET_Event, Param_Cell, Param_CellByRef);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
	g_cExplode = PrecacheModel("materials/sprites/muzzleflash4.vmt", true);
	
	PrecacheModel(MODEL_CASH, true);
}
// ------------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnAssurance,	fwdAssurance);
	rp_HookEvent(client, RP_OnPlayerBuild,	fwdOnPlayerBuild);
	
	if( rp_GetClientBool(client, ch_Kevlar) )
		rp_HookEvent(client, RP_OnFrameSeconde, fwdRegenKevlar);
	if( rp_GetClientBool(client, ch_Yeux) )
		rp_HookEvent(client, RP_PreHUDColorize, fwfBioYeux);
}
public Action fwdAssurance(int client, int& amount) {	
	
	if( rp_GetClientBool(client, ch_Kevlar) )
		amount += 100;
	if( rp_GetClientBool(client, ch_Yeux) )
		amount += 100;
	
	return Plugin_Changed; // N'a pas d'impact, pour le moment.
}
// ------------------------------------------------------------------------------
public Action fwdRegenKevlar(int client) {
	
	int kev = rp_GetClientInt(client, i_Kevlar);
	if( kev < 250 ) {
		rp_SetClientInt(client, i_Kevlar, kev + 1);
	}
}
public Action Cmd_ItemBioKev(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemBioKev");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( rp_GetClientBool(client, ch_Kevlar) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà une régénération bionique.");
		ITEM_CANCEL(client, item_id);
	}
	
	rp_HookEvent(client, RP_OnFrameSeconde, fwdRegenKevlar);
	rp_SetClientBool(client, ch_Kevlar, true);
}
// ------------------------------------------------------------------------------
public Action Cmd_ItemBioYeux(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemBioYeux");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( rp_GetClientBool(client, ch_Yeux) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà des yeux bioniques.");
		ITEM_CANCEL(client, item_id);
	}
	
	rp_HookEvent(client, RP_PreHUDColorize, fwfBioYeux);
	rp_SetClientBool(client, ch_Yeux, true);
}
public Action fwfBioYeux(int client, int color[4]) {
	#if defined DEBUG
	PrintToServer("fwfBioYeux");
	#endif
	
	color[0] = 0;
	color[1] = 0;
	color[2] = 0;
	color[3] = 0;
	
	return Plugin_Stop;
}
public Action fwdFrozen(int client, float& speed, float& gravity) {
	speed = 0.0;
	gravity = 0.0; 
	return Plugin_Stop;
}
// ------------------------------------------------------------------------------
public Action Cmd_ItemKevlar(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemKevlar");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int kev = rp_GetClientInt(client, i_Kevlar);
	
	if( kev >= 250 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	if( kev < 100 )
		kev = 100;
	else
		kev += 50;
	
	if( kev > 250 )
		kev = 250;
	
	rp_SetClientInt(client, i_Kevlar, kev);
	
	return Plugin_Continue;
}
public Action Cmd_ItemPropulseur(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPropulseur");
	#endif
	
	int client = GetCmdArgInt(1);
	
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	velocity[0] *= 5.0;
	velocity[1] *= 5.0;
	velocity[2] = (FloatAbs(velocity[2]) * 2.0) + Math_GetRandomFloat(50.0, 75.0);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	
	ServerCommand("sm_effect_particles %d Trail12 1 lfoot", client);
	ServerCommand("sm_effect_particles %d Trail12 1 rfoot", client);
	
}
// ------------------------------------------------------------------------------
public Action Cmd_ItemNano(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemNano");
	#endif
	
	char arg1[12];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	
	if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_PEACEFULL ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit où vous êtes.");
		return Plugin_Handled;
	}
	rp_SetClientInt(client, i_LastAgression, GetTime());
	
	if( StrEqual(arg1, "cryo") ) {
		
		float vecStart[3];
		GetClientEyePosition(client, vecStart);
		vecStart[2] -= 20.0;

		
		TE_SetupBeamRingPoint(vecStart, 2.0, 250.0, g_cBeam, 0, 0, 0, 0.5, 10.0, 0.5, {0, 128, 255, 192}, 1, 0);
		TE_SendToAll();
		
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( !IsPlayerAlive(i) )
				continue;
			if( GetEntityMoveType(i) != MOVETYPE_WALK )
				continue;
			
			float vecEnd[3];
			GetClientEyePosition(i, vecEnd);
			vecEnd[2] -= 20.0;
			
			if( GetVectorDistance(vecStart, vecEnd) > 250.0 )
				continue;
			
			TE_SetupBeamPoints(vecStart, vecEnd, g_cBeam, 0, 0, 0, 1.0, 5.0, 5.0, 1, 0.5, {0, 128, 255, 192}, 0);
			TE_SendToAll();
			
			rp_HookEvent(i, RP_PrePlayerPhysic, fwdFrozen, 5.0);
			rp_ClientColorize(i, { 0, 128, 255, 192 } );
			
			EmitSoundToAllAny("physics/glass/glass_impact_bullet4.wav", i);
			CreateTimer(GetRandomFloat(4.0, 6.0), NanoUnfreeze, i);
		}
	}
	else if( StrEqual(arg1, "implo") ) {
		
		float vecStart[3];
		GetClientEyePosition(client, vecStart);
		vecStart[2] -= 20.0;
		
		rp_Effect_Push(vecStart, 500.0, -2000.0, client);		
	}
	else if( StrEqual(arg1, "flash") ) {
		float vecStart[3];
		GetClientEyePosition(client, vecStart);
		vecStart[2] -= 20.0;
		
		TE_SetupBeamRingPoint(vecStart, 2.0, 250.0, g_cBeam, 0, 0, 0, 0.5, 10.0, 0.5, {255, 255, 255, 192}, 1, 0);
		TE_SendToAll();
		
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( !IsPlayerAlive(i) )
				continue;
			if( GetEntityMoveType(i) != MOVETYPE_WALK )
				continue;
			if( i == client )
				continue;
			
			float vecEnd[3];
			GetClientEyePosition(i, vecEnd);
			vecEnd[2] -= 20.0;
			
			if( GetVectorDistance(vecStart, vecEnd) > 250.0 )
				continue;
			
			TE_SetupBeamPoints(vecStart, vecEnd, g_cBeam, 0, 0, 0, 1.0, 5.0, 5.0, 1, 0.5, {255, 255, 255, 192}, 0);
			TE_SendToAll();
			if(!rp_GetClientBool(i, ch_Yeux))
				ServerCommand("sm_effect_flash %d 5.0 255", i);
		}
	}
	else if( StrEqual(arg1, "unprop") ) {
		
		int target = rp_GetClientTarget(client);
		// TODO: Move this fonction to here
		rp_ClientRemoveProp(client, target, item_id);
	}
	
	return Plugin_Handled;
}
public Action NanoUnfreeze(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("NanoUnfreeze");
	#endif
	
	rp_ClientColorize(client);		
}
// ------------------------------------------------------------------------------
public Action Cmd_ItemMoreCash(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemMoreCash");
	#endif
	
	int client = GetCmdArgInt(1);
	int amount = rp_GetClientInt(client, i_Machine);
	
	if( amount >= 15 ) {
		int item_id = GetCmdArgInt(args);
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas avoir de machine supplémentaire.");
	}
	else {
		rp_SetClientInt(client, i_Machine, amount + 1);
		
	}
}
// ------------------------------------------------------------------------------
public Action Cmd_ItemCash(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCash");
	#endif
	
	int client = GetCmdArgInt(1);
	
	if( rp_GetClientJobID(client) == 1 || rp_GetClientJobID(client) == 101 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit aux forces de l'ordre.");
		return Plugin_Handled;
	}
	
	int target = BuildingCashMachine(client);
	
	if( target == 0 ) {
		char arg_last[12];
		GetCmdArg(args, arg_last, 11);
		int item_id = StringToInt(arg_last);
		
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	g_bProps_trapped[target] = false;
	
	char arg[32];
	GetCmdArg(0, arg, sizeof(arg));
	if( StrEqual(arg, "rp_item_cash2") ) {
		g_bProps_trapped[target] = true;
		
		float vecTarget[3];
		Entity_GetAbsOrigin(target, vecTarget);
		TE_SetupBeamRingPoint(vecTarget, 1.0, 150.0, g_cBeam, g_cGlow, 0, 15, 0.5, 50.0, 0.0, {50, 100, 255, 50}, 10, 0);
		TE_SendToAll();
		
		SDKHook(target, SDKHook_OnTakeDamage, PropsDamage);
		SDKHook(target, SDKHook_Touch,		PropsTouched);
	}
	
	return Plugin_Handled;
}
public Action fwdOnPlayerBuild(int client, float& cooldown){
	if( rp_GetClientJobID(client) != 221 )
		return Plugin_Continue;
	int job = rp_GetClientInt(client, i_Job);
	int max, ent;
	doRP_OnClientMaxMachineCount(client, max);
	if(max >= 10000){
		ent = BuildingCashMachine(client, true);
		cooldown = 3.0;
		return Plugin_Stop;
	}
	ent = (job == 221 || job == 222) ? BuildingBigCashMachine(client) : BuildingCashMachine(client, false);
	if( ent > 0 ) {
		rp_SetClientStat(client, i_TotalBuild, rp_GetClientStat(client, i_TotalBuild)+1);
		switch(job){
			case 221: cooldown = 60.0;
			case 222: cooldown = 120.0;
			case 223: cooldown = 15.0;
			case 224: cooldown = 20.0;
			case 225: cooldown = 25.0;
			default: cooldown = 30.0;
		}
	}
	else {
		cooldown = 3.0;
	}
	return Plugin_Stop;
}
int BuildingCashMachine(int client, bool force=false) {
	#if defined DEBUG
	PrintToServer("BuildingCashMachine");
	#endif
	if( !rp_IsBuildingAllowed(client) )
		return 0;
	
	char classname[64];
	Format(classname, sizeof(classname), "rp_cashmachine");
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	vecOrigin[2] += 12.0;
	
	int count, max = 3;
	
	switch( rp_GetClientInt(client, i_Job) ) {
		case 221: max = 15; 
		case 222: max = 15;
		case 223: max = 13;
		case 224: max = 12;
		case 225: max = 11;
		case 226: max = 10;		
	}
	
	count = CountMachine(client);
	if( count == -1 )
		return 0;
	
	max += rp_GetClientInt(client, i_Machine);
	
	if( max > 15 )
		max = 15;
	
	int appart = rp_GetPlayerZoneAppart(client);
	if( appart > 0 && rp_GetAppartementInt(appart, appart_bonus_coffre) ) {
		max += 3;
	}
	
	if( count > (max-1) && !force) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez trop de machines actives.");
		return 0;
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Construction en cours...");
	
	EmitSoundToAllAny("player/ammo_pack_use.wav", client, _, _, _, 0.66);
	
	int ent = CreateEntityByName("prop_physics");
	
	DispatchKeyValue(ent, "classname", classname);
	DispatchKeyValue(ent, "model", MODEL_CASH);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	SetEntityModel(ent, MODEL_CASH);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp( ent, Prop_Data, "m_takedamage", 2);
	SetEntProp( ent, Prop_Data, "m_iHealth", 100);
	
	
	
	vecOrigin[2] -= 16.0;
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityRenderMode(ent, RENDER_NONE);
	ServerCommand("sm_effect_fading \"%i\" \"3.0\" \"0\"", ent);
	
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, 3.0);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	
	
	rp_SetBuildingData(ent, BD_started, GetTime());
	rp_SetBuildingData(ent, BD_owner, client );
	
	CreateTimer(3.0, BuildingCashMachine_post, ent);

	return ent;
}
public Action BuildingCashMachine_post(Handle timer, any entity) {
	#if defined DEBUG
	PrintToServer("BuildingCashMachine_post");
	#endif
	if( !IsValidEdict(entity) && !IsValidEntity(entity) )
		return Plugin_Handled;

	CreateTimer(20.0, Frame_CashMachine, EntIndexToEntRef(entity));
	
	SetEntProp( entity, Prop_Data, "m_takedamage", 2);
	SetEntProp( entity, Prop_Data, "m_iHealth", 100);
	
	HookSingleEntityOutput(entity, "OnBreak", BuildingCashMachine_break);
	
	return Plugin_Handled;
}
public void BuildingCashMachine_break(const char[] output, int caller, int activator, float delay) {
	#if defined DEBUG
	PrintToServer("BuildingCashMachine_break");
	#endif
	CashMachine_Destroy(caller);
	
	if( IsValidClient(activator) ) {
		rp_IncrementSuccess(activator, success_list_no_tech);
		
		if( rp_IsInPVP(caller) ) {
			int owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
			if( IsValidClient(owner) ) {
				if( rp_GetClientGroupID(activator) > 0 && rp_GetClientGroupID(owner) > 0 && rp_GetClientGroupID(activator) != rp_GetClientGroupID(owner) ) {
					CashMachine_Destroy(caller);
				}
			}
		}
	}
}
public Action Frame_CashMachine(Handle timer, any ent) {
	ent = EntRefToEntIndex(ent); if( ent == -1 ) { return Plugin_Handled; }
	#if defined DEBUG
	PrintToServer("Frame_CashMachine");
	#endif
	
	int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if( !IsValidClient(client) ) {
		rp_ScheduleEntityInput(ent, 60.0, "Kill");
		return Plugin_Handled;
	}
	
	int heal = Entity_GetHealth(ent) + Math_GetRandomInt(1, 2);
	if (heal > 100) heal = 100;
	Entity_SetHealth(ent, heal, true);
	
	if( !rp_GetClientBool(client, b_IsAFK) && rp_GetClientInt(client, i_TimeAFK) <= 60 && g_bProps_trapped[ent] == false ) {
		EmitSoundToAllAny("ambient/tones/equip3.wav", ent, _, _, _, 0.66);
		
		rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank)+1);
		rp_SetClientStat(client, i_MoneyEarned_CashMachine, rp_GetClientStat(client, i_MoneyEarned_CashMachine)+1);
		
		int capital_id = rp_GetRandomCapital( rp_GetClientJobID(client) );
		rp_SetJobCapital( capital_id, rp_GetJobCapital(capital_id)-1 );
		
		
		if( rp_GetClientJobID(client) == 221 && Math_GetRandomInt(1, 100) > 80 ) {
			rp_SetJobCapital( capital_id, rp_GetJobCapital(capital_id)-1 );
			rp_SetJobCapital( 221, rp_GetJobCapital(221)+1 );
		}
		
		if( rp_GetBuildingData(ent, BD_started)+(48*60) < GetTime() ) {
			rp_IncrementSuccess(client, success_list_technicien, 48);
		}
		
		//char szQuery[1024];
		//Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '2', '%i', '%s', '%i');",
		//"MACHINE", capital_id, GetTime(), 1, "MACHINE", 1);
		//SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery, DBPrio_Low);
	}
	
	float time = GetMachineTime(client);
	
	CreateTimer(time, Frame_CashMachine, EntIndexToEntRef(ent));
	return Plugin_Handled;
}
void CashMachine_Destroy(int entity) {
	#if defined DEBUG
	PrintToServer("CashMachine_Destroy");
	#endif
	float vecOrigin[3];
	Entity_GetAbsOrigin(entity, vecOrigin);
	
	char name[64];
	GetEdictClassname(entity, name, sizeof(name));
	
	if( rp_GetBuildingData(entity, BD_started)+120 < GetTime() ) {
		rp_Effect_SpawnMoney(vecOrigin, true);
		if( StrContains(name, "big") >= 0 ){
			for(int i = 0; i<14; i++){
			  rp_Effect_SpawnMoney(vecOrigin, true);
			}
		}
	}
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 0.5, 2, 1, 25, 25);
	TE_SendToAll();
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if( IsValidClient(owner) ) {
		if( StrContains(name, "big") >= 0 )
			CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Votre photocopieuse à faux-billets a été détruite.");
		else
			CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Une de vos machines à faux-billets a été détruite.");
		
		if( rp_GetBuildingData(entity, BD_started)+120 < GetTime() ) {
			rp_SetClientInt(owner, i_Bank, rp_GetClientInt(owner, i_Bank)-25);
		}
	}
}
void ExplodeProp(int ent) {
	#if defined DEBUG
	PrintToServer("ExplodeProp");
	#endif
	if( !g_bProps_trapped[ent] )
		return;
	
	g_bProps_trapped[ent] = false;
	
	float vecOrigin[3];
	Entity_GetAbsOrigin(ent, vecOrigin);
	
	float dmg = float(RoundToCeil(Entity_GetHealth(ent) / 5.0) + 5) * 4.0;
	
	
	rp_Effect_Explode(vecOrigin, dmg, 250.0, ent, "rp_cashmachine");
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 200, 200);
	TE_SendToAll();
	AcceptEntityInput(ent, "Kill");
	
}
public void PropsTouched(int touched, int toucher) {
	#if defined DEBUG
	PrintToServer("PropsTouched");
	#endif
	if( IsValidClient(toucher) && toucher != rp_GetBuildingData(touched, BD_owner) ) {
		ExplodeProp(touched);
	}
}
public Action PropsDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	#if defined DEBUG
	PrintToServer("PropsDamage");
	#endif
	if( attacker == inflictor && IsValidClient(attacker) ) {
		int wep_id = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		char sWeapon[32];
		
		GetEdictClassname(wep_id, sWeapon, sizeof(sWeapon));
		if( StrContains(sWeapon, "weapon_knife") == 0 || StrContains(sWeapon, "weapon_bayonet") == 0 ) {
			ExplodeProp(victim);
		}
	}
}
// ------------------------------------------------------------------------------
public Action Cmd_ItemCashBig(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCashBig");
	#endif
	
	int client = GetCmdArgInt(1);
	
	if( rp_GetClientJobID(client) == 1 || rp_GetClientJobID(client) == 101 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit aux forces de l'ordre.");
		return Plugin_Handled;
	}
	
	int target = BuildingBigCashMachine(client);
	
	if( target == 0 ) {
		char arg_last[12];
		GetCmdArg(args, arg_last, 11);
		int item_id = StringToInt(arg_last);
		
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	rp_SetClientInt(client, i_Machine, 14);
	g_bProps_trapped[target] = false;
	return Plugin_Handled;
}
int BuildingBigCashMachine(int client) {
	#if defined DEBUG
	PrintToServer("BuildingBigCashMachine");
	#endif
	if( !rp_IsBuildingAllowed(client) )
		return 0;
	
	char bigclassname[64];
	Format(bigclassname, sizeof(bigclassname), "rp_bigcashmachine");
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin);
	vecOrigin[2] += 12.0;
	
	int count, max = 15;
	
	switch( rp_GetClientInt(client, i_Job) ) {
		case 221: max = 15; 
		case 222: max = 15;
		case 223: max = 13;
		case 224: max = 12;
		case 225: max = 11;
		case 226: max = 10;		
	}
	
	count = CountMachine(client);
	if( count == -1 )
		return 0;
	
	int appart = rp_GetPlayerZoneAppart(client);
	if( appart > 0 && rp_GetAppartementInt(appart, appart_bonus_coffre) ) {
		max += 3;
	}
	
	if( count > (max-15) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez trop de machines actives.");
		return 0;
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Construction en cours...");
	
	EmitSoundToAllAny("player/ammo_pack_use.wav", client, _, _, _, 0.66);
	
	int ent = CreateEntityByName("prop_physics");
	
	DispatchKeyValue(ent, "classname", bigclassname);
	DispatchKeyValue(ent, "model", MODEL_CASHBIG);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	SetEntityModel(ent, MODEL_CASHBIG);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp( ent, Prop_Data, "m_takedamage", 2);
	SetEntProp( ent, Prop_Data, "m_iHealth", 1000);	
	
	vecOrigin[2] -= 16.0;
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityRenderMode(ent, RENDER_NONE);
	ServerCommand("sm_effect_fading \"%i\" \"5.0\" \"0\"", ent);
	
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, 5.0);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	
	
	rp_SetBuildingData(ent, BD_started, GetTime());
	rp_SetBuildingData(ent, BD_owner, client );
	
	CreateTimer(5.0, BuildingBigCashMachine_post, ent);

	return ent;
}
public Action BuildingBigCashMachine_post(Handle timer, any entity) {
	#if defined DEBUG
	PrintToServer("BuildingBigCashMachine_post");
	#endif
	if( !IsValidEdict(entity) && !IsValidEntity(entity) )
		return Plugin_Handled;

	CreateTimer(2.0, Frame_BigCashMachine, EntIndexToEntRef(entity));
	
	SetEntProp( entity, Prop_Data, "m_takedamage", 2);
	SetEntProp( entity, Prop_Data, "m_iHealth", 1000);
	
	HookSingleEntityOutput(entity, "OnBreak", BuildingCashMachine_break);
	
	return Plugin_Handled;
}
public Action Frame_BigCashMachine(Handle timer, any ent) {
	ent = EntRefToEntIndex(ent); if( ent == -1 ) { return Plugin_Handled; }
	#if defined DEBUG
	PrintToServer("Frame_BigCashMachine");
	#endif
	
	int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	if( !IsValidClient(client) ) {
		rp_ScheduleEntityInput(ent, 60.0, "Kill");
		return Plugin_Handled;
	}
	
	int heal = Entity_GetHealth(ent) + Math_GetRandomInt(1, 2);
	if (heal > 1000) heal = 1000;
	Entity_SetHealth(ent, heal, true);
	
	if( !rp_GetClientBool(client, b_IsAFK) && rp_GetClientInt(client, i_TimeAFK) <= 60 && g_bProps_trapped[ent] == false ) {
		EmitSoundToAllAny("ambient/tones/equip3.wav", ent, _, _, _, 1.0);
		
		rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank)+2);
		rp_SetClientStat(client, i_MoneyEarned_CashMachine, rp_GetClientStat(client, i_MoneyEarned_CashMachine)+2);
		
		int capital_id = rp_GetRandomCapital( rp_GetClientJobID(client) );
		rp_SetJobCapital( capital_id, rp_GetJobCapital(capital_id)-2 );
		
		
		if( rp_GetClientJobID(client) == 221 && Math_GetRandomInt(1, 100) > 80 ) {
			rp_SetJobCapital( capital_id, rp_GetJobCapital(capital_id)-2 );
			rp_SetJobCapital( 221, rp_GetJobCapital(221)+2 );
		}
		
		if( rp_GetBuildingData(ent, BD_started)+(48*60) < GetTime() ) {
			rp_IncrementSuccess(client, success_list_technicien, 48);
		}
		
		//char szQuery[1024];
		//Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '2', '%i', '%s', '%i');",
		//"MACHINE", capital_id, GetTime(), 1, "MACHINE", 15);
		//SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery, DBPrio_Low);
	}

	float time = GetMachineTime(client);
	
	CreateTimer(time/7.5, Frame_BigCashMachine, EntIndexToEntRef(ent));
	return Plugin_Handled;
}
float GetMachineTime(int client) {
	if( rp_GetClientBool(client, b_HasVilla) && rp_GetClientPvPBonus(client, cap_villa) )
		return Math_GetRandomFloat(8.0, 12.0);
	else if( rp_GetClientBool(client, b_HasVilla) || rp_GetClientPvPBonus(client, cap_villa) )
		return Math_GetRandomFloat(12.0, 18.0);
	else
		return Math_GetRandomFloat(18.0, 22.0);
}
int CountMachine(int client) {
	int count = 0;
	char classname[64], bigclassname[64], tmp[64];
	float vecOrigin[3], vecOrigin2[3];
	GetClientAbsOrigin(client, vecOrigin);
	Format(bigclassname, sizeof(bigclassname), "rp_bigcashmachine");
	Format(classname, sizeof(classname), "rp_cashmachine");
	
	for(int i=MaxClients; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, tmp, 63);
		
		if( StrEqual(bigclassname, tmp) && rp_GetBuildingData(i, BD_owner) == client ){
			count += 15;
			Entity_GetAbsOrigin(i, vecOrigin2);
			if( GetVectorDistance(vecOrigin, vecOrigin2) <= 50 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas construire aussi proche d'une autre machine vous appartenant.");
				return -1;
			}
		}
		if( StrEqual(classname, tmp) && rp_GetBuildingData(i, BD_owner) == client ) {
			count++;
			Entity_GetAbsOrigin(i, vecOrigin2);
			if( GetVectorDistance(vecOrigin, vecOrigin2) <= 24 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas construire aussi proche d'une autre machine vous appartenant.");
				return -1;
			}
		}
	}
	
	return count;
}
