#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <emitsoundany>
#include <smlib>

#include <pve.inc>

char g_szName[PLATFORM_MAX_PATH] =	"Squelette arché";
char g_szModel[PLATFORM_MAX_PATH] =	"models/npc/tsx/skeleton/skeleton.mdl";
char g_szModel2[PLATFORM_MAX_PATH] =	"models/npc/tsx/skeleton/skeleton_arrow.mdl";

char g_szMaterials[][PLATFORM_MAX_PATH] = {
	"materials/models/npc/tsx/skeleton/DS_equipment_standard.vtf",
	"materials/models/npc/tsx/skeleton/DS_equipment_standard.vmt",
	"materials/models/npc/tsx/skeleton/DS_skeleton_standard.vtf",
	"materials/models/npc/tsx/skeleton/DS_skeleton_standard.vmt"
};
char g_szSounds[][PLATFORM_MAX_PATH] = {
	"weapons/knife/knife_hit1.wav",
	"weapons/knife/knife_hit2.wav",
	"weapons/knife/knife_hit3.wav",
	"weapons/knife/knife_hit4.wav",
	
	"DeadlyDesire/halloween/zombie/spawn1.mp3",
	"DeadlyDesire/halloween/zombie/spawn2.mp3",
	"DeadlyDesire/halloween/zombie/spawn3.mp3",
	
	"DeadlyDesire/halloween/zombie/die1.mp3",
	"DeadlyDesire/halloween/zombie/die2.mp3",
	"DeadlyDesire/halloween/zombie/die3.mp3"
};

public void OnAllPluginsLoaded() {
	int id = PVE_Create(g_szName, g_szModel);
	
	PVE_SetInt(id, ESI_MaxHealth, 		1000);
	PVE_SetInt(id, ESI_AttackType,		view_as<int>(ESA_Weapon));
	PVE_SetInt(id, ESI_AttackDamage,	100);
	PVE_SetInt(id, ESI_MinSkin, 		0);
	PVE_SetInt(id, ESI_MaxSkin, 		14);
	
	PVE_SetFloat(id, ESF_Speed,			300.0);
	PVE_SetFloat(id, ESF_Gravity,		1.0);
	PVE_SetFloat(id, ESF_ScaleSize,		1.0);
	PVE_SetFloat(id, ESF_FeetSize,  	0.0);
	PVE_SetFloat(id, ESF_AttackSpeed,	50/35.0);
	PVE_SetFloat(id, ESF_AttackRange,	1024.0);
	
	PVE_AddAnimation(id, EAA_Idle, 		48,	100, 35);
	PVE_AddAnimation(id, EAA_Run, 		49,	 30, 35);
	PVE_AddAnimation(id, EAA_Attack, 	50,  50, 35);
	PVE_AddAnimation(id, EAA_Deading, 	38,	 45, 35);
	PVE_AddAnimation(id, EAA_Dead, 		39,	  1, 35);
	
	PVE_RegHook(id, ESH_Spawn,			OnSpawn);
	PVE_RegHook(id, ESH_PreAttack,		OnPreAttack);
	PVE_RegHook(id, ESH_Attack,			OnAttack);
	PVE_RegHook(id, ESH_Dead,			OnDead);
}
public Action OnPreAttack(int id, int entity, int target) {	
	PVE_RunAnimation(entity, EAA_Attack);
	return Plugin_Continue;
}
public Action OnAttack(int id, int entity, int target) {	
	int ent = PVE_ShootProjectile(entity, g_szModel2, "skeleton_arrow", 0.0, 2000.0);
	return Plugin_Handled;
}
public void OnSpawn(int id, int entity) {
	char sound[PLATFORM_MAX_PATH];
	Format(sound, sizeof(sound), "DeadlyDesire/halloween/zombie/spawn%d.mp3", GetRandomInt(1, 3));
	EmitSoundToAllAny(sound, entity);
}
public void OnDead(int id, int entity) {
	char sound[PLATFORM_MAX_PATH];
	Format(sound, sizeof(sound), "DeadlyDesire/halloween/zombie/die%d.mp3", GetRandomInt(1, 3));
	EmitSoundToAllAny(sound, entity);
	
	float pos[3];
	Entity_GetAbsOrigin(entity, pos);
	pos[2] += 8.0;
	ServerCommand("rp_zombie_die %f %f %f", pos[0], pos[1], pos[2]);
}

public void OnMapStart() {
	PrecacheModel(g_szModel);
	AddModelToDownloadsTable(g_szModel);
	PrecacheModel(g_szModel2);
	AddModelToDownloadsTable(g_szModel2);
	
	for (int i = 0; i < sizeof(g_szSounds); i++) {
		AddSoundToDownloadsTable(g_szSounds[i]);
		PrecacheSoundAny(g_szSounds[i]);
	}
	for (int i = 0; i < sizeof(g_szMaterials); i++) {
		AddFileToDownloadsTable(g_szMaterials[i]);
	}
}
