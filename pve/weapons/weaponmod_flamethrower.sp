#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <emitsoundany>
#include <phun>
#include <smlib>


#include <custom_weapon_mod.inc>

char g_szFullName[PLATFORM_MAX_PATH] =	"Lance-flammes";
char g_szName[PLATFORM_MAX_PATH] 	 =	"flamethrower";
char g_szReplace[PLATFORM_MAX_PATH]  =	"weapon_negev";

char g_szVModel[PLATFORM_MAX_PATH] =	"models/weapons/v_flamethrower.mdl";
char g_szWModel[PLATFORM_MAX_PATH] =	"models/weapons/w_flamethrower.mdl";

char g_szMaterials[][PLATFORM_MAX_PATH] = {
	"materials/models/weapons/flamethrower/v_flamethrower.vmt",
	"materials/models/weapons/flamethrower/v_flamethrower.vtf",
	"materials/models/weapons/flamethrower/v_flamethrower_gauge.vmt",
	"materials/models/weapons/flamethrower/v_flamethrower_gauge.vtf",
	"materials/models/weapons/flamethrower/w_flamethrower.vmt",
	"materials/models/weapons/flamethrower/w_flamethrower.vtf",
	"materials/models/weapons/v_hand/v_hand_sheet.vmt"
};
char g_szSounds[][PLATFORM_MAX_PATH] = {
};

public void OnAllPluginsLoaded() {
	int id = CWM_Create(g_szFullName, g_szName, g_szReplace, g_szVModel, g_szWModel);
	
	CWM_SetInt(id, WSI_AttackType,		view_as<int>(WSA_Automatic));
	CWM_SetInt(id, WSI_AttackDamage, 	10);
	CWM_SetInt(id, WSI_AttackBullet, 	1);
	CWM_SetInt(id, WSI_MaxBullet, 		100);
	CWM_SetInt(id, WSI_MaxAmmunition, 	100);
	
	CWM_SetFloat(id, WSF_Speed,			240.0);
	CWM_SetFloat(id, WSF_ReloadSpeed,	1.0);
	CWM_SetFloat(id, WSF_AttackSpeed,	0.01);
	CWM_SetFloat(id, WSF_AttackRange,	RANGE_MELEE * 2.0);
	CWM_SetFloat(id, WSF_Spread, 		0.0);
	
	CWM_AddAnimation(id, WAA_Idle, 		3,	64, 30);
	CWM_AddAnimation(id, WAA_Draw, 		7,	29, 30);
	CWM_AddAnimation(id, WAA_Attack, 	12, 34, 30);
	
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
	int ent = CWM_ShootProjectile(client, entity, NULL_MODEL, "flame", 10.0, 800.0, OnProjectileHit);
	Entity_SetMinMaxSize(ent, view_as<float>({-8.0, -8.0, -8.0}), view_as<float>({8.0, 8.0, 8.0}));
	DispatchKeyValue(ent, "OnUser1", "!self,Kill,,5.0,-1");
	AcceptEntityInput(ent, "FireUser1");
	// TODO: Attacher une particule qui ressemble à une flamme
	// TODO: Utiliser un TempEnt. Ca semble plus sur qu'une entité.
	AttachParticle(ent, "burning_gib_01", 5.1);
	return Plugin_Continue;
}
public void OnProjectileHit(int client, int wpnid, int entity, int target) {
	if( target > 0 && target < MaxClients )
		IgniteEntity(target, 5.0);
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
}
