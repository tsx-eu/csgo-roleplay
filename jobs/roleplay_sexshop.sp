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
#define MAX_AREA_DIST		500.0
#define MODEL_BAGAGE 		"models/props/cs_office/box_office_indoor_32.mdl"
public Plugin myinfo = {
	name = "Jobs: Sexshop", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Sexshop",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_cBeam, g_cGlow, g_cExplode;
Handle g_hCigarette[65];
// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	RegServerCmd("rp_item_preserv",		Cmd_ItemPreserv,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_poupee",		Cmd_ItemPoupee,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_menottes",	Cmd_ItemMenottes,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_sucette",		Cmd_ItemSucette,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_sucetteduo",	Cmd_ItemSucette2,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_fouet",		Cmd_ItemFouet,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_alcool",		Cmd_ItemAlcool,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_lube",		Cmd_ItemLube,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_kevlarbox",	Cmd_ItemKevlarBox,		"RP-ITEM", 	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_cig", 		Cmd_ItemCigarette,		"RP-ITEM",	FCVAR_UNREGISTERED);	
	RegServerCmd("rp_item_ruban",		Cmd_ItemRuban,			"RP-ITEM",	FCVAR_UNREGISTERED);
	
	for (int i = 1; i <= MaxClients; i++) 
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
	g_cExplode = PrecacheModel("materials/sprites/muzzleflash4.vmt", true);
	PrecacheModel(MODEL_BAGAGE, true);
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerBuild,	fwdOnPlayerBuild);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPreserv(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPreserv");
	#endif
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	int kevlar = rp_GetClientInt(client, i_Kevlar);
	if( kevlar >= 250 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	kevlar += 5;
	if( kevlar > 250 )
		kevlar = 250;
	
	rp_SetClientInt(client, i_Kevlar, kevlar);
	return Plugin_Handled;
}
public Action fwdInvincible(int client, int attacker, float& damage) {
	damage = 0.0;
	return Plugin_Stop;
}
public Action fwdFrozen(int client, float& speed, float& gravity) {
	speed = 0.0;
	return Plugin_Stop;
}
public Action fwdSlowTime(int client, float& speed, float& gravity) {
	speed -= 5.0;
	return Plugin_Changed;
}
public Action Cmd_ItemPoupee(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPoupee");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( !rp_GetClientBool(client, b_MayUseUltimate) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas utiliser cet item pour le moment.");
		return Plugin_Handled;
	}
	
	rp_HookEvent(client, RP_PreTakeDamage, fwdInvincible, 5.0);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, 5.0);
	rp_SetClientFloat(client, fl_Invincible, GetGameTime() + 5.0);
	
	int heal = GetClientHealth(client) + 100;
	int kevlar = rp_GetClientInt(client, i_Kevlar) + 25;
	
	if( kevlar > 250 )
		kevlar = 250;
	if( heal > 500 )
		heal = 500;
		
	SetEntityHealth(client, heal);
	rp_SetClientInt(client, i_Kevlar, kevlar);	
	
	float vecTarget[3];
	GetClientAbsOrigin(client, vecTarget);
	vecTarget[2] += 10.0;
	
	TE_SetupBeamRingPoint(vecTarget, 30.0, 40.0, g_cBeam, g_cGlow, 0, 0, 5.0, 80.0, 0.0, {250, 250, 50, 250}, 0, 0);
	TE_SendToAll();

	rp_SetClientBool(client, b_MayUseUltimate, false);

	CreateTimer(30.0, AllowUltimate, client);
	return Plugin_Handled;
}

public Action AllowUltimate(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("AllowUltimate");
	#endif

	rp_SetClientBool(client, b_MayUseUltimate, true);
}
public Action fwdTazerRose(int client, int color[4]) {
	#if defined DEBUG
	PrintToServer("fwdTazerRose");
	#endif
	color[0] += 255;
	color[1] -= 50;
	color[2] += 50;
	color[3] += 50;
	return Plugin_Changed;
}
public Action Cmd_ItemMenottes(int args){
	#if defined DEBUG
	PrintToServer("Cmd_ItemMenottes");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	if( GetClientTeam(client) == CS_TEAM_CT ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit aux forces de l'ordre.");
		ITEM_CANCEL(client, item_id);
		return;
	}
	
	int target = rp_GetClientTarget(client);
	if( !IsValidClient(target) || !rp_IsTutorialOver(target) ) {
		ITEM_CANCEL(client, item_id);
		return;
	}
	if( rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_PEACEFULL || rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_PEACEFULL) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit où vous êtes.");
		ITEM_CANCEL(client, item_id);
		return;
	}
	if( GetEntityMoveType(target) == MOVETYPE_NOCLIP ) {
		ITEM_CANCEL(client, item_id);
		return;
	}
	if( rp_GetClientBool(target, b_Lube) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N vous glisse entre les mains.", target);
		ITEM_CANCEL(client, item_id);
		return;
	}
	
	if( rp_ClientFloodTriggered(client, target, fd_menotte) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N vous glisse entre les mains.", target);
		return;
	}
	rp_ClientFloodIncrement(client, target, fd_menotte, 5.0);
					
	rp_SetClientInt(client, i_LastAgression, GetTime());
	rp_IncrementSuccess(client, success_list_menotte);
	rp_Effect_Tazer(client, target);
	rp_ClientColorize(target, { 255, 175, 200, 255 } );
	
	rp_HookEvent(target, RP_PrePlayerPhysic, fwdFrozen, 5.0);
	rp_HookEvent(target, RP_PreHUDColorize, fwdTazerRose, 5.0);
	
	LogToGame("[TSX-RP] [MENOTTES] %L a attaché %L.", client, target); // Ajout dans les logs
	CreateTimer(5.0, Cmd_ItemMenottes_Over, target); // TODO: Laisser rose après 5 secondes.
}
public Action Cmd_ItemMenottes_Over(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemMenottes_Over");
	#endif
	
	rp_ClientColorize(client);
}
public Action Cmd_ItemSucette(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemSucette");
	#endif
	
	int client = GetCmdArgInt(1);
		
	if( Client_IsInVehicle(client) || rp_GetClientVehiclePassager(client) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible d'utiliser cet objet dans une voiture.");
		int item_id = GetCmdArgInt(args);
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}

	float Origin[3];	
	GetClientAbsOrigin(client, Origin);
	
	TE_SetupExplosion(Origin, g_cExplode, GetRandomFloat(0.5, 2.0), 2, 1, Math_GetRandomInt(25, 100) , Math_GetRandomInt(25, 100) );
	TE_SendToAll();
	
	SDKHooks_TakeDamage(client, client, client, 5000.0);
	return Plugin_Handled;
}
public Action Cmd_ItemSucette2(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemSucette2");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( !rp_GetClientBool(client, b_MayUseUltimate) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas utiliser cet item pour le moment.");
		return Plugin_Handled;
	}
	
	if( Client_IsInVehicle(client) || rp_GetClientVehiclePassager(client) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible d'utiliser cet objet dans une voiture.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	
	rp_SetClientBool(client, b_MayUseUltimate, false);
	
	float duration = 1.0;
	if( rp_IsInPVP(client) || GetClientTeam(client) == CS_TEAM_CT) {
		CreateTimer(45.0, AllowUltimate, client);
		duration += 0.66;
	}
	else{
		CreateTimer(30.0, AllowUltimate, client);
	}

	rp_SetClientInt(client, i_LastAgression, GetTime());
	EmitSoundToAll("UI/arm_bomb.wav", client);
	
	CreateTimer((duration / 4.0) * 1.0, Beep, client);
	CreateTimer((duration / 4.0) * 2.0, Beep, client);
	CreateTimer((duration / 4.0) * 3.0, Beep, client);
	CreateTimer(duration, 				Cmd_ItemSucette2_task, client);
	
	return Plugin_Handled;
}
public Action Beep(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Beep");
	#endif
	
	EmitSoundToAll("UI/arm_bomb.wav", client);
}
public Action Cmd_ItemSucette2_task(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemSucette2_task");
	#endif
	
	if( !IsValidClient(client) )
		return Plugin_Handled;
	if( !IsPlayerAlive(client) )
		return Plugin_Handled;
	
	int lenght = (GetClientHealth(client)*2);
	
	if( lenght > 1000 )
		lenght = 1000;
	
	if( rp_IsInPVP(client) )
		lenght = RoundToFloor(float(lenght) / 2.0);
	
	float Origin[3];
	GetClientAbsOrigin(client, Origin);
	TE_SetupExplosion(Origin, g_cExplode, GetRandomFloat(0.5, 2.0), 2, 1, Math_GetRandomInt(25, 100) , Math_GetRandomInt(25, 100) );
	TE_SendToAll();
	
	int amount = rp_Effect_Explode(Origin, float(lenght)*2.0, float(lenght), client, "weapon_sucetteduo");
	rp_Effect_Push(Origin, float(lenght), float(lenght));
	
	SDKHooks_TakeDamage(client, client, client, 5000.0);
	
	if( amount >= 10 )
		rp_IncrementSuccess(client, success_list_sexshop, 10);
	
	return Plugin_Handled;
}


public Action Cmd_ItemFouet(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemFouet");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int target = rp_GetClientTarget(client);
	
	if( !IsValidClient(target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	if( Entity_GetDistance(client, target) > MAX_AREA_DIST ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	if( !rp_IsTutorialOver(target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	if( rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_PEACEFULL ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	if( rp_ClientFloodTriggered(client, target, fd_fouet) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N vous glisse entre les mains.", target);
		return Plugin_Handled;
	}
	rp_ClientFloodIncrement(client, target, fd_fouet, 5.0);
	
	rp_SetClientInt(client, i_LastAgression, GetTime());
	rp_Effect_Tazer(client, target);
	rp_ClientDamage(target, rp_GetClientInt(client, i_KnifeTrain), client);
	
	SlapPlayer(target, 0, true);
	SlapPlayer(target, 0, true);
	EmitSoundToAll("tsx/roleplay/fouet.mp3", target);

	
	rp_HookEvent(target, RP_PreHUDColorize, fwdSlowTime, 5.0);
	
	return Plugin_Handled;
}
public Action Cmd_ItemAlcool(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemAlcool");
	#endif
	char arg[16];
	int client, target, item_id;
	client = GetCmdArgInt(3);
	item_id = GetCmdArgInt(args);
	GetCmdArg(1, arg, sizeof(arg));

	if(StrEqual(arg,"me")){
		target = client;
	}
	else if (StrEqual(arg,"aim")){
		target = rp_GetClientTarget(client);
		if(target == -1 || !rp_IsEntitiesNear(client, target, true)){
			ITEM_CANCEL(client,item_id);
			return Plugin_Handled;
		}
		if( rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_PEACEFULL ) {
			ITEM_CANCEL(client, item_id);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit où vous êtes.");
			return Plugin_Handled;
		}
		if( rp_GetClientFloat(target, fl_Alcool) > 0.0 ) {
			ITEM_CANCEL(client, item_id);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N a trop bu, il n'est pas raisonable de lui donner à boire.", target);
			return Plugin_Handled;
		}
		float vecTarget[3];
		GetClientAbsOrigin(client, vecTarget);
		TE_SetupBeamRingPoint(vecTarget, 10.0, 500.0, g_cBeam, g_cGlow, 0, 15, 0.5, 50.0, 0.0, { 255, 0, 191, 200}, 10, 0);
		rp_SetClientInt(client, i_LastAgression, GetTime());
		LogToGame("[TSX-RP] [DROGUE] %L a alcoolisé %L.", client, target);
	}

	float level = rp_GetClientFloat(target, fl_Alcool) + GetCmdArgFloat(2);
	rp_SetClientFloat(target, fl_Alcool, level);
	rp_IncrementSuccess(target, success_list_alcool_abuse);	
	if( level > 4.0 ) {
		SDKHooks_TakeDamage(target, target, target, (25 + GetClientHealth(target))/2.0);
	}
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemKevlarBox(int args) {
	int client = GetCmdArgInt(1);
	
	if( BuildingKevlarBox(client) == 0 ) {
		int item_id = GetCmdArgInt(args);
		
		ITEM_CANCEL(client, item_id);
	}
}
public Action fwdOnPlayerBuild(int client, float& cooldown) {
	if( rp_GetClientJobID(client) != 191 )
		return Plugin_Continue;
	
	int ent = BuildingKevlarBox(client);
	
	if( ent > 0 ) {
		rp_SetClientStat(client, i_TotalBuild, rp_GetClientStat(client, i_TotalBuild)+1);
		rp_ScheduleEntityInput(ent, 300.0, "Kill");
		cooldown = 30.0;
	}
	else {
		cooldown = 3.0;
	}
	return Plugin_Stop;
}

int BuildingKevlarBox(int client) {
	#if defined DEBUG 
	PrintToServer("BuildingKevlarBox");
	#endif
	
	if( !rp_IsBuildingAllowed(client) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas construire ici.");
		return 0;
	}
	
	char classname[64], tmp[64];
	Format(classname, sizeof(classname), "rp_kevlarbox");
	
	float vecOrigin[3], vecOrigin2[3];
	GetClientAbsOrigin(client, vecOrigin);
	
	for(int i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
			
		GetEdictClassname(i, tmp, 63);
		
		if( StrEqual(classname, tmp) && rp_GetBuildingData(i, BD_owner) == client ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà une valise remplie de préservatifs.");
			return 0;
		}
		if( StrEqual(tmp, "rp_kevlarbox") ) {
			Entity_GetAbsOrigin(i, vecOrigin2);
			if( GetVectorDistance(vecOrigin, vecOrigin2) < 600 ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il existe une autre valise remplie de préservatifs à proximité.");
				return 0;
			}
		}
	}
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Construction en cours...");
	
	EmitSoundToAllAny("player/ammo_pack_use.wav", client, _, _, _, 0.66);
	
	int ent = CreateEntityByName("prop_physics");
	
	DispatchKeyValue(ent, "classname", classname);
	DispatchKeyValue(ent, "model", MODEL_BAGAGE);
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	SetEntityModel(ent, MODEL_BAGAGE);
	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp( ent, Prop_Data, "m_takedamage", 2);
	SetEntProp( ent, Prop_Data, "m_iHealth", 1000);
	
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	
	SetEntityRenderMode(ent, RENDER_NONE);
	ServerCommand("sm_effect_fading \"%i\" \"2.5\" \"0\"", ent);
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	
	rp_SetBuildingData(ent, BD_started, GetTime());
	rp_SetBuildingData(ent, BD_owner, client );
	
	CreateTimer(3.0, BuildingKevlarBox_post, ent);

	return ent;
	
}
public Action BuildingKevlarBox_post(Handle timer, any entity) {
	#if defined DEBUG
	PrintToServer("BuildingKevlarBox_post");
	#endif
	
	if( !IsValidEdict(entity) && !IsValidEntity(entity) )
		return Plugin_Handled;
		
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	
	if( rp_IsInPVP(entity) ) {
		rp_ClientColorize(entity);
	}
	
	SetEntProp( entity, Prop_Data, "m_takedamage", 2);
	SetEntProp( entity, Prop_Data, "m_iHealth", 1000);
	HookSingleEntityOutput(entity, "OnBreak", BuildingKevlarBox_break);
	
	CreateTimer(1.0, Frame_KevlarBox, EntIndexToEntRef(entity));
	
	return Plugin_Handled;
}
public void BuildingKevlarBox_break(const char[] output, int caller, int activator, float delay) {
	#if defined DEBUG
	PrintToServer("BuildingKevlarBox_break");
	#endif
	
	int client = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");
	CPrintToChat(client,"{lightblue}[TSX-RP]{default} Votre valise remplie de préservatifs a été détruite.");
	
	float vecOrigin[3];
	Entity_GetAbsOrigin(caller,vecOrigin);
	TE_SetupSparks(vecOrigin, view_as<float>({0.0,0.0,1.0}),120,40);
	TE_SendToAll();
	
	//rp_Effect_Explode(vecOrigin, 100.0, 400.0, client);
}
public Action Frame_KevlarBox(Handle timer, any ent) {
	ent = EntRefToEntIndex(ent); if( ent == -1 ) { return Plugin_Handled; }
	#if defined DEBUG
	PrintToServer("Frame_KevlarBox");
	#endif
	
	float vecOrigin[3], vecOrigin2[3];
	Entity_GetAbsOrigin(ent, vecOrigin);
	vecOrigin[2] += 12.0;
	
	bool inPvP = rp_IsInPVP(ent);
	float maxDist = 240.0;
	if( inPvP )
		maxDist = 180.0;
	
	int boxHeal = GetEntProp(ent, Prop_Data, "m_iHealth"), kevlar, toKevlar;
	float dist;
	
	int owner = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");	
	if( !IsValidClient(owner) ) {
		rp_ScheduleEntityInput(ent, 60.0, "Kill");
		return Plugin_Handled;
	}
	int gOWNER = rp_GetClientGroupID(owner);
	
	for(int client=1; client<=MaxClients; client++) {
		
		if( !IsValidClient(client) )
			continue;
		if( boxHeal < 100 )
			break;
		if( inPvP && rp_GetClientGroupID(client) != gOWNER )
			continue;
		
		GetClientAbsOrigin(client, vecOrigin2);
		vecOrigin2[2] += 24.0;
		
		dist = GetVectorDistance(vecOrigin, vecOrigin2);
		if( dist > maxDist )
			continue;
		
		kevlar = rp_GetClientInt(client, i_Kevlar);
		if( kevlar >= 250 )
			continue;
		
		Handle trace = TR_TraceRayFilterEx(vecOrigin, vecOrigin2, MASK_SHOT, RayType_EndPoint, FilterToOne, ent);
		
		if( TR_DidHit(trace) ) {
			if( TR_GetEntityIndex(trace) != client ) {
				CloseHandle(trace);
				continue;
			}
		}
		
		CloseHandle(trace);
		
		if( inPvP || rp_IsInPVP(client) ) {
			toKevlar = 3;
			kevlar += 3;
		}
		else {
			toKevlar = 6;
			kevlar += 6;
		}
		
		if( kevlar > 250 )
			kevlar = 250;
			
		boxHeal -= toKevlar;
		rp_SetClientInt(client, i_Kevlar, kevlar);
	}
	boxHeal += 5;
	if( boxHeal > 1500 )
		boxHeal = 1500;
	if( !inPvP )
		boxHeal += Math_GetRandomInt(5, 20);
	
	SetEntProp(ent, Prop_Data, "m_iHealth", boxHeal);
	
	TE_SetupBeamRingPoint(vecOrigin, 1.0, maxDist, g_cBeam, g_cBeam, 1, 20, 1.0, 20.0, 0.0, {0, 0, 255, 128}, 10, 0);
	TE_SendToAll();
	
	CreateTimer(1.0, Frame_KevlarBox, EntIndexToEntRef(ent));
	return Plugin_Handled;
}
public Action Cmd_ItemLube(int args){
	#if defined DEBUG
	PrintToServer("Cmd_ItemLube");
	#endif
	int client = GetCmdArgInt(1);

	rp_SetClientBool(client, b_Lube, true);
	rp_HookEvent(client, RP_PreHUDColorize, fwdLube, 30.0);
	rp_HookEvent(client, RP_OnAssurance,	fwdAssurance);
	
	return Plugin_Handled;
}
public Action fwdAssurance(int client, int& amount) {
	if( rp_GetClientBool(client, b_Lube) )
		amount += 1000;
}

public Action fwdLube(int client, int color[4]){
	#if defined DEBUG
	PrintToServer("fwdLube");
	#endif
	
	color[0] += 255;
	color[1] += 191;
	color[2] += 255;
	color[3] += 50;
	return Plugin_Changed;
}

// ----------------------------------------------------------------------------
public Action Cmd_ItemCigarette(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemCigarette");
	#endif
	
	char Arg1[32];
	GetCmdArg(1, Arg1, 31);
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	
	
	if( StrEqual(Arg1, "deg") ) {
		if( !rp_GetClientBool(client, b_MayUseUltimate) ) {
			ITEM_CANCEL(client, item_id);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas utiliser cet item pour le moment.");
			return Plugin_Handled;
		}
		rp_SetClientBool(client, b_MayUseUltimate, false);
		CreateTimer(10.0, AllowUltimate, client);
		rp_SetClientInt(client, i_LastAgression, GetTime());
		float origin[3];
		GetClientAbsOrigin(client, origin);
		origin[2] -= 1.0;
		rp_Effect_Push(origin, 500.0, 1000.0, client);
	}
	else if( StrEqual(Arg1, "flame") ) {
		UningiteEntity(client);
		for(float i=0.1; i<=30.0; i+= 0.50) {
			CreateTimer(i, Task_UningiteEntity, client);
		}
	}
	else if( StrEqual(Arg1, "light") ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigGravity, 30.0);
	}
	else if( StrEqual(Arg1, "choco") ) {
		// Ne fait absolument rien.
	}
	else { // WHAT IS THAT KIND OF SORCELERY?
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdCigSpeed, 30.0);
	}
	
	ServerCommand("sm_effect_particles %d shacks_exhaust 30 forward", client);
	
	if( g_hCigarette[client] )
		delete g_hCigarette[client];
	
	g_hCigarette[client] = CreateTimer( 30.0, ItemStopCig, client);
	rp_SetClientBool(client, b_Smoking, true);
	
	return Plugin_Handled;
}
public Action Task_UningiteEntity(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Task_UningiteEntity");
	#endif
	UningiteEntity(client);
}
public Action ItemStopCig(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("ItemStopCig");
	#endif
	
	rp_SetClientBool(client, b_Smoking, false);
}
public Action fwdCigSpeed(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdCigSpeed");
	#endif
	speed += 0.15;
	
	return Plugin_Changed;
}
public Action fwdCigGravity(int client, float& speed, float& gravity) {
	#if defined DEBUG
	PrintToServer("fwdCigGravity");
	#endif
	gravity -= 0.15;
	
	return Plugin_Changed;
}


public Action Cmd_ItemRuban(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemRuban");
	#endif

	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	rp_ClientGiveItem(client, item_id);
	
	Handle dp;
	CreateDataTimer(0.25, Cmd_ItemRuban_Task, dp);
	WritePackCell(dp, client);
	WritePackCell(dp, item_id);
	
	
	return Plugin_Handled;
}
public Action Cmd_ItemRuban_Task(Handle timer, any dp) {
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int item_id = ReadPackCell(dp);
	
	char tmp[32];
	Handle menu = CreateMenu(MenuRubanWho);
	SetMenuTitle(menu, "Sur qui mettre le ruban ?");
	Format(tmp, 31, "%i_target", item_id);
	AddMenuItem(menu, tmp, "Ce que je vise");
	Format(tmp, 31, "%i_client", item_id);
	AddMenuItem(menu, tmp, "Moi");
	DisplayMenu(menu, client, 60);
	
	CloseHandle(dp);
	return Plugin_Handled;
}
public int MenuRubanWho(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		int target;
		char options[64], data[2][32];
		GetMenuItem(menu, param2, options, 63);
		ExplodeString(options, "_", data, sizeof(data), sizeof(data[]));
		if(StrEqual(data[1],"client")){
			target = client;
		}
		else{
			target = GetClientAimTarget(client, false);
			if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre cible n'est pas valide.");
				return;
			}
			char classname[64];
			GetEdictClassname(target, classname, sizeof(classname));

			if( StrContains("chicken|player|weapon|prop_physics|", classname) == -1 ){
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre cible n'est pas valide.");
				return;
			}

			if( !rp_IsEntitiesNear(client, target) ){
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre cible est trop loin.");
				return;
			}
		}
		char tmp[64];
		Handle menucolor = CreateMenu(MenuRubanColor);
		SetMenuTitle(menucolor, "De quelle couleur ?");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 255, 0  , 0  , 200);
		AddMenuItem(menucolor, tmp, "Rouge");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 0  , 255, 0  , 200);
		AddMenuItem(menucolor, tmp, "Vert");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 0  , 0  , 255, 200);
		AddMenuItem(menucolor, tmp, "Bleu");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 255, 255, 255, 200);
		AddMenuItem(menucolor, tmp, "Blanc");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 122, 122, 0  , 200);
		AddMenuItem(menucolor, tmp, "Jaune");
		Format(tmp,63,"%s_%i_%i_%i_%i_%i", data[0], target, 253, 108, 158, 200);
		AddMenuItem(menucolor, tmp, "Rose");
		DisplayMenu(menucolor, client, 20);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public int MenuRubanColor(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64], data[6][32];
		int color[4];
		GetMenuItem(menu, param2, options, 63);
		ExplodeString(options, "_", data, sizeof(data), sizeof(data[]));
		int item_id = StringToInt(data[0]);
		int target = StringToInt(data[1]);
		color[0] = StringToInt(data[2]);
		color[1] = StringToInt(data[3]);
		color[2] = StringToInt(data[4]);
		color[3] = StringToInt(data[5]);
		if( target == 0 || !IsValidEdict(target) || !IsValidEntity(target) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre cible a disparue.");
			return;
		}
		if(rp_GetClientItem(client, item_id)==0){
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez plus l'item ruban.");
			return;
		}
		else{
			rp_ClientGiveItem(client, item_id, -1);
		}

		TE_SetupBeamFollow(target, g_cBeam, 0, 180.0, 4.0, 0.1, 5, color);
		TE_SendToAll();
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
void UningiteEntity(int entity) {
	
	int ent = GetEntPropEnt(entity, Prop_Data, "m_hEffectEntity");
	if( IsValidEdict(ent) )
		SetEntPropFloat(ent, Prop_Data, "m_flLifetime", 0.0); 
}
