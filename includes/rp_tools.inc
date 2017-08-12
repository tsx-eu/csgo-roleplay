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
#if defined _rp_tools_included_
#endinput
#endif
#define _rp_tools_included_

#include <sdkhooks>
#include <cstrike>
// ----------------------------------------------------------------------------
stock int Math_GetRandomPow(int min, int max) {
	return RoundToFloor(float(max - min) * Pow(GetURandomFloat(), 2.0)) + min;
}
stock void String_WordWrap(char[] s, int wrapline) {
	int i, k, wraploc, lastwrap;
	
	for (i = 0; s[i] != '\0'; ++i, ++wraploc) {
		if (wraploc >= wrapline) {
			for (k = i; k > 0; --k) {
				if (k - lastwrap <= wrapline && s[k] == ' ') {
					s[k] = '\n';
					lastwrap = k + 1;
					break;
				}
			}
			wraploc = i - lastwrap;
		}
	}
}
stock bool IsNaN(float a) {
	static char tmp[12];
	Format(tmp, sizeof(tmp), "%f", a);
	return StrEqual(tmp, "NaN");
}
stock void String_CleanupName(char[] name, char[] output, int length) {
	int a, b, c, d;
	
	for (int i = 0; i < length; i++)
	output[i] = 0;
	
	while (name[c] != 0 || c > length) {
		
		if ((b = GetCharBytes(name[c])) == 1) {
			a = view_as<int>(name[c]);
			if ((a >= 65 && a <= 90) || (a >= 97 && a <= 122) || a == 32 || a == 39 || a == 45) {
				Format(output, length, "%s%c", output, name[c]);
			}
		}
		else {
			char[] tmp = new char[b + 1];
			for (d = 0; d < b; d++)
			tmp[d] = name[c + d];
			
			if (StrEqual(tmp, "é") || StrEqual(tmp, "ê") || StrEqual(tmp, "è") || StrEqual(tmp, "à") || StrEqual(tmp, "ç") || StrEqual(tmp, "ù")) {
				Format(output, length, "%s%s", output, tmp);
			}
		}
		
		c += b;
	}
	
	while (ReplaceString(output, length, "  ", " ")) {  }
	
	TrimString(output);
	String_ToLower(output, output, length);
	
	a = b = c = d = 0;
	while (output[c] != 0 || c > length) {
		
		if ((b = GetCharBytes(name[c])) == 1) {
			
			if (c == 0) {
				output[c] = CharToUpper(output[c]);
			}
			else {
				a = view_as<int>(output[c - 1]);
				
				if (a == 32 || a == 39 || a == 45) {
					output[c] = CharToUpper(output[c]);
				}
			}
		}
		
		c += b;
	}
}
stock void String_NumberFormat(int value, char[] buffer, int size) {
	
	char[] helper = new char[size];
	IntToString(value, helper, size);
	strcopy(buffer, size, helper);
	
	int length = strlen(helper);
	
	int n_helper;
	
	if (helper[0] == '-') {
		n_helper += ((length - 1) % 3) + 1;
		
		if (n_helper == 1) {
			n_helper = 4;
		}
	}
	else {
		n_helper += length % 3;
		
		if (n_helper == 0) {
			n_helper = 3;
		}
	}
	
	int n_buffer = n_helper;
	
	while (n_helper < length) {
		buffer[n_buffer] = ' ';
		strcopy(buffer[n_buffer + 1], size, helper[n_helper]);
		
		n_buffer += 4;
		n_helper += 3;
	}
}
stock void String_ColorsToHTML(char[] text, int length) {
	ReplaceString(text, length, "{darkred}", "<font color='#bb0000'>");
	ReplaceString(text, length, "{red}", "<font color='#ff0000'>");
	ReplaceString(text, length, "{pink}", "<font color='#ffc0cc'>");
	ReplaceString(text, length, "{green}", "<font color='#00cc00'>");
	ReplaceString(text, length, "{lightgreen}", "<font color='#90ff90'>");
	ReplaceString(text, length, "{lime}", "<font color='#00ff00'>");
	ReplaceString(text, length, "{grey}", "<font color='#808080'>");
	ReplaceString(text, length, "{olive}", "<font color='#808000'>");
	ReplaceString(text, length, "{lightblue}", "<font color='#add8e6'>");
	ReplaceString(text, length, "{blue}", "<font color='#0000ff'>");
	ReplaceString(text, length, "{purple}", "<font color='#800080'>");
	ReplaceString(text, length, "{darkorange}", "<font color='#ff8c00'>");
	ReplaceString(text, length, "{orange}", "<font color='#ffa500'>");
	ReplaceString(text, length, "{default}", "<font color='#ffffff'>");
}
// ----------------------------------------------------------------------------
stock void PrintToChatClientArea(int client, const char[] message, any...) {
	char buffer[250];
	VFormat(buffer, sizeof(buffer), message, 3);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i))
			continue;
		if (!IsPlayerAlive(i))
			continue;
		
		if (rp_IsTargetHear(i, client)) {
			CPrintToChat(i, "{lightblue}[TSX-RP]{default} %s", buffer);
		}
	}
}
stock void PrintToChatZone(int zoneID, const char[] message, any...) {
	char buffer[MAX_MESSAGE_LENGTH];
	VFormat(buffer, sizeof(buffer), message, 3);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i))
			continue;
		if (!IsPlayerAlive(i))
			continue;
		
		if (rp_GetPlayerZone(i) == zoneID) {
			CPrintToChat(i, "{lightblue}[TSX-RP]{default} %s", buffer);
		}
	}
}
stock void PrintToChatPoliceSearch(int target, const char[] message, any...) {
	char buffer[MAX_MESSAGE_LENGTH];
	VFormat(buffer, sizeof(buffer), message, 3);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i))
			continue;
		
		if (i == target || rp_GetClientJobID(i) == 1 || rp_GetClientJobID(i) == 101) {
			CPrintToChat(i, buffer);
		}
	}
}
stock void PrintToChatPoliceJob(int target, const char[] message, any...) {
	char buffer[MAX_MESSAGE_LENGTH];
	VFormat(buffer, sizeof(buffer), message, 3);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i))
			continue;
		if (!IsPlayerAlive(i))
			continue;
		
		if (rp_GetClientJobID(i) == 1 || rp_GetClientJobID(i) == 101 || rp_GetClientJobID(i) == target) {
			CPrintToChat(i, buffer);
		}
	}
}
// ----------------------------------------------------------------------------
stock float GetCmdArgFloat(int index) {
	char arg[32];
	GetCmdArg(index, arg, sizeof(arg));
	return StringToFloat(arg);
}
stock int GetCmdArgInt(int index) {
	char arg[32];
	GetCmdArg(index, arg, sizeof(arg));
	return StringToInt(arg);
}
stock bool IsValidClient(int client) {
	if (client <= 0 || client > MaxClients)
		return false;
	
	if (!IsValidEdict(client) || !IsClientConnected(client))
		return false;
	
	return true;
}
public bool FilterToOne(int entity, int mask, any data) {
	static char classname[64];
	if (entity == data)
		return false;
	if (Entity_GetParent(entity) == data)
		return false;
	
	GetEdictClassname(entity, classname, sizeof(classname));
	if (StrEqual(classname, "notsolid"))
		return false;
	
	return true;
}
public void SQL_QueryCallBack(Handle owner, Handle handle, const char[] error, any data) {
	if (strlen(error) >= 1) {
		LogError("[SQL] [ERROR] %s - %f - %i", error, data, data);
	}
}
stock int rp_GetItemInt(int itemID, int typeID) {
	char tmp[32];
	rp_GetItemData(itemID, view_as<rp_item_type>(typeID), tmp, sizeof(tmp));
	return StringToInt(tmp);
}
stock float rp_GetItemFloat(int itemID, int typeID) {
	char tmp[32];
	rp_GetItemData(itemID, view_as<rp_item_type>(typeID), tmp, sizeof(tmp));
	return StringToFloat(tmp);
}
stock int rp_GetJobInt(int jobID, int typeID) {
	char tmp[32];
	rp_GetJobData(jobID, view_as<rp_job_type>(typeID), tmp, sizeof(tmp));
	return StringToInt(tmp);
}
stock int rp_GetGroupInt(int groupID, int typeID) {
	char tmp[32];
	rp_GetGroupData(groupID, view_as<rp_group_type>(typeID), tmp, sizeof(tmp));
	return StringToInt(tmp);
}
stock int rp_GetZoneInt(int zoneID, int typeID) {
	char tmp[32];
	rp_GetZoneData(zoneID, view_as<zone_type>(typeID), tmp, sizeof(tmp));
	return StringToInt(tmp);
}
stock float rp_GetZoneFloat(int zoneID, int typeID) {
	char tmp[32];
	rp_GetZoneData(zoneID, view_as<zone_type>(typeID), tmp, sizeof(tmp));
	return StringToFloat(tmp);
}
stock int rp_GetLocationInt(int zoneID, int typeID) {
	char tmp[32];
	rp_GetLocationData(zoneID, view_as<location_type>(typeID), tmp, sizeof(tmp));
	return StringToInt(tmp);
}
stock int rp_GetServerInt(rp_serv typeID) {
	char tmp[64];
	rp_GetServerString(typeID, tmp, sizeof(tmp));
	return StringToInt(tmp);
}

stock bool rp_IsRemoveAble(int target) {
	#if defined DEBUG
	PrintToServer("IsRemoveAble");
	#endif
	if (!IsValidEdict(target))
		return false;
	if (!IsValidEntity(target))
		return false;
	
	char classname[128];
	GetEdictClassname(target, classname, sizeof(classname));
	
	if (StrEqual(classname, "prop_dynamic")) {
		if (Entity_GetParent(target) >= 1) {
			return false;
		}
		return true;
	}
	if (StrEqual(classname, "rp_mine")) {
		return true;
	}
	if (StrContains(classname, "weapon_") == 0) {
		return true;
	}
	if (StrContains(classname, "item_") == 0) {
		return true;
	}
	if (StrEqual(classname, "rp_cashmachine")) {
		return true;
	}
	if (StrEqual(classname, "rp_bigcashmachine")) {
		return true;
	}
	if (StrEqual(classname, "rp_plant")) {
		return true;
	}
	if (StrContains(classname, "prop_physics") == 0) {
		return true;
	}
	if (StrEqual(classname, "rp_grave")) {
		return true;
	}
	
	return false;
}
stock bool rp_IsMoveAble(int ent) {
	static char classname[64];
	
	if (ent <= 0)
		return false;
	if (!IsValidEdict(ent))
		return false;
	if (!IsValidEntity(ent))
		return false;
	
	if (GetEntityMoveType(ent) == MOVETYPE_NOCLIP)
		return false;
	
	if (IsValidClient(ent)) {
		if (IsPlayerAlive(ent)) {
			return true;
		}
		else {
			return false;
		}
	}
	
	
	GetEdictClassname(ent, classname, 63);
	
	
	if (StrContains(classname, "door", false) != -1)
		return false;
	if (StrContains(classname, "player", false) == 0)
		return true;
	if (StrContains(classname, "prop_p", false) == 0)
		return true;
	if (StrContains(classname, "func_phys", false) == 0)
		return true;
	if (StrContains(classname, "weapon_", false) == 0)
		return true;
	if (StrContains(classname, "item_", false) == 0)
		return true;
	if (StrContains(classname, "chicken", false) == 0)
		return true;
	if (StrContains(classname, "bonbon_entity_2", false) == 0)
		return true;
	
	return false;
}
stock void rp_ClientSwitchWeapon(int client, int wepid, int target = -1) {
	if (target == -1)
		target = client;
	
	char wepname[64];
	int g, ammo, ammo1, index;
	enum_ball_type wep_type = rp_GetWeaponBallType(wepid);
	bool s = rp_GetWeaponStorage(wepid);
	
	g = rp_GetWeaponGroupID(wepid);
	ammo = Weapon_GetPrimaryClip(wepid);
	Client_GetWeaponPlayerAmmoEx(client, wepid, ammo1);
	index = GetEntProp(wepid, Prop_Send, "m_iItemDefinitionIndex");
	CSGO_GetItemDefinitionNameByIndex(index, wepname, sizeof(wepname));
	
	RemovePlayerItem(client, wepid);
	RemoveEdict(wepid);
	
	wepid = GivePlayerItem(target, wepname);
	
	rp_SetWeaponBallType(wepid, wep_type);
	rp_SetWeaponGroupID(wepid, g);
	Weapon_SetPrimaryClip(wepid, ammo);
	Client_SetWeaponPlayerAmmoEx(target, wepid, ammo1);
	rp_SetWeaponStorage(wepid, s);
	
	rp_SetClientWeaponSkin(target, wepid);
}

public Action rp_ClientRemoveProp(int client, int target, int item_id) {
	
	if (target > 0 && Entity_GetDistance(client, target) < 300.0) {
		if( rp_IsRemoveAble(target) && GetEntProp(target, Prop_Data, "m_takedamage") > 0 ) {
			
			char name[128];
			GetEdictClassname(target, name, sizeof(name));
			if (StrEqual(name, "rp_cashmachine")) {
				
				int owner = GetEntPropEnt(target, Prop_Send, "m_hOwnerEntity");
				if (IsValidClient(owner)) {
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez detruit la machine de %N", owner);
					CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Une de vos machines a faux billet a été detruite.");
				}
				
			}
			if (StrEqual(name, "rp_bigcashmachine")) {
				
				int owner = GetEntPropEnt(target, Prop_Send, "m_hOwnerEntity");
				if (IsValidClient(owner)) {
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez detruit la grosse machine de %N", owner);
					CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Votre grosse machine a faux billet a été detruite.");
				}
			}
			else if (StrEqual(name, "rp_plant")) {
				int owner = GetEntPropEnt(target, Prop_Send, "m_hOwnerEntity");
				if (IsValidClient(owner) && owner != client) {
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez detruit un plant de drogue de %N", owner);
					CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Une de vos plantations a été detruite.");
				}
				else if (owner == client && rp_GetBuildingData(target, BD_FromBuild) == 0) {
					int sub = rp_GetBuildingData(target, BD_item_id);
					rp_ClientGiveItem(client, sub, rp_GetBuildingData(target, BD_count));
				}
			}
			
			rp_Effect_Tazer(client, target);
			
			
			if (StrContains(name, "prop_physics") == 0) {
				int owner = rp_GetBuildingData(target, BD_owner);
				
				if (IsValidClient(owner)) {
					
					if (owner == client) {
						int i = rp_GetBuildingData(target, BD_item_id);
						if (i > 0) {
							rp_ClientGiveItem(client, i);
						}
						AcceptEntityInput(target, "Kill");
					}
					else {
						// DealDamage(target, 1000, client);
						SDKHooks_TakeDamage(target, client, client, 1000.0);
					}
				}
				else {
					AcceptEntityInput(target, "Kill");
					CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le props a été supprime.");
				}
			}
			else {
				AcceptEntityInput(target, "Kill");
				CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le props a été supprime.");
			}
		}
		else if (rp_IsValidVehicle(target) && rp_GetZoneBit(rp_GetPlayerZone(target)) & BITZONE_PVP) {
			int heal = rp_GetVehicleInt(target, car_health) - 500;
			int owner = rp_GetVehicleInt(target, car_owner);
			rp_SetVehicleInt(target, car_health, heal);
			
			if (heal <= 0 && IsValidClient(owner)) {
				CPrintToChat(owner, "{lightblue}[TSX-RP]{default} Votre voiture a été détruite en PvP.");
			}
			rp_Effect_Tazer(client, target);
		}
		else {
			ITEM_CANCEL(client, item_id);
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il n'y a rien à supprimer.");
		}
	}
	else {
		ITEM_CANCEL(client, item_id);
	}
	
	return Plugin_Continue;
}
stock int rp_GetWeaponPrice(int weaponID) {
	char classname[65], tmp[255], tmp2[255];
	GetEdictClassname(weaponID, classname, sizeof(classname));
	
	for (int i = 1; i < MAX_ITEMS; i++) {
		rp_GetItemData(i, item_type_extra_cmd, tmp, sizeof(tmp));
		Format(tmp2, sizeof(tmp2), "rp_giveitem %s", classname);
		if (StrEqual(tmp, tmp2)) {
			return rp_GetItemInt(i, item_type_prix) + rp_GetWeaponPriceCartouche(weaponID);
		}
	}
	
	ReplaceString(classname, sizeof(classname), "weapon_", "");
	int owner = GetEntPropEnt(weaponID, Prop_Send, "m_hPrevOwner");
	
	if (owner > 0 && view_as<int>(CS_AliasToWeaponID(classname)) > 0)
		return CS_GetWeaponPrice(owner, CS_AliasToWeaponID(classname)) + rp_GetWeaponPriceCartouche(weaponID);
	// fallback:
	return 500;
}
stock int rp_GetWeaponPriceCartouche(int weaponID) {
	int prix;
	if (rp_GetWeaponGroupID(weaponID) > 0)
		prix += 250;
	
	switch (rp_GetWeaponBallType(weaponID)) {
		case ball_type_fire : prix += 250;
		case ball_type_caoutchouc : prix += 200;
		case ball_type_poison : prix += 200;
		case ball_type_vampire : prix += 200;
		case ball_type_paintball : prix += 50;
		case ball_type_reflexive : prix += 200;
		case ball_type_explode : prix += 300;
		case ball_type_revitalisante : prix += 200;
		case ball_type_nosteal : prix += 50;
		case ball_type_notk : prix += 50;
		case ball_type_braquage : prix += 1000;
	}
	return prix;
}
stock int rp_CountPoliceNear(int client) {
	static float g_flLastCheck[65];
	static int g_iLastData[65];
	
	if (g_flLastCheck[client] > GetGameTime()) {
		return g_iLastData[client];
	}
	
	int job, count;
	for (int i = 1; i < MaxClients; i++) {
		if (!IsValidClient(i))
			continue;
		
		job = rp_GetClientInt(i, i_Job);
		
		if (GetClientTeam(i) == CS_TEAM_CT || (job >= 1 && job <= 7)) {
			if (Entity_GetDistance(client, i) < 500 && !rp_GetClientBool(i, b_IsAFK)) {
				count++;
			}
		}
	}
	
	g_flLastCheck[client] = GetGameTime() + 0.5;
	g_iLastData[client] = count;
	return count;
}
// ----------------------------------------------------------------------------
stock int rp_PlayerIsInCasinoMachine(int client) {
	static float rows[][][] = {
		{{2505.0, -5624.0, -1962.0}, {2545.0, -5530.0, -1882.0}},
		{{2505.0, -5528.0, -1962.0}, {2545.0, -5434.0, -1882.0}},
		{{2505.0, -5428.0, -1962.0}, {2545.0, -5334.0, -1882.0}},
		{{2505.0, -5324.0, -1962.0}, {2545.0, -5190.0, -1882.0}},
		{{2353.0, -5620.0, -1962.0}, {2393.0, -5478.0, -1882.0}},
		{{2353.0, -5468.0, -1962.0}, {2393.0, -5326.0, -1882.0}},
		{{2249.0, -5468.0, -1962.0}, {2289.0, -5326.0, -1882.0}},
		{{2249.0, -5620.0, -1962.0}, {2289.0, -5478.0, -1882.0}},
		{{1788.0, -5359.0, -1962.0}, {1938.0, -5309.0, -1882.0}},
		{{1938.0, -5359.0, -1962.0}, {2028.0, -5309.0, -1882.0}}
	};
	
	if( rp_GetPlayerZone(client) != 278 )
		return -1;
	
	float pos[3];
	GetClientAbsOrigin(client, pos);
	
	for (int i = 0; i < sizeof(rows); i++) {
		if(	pos[0] <= rows[i][1][0] && pos[1] <= rows[i][1][1] && pos[2] <= rows[i][1][2] &&
			pos[0] >= rows[i][0][0] && pos[1] >= rows[i][0][1] && pos[2] >= rows[i][0][2] ) {
				return i;
		}
	}
	return -1;
}
public Action Cmd_PluginReloadSelf(int args) {
	static char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}