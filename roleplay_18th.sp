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
#include <cstrike>
#include <csgo_items>   // https://forums.alliedmods.net/showthread.php?t=243009
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

// TODO: Gérer le mandat de perquiz correctement.
// TODO: Déplacer le /vol.

public Plugin myinfo = {
	name = "Jobs: 18th", author = "KoSSoLaX",
	description = "RolePlay - Jobs: 18th",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iWeaponStolen[2049];

int g_cBeam, g_cGlow;
// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_piedbiche", 	Cmd_ItemPiedBiche,		"RP-ITEM",	FCVAR_UNREGISTERED);	
	RegServerCmd("rp_item_picklock", 	Cmd_ItemPickLock,		"RP-ITEM",	FCVAR_UNREGISTERED); 
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerUse,	fwdOnPlayerUse);
}
public void OnClientDisconnect(int client) {
	rp_UnhookEvent(client, RP_OnPlayerUse,	fwdOnPlayerUse);
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
	speed += 0.4;
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
	
	
	
	if( rp_GetClientInt(client, i_Job) >= 104 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes pas assez haut gradé.");
		return Plugin_Handled;
	}	
		
	int target = GetClientTarget(client);
	if( !rp_IsValidVehicle(target) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser une voiture.");
		return Plugin_Handled;
	}
	if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_BLOCKSTEAL || rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_BLOCKSTEAL ) {
		ITEM_CANCEL(client, item_id);
		ACCESS_DENIED(client);
	}
	
	if( !rp_IsEntitiesNear(client, target) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez etre plus proche de la voiture pour la voler.");
		return Plugin_Handled;
	}
		
	/* TODO:
	int appart = getZoneAppart(g_iVehicleData[target][car_owner]);
	if( appart > 0 && g_iAppartBonus[appart][appart_bonus_garage] ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler cette voiture.");
		return Plugin_Handled;
	}*/
	if( rp_GetZoneBit(rp_GetPlayerZone(target)) & BITZONE_PARKING ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler cette voiture sur un parking.");
		return Plugin_Handled;
	}
		
	float vecTarget[3];
	GetClientAbsOrigin(client, vecTarget);
	TE_SetupBeamRingPoint(vecTarget, 10.0, 500.0, g_cBeam, g_cGlow, 0, 15, 0.5, 50.0, 0.0, {255, 0, 0, 200}, 10, 0);
	TE_SendToAll();
	
	rp_ClientGiveItem(client, item_id, -rp_GetClientItem(client, item_id));
	rp_SetClientBool(client, b_MaySteal, false);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, 15.0);
		
	ServerCommand("sm_effect_panel %d 15.0 \"Crochetage de la voiture...\"", client);
	
	CreateTimer(5.0, timerAlarm, target);
	CreateTimer(10.0, timerAlarm, target);
	
	rp_ClientColorize(client, { 255, 0, 0, 255 } );
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
	
	if( !rp_IsEntitiesNear(client, target) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez etre plus proche de la voiture pour la voler.");
		CreateTimer(0.01, AllowStealing, client);
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
			
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} %d billets ont été sorti de la boite a gants.", rand);
			
		while(rand >= 1 ) {
			rand--;
			rp_Effect_SpawnMoney(vecOrigin, true);
			
			int mnt = Math_GetRandomInt(2, 5) * 10;
			int cpt = rp_GetRandomCapital(181);
			
			rp_SetJobCapital(181, rp_GetJobCapital(181) + mnt);
			rp_SetJobCapital(cpt, rp_GetJobCapital(cpt) - mnt);
		}
	}
	
	
	rp_SetClientKeyVehicle(client, target, true);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez maintenant les clés de cette voiture.");
	
	
	return Plugin_Continue;
}
public void OnEntityCreated(int ent, const char[] classname) {
	g_iWeaponStolen[ent] = GetTime() - 100;
}
int findPlayerWeapon(int client, int target) {
	
	if( rp_GetClientJobID(target)==41 && rp_GetClientInt(target, i_ToKill) > 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler un tueur sous contrat.");
		return -1;
	}
	if( rp_IsClientNew(target) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler un nouveau joueur");
		return -1;
	}
	if( !rp_IsTutorialOver(target) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur n'a pas terminé le tutorial.");
		return -1;
	}
	if( rp_GetClientBool(target, b_Stealing) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Quelqu'un d'autre est déjà entrain de voler ce joueur.");
		return -1;
	}
	if( rp_GetClientFloat(target, fl_LastStolen)+(STEAL_TIME) > GetGameTime() ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur s'est déjà fait volé récement.");
		return -1;
	}
	if( rp_GetClientFloat(target, fl_Invincible) >= GetGameTime() ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur est invincible.");
		return -1;
	}
	if( rp_GetClientJobID(target) == 181 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler un autre 18th");
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
// ----------------------------------------------------------------------------
public Action Cmd_ItemPickLock(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPickLock");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int target = GetClientTarget(client);
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
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez etre plus proche du joueur pour le voler.");
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
	
	int alpha[4], job;
	alpha[0] = 255;
	alpha[3] = 128;
	job = rp_GetClientInt(client, i_Job);
	
	if( rp_IsNight() )
		alpha[3] = 50;
	
	TE_SetupBeamRingPoint(vecStart, 0.0, 10.0, g_cBeam, 0, 0, 10, 1.0, 20.0, 1.0, alpha, 1, 0);
	TE_SendToAll();
	TE_SetupBeamRingPoint(vecEnd, 30.0, 40.0, g_cBeam, 0, 0, 10, 1.0, 20.0, 1.0, alpha, 1, 0);
	TE_SendToAll();
	
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdAccelerate, 5.0);
	
	rp_ClientColorize(client, { 255, 0, 0, 255 } );
	rp_ClientReveal(client);
	
	// Anti-cheat:
	if( rp_GetClientItem(client, item_id) >= GetMaxKit(client, item_id)-1 ) {
		rp_ClientGiveItem(client, item_id, -rp_GetClientItem(client, item_id) + GetMaxKit(client, item_id) - 1);
	}
		
	float StealTime = 6.0;
	switch( job ) {
		case 181:	StealTime = 3.0;
		case 182:	StealTime = 3.5;
		case 183:	StealTime = 4.0; // Haut gradé
		case 184:	StealTime = 4.5; // Pro
		case 185:	StealTime = 5.0; // Narmol
		case 186:	StealTime = 5.5; // Apprenti
		
		default:	StealTime = 6.0;
	}
	
	
	Handle dp;
	CreateDataTimer(StealTime, ItemPickLockOver_18th, dp, TIMER_DATA_HNDL_CLOSE);
	WritePackCell(dp, client);
	WritePackCell(dp, target);
	WritePackCell(dp, EntIndexToEntRef(wepid));
	
	rp_SetClientBool(client, b_MaySteal, false);
	rp_SetClientBool(target, b_Stealing, true);
	
	
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
	rp_SetClientBool(target, b_Stealing, false);
	
	rp_ClientColorize(client);
	rp_ClientReveal(client);
	
	
	
	
	if ( rp_GetClientFloat(target, fl_Invincible) >= GetGameTime() )
		return Plugin_Handled;
		
	char wepname[64], wepdata[64];
	if( IsValidEdict(wepid) && IsValidEntity(wepid) ) {
		int index = GetEntProp(wepid, Prop_Send, "m_iItemDefinitionIndex");
		CSGO_GetItemDefinitionNameByIndex(index, wepname, sizeof(wepname));
	}
	
	int price = CS_GetWeaponPrice2( CS_AliasToWeaponID(wepdata) );
	
	if( IsValidEdict(wepid) && IsValidEntity(wepid) &&
		IsValidClient(target) && rp_IsEntitiesNear(client, target, false, -1.0) &&
		Entity_GetOwner(wepid) == target
	) {
		
		if( rp_GetClientFloat(target, fl_LastStolen)+(60.0) < GetGameTime() && g_iWeaponStolen[wepid]+(15*60) < GetTime() )
		{
				
			if( rp_GetClientBool(target, b_IsAFK) && (rp_GetClientJobID(target) == 1 || rp_GetClientJobID(target) == 101 ) ) {
			
				int button = GetClientButtons(client);
			
				if( button & IN_FORWARD || button & IN_BACK || button & IN_LEFT || button & IN_RIGHT ||
					button & IN_MOVELEFT || button & IN_MOVERIGHT || button & IN_ATTACK || button & IN_JUMP || button & IN_DUCK	) {
					price *= 2.0;
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vol en action, argent doublé");
				}
			
				int amount = RoundFloat( (float(price)/100.0) * (25.0) );
				
				if( (rp_GetClientInt(client, i_Money)+rp_GetClientInt(client, i_Bank)) < amount ) {
					amount = rp_GetClientInt(client, i_Money) + rp_GetClientInt(client, i_Bank);
				}
				
				rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money) + amount);
				rp_SetClientInt(target, i_Money, rp_GetClientInt(client, i_Money) - amount);
			}
				
			int cpt = rp_GetRandomCapital(181);
			rp_SetJobCapital(181, (rp_GetJobCapital(181) +  (price/2) ) );
			rp_SetJobCapital(cpt, (rp_GetJobCapital(cpt) -  (price/2) ) );
				
		}
	}
	else {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le joueur n'avait plus son arme sur lui.");
		return Plugin_Handled;
	}
	
	float time = GetGameTime();
	if( rp_GetClientBool(target, b_IsAFK) )
		time += 5.0 * 60.0;
	
	rp_SetClientFloat(target, fl_LastStolen, time);
	rp_SetClientInt(client, i_LastVolAmount, price/2);
	rp_SetClientInt(client, i_LastVolTarget, target);
	rp_SetClientInt(target, i_LastVol, client);
	
	char SteamID[64], szQuery[1024];
	
	GetClientAuthId(client, AuthId_Engine, SteamID, sizeof(SteamID), false);
	Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '4', '%i', '%s', '%i');",
	SteamID, rp_GetClientJobID(client), GetTime(), 0, "Vol: Arme", price/2);
	
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
	
	
	LogToGame("[TSX-RP] [VOL-18TH] %L a vole %s de %L", client, wepname, target);
	
	rp_ClientSwitchWeapon(target, wepid, client);
	g_iWeaponStolen[wepid] = GetTime();
	//g_iSuccess_last_pas_vu_pas_pris[target] = GetTime();
	
	FakeClientCommand(target, "use weapon_knife");
	
	return Plugin_Handled;
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
int GetMaxKit(int client, int itemID) {
	if( client ) { } // Hu?
	
	if( itemID == ITEM_KITCROCHTAGE )
		return 3;
	return 1;
}
int CS_GetWeaponPrice2(CSWeaponID id) {
	
	static const int priceList[CSWeaponID] = {
		0, 500, 200, 1700, 300, 2000, 0, 1050, 3300, 300, 500, 500, 1200, 4200, 2000, 2250, 500, 4750,
		1500, 5200, 1700, 3100, 1250, 5000, 200, 700, 3500, 2700, 0, 2350, 2200, 650, 1000, 1250, 2000,
		1400, 1800, 5700, 1200, 500, 400, 200, 1700, 1250, 1200, 300, 5000, 5000, 3000, 2750, 0, 400,
		50, 600, 400 };

	return priceList[id];
}