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

char g_szFullName[PLATFORM_MAX_PATH] =	"Lance-roquettes";
char g_szName[PLATFORM_MAX_PATH] 	 =	"rocketlauncher";
char g_szReplace[PLATFORM_MAX_PATH]  =	"weapon_negev";

char g_szVModel[PLATFORM_MAX_PATH] =	"models/v_models/v_grenade_launcher.mdl";
char g_szWModel[PLATFORM_MAX_PATH] =	"models/w_models/weapons/w_grenade_launcher.mdl";
char g_szTModel[PLATFORM_MAX_PATH] =	"models/weapons/w_eq_fraggrenade_thrown.mdl";

int g_cModel; 
char g_szMaterials[][PLATFORM_MAX_PATH] = {
	"models/v_models/weapons/grenade_launcher/grenade_launcher.vtf",
	"models/v_models/weapons/grenade_launcher/grenade_launcher.vmt"
};
char g_szSounds[][PLATFORM_MAX_PATH] = {
};

public void OnAllPluginsLoaded() {
	int id = CWM_Create(g_szFullName, g_szName, g_szReplace, g_szVModel, g_szWModel);
	
	CWM_SetInt(id, WSI_AttackType,		view_as<int>(WSA_Automatic));
	CWM_SetInt(id, WSI_AttackDamage, 	250);
	CWM_SetInt(id, WSI_AttackBullet, 	1);
	CWM_SetInt(id, WSI_MaxBullet, 		4);
	CWM_SetInt(id, WSI_MaxAmmunition, 	20);
	
	CWM_SetFloat(id, WSF_Speed,			240.0);
	CWM_SetFloat(id, WSF_ReloadSpeed,	1.0);
	CWM_SetFloat(id, WSF_AttackSpeed,	2.0);
	CWM_SetFloat(id, WSF_AttackRange,	RANGE_MELEE * 4.0);
	CWM_SetFloat(id, WSF_Spread, 		0.0);
	
	CWM_AddAnimation(id, WAA_Idle, 		3,	60, 30);
	CWM_AddAnimation(id, WAA_Draw, 		3,	29, 30);
	CWM_AddAnimation(id, WAA_Attack, 	5,  30, 30);
	
	CWM_RegHook(id, WSH_Draw,			OnDraw);
	CWM_RegHook(id, WSH_Attack,			OnAttack);
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
	int ent = CWM_ShootProjectile(client, entity, g_szTModel, "rocket", 0.0, 1600.0, OnProjectileHit);
	TE_SetupBeamFollow(ent, g_cModel, 0, 1.0, 1.0, 0.0, 1, {255, 255, 255, 100});
	TE_SendToAll();
	return Plugin_Continue;
}
public void OnProjectileHit(int client, int wpnid, int entity, int target) {
	CWM_ShootExplode(client, wpnid, entity, 250.0);
	float pos[3];
	Entity_GetAbsOrigin(entity, pos);
	TE_SetupExplosion(pos, 0, 250.0, 0, 0, 250, 50);
	TE_SendToAll();
}
public void OnMapStart() {

	AddModelToDownloadsTable(g_szVModel);
	AddModelToDownloadsTable(g_szWModel);
	AddModelToDownloadsTable(g_szTModel);
	
	for (int i = 0; i < sizeof(g_szSounds); i++) {
		AddSoundToDownloadsTable(g_szSounds[i]);
		PrecacheSoundAny(g_szSounds[i]);
	}
	for (int i = 0; i < sizeof(g_szMaterials); i++) {
		AddFileToDownloadsTable(g_szMaterials[i]);
	}
	
	g_cModel = PrecacheModel("materials/sprites/laserbeam.vmt");

}
