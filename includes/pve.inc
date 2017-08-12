#if defined _pve_included
#endinput
#endif
#define _pve_included

#define PATHFIND_TIMER	1.0
#define PATHFIND_STEP	10
#define PATHFIND_RANGE	32.0
#define PATHFIND_AVOID	0.1
#define PATHFIND_LADDER	0.95
#define PATHFIND_LERP	2.0

#define	JUMP_THRESHOLD	0.5
#define JUMP_HEIGHT		52.0

#define MAX_NPC			8
#define MAX_ENTITIES	2049
#define MAX_BLOOD		8
#define MAX_ANIMATION 	8
#define MAX_FOOTSTEP	14
#define FLT_MAX			2147483647.0
#define RANGE_NONE		-FLT_MAX
#define RANGE_MELEE		52.0
#define NPC_REMOVE		30.0
#define NPC_FOOTSTEP	0.3

#define ROLEPLAY
//#define DEBUG

native int PVE_Create(char fullname[PLATFORM_MAX_PATH], char name[PLATFORM_MAX_PATH], char model[PLATFORM_MAX_PATH]);
native void PVE_SetFloat(int id, PVE_DataFloat data, float value);
native void PVE_SetInt(int id, PVE_DataInteger data, int value);

native int PVE_Spawn(int id, float position[3], float angles[3]);
native void PVE_RegHook(int id, PVE_HookType data, PVE_HookTypeForward fonction);
native void PVE_RegEvent(int entity, PVE_EventType data, PVE_EventTypeForward fonction);

native void PVE_AddAnimation(int id, PVE_DataAnimation data, int sequence, int frames, int fps);
native void PVE_RunAnimation(int entity, PVE_DataAnimation data, float time = -1.0);

native int PVE_ShootProjectile(int entity, char model[PLATFORM_MAX_PATH], char name[32], float spreadAngle = 0.0, float speed = FLT_MAX, PVE_HitCallback fonction);

native int PVE_GetId(char name[PLATFORM_MAX_PATH]);
native void PVE_SetEntityFloat(int id, PVE_DataFloat data, float value);
native void PVE_SetEntityInt(int id, PVE_DataInteger data, int value);
native float PVE_GetEntityFloat(int id, PVE_DataFloat data);
native int PVE_GetEntityInt(int id, PVE_DataInteger data);

enum PVE_DataAnimation {
	EAA_Idle,
	
	EAA_Walk,
	EAA_Run,
	
	EAA_Attack,
	EAA_Attack2,
	EAA_Reload,
	
	EAA_Deading,
	EAA_Dead,
	EAA_Max
}
enum PVE_DataInteger {
	ESI_Identifier,
	ESI_State,
	ESI_Health,
	ESI_MaxHealth,
	ESI_MinSkin,
	ESI_MaxSkin,
	ESI_Target,
	ESI_CollisionWay,
	ESI_Node,
	ESI_Loading,
	ESI_Loaded,
	ESI_AttackType,
	ESI_AttackDamage,
	ESI_CanJump,
	ESI_Ladder,
	ESI_Animation,
	
	ESI_Max
};
enum PVE_DataFloat {
	Float:ESF_Speed,
	Float:ESF_Gravity,
	Float:ESF_FeetSize,
	Float:ESF_ScaleSize,
	Float:ESF_Attack,
	Float:ESF_NextAttack,
	Float:ESF_AttackSpeed,
	Float:ESF_AttackRange,
	Float:ESF_NextIdle,
	Float:ESF_NextFootStep,
	Float:ESF_FadeOut,
	Float:ESF_AnimationSpeed,
	
	ESF_Max
};
enum PVE_DataString {
	ESS_Fullname,
	ESS_Name,
	ESS_Model,
	
	ESS_Max
};
enum PVE_DataVector {
	ESV_Origin,
	ESV_PredictedOrigin,
	ESV_Direction,
	ESV_Velocity,
	ESV_Node,
	ESV_EndOfLadder,
	ESV_Max
};
enum PVE_EntityState {
	ESM_Spawning 	= 0,
	ESM_Die 		= 1,
	
	ESM_Think 		= 10,
	ESM_Search 		= 11,
	ESM_Pathfind 	= 12,
	ESM_Collision	= 13,
	ESM_Chase 		= 14,

	ESM_PreAttack		= 20,
	ESM_Attack		= 21,
	
	ESM_Max 		= 100
};
enum PVE_AttackType {
	ESA_None,
	ESA_Melee,
	ESA_Weapon,
	
	ESA_Max
};
enum PVE_HookType {
	ESH_Spawn,
	ESH_PreAttack,
	ESH_Attack,
	ESH_Dead,
	
	ESH_Max
};
enum PVE_EventType {
	ESE_FollowChange,
	ESE_CanAttack,
	ESE_Think,
	ESE_Dead,
	
	ESE_Max
};
typeset PVE_HookTypeForward {
	function void(int id, int entity);					// ESH_Spawn
	function Action(int id, int entity, int target); 	// ESH_PreAttack // Continue = attack, handled = pas d'attaque mais cooldown, stop = pas d'attaque ni de cooldown
	function Action(int id, int entity, int target); 	// ESH_Attack 	 // Continue = attack, handled = pas d'attaque mais cooldown, stop = pas d'attaque ni de cooldown
	function void(int id, int entity);					// ESH_Dead
}
typeset PVE_EventTypeForward {
	function Action(int id, int entity, int& target);				// ESE_FollowChange
	function bool(int id, int entity, int target); 					// ESE_CanAttack
	function void(int id, int entity, PVE_EntityState& state);		// ESE_Think
	function void(int id, int entity);								// ESE_Dead
}
typeset PVE_HitCallback {
	function void(int id, int entity, int ent, int target);
}
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

#if defined ROLEPLAY
#else
public Action Cmd_PluginReloadSelf(int args) {
	static char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
#endif
