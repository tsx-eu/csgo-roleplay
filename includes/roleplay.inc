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
#if defined _tsxrp_included_
  #endinput
#endif
#define _tsxrp_included_

#include <rp_tools.inc>

// ----------------------------------------------------------------------------
enum rp_event {
	RP_PreTakeDamage,													
	RP_PostTakeDamageWeapon,
	RP_PostTakeDamageKnife,
	
	RP_PreGiveDamage,													
	RP_PostGiveDamageWeapon,
	RP_PostGiveDamageKnife,
	
	RP_PrePlayerPhysic,
	RP_PreHUDColorize,
	RP_OnFrameSeconde,
	RP_OnAssurance,
	RP_OnPlayerSpawn,
	RP_OnPlayerDead,
	RP_OnPlayerBuild,
	RP_OnPlayerUse,
	RP_OnPlayerCommand,
	RP_OnPlayerSteal,
	
	RP_EventMax
}
typeset rp_event_enum {
	function Action(int victim, int attacker, float& damage); 			/* RP_PreTakeDamage  == return Plugin_Handled = aucun dégat */
	function Action(int victim, int attacker, float& damage, int wepID);/* RP_PostTakeDamageWeapon */
	function Action(int victim, int attacker, float& damage); 			/* RP_PostTakeDamageKnife */
	
	function Action(int attacker, int victim, float& damage); 			/* RP_PreGiveDamage  == return Plugin_Handled = aucun dégat */
	function Action(int attacker, int victim, float& damage, int wepID);/* RP_PostGiveDamageWeapon */
	function Action(int attacker, int victim, float& damage); 			/* RP_PostGiveDamageKnife */
	
	function Action(int client, float& speed, float& gravity); 			/* RP_PrePlayerPhysic */
	function Action(int client, int color[4]); 							/* RP_PreHUDColorize */
	function Action(int client);										/* RP_OnFrameSeconde */
	function Action(int client, int& amount);							/* RP_OnAssurance */
	function Action(int client);										/* RP_OnPlayerSpawn */
	function Action(int victim, int attacker, float& respawn);			/* RP_OnPlayerDead == return Plugin_Handled = cacher des logs */
	function Action(int client, float& cooldown);						/* RP_OnPlayerBuild */
	function Action(int client);										/* RP_OnPlayerUse */
	function Action(int client, char[] command);						/* RP_OnPlayerCommand */
	function Action(int client, int target, float& cooldown);			/* RP_OnPlayerSteal */
};
native bool rp_HookEvent(int client, rp_event eventID, rp_event_enum hook, float duration=-1.0);
native bool rp_UnhookEvent(int client, rp_event eventID, rp_event_enum hook);
// ----------------------------------------------------------------------------

native int rp_GetClientInt(int client, int_user_data prop);
native bool rp_GetClientBool(int client, bool_user_data prop);
native float rp_GetClientFloat(int client, float_user_data prop);
native void rp_SetClientInt(int client, int_user_data prop, int value);
native void rp_SetClientBool(int client, bool_user_data prop, bool value);
native void rp_SetClientFloat(int client, float_user_data prop, float value);
native void rp_SetClientString(int client, sz_user_data prop, char[] value, int length);
native void rp_GetClientString(int client, sz_user_data prop, char[] value, int length);

// ----------------------------------------------------------------------------
native int rp_GetClientJobID(int client); /* return le numéro du job auquel il appartient. 1, 11, 21, 31... */
native int rp_GetClientGroupID(int client); /* return le numéro du groupe auquel il appartient. 1, 11, 21, 31... */
native int rp_GetClientPvPBonus(int client, rp_capture_zone typeID);
// ----------------------------------------------------------------------------
native bool rp_IsInPVP(int entity);
native bool rp_IsEntitiesNear(int ent1, int ent2, bool tresProche = false, float cache = 0.25);
native bool rp_IsTutorialOver(int client);
native bool rp_IsBuildingAllowed(int client, bool silent = false);
native bool rp_IsClientLucky(int client);
native bool rp_IsClientNew(int client);
native bool rp_IncrementLuck(int client);
native bool rp_IsTargetSeen(int client, int target);
native bool rp_IsValidDoor(int doorID);
native bool rp_IsNight();
// ----------------------------------------------------------------------------
native bool rp_IsValidVehicle(int entity);
native void rp_SetClientKeyVehicle(int client, int vehicleID, bool status=false);
native bool rp_GetClientKeyVehicle(int client, int vehicleID);
native void rp_ClientVehicleExit(int client, int vehicleID, bool forced=false);
native void rp_ClientVehiclePassagerExit(int client, int vehicleID);
native int rp_GetClientVehiclePassager(int client);
native void rp_SetClientVehiclePassager(int client, int vehicleID);
native void rp_SetVehicleInt(int vehicleID, car_data typeID, int value);
native int rp_GetVehicleInt(int vehicleID, car_data typeID);
native void rp_SetClientVehicle(int client, int vehicleID, bool force=false);
// ----------------------------------------------------------------------------
native void rp_SetAppartementInt(int appartID, type_appart_bonus typeID, int value);
native int rp_GetAppartementInt(int appartID, type_appart_bonus typeID);
native void rp_SetClientKeyAppartement(int client, int appartID, bool status=false);
native bool rp_GetClientKeyAppartement(int client, int appartID);
// ----------------------------------------------------------------------------
native void rp_Effect_PropExplode(int entityID, bool tazer = false);
native void rp_Effect_Smoke(int client, float duration = 30.0);
native void rp_Effect_VisionTrouble(int client, float duration = 30.0);
native void rp_Effect_ShakingVision(int client, float duration = 30.0);
native void rp_Effect_Particle(int entity, char[] effect, float duration = 0.0001);
native void rp_Effect_Tazer(int client, int target);
native void rp_Effect_SpawnMoney(float origin[3], bool high = false);
native void rp_Effect_BeamBox(int client, int target = -1, float origin[3] = NULL_VECTOR, int red = 0, int green = 255, int blue = 0);
// ----------------------------------------------------------------------------
native int rp_Effect_Explode(float origin[3], float damage, float length, int entity=0, char[] weapon = "");
native void rp_Effect_Push(float origin[3], float radius, float speed, int ignore = -1);
// ----------------------------------------------------------------------------
native void rp_IncrementSuccess(int client, rp_success_list success, int amount = 1);
// ----------------------------------------------------------------------------
native int rp_GetClientItem(int client, int itemID, bool fromBank = false);
native void rp_ClientGiveItem(int client, int itemID, int amount=1, bool toBank = false);
// ----------------------------------------------------------------------------
native void rp_ClientRespawn(int client, float time=0.1);
native void rp_ClientSave(int client);
native void rp_ClientIgnite(int client, float time=10.0, int attacker=0);
native void rp_ClientPoison(int client, float time=10.0, int attacker=0);
native void rp_ClientDamage(int client, int damage, int attacker, char[] weapon = "point_hurt", int damageType = DMG_GENERIC);
native void rp_ClientColorize(int client, int color[4]={-1,-1,-1,-1});
native void rp_ClientSendToSpawn(int client, bool nearest = false);
native void rp_ClientGiveKnife(int client);
native void rp_ClientReveal(int client);
native void rp_ClientDrawWeaponMenu(int client, int ent, bool steal);
// ----------------------------------------------------------------------------
native int rp_GetPlayerZoneAppart(int client); /* Numéro de l'appartement: Uniquement si au moins 1 appart. Sinon 0 */
native int rp_GetPlayerZone(int client, float cache = 0.25); 
native int rp_GetZoneBit(int client, float cache = 300.0);
// ----------------------------------------------------------------------------
native int rp_GetRandomCapital(int jobID);
native int rp_GetJobCapital(int jobID);
native int rp_SetJobCapital(int jobID, int amount);
// ----------------------------------------------------------------------------
native int rp_GetDoorID(int ent); // return doorID
native void rp_SetDoorLock(int doorID, bool status); 
native void rp_ClientOpenDoor(int client, int doorID, bool status);
// ----------------------------------------------------------------------------
native void rp_SetClientWeaponSkin(int client, int wepID);
native void rp_SetWeaponGroupID(int wepID, int groupID);
native void rp_SetWeaponBallType(int wepID, enum_ball_type typeID);
native void rp_SetClientKnifeType(int client, enum_ball_type typeID);
native enum_ball_type rp_GetWeaponBallType(int wepID);
native enum_ball_type rp_GetClientKnifeType(int client);
native bool rp_GetWeaponStorage(int wepID);
native void rp_SetWeaponStorage(int wepID, bool value);
native int rp_GetWeaponGroupID(int wepID);

// ----------------------------------------------------------------------------
native void rp_GetWeaponSkinData(int skinID, skin_data typeID, char[] str, int length);
public int rp_GetWeaponSkinInt(int skinID, int typeID) {
	char tmp[32];
	rp_GetWeaponSkinData(skinID, view_as<skin_data>typeID, tmp, sizeof(tmp));
	return StringToInt(tmp);
}
native void rp_GetZoneData(int zoneID, zone_type typeID, char[] str, int length);
native void rp_GetJobData(int jobID, rp_job_type typeID, char[] str, int length);
native void rp_GetItemData(int itemID, rp_item_type typeID, char[] str, int length);
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
// ----------------------------------------------------------------------------
native void rp_ScheduleEntityInput(int entity, float time, char[] input);
// ----------------------------------------------------------------------------
native Handle rp_GetDatabase();
native Handle rp_CreateSellingMenu();
// ----------------------------------------------------------------------------
native void rp_ClientRemoveProp(int client, int target, int item_id);
// ----------------------------------------------------------------------------
native void rp_SetBuildingData(int ent, building_prop_data typeID, int data);
native int rp_GetBuildingData(int ent, building_prop_data typeID);
// ----------------------------------------------------------------------------
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
// ----------------------------------------------------------------------------

#define ACCESS_DENIED(%1)	CPrintToChat(%1, "{lightblue}[TSX-RP]{default} Vous n'avez pas accès à cette commande.");	return Plugin_Handled
#define ITEM_CANCEL(%1,%2)	rp_ClientGiveItem(%1,%2); rp_SetClientFloat(%1, fl_CoolDown, 0.05)

#define BITZONE_DEFAULT		(0)		// https://www.ts-x.eu/shared_public/bit.html
#define BITZONE_PEACEFULL	(1<<0)
#define BITZONE_PVP			(1<<1)
#define BITZONE_DENY		(1<<2)
#define BITZONE_BLOCKITEM	(1<<3)
#define BITZONE_BLOCKSELL	(1<<4)
#define BITZONE_BLOCKCHIRU	(1<<5)
#define BITZONE_BLOCKSTEAL	(1<<6)
#define BITZONE_BLOCKBUILD	(1<<7)
#define BITZONE_BLOCKFORCE	(1<<8)
#define BITZONE_BLOCKTALK	(1<<9)
#define BITZONE_BLOCKOUT	(1<<10)
#define BITZONE_BLOCKJAIL	(1<<11)
#define BITZONE_BLOCKSPEAK	(1<<12)
#define BITZONE_PARKING		(1<<15)
#define BITZONE_JUSTICEITEM	(1<<18)
#define BITZONE_POLICEFORCE	(1<<19)
#define BITZONE_JAIL		(1<<20)
#define BITZONE_HAUTESECU	(1<<21)
#define BITZONE_LACOURS		(1<<22)
#define BITZONE_EVENT		(1<<23)
#define BITZONE_VENTE		(1<<24)
#define	BITZONE_PERQUIZ		(1<<25)

#define MAX_ITEMS	330
#define MAX_JOBS	230

// ----------------------------------------------------------------------------
enum bool_user_data {
	b_isConnected,	// Money,bank, item
	b_isConnected2, // Success
	b_Respawning,
	b_Drugged,
	b_License1,
	b_License2,
	b_LicenseSell,
	b_MaySteal,
	b_PayToBank,
	b_HaveCard,
	b_HaveAccount,
	b_Invisible,
	b_Smoking,
	b_ForceExit,
	b_Stealing,
	b_LampePoche,
	b_Jumelle,
	b_Blind,
	b_KeyReverse,
	b_Assurance,
	b_Beacon,
	b_Crayon,
	b_Map,
	b_CAPSLOCK,
	b_NoDonateurSkin,
	b_AdminHeal,
	b_HasMail,
	b_HasGrave,
	b_SpawnToGrave,
	b_Pissing,
	b_ChiruRegen,
	b_ChiruMaxHeal,
	b_ChiruKevlar,
	b_ChiruYeux,
	b_IsAFK,
	b_udata_max
};
enum int_user_data {
	i_Money,
	i_Bank,
	i_Job,
	i_Group,
	i_JailTime,
	i_KnifeTrain,
	i_KnifeTrainAdmin,
	i_Esquive,
	i_LastKilled,
	i_LastKilled_Reverse,
	i_Client,
	i_Skin,
	i_LastForcedSave,
	i_ToKill,
	i_ContratFor,
	i_Reduction,
	i_ContratPay,
	i_KidnappedBy,
	i_Kevlar,
	i_KillAmount,
	i_KillingSpread,
	i_Malus,
	i_Sickness,
	i_FreekillSick,
	i_ContratTotal,
	i_LastVol,
	i_LastVolAmount,
	i_LastVolTarget,
	i_BurnedBy,
	i_JailledBy,
	i_Cryptage,
	i_LastTime,
	i_SpawnAmount,
	i_jailTime_Last,
	i_jailTime_Reason,
	i_Perquiz,
	i_Camera,
	i_GPS,
	i_Machine,
	i_Donateur,
	i_ThirdPerson,
	i_Protect_Him,
	i_Protect_From,
	i_Protect_Last,
	i_ToPay,
	i_TimePlayedJob,
	i_PVP,
	i_Sick,
	i_Tutorial,
	i_TeleportTo,
	i_Disposed,
	i_KnifeSkin,
	i_Mask,
	i_AppartCount,
	i_LastKillTime,
	i_AddToPay,
	i_TimeAFK,
	i_TimeAFK_total,
	
	i_udata_max
};
enum float_user_data {
	Float:fl_Vitality,
	Float:fl_WeaponTrain,
	Float:fl_WeaponTrainAdmin,
	Float:fl_TazerTime,
	Float:fl_FrozenTime,
	Float:fl_invisibleTime,
	Float:fl_invisibleTimeLeft,
	Float:fl_Gravity,
	Float:fl_Speed,
	Float:fl_ForwardStates,
	Float:fl_Energy,
	Float:fl_Burning,
	Float:fl_LastStolen,
	Float:fl_PaintBall,
	Float:fl_Size,
	Float:fl_Reflect,
	Float:fl_SlowTime,
	Float:fl_CoolDown,
	Float:fl_Invincible,
	Float:fl_LastVente,
	Float:fl_Alcool,
	Float:fl_LowDamage,
	Float:fl_HallucinationTime,
	
	fl_udata_max
};
enum sz_user_data {
	String:sz_Skin,
	
	sz_udata_max
};
enum sick_type {
	sick_type_none,
	
	sick_type_fievre,
	sick_type_grippe,
	sick_type_tourista,
	sick_type_hemoragie,
	
	sick_type_max
};
enum rp_success_list {	
	success_list_police,
	success_list_hopital,
	success_list_mcdo,
	success_list_tueur,
	success_list_coach,
	success_list_dealer,
	success_list_mafia,
	success_list_armurerie,
	success_list_vetement,
	success_list_detective,
	success_list_moniteur,
	success_list_loterie,
	success_list_sexshop,
	success_list_technicien,
	success_list_touch_down,
	success_list_touch_up,
	success_list_life_short,
	success_list_vengeur,
	success_list_marathon,
	success_list_brulure,
	success_list_immune,
	success_list_jetumeurs,
	success_list_noviolence,
	success_list_5sectokill,
	success_list_no_spy,
	success_list_shared_work,
	success_list_worldspawn,
	success_list_only_one,
	success_list_student,
	success_list_robin_wood,
	success_list_unknown,
	success_list_in_gang,
	success_list_pyramid,
	success_list_ikea_fail,
	success_list_graffiti,
	success_list_fireworks,
	success_list_assurance,
	success_list_no_tech,
	success_list_no_18th,
	success_list_million,
	success_list_pas_vu_pas_pris,
	success_list_pissing,
	success_list_trafiquant,
	success_list_faster_dead,
	success_list_collector,
	success_list_pvpkill,
	success_list_monopoly,
	success_list_menotte,
	success_list_cafeine,
	success_list_to_infini,
	success_list_with_succes,
	success_list_kidnapping,
	success_list_killpvp2,
	success_list_alcool_abuse,
	success_list_tel,
	success_list_w_friends,
	success_list_w_friends2,
	success_list_w_friends3,
	success_list_bon_patron,
	success_list_rainbow,
	success_list_hdv,
	success_list_carkill,
	success_list_carshop,
	success_list_lotto,
	success_list_quota,
	success_list_cpt,
	success_list_all
};
enum building_prop_data {
	BD_started,
	BD_count,
	BD_max,
	BD_owner,
	BD_Trapped,
	
	building_prop_data_max
};
enum rp_capture_zone {
	cap_nuclear =  0,
	cap_tower,
	cap_villa,
	cap_disableItem,
	capture_max
};
enum enum_ball_type {
	ball_type_none,
	ball_type_fire,
	ball_type_caoutchouc,
	ball_type_poison,
	ball_type_vampire,
	ball_type_paintball,
	ball_type_reflexive,
	ball_type_explode,
	ball_type_max
};
enum rp_item_type {
	item_type_name = 0,
	item_type_extra_cmd,
	item_type_give_hp,
	item_type_reuse_delay,
	item_type_job_id,
	item_type_prix,
	item_type_auto,
	item_type_dead,
	
	item_type_ordered_id,
	
	item_type_max
};
enum rp_job_type {
	job_type_name = 0,
	job_type_isboss,
	job_type_ownboss,
	job_type_pay,
	job_type_capital,
	job_type_subside,
	job_type_quota,
	job_type_current,
	job_type_tag,
	job_type_cochef,
	
	job_type_max
};
enum zone_type {
	zone_type_name = 0,
	
	zone_type_min_x,
	zone_type_min_y,
	zone_type_min_z,
	
	zone_type_max_x,
	zone_type_max_y,
	zone_type_max_z,
	
	zone_type_type,	
	zone_type_bit,
	
	zone_type_max
};
enum car_data {
	car_light_left_id = 0,
	car_light_right_id,
	car_light_middle_id,
	car_light_is_on,
	car_thirdperson_id,
	car_klaxon,
	car_owner,
	car_item_id,
	car_health,
	car_awayTick,
	car_maxPassager,
	
	car_data_max,
};
enum skin_data {
	skin_id,
	skin_name,
	
	skin_max
};
enum type_appart_bonus {
	appart_bonus_energy,
	appart_bonus_heal,
	appart_bonus_armor,
	appart_bonus_garage,
	appart_bonus_vitality,
	appart_bonus_coffre,
	appart_bonus_paye,
	
	appart_proprio,
	
	appart_bonus_max	
};
