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

char g_szVModel[PLATFORM_MAX_PATH] =	"models/weapons/tsx/bio_rifle/v_bio_rifle.mdl";
char g_szWModel[PLATFORM_MAX_PATH] =	"models/weapons/tsx/bio_rifle/w_bio_rifle.mdl";
char g_szTModel[PLATFORM_MAX_PATH] =	"models/weapons/tsx/bio_rifle/biomass.mdl";

char g_szMaterials[][PLATFORM_MAX_PATH] = {
	"materials/models/weapons/tsx/bio_rifle/BioRifleGlass0.vmt",
	"materials/models/weapons/tsx/bio_rifle/BioRifleGlass0.vtf",
	"materials/models/weapons/tsx/bio_rifle/BioRifleTex0.vmt",
	"materials/models/weapons/tsx/bio_rifle/BioRifleTex0.vtf",
	"materials/models/weapons/tsx/bio_rifle/BioRifleTex1.vmt",
	"materials/models/weapons/tsx/bio_rifle/BioRifleTex1.vtf",
	"materials/models/weapons/tsx/bio_rifle/BioRifleTex2.vmt",
	"materials/models/weapons/tsx/bio_rifle/BioRifleTex2.vtf",
	"materials/models/weapons/tsx/bio_rifle/BioRifleTex3.vmt",
	"materials/models/weapons/tsx/bio_rifle/BioRifleTex3.vtf",
	"materials/models/weapons/tsx/bio_rifle/BioRifleTex4.vmt",
	"materials/models/weapons/tsx/bio_rifle/BioRifleTex4.vtf",
	"materials/models/weapons/tsx/bio_rifle/BRInnerGoo.vmt",
	"materials/models/weapons/tsx/bio_rifle/BRInnerGoo.vtf",
	"materials/models/weapons/tsx/bio_rifle/BRInnerGoo1.vmt",
	"materials/models/weapons/tsx/bio_rifle/BRInnerGoo1.vtf",
	"materials/models/weapons/tsx/bio_rifle/BRInnerGoo2.vmt",
	"materials/models/weapons/tsx/bio_rifle/BRInnerGoo2.vtf",
	"materials/models/weapons/tsx/bio_rifle/BRInnerGoo3.vmt",
	"materials/models/weapons/tsx/bio_rifle/BRInnerGoo3.vtf",
	"materials/models/weapons/tsx/bio_rifle/BRInnerGoo4.vmt",
	"materials/models/weapons/tsx/bio_rifle/BRInnerGoo4.vtf",
};
char g_szSounds[][PLATFORM_MAX_PATH] = {
		
};

#define MAX_WMODE	5
int g_iColors[MAX_WMODE][4] = {
	{0, 200, 0, 200},
	{0, 0, 200, 200},
	{200, 0, 0, 200},
	{200, 100, 200, 200},
	{200, 200, 0, 200}
};
char g_szTypes[MAX_WMODE][64] = {
	"<font color='#00FF00'>Vie</font>", "<font color='#0000FF'>Armure</font>", "<font color='#FF0000'>Bonus Dégat</font>", "<font color='#FF00FF'>Vitesse</font>", "<font color='#FFFF00'>Gravité</font>"
};

int g_iWeaponMode[MAX_ENTITIES];
float g_fWeaponStart[MAX_ENTITIES];
int g_cBeam;
int g_iParticleCount = 0;

public void OnPluginStart() {
	RegServerCmd("sm_cwm_reload", Cmd_PluginReloadSelf);
}
public void OnAllPluginsLoaded() {
	int id = CWM_Create(g_szFullName, g_szName, g_szReplace, g_szVModel, g_szWModel);
	
	CWM_SetInt(id, WSI_AttackType,		view_as<int>(WSA_LockAndLoad));
	CWM_SetInt(id, WSI_ReloadType,		view_as<int>(WSR_OneByOne));
	CWM_SetInt(id, WSI_AttackDamage, 	0);
	CWM_SetInt(id, WSI_AttackBullet, 	1);
	CWM_SetInt(id, WSI_MaxBullet, 		25);
	CWM_SetInt(id, WSI_MaxAmmunition, 	25);
	
	CWM_SetFloat(id, WSF_Speed,			240.0);
	CWM_SetFloat(id, WSF_ReloadSpeed,	0.1);
	CWM_SetFloat(id, WSF_AttackSpeed,	0.5);
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
	PrintHintText(client, "Mode de tir: %s", g_szTypes[g_iWeaponMode[entity]]);
}
public void OnIdle(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Idle);
}
public Action OnAttack(int client, int entity) {
	CWM_RunAnimation(entity, WAA_Attack);
	g_fWeaponStart[entity] = GetGameTime();
	return Plugin_Continue;
}
public Action OnAttackPost(int client, int entity) {
	CWM_RunAnimation(entity, WAA_AttackPost);
	float pc = (GetGameTime() - g_fWeaponStart[entity]) * (30 / 60.0);
	if( pc > 1.0 )
		pc = 1.0;
	
	float scale = 1.0 + pc * Pow( 0.5 + pc, 2.0);
	
	int ent = CWM_ShootProjectile(client, entity, g_szTModel, "blob", 3.0, 800.0, OnProjectileHit);
	SetEntityGravity(ent, 1.0);
	SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.25);
	SetEntPropFloat(ent, Prop_Send, "m_flModelScale", scale);
	SetEntProp(ent, Prop_Send, "m_nSkin", g_iWeaponMode[entity]);
	
	DispatchKeyValue(ent, "OnUser1", "!self,Kill,,10.0,-1");
	AcceptEntityInput(ent, "FireUser1");
	
	if( GetRandomInt(0, 50) >= g_iParticleCount ) {
		TE_SetupBeamFollow(ent, g_cBeam, g_cBeam, 0.25, scale * 2.0, 0.1, 1, g_iColors[g_iWeaponMode[entity]]);
		TE_SendToAll();
		
		g_iParticleCount++;
		CreateTimer(10.0, DecreaseParticleCount);
	}
	
	SetEntityRenderMode(ent, RENDER_TRANSTEXTURE);
	SetEntityRenderColor(ent, 255, 255, 255, 200);
	
	g_iWeaponMode[ent] = g_iWeaponMode[entity];
}
public Action OnProjectileHit(int client, int wpnid, int entity, int target) {
	float scale = GetEntPropFloat(entity, Prop_Send, "m_flModelScale");
	float pos[3], ang[3], vel[3];
	
	Entity_GetAbsOrigin(entity, pos);
	
	if( scale >= 1.5 ) {
		
		int cpt = RoundToCeil(scale);
		Entity_GetAbsVelocity(entity, vel);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", scale / 4.0);
		
		float speed = GetVectorLength(vel) * 0.8;
		
		for (int i = 0; i < cpt; i++) {
			
			for (int j = 0; j < 3; j++)
				ang[j] = GetRandomFloat(-180.0, 180.0);
			
			GetAngleVectors(ang, vel, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(vel, speed);
			
			int ent = CWM_ShootProjectile(client, wpnid, g_szTModel, "blob", 3.0, speed, OnProjectileHit);
			SetEntPropFloat(ent, Prop_Send, "m_flModelScale", scale / 2.0);
			SetEntPropFloat(ent, Prop_Send, "m_flElasticity", 0.25);
			SetEntProp(ent, Prop_Send, "m_nSkin", g_iWeaponMode[entity]);
			
			DispatchKeyValue(ent, "OnUser1", "!self,Kill,,5.0,-1");
			AcceptEntityInput(ent, "FireUser1");
			
			if( GetRandomInt(0, 50) >= g_iParticleCount ) {
				TE_SetupBeamFollow(ent, g_cBeam, g_cBeam, 0.25, scale * 2.0, 0.1, 1, g_iColors[g_iWeaponMode[entity]]);
				TE_SendToAll();
				
				g_iParticleCount++;
				CreateTimer(10.0, DecreaseParticleCount);
			}
			
			SetEntityRenderMode(ent, RENDER_TRANSTEXTURE);
			SetEntityRenderColor(ent, 255, 255, 255, 200);
			TeleportEntity(ent, pos, ang, vel);
			g_iWeaponMode[ent] = g_iWeaponMode[entity];
		}
		
		SetEntityGravity(entity, GetEntityGravity(entity) + 0.25);
	}
	
	if( IsValidClient(target) ) {
		TE_SetupBeamRingPoint(pos, 16.0, 64.0, g_cBeam, 0, 0, 0, 1.0, scale, 0.0, g_iColors[g_iWeaponMode[entity]], 0, 0);
		TE_SendToAll();
		
		switch(g_iWeaponMode[entity]) {
			case 0: { // Vert
				int arg = GetClientHealth(target) + (RoundToCeil(scale * 25.0));
				if( arg > 500 )
					arg = 500;
				SetEntityHealth(target, arg);
			}
			case 1: { // Bleu
				int arg = rp_GetClientInt(target, i_Kevlar) + (RoundToCeil(scale * 10.0));
				if( arg > 250 )
					arg = 250;
				rp_SetClientInt(target, i_Kevlar, arg);
			}
			case 2: { // Rouge
				rp_HookEvent(target, RP_PostGiveDamageWeapon, fwdDamage, scale * 5.0);
			}
			case 3: { // Rose
				rp_HookEvent(target, RP_PrePlayerPhysic, fwdSlow, scale * 10.0);
			}
			case 4: { // Jaune
				rp_HookEvent(target, RP_PrePlayerPhysic, fwdGravity, scale * 10.0);
			}
			default: {
				SlapPlayer(client, 0, true);
			}
		}
		return Plugin_Continue;
	}
	
	return Plugin_Stop;
}
public Action OnAttack2(int client, int entity) {
	
	int btn = GetClientButtons(client);
	if( !(btn & IN_ATTACK) ) {
		g_iWeaponMode[entity] = (g_iWeaponMode[entity] + 1) % MAX_WMODE;
		CWM_SetEntityInt(entity, WSI_Skin, g_iWeaponMode[entity]);
		CWM_RefreshHUD(client, entity);
		
		PrintHintText(client, "Mode de tir: %s", g_szTypes[g_iWeaponMode[entity]]);
	}
	
	return Plugin_Handled;
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
	
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}
// ------------------------------------------------------------------------------------------
public Action fwdDamage(int attacker, int victim, float &damage, int wepID, float pos[3]) {
	damage *= 1.15;
	
	return Plugin_Changed;
}
public Action fwdSlow(int client, float& speed, float& gravity) {
	speed += 0.25;
	
	return Plugin_Changed;
}
public Action fwdGravity(int client, float& speed, float& gravity) {
	gravity -= 0.1;
	
	return Plugin_Changed;
}
public Action DecreaseParticleCount(Handle timer, any none) {
	g_iParticleCount--;
}
