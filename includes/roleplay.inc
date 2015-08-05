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

// TODO: Corriger la doc en mettant les commentaires avant la fonction...

// ----------------------------------------------------------------------------
enum rp_event {
	RP_PreTakeDamage,			/* Le joueur recoit des dégats, quelques soit l'arme. Attention, n'est jamais appelé en zone EVENT, ni pendant une capture */				
	RP_PostTakeDamageWeapon,	/* Les 2 suivants sont appelé lors d'une capture, mais pas en zone event. La détection d'arme a aussi été faites. */
	RP_PostTakeDamageKnife,
	
	RP_PreGiveDamage,			/* Le joueur inflige des dégats, quelques soit l'arme. Attention, n'est jamais appelé en zone EVENT, ni pendant une capture */										
	RP_PostGiveDamageWeapon,	/* Les 2 suivants sont appelé lors d'une capture, mais pas en zone event. La détection d'arme a aussi été faites. */
	RP_PostGiveDamageKnife,
	
	RP_PrePlayerPhysic,		/* Permet de modifier la physique d'un joueur. Utiliser return Plugin_Stop pour forcer les valeurs et ignorer toutes les autres. */
	RP_PostPlayerPhysic,		/* Idem, mais accepté en PvP */
	
	RP_PreHUDColorize,		/* Modifie la couleur de l'écran */
	RP_OnFrameSeconde,		/* Appelé chaque seconde */
	RP_OnAssurance,			/* Modifie l'assurance, est appelé à chaques fois que le serveur la recalcul */
	RP_OnPlayerSpawn,			/* Lorsqu'un joueur respawn. Appelé après l'avoir TP Au bon endroit */
	RP_OnPlayerDead,			/* Un joueur meurt. Return Plugin_Handled pour cacher la mort des logs*/
	RP_OnPlayerBuild,			/* Un joueur utilise la commande /build */
	RP_OnPlayerUse,			/* Un joueur utilise la commande utiliser, soit la touche E. */
	RP_OnPlayerCommand,		/* Un joueur execute une commande, /vol, /truc, /bidule. command ne contient ni de !, ni de /. */
	RP_OnPlayerSteal,			/* Un joueur execute le /vol */
	RP_OnPlayerZoneChange,		/* Un joueur change de zone */
	
	RP_OnPlayerHear,		/* Peut-il entendre un autre joueur ? */
	RP_PrePlayerTalk,		/* J'écris un message dans le chat  */
	
	
	RP_EventMax
}
typeset rp_event_enum {
	
	function Action(int victim, int attacker, float& damage); 			/* RP_PreTakeDamage  == return Plugin_Handled = aucun dégat */
	
	function Action(int victim, int attacker, float& damage, int wepID, float pos[3]);	/* RP_PostTakeDamageWeapon */
	function Action(int victim, int attacker, float& damage); 			/* RP_PostTakeDamageKnife */
	function Action(int attacker, int victim, float& damage); 			/* RP_PreGiveDamage  == return Plugin_Handled = aucun dégat */
	function Action(int attacker, int victim, float& damage, int wepID, float pos[3]);	/* RP_PostGiveDamageWeapon */
	function Action(int attacker, int victim, float& damage); 			/* RP_PostGiveDamageKnife */
	
	
	function Action(int client, float& speed, float& gravity); 			/* RP_PrePlayerPhysic == return Plugin_Stop pour forcer les valeurs et ignorer les autres plugins/hook*/
	function Action(int client, float& speed, float& gravity); 			/* RP_PostPlayerPhysic */
	
	
	function Action(int client, int color[4]); 					/* RP_PreHUDColorize == idem */
	function Action(int client);								/* RP_OnFrameSeconde */
	function Action(int client, int& amount);						/* RP_OnAssurance */
	function Action(int client);								/* RP_OnPlayerSpawn */
	function Action(int victim, int attacker, float& respawn);			/* RP_OnPlayerDead == return Plugin_Handled = cacher des logs */
	function Action(int client, float& cooldown);					/* RP_OnPlayerBuild */
	function Action(int client);								/* RP_OnPlayerUse */
	function Action(int client, char[] command, char[] arg);	/* RP_OnPlayerCommand */
	function Action(int client, int target, float& cooldown);			/* RP_OnPlayerSteal */
	function Action(int client, int newZoneID, int oldZoneID);		/* RP_OnPlayerZoneChange */
	
	function Action(int client, int target, float& dist);		/* RP_OnPlayerHear Est-ce que client peut entendre target ? */
	function Action(int client, char[] message, int length, bool local);	/* RP_PrePlayerTalk */
};
/*
 * @brief Hook sur un joueur. 
 * @note Attention, penser à unhook lorsque le joueur déco!
 * @param	client	un joueur
 * @param 	eventID	Un évenement produit par un joueur. Cf: enum rp_event
 * @param 	hook	Function a appeler lorsque le hook est appelé
*/
native bool rp_HookEvent(int client, rp_event eventID, rp_event_enum hook, float duration=-1.0);
native bool rp_UnhookEvent(int client, rp_event eventID, rp_event_enum hook);
// ----------------------------------------------------------------------------
/*
 * @brief Récupère un attribu d'un joueur
 * @param 	client	un joueur
 * @param	prop	Une propriétée comprise dans l'enum Entier: int_user_data, Booléen: bool_user_data, Flotant: float_user_data, String: sz_udata_max
 * @return valeur
*/
native int rp_GetClientInt(int client, int_user_data prop);
native bool rp_GetClientBool(int client, bool_user_data prop);
native float rp_GetClientFloat(int client, float_user_data prop);
native void rp_GetClientString(int client, sz_user_data prop, char[] value, int length);
/*
 * @brief Altère un attribu d'un joueur
 * @param 	client	un joueur
 * @param	prop	Une propriétée comprise dans l'enum Entier: int_user_data, Booléen: bool_user_data, Flotant: float_user_data, String: sz_udata_max
 * @param	valeur
*/
native void rp_SetClientInt(int client, int_user_data prop, int value);
native void rp_SetClientBool(int client, bool_user_data prop, bool value);
native void rp_SetClientFloat(int client, float_user_data prop, float value);
native void rp_SetClientString(int client, sz_user_data prop, char[] value, int length);
// ----------------------------------------------------------------------------
native int rp_GetClientJobID(int client);										/* return le numéro du job auquel il appartient. 1==police, 11==hosto, 21==mcdo, etc --> http://www.ts-x.eu/index.php?page=roleplay&game=csgo&sub=job&id=1 */
native int rp_GetClientGroupID(int client);									/* return le numéro du groupe auquel il appartient. 1==SPQR, 11==SMURF, etc --> https://www.ts-x.eu/index.php?page=roleplay&game=csgo&sub=group&id=1 */
native int rp_GetClientPvPBonus(int client, rp_capture_zone typeID);					/* Est-ce qu'un joueur à le droit à un bonus de type PVP ? typeID==> cap_nuclear, cap_tower, cap_villa */
// ----------------------------------------------------------------------------
native bool rp_IsInPVP(int entity);											/* L'entité est-elles en PvP ? Attention cache de 0.5 seconde */
native bool rp_IsEntitiesNear(int client, int ent2, bool tresProche = false, float cache = 0.25); /* L'entité est-elle proche d'un joueur ? */
native bool rp_IsTutorialOver(int client);									/* Le tutorial n'est pas terminé */
native bool rp_IsBuildingAllowed(int client, bool silent = false);					/* Peut-on construire quelques chose à cet endroit ? */
native bool rp_IsClientLucky(int client);										/* Le joueur à t-il de la chance ? */
native bool rp_IsClientNew(int client);										/* Moins de 20 heures de jeu */
native bool rp_IncrementLuck(int client);										/* Augmente la chance d'un joueur... */
native bool rp_IsTargetSeen(int client, int target);								/* Est-ce que client peut voir target ? TODO: A confirmer que ce n'est pas l'inverse */
native bool rp_IsTargetHear(int client, int target);								/* Est-ce que client peut entendre target ? */
native bool rp_IsValidDoor(int ent);										/* La porte est-elle valide ? */
native bool rp_IsNight();												/* Entre 18h30 et 6h30 du matin */
// ----------------------------------------------------------------------------
native bool rp_IsValidVehicle(int entity);
native void rp_SetClientKeyVehicle(int client, int vehicleID, bool status=false);			/* Définir les clés d'une voiture à un joueur. Status=true -> Il a la clé */
native bool rp_GetClientKeyVehicle(int client, int vehicleID);						/* Le joueur à t-il la clé d'une voiture ? */
native void rp_ClientVehicleExit(int client, int vehicleID, bool forced=false);			/* Sort un conducteur d'une voiture */
native void rp_ClientVehiclePassagerExit(int client, int vehicleID);					/* Sort un passager d'une voiture */
native int rp_GetClientVehiclePassager(int client);								/* Sommes-nous passager d'une voiture ? */
native void rp_SetClientVehiclePassager(int client, int vehicleID);					/* Mettons nous passager d'une voiture ! */
native void rp_SetVehicleInt(int vehicleID, car_data typeID, int value);				/* Définir propriétée d'une voiture */
native int rp_GetVehicleInt(int vehicleID, car_data typeID);						/* Récupérer propriétée d'une voiture */
native void rp_SetClientVehicle(int client, int vehicleID, bool force=false);				/* Mettre un joueur conducteur d'une voiture */
// ----------------------------------------------------------------------------
native void rp_SetAppartementInt(int appartID, type_appart_bonus typeID, int value);		/* Définir une propriétée d'un appartement */
native int rp_GetAppartementInt(int appartID, type_appart_bonus typeID);				/* Récupérer une propriétée d'un appartement */
native void rp_SetClientKeyAppartement(int client, int appartID, bool status=false);		/* Donner une clé à un joueur d'un appartement */
native bool rp_GetClientKeyAppartement(int client, int appartID);						/* Est-ce qu'un joueur possède la clé d'un appartement ? */
// ----------------------------------------------------------------------------
native void rp_Effect_PropExplode(int entityID, bool tazer = false);					/* Explose un props, s'il est piégé */
native void rp_Effect_Smoke(int client, float duration = 30.0);						/* Petit effect de fumée de cigarette */
native void rp_Effect_VisionTrouble(int client, float duration = 30.0);					/* Trouble la vision d'un joueur */
native void rp_Effect_ShakingVision(int client, float duration = 30.0);					/* Fait trembler la vue d'un joueur */
native void rp_Effect_Particle(int entity, char[] effect, float duration=0.0001);		/* Affiche une particule */
native void rp_Effect_ParticlePath(int entity, char[] effect, const float src[3], const float angle[3], const float dest[3]); /* Affiche une particule à un endroit précis */
native void rp_Effect_Tazer(int client, int target);								/* Affiche un trait du tazer entre un joueur et une cible */
native void rp_Effect_SpawnMoney(float origin[3], bool high = false);						/* Spawn des billets 20-50$. High = true -> 200-500$. Penser à retirer la thune d'un capital */
native void rp_Effect_BeamBox(int client, int target = -1, float origin[3] = NULL_VECTOR, int red = 0, int green = 255, int blue = 0); /* Affiche un lazer tracant entre un joueur et une cible */
// ----------------------------------------------------------------------------
native int rp_Effect_Explode(float origin[3], float damage, float length, int entity=0, char[] weapon = "");	/* Inflige des dégats aux alentours */
native void rp_Effect_Push(float origin[3], float radius, float speed, int ignore = -1);		/* Pousse toutes les entités aux alentours. Ou utiliser qql math compris dans le /push. Cette fonction est lourde... */
// ----------------------------------------------------------------------------
native void rp_IncrementSuccess(int client, rp_success_list success, int amount = 1);		/* Augmente les stats un succès */
// ----------------------------------------------------------------------------
native int rp_GetClientItem(int client, int itemID, bool fromBank = false);				/* Combien fois un joueur possède un certain item? MAX 300. */
native void rp_ClientGiveItem(int client, int itemID, int amount=1, bool toBank = false); 	/* Donne un item à un joueur. La valeur peut être négative */
// ----------------------------------------------------------------------------
native void rp_ClientRespawn(int client, float time=0.1);							/* Respawn un joueur */
native void rp_ClientSave(int client);										/* Sauvegarde les données d'un joueur */
native void rp_ClientIgnite(int client, float time=10.0, int attacker=0);				/* Brule un joueur pour une certaine durée. */
native void rp_ClientPoison(int client, float time=10.0, int attacker=0);				/* Empoisone un joueur pour une certaine durée. */
native void rp_ClientDamage(int client, int damage, int attacker, char[] weapon = "point_hurt", int damageType = DMG_GENERIC);	/* Inflige des dégats à un autre joueur */
native void rp_ClientColorize(int client, int color[4]={-1,-1,-1,-1});					/* Colorie un joueur. Si 2ème param pas défini la couleur sera soit normal, soit couleur de PvP */
native void rp_ClientSendToSpawn(int client, bool nearest = false);					/* Téléporte un joueur à un spawn aléatoire. Si "nearest" est vrai. Il s'agit du spawn le plus prêt d'ou le joueur se trouve */
native void rp_ClientResetSkin(int client);									/* Remet le skin classique d'un joueur */
native void rp_ClientGiveKnife(int client);									/* Retire, et remet le couteau d'un joueur. Utile pour rafraichir son écran, ou quand il sort d'une voiture... */
native void rp_ClientReveal(int client);										/* Si le joueur est invisible, le rend visible */
native void rp_ClientDrawWeaponMenu(int client, int ent, bool steal);					/* Affiche le menu de selection d'arme. Pour police, justice, ou crochetage mafia */
// ----------------------------------------------------------------------------
native int rp_GetPlayerZoneAppart(int client); 									/* Numéro de l'appartement: Uniquement si on se trouve dedans... */
native int rp_GetPlayerZone(int client, float cache = 0.25); 						/* Numéro de la zone actuelle. */
native int rp_GetZoneBit(int client, float cache = 300.0);							/* Récupére une option sur une zone. val & BITZONE_BLOCKSTEAL --> On ne peut pas voler dans cette zone */
// ----------------------------------------------------------------------------
native int rp_GetRandomCapital(int jobID);									/* Prend un job au hasard. Plus il ya d'argent dans ce capital, plus ses chances d'être choisis est élevé */
native int rp_GetJobCapital(int jobID);										/* Valeur d'un capital */
native int rp_SetJobCapital(int jobID, int amount);								/* Définir un capital */
// ----------------------------------------------------------------------------
native int rp_GetDoorID(int ent); // return doorID								/* Récupére le numéro unique d'une porte. Appelé doorID */
native bool rp_GetClientKeyDoor(int client, int doorID);								/* Le joueur a-t-il la clé de la porte ? */
native void rp_SetDoorLock(int doorID, bool status); 								/* Verouille ou déverouille un doorID */
native void rp_ClientOpenDoor(int client, int doorID, bool status);					/* Le joueur ouvre, ou referme la porte. Ne fonctionne pas si la porte est lockée. TODO: Vérif s'il fait un doorID ou entID */
// ----------------------------------------------------------------------------
native void rp_SetClientWeaponSkin(int client, int wepID);							/* Définir le skin d'une arme par rapport au chois perso d'un joueur */
native void rp_SetWeaponGroupID(int wepID, int groupID);							/* Défini le numéro de groupe d'une arme. cf rp_GetClientGroupID */
native void rp_SetWeaponBallType(int wepID, enum_ball_type typeID);					/* Défini le type de balle d'une arme */
native void rp_SetClientKnifeType(int client, enum_ball_type typeID);					/* Défini le type de couteau qu'un joueur porte... (Incendiaire, poison, para, etc) */
native enum_ball_type rp_GetWeaponBallType(int wepID);							/* Quel est le type de balle d'une arme */
native enum_ball_type rp_GetClientKnifeType(int client);							/* Quel est le type de couteau d'un joueur */
native bool rp_GetWeaponStorage(int wepID);									/* L'arme vient-elle de l'armurerie police ? */
native void rp_SetWeaponStorage(int wepID, bool value);							/* Définir que l'arme vient de l'armurerie police */
native int rp_GetWeaponGroupID(int wepID);									/* Récupère le groupID d'une arme */
typedef GrenadeFunction = function void (int client, int entity);						/* Créer une grenade. Les 2 callback fctExplode et fctThrow sont appelé. Duration = durée avant que le fctExplode soit appelé*/
native int rp_CreateGrenade(int client, const char[] name, const char[] model, GrenadeFunction fctThrow, GrenadeFunction fctExplode, float duration);
// ----------------------------------------------------------------------------
native void rp_GetWeaponSkinData(int skinID, skin_data typeID, char[] str, int length);		/* Récupère les données de la liste des skins d'arme */
native void rp_GetLocationData(int zoneID, location_type typeID, char[] str, int length);		/* Récupère les données d'une position (spawn, jail)*/
native void rp_GetZoneData(int zoneID, zone_type typeID, char[] str, int length);			/* Récupère les données d'une zone banque, police, hosto... */
native void rp_GetJobData(int jobID, rp_job_type typeID, char[] str, int length);			/* Récupère les données d'un job */
native void rp_GetGroupData(int groupID, rp_group_type typeID, char[] str, int length);			/* Récupère les données d'un group */
native void rp_GetItemData(int itemID, rp_item_type typeID, char[] str, int length);		/* Récupère les données d'un item */
native int rp_GetBuildingData(int ent, building_prop_data typeID);					/* Récupère les données d'une constuction. Attention utilise un entier*/
native void rp_SetBuildingData(int ent, building_prop_data typeID, int data);				/* Définir les données d'une constuction. Attention utilise un entier*/
// ----------------------------------------------------------------------------
native void rp_ScheduleEntityInput(int entity, float time, char[] input);				/* Programme un input dans le futur. cf: https://developer.valvesoftware.com/wiki/Inputs_and_Outputs */
// ----------------------------------------------------------------------------
native Handle rp_GetDatabase();											/* Récupère un pointeur sur la DB */
native Handle rp_CreateSellingMenu();										/* Récupère un pointeur sur le menu de vente... cf... Je sais plus quel job. */
// ----------------------------------------------------------------------------
native void rp_ClientRemoveProp(int client, int target, int item_id);					/* Supprime un prop. Rembourse item_id si le target ne peut pas être supprimé */
// ----------------------------------------------------------------------------
native void rp_GetDate(char[] str, int length);
native void rp_GetTime(int& hour, int& minutes);
// ----------------------------------------------------------------------------
native bool rp_ClientCanDrawPanel(int client);
native void rp_SendPanelToClient(Handle panel, int client, float duration);
typedef QuestFctInit = function bool (int client);
typedef QuestFct = function void (int objectiveID, int client);
public void QUEST_NULL(int objectiveID, int client) {
}
native void rp_QuestStepComplete(int client, int objectiveID);
native int rp_RegisterQuest(char uniqID[32], char name[64], quest_type_type type, QuestFctInit CanStart);
native void rp_QuestAddStep(int questID, int stepID, QuestFct start, QuestFct frame, QuestFct abort, QuestFct done);
// ----------------------------------------------------------------------------

#define ACCESS_DENIED(%1)	CPrintToChat(%1, "{lightblue}[TSX-RP]{default} Vous n'avez pas accès à cette commande.");	return Plugin_Handled
#define ITEM_CANCEL(%1,%2)	rp_ClientGiveItem(%1,%2); rp_SetClientFloat(%1, fl_CoolDown, 0.05)

#define BITZONE_DEFAULT		(0)		// https://www.ts-x.eu/shared_public/bit.html
#define BITZONE_PEACEFULL	(1<<0)
#define BITZONE_PVP		(1<<1)
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
#define BITZONE_PERQUIZ		(1<<25)

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
	b_HasShoes,
	b_SpawnToGrave,
	b_Pissing,
	b_ChiruRegen,
	b_ChiruMaxHeal,
	b_ChiruKevlar,
	b_ChiruYeux,
	b_IsAFK,
	b_IsMuteGlobal,
	b_IsMuteLocal,
	b_IsMuteVocal,
	b_IsNoPyj,
	
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
	i_Plant,
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
	i_TimeAFK_today,
	i_TimeAFK_total,
	i_MarriedTo,
	
	i_ItemCount,
	i_ItemBankCount,

	i_LastAgression,
	
	
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
	BD_item_id,
	
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
	ball_type_revitalisante,
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

enum rp_group_type {
	group_type_name = 0,
	
	group_type_chef,
	group_type_own_chef,
	
	group_type_capital, 
	group_type_color,
	group_type_buy,
	group_type_skin,
	
	group_type_max
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
enum location_type {
	location_type_base = 0,
	location_type_message,
	location_type_origin_x,
	location_type_origin_y,
	location_type_origin_z,
	
	location_type_map,
	location_type_max
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
	car_battery,
	
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
enum quest_type_type {
	quest_story,
	quest_daily,
	quest_weekly
}

#include <rp_tools.inc>
