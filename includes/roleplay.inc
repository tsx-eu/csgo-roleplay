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

enum rp_event {
	RP_PreTakeDamage,													
	RP_PostTakeDamageWeapon,
	RP_PostTakeDamageKnife,
	RP_PrePlayerPhysic,
	RP_PreHUDColorize,
	RP_OnFrameSeconde,
	RP_OnAssurance,
	RP_OnPlayerSpawn,
	RP_OnPlayerDead,
	RP_OnPlayerBuild,
	
	RP_EventMax
}
typeset rp_event_enum {
	function Action(int victim, int attacker, float &damage); 			/* RP_PreTakeDamage  == return Plugin_Handled = aucun dégat */
	function Action(int victim, int attacker, float &damage, int wepID);/* RP_PostTakeDamageWeapon */
	function Action(int victim, int attacker, float &damage); 			/* RP_PostTakeDamageKnife */
	function Action(int client, float &speed, float &gravity); 			/* RP_PrePlayerPhysic */
	function Action(int client, int color[4]); 							/* RP_PreHUDColorize */
	function Action(int client);										/* RP_OnFrameSeconde */
	function Action(int client, int& amount);							/* RP_OnAssurance */
	function Action(int client);										/* RP_OnPlayerSpawn */
	function Action(int victim, int attacker);							/* RP_OnPlayerDead == return Plugin_Handled = cacher des logs */
	function Action(int client, float& cooldown);						/* RP_OnPlayerBuild */
	
};

native bool rp_HookEvent(int client, rp_event eventID, rp_event_enum hook, float duration=-1.0);
native bool rp_UnhookEvent(int client, rp_event eventID, rp_event_enum hook);

native int	rp_GetClientInt(int client, int_user_data prop);
native bool rp_GetClientBool(int client, bool_user_data prop);
native float rp_GetClientFloat(int client, float_user_data prop);
native void rp_SetClientInt(int client, int_user_data prop, int value);
native void rp_SetClientBool(int client, bool_user_data prop, bool value);
native void rp_SetClientFloat(int client, float_user_data prop, float value);
native int rp_GetClientGroupID(int client); /* return le numéro du groupe auquel il appartient. 1, 11, 21, 31... */
native int rp_GetClientJobID(int client); /* return le numéro du job auquel il appartient. 1, 11, 21, 31... */
native int rp_GetClientPvPBonus(int client, rp_capture_zone typeID);

native bool rp_IsInPVP(int entity);
native bool rp_IsEntitiesNear(int ent1, int ent2, bool tresProche = false, float cache = 0.25);
native bool rp_IsTutorialOver(int client);
native bool rp_IsBuildingAllowed(int client, bool silent = false);

native void rp_Effect_Smoke(int client, float duration = 30.0);
native void rp_Effect_VisionTrouble(int client, float duration = 30.0);
native void rp_Effect_ShakingVision(int client, float duration = 30.0);
native void rp_Effect_Particle(int entity, char[] effect, float duration = 0.0001);
native void rp_Effect_Tazer(int client, int target);
native void rp_Effect_SpawnMoney(float origin[3], bool high = false);

native int rp_Effect_Explode(float origin[3], float damage, float length, int entity=0, char[] weapon = "");

native void rp_IncrementSuccess(int client, rp_success_list success, int amount = 1);

native void rp_ClientGiveItem(int client, int itemID, int amount=1, bool toBank = false);
native void rp_ClientRespawn(int client, float time=0.1);
native void rp_ClientSave(int client);
native void rp_ClientIgnite(int client, float time=10.0, int attacker=0);
native void rp_ClientPoison(int client, float time=10.0, int attacker=0);
native void rp_ClientDamage(int client, int damage, int attacker, char[] weapon = "point_hurt", int damageType = DMG_GENERIC);
native void rp_ClientColorize(int client, int color[4]={-1,-1,-1,-1});

native int rp_GetPlayerZoneAppart(int client);
native int rp_GetPlayerZone(int client, float cache = 0.25);
native int rp_GetZoneBit(int client, float cache = 300.0);
native int rp_GetRandomCapital(int jobID);

native void rp_MakeRadiusPush(float center[3], float radius, float speed, int ignore = -1);

native void rp_SetClientWeaponSkin(int client, int wepID);
native void rp_SetWeaponGroupID(int wepID, int groupID);
native void rp_SetWeaponBallType(int wepID, enum_ball_type typeID);
native void rp_SetClientKnifeType(int client, enum_ball_type typeID);
native enum_ball_type rp_GetWeaponBallType(int wepID);
native enum_ball_type rp_GetClientKnifeType(int client);

native void rp_GetItemData(int itemID, rp_item_type typeID, char[] str, int length);
public int rp_GetItemInt(int itemID, int typeID) {
	char tmp[32];
	rp_GetItemData(itemID, view_as<rp_item_type>typeID, tmp, sizeof(tmp));
	return StringToInt(tmp);
}

native bool rp_IsClientLucky(int client);
native bool rp_IncrementLuck(int client);

native void rp_ScheduleEntityInput(int entity, float time, char[] input);


native int rp_GetJobCapital(int jobID);
native int rp_SetJobCapital(int jobID, int amount);

native Handle rp_GetDatabase();

native void rp_ClientRemoveProp(int client, int target, int item_id);
native void rp_SetBuildingData(int ent, building_prop_data typeID, int data);
native int rp_GetBuildingData(int ent, building_prop_data typeID);

// BUG min=1 sinon ça fait dla merde
public int Math_GetRandomPow(int min, int max) {
	return RoundToFloor( float( min + (max - min)  ) * ( Pow(GetRandomFloat(0.0, 1.0), (1.0/0.5) )  )) + 1;
}
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
	
	building_prop_data_max
};
enum rp_capture_zone {
	cap_nuclear =  0,
	cap_tower,
	cap_villa,
	capture_max
};

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