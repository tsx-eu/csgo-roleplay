#if defined _weaponmod_included
#endinput
#endif
#define _weaponmod_included

#define MAX_CWEAPONS	8
#define MAX_ENTITIES	2049
#define MAX_BLOOD		8
#define MAX_ANIMATION 	8
#define FLT_MAX			2147483647.0
#define RANGE_NONE		-FLT_MAX
#define RANGE_MELEE		52.0
#define RANGE_WEAPON	8192.0
#define NULL_MODEL		""

#define ROLEPLAY
//#define DEBUG

native int CWM_Create(char fullname[PLATFORM_MAX_PATH], char name[PLATFORM_MAX_PATH], char weaponToReplace[PLATFORM_MAX_PATH], char v_model[PLATFORM_MAX_PATH], char w_model[PLATFORM_MAX_PATH]);

native void CWM_RegHook(int id, CWM_HookType data, CWM_HookTypeForward fonction);

native void CWM_AddAnimation(int id, CWM_DataAnimation data, int sequence, int frames, int fps);
native void CWM_RunAnimation(int entity, CWM_DataAnimation data, float time = -1.0);

native int CWM_Spawn(int id, int client, float pos[3], float ang[3]);

native int CWM_ShootProjectile(int client, int entity, char model[PLATFORM_MAX_PATH], char name[32], float spreadAngle = 0.0, float speed = FLT_MAX, CWM_HitCallback fonction = INVALID_FUNCTION);
native int CWM_ShootHull(int client, int entity, float size, float hit[3]);
native int CWM_ShootDamage(int client, int entity, float hit[3]);
native int CWM_ShootExplode(int client, int wpnid, int entity, float radius);

native void CWM_RefreshHUD(int client, int entity);

native int CWM_GetId(char name[PLATFORM_MAX_PATH]);

native void CWM_SetInt(int id, CWM_DataInteger data, int value);
native int CWM_GetInt(int id, CWM_DataInteger data);
native void CWM_SetEntityInt(int entity, CWM_DataInteger data, int value);
native int CWM_GetEntityInt(int entity, CWM_DataInteger data);

native void CWM_SetFloat(int id, CWM_DataFloat data, float value);
native float CWM_GetFloat(int id, CWM_DataFloat data);
native void CWM_SetEntityFloat(int entity, CWM_DataFloat data, float value);
native float CWM_GetEntityFloat(int entity, CWM_DataFloat data);

native bool CWM_IsCustom(int entity);

enum CWM_DataAnimation {
	WAA_Idle,
	WAA_Draw,
	WAA_Attack,
	WAA_AttackPost,
	WAA_Attack2,
	WAA_Reload,
	WAA_Max
}
enum CWM_DataInteger {
	WSI_Identifier,
	WSI_AttackType,
	WSI_ReloadType,
	WSI_AttackDamage,
	WSI_AttackBullet,
	WSI_Animation,
	WSI_Owner,
	WSI_VModel,
	WSI_WModel,
	WSI_Bullet,
	WSI_MaxBullet,
	WSI_Ammunition,
	WSI_MaxAmmunition,
	WSI_Skin,
	WSI_State,
	
	WSI_Max
};
enum CWM_DataFloat {
	Float:WSF_Speed,
	Float:WSF_Attack,
	Float:WSF_NextAttack,
	Float:WSF_AttackSpeed,
	Float:WSF_AttackRange,
	Float:WSF_ReloadSpeed,
	Float:WSF_NextIdle,
	Float:WSF_AnimationSpeed,
	Float:WSF_Spread,
	
	WSF_Max
};
enum CWM_DataString {
	WSS_Fullname,
	WSS_Name,
	WSS_ReplaceWeapon,
	WSS_VModel,
	WSS_WModel,
	
	WSS_Max
};
enum CWM_AttackType {
	WSA_None,
	WSA_Automatic,
	WSA_SemiAutomatic,
	WSA_LockAndLoad,
	
	WSA_Max
};
enum CWM_ReloadType {
	WSR_Automatic,
	WSR_OneByOne,
	
	WSR_Max
};
enum CWM_HookType {
	WSH_Draw,
	WSH_Attack,
	WSH_AttackPost,
	WSH_Attack2,
	WSH_Reload,
	WSH_Idle,
	WSH_Empty,
	WSH_Max
};
typeset CWM_HookTypeForward {
	function void(int client, int entity);					// WSH_Draw
	function Action(int client, int entity); 				// WSH_Attack 	 // Continue = attack, handled = pas d'attaque mais cooldown, stop = pas d'attaque ni de cooldown
	function void(int client, int entity);					// WSH_Reload
	function void(int client, int entity);					// WSH_Idle
	function void(int client, int entity);					// WSH_Empty
}
typeset CWM_HitCallback {
	function Action(int client, int wpnid, int entity, int target);	// Continue = subit les dégats, handle/stop = pas de dégat
}
stock void CWM_Refill(int entity) {
	int id = CWM_GetEntityInt(entity, WSI_Identifier);
	if( id >= 0 ) {
		CWM_SetEntityInt(entity, WSI_Bullet, CWM_GetInt(entity, WSI_MaxBullet));
		CWM_SetEntityInt(entity, WSI_Ammunition, CWM_GetInt(entity, WSI_MaxAmmunition));
	}
}

#if !defined _pve_included
stock void AddModelToDownloadsTable(char file[PLATFORM_MAX_PATH]) {
	char tmp[PLATFORM_MAX_PATH], tmp2[PLATFORM_MAX_PATH];
	int len = strlen(file);
	strcopy(tmp, sizeof(tmp), file);
	
	ReplaceString(tmp, len, ".mdl", "", true);
	Format(tmp2, sizeof(tmp2), "%s.mdl", tmp);		if( FileExists(tmp2, true) ) AddFileToDownloadsTable(tmp2);
	Format(tmp2, sizeof(tmp2), "%s.phy", tmp);		if( FileExists(tmp2, true) ) AddFileToDownloadsTable(tmp2);
	Format(tmp2, sizeof(tmp2), "%s.vvd", tmp);		if( FileExists(tmp2, true) ) AddFileToDownloadsTable(tmp2);
	Format(tmp2, sizeof(tmp2), "%s.dx90.vtx", tmp); if( FileExists(tmp2, true) ) AddFileToDownloadsTable(tmp2);
}
stock void AddSoundToDownloadsTable(char file[PLATFORM_MAX_PATH]) {
	char tmp[PLATFORM_MAX_PATH];
	Format(tmp, sizeof(tmp), "sound/%s", file);
	if( FileExists(tmp, true) )
		AddFileToDownloadsTable(tmp);
}
#endif