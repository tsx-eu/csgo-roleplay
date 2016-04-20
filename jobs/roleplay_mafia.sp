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
#define ITEM_KITEXPLOSIF	3

// TODO: Repensé le /vol pour fusionner doublon.

public Plugin myinfo = {
	name = "Jobs: Mafia", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Mafia",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_cBeam, g_cGlow, g_cExplode;
int g_iDoorDefine_ALARM[2049], g_iDoorDefine_LOCKER[2049];
Handle g_hForward_RP_OnClientStealItem;
bool doRP_CanClientStealItem(int client, int target) {
	Action a;
	Call_StartForward(g_hForward_RP_OnClientStealItem);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_Finish(a);
	if( a == Plugin_Handled || a == Plugin_Stop )
		return false;
	return true;
}
// ----------------------------------------------------------------------------
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	RegServerCmd("rp_item_piedbiche", 	Cmd_ItemPiedBiche,		"RP-ITEM",	FCVAR_UNREGISTERED);	
	RegServerCmd("rp_item_picklock", 	Cmd_ItemPickLock,		"RP-ITEM",	FCVAR_UNREGISTERED); 
	RegServerCmd("rp_item_picklock2", 	Cmd_ItemPickLock,		"RP-ITEM",	FCVAR_UNREGISTERED);	
	// Epicier
	RegServerCmd("rp_item_doorDefine",	Cmd_ItemDoorDefine,		"RP-ITEM",	FCVAR_UNREGISTERED);
	
	g_hForward_RP_OnClientStealItem = CreateGlobalForward("RP_CanClientStealItem", ET_Event, Param_Cell, Param_Cell);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
	g_cExplode = PrecacheModel("materials/sprites/muzzleflash4.vmt", true);
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerUse,	fwdOnPlayerUse);
	rp_HookEvent(client, RP_OnPlayerSteal,	fwdOnPlayerSteal);
	
}
public void OnClientDisconnect(int client) {
	for(int i=0; i<2049; i++){
		if(g_iDoorDefine_ALARM[i] == client)
			g_iDoorDefine_ALARM[i] = 0;

		if(g_iDoorDefine_LOCKER[i] == client)
			g_iDoorDefine_LOCKER[i] = 0;
	}
}
public Action fwdOnPlayerSteal(int client, int target, float& cooldown) {
	if( rp_GetClientJobID(client) != 91 )
		return Plugin_Continue;
	static int RandomItem[MAX_ITEMS];
	static char tmp[128], szQuery[1024];
	
	if( rp_GetClientJobID(target) == 91 ) {
		ACCESS_DENIED(client);
	}
	if( rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_BLOCKSTEAL ) {
		ACCESS_DENIED(client);
	}
	
	int VOL_MAX, amount, money, job, prix;
	
	
	money = rp_GetClientInt(target, i_Money);
	VOL_MAX = (money+rp_GetClientInt(target, i_Bank)) / 200;
	
	if( rp_IsClientNew(target) )
		amount = Math_GetRandomPow(1, VOL_MAX);
	else
		amount = Math_GetRandomInt(1, VOL_MAX);
	
	if( VOL_MAX > 0 && money <= 0 && rp_GetClientInt(client, i_Job) <= 93 && !rp_IsClientNew(target) && doRP_CanClientStealItem(client, target) ) {
		amount = 0;
		
		for(int i = 0; i < MAX_ITEMS; i++) {
			
			if( rp_GetClientItem(target, i) <= 0 )
				continue;
				
			job = rp_GetItemInt(i, item_type_job_id);
			if( job == 0|| job == 91 || job == 101 || job == 181 )
				continue;
			if( job == 51 && !(rp_GetClientItem(target, i) >= 1 && Math_GetRandomInt(0, 1) == 1) ) // TODO: Double vérif voiture
				continue;
			
			RandomItem[amount++] = i;
		}
		
		if( amount == 0  ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce joueur n'a pas d'argent, ni d'item sur lui.");
			cooldown = 1.0;
			return Plugin_Stop;
		}
		
		int i = RandomItem[ Math_GetRandomInt(0, (amount-1)) ];
		prix = rp_GetItemInt(i, item_type_prix) / 2;
		
		rp_ClientGiveItem(target, i, -1);
		rp_ClientGiveItem(client, i, 1);
		
		rp_SetClientInt(client, i_LastVolTime, GetTime());
		rp_SetClientInt(client, i_LastVolAmount, prix);
		rp_SetClientInt(client, i_LastVolTarget, target);
		rp_SetClientInt(target, i_LastVol, client);		
		rp_SetClientFloat(target, fl_LastVente, GetGameTime() + 10.0);
		
		rp_GetItemData(i, item_type_name, tmp, sizeof(tmp));
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez volé: %s.", tmp);
		CPrintToChat(target, "{lightblue}[TSX-RP]{default} Quelqu'un vous a volé: %s.", tmp);
					
		LogToGame("[TSX-RP] [VOL] %L a vole %L 1 %s", client, target, tmp);
		
		GetClientAuthId(client, AuthId_Engine, tmp, sizeof(tmp), false);
		Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_sell` (`id`, `steamid`, `job_id`, `timestamp`, `item_type`, `item_id`, `item_name`, `amount`) VALUES (NULL, '%s', '%i', '%i', '2', '%i', '%s', '%i');",
			tmp, rp_GetClientJobID(client), GetTime(), i, "Vol: Objet", amount);

		SQL_TQuery( rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		
		int alpha[4];
		alpha[1] = 255;
		alpha[3] = 50;
		
		if( rp_IsNight() ) {
			cooldown *= 1.5;
			alpha[3] = 25;
		}
		else {
			cooldown *= 2.0;
		}
		
		if( amount < 50 )
			cooldown *= 0.5;
		if( amount < 5 )
			cooldown *= 0.5;
		
		float vecTarget[3];
		GetClientAbsOrigin(client, vecTarget);

		ServerCommand("sm_effect_particles %d Aura2 3", client);
		
		//g_iSuccess_last_pas_vu_pas_pris[target] = GetTime();

		int cpt = rp_GetRandomCapital(91);
		rp_SetJobCapital(91, rp_GetJobCapital(91) + prix);
		rp_SetJobCapital(cpt, rp_GetJobCapital(cpt) - prix);
		
	}
	else if( VOL_MAX > 0 && money >= 1 ) {
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
		
		ServerCommand("sm_effect_particles %d Aura2 2", client);
		
		int cpt = rp_GetRandomCapital(91);
		rp_SetJobCapital(91, rp_GetJobCapital(91) + (amount/4));
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
	
	if( rp_GetClientJobID(client) == 91 && rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) == 91 ) {
		
		int itemID = ITEM_KITCROCHTAGE;
		int mnt = rp_GetClientItem(client, itemID);
		int max = GetMaxKit(client, itemID);
		if( mnt <  max ) {
			rp_ClientGiveItem(client, itemID, max - mnt);
			rp_GetItemData(itemID, item_type_name, tmp, sizeof(tmp));
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez récupéré %i %s.", max - mnt, tmp);
			
			FakeClientCommand(client, "say /item");
		}
		
		itemID = ITEM_KITEXPLOSIF;
		mnt = rp_GetClientItem(client, itemID);
		max = GetMaxKit(client, itemID);
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
// ----------------------------------------------------------------------------
public Action Cmd_ItemDoorDefine(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemDoorDefine");
	#endif
	char Arg1[12];	GetCmdArg(1, Arg1, 11);	
	int client = GetCmdArgInt(2);
	int item_id = GetCmdArgInt(args);
	
	int door = rp_GetClientTarget(client);
	if( !rp_IsValidDoor(door) && IsValidEdict(door) && rp_IsValidDoor(Entity_GetParent(door)) )
		door = Entity_GetParent(door);
	
	if( !rp_IsValidDoor(door) || !rp_IsEntitiesNear(client, door) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser une porte.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	int doorID = rp_GetDoorID(door);
	if( StrEqual(Arg1, "locker") ) {
		if(g_iDoorDefine_LOCKER[doorID] != 0){
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Un cadenas est déja présent sur cette porte.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		g_iDoorDefine_LOCKER[doorID] = client;
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le cadenas a été placé avec succès.");
	}
	else if( StrEqual(Arg1, "alarm") ) {
		if(g_iDoorDefine_ALARM[doorID] != 0){
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Une alarme est déja présente sur cette porte.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		g_iDoorDefine_ALARM[doorID] = client;
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} L'alarme a été installée.");
	}
	
	return Plugin_Handled;
}
public Action Cmd_ItemPiedBiche(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPiedBiche");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( rp_GetClientJobID(client) != 91 ) {
		return Plugin_Continue;
	}
	
	if( rp_GetClientVehiclePassager(client) > 0 || Client_GetVehicle(client) > 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible d'utiliser cet item dans une voiture.");
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	if( rp_GetClientBool(client, b_MaySteal) == false ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas voler pour le moment.");
		return Plugin_Handled;
	}
		
	int target = rp_GetClientTarget(client);
	
	if( target <= MaxClients ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser un distributeur de billet.");
		return Plugin_Handled;
	}
	
	char classname[128];
	GetEdictClassname(target, classname, sizeof(classname));
	if( StrContains(classname, "rp_bank__") == 0 ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser un distributeur de billet.");
		return Plugin_Handled;
	}
	
	if( StrContains(classname, "rp_weaponbox_") != 0 && StrContains(classname, "rp_bank_") != 0 ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser un distributeur de billet.");
		return Plugin_Handled;
	}
	
	
	if( rp_IsEntitiesNear(client, target, true) == false ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser un distributeur de billet.");
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
		
	ServerCommand("sm_effect_panel %d 15.0 \"Crochetage du distributeur...\"", client);
	
	if( StrContains(classname, "rp_bank_") == 0 ) {
		CreateTimer(2.5, timerAlarm, target); 
		CreateTimer(7.5, timerAlarm, target); 
		CreateTimer(12.5, timerAlarm, target); 
	}
	
	
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
	
	if( rp_IsEntitiesNear(client, target, true) == false || !IsPlayerAlive(client) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser un distributeur de billet.");
		CreateTimer(0.5, AllowStealing, client);
		return Plugin_Handled;
	}
	
	
	float vecOrigin[3];
	GetClientEyePosition(client, vecOrigin);
	vecOrigin[2] += 25.0;
	
	
	char classname[128];
	GetEdictClassname(target, classname, sizeof(classname));
	if( StrContains(classname, "rp_weaponbox_") == 0 ) {
		rp_ClientDrawWeaponMenu(client, target, true);
		CreateTimer(STEAL_TIME*0.5, AllowStealing, client);
		return Plugin_Handled;
	}
	int rand = 4 + Math_GetRandomPow(0, 4), count = 0, job, rnd;
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
	rp_SetClientStat(client, i_JobSucess, rp_GetClientStat(client, i_JobSucess) + 1);
	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) - 1);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} %d billets ont été sorti du distributeur.", rand);
	int amount = 0;
	while(rand >= 1 ) {
		rand--;
		
		rnd = Math_GetRandomInt(2, 5) * 10;
		job = rp_GetRandomCapital(91);
		
		rp_Effect_SpawnMoney(vecOrigin, true);
		amount += rnd;
		rp_SetJobCapital(job, rp_GetJobCapital(job) - rnd);
	}
	rp_SetJobCapital(91, rp_GetJobCapital(91) + amount);
	rp_SetClientInt(client, i_LastVolTime, GetTime());
	rp_SetClientInt(client, i_LastVolAmount, amount);
	rp_SetClientInt(client, i_LastVolTarget, -1);
	
	float time;
	
	if( rp_IsNight() )
		time = (STEAL_TIME * 1.0);
	else
		time = (STEAL_TIME * 2.0);
	
	CreateTimer(time, AllowStealing, client);
	
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPickLock(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPickLock");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	bool fast = false; char arg[64];
	GetCmdArg(0, arg, sizeof(arg));
	if( StrEqual(arg, "rp_item_picklock2") )
		fast = true;
	
	rp_ClientReveal(client);
	
	if( rp_GetClientJobID(client) != 91 ) {
		return Plugin_Continue;
	}
	
	int door = GetClientAimTarget(client, false);
	
	if( !rp_IsValidDoor(door) && IsValidEdict(door) && rp_IsValidDoor(Entity_GetParent(door)) )
		door = Entity_GetParent(door);
		

		
	if( !rp_IsValidDoor(door) || !rp_IsEntitiesNear(client, door, true) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez viser une porte.");
		return Plugin_Handled;
	}
		
	float vecTarget[3];
	GetClientAbsOrigin(client, vecTarget);
	TE_SetupBeamRingPoint(vecTarget, 10.0, 500.0, g_cBeam, g_cGlow, 0, 15, 0.5, 50.0, 0.0, {255, 0, 0, 50}, 10, 0);
	TE_SendToAll();
	
	// Anti-cheat:
	if( rp_GetClientItem(client, item_id) >= GetMaxKit(client, item_id)-1 ) {
		rp_ClientGiveItem(client, item_id, -rp_GetClientItem(client, item_id) + GetMaxKit(client, item_id) - 1);
	}
	
	
	int doorID = rp_GetDoorID(door);
	int alarm = g_iDoorDefine_ALARM[doorID];
	if( alarm ) {
		
		if( IsValidClient(alarm) ) {
			char zone[128];
			rp_GetZoneData(rp_GetPlayerZone(door), zone_type_name, zone, sizeof(zone));
			
			CPrintToChat(alarm, "{lightblue}[TSX-RP]{default} Quelqu'un crochette votre porte (%s).", zone );
			rp_Effect_BeamBox(alarm, client);
		}
		
		if( Math_GetRandomInt(1, 5) == 5 ) { // boum
			g_iDoorDefine_ALARM[doorID] = 0;
		}
		
		EmitSoundToAllAny("UI/arm_bomb.wav", door);
		CreateTimer(10.0, timerAlarm, door); 
			
	}
	
	float time = 7.5;
	
	if( fast )
		time = 1.5;
	
	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) + 1);
	rp_SetClientInt(client, i_LastVolTime, GetTime());
	rp_SetClientInt(client, i_LastVolAmount, 100);
	rp_SetClientInt(client, i_LastVolTarget, -1);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, time);
	ServerCommand("sm_effect_panel %d %f \"Tentative de crochetage de la porte...\"", client, time);
	
	rp_ClientColorize(client, { 255, 0, 0, 190} );
	rp_ClientReveal(client);
	
	Handle dp;
	CreateDataTimer(time-0.25, ItemPickLockOver_maffia, dp, TIMER_DATA_HNDL_CLOSE); 
	WritePackCell(dp, client);
	WritePackCell(dp, door);
	WritePackCell(dp, fast);
	
	return Plugin_Handled;
}
public Action ItemPickLockOver_maffia(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("ItemPickLockOver_maffia");
	#endif
	static int last_door[65] = 0;
	
	if( dp == INVALID_HANDLE ) {
		return Plugin_Handled;
	}
	
	ResetPack(dp);
	int client 	 = ReadPackCell(dp);
	int door = ReadPackCell(dp);
	int doorID = rp_GetDoorID(door);
	bool fast = ReadPackCell(dp);
	
	rp_ClientColorize(client);
	
	if( !rp_IsEntitiesNear(client, door, true) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez raté votre tentative de crochetage, vous étiez trop loin de la porte...");
		return Plugin_Handled;
	}
	
	int ratio = 0, job = rp_GetClientInt(client, i_Job);
	int alarm = g_iDoorDefine_LOCKER[doorID];
	
	switch( job ) {
		case 91: ratio = 80;
		case 92: ratio = 75;
		case 93: ratio = 70; 	// Parrain
		case 94: ratio = 65;	// Pro
		case 95: ratio = 60;	// Mafieu
		case 96: ratio = 55;	// Apprenti
		
		default: ratio = 0;
		
	}
	
	if( rp_IsInPVP(client) )
		ratio /= 2;
	if( rp_GetZoneBit( rp_GetPlayerZone(door)) & BITZONE_HAUTESECU )
		ratio /= 2;
	if( alarm )
		ratio /= 4;
		
	if( !fast || (fast && rp_IsInPVP(client)) ) {
		if( Math_GetRandomInt(0, 100) > ratio ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez raté votre tentative de crochetage.");
			return Plugin_Handled;
		}
		
		if( rp_IsInPVP(client) || alarm ) {
			rp_SetJobCapital(91, rp_GetJobCapital(91) + 250);
			int cap = rp_GetRandomCapital(91);
			rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 250);
		}
	}
	else {
		if( Math_GetRandomInt(0, 150) > (ratio*2) ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez raté votre tentative de crochetage.");
			return Plugin_Handled;
		}
	}
	
	if( alarm ) {	
		if( IsValidClient(alarm) ) {
			char zone[128];
			rp_GetZoneData(rp_GetPlayerZone(door), zone_type_name, zone, sizeof(zone));
			
			CPrintToChat(alarm, "{lightblue}[TSX-RP]{default} Quelqu'un a ouvert votre porte cadnacée (%s).", zone );
			rp_Effect_BeamBox(alarm, client);
		}
		
		if( Math_GetRandomInt(1, 5) == 5 ) { // boum
			g_iDoorDefine_LOCKER[doorID] = 0;
			
			rp_SetJobCapital(91, rp_GetJobCapital(91) + 250);
			int cap = rp_GetRandomCapital(91);
			rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 250);
		}
		
		EmitSoundToAllAny("UI/arm_bomb.wav", door);
		CreateTimer(10.0, timerAlarm, door); 
			
	}
	

	rp_SetDoorLock(doorID, false); 
	rp_ClientOpenDoor(client, doorID, true);

	if( fast ) {
		float vecOrigin[3];
		Entity_GetAbsOrigin(door, vecOrigin);
		
		TE_SetupExplosion(vecOrigin, g_cExplode, 0.5, 2, 1, 25, 25);
		TE_SendToAll();
		CreateTimer(30.0, TaskResetDoor, doorID);
	}

	rp_SetClientStat(client, i_JobSucess, rp_GetClientStat(client, i_JobSucess) + 1);
	rp_SetClientStat(client, i_JobFails, rp_GetClientStat(client, i_JobFails) - 1);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} La porte a été ouverte.");
	
	// TODO:
	//g_iSuccess_last_mafia[client][0] = GetTime();
	
	int zone = rp_GetZoneInt(rp_GetPlayerZone(door), zone_type_type);
	if( zone == 1 || zone == -1 || Math_GetRandomInt(1, 4) == 4 || last_door[client] != doorID ) {
		
		rp_SetJobCapital(91, rp_GetJobCapital(91) + 250);
		int cap = rp_GetRandomCapital(91);
		rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 250);
		
		last_door[client] = doorID;
	}
	
	return Plugin_Continue;
}
public Action TaskResetDoor(Handle timer, any doorID) {
	#if defined DEBUG
	PrintToServer("TaskResetDoor");
	#endif
	
	
	rp_ClientOpenDoor(0, doorID, false);
	rp_SetDoorLock(doorID, true); 
}
// ----------------------------------------------------------------------------
public Action timerAlarm(Handle timer, any door) {
	#if defined DEBUG
	PrintToServer("timerAlarm");
	#endif
	
	EmitSoundToAllAny("UI/arm_bomb.wav", door, _, _, _, 0.5);
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
	#if defined DEBUG
	PrintToServer("GetMaxKit");
	#endif
	int max, job = rp_GetClientInt(client, i_Job);
	
	switch( job ) {
		case 91:	max = 7;
		case 92:	max = 6;
		case 93:	max = 5; // parrain
		case 94:	max = 5; // pro
		case 95:	max = 5; // mafieux
		case 96:	max = 5; // apprenti
		default:	max = 0;
	}
	
	if( itemID == ITEM_PIEDBICHE )
		max = 1;
	if( itemID == ITEM_KITEXPLOSIF )
		max = RoundToCeil(max / 3.0);
	
	return max;
}
