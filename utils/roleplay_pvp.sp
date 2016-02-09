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
#include <smlib>
#include <colors_csgo>
#include <basecomm>

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

// TODO: Refactoring
// TODO: Activer les hooks uniquement si capture est activé.
// TODO: Timer pour "CaptureCalculation"... 
// TODO: Corrigé le printHUD
// TODO: Ajouté la précision de tire. En gérant le cas des mecs qui se déconnecte.
// TODO: Gérer les groupes défenseurs et attaquant
// TODO: Corrigé big-mac
// TODO: Respawn les défenseurs dans la tour
// TODO: 50 points de base par membre connecté
// TODO: A check +250 points par drapeau
// TODO: Système ELO pour gagner des points en tuant un joueur.
// TODO: La défense ne peut pas déposer de drapeau
// TODO: Un attaquant passe défenseur s'il a 100 points de plus que le défenseur actuel.
// TODO: Gagnant = celui qui a le plus de point.
// TODO: Dégat divisé par 2 entre chaque gang attaquant
// TODO: Dégat divisé par 2 entre quelqu'un du même gang

//#define DEBUG
#define MAX_GROUPS		150
#define MAX_ZONES		310
#define	MAX_ENTITIES	2048
#define	ZONE_BUNKER		235
#define	FLAG_SPEED		250.0

int g_iClientFlag[65];
int g_iFlagClient[MAX_ENTITIES+1];
enum flag_data {
	data_group,
	data_skin,
	data_red,
	data_green,
	data_blue,
	data_time,
	flag_data_max
}
int g_iFlagData[MAX_ENTITIES+1][flag_data_max];
float g_fLastDrop[65];

Handle g_hCapturable = INVALID_HANDLE;

int g_iCapture_POINT[MAX_GROUPS][capture_max];
int g_iDisableItem[MAX_ITEMS];
bool g_bIsInCaptureMode = false;
int g_cBeam;

public Plugin myinfo = {
	name = "Utils: PvP", author = "KoSSoLaX",
	description = "RolePlay - Utils: PvP",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

public void OnPluginStart() {
	RegConsoleCmd("drop", FlagDrop);
	RegServerCmd("rp_item_spawnflag", 	Cmd_ItemFlag,			"RP-ITEM",	FCVAR_UNREGISTERED);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnConfigsExecuted() {
	g_hCapturable = FindConVar("rp_capture");
	HookConVarChange(g_hCapturable, OnCvarChange);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}
public void OnCvarChange(Handle cvar, const char[] oldVal, const char[] newVal) {
	#if defined DEBUG
	PrintToServer("OnCvarChange");
	#endif
	int winner = 0;
	int maxPoint = 0;
	char optionsBuff[4][32], tmp[256];
	
	if( cvar == g_hCapturable ) {
		if( StrEqual(oldVal, "none") && StrEqual(newVal, "active") ) {

			CPrintToChatAll("{lightblue} ================================== {default}");
			CPrintToChatAll("{lightblue} Le bunker peut maintenant être capturé! {default}");
			CPrintToChatAll("{lightblue} ================================== {default}");
			
			g_bIsInCaptureMode = true;
			
			for(int i=1; i<MAX_GROUPS; i++) {
				g_iCapture_POINT[i][cap_bunker] = 0;			
			}

			for(int i=1; i<=MaxClients; i++) {
				if( !IsValidClient(i) || !rp_IsInPVP(i) )
					continue;
				
				int v = Client_GetVehicle(i);
				if( v > 0 )
					rp_ClientVehicleExit(i, v, true);
				
				rp_ClientDamage(i, 10000, 1);
				if( g_iClientFlag[i] > 0 ) {
					AcceptEntityInput(g_iClientFlag[i], "KillHierarchy");
					g_iClientFlag[i] = 0;
				}
				
				ClientCommand(i, "play *tsx/roleplay/bombing.mp3");
			}
			
			for(int i=1; i<MAX_ZONES; i++) {
				if( rp_GetZoneBit(i) & BITZONE_PVP ) {
					ServerCommand("rp_force_clean %d full", i);
				}
			}
		}
		else if( StrEqual(oldVal, "active") && StrEqual(newVal, "none") ) {

			CPrintToChatAll("{lightblue} ================================== {default}");
			CPrintToChatAll("{lightblue} Le bunker ne peut plus être capturés. {default}");
			CPrintToChatAll("{lightblue} ================================== {default}");
			
			g_bIsInCaptureMode = false;
			
			for(int i=1; i<MAX_GROUPS; i++) {
				if( rp_GetGroupInt(i, group_type_chef)!= 1 )
					continue;

				if( maxPoint > g_iCapture_POINT[i][cap_bunker] )
					continue;

				winner = i;
				maxPoint = g_iCapture_POINT[i][cap_bunker];
			}
			
			rp_GetGroupData(winner, group_type_name, tmp, sizeof(tmp));
			ExplodeString(tmp, " - ", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
			
			char fmt[1024];
			Format(fmt, sizeof(fmt), "UPDATE `rp_servers` SET `bunkerCap`='%i';';", winner);
			SQL_TQuery( rp_GetDatabase(), SQL_QueryCallBack, fmt);
			rp_SetCaptureInt(cap_bunker, winner);
			
			CPrintToChatAll("{lightblue} Le bunker appartient maintenant à... %s !", optionsBuff[1]);			
			CPrintToChatAll("{lightblue} ================================== {default}");

			GiveCashBack();
		}
	}
}
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerDead, fwdDead);
	rp_HookEvent(client, RP_OnPlayerHUD, fwdHUD);
}

void GiveCashBack() {
	#if defined DEBUG
	PrintToServer("GiveCashBack");
	#endif
	int amount;
	char tmp[128];
	
	for (int i = 0; i < MAX_ITEMS; i++) {
		g_iDisableItem[i] = 0;
	}

	for(int client=1; client<=GetMaxClients(); client++) {
		if( !IsValidClient(client) || rp_GetClientGroupID(client) == 0 )
			continue;
		
		if( rp_GetClientGroupID(client) == rp_GetCaptureInt(cap_bunker) ) {
			amount = 10;
			rp_IncrementSuccess(client, success_list_pvpkill, 100);
		}
		else {
			amount = 1;
		}

		int gID = rp_GetClientGroupID(client);
		int bonus = RoundToCeil(g_iCapture_POINT[gID][cap_bunker] / 200.0);
		
		rp_ClientGiveItem(client, 309, amount + 3 + bonus, true);
		rp_GetItemData(309, item_type_name, tmp, sizeof(tmp));
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu %d %s, en récompense de la capture.", amount+3+bonus, tmp);
	}	
}

public Action Cmd_ItemFlag(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemFlag");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int gID = rp_GetClientGroupID(client);
	
	if( !IsPlayerAlive(client)) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous êtes mort.");
		return;
	}	
	if( gID == 0 ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous n'avez pas de groupe.");
		return;
	}
	if( rp_IsInPVP(client) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous devez être hors de la PvP.");
		return;
	}
	
	if( g_iClientFlag[client] > 0 && IsValidEdict(g_iClientFlag[client]) && IsValidEntity(g_iClientFlag[client]) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez déjà un drapeau.");
		return;
	}
	
	char classname[64];
	int count = 0;
	
	for(int i=1; i<MAX_ENTITIES; i++) {
		if( !IsValidEdict(i) )
			continue;
		if( !IsValidEntity(i) )
			continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		if( !StrEqual(classname, "ctf_flag") )
			continue;
		
		
		if( g_iFlagData[i][data_group] == gID ) {
			count++;
			
			if( count >= 2 ) {
				
				if( gID == rp_GetClientInt(client, i_Group) ) {
					if( IsValidClient(g_iFlagClient[i]) ) {
						g_iClientFlag[g_iFlagClient[i]] = 0;
					}
					
					AcceptEntityInput(i, "KillHierarchy");
				}
				else {
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il y a déjà 2 drapeaux pour votre équipe sur le terrain.");
					ITEM_CANCEL(client, item_id);
					return;
				}
			}
		}
	}
	
	float vecOrigin[3];
	GetClientAbsOrigin(client, vecOrigin); vecOrigin[2] += 10.0;
	
	int color[3];
	char strBuffer[4][8];
	rp_GetGroupData(gID, group_type_color, classname, sizeof(classname));
	ExplodeString(classname, ",", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));
	color[0] = StringToInt(strBuffer[0]);
	color[1] = StringToInt(strBuffer[1]);
	color[2] = StringToInt(strBuffer[2]);
	
	int flag = CTF_SpawnFlag(vecOrigin, Math_GetRandomInt(0, 1), color);
	g_iFlagData[flag][data_group] = gID;
}

public Action FlagDrop(int client, int args) {
	if( g_iClientFlag[client] > 0 ) {
		
		CTF_DropFlag(client, true);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action FlagThink(Handle timer, any data) {
	int entity = EntRefToEntIndex(data);
	
	if( !IsValidEdict(entity) )
		return Plugin_Handled;
	
	int color[4];
	color[0] = g_iFlagData[entity][data_red];
	color[1] = g_iFlagData[entity][data_green];
	color[2] = g_iFlagData[entity][data_blue];
	color[3] = 200;
	
	if( g_bIsInCaptureMode ) {
		if( rp_GetPlayerZone(entity) == ZONE_BUNKER ) {
			
			int oldGang = rp_GetCaptureInt(cap_bunker);
			rp_SetCaptureInt(cap_bunker, g_iFlagData[entity][data_group]);
			
			for(int i=1; i<=MaxClients; i++) {
				if( !IsValidClient(i) )
					continue;
				
				int gID = rp_GetClientGroupID(i);
				if( gID == 0 )
					continue;
				
				if( gID == rp_GetCaptureInt(cap_bunker) ) {
					ClientCommand(i, "play common/stuck1");
				}
				else if( gID == oldGang ) {
					ClientCommand(i, "play common/stuck2");
				}
			}
			
			float vecOrigin[3];
			Entity_GetAbsOrigin(entity, vecOrigin);
			
			TE_SetupBeamRingPoint(vecOrigin, 1.0, 50.0, g_cBeam, g_cBeam, 0, 30, 2.0, 5.0, 1.0, color, 10, 0);
			TE_SendToAll();
			
			AcceptEntityInput(entity, "KillHierarchy");
			return Plugin_Handled;
		}
	}
	
	float vecFlag[3], vecOrigin[3], vecOrigin2[3];
	
	
	if( IsValidClient(g_iFlagClient[entity]) ) {
		return Plugin_Handled;
	}
	
	if( g_iFlagData[entity][data_time]+60 < GetTime() ) {
		int gID = g_iFlagData[entity][data_group];
		for(int i=1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( gID == rp_GetClientGroupID(i) )
				ClientCommand(i, "play common/warning");
		}
		AcceptEntityInput(entity, "KillHierarchy");
		return Plugin_Handled;
	}
	
	
	
	
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecFlag);
	vecFlag[2] += 25.0;
	
	for(int client=1; client<=MaxClients; client++) {
		if( !IsValidClient(client) )
			continue;
		if( !IsPlayerAlive(client) )
			continue;
		if( g_iClientFlag[client] > 0 && IsValidEdict(g_iClientFlag[client]) && IsValidEntity(g_iClientFlag[client]) )
			continue;		
		if( g_iFlagData[entity][data_group] != rp_GetClientGroupID(client) )
			continue;
			
		GetClientAbsOrigin(client, vecOrigin);
		GetClientEyePosition(client, vecOrigin2);
		
		TE_SetupBeamPoints(vecOrigin, vecFlag, g_cBeam, g_cBeam, 0, 30, 0.2, 1.0, 1.0, 1, 0.0, color, 10);
		TE_SendToClient(client);
		
		if( GetVectorDistance(vecOrigin, vecFlag) <= 52.0 || GetVectorDistance(vecOrigin2, vecFlag) <= 52.0 ) {
			CTF_FlagTouched(client, entity);
		}
	}
	
	CreateTimer(0.1, FlagThink, data);
	return Plugin_Handled;
}
void CTF_FlagTouched(int client, int flag) {	
	
	if( (g_fLastDrop[client]+3.0) >= GetGameTime() ) {
		return;
	}
	
	g_iFlagClient[flag] = client;
	g_iClientFlag[client] = flag;
	
	ClientCommand(client, "play common/wpn_hudoff");
	
	SetVariantString("!activator");
	AcceptEntityInput(flag, "SetParent", client);
	
	SetVariantString("grenade2");
	AcceptEntityInput(flag, "SetParentAttachment");
	
	char strBuffer[4][8], tmp[64];
	float vecOrigin[3], ang[3], pos[3];
	Entity_GetAbsOrigin(flag, vecOrigin);
	
	rp_GetGroupData(g_iFlagData[flag][data_group], group_type_color, tmp, sizeof(tmp));
	ExplodeString(tmp, ",", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));
	
	
	ang[0] = -90.0;
	ang[1] = 180.0;
	ang[2] = 90.0;
	
	
	pos[0] = 20.0;
	pos[1] = 5.0;
	pos[2] = 0.0;
	
	TeleportEntity(flag, pos, ang, NULL_VECTOR);
	ClientCommand(client, "thirdperson");
	CreateTimer(0.5, SwitchToFirst, client);
	
	SDKHook(flag, SDKHook_SetTransmit, SDKHideFlag);
	
	TE_SetupDynamicLight(vecOrigin, StringToInt(strBuffer[0]), StringToInt(strBuffer[1]), StringToInt(strBuffer[2]), 5, 200.0, 0.1, 0.1);
	TE_SendToClient(client);
}
public Action SwitchToFirst(Handle timer, any client) {
	if( rp_GetClientInt(client, i_ThirdPerson) == 0 )
		ClientCommand(client, "firstperson");
}
public Action SDKHideFlag(int from, int to ) {
	if( g_iFlagClient[from] == to && rp_GetClientInt(to, i_ThirdPerson) == 0) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
void CTF_DropFlag(int client, int thrown) {
	
	int flag = g_iClientFlag[client];
	g_iClientFlag[client] = 0;
	g_fLastDrop[client] = GetGameTime();
	
	int skin = g_iFlagData[flag][data_skin];
	int color[3];
	color[0] = g_iFlagData[flag][data_red];
	color[1] = g_iFlagData[flag][data_green];
	color[2] = g_iFlagData[flag][data_blue];
	int gID = g_iFlagData[flag][data_group];
	
	AcceptEntityInput(flag, "KillHierarchy");
	
	float vecOrigin[3], vecAngles[3], vecPush[3];
	GetClientEyeAngles(client, vecAngles);
	GetClientEyePosition(client, vecOrigin);
	vecAngles[0] += 10.0;
	
	flag = CTF_SpawnFlag(vecOrigin, skin, color);
	g_iFlagData[flag][data_group] = gID;
	
	if( thrown ) {
		
		vecOrigin[0] = (vecOrigin[0] + (60.0 * Cosine( DegToRad( vecAngles[1] ) ) ) );
		vecOrigin[1] = (vecOrigin[1] + (60.0 * Sine( DegToRad( vecAngles[1] ) ) ) );
		vecOrigin[2] = (vecOrigin[2] - 20.0);
		
		Entity_GetAbsVelocity(client, vecPush);
		
		
		vecPush[0] = vecPush[0]*0.5 + ( FLAG_SPEED * Cosine( DegToRad(vecAngles[1]) ) );
		vecPush[1] = vecPush[1]*0.5 + ( FLAG_SPEED * Sine( DegToRad(vecAngles[1]) ) );
		vecPush[2] = vecPush[2]*0.5 + ( (FLAG_SPEED/2.0) * Cosine( DegToRad( vecAngles[0] ) ) );
	}
	else {
		
		vecOrigin[2] = (vecOrigin[2] - 20.0);
		vecPush[2] = 20.0;
	}
	
	vecPush[2] += 50.0;
	TeleportEntity(flag, vecOrigin, vecAngles, vecPush);
	
}
int CTF_SpawnFlag(float vecOrigin[3], int skin, int color[3]) {
	
	char szSkin[12];
	char szColor[32];
	Format(szSkin, sizeof(szSkin), "%d", skin);
	Format(szColor, sizeof(szColor), "%d %d %d", color[0], color[1], color[2]);
	
	
	int ent1 = CreateEntityByName("hegrenade_projectile");
	if( !IsValidEdict(ent1) )
		return -1;
	int ent2 = CreateEntityByName("prop_dynamic_override");
	if( !IsValidEdict(ent2) )
		return -1;
	int ent3 = CreateEntityByName("light_dynamic");
	if( !IsValidEdict(ent3) )
		return -1;
	
	//
	DispatchKeyValue(ent1, "classname", "ctf_flag");
	//
	DispatchKeyValue(ent3, "brightness", "3");
	DispatchKeyValue(ent3, "distance", "128");
	
	DispatchKeyValue(ent2, "Skin", szSkin);
	DispatchKeyValue(ent2, "model", "models/flag/briefcase.mdl");
	DispatchKeyValue(ent3, "_light", szColor);
	
	DispatchSpawn(ent1);
	DispatchSpawn(ent2);
	DispatchSpawn(ent3);
	
	SetEntityMoveType(ent1, MOVETYPE_FLYGRAVITY);
	
	
	SetEntProp(ent1, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	SetEntProp(ent1, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);
	SetEntProp(ent2, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	SetEntProp(ent2, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID);
	
	
	SetEntPropFloat(ent1, Prop_Send, "m_flElasticity", 0.1);
	
	vecOrigin[2] += 10.0;
	TeleportEntity(ent1, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	TeleportEntity(ent3, vecOrigin, NULL_VECTOR, NULL_VECTOR);
	//
	SetVariantString("!activator");
	AcceptEntityInput(ent2, "SetParent", ent1);
	//
	SetVariantString("!activator");
	AcceptEntityInput(ent3, "SetParent", ent1);
	
	SetEntityRenderMode(ent1, RENDER_TRANSALPHA);
	SetEntityRenderMode(ent2, RENDER_TRANSALPHA);
	SetEntityRenderColor(ent1, 0, 0, 0, 0);
	SetEntityRenderColor(ent2, color[0], color[1], color[2],  255);
	
	CreateTimer(0.1, CTF_SpawnFlag_Delay, ent2);
	
	g_iFlagData[ent1][data_skin] = skin;
	g_iFlagData[ent1][data_red] = color[0];
	g_iFlagData[ent1][data_green] = color[1];
	g_iFlagData[ent1][data_blue] = color[2];
	g_iFlagData[ent1][data_time] = GetTime();
	
	g_iFlagClient[ent1] = 0;
	
	CreateTimer(0.01, FlagThink, EntIndexToEntRef(ent1));
	
	return ent1;
}

public Action CTF_SpawnFlag_Delay(Handle timer, any ent2) {
	TeleportEntity(ent2, view_as<float>({30.0, 0.0, 0.0}), view_as<float>({0.0, 90.0, 0.0}), NULL_VECTOR);
}

void captureCalculation() {
	static bool which=true;
	
	if( !isInCaptureMode() )
		return;
	#if defined DEBUG
	PrintToServer("captureCalculation");
	#endif
	
	
	g_iCapture_POINT[rp_GetCaptureInt(cap_bunker)][cap_bunker]++;
	
	
	float mins[3], maxs[3];
	int zone = g_iZoneNuke;
	int gID = g_iCapture[cap_nuclear];
	
	if( which ) {
		zone = g_iZoneTower;
		gID = g_iCapture[cap_tower];
	}
	which = !which;
	
	mins[0] = StringToFloat(g_szZoneList[zone][zone_type_min_x]);
	mins[1] = StringToFloat(g_szZoneList[zone][zone_type_min_y]);
	mins[2] = StringToFloat(g_szZoneList[zone][zone_type_min_z]);
	
	maxs[0] = StringToFloat(g_szZoneList[zone][zone_type_max_x]);
	maxs[1] = StringToFloat(g_szZoneList[zone][zone_type_max_y]);
	maxs[2] = StringToFloat(g_szZoneList[zone][zone_type_max_z]);
	
	char strBuffer[4][8];
	int color[4];
	ExplodeString(g_szGroupList[gID][group_type_color], ",", strBuffer, sizeof(strBuffer), sizeof(strBuffer[]));
	color[0] = StringToInt(strBuffer[0]);
	color[1] = StringToInt(strBuffer[1]);
	color[2] = StringToInt(strBuffer[2]);
	color[3] = 255;
	
	Effect_DrawBeamBoxToAll(mins, maxs, g_cBeam, g_cBeam, 0, 30, 2.0, 5.0, 5.0, 2, 1.0, color, 0);	
}

void TE_SetupDynamicLight(const float vecOrigin[3], int r, int g, int b, int iExponent, float fRadius, float fTime, float fDecay) {
	TE_Start("Dynamic Light");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("r",r);
	TE_WriteNum("g",g);
	TE_WriteNum("b",b);
	TE_WriteNum("exponent",iExponent);
	TE_WriteFloat("m_fRadius",fRadius);
	TE_WriteFloat("m_fTime",fTime);
	TE_WriteFloat("m_fDecay",fDecay);
}
void addGangPoint(int client, int type, int amount=1) {
	#if defined DEBUG
	PrintToServer("addGangPoint");
	#endif
	
	int group = rp_GetClientGroupID(client);
	if( group > 0 && g_bIsInCaptureMode ) {
		g_iCapture_POINT[group][type] += amount;
		if( g_iCapture_POINT[group][type] < 0 )
			g_iCapture_POINT[group][type] = 0;
	}
}
	
public Action fwdDead(int victim, int attacker, float& respawn) {
	if( g_iClientFlag[victim] > 0 ) {
		CTF_DropFlag(victim, false);
	}
	
	addGangPoint(attacker, cap_bunker, 10);
	rp_IncrementSuccess(attacker, success_list_killpvp2);
	return Plugin_Continue;
}
public Action fwdHUD(int client, char[] szHUD) {
	int size = 256;
	// TODO: Fix size...
	
	int gID = rp_GetClientGroupID(client);
	char optionsBuff[4][32], tmp[128];
	
	if( g_bIsInCaptureMode && gID > 0 ) {
		
		Format(szHUD, size, "PvP: Capture du bunker \n");
		
		
		for(int i=1; i<MAX_GROUPS; i++) {
			if(rp_GetGroupInt(i, group_type_chef) != 1 )
				continue;
				
			if( g_iCapture_POINT[i][cap_bunker] == 0 && gID != i )
				continue;
			
			rp_GetGroupData(i, group_type_name, tmp, sizeof(tmp));
			ExplodeString(tmp, " - ", optionsBuff, sizeof(optionsBuff), sizeof(optionsBuff[]));
				
			if( gID == i )
				Format(szHUD, size, "%s [%s]: %d\n", szHUD, optionsBuff[1], g_iCapture_POINT[i][cap_bunker]);
			else
				Format(szHUD, size, "%s %s: %d\n", szHUD, optionsBuff[1], g_iCapture_POINT[i][cap_bunker]);
				
		}
		
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
