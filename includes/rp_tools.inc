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

