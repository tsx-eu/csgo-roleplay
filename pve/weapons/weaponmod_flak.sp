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

char g_szFullName[PLATFORM_MAX_PATH] =	"Cannon FLAK";
char g_szName[PLATFORM_MAX_PATH] 	 =	"flakcannon";
char g_szReplace[PLATFORM_MAX_PATH]  =	"weapon_negev";

char g_szVModel[PLATFORM_MAX_PATH] =	"models/weapons/tsx/flak_cannon/v_flak_cannon.mdl";
char g_szWModel[PLATFORM_MAX_PATH] =	"models/weapons/tsx/flak_cannon/w_flak_cannon.mdl";
char g_szTModel[][PLATFORM_MAX_PATH] =	{
	"models/gibs/wood_gib01a.mdl",
	"models/gibs/wood_gib01b.mdl",
	"models/gibs/wood_gib01c.mdl",
	"models/gibs/wood_gib01d.mdl",
	"models/gibs/wood_gib01e.mdl"
};

int g_cModel; 
char g_szMaterials[][PLATFORM_MAX_PATH] = {
	"materials/models/weapons/tsx/flak_cannon/Flak3rdperson.vtf",
	"materials/models/weapons/tsx/flak_cannon/Flak3rdperson.vmt",
	"materials/models/weapons/tsx/flak_cannon/FlakTex0.vtf",
	"materials/models/weapons/tsx/flak_cannon/FlakTex0.vmt",
	"materials/models/weapons/tsx/flak_cannon/FlakTex1.vtf",
	"materials/models/weapons/tsx/flak_cannon/FlakTex1.vmt"
};
char g_szSounds[][PLATFORM_MAX_PATH] = {
	"physics/metal/metal_box_scrape_rough_loop2.wav",
	"physics/concrete/boulder_impact_hard1.wav",
	"physics/concrete/boulder_impact_hard2.wav",
	"physics/concrete/boulder_impact_hard3.wav",
	"physics/concrete/boulder_impact_hard4.wav",
	"physics/glass/glass_sheet_impact_hard1.wav",
	"physics/glass/glass_sheet_impact_hard2.wav",
	"physics/glass/glass_sheet_impact_hard3.wav"	
};

#define MAX_HIT	3
int g_iHitcount[MAX_ENTITIES];
int g_iParticleCount = 0;
public void OnPluginStart() {
	RegServerCmd("sm_cwm_reload", Cmd_PluginReloadSelf);
}
public void OnAllPluginsLoaded() {
	int id = CWM_Create(g_szFullName, g_szName, g_szReplace, g_szVModel, g_szWModel);
	
	CWM_SetInt(id, WSI_AttackType,		view_as<int>(WSA_SemiAutomatic));
	CWM_SetInt(id, WSI_ReloadType,		view_as<int>(WSR_Automatic));
	CWM_SetInt(id, WSI_AttackDamage, 	75);
	CWM_SetInt(id, WSI_AttackBullet, 	1);
	CWM_SetInt(id, WSI_MaxBullet, 		50);
	CWM_SetInt(id, WSI_MaxAmmunition, 	0);
	
	CWM_SetFloat(id, WSF_Speed,			240.0);
	CWM_SetFloat(id, WSF_ReloadSpeed,	30/15.0);
	CWM_SetFloat(id, WSF_AttackSpeed,	20/15.0);
	CWM_SetFloat(id, WSF_AttackRange,	RANGE_MELEE * 4.0);
	CWM_SetFloat(id, WSF_Spread, 		0.0);
	
	CWM_AddAnimation(id, WAA_Idle, 		0,	14,	30);
	CWM_AddAnimation(id, WAA_Draw, 		1,	7,	30);
	CWM_AddAnimation(id, WAA_Attack, 	2,  25,	30);
	CWM_AddAnimation(id, WAA_Attack2, 	3,  23,	30);
	
	CWM_RegHook(id, WSH_Draw,			OnDraw);
	CWM_RegHook(id, WSH_Attack,			OnAttack);
	CWM_RegHook(id, WSH_Idle,			OnIdle);
	CWM_RegHook(id, WSH_Reload,			OnReload);
}
public void OnReload(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Reload);
}
public void OnDraw(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Draw);
}
public void OnIdle(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Idle);
}
public Action OnAttack(int client, int entity) {
	static char tmp[32];
	CWM_RunAnimation(entity, WAA_Attack);
	EmitSoundToAllAny(g_szSounds[GetRandomInt(1, 4)], entity, SNDCHAN_WEAPON);
	
	for (int i = 0; i < 8; i++) {
		
		int ent = CWM_ShootProjectile(client, entity, g_szTModel[GetRandomInt(0, sizeof(g_szTModel)-1)], "flak", 4.0, 1600.0, OnProjectileHit);
		g_iHitcount[ent] = GetRandomInt(-1, 1);
		
		float life = GetRandomFloat(2.0, 3.0);
		Format(tmp, sizeof(tmp), "!self,Kill,,%.1f,-1", life);
		SetEntPropFloat(ent,  Prop_Send, "m_flModelScale", 0.1);
		SetEntityGravity(ent, 0.65);
		SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.65);
		DispatchKeyValue(ent, "OnUser1", tmp);
		AcceptEntityInput(ent, "FireUser1");
		
		if( GetRandomInt(0, 50) >= g_iParticleCount ) {
			TE_SetupBeamFollow(ent, g_cModel, 0, GetRandomFloat(0.2, 0.5), 0.25, 0.0, 1, {255, 255, 255, 50});
			TE_SendToAll();
			
			g_iParticleCount++;
			CreateTimer(life, DecreaseParticleCount);
		}
	}
	return Plugin_Continue;
}
public Action DecreaseParticleCount(Handle timer, any none) {
	g_iParticleCount--;
}
public Action OnProjectileHit(int client, int wpnid, int entity, int target) {
	g_iHitcount[entity]++;
	if( target > 0 && target < MaxClients )
		return Plugin_Continue;
	
	return g_iHitcount[entity] < MAX_HIT ? Plugin_Stop : Plugin_Continue;
}
public void OnMapStart() {

	AddModelToDownloadsTable(g_szVModel);
	AddModelToDownloadsTable(g_szWModel);
	for (int i = 0; i < sizeof(g_szTModel); i++)
		AddModelToDownloadsTable(g_szTModel[i]);
	
	for (int i = 0; i < sizeof(g_szSounds); i++) {
		AddSoundToDownloadsTable(g_szSounds[i]);
		PrecacheSoundAny(g_szSounds[i]);
	}
	for (int i = 0; i < sizeof(g_szMaterials); i++) {
		AddFileToDownloadsTable(g_szMaterials[i]);
	}
	
	g_cModel = PrecacheModel("materials/sprites/laserbeam.vmt");

}
