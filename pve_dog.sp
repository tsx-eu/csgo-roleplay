#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors_csgo>  // https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>      	// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#include <pve.inc>
#include <roleplay.inc>   // https://www.ts-x.eu

char g_szFullname[PLATFORM_MAX_PATH] =	"Chien";
char g_szName[PLATFORM_MAX_PATH] =	"dog";
char g_szModel[PLATFORM_MAX_PATH] =	"models/npc/dog/npc_dog.mdl";

int g_iClientLastDamage[65][3];

public void OnPluginStart() {
	RegServerCmd("sm_pve_reload", Cmd_PluginReloadSelf);
	
	RegServerCmd("rp_item_dog",		Cmd_ItemDog,			"RP-ITEM",	FCVAR_UNREGISTERED);
}
public Action Cmd_ItemDog(int args) {
	int client = GetCmdArgInt(1);
	float pos[3], ang[3];
	GetClientAbsOrigin(client, pos);
	
	int ent = PVE_Spawn(PVE_GetId(g_szName), pos, ang);
	Entity_SetOwner(ent, client);
	PVE_RegEvent(ent, ESE_FollowChange, OnFollowChange);
	PVE_RegEvent(ent, ESE_CanAttack, OnWantAttack);
	PVE_RegEvent(ent, ESE_Dead, OnDead);
	
	
	rp_HookEvent(client, RP_PreTakeDamage, OnDamage);
}
public Action OnDamage(int victim, int attacker, float &damage) {
	g_iClientLastDamage[victim][0] = attacker;
	g_iClientLastDamage[victim][1] = GetTime() + 20;	
	g_iClientLastDamage[victim][2] = RoundToCeil(damage);
}
public Action OnFollowChange(int id, int entity, int& target) {
	int owner = Entity_GetOwner(entity);
	
	target = owner;
	if( IsValidClient(g_iClientLastDamage[owner][0]) && g_iClientLastDamage[owner][1] > GetTime() )
		target = g_iClientLastDamage[owner][0];
	
	return Plugin_Changed;
}
public bool OnWantAttack(int id, int entity, int target) {
	if( target == Entity_GetOwner(entity) )
		return false;
	return true;
}
public void OnAllPluginsLoaded() {
	int id = PVE_Create(g_szFullname, g_szName, g_szModel);
	
	PVE_SetInt(id, ESI_MaxHealth, 		500);
	PVE_SetInt(id, ESI_AttackType,		view_as<int>(ESA_Melee));
	PVE_SetInt(id, ESI_AttackDamage,	50);
	PVE_SetInt(id, ESI_MaxSkin, 		1);
	
	PVE_SetFloat(id, ESF_Speed,			300.0);
	PVE_SetFloat(id, ESF_Gravity,		1.0);
	PVE_SetFloat(id, ESF_ScaleSize,		1.0);
	PVE_SetFloat(id, ESF_FeetSize,  	0.0);
	PVE_SetFloat(id, ESF_AttackSpeed,	40/50.0);
	PVE_SetFloat(id, ESF_AttackRange,	RANGE_MELEE);
	
	PVE_AddAnimation(id, EAA_Idle, 		 1,	 40, 24);
	PVE_AddAnimation(id, EAA_Idle, 		 2,	134, 24);
	PVE_AddAnimation(id, EAA_Idle, 		 3,	34,  24);
	
	PVE_AddAnimation(id, EAA_Run, 		 5,	 15, 24);
	PVE_AddAnimation(id, EAA_Attack, 	 6,	 15, 24);
	PVE_AddAnimation(id, EAA_Attack, 	 7,  40, 24);
	
	PVE_AddAnimation(id, EAA_Deading, 	16,	 40, 24);
	PVE_AddAnimation(id, EAA_Dead, 		0,	  1, 24);
	
	PVE_RegHook(id, ESH_PreAttack,		OnPreAttack);
	PVE_RegHook(id, ESH_Attack,			OnAttack);
}
public Action OnPreAttack(int id, int entity, int target) {	
	PVE_RunAnimation(entity, EAA_Attack);
	return Plugin_Continue;
}
public Action OnAttack(int id, int entity, int target) {	
	return Plugin_Continue;
}
public void OnDead(int id, int entity, int target) {
	int owner = Entity_GetOwner(entity);
	rp_UnhookEvent(owner, RP_PreTakeDamage, OnDamage);
}

public void OnMapStart() {
	PrecacheModel(g_szModel);
	AddModelToDownloadsTable(g_szModel);
}
