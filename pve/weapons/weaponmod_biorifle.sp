#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <emitsoundany>
#include <smlib>

#include <custom_weapon_mod.inc>

#define ROLEPLAY
#if defined ROLEPLAY
#include <colors_csgo>
#include <roleplay>
#endif

char g_szFullName[PLATFORM_MAX_PATH] =	"Pistolet bioniques";
char g_szName[PLATFORM_MAX_PATH] 	 =	"biorifle";
char g_szReplace[PLATFORM_MAX_PATH]  =	"weapon_negev";

char g_szVModel[PLATFORM_MAX_PATH] =	"models/v_models/v_grenade_launcher.mdl";
char g_szWModel[PLATFORM_MAX_PATH] =	"models/w_models/weapons/w_grenade_launcher.mdl";

int g_cModel; 
char g_szMaterials[][PLATFORM_MAX_PATH] = {
	
};
char g_szSounds[][PLATFORM_MAX_PATH] = {
		
};

#define MAX_WMODE	5

int g_iWeaponMode[MAX_ENTITIES];

public void OnAllPluginsLoaded() {
	int id = CWM_Create(g_szFullName, g_szName, g_szReplace, g_szVModel, g_szWModel);
	
	CWM_SetInt(id, WSI_AttackType,		view_as<int>(WSA_LockAndLoad));
	CWM_SetInt(id, WSI_AttackDamage, 	0);
	CWM_SetInt(id, WSI_AttackBullet, 	1);
	CWM_SetInt(id, WSI_MaxBullet, 		10);
	CWM_SetInt(id, WSI_MaxAmmunition, 	20);
	
	CWM_SetFloat(id, WSF_Speed,			240.0);
	CWM_SetFloat(id, WSF_ReloadSpeed,	0.0);
	CWM_SetFloat(id, WSF_AttackSpeed,	59/30.0);
	CWM_SetFloat(id, WSF_AttackRange,	RANGE_MELEE * 4.0);
	CWM_SetFloat(id, WSF_Spread, 		0.0);
	
	CWM_AddAnimation(id, WAA_Idle, 		0, 119, 60);
	CWM_AddAnimation(id, WAA_Draw, 		1,	29, 30);
	CWM_AddAnimation(id, WAA_Attack, 	3,  59, 30);
	CWM_AddAnimation(id, WAA_AttackPost,2,  19, 60);
	
	CWM_RegHook(id, WSH_Draw,			OnDraw);
	CWM_RegHook(id, WSH_Attack,			OnAttack);
	CWM_RegHook(id, WSH_AttackPost,		OnAttackPost);
	CWM_RegHook(id, WSH_Attack2,		OnAttack2);
	CWM_RegHook(id, WSH_Idle,			OnIdle);
}
public void OnDraw(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Draw);
}
public void OnIdle(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Idle);
}
public Action OnAttack(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Attack);
	return Plugin_Continue;
}
public Action OnAttackPost(int client, int entity) {
	CWM_RunAnimation(entity, WAA_AttackPost);
}
public Action OnAttack2(int client, int entity) {
	g_iWeaponMode[entity] = (g_iWeaponMode[entity] + 1) % MAX_WMODE;
	CWM_SetEntityInt(entity, WSI_Skin, g_iWeaponMode[entity]);
	CWM_RefreshHUD(client, entity);
	// TODO:
	// int ent = CWM_ShootProjectile(client, entity, g_szTModel, "blob", 8.0, 600.0);
	return Plugin_Continue;
}

public void OnMapStart() {

	AddModelToDownloadsTable(g_szVModel);
	AddModelToDownloadsTable(g_szWModel);
	
	for (int i = 0; i < sizeof(g_szSounds); i++) {
		AddSoundToDownloadsTable(g_szSounds[i]);
		PrecacheSoundAny(g_szSounds[i]);
	}
	for (int i = 0; i < sizeof(g_szMaterials); i++) {
		AddFileToDownloadsTable(g_szMaterials[i]);
	}
	
	g_cModel = PrecacheModel("materials/sprites/laserbeam.vmt");

}
