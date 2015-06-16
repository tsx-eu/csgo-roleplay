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
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG

public Plugin myinfo = {
	name = "Jobs: CARSHOP", author = "KoSSoLaX",
	description = "RolePlay - Jobs: CarShop",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

Handle g_hMAX_CAR;
int g_cExplode, g_cBeam;
// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_vehicle", 	Cmd_ItemVehicle,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_vehicle2", 	Cmd_ItemVehicle,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_carstuff", 	Cmd_ItemVehicleStuff,	"RP-ITEM",	FCVAR_UNREGISTERED);
	g_hMAX_CAR = CreateConVar("rp_max_car",	"20", "Nombre de voiture maximum sur le serveur", 0, true, 0.0, true, 50.0);
}
public void OnMapStart() {
	g_cExplode = PrecacheModel("materials/sprites/muzzleflash4.vmt");
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemVehicle(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemVehicle");
	#endif
	
	char arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int skinid = GetCmdArgInt(2);
	int client = GetCmdArgInt(3);
	int item_id = GetCmdArgInt(args);
	
	if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_PEACEFULL ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit où vous êtes.");
		return;
	}
	
	if( StrContains(arg1, "crownvic_cvpi") >  0 ) {
		if( rp_GetClientJobID(client) != 1 && rp_GetClientJobID(client) != 101 ) {
			ITEM_CANCEL(client, item_id);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est réservé aux forces de l'ordre.");
			return;
		}
	}
	
	int count = 0;
	for(int i=1; i<=2048; i++) {
		if( !rp_IsValidVehicle(i) )
			continue;
		
		count++;
	}
	
	if( count >= GetConVarInt(g_hMAX_CAR) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il y a trop de voiture sur le serveur pour l'instant.");
		return;			
	}
	
	
	float vecOrigin[3], vecAngles[3];
	GetClientAbsOrigin(client, vecOrigin);
	vecOrigin[2] += 10.0;
	
	GetClientEyeAngles(client, vecAngles);
	vecAngles[0] = vecAngles[2] = 0.0;
	vecAngles[1] -= 90.0;
	
	int car = rp_CreateVehicle(vecOrigin, vecAngles, arg1, skinid, client);
	if( !car ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il n'y a pas assez de place ici.");
	}
	
	rp_SetVehicleInt(car, car_owner, client);
	rp_SetVehicleInt(car, car_item_id, item_id);
	rp_SetClientKeyVehicle(client, car, true);
	for (int i = 1; i <= MaxClients; i++) {
		if( IsValidClient(i) )
			rp_SetClientKeyVehicle(i, car, false);
	}
	
	CreateTimer(3.5, Timer_VehicleRemoveCheck, car);
	
	// Voiture donateur, on la thune wesh
	char arg0[128];
	GetCmdArg(0, arg0, sizeof(arg0));
	if( StrEqual(arg0, "rp_item_vehicle2") ) {
		ServerCommand("sm_effect_colorize %d 32 64 255 255", car);
		TE_SetupBeamFollow(car, g_cBeam, 0, 30.0, 8.0, 0.1, 250, {32, 64, 255, 255});
		TE_SendToAll();
	}
	
	return;
}
public Action Timer_VehicleRemoveCheck(Handle timer, any ent) {
	bool IsNear = false;
	
	
	if( Vehicle_HasDriver(ent) )
		IsNear = true;
	else if( rp_GetZoneBit(rp_GetPlayerZone(ent)) & BITZONE_PARKING )
		IsNear = true;
	else {
		float vecOrigin[3], vecTarget[3];
		Entity_GetAbsOrigin(ent, vecOrigin);
			
		for(int client=1; client<=MAXPLAYERS; client++) {
			if( !IsValidClient(client) )
				continue;
			
			if( rp_GetClientVehiclePassager(client, ent) ) {
				IsNear = true;
				break;
			}
			
			if( rp_GetClientKeyVehicle(client, ent) ) {
				
				Entity_GetAbsOrigin(client, vecTarget);
					
				if( GetVectorDistance(vecOrigin, vecTarget) <= 4000.0 ) {
					IsNear = true;
					break;
				}
				
				// TODO:
				/*
				int can = getZoneAppart(client);
				if( can >= 0 && g_iAppartBonus[can][appart_bonus_garage] ) {
					IsNear = true;
					break;
				}*/
			}
		}
	}
	
	if( rp_GetVehicleInt(ent, car_health) <= 0 ) {
		VehicleRemove(ent, true);
		return Plugin_Handled;
	}
		
	if( !IsNear ) {
		int tick = rp_GetVehicleInt(ent, car_awayTick) + 1;
		rp_SetVehicleInt(ent, car_awayTick, tick );
		
		if( tick > 250 ) {		
			VehicleRemove(ent);
			return Plugin_Handled;
		}
	}
	else {
		rp_SetVehicleInt(ent, car_awayTick, 0 );
	}
	
	CreateTimer(1.1, Timer_VehicleRemoveCheck, ent);
	return Plugin_Continue;
}
void VehicleRemove(int vehicle, bool explode = false) {
	#if defined DEBUG
	PrintToServer("VehicleRemove");
	#endif
	//CreateTimer(0.1, BatchLeave, vehicle);
	
	for(int i=1; i<=MaxClients+1; i++)
		rp_SetClientKeyVehicle(i, false);
	
	if( explode ) {
		IgniteEntity(vehicle, 1.75);
		// Bim, boum badaboum.
		for(float time = 0.0; time<=2.5; time+=0.75 ) {
			float vecOrigin[3];
			Entity_GetAbsOrigin(vehicle, vecOrigin);
			
			vecOrigin[0] += GetRandomFloat(-20.0, 20.0);
			vecOrigin[1] += GetRandomFloat(-20.0, 20.0);
			vecOrigin[2] += GetRandomFloat(5.0, 20.0);
			
			TE_SetupExplosion(vecOrigin, g_cExplode, GetRandomFloat(0.5, 2.0), 2, 1, Math_GetRandomInt(25, 100) , Math_GetRandomInt(25, 100) );
			TE_SendToAll(time);
		}
	}
	
	int light = rp_GetVehicleInt(vehicle, car_light_left_id);
	if( light > 0 && IsValidEdict(light) && IsValidEntity(light) ) {
		rp_ScheduleEntityInput(light, 1.0, "Kill");
		AcceptEntityInput(light, "LightOff");
		rp_SetVehicleInt(vehicle, car_light_left_id, 0);
	}
	
	light = rp_GetVehicleInt(vehicle, car_light_right_id);
	if( light > 0 && IsValidEdict(light) && IsValidEntity(light) ) {
		rp_ScheduleEntityInput(light, 1.0, "Kill");
		AcceptEntityInput(light, "LightOff");
		rp_SetVehicleInt(vehicle, car_light_left_id, 0);
	}
	
	ServerCommand("sm_effect_fading %i 2.5 1", vehicle);
	rp_ScheduleEntityInput(vehicle, 2.5, "Kill");
}
public Action Cmd_ItemVehicleStuff(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemVehicleStuff");
	#endif
	static int offset = -1;
	static int last[65];
	
	
	char arg1[12];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	int client = GetCmdArgInt(2);
	int target = GetClientAimTarget(client, false);
	int item_id = GetCmdArgInt(args);
	
	if( !rp_IsValidVehicle(target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	
	if( !rp_GetClientKeyVehicle(client, target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	if( offset == -1 ) {
		offset = GetEntSendPropOffs(target, "m_clrRender", true);
	}
	
	if( StrEqual(arg1, "repair") ) {
		
		if( Vehicle_GetDriver(target) != client) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible d'utiliser cet item dans une voiture.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		
		// TODO: Rembourser si pas de soin
		int heal = rp_GetVehicleInt(target, car_health) + 1000;
		if( heal >= 2500 ) {
			heal = 2500;
		}
		
		rp_SetVehicleInt(target, car_health, heal);
	}
	else if( StrEqual(arg1, "key") ) {
		
		if( Vehicle_GetDriver(target) != client) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez utiliser cet item dans votre voiture.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		
		if( rp_GetVehicleInt(target, car_owner) != client ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes pas le propriétaire de cette voiture.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		
		int amount=0;
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( rp_GetClientVehiclePassager(i, target) )
				continue;
			if( rp_GetClientKeyVehicle(i, target) )
				continue;
			
			amount++;
			rp_SetClientKeyVehicle(i, target, true);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N{default} a maintenant la clé de votre voiture.", i);
		}
		
		if( amount == 0 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il n'y a personne dans votre voiture à qui donner la clé.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		
		
	}
	else if( StrEqual(arg1, "gang") ) {
		
		int gID = rp_GetClientGroupID(client);
		
		if( gID == 0 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas de gang.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		if( Vehicle_GetDriver(target) != client) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez utiliser cet item dans votre voiture.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		
		if( rp_GetVehicleInt(target, car_owner) != client ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'êtes pas le propriétaire de cette voiture.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
		
		int amount=0;
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( rp_GetClientGroupID(i) != gID )
				continue;
			if( rp_GetClientKeyVehicle(i, target) )
				continue;
			
			amount++;
			rp_SetClientKeyVehicle(i, target, true);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} %N{default} a maintenant la clé de votre voiture.", i);
		}
		if( amount == 0 ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez personne a qui donner la clé.");
			ITEM_CANCEL(client, item_id);
			return Plugin_Handled;
		}
	}
	
	else {
		int color[4];
		
		for(int i=0; i<3; i++) {
			color[i] = GetEntData(target, offset+i, 1);
		}
		
		if( color[0] >= 250 && color[1] >= 250 && color[2] >= 250 && last[client] != target ) {
			rp_IncrementSuccess(client, success_list_carshop);
		}
		
		last[client] = target;
		
		if( StrEqual(arg1, "red") ) {
			color[0] += 64;
			color[1] -= 64;
			color[2] -= 64;
		}
		else if( StrEqual(arg1, "green") ) {
			color[0] -= 64;
			color[1] += 64;
			color[2] -= 64;
		}
		else if( StrEqual(arg1, "bleue") ) {
			color[0] -= 64;
			color[1] -= 64;
			color[2] += 64;
		}
		else if( StrEqual(arg1, "white") ) {
			color[0] += 64;
			color[1] += 64;
			color[2] += 64;
		}
		else if( StrEqual(arg1, "black") ) {
			color[0] -= 64;
			color[1] -= 64;
			color[2] -= 64;
		}
		
		for(int i=0; i<3; i++) {
			if( color[i] > 255 )
				color[i] = 255;
			if( color[i] < 0 )
				color[i] = 0;
		}
		
		SetEntityRenderMode(target, RENDER_TRANSCOLOR);
		SetEntityRenderColor(target, color[0], color[1], color[2], color[3]);
	}
	
	return Plugin_Handled;
	
}