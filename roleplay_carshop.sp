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

#define __LAST_REV__ 		"v:0.1.1"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MENU_TIME_DURATION 	30
#define CONTACT_DIST		500

public Plugin myinfo = {
	name = "Jobs: CARSHOP", author = "KoSSoLaX",
	description = "RolePlay - Jobs: CarShop",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

Handle g_hMAX_CAR;
int g_cExplode, g_cBeam;
int g_iBlockedTime[65][65];

// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_vehicle", 	Cmd_ItemVehicle,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_vehicle2", 	Cmd_ItemVehicle,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_carstuff", 	Cmd_ItemVehicleStuff,	"RP-ITEM",	FCVAR_UNREGISTERED);
	g_hMAX_CAR = CreateConVar("rp_max_car",	"20", "Nombre de voiture maximum sur le serveur", 0, true, 0.0, true, 50.0);
	
	// Reload:
	for (int i = 1; i <= MaxClients; i++) {
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
	}
}
public void OnMapStart() {
	g_cExplode = PrecacheModel("materials/sprites/muzzleflash4.vmt");
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerUse, fwdUse);
	for (int i = 1; i < 65; i++)
		g_iBlockedTime[client][i] = 0;
}
public void OnClientDisconnect(int client) {
	rp_UnhookEvent(client, RP_OnPlayerUse, fwdUse);
	for (int i = MaxClients; i <= 2048; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		if( rp_GetVehicleInt(i, car_owner) == client) {
			VehicleRemove(i);
			
		}
	}
}
public Action fwdUse(int client) {
	
	
	int target = GetClientTarget(client);
	int vehicle = GetEntPropEnt(client, Prop_Send, "m_hVehicle");
	int passager = rp_GetClientVehiclePassager(client);
	
	//
	if( vehicle > 0 ) {
		int speed = GetEntProp(vehicle, Prop_Data, "m_nSpeed");
		int buttons = GetClientButtons(client);
			
		if( speed <= 20 && !(buttons & IN_DUCK) )
			rp_ClientVehicleExit(client, vehicle);
	}
	else if( passager > 0 ) {
		rp_ClientVehiclePassagerExit(client, passager);
	}
	else if( rp_IsValidVehicle(target) && rp_IsEntitiesNear(client, target, true) ) {
		
		int driver = GetEntPropEnt(target, Prop_Send, "m_hPlayer");
		if( driver > 0 ) {
			
			if( rp_GetVehicleInt(target, car_owner) == client && driver != client ) {
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous pouvez éjecter le conducteur avec la commande /out");
			}
			AskToJoinCar(client, target);			
		}
		else {
			rp_SetClientVehicle(client, target, true);
		}
	}
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
	int max = 2;
	
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
	if( StrContains(arg1, "hummer") != -1 )
		max = 4;
	if( StrContains(arg1, "crownvic") != -1 )
		max = 4;
	
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
	rp_SetVehicleInt(car, car_maxPassager, max);
	rp_SetClientKeyVehicle(client, car, true);
	
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
public Action Cmd_ItemVehicleStuff(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemVehicleStuff");
	#endif
	static int offset = -1;	
	
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
	
	if( StrEqual(arg1, "key") ) {
		
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
			if( rp_GetClientVehiclePassager(i) != target )
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
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
int rp_CreateVehicle(float origin[3], float angle[3], char[] model, int skin, int client=0) {
	// Thanks blodia: https://forums.alliedmods.net/showthread.php?p=1268368#post1268368
	LogToGame("[PRE] Vehicle Spawning from %N", client);
	
	int ent = CreateEntityByName("prop_vehicle_driveable");
	if( ent == -1) { return 0; } // Tout le monde sait que ça n'arrive jamais...
	
	char ScriptPath[PLATFORM_MAX_PATH], szSkin[12], buffer[8][64];
	bool valid = false;
	int amount = ExplodeString(model, "/", buffer, sizeof(buffer), sizeof(buffer[]));
	if( amount > 0 ) {
		ReplaceString(buffer[amount-1], sizeof(buffer[]), ".mdl", "");
		Format(ScriptPath, sizeof(ScriptPath), "scripts/vehicles/%s.txt", buffer[amount-1]);
		
		if( FileExists(ScriptPath) )
			valid = true;
	}
	if( !valid )
		Format(ScriptPath, sizeof(ScriptPath), "scripts/vehicles/jeep.txt");
	
	DispatchKeyValue(ent, "model", 				model);
	DispatchKeyValue(ent, "vehiclescript", 		ScriptPath);
	DispatchKeyValue(ent, "solid",				"6");
	DispatchKeyValue(ent, "actionScale",		"1");
	DispatchKeyValue(ent, "EnableGun",			"0");
	DispatchKeyValue(ent, "ignorenormals",		"0");
	DispatchKeyValue(ent, "fadescale",			"1");
	DispatchKeyValue(ent, "fademindist",		"-1");
	DispatchKeyValue(ent, "VehicleLocked",		"0");
	DispatchKeyValue(ent, "screenspacefade",	"0");
	DispatchKeyValue(ent, "spawnflags", 		"256" );
	DispatchKeyValue(ent, "setbodygroup", 		"511" );
	DispatchKeyValueFloat(ent, "MaxPitch", 		360.00);
	DispatchKeyValueFloat(ent, "MinPitch", 		-360.00);
	DispatchKeyValueFloat(ent, "MaxYaw", 		90.00);
	
	IntToString(skin, szSkin, sizeof(szSkin));
	DispatchKeyValue(ent, "skin", szSkin);
	DispatchSpawn(ent);
	
	// check if theres space to spawn the vehicle.
	float MinHull[3],  MaxHull[3];
	GetEntPropVector(ent, Prop_Send, "m_vecMins", MinHull);
	GetEntPropVector(ent, Prop_Send, "m_vecMaxs", MaxHull);
	
	Handle trace;
	if( client == 0 )
		trace = TR_TraceHullEx(origin, origin, MinHull, MaxHull, MASK_SOLID);
	else
		trace = TR_TraceHullFilterEx(origin, origin, MinHull, MaxHull, MASK_SOLID, FilterToOne, client);
	
	if( TR_DidHit(trace) ) { delete trace; AcceptEntityInput(ent, "Kill");	return 0; }
	delete trace;
	
	TeleportEntity(ent, origin, angle, NULL_VECTOR);
	int left, right, cam;
	rp_CreateVehicleLighting(ent, left, right);
	cam = rp_CreateVehicleCamera(ent);
	
	rp_SetVehicleInt(ent, car_light_left_id, left);
	rp_SetVehicleInt(ent, car_light_right_id, right);
	rp_SetVehicleInt(ent, car_light_is_on, 0);
	rp_SetVehicleInt(ent, car_thirdperson_id, cam);
	rp_SetVehicleInt(ent, car_health, 1000);
	rp_SetVehicleInt(ent, car_klaxon, Math_GetRandomInt(1, 6));
	
	SetEntProp(ent, Prop_Data, "m_takedamage", DAMAGE_NO); // Nope
	SetEntProp(ent, Prop_Data, "m_nNextThinkTick", -1);
	SetEntProp(ent, Prop_Data, "m_bHasGun", 0);
	
//	AcceptEntityInput(ent, "HandBrakeOn");
	AcceptEntityInput(ent, "TurnOff");
	
	if( IsValidClient(client) ) {
		
		rp_SetVehicleInt(ent, car_owner, client);
		rp_SetClientKeyVehicle(client, ent, true);
	
		rp_SetClientVehicle(client, ent, true);
		 // PLEASE CHECK AGAIN SERVER WAS SLOW OK?
		Handle dp;
		CreateDataTimer(0.1, rp_SetClientVehicleTask, dp, TIMER_DATA_HNDL_CLOSE);
		WritePackCell(dp, client);
		WritePackCell(dp, ent);
	}
	
	LogToGame("[POST] Vehicle Spawning from %N", client);
	return ent;
}
void rp_CreateVehicleLighting(int vehicle, int& left, int& right) {
	
	float origin[3], angles[3], MaxHull[3];
	Entity_GetAbsOrigin(vehicle, origin);
	Entity_GetAbsAngles(vehicle, angles);
	Entity_GetMaxSize(vehicle, MaxHull);
	
	angles[1] += 90.0;
	
	float x = 25.0, y = MaxHull[1], z = 30.0, radian = DegToRad(angles[1]);
	float LightOrigin[3];
	
	LightOrigin[0] = origin[0] + (x*Sine(radian)) + (y*Cosine(radian));
	LightOrigin[1] = origin[1] - (x*Cosine(radian)) + (y*Sine(radian));
	LightOrigin[2] = origin[2] + z;
	angles[0] += 15.0;
	
	// TODO: Check failed
	left = CreateEntityByName("point_spotlight");
	ActivateEntity(left);
	
	DispatchKeyValue(left, "spotlightlength",	"500");
	DispatchKeyValue(left, "spotlightwidth",		"200");
	DispatchKeyValue(left, "rendercolor",		"255 255 255 5000");
	DispatchKeyValue(left, "spawnflags", 		"0");
	DispatchSpawn(left);
	
	TeleportEntity(left, LightOrigin, angles, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(left, "SetParent", vehicle);
	AcceptEntityInput(left, "LightOff");
	
	x = -25.0;
	LightOrigin[0] = origin[0] + (x*Sine(radian)) + (y*Cosine(radian));
	LightOrigin[1] = origin[1] - (x*Cosine(radian)) + (y*Sine(radian));
	LightOrigin[2] = origin[2] + z;
	
	// TODO: Check failed
	right = CreateEntityByName("point_spotlight");
	ActivateEntity( right);
	
	DispatchKeyValue( right, "spotlightlength",	"500");
	DispatchKeyValue( right, "spotlightwidth",	"200");
	DispatchKeyValue( right, "rendercolor",		"255 255 255 5000");
	DispatchKeyValue( right, "spawnflags",		"0");	
	DispatchSpawn( right);
	TeleportEntity( right, LightOrigin, angles, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(right, "SetParent", vehicle);
	AcceptEntityInput(right, "LightOff");	
}
int rp_CreateVehicleCamera(int vehicle) {
	
	float origin[3], angles[3];
	Entity_GetAbsOrigin(vehicle, origin);
	Entity_GetAbsAngles(vehicle, angles);
	angles[1] += 90.0;
	
	float x = 0.0, y = -200.0, z = 120.0 , radian = DegToRad(angles[1]);
	origin[0] += (x*Sine(radian)) + (y*Cosine(radian));
	origin[1] += (x*Cosine(radian)) + (y*Sine(radian));
	origin[2] += z;
	angles[0] -= 10.0;
	
	int ent = CreateEntityByName("env_fire");
	
	DispatchSpawn(ent);
	ActivateEntity(ent);
	
	TeleportEntity(ent, origin, angles, NULL_VECTOR);
	
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", vehicle);
	return ent;
}
void VehicleRemove(int vehicle, bool explode = false) {
	#if defined DEBUG
	PrintToServer("VehicleRemove");
	#endif
	CreateTimer(0.1, BatchLeave, vehicle);
	
	for(int i=1; i<=MaxClients+1; i++)
		rp_SetClientKeyVehicle(i, vehicle, false);
	
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
// ----------------------------------------------------------------------------
public Action rp_SetClientVehicleTask(Handle timer, Handle dp) {
	#if defined DEBUG
	PrintToServer("rp_SetClientVehicleTask");
	#endif
	
	ResetPack(dp);
	int client = ReadPackCell(dp);
	int car = ReadPackCell(dp);
	rp_SetClientVehicle(client, car, true);
}
public Action BatchLeave(Handle timer, any vehicle) {
	#if defined DEBUG
	PrintToServer("BatchLeave");
	#endif
	int client = GetEntPropEnt(vehicle, Prop_Send, "m_hPlayer");
	
	if( IsValidClient(client) ) {
		rp_ClientVehicleExit(client, vehicle, true);
		
		
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			rp_ClientVehicleExit(client, vehicle, true);
		}
	}
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
			
			if( rp_GetClientVehiclePassager(client) == ent ) {
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

// ----------------------------------------------------------------------------
void AskToJoinCar(int client, int vehicle) {
	#if defined DEBUG
	PrintToServer("AskToJoinCar");
	#endif
	
	if( rp_GetVehicleInt(vehicle, car_maxPassager) <= CountPassagerInVehicle(vehicle) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il n'y a plus de place dans cette voiture.");
		return;
	}
	
	int driver = GetEntPropEnt(vehicle, Prop_Send, "m_hPlayer");
	if( g_iBlockedTime[driver][client] != 0 ) {
		if( (g_iBlockedTime[driver][client]+(6*60)) >= GetTime() ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ce conducteur ne vous repondera pas.");
			return;
		}
	}
	char tmp[255];	
	Handle menu = CreateMenu(AskToJoinCar_Menu);
	
	Format(tmp, sizeof(tmp), "%N souhaite entrer dans votre voiture.\n L'acceptez-vous?", client);
	SetMenuTitle(menu, tmp);
	
	Format(tmp, sizeof(tmp), "%i_%i_1", client, vehicle);	AddMenuItem(menu, tmp, "J'accepte");
	Format(tmp, sizeof(tmp), "%i_%i_2", client, vehicle);	AddMenuItem(menu, tmp, "Je refuse");
	AddMenuItem(menu, "vide", "-----------------", ITEMDRAW_DISABLED);
	Format(tmp, sizeof(tmp), "%i_%i_3", client, vehicle);	AddMenuItem(menu, tmp, "Ignorer ce joueur");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, driver, MENU_TIME_DURATION);
}
public int AskToJoinCar_Menu(Handle p_hItemMenu, MenuAction p_oAction, int client, int p_iParam2) {
	#if defined DEBUG
	PrintToServer("AskToJoinCar_Menu");
	#endif
	if (p_oAction == MenuAction_Select) {
		char szMenuItem[32];
		
		if (GetMenuItem(p_hItemMenu, p_iParam2, szMenuItem, sizeof(szMenuItem))) {
			
			char data[3][32];
			ExplodeString(szMenuItem, "_", data, sizeof(data), sizeof(data[]));
			
			int request = StringToInt(data[0]);
			int vehicle = StringToInt(data[1]);
			int type = StringToInt(data[2]);
			
			if( type == 1 ) {
				if( rp_GetVehicleInt(vehicle, car_maxPassager) <= CountPassagerInVehicle(vehicle) ) {
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il n'y a plus de place dans cette voiture.");
					CPrintToChat(request, "{lightblue}[TSX-RP]{default} Il n'y a plus de place dans cette voiture.");
					
					return;
				}
				if( !IsPlayerAlive(request) ) {
					CPrintToChat(request, "{lightblue}[TSX-RP]{default} Vous êtes mort.");
					return;
				}
				if( Vehicle_GetDriver(vehicle) != client  ) {
					CPrintToChat(request, "{lightblue}[TSX-RP]{default} Le conducteur n'est plus dans sa voiture.");
					return;
				}
				
				if( Entity_GetDistance(request, vehicle) >= (CONTACT_DIST) ) {
					CPrintToChat(request, "{lightblue}[TSX-RP]{default} La voiture est trop éloignée.");
					return;
				}
				
				rp_SetClientVehiclePassager(request, vehicle);
				ClientCommand(request, "firstperson");
			}
			else if( type == 2 ) {
				CPrintToChat(request, "{lightblue}[TSX-RP]{default} Le conducteur a refusé votre demande.");
				return;
			}
			else if( type == 3 ) {
				g_iBlockedTime[client][request] = GetTime();
				CPrintToChat(request, "{lightblue}[TSX-RP]{default} Le conducteur a refusé, et vous ignorera.");
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ignorerez les demandes de %N pour 6 heures", request);
				return;
			}
		}
	}
	else if (p_oAction == MenuAction_End) {
		CloseHandle(p_hItemMenu);
	}
}

int CountPassagerInVehicle(int vehicle) {
	int cpt = 0;
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if ( rp_GetClientVehiclePassager(i) == vehicle )
			cpt++;
	}
	return cpt;
}