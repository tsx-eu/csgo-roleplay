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
	RP_PrePlayerPhysic,
	RP_PreHUDColorize,
	
	RP_EventMax
}
typeset rp_event_enum {
	function Action(int victim, int attacker, float &damage);
	function Action(int client, float &speed, float &gravity);
	function Action(int client, int color[4]);
};

native bool rp_HookEvent(int client, rp_event eventID, rp_event_enum hook, float duration=-1.0);
native bool rp_UnhookEvent(int client, rp_event eventID, rp_event_enum hook);

native void rp_giveClientItem(int client, int itemID, int amount=1, bool toBank = false);

native void rp_getClientFloat(int client, float_user_data prop, float &value);
native void rp_setClientFloat(int client, float_user_data prop, float value);
native void rp_getClientInt(int client, int_user_data prop, int &value);
native void rp_setClientInt(int client, int_user_data prop, int value);
native void rp_getClientBool(int client, bool_user_data prop, bool &value);
native void rp_setClientBool(int client, bool_user_data prop, bool value);

native bool rp_IsEntitiesNear(int ent1, int ent2, bool tresProche = false, float cache = 0.25);
native bool rp_IsTutorialOver(int client);

native void rp_Effect_Smoke(int client, float duration = 30.0);
native void rp_Effect_VisionTrouble(int client, float duration = 30.0);
native void rp_Effect_ShakingVision(int client, float duration = 30.0);

native void rp_IncrementSuccess(int client, rp_success_list success, int amount = 1);




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
}
enum sick_type {
	sick_type_none,
	
	sick_type_fievre,
	sick_type_grippe,
	sick_type_tourista,
	sick_type_hemoragie,
	
	sick_type_max
}
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

#define ACCESS_DENIED(%1)	CPrintToChat(%1, "{lightblue}[TSX-RP]{default} Vous n'avez pas accès à cette commande.");	return Plugin_Handled
#define ITEM_CANCEL(%1,%2)	rp_giveClientItem(%1,%2); rp_setClientFloat(%1, fl_CoolDown, 0.05)

