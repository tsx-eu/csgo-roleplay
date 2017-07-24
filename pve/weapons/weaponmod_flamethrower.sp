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

char g_szFullName[PLATFORM_MAX_PATH] =	"Lance-flammes";
char g_szName[PLATFORM_MAX_PATH] 	 =	"flamethrower";
char g_szReplace[PLATFORM_MAX_PATH]  =	"weapon_negev";

char g_szVModel[PLATFORM_MAX_PATH] =	"models/weapons/tsx/flamethrower/v_flamethrower.mdl";
char g_szWModel[PLATFORM_MAX_PATH] =	"models/weapons/tsx/flamethrower/w_flamethrower.mdl";

int g_cModel; 
char g_szMaterials[][PLATFORM_MAX_PATH] = {
	"materials/models/weapons/tsx/flamethrower/v_flamethrower.vmt",
	"materials/models/weapons/tsx/flamethrower/v_flamethrower.vtf",
	"materials/models/weapons/tsx/flamethrower/v_flamethrower_gauge.vmt",
	"materials/models/weapons/tsx/flamethrower/v_flamethrower_gauge.vtf",
	"materials/models/weapons/tsx/flamethrower/w_flamethrower.vmt",
	"materials/models/weapons/tsx/flamethrower/w_flamethrower.vtf",
	"materials/models/weapons/tsx/flamethrower/flame.vmt",
	"materials/models/weapons/tsx/flamethrower/flame.vtf",
	"materials/models/weapons/v_hand/v_hand_sheet.vmt"
};
char g_szSounds[][PLATFORM_MAX_PATH] = {
};

public void OnAllPluginsLoaded() {
	int id = CWM_Create(g_szFullName, g_szName, g_szReplace, g_szVModel, g_szWModel);
	
	CWM_SetInt(id, WSI_AttackType,		view_as<int>(WSA_Automatic));
	CWM_SetInt(id, WSI_ReloadType,		view_as<int>(WSR_Automatic));
	CWM_SetInt(id, WSI_AttackDamage, 	25);
	CWM_SetInt(id, WSI_AttackBullet, 	1);
	CWM_SetInt(id, WSI_MaxBullet, 		250);
	CWM_SetInt(id, WSI_MaxAmmunition, 	500);
	
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
	int ent = CWM_ShootProjectile(client, entity, NULL_MODEL, "flame", 3.0, 800.0, OnProjectileHit);
	SetEntityGravity(ent, 0.5);
	SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.1);
	Entity_SetMinMaxSize(ent, view_as<float>({-16.0, -16.0, -16.0}), view_as<float>({16.0, 16.0, 16.0}));
	DispatchKeyValue(ent, "OnUser1", "!self,Kill,,0.5,-1");
	AcceptEntityInput(ent, "FireUser1");
	
	float size = 10.0 + -GetRandomFloat(-4.0, 4.0);
	int color[4];
	color[0] = 255;
	color[1] = RoundFloat(64 + size * 3.0);
	color[2] = RoundFloat(size * 2.0);
	color[3] = RoundFloat((size / 16.0) * 255);
	
	TE_SetupBeamFollow(ent, g_cModel, 0, 0.5, 2.0 + size, 0.0, 1, color);
	TE_SendToAll();
	
	/*
	int sub = CreateEntityByName("env_sprite");
	DispatchKeyValue(sub, "model", "materials/models/weapons/tsx/flamethrower/flame.vmt");
	DispatchKeyValueFloat(sub, "scale", size / 8.0);
	DispatchKeyValue(sub, "rendermode", "5");
	DispatchKeyValue(sub, "spawnflags", "1");
	DispatchSpawn(sub);
	
	float pos[3];
	Entity_GetAbsOrigin(ent, pos);
	TeleportEntity(sub, pos, NULL_VECTOR, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(sub, "SetParent", ent);
	*/
	
	return Plugin_Continue;
}
public Action OnProjectileHit(int client, int wpnid, int entity, int target) {
	if( target > 0 && target < MaxClients ) {
#if defined ROLEPLAY
		rp_ClientIgnite(target, 10.0, client);
#else
		IgniteEntity(target, 10.0);
#endif
	}
	
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
	
	g_cModel = PrecacheModel("materials/models/weapons/tsx/flamethrower/flame.vmt");

}
