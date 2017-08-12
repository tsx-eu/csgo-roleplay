#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <emitsoundany>
#include <colors_csgo>

#include <custom_weapon_mod.inc>

#define ROLEPLAY

#if defined ROLEPLAY
#include <roleplay>
#endif

char g_szFullName[PLATFORM_MAX_PATH] =	"Tronçoneuse";
char g_szName[PLATFORM_MAX_PATH] 	 =	"chainsaw";
char g_szReplace[PLATFORM_MAX_PATH]  =	"weapon_negev";

char g_szVModel[PLATFORM_MAX_PATH] =	"models/weapons/tsx/chainsaw/v_chainsaw.mdl";
char g_szWModel[PLATFORM_MAX_PATH] =	"models/weapons/tsx/chainsaw/w_chainsaw.mdl";

char g_szMaterials[][PLATFORM_MAX_PATH] = {
	"materials/models/weapons/tsx/chainsaw/chainsaw.vmt",
	"materials/models/weapons/tsx/chainsaw/chainsaw.vtf",
	"materials/models/weapons/tsx/chainsaw/chainsaw_chain.vmt",
	"materials/models/weapons/tsx/chainsaw/chainsaw_chain.vtf",
	"materials/models/weapons/tsx/chainsaw/chainsaw_exp.vtf"	
};
char g_szSounds[][PLATFORM_MAX_PATH] = {
	"physics/metal/metal_solid_strain5.wav"
};
public void OnPluginStart() {
	RegServerCmd("sm_cwm_reload", Cmd_PluginReloadSelf);
}
public void OnAllPluginsLoaded() {
	int id = CWM_Create(g_szFullName, g_szName, g_szReplace, g_szVModel, g_szWModel);
	
	CWM_SetInt(id, WSI_AttackType,		view_as<int>(WSA_Automatic));
	CWM_SetInt(id, WSI_ReloadType,		view_as<int>(WSR_Automatic));
	CWM_SetInt(id, WSI_AttackDamage, 	25);
	CWM_SetInt(id, WSI_AttackBullet, 	1);
	CWM_SetInt(id, WSI_MaxBullet, 		250);
	CWM_SetInt(id, WSI_MaxAmmunition, 	500);
	
	CWM_SetFloat(id, WSF_Speed,			300.0);
	CWM_SetFloat(id, WSF_ReloadSpeed,	65/30.0);
	CWM_SetFloat(id, WSF_AttackSpeed,	0.1);
	CWM_SetFloat(id, WSF_AttackRange,	RANGE_MELEE + 16.0);
	CWM_SetFloat(id, WSF_Spread, 		0.0);
	
	CWM_AddAnimation(id, WAA_Idle, 		3,	64, 30);
	CWM_AddAnimation(id, WAA_Draw, 		7,	65, 30);
	CWM_AddAnimation(id, WAA_Reload, 	7,	65, 30);
	CWM_AddAnimation(id, WAA_Attack, 	1,  30, 60);
	
	CWM_RegHook(id, WSH_Draw,			OnDraw);
	CWM_RegHook(id, WSH_Attack,			OnAttack);
	CWM_RegHook(id, WSH_Idle,			OnIdle);
	CWM_RegHook(id, WSH_Reload,			OnReload);
}
public void OnDraw(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Draw);
}
public void OnIdle(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Idle);
}
public void OnReload(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Reload);
}
public Action OnAttack(int client, int entity) {

	float hit[3], src[3];
	CWM_RunAnimation(entity, WAA_Attack);
	EmitSoundToAllAny("physics/metal/metal_solid_strain5.wav", entity, _, _, _, 0.2);
	
	int target = CWM_ShootDamage(client, entity, hit);
	if( target >= 0 ) {
		
		GetClientEyePosition(client, src);
		for (int i = 0; i <= 2; i++)
			src[i] = hit[i] - src[i];
		
		// NormalizeVector(src, src);	// Si on normalise pas, on peut pousser plus fort si on est "loin" de la tronco
		ScaleVector(src, 10.0);			// Ca a du sens, car quand on est "en plein dedans" c'est plus dur de s'en retirer :-)
		src[2] += 50.0;
		
		if( target > 0)
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, src);
		
		NegateVector(src);
		NormalizeVector(src, src);
		TE_SetupSparks(hit, src, 1, 0);
		TE_SendToAll();
		
		
#if defined ROLEPLAY
		if ( rp_GetBuildingData(target, BD_owner) > 0 ) {
			CWM_ShootDamage(client, entity, hit);
			CWM_ShootDamage(client, entity, hit);
			CWM_ShootDamage(client, entity, hit);
		}
#endif
	}
	
	return Plugin_Handled;
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
