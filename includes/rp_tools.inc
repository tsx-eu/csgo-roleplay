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

// ----------------------------------------------------------------------------
// TODO: BUG min=1 sinon ça fait dla merde
public int Math_GetRandomPow(int min, int max) {
	return RoundToFloor( float( min + (max - min)  ) * ( Pow(GetRandomFloat(0.0, 1.0), (1.0/0.5) )  )) + 1;
}
// ----------------------------------------------------------------------------
public float GetCmdArgFloat(int index) {
	char arg[32];
	GetCmdArg(index, arg, sizeof(arg));
	return StringToFloat(arg);
}
public int GetCmdArgInt(int index) {
	char arg[32];
	GetCmdArg(index, arg, sizeof(arg));
	return StringToInt(arg);
}
public bool IsValidClient(int client) {
	if( client <= 0 || client > MaxClients )
		return false;
	
	if( !IsValidEdict(client) || !IsClientConnected(client) )
		return false;
	
	return true;
}
public int GetClientTarget(int client) {
	float vecStart[3], vecAngles[3];
	GetClientEyePosition(client, vecStart);
	GetClientEyeAngles(client, vecAngles);
	
	Handle trace = TR_TraceRayFilterEx(vecStart, vecAngles, MASK_SOLID, RayType_Infinite, FilterToOne, client);
	if( !TR_DidHit(trace) ) {
		CloseHandle(trace);
		return 0;
	}
	
	int ent = TR_GetEntityIndex(trace);
	CloseHandle(trace);
	
	return ent;
}
public bool FilterToOne(int entity, int mask, any data) {
	return (data != entity);
}
public void SQL_QueryCallBack(Handle owner, Handle handle, const char[] error, any data) {
	if( strlen(error) >= 1  ) {
		LogError("[SQL] [ERROR] %s - %f - %i", error, data, data);
	}
}
public int rp_GetItemInt(int itemID, int typeID) {
	char tmp[32];
	rp_GetItemData(itemID, view_as<rp_item_type>typeID, tmp, sizeof(tmp));
	return StringToInt(tmp);
}
public int rp_GetJobInt(int jobID, int typeID) {
	char tmp[32];
	rp_GetJobData(jobID, view_as<rp_job_type>typeID, tmp, sizeof(tmp));
	return StringToInt(tmp);
}
public int rp_GetZoneInt(int zoneID, int typeID) {
	char tmp[32];
	rp_GetZoneData(zoneID, view_as<zone_type>typeID, tmp, sizeof(tmp));
	return StringToInt(tmp);
}
public int rp_GetLocationInt(int zoneID, int typeID) {
	char tmp[32];
	rp_GetLocationData(zoneID, view_as<location_type>typeID, tmp, sizeof(tmp));
	return StringToInt(tmp);
}
public int rp_GetWeaponSkinInt(int skinID, int typeID) {
	char tmp[32];
	rp_GetWeaponSkinData(skinID, view_as<skin_data>typeID, tmp, sizeof(tmp));
	return StringToInt(tmp);
}

public bool rp_IsRemoveAble(int target) {
	#if defined DEBUG
	PrintToServer("IsRemoveAble");
	#endif
	if( !IsValidEdict(target) )
		return false;
	if( !IsValidEntity(target) )
		return false;
	
	char classname[128];
	GetEdictClassname(target, classname, sizeof(classname));
	
	if( StrEqual(classname, "prop_dynamic") ) {
		if( Entity_GetParent(target) >= 1 ) {
			return false;
		}
		return true;
	}
	if( StrEqual(classname, "rp_mine") ) {
		return true;
	}
	if( StrContains(classname, "weapon_") == 0 ) {
		return true;
	}
	if( StrContains(classname, "item_") == 0 ) {
		return true;
	}
	if( StrContains(classname, "rp_cashmachine_") == 0 ) {
		return true;
	}
	if( StrContains(classname, "rp_plant_") == 0 ) {
		return true;
	}
	if( StrContains(classname, "prop_physics") == 0 ) {
		return true;
	}
	if( StrContains(classname, "rp_grave") == 0 ) {
		return true;
	}
	
	return false;
}
public bool rp_IsMoveAble(int ent) {
	static char classname[64];
	
	if( ent <= 0 )
		return false;
	if( !IsValidEdict(ent) ) 
		return false;
	if( !IsValidEntity(ent) )
		return false;
	
	if( GetEntityMoveType(ent) == MOVETYPE_NOCLIP )
		return false;
	
	if( IsValidClient(ent) )  {
		if( IsPlayerAlive(ent) ) {
			return true;
		}
		else {
			return false;
		}
	}
	
	
	GetEdictClassname(ent, classname, 63);
	
	
	if( StrContains(classname, "door", false) != -1 )
		return false;
	if( StrContains(classname, "player", false) == 0 )
		return true;
	if( StrContains(classname, "prop_p", false) == 0 )
		return true;
	if( StrContains(classname, "func_phys", false) == 0 )
		return true;
	if( StrContains(classname, "weapon_", false) == 0 )
		return true;
	if( StrContains(classname, "item_", false) == 0 )
		return true;
	if( StrContains(classname, "chicken", false) == 0 )
		return true;
	if( StrContains(classname, "bonbon_entity_2", false) == 0 )
		return true;
	
	return false;
}
stock void rp_ClientSwitchWeapon(int client, int wepid, int target=-1) {
	if( target == -1 )
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
	RemoveEdict( wepid );
	
	wepid = GivePlayerItem(target, wepname);
	
	rp_SetWeaponBallType(wepid, wep_type);
	rp_SetWeaponGroupID(wepid, g);
	Weapon_SetPrimaryClip(wepid, ammo);
	Client_SetWeaponPlayerAmmoEx(target, wepid, ammo1);
	rp_SetWeaponStorage(wepid, s);
	
	rp_SetClientWeaponSkin(target, wepid);
}

