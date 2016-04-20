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
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MAX_AREA_DIST 		500
#define STEAL_TIME			30.0
#define ITEM_PIEDBICHE		1
#define ITEM_KITCROCHTAGE	2

public Plugin myinfo = {
	name = "Jobs: 18th", author = "KoSSoLaX",
	description = "RolePlay - Jobs: 18th",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iWeaponStolen[2049];
int g_iStolenAmountTime[65];

int g_cBeam, g_cGlow;

forward void RP_On18thStealWeapon(int client, int victim, int weaponID);
Handle g_RP_On18thStealWeapon;

// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	g_RP_On18thStealWeapon = CreateGlobalForward("RP_On18thStealWeapon", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	
	RegServerCmd("rp_item_piedbiche", 	Cmd_ItemPiedBiche,		"RP-ITEM",	FCVAR_UNREGISTERED);	
	RegServerCmd("rp_item_picklock", 	Cmd_ItemPickLock,		"RP-ITEM",	FCVAR_UNREGISTERED); 
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
}
// ----------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerUse,	fwdOnPlayerUse);
	rp_HookEvent(client, RP_OnPlayerSteal,	fwdOnPlayerSteal);	
}
public Action fwdOnPlayerSteal(int client, int target, float& cooldown) {
	if( rp_GetClientJobID(client) != 181 )
		return Plugin_Continue;
	
	static char tmp[128], szQuery[1024];
	
	if( rp_GetClientJobID(target) == 181 ) {
		ACCESS_DENIED(client);
	}
	if( rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_BLOCKSTEAL ) {
		ACCESS_DENIED(client);
	}
	if( rp_ClientFloodTriggered(client, target, fd_vol) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler %N, pour le moment.", target);
		return Plugin_Handled;
	}
	
	int VOL_MAX, amount, money;
	money = rp_GetClientInt(target, i_Money);
	VOL_MAX = (money+rp_GetClientInt(target, i_Bank)) / 200;
	
	if( rp_IsClientNew(target) )
		amount = Math_GetRandomPow(1, VOL_MAX);
	else
		amount = Math_GetRandomInt(1, VOL_MAX);
	
	if( VOL_MAX > 0 && money >= 1 ) {
		if( amount > money )
			amount = money;
			
		rp_SetClientStat(target, i_MoneySpent_Stolen, rp_GetClientStat(target, i_MoneySpent_Stolen) + amount);
		rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + amount);
		rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - amount);
		
		rp_SetClientInt(client, i_LastVolTime, GetTime());
		rp_SetClientInt(client, i_LastVolAmount, amount);
		rp_SetClientInt(client, i_LastVolTarget, target);
		rp_SetClientInt(target, i_LastVol, client);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez volé %d$.", amount);
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Quelqu'un vous a volé %d$.", amount);

		//g_iSuccess_last_mafia[client][1] = GetTime();
		//g_iSuccess_last_pas_vu_pas_pris[target] = GetTime();
		LogToGame("[TSX-RP] [VOL] %L a vole %L %i$", client, target, amount);
		
		GetClientAuthId(client, AuthId_Engine, tmp, sizeof(tmp), false);
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
			tmp, rp_GetClientJobID(client), GetTime(), 0, "Vol: Argent", amount);
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		
		
		if( rp_IsNight() )
			cooldown *= 0.5;
		
		if( amount < 50 )
			cooldown *= 0.5;
		if( amount < 5 )
			cooldown *= 0.5;
			
		if( amount > 500 )
			rp_SetClientFloat(client, fl_LastVente, GetGameTime() + 10.0);
		if( amount > 2000 )
			rp_SetClientFloat(client, fl_LastVente, GetGameTime() + 30.0);
		
		rp_ClientFloodIncrement(client, target, fd_vol, cooldown);
		
		ServerCommand("sm_effect_particles %d Aura2 2", client);
		
		int cpt = rp_GetRandomCapital(181);
		rp_SetJobCapital(181, rp_GetJobCapital(181) + (amount/4));
		rp_SetJobCapital(cpt, rp_GetJobCapital(cpt) - (amount/4));
	}
	else {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N n'a pas d'argent sur lui.", target);
		cooldown = 1.0;
	}
	
	return Plugin_Stop;
}
public Action fwdOnPlayerUse(int client) {
	#if defined DEBUG
	PrintToServer("fwdOnPlayerUse");
	#endif
	static char tmp[128];
	
	if( rp_GetClientJobID(client) == 181 && rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) == 181 ) {
		
		int itemID = ITEM_KITCROCHTAGE;
		int mnt = rp_GetClientItem(client, itemID);
		int max = GetMaxKit(client, itemID);
		if( mnt <  max ) {
			rp_ClientGiveItem(client, itemID, max - mnt);
			rp_GetItemData(itemID, item_type_name, tmp, sizeof(tmp));
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez récupéré %i %s.", max - mnt, tmp);
			
			FakeClientCommand(client, "say /item");
		}
		
		itemID = ITEM_PIEDBICHE;
		mnt = rp_GetClientItem(client, itemID);
		max = GetMaxKit(client, itemID);
		if( mnt <  max ) {
			rp_ClientGiveItem(client, itemID, max - mnt);
			rp_GetItemData(itemID, item_type_name, tmp, sizeof(tmp));
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez récupéré %i %s.", max - mnt, tmp);
			
			FakeClientCommand(client, "say /item");
		}
		
	}
}
// ----------------------------------------------------------------------------
public Action fwdFrozen(int client, float& speed, float& gravity) {
	speed = 0.0;
	gravity = 0.0; 
	return Plugin_Stop;
}
public Action fwdAccelerate(int client, float& speed, float& gravity) {
	speed += 0.5;
	return Plugin_Changed;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPiedBiche(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPiedBiche");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( rp_GetClientJobID(client) != 181 ) {
		return Plugin_Continue;
	}
	
	if( rp_GetClientBool(client, b_MaySteal) == false ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler pour le moment.");
		return Plugin_Handled;
	}
	
	if( rp_GetClientVehiclePassager(client) > 0 || Client_GetVehicle(client) > 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible d'utiliser cet item dans une voiture.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	int target = rp_GetClientTarget(client);
	if( !rp_IsValidVehicle(target) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser une voiture.");
		return Plugin_Handled;
	}
	char model[64];
	Entity_GetModel(target, model, sizeof(model));
	
	if( StrContains(model, "07crownvic_cvpi") == -1 ) {
		if( rp_GetClientInt(client, i_Job) >= 184 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes pas assez haut gradé.");
			return Plugin_Handled;
		}
	}
	
	if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_BLOCKSTEAL || rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_BLOCKSTEAL ) {
		ITEM_CANCEL(client, item_id);
		ACCESS_DENIED(client);
	}
	
	if( !rp_IsEntitiesNear(client, target) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être plus proche de la voiture pour la voler.");
		return Plugin_Handled;
	}
	
	
	int appart = rp_GetPlayerZoneAppart( rp_GetVehicleInt(target, car_owner) );
	if( appart > 0 && rp_GetAppartementInt(appart, appart_bonus_garage) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler cette voiture, le propriétaire est dans son appartement.");
		return Plugin_Handled;
	}
	
	if( rp_GetZoneBit(rp_GetPlayerZone(target)) & BITZONE_PARKING ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler de voiture dans le garage.");
		return Plugin_Handled;
	}

	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) + 1);
		
	float vecTarget[3];
	GetClientAbsOrigin(client, vecTarget);
	TE_SetupBeamRingPoint(vecTarget, 10.0, 500.0, g_cBeam, g_cGlow, 0, 15, 0.5, 50.0, 0.0, {255, 0, 0, 200}, 10, 0);
	TE_SendToAll();
	
	rp_ClientGiveItem(client, item_id, -rp_GetClientItem(client, item_id));
	rp_SetClientBool(client, b_MaySteal, false);
	rp_SetClientInt(client, i_LastVolTime, GetTime());
	rp_SetClientInt(client, i_LastVolAmount, 100);
	rp_SetClientInt(client, i_LastVolTarget, -1);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, 15.0);
		
	ServerCommand("sm_effect_panel %d 15.0 \"Crochetage de la voiture...\"", client);
	
	CreateTimer(5.0, timerAlarm, target);
	CreateTimer(10.0, timerAlarm, target);
	
	rp_ClientColorize(client, { 255, 0, 0, 190 } );
	rp_ClientReveal(client);
		
	Handle dp;
	CreateDataTimer(15.0, ItemPiedBicheOver, dp, TIMER_DATA_HNDL_CLOSE);
		
	WritePackCell(dp, client);
	WritePackCell(dp, target);
		
	return Plugin_Handled;

}
public Action ItemPiedBicheOver(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("ItemPiedBicheOver");
	#endif
	
	if( dp == INVALID_HANDLE ) {
		return Plugin_Handled;
	}
	ResetPack(dp);
	int client 	= ReadPackCell(dp);
	int target	= ReadPackCell(dp);
	
	rp_ClientColorize(client);
	rp_ClientReveal(client);
	
	if( !rp_IsEntitiesNear(client, target) || !IsPlayerAlive(client) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être plus proche de la voiture pour la voler.");
		rp_SetClientBool(client, b_MaySteal, true);
		return Plugin_Handled;
	}
	
	int rand = 4 + Math_GetRandomPow(0, 4), count = 0, job;
	for(int i=1; i<MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		job = rp_GetClientInt(i, i_Job);
		
		if( GetClientTeam(i) == CS_TEAM_CT || (job >= 1 && job <= 7 ) ) {
			if( Entity_GetDistance(client, i) < (MAX_AREA_DIST+100) ) {
				rand += (4 + Math_GetRandomPow(0, 12));
				count++;
				if( count >= 5 )
					break;
			}
		}
	}
	
	float vecOrigin[3];
	GetClientEyePosition(client, vecOrigin);
	
	if( !rp_GetClientKeyVehicle(client, target) ) {
			
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %d billets ont été sortis de la boîte à gants.", rand);
			
		while(rand >= 1 ) {
			rand--;
			rp_Effect_SpawnMoney(vecOrigin, true);
			
			int mnt = Math_GetRandomInt(2, 5) * 10;
			int cpt = rp_GetRandomCapital(181);
			
			rp_SetJobCapital(181, rp_GetJobCapital(181) + mnt);
			rp_SetJobCapital(cpt, rp_GetJobCapital(cpt) - mnt);
		}
	}
	
	rp_SetClientStat(client, i_JobSucess, rp_GetClientStat(client, i_JobSucess) + 1);
	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) - 1);
	rp_SetClientBool(client, b_MaySteal, true);
	rp_SetClientKeyVehicle(client, target, true);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez maintenant les clés de cette voiture.");
	rp_SetClientInt(client, i_LastVolAmount, 150);
	rp_SetClientInt(client, i_LastVolTarget, -1);
	rp_SetClientInt(client, i_LastVolVehicle, target);
	rp_SetClientInt(client, i_LastVolVehicleTime, GetTime());
	
	return Plugin_Continue;
}
public void OnEntityCreated(int ent, const char[] classname) {
	if( ent > 0 ) {
		g_iWeaponStolen[ent] = GetTime() - 110;
	}
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPickLock(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPickLock");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int target = rp_GetClientTarget(client);
	float vecEnd[3], vecStart[3];
	
	if( rp_GetClientJobID(client) != 181 ) {
		return Plugin_Continue;
	}
	
	if( !IsValidClient(target) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser un joueur.");
		return Plugin_Handled;
	}
	if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_BLOCKSTEAL || rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_BLOCKSTEAL ) {
		ITEM_CANCEL(client, item_id);
		ACCESS_DENIED(client);
	}
		
	if( !rp_IsEntitiesNear(client, target) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être plus proche du joueur pour le voler.");
		return Plugin_Handled;
	}
	

	int wepid = findPlayerWeapon(client, target);
	
		
	if( wepid == -1 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
			
	CPrintToChat(target, "{lightblue}[TSX-RP]{default} Quelqu'un essaye de vous voler.");
	
	GetClientEyePosition(client, vecStart);		
	GetClientEyePosition(target, vecEnd);
	
	int job;
	job = rp_GetClientInt(client, i_Job);
	
	
	rp_ClientReveal(client);
	
	// Anti-cheat: 
	if( rp_GetClientItem(client, item_id) >= GetMaxKit(client, item_id)-1 ) {
		rp_ClientGiveItem(client, item_id, -rp_GetClientItem(client, item_id) + GetMaxKit(client, item_id) - 1);
	}
	
	char wepname[64];
	GetEdictClassname(wepid, wepname, sizeof(wepname));
	ReplaceString(wepname, sizeof(wepname), "weapon_", "");	
	int price = rp_GetWeaponPrice(wepid); 
	
	float StealTime = (Logarithm(float(price), 2.0) * 0.5) - 2.0;
	
	switch( job ) {
		case 181:	StealTime += 0.1;
		case 182:	StealTime += 0.2;
		case 183:	StealTime += 0.3; // Haut gradé
		case 184:	StealTime += 0.4; // Pro
		case 185:	StealTime += 0.5; // Narmol
		case 186:	StealTime += 0.6; // Apprenti
		
		default:	StealTime += 0.7;
	}
	
	if( !rp_IsTargetSeen(target, client) ) {
		StealTime -= 0.4;
	}
	
	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) + 1);
	rp_SetClientInt(client, i_LastVolVehicleTime, GetTime());
	rp_SetClientInt(client, i_LastVolAmount, 100);
	rp_SetClientInt(client, i_LastVolTarget, target);
	ServerCommand("sm_effect_particles %d Aura1 %d", client, RoundToCeil(StealTime));
	
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdAccelerate, StealTime);
	rp_HookEvent(client, RP_PreTakeDamage, fwdDamage, StealTime);
	
	Handle dp;
	CreateDataTimer(StealTime, ItemPickLockOver_18th, dp, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
	WritePackCell(dp, EntIndexToEntRef(wepid));
	
	rp_SetClientBool(client, b_MaySteal, false);
	rp_SetClientBool(target, b_Stealing, true);
	SDKHook(target, SDKHook_WeaponDrop, OnWeaponDrop);
	
	return Plugin_Handled;
}
public Action ItemPickLockOver_18th(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("ItemPickLockOver_18th");
	#endif
	if( dp == INVALID_HANDLE ) {
		return Plugin_Handled;
	}
	
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int target 	 = ReadPackCell(dp);
	int wepid = EntRefToEntIndex(ReadPackCell(dp));
	
	CreateTimer(STEAL_TIME/2.0, AllowStealing, client);	
	
	rp_ClientColorize(client);
	rp_ClientReveal(client);
	
	if( rp_GetClientBool(target, b_Stealing) == false || !IsPlayerAlive(client) || !IsPlayerAlive(target) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N s'est débattu, le vol a échoué.", target);
		rp_SetClientBool(target, b_Stealing, false);
		SDKUnhook(target, SDKHook_WeaponDrop, OnWeaponDrop);
		return Plugin_Handled;
	}
	if( (rp_IsClientNew(target) || (rp_GetClientJobID(target)==41 && rp_GetClientInt(target, i_ToKill) > 0) || (rp_GetWeaponBallType(wepid) == ball_type_nosteal)) && Math_GetRandomInt(0,3) != 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N est plus difficile à voler qu'un autre...", target);
		rp_SetClientBool(target, b_Stealing, false);
		SDKUnhook(target, SDKHook_WeaponDrop, OnWeaponDrop);
		return Plugin_Handled;
	}
	
	if ( rp_GetClientFloat(target, fl_Invincible) >= GetGameTime() ) {
		rp_SetClientBool(target, b_Stealing, false);
		SDKUnhook(target, SDKHook_WeaponDrop, OnWeaponDrop);
		return Plugin_Handled;
	}
	

	rp_SetClientBool(target, b_Stealing, false);
	g_iStolenAmountTime[target]++;
	CreateTimer(300.0, RemoveStealAmount, target);
	
	if( !rp_IsTargetSeen(target, client) ) {
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdAccelerate, 5.0);
		rp_HookEvent(client, RP_PrePlayerPhysic, fwdAccelerate, 1.0);
	}
	
	char wepname[64];
	GetEdictClassname(wepid, wepname, sizeof(wepname));
	ReplaceString(wepname, sizeof(wepname), "weapon_", "");	
	int price = rp_GetWeaponPrice(wepid);
	
	if( IsValidEdict(wepid) && IsValidEntity(wepid) &&
		IsValidClient(target) && rp_IsEntitiesNear(client, target, false, -1.0) &&
		Entity_GetOwner(wepid) == target
	) {
		
		if( rp_GetClientFloat(target, fl_LastStolen)+(60.0) < GetGameTime() && g_iWeaponStolen[wepid]+(120) < GetTime() ) {
			
			if( !rp_GetClientBool(target, b_IsAFK) && (rp_GetClientJobID(target) == 1 || rp_GetClientJobID(target) == 101) ) {
			
				int button = GetClientButtons(target);
			
				if( button & IN_FORWARD || button & IN_BACK || button & IN_LEFT || button & IN_RIGHT ||
					button & IN_MOVELEFT || button & IN_MOVERIGHT || button & IN_ATTACK || button & IN_JUMP || button & IN_DUCK	) {
					price *= 2;
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vol en action, argent doublé");
				}
			
				int amount = RoundFloat( (float(price)/100.0) * (25.0) );
				
				if( (rp_GetClientInt(target, i_Money)+rp_GetClientInt(target, i_Bank)) < amount ) {
					amount = rp_GetClientInt(target, i_Money) + rp_GetClientInt(target, i_Bank);
				}
				
				
				rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + amount);
				rp_SetClientInt(target, i_Money, rp_GetClientInt(target, i_Money) - amount);
			}
			
			int cpt = rp_GetRandomCapital(181);
			rp_SetJobCapital(181, (rp_GetJobCapital(181) +  (price/2) ) );
			rp_SetJobCapital(cpt, (rp_GetJobCapital(cpt) -  (price/2) ) );
			
			Call_StartForward(g_RP_On18thStealWeapon);
			Call_PushCell(client);
			Call_PushCell(target);
			Call_PushCell(wepid);
			Call_Finish();
				
		}
		else {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} L'arme %s de %N s'est déjà faite volée il y a quelques instants.", wepname, target);
		}
	}
	else {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le joueur n'avait plus son arme sur lui.");
		SDKUnhook(target, SDKHook_WeaponDrop, OnWeaponDrop);
		return Plugin_Handled;
	}
	
	float time = GetGameTime();
	if( rp_GetClientBool(target, b_IsAFK) )
		time += 5.0 * 60.0;
	
	rp_SetClientFloat(target, fl_LastStolen, time);
	rp_SetClientInt(client, i_LastVolTime, GetTime());
	rp_SetClientInt(client, i_LastVolAmount, price/4);
	rp_SetClientInt(client, i_LastVolTarget, target);
	rp_SetClientInt(target, i_LastVol, client);
	
	char SteamID[64], szQuery[1024];
	
	GetClientAuthId(client, AuthId_Engine, SteamID, sizeof(SteamID), false);
	Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
	SteamID, rp_GetClientJobID(client), GetTime(), 0, "Vol: Arme", price/2);
	
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
	
	rp_SetClientStat(client, i_JobSucess, rp_GetClientStat(client, i_JobSucess) + 1);
	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) - 1);
	LogToGame("[TSX-RP] [VOL-18TH] %L a vole %s de %L", client, wepname, target);
	
	RemovePlayerItem(target, wepid);
	EquipPlayerWeapon(client, wepid);
	
	g_iWeaponStolen[wepid] = GetTime();
	//g_iSuccess_last_pas_vu_pas_pris[target] = GetTime();
	
	FakeClientCommand(target, "use weapon_knife");
	
	SDKUnhook(target, SDKHook_WeaponDrop, OnWeaponDrop);
	return Plugin_Handled;
}
int findPlayerWeapon(int client, int target) {
	
	if( !rp_IsTutorialOver(target) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur n'a pas terminé le tutoriel.");
		return -1;
	}
	if( rp_GetClientBool(target, b_Stealing) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Quelqu'un d'autre est déjà en train de voler ce joueur.");
		return -1;
	}
	
	if( (g_iStolenAmountTime[target] >= 3 && rp_GetClientFloat(target, fl_LastStolen)+(STEAL_TIME) > GetGameTime()) || (g_iStolenAmountTime[target] >= 5) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur s'est déjà fait volé récemment.");
		return -1;
	}
	if( rp_GetClientFloat(target, fl_Invincible) >= GetGameTime() ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur est invincible.");
		return -1;
	}
	if( rp_GetClientJobID(target) == 181 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler un autre 18th.");
		return -1;
	}
	
	int wepid;
	for( int i = 0; i < 5; i++ ) {
		if( i == 2 )
			continue;
			
		wepid = GetPlayerWeaponSlot( target, i );
		if( !IsValidEdict(wepid) )
			continue;
		if( g_iWeaponStolen[wepid]+120 > GetTime() )
			continue;
		
		return wepid;
	}
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur n'a pas d'arme.");
	return -1;
}
public Action OnWeaponDrop(int client, int weapon) {
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas lâcher vos armes pendant qu'un 18th vous vol, tirez lui dessus !");
	return Plugin_Handled;
}
public Action fwdDamage(int client, int attacker, float& damage) {
	
	if( Math_GetRandomInt(0, 4) == 4 && rp_GetClientBool(attacker, b_Stealing) == true ) {
		rp_SetClientBool(attacker, b_Stealing, false);
		rp_ClientColorize(client);
		rp_ClientReveal(client);
	}
	
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action timerAlarm(Handle timer, any door) {
	#if defined DEBUG
	PrintToServer("timerAlarm");
	#endif
	
	EmitSoundToAllAny("UI/arm_bomb.wav", door);
	return Plugin_Handled;
}
public Action AllowStealing(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("AllowStealing");
	#endif
	
	rp_SetClientBool(client, b_MaySteal, true);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous pouvez à nouveau voler.");
}
public Action RemoveStealAmount(Handle time, any client) {
	g_iStolenAmountTime[client]--;
}
int GetMaxKit(int client, int itemID) {
	
	if( itemID == ITEM_KITCROCHTAGE ) {
		int job = rp_GetClientInt(client, i_Job);
		switch( job ) {
			case 181:	return 5;
			case 182:	return 5;
			case 183:	return 4; // Haut gradé
			case 184:	return 3; // Pro
			case 185:	return 2; // Narmol
			case 186:	return 1; // Apprenti
			
			default:	return 2;
		}
		return 2;
	}
	
	return 1;
}
