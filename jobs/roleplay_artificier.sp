/*
 * Cette oeuvre, création, site ou texte est sous licence Creative Commons Attribution
 * - Pas d’Utilisation Commerciale
 * - Partage dans les Mêmes Conditions 4.0 International. 
 * Pour accéder à une copie de cette licence, merci de vous rendre à l'adresse suivante
 * http://creativecommons.org/licenses/by-nc-sa/4.0/ .
 *
 * Merci de respecter le travail fourni par le ou les auteurs 
 * https://www.ts-x.eu/ - kossolax@ts-x.eu
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define	MAX_AREA_DIST	500

// TODO: Certain debug sont manquant

public Plugin myinfo = {
	name = "Jobs: Artificier", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Artificier",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};
int g_cBeam, g_cGlow, g_cShockWave, g_cShockWave2, g_cExplode;
bool g_bC4Expl[2049];

// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_firework",	Cmd_ItemFireWork,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_highjump",	Cmd_ItemHighJump,		"RP-ITEM",	FCVAR_UNREGISTERED);
	//RegServerCmd("rp_item_mine",		Cmd_ItemMine,			"RP-ITEM",  FCVAR_UNREGISTERED); <-- Désactivé à cause d'un bug CSGO. A réinsérer plus tard :>
	RegServerCmd("rp_item_bomb",		Cmd_ItemBomb,			"RP-ITEM",  FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_nade",		Cmd_ItemNade,			"RP-ITEM",  FCVAR_UNREGISTERED);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
// ----------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
	g_cShockWave = PrecacheModel("materials/effects/concrefract.vmt", true);
	g_cShockWave2 = PrecacheModel("materials/sprites/rollermine_shock.vmt", true);
	g_cExplode = PrecacheModel("materials/sprites/muzzleflash4.vmt", true);
	PrecacheModel("models/weapons/w_c4_planted.mdl", true);
}
// ------------------------------------------------------------------------------
public Action Cmd_ItemNade(int args) {
	char arg1[12];	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int client = GetCmdArgInt(2);
	rp_SetClientInt(client, i_LastAgression, GetTime());
	
	if( StrEqual(arg1, "conc") ) {
		rp_CreateGrenade(client, "ctf_nade_conc", "models/grenades/conc/conc.mdl", throwClassic, concExplode, 3.0);
	}
	else if( StrEqual(arg1, "caltrop") ) {
		for (int i = 0; i <= 10; i++) {
			rp_CreateGrenade(client, "ctf_nade_caltrop", "models/grenades/caltrop/caltrop.mdl", throwCaltrop, caltropExplode, 0.1);
		}
	}
	else if( StrEqual(arg1, "nail") ) {
		rp_CreateGrenade(client, "ctf_nade_nail", "models/grenades/nailgren/nailgren.mdl", throwClassic, nailExplode, 3.0);
	}
	else if( StrEqual(arg1, "mirv") ) {
		rp_CreateGrenade(client, "ctf_nade_mirv", "models/grenades/mirv/mirv.mdl", throwClassic, mirvExplode, 3.0);
	}
	else if( StrEqual(arg1, "gas") ) {
		rp_CreateGrenade(client, "ctf_nade_gas", "models/grenades/gas/gas.mdl", throwClassic, gasExplode, 3.0);
	}
	else if( StrEqual(arg1, "emp") ) {
		rp_CreateGrenade(client, "ctf_nade_emp", "models/grenades/emp/emp.mdl", throwClassic, EMPExplode, 3.0);
	}
	else if( StrEqual(arg1, "c4") ) {
		int ent = rp_CreateGrenade(client, "ctf_nade_c4", "models/weapons/w_c4_planted.mdl", throwCaltrop, C4Explode, 30.0);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre C4 explosera dans 30 secondes. Entrez /C4 pour le faire exploser.");
		g_bC4Expl[ent] = true;
		
	}
}
// ------------------------------------------------------------------------------
public void throwMirvlet(int client, int ent) {
	float vecOrigin[3], vecPush[3];
	
	Entity_GetAbsOrigin(client, vecOrigin);
	vecOrigin[2] += 25.0;

	vecPush[0] = GetRandomFloat(-250.0, 250.0);
	vecPush[1] = GetRandomFloat(-250.0, 250.0);
	vecPush[2] = GetRandomFloat(10.0, 50.0);
	
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, vecPush);
}
public void throwCaltrop(int client, int ent) {
	float vecOrigin[3],  vecPush[3];
	
	GetClientEyePosition(client, vecOrigin);
	vecOrigin[2] -= 25.0;

	vecPush[0] = GetRandomFloat(-120.0, 120.0);
	vecPush[1] = GetRandomFloat(-120.0, 120.0);
	vecPush[2] = GetRandomFloat(10.0, 50.0);
	
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, vecPush);
}
public void throwClassic(int client, int ent) {
	float vecOrigin[3], vecAngles[3], vecPush[3];
	
	GetClientEyePosition(client, vecOrigin);
	GetClientEyeAngles(client,vecAngles);
	vecOrigin[2] -= 25.0;
	
	GetAngleVectors(vecAngles, vecPush, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vecPush, 800.0);
	
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, vecPush);
}
// ------------------------------------------------------------------------------
public void concExplode(int client, int ent) {
	
	float vecOrigin[3], vecCenter[3];
	char sound[128];
	
	Entity_GetAbsOrigin(ent, vecCenter);
	
	for (int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetZoneBit(rp_GetPlayerZone(i)) & BITZONE_PEACEFULL )
			continue;
		
		GetClientAbsOrigin(i, vecOrigin);
		
		if( GetVectorDistance(vecOrigin, vecCenter) > 280.0 )
			continue;
		
		ConcPlayer(i, vecCenter, client, false);
	}
	
	vecCenter[2] += 25.0;
	
	TE_SetupBeamRingPoint(vecCenter, 1.0, 285.0, g_cShockWave, 0, 0, 10, 0.25, 50.0, 0.0, {255, 255, 255, 255}, 1, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vecCenter, 0.1, 288.0, g_cShockWave2, 0, 0, 10, 0.25, 50.0, 0.0, {255, 255, 255, 200}, 1, 0);
	TE_SendToAll();
	
	
	Format(sound, sizeof(sound), "grenades/conc%i.mp3", Math_GetRandomInt(1, 2));
	EmitSoundToAllAny(sound, ent);
	
	rp_ScheduleEntityInput(ent, 0.25, "KillHierarchy");
}
// Source: http://forums.fortress-forever.com/showpost.php?p=335934&postcount=8
// https://github.com/fortressforever/fortressforever/blob/beta/game_shared/ff/ff_grenade_concussion.cpp#L320
// A l'origine, ce code provient du serveur CTF. Les grenades pouvaient être tenue en main lors de l'explosion (hh) ou relachée à temps.
void ConcPlayer(int victim, float center[3], int attacker, bool hh) {
	
	if( victim != attacker ) {
		float pSpd[3], cPush[3], pPos[3], distance, pointDist, calcSpd, baseSpd;
		
		GetClientAbsOrigin(victim, pPos);
		pPos[2] += 48.0;
		
		GetEntPropVector(victim, Prop_Data, "m_vecVelocity", pSpd);
		distance = GetVectorDistance(pPos, center);
		
		SubtractVectors(pPos, center, cPush);
		NormalizeVector(cPush, cPush);
		pointDist = FloatDiv(distance, 280.0);
		
		baseSpd = 1000.0; // 650
		
		if( 0.25 > pointDist ) {
			pointDist = 0.25;
		}
		
		calcSpd = baseSpd * pointDist;
		calcSpd = -1.0*Cosine( (calcSpd / baseSpd) * 3.141592 ) * ( baseSpd - (800.0 / 3.0) ) + ( baseSpd + (800.0 / 3.0) );
		
		ScaleVector(cPush, (calcSpd*0.8));
		
		bool OnGround;
		if(GetEntityFlags(victim) & FL_ONGROUND) {
			OnGround = true;
		}
		else {
			OnGround = false;
		}
		if( (hh && victim != attacker) || !hh) {
			if( pSpd[2] < 0.0 && cPush[2] > 0.0 ) {
				pSpd[2] = 0.0;
			}
		}
		
		AddVectors(pSpd, cPush, pSpd);
		
		if( OnGround ) {
			if(pSpd[2] < 800.0/3.0) {
				pSpd[2] = 800.0/3.0;
			}
		}
		
		float vecPlayerOrigin[3];
		GetClientAbsOrigin(victim, vecPlayerOrigin);
		
		if( OnGround ) {
			int flags = GetEntityFlags(victim);
			SetEntityFlags(victim, (flags&~FL_ONGROUND) );
			SetEntPropEnt(victim, Prop_Send, "m_hGroundEntity", -1);
			
			vecPlayerOrigin[2] += 1.0;
			TeleportEntity(victim, vecPlayerOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, pSpd);
	}
	else {
		float vecPlayerOrigin[3], vecResult[3];
		GetClientAbsOrigin(victim, vecPlayerOrigin);
		
		float vecDisplacement[3];
		vecDisplacement[0] = vecPlayerOrigin[0] - center[0];
		vecDisplacement[1] = vecPlayerOrigin[1] - center[1];
		vecDisplacement[2] = vecPlayerOrigin[2] - center[2];
		
		float flDistance = GetVectorLength(vecDisplacement);
		
		if( hh && attacker == victim) {
			float fLateral = 2.74;
			float fVertical = 4.10;
			
			float vecVelocity[3];
			GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vecVelocity);
			
			vecResult[0] = vecVelocity[0] * fLateral;
			vecResult[1] = vecVelocity[1] * fLateral;
			vecResult[2] = vecVelocity[2] * fVertical;
			
		}
		else {
			
			float verticalDistance = vecDisplacement[2];
			vecDisplacement[2] = 0.0;
			float horizontalDistance = GetVectorLength(vecDisplacement);
			
			vecDisplacement[0] /= horizontalDistance;
			vecDisplacement[1] /= horizontalDistance;
			vecDisplacement[2] /= horizontalDistance;
			
			vecDisplacement[0] *= (horizontalDistance * (8.4 - 0.015 * flDistance) );
			vecDisplacement[1] *= (horizontalDistance * (8.4 - 0.015 * flDistance) );
			vecDisplacement[2] = (verticalDistance * (12.6 - 0.0225 * flDistance) );
			
			vecResult[0] = vecDisplacement[0];
			vecResult[1] = vecDisplacement[1];
			vecResult[2] = vecDisplacement[2];		
		}
		
		
		int flags = GetEntityFlags(victim);
		if( flags & FL_ONGROUND ) {
			
			SetEntityFlags(victim, (flags&~FL_ONGROUND) );
			SetEntPropEnt(victim, Prop_Send, "m_hGroundEntity", -1);
			
			vecPlayerOrigin[2] += 1.0;
			TeleportEntity(victim, vecPlayerOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		
		TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vecResult);
		
	}
	
	float vecAngles[3];
	vecAngles[0] = 50.0;
	vecAngles[1] = 50.0;
	vecAngles[2] = 50.0;
	
	SetEntPropVector(victim, Prop_Send, "m_viewPunchAngle", vecAngles);
	ServerCommand("sm_effect_flash %d 2.5 50", victim);
}
// ------------------------------------------------------------------------------
public void caltropExplode(int client, int ent) {
	rp_ScheduleEntityInput(ent, 12.25, "KillHierarchy");
	CreateTimer(0.01, caltropShot, EntIndexToEntRef(ent));
}
public Action fwdSlow(int client, float& speed, float& gravity) {
	speed -= 0.0666;
	return Plugin_Changed;
}
public Action caltropShot(Handle timer, any ent) {
	ent = EntRefToEntIndex(ent);
	if( !IsValidEdict(ent) || !IsValidEntity(ent) )
		return Plugin_Handled;
	
	int attacker = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	float vecCenter[3], vecOrigin[3];
	Entity_GetAbsOrigin(ent, vecCenter);
	
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( i == attacker )
			continue;
		
		GetClientAbsOrigin(i, vecOrigin);
		if( GetVectorDistance(vecOrigin, vecCenter) >= 20.0 )
			continue;
		
		rp_HookEvent(i, RP_PrePlayerPhysic, fwdSlow, 2.5);
		if( Math_GetRandomInt(0, 1) )
			rp_ClientDamage(i, 1, attacker, "nade_caltrop");
	}
	
	CreateTimer(0.01, caltropShot, EntIndexToEntRef(ent));
	return Plugin_Handled;
}
// ------------------------------------------------------------------------------
public void nailExplode(int client, int ent) {	
	float vecOrigin[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
	vecOrigin[2] += 25.0;
	TeleportEntity(ent, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	
	CreateTimer(0.00001, nailShot, EntIndexToEntRef(ent));
	CreateTimer(5.0, nailExplode_Task, EntIndexToEntRef(ent));
	
}
public Action nailExplode_Task(Handle timer, any ent) {
	ent = EntRefToEntIndex(ent);
	if( !IsValidEdict(ent) || !IsValidEntity(ent) )
		return Plugin_Handled;
		
	float vecOrigin[3];	
	char sound[128];
	int attacker = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	Entity_GetAbsOrigin(ent, vecOrigin);
	
	rp_Effect_Explode(vecOrigin, 500.0, 400.0, attacker, "nade_nail");
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 100, 100);
	TE_SendToAll();
	
	Format(sound, sizeof(sound), "weapons/hegrenade/explode%i.wav", Math_GetRandomInt(3, 5));
	EmitSoundToAllAny(sound, ent);
	
	rp_ScheduleEntityInput(ent, 0.01, "KillHierarchy");
	
	return Plugin_Handled;
}
public Action nailShot(Handle timer, any ent) {
	static float lastAngle[2049];
	ent = EntRefToEntIndex(ent);
	if( !IsValidEdict(ent) || !IsValidEntity(ent) )
		return Plugin_Handled;
	
	int attacker = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	float vecAngles[3], vecOrigin[3], vecDest[3];
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
	
	vecAngles[1] = lastAngle[ent] + Math_GetRandomFloat(4.0, 6.0);
	if ( vecAngles[1] >= 360.0 ) {
		vecAngles[1] -= 360.0;
	}
	
	TeleportEntity(ent, NULL_VECTOR, vecAngles, NULL_VECTOR);
	
	for(int i=1; i<=3; i++) {
		
		vecAngles[1] += 120.0;
		
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);
		vecOrigin[0] = (vecOrigin[0] + (5.0 * Cosine( DegToRad(vecAngles[1]) )) );
		vecOrigin[1] = (vecOrigin[1] + (5.0 * Sine( DegToRad(vecAngles[1]))));
		
		TE_SetupMuzzleFlash(vecOrigin, vecAngles, 1.0, 1);
		TE_SendToAll();
		
		float vecTarget[3], vecAnglesTarget[3];
		GetFrontLocationData(vecOrigin, vecAngles, vecTarget, vecAnglesTarget, MAX_AREA_DIST*1.25);
		
		Handle trace = TR_TraceRayFilterEx(vecOrigin, vecTarget, MASK_SHOT, RayType_EndPoint, FilterToOne, ent);
		int victim = 0;
		
		if( !TR_DidHit(trace) ) {
			vecDest[0] = vecTarget[0];
			vecDest[1] = vecTarget[1];
			vecDest[2] = vecTarget[2];
		}
		else {
			victim = TR_GetEntityIndex(trace);
			TR_GetEndPosition(vecDest, trace);
		}
		
		CloseHandle(trace);
		
		TE_SetupBeamPoints( vecOrigin, vecDest, g_cBeam, 0, 0, 0, 0.1, 3.0, 3.0, 1, 0.0, {200, 200, 200, 20}, 0);
		TE_SendToAll();
		
		if( IsValidClient(victim) ) {
			rp_ClientDamage(victim, Math_GetRandomInt(30, 60), attacker);
		}
	}
	
	lastAngle[ent] = vecAngles[1];
	CreateTimer(0.00001, nailShot, EntIndexToEntRef(ent));
	return Plugin_Handled;
}
void GetFrontLocationData( float _origin[3], float _angles[3], float position[3], float angles[3], float distance = 50.0 ) {
	float direction[3];
	GetAngleVectors( _angles, direction, NULL_VECTOR, NULL_VECTOR );
	
	position[0] = _origin[0] + direction[0] * distance;
	position[1] = _origin[1] + direction[1] * distance;
	position[2] = _origin[2];
	
	angles[0] = 0.0;
	angles[1] = _angles[1];
	angles[2] = 0.0;
}
// ------------------------------------------------------------------------------
public void mirvExplode(int client, int ent) {
	float vecOrigin[3];
	char sound[128];
	Entity_GetAbsOrigin(ent, vecOrigin);
	
	rp_Effect_Explode(vecOrigin, 500.0, 400.0, client, "nade_mirv");
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 200, 200);
	TE_SendToAll();
	
	Format(sound, sizeof(sound), "weapons/hegrenade/explode%i.wav", Math_GetRandomInt(3, 5));
	EmitSoundToAllAny(sound, ent);
	
	for(int i=0; i<Math_GetRandomInt(7, 8); i++) {
		
		rp_CreateGrenade(ent, "ctf_nade_mirvlet", "models/grenades/mirv/mirvlet.mdl", throwMirvlet, mirvletExplode, 3.0);
	}
	SetEntityRenderMode(ent, RENDER_NONE);
	rp_ScheduleEntityInput(ent, 3.25, "KillHierarchy");
}
public void mirvletExplode(int client, int ent) {
	
	float vecOrigin[3];
	char sound[128];
	Entity_GetAbsOrigin(ent, vecOrigin);
	
	int attacker = GetEntPropEnt(client, Prop_Send, "m_hOwnerEntity");
	
	rp_Effect_Explode(vecOrigin, 250.0, 200.0, attacker, "nade_mirvlet");
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 100, 100);
	TE_SendToAll();
	
	Format(sound, sizeof(sound), "weapons/hegrenade/explode%i.wav", Math_GetRandomInt(3, 5));
	EmitSoundToAllAny(sound, ent);
	
	rp_ScheduleEntityInput(ent, 0.25, "KillHierarchy");
}
// ------------------------------------------------------------------------------
public void gasExplode(int client, int ent) {
	float vecOrigin[3];
	Entity_GetAbsOrigin(ent, vecOrigin);
	
	int ent1 = CreateEntityByName("env_particlesmokegrenade");	
	ActivateEntity(ent1);
	DispatchSpawn(ent1);
	SetEntProp(ent1, Prop_Send, "m_CurrentStage", 1); 
	SetEntPropEnt(ent1, Prop_Send, "m_hOwnerEntity", client);
		
	TeleportEntity(ent1, vecOrigin, NULL_VECTOR, NULL_VECTOR);
		
	SetVariantString("!activator");
	AcceptEntityInput(ent1, "SetParent", ent);
	
	SetEntPropFloat(ent1, Prop_Send, "m_FadeStartTime", 8.0);
	SetEntPropFloat(ent1, Prop_Send, "m_FadeEndTime", 16.0);
	
	CreateTimer(0.01, gasShot, EntIndexToEntRef(ent));
	rp_ScheduleEntityInput(ent, 15.25, "KillHierarchy");
}
public Action gasShot(Handle timer, any ent) {
	ent = EntRefToEntIndex(ent);
	if( !IsValidEdict(ent) || !IsValidEntity(ent) )
		return Plugin_Handled;
	
	int attacker = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	float vecCenter[3], vecOrigin[3], time = GetGameTime() + 20.0;
	Entity_GetAbsOrigin(ent, vecCenter);
	
	for(int i=1; i<=MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		GetClientEyePosition(i, vecOrigin);
		if( GetVectorDistance(vecOrigin, vecCenter) >= 200.0 )
			continue;
		
		rp_ClientDamage(i, Math_GetRandomInt(2, 6), attacker, "ctf_nade_gas");
		rp_SetClientFloat(i, fl_HallucinationTime, time);				
	}
	
	CreateTimer(0.2, gasShot, EntIndexToEntRef(ent));
	return Plugin_Handled;
}
// ------------------------------------------------------------------------------
public void EMPExplode(int client, int ent) {
	
	EmitSoundToAllAny("grenades/emp_explosion.mp3", ent);
	EmitSoundToAllAny("grenades/emp_explosion.mp3", ent);
	
	CreateTimer(0.75, EMPExplode_Task, ent);
}
public Action EMPExplode_Task(Handle timer, any ent) {
	
	int kev, client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");	
	float vecOrigin[3],  damage = 0.0, vecOrigin2[3];
	char classname[64];
	int attacker = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
	Entity_GetAbsOrigin(ent, vecOrigin);
	
	for(int i=1; i<=2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		
		GetEdictClassname(i, classname, sizeof(classname));
		
		if( StrContains(classname, "player") == 0 || StrContains(classname, "weapon_") == 0 ||
			StrContains(classname, "rp_cashmachine_") == 0 || StrContains(classname, "rp_bigcashmachine_") == 0 || StrContains(classname, "rp_mine_") == 0 ) {
			
			if( StrContains(classname, "weapon_knife") == 0 )
				continue;
			
			
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", vecOrigin2);
			
			if( GetVectorDistance(vecOrigin, vecOrigin2) > 400.0 )
				continue;
			
			damage += 52.5;
			
			TE_SetupExplosion(vecOrigin2, g_cExplode, 1.0, 0, 0, 25, 25);
			TE_SendToAll();
			
			TE_SetupBeamRingPoint(vecOrigin, 1.0, 26.0, g_cShockWave, 0, 0, 20, 0.20, 50.0, 0.0, {255, 255, 255, 255}, 1, 0);
			TE_SendToAll();
			
			TE_SetupBeamRingPoint(vecOrigin, 0.1, 25.0, g_cBeam, 0, 0, 10, 0.20, 50.0, 0.0, {255, 200, 50, 200}, 1, 0);
			TE_SendToAll();
			
			if( StrContains(classname, "weapon_") == 0 && GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") <= 0 ) {
				AcceptEntityInput(i, "Kill");
			}
			else if( StrContains(classname, "rp_mine_") == 0 ) {
				AcceptEntityInput(i, "Kill");
			}
			else {
				if( IsValidClient(i) && !(rp_GetZoneBit(rp_GetPlayerZone(i)) & BITZONE_PEACEFULL) ) {
					kev = rp_GetClientInt(i, i_Kevlar) / 2;
					damage += float(kev);
					
					kev -= 50;
					if( kev < 0 )
						kev = 0;
					
					rp_SetClientInt(i, i_Kevlar, kev);
					FakeClientCommand(i, "use weapon_knife; use weapon_knifegg"); 
					rp_SetClientFloat(i, fl_TazerTime, GetGameTime() + 0.5);
				}
				else {
					rp_ClientDamage(i, 50, client, "ctf_nade_emp");
				}
			}
		}
	}
	
	vecOrigin[2] += 1.0;
	
	rp_Effect_Explode(vecOrigin, damage, 400.0, attacker, "ctf_nade_emp");
	
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 100, 400);
	TE_SendToAll();
	
	TE_SetupBeamRingPoint(vecOrigin, 1.0, 401.0, g_cShockWave, 0, 0, 20, 0.20, 50.0, 0.0, {255, 255, 255, 255}, 1, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vecOrigin, 0.1, 400.0, g_cBeam, 0, 0, 10, 0.20, 50.0, 0.0, {255, 200, 50, 200}, 1, 0);
	TE_SendToAll();
	
	rp_ScheduleEntityInput(ent, 0.25, "KillHierarchy");
}
// ------------------------------------------------------------------------------
public void C4Explode(int client, int ent) {
	if( !g_bC4Expl[ent] )
		return;
	
	float vecOrigin[3];
	char sound[128];
	Entity_GetAbsOrigin(ent, vecOrigin);
	
	rp_Effect_Explode(vecOrigin, 400.0, 250.0, client, "nade_c4");
	
	TE_SetupExplosion(vecOrigin, g_cExplode, 1.0, 0, 0, 200, 200);
	TE_SendToAll();
	
	Format(sound, sizeof(sound), "weapons/hegrenade/explode%i.wav", Math_GetRandomInt(3, 5));
	EmitSoundToAllAny(sound, ent);
	
	rp_ScheduleEntityInput(ent, 0.25, "KillHierarchy");
	
	g_bC4Expl[ent] = false;
}
public Action fwdCommand(int client, char[] command, char[] arg) {	
	if( StrEqual(command, "c4") ) { // C'est pour nous !
	
		if( rp_GetClientFloat(client, fl_CoolDown) > GetGameTime() ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez rien utiliser pour encore %.2f seconde(s).", (rp_GetClientFloat(client, fl_CoolDown)-GetGameTime()) );
			return Plugin_Handled;
		}
		
		char classname[64];
		for(int i=1; i<2048; i++) {
			if( !IsValidEdict(i) )
				continue;
			if( !IsValidEntity(i) )
				continue;
			if( !g_bC4Expl[i] )
				continue;
			
			GetEdictClassname(i, classname, sizeof(classname));
			
			if( StrEqual(classname, "ctf_nade_c4") ) {

				int owner = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity");
				if( owner != client )
					continue;

				C4Explode(client, i);
				continue;
			}
		}
		
		rp_SetClientFloat(client, fl_CoolDown, GetGameTime() + 2.5);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
// ------------------------------------------------------------------------------
public Action Cmd_ItemFireWork(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemFireWork");
	#endif
	
	int target = GetCmdArgInt(1);
	
	CreateTimer(0.1, Fire_Spriteworks01, target);
	CreateTimer(0.6, Fire_Spriteworks02, target);
	
	rp_IncrementSuccess(target, success_list_fireworks);
}

public Action Fire_Spriteworks01(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Fire_Spriteworks01");
	#endif
	float vec[3], vec2[3];
	GetClientAbsOrigin(client, vec);
	vec2 = vec; // <-- CA CAY PRATIQUE
	vec2[2] = vec[2] + 400.0;
	
	// TODO <-- Couleur de ligne différente ?
	TE_SetupBeamPoints( vec, vec2, g_cBeam, 0, 0, 0, 0.8, 2.0, 1.0, 1, 0.0, {255,255,255,50}, 10);
	TE_SendToAll();
}
public Action Fire_Spriteworks02(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Fire_Spriteworks02");
	#endif
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 400.0;
	
	char sound[128];
	Format(sound, sizeof(sound), "weapons/hegrenade/explode%i.wav", Math_GetRandomInt(3, 5));
	EmitSoundToAllAny(sound, SOUND_FROM_WORLD, _, _, _, _, _, _, vec);
	
	float vecAngle[3]; 
	rp_Effect_ParticlePath(client, "firework_crate_explosion_01", vec, vecAngle, vec);
	rp_Effect_ParticlePath(client, "firework_crate_explosion_02", vec, vecAngle, vec);
	rp_Effect_ParticlePath(client, "firework_crate_ground_sparks_01", vec, vecAngle, vec);
	
}
public Action Cmd_ItemHighJump(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemHighJump");
	#endif
	
	int client = GetCmdArgInt(1);
	
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
	velocity[0] += GetRandomFloat(-100.0, 100.0);
	velocity[1] += GetRandomFloat(-100.0, 100.0);
	velocity[2] += GetRandomFloat(500.0, 750.0);
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	
	ServerCommand("sm_effect_particles %d Trail5 1 lfoot", client);
	ServerCommand("sm_effect_particles %d Trail5 1 rfoot", client);
	
	
	return Plugin_Handled;
}
// ------------------------------------------------------------------------------
public Action Cmd_ItemBomb(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemBomb");
	#endif
	
	int client = GetCmdArgInt(1);
	int target = GetClientTarget(client);
	int item_id = GetCmdArgInt(args);
	
	if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_PEACEFULL ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit où vous êtes.");
		return Plugin_Handled;
	}
	
	char classname[64];
	GetEdictClassname(target, classname, sizeof(classname));
	if( StrContains("prop_door_rotating|func_door|chicken|player|rp_cashmachine|rp_bigcashmachine|rp_plant|weapon|prop_physics|", classname) == -1 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	if( !rp_IsEntitiesNear(client, target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}

	rp_SetClientInt(client, i_LastAgression, GetTime());

	Handle dp;
	CreateDataTimer(15.0, ItemBombOver, dp, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dp, EntIndexToEntRef(target) );
	WritePackCell(dp, client);
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} La bombe a été placée et explosera dans 15 secondes.");
	rp_Effect_BeamBox(client, target);
	
	float vecTarget[3];
	GetClientAbsOrigin(client, vecTarget);
	TE_SetupBeamRingPoint(vecTarget, 10.0, 500.0, g_cBeam, g_cGlow, 0, 15, 0.5, 50.0, 0.0, {100, 100, 100,100}, 10, 0);
	TE_SendToAll();
	
	TE_SetupBeamFollow(client, g_cBeam, g_cGlow, 15.0, 5.0, 0.1, 0, {100, 100, 100, 100});
	TE_SendToAll();
	
	return Plugin_Handled;
}
public Action ItemBombOver(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("ItemBombOver");
	#endif
	
	if( dp == INVALID_HANDLE ) {
		return Plugin_Handled;
	}
	ResetPack(dp);
	
	int target 	= EntRefToEntIndex( ReadPackCell(dp) );
	int client	= ReadPackCell(dp);
	
	float vecOrigin[3];
	if( IsValidClient(target) )
		GetClientEyePosition(target, vecOrigin);
	else if( IsValidEdict(target) )
		Entity_GetAbsOrigin(target, vecOrigin);
	else
		return Plugin_Handled;
	
	rp_Effect_Explode(vecOrigin, 100.0, 128.0, client, "weapon_c4");
	
	return Plugin_Handled;
}