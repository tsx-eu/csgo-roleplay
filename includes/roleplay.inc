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

// ----------------------------------------------------------------------------
// Artisan:
forward int RP_CanClientCraftForFree(int client, int itemID);
forward void RP_ClientCraftOver(int client, int itemID);
// Dealer
forward void RP_On18thStealWeapon(int client, int victim, int weaponID);
forward void RP_OnClientMaxPlantCount(int client, int& max);
forward void RP_OnClientPiedBiche(int client, int type );
forward Action RP_ClientCanTP(int client);
forward void RP_OnMarcheNoireDealer(int client, int prix);
// Mafia
forward Action RP_CanClientStealItem(int client, int target);
forward void RP_OnClientWeaponPick(int client, int type);
forward void RP_OnMarcheNoireMafia(int client, int target, int victim, int itemID, int prix);
// Police:
forward void RP_OnClientTazedItem(int client, int reward);
forward Action RP_OnClientSendJail(int client, int target);
forward void RP_OnMarchePolice(int client, int prix, int realPrice);
// Technicien:
forward void RP_OnClientMaxMachineCount(int client, int& max);
// ----------------------------------------------------------------------------
enum rp_event {
	RP_PreTakeDamage,			     /* Le joueur recoit des dégats, quelques soit l'arme. Attention, n'est jamais appelé en zone EVENT */
	RP_PostTakeDamageWeapon,	 /* La détection d'arme a été faites. */
	RP_PostTakeDamageKnife,    /* La détection du couteau été faites. */

	RP_PreGiveDamage,          /* Le joueur inflige des dégats, quelques soit l'arme. Attention, n'est jamais appelé en zone EVENT */
	RP_PostGiveDamageWeapon,   /* La détection d'arme a été faites. */
	RP_PostGiveDamageKnife,    /* La détection du couteau été faites. */

	RP_PrePlayerPhysic,        /* Permet de modifier la physique d'un joueur. Utiliser return Plugin_Stop pour forcer les valeurs et ignorer toutes les autres. */
	RP_PostPlayerPhysic,       /* By-pass les zones en BITZONE_BLOCKCHIRU */

	RP_PreHUDColorize,		     /* Modifie la couleur de l'écran */
	RP_OnFrameSeconde,		     /* Appelé chaque seconde */
	RP_OnAssurance,			       /* Modifie l'assurance, est appelé à chaques fois que le serveur la recalcule */
	RP_OnPlayerSpawn,			     /* Lorsqu'un joueur respawn. Appelé après l'avoir TP Au bon endroit */
	RP_OnPlayerDead,           /* Un joueur meurt. Return Plugin_Handled pour cacher la mort des logs*/
	RP_OnPlayerKill,           /* Un joueur tue. Return Plugin_Handled pour cacher la mort des logs*/
	RP_OnPlayerBuild,          /* Un joueur utilise la commande /build */
	RP_OnPlayerUse,             /* Un joueur utilise la commande utiliser (touche E). */
	RP_OnPlayerCommand,        /* Un joueur execute une commande, /vol, /truc, /bidule. command ne contient ni de !, ni de /. */
	RP_OnPlayerSteal,          /* Un joueur execute le /vol */
	RP_OnPlayerZoneChange,     /* Un joueur change de zone */

	RP_OnPlayerHear,           /* Peut-il entendre un autre joueur ? */
	RP_PrePlayerTalk,          /* J'écris un message dans le chat  */
	RP_OnPlayerDataLoaded,     /* Quand le joueur a chargé */
	RP_OnPlayerSell,           /* Quand un joueur fait une vente */
	RP_OnPlayerHUD,            /* A chaque fois que le HUD à gauche se refresh */
	RP_OnPlayerCheckKey,	   /* A chaque vérification s'il a la clé */
	RP_OnResellWeapon,		   /* Revente d'arme au marché noire */

	RP_EventMax
}
typeset rp_event_enum {
	function Action(int victim, int attacker, float& damage); 			                   /* RP_PreTakeDamage  == return Plugin_Handled = aucun dégat */
	function Action(int victim, int attacker, float& damage, int wepID, float pos[3]); /* RP_PostTakeDamageWeapon */
	function Action(int victim, int attacker, float& damage);                          /* RP_PostTakeDamageKnife */

	function Action(int attacker, int victim, float& damage);                          /* RP_PreGiveDamage  == return Plugin_Handled = aucun dégat */
	function Action(int attacker, int victim, float& damage, int wepID, float pos[3]); /* RP_PostGiveDamageWeapon */
	function Action(int attacker, int victim, float& damage); 	                    	 /* RP_PostGiveDamageKnife */

	function Action(int client, float& speed, float& gravity); 	                       /* RP_PrePlayerPhysic == return Plugin_Stop pour forcer les valeurs et ignorer les autres plugins/hook*/
	function Action(int client, float& speed, float& gravity); 	                       /* RP_PostPlayerPhysic */
	function Action(int client, int color[4]); 					                               /* RP_PreHUDColorize == idem */
	function Action(int client);								                                       /* RP_OnFrameSeconde */
	function Action(int client, int& amount);						                               /* RP_OnAssurance */
	function Action(int client);							        	                               /* RP_OnPlayerSpawn */
	function Action(int victim, int attacker, float& respawn);	                       /* RP_OnPlayerDead == return Plugin_Handled = cacher des logs */
	function Action(int attacker, int victim, char weapon[64]);	                       /* RP_OnPlayerKill == return Plugin_Handled = cacher des logs */
	
	function Action(int client, float& cooldown);					                             /* RP_OnPlayerBuild */
	function Action(int client);								                                       /* RP_OnPlayerUse */
	function Action(int client, char[] command, char[] arg);		                       /* RP_OnPlayerCommand */
	function Action(int client, int target, float& cooldown);		                       /* RP_OnPlayerSteal */
	function Action(int client, int newZoneID, int oldZoneID);	                       /* RP_OnPlayerZoneChange */
	function Action(int client, int target, float& dist);				                       /* RP_OnPlayerHear Est-ce que client peut entendre target ? */
	function Action(int client, char[] message, int length, bool local);	             /* RP_PrePlayerTalk */
	function Action(int client);								                                       /* RP_OnPlayerDataLoaded */
	function Action(int client, int money);					                         	         /* RP_OnPlayerSell */
	function Action(int client, char[] szHUD, const int maxSize);			                 /* RP_OnPlayerHUD */
	function Action(int client, int doorID, int lockStatus);											/* RP_OnPlayerCheckKey */
	function Action(int client, int weaponID, int price);									/* RP_OnResellWeapon */
};
/**
 * Hook un évenement d'un joueur
 * @param  int           client        le joueur
 * @param  rp_event      eventID       l'id de l'evenement
 * @param  rp_event_enum hook          la fonction
 * @param  float         duration=-1.0 la durée. -1 = infini
 */
native bool rp_HookEvent(int client, rp_event eventID, rp_event_enum hook, float duration=-1.0);
/**
 * Retire un hook créer par rp_HookEvent
 * @param  int           client        le joueur
 * @param  rp_event      eventID       l'id de l'evenement
 * @param  rp_event_enum hook          la fonction à ne plus utiliser
 */
native bool rp_UnhookEvent(int client, rp_event eventID, rp_event_enum hook);
native Handle rp_GetForwardHandle(int client, rp_event eventID);
// ----------------------------------------------------------------------------
//                                                 Getter et Setter sur joueur
// ----------------------------------------------------------------------------
/**
 * Récupère la propriétée entier d'un joueur
 * @param  int           client        le joueur
 * @param  int_user_data prop          la variable
 * @return int      La valeur
 */
native int rp_GetClientInt(int client, int_user_data prop);
/**
 * Récupère la propriétée booléen d'un joueur
 * @param  int           client        le joueur
 * @param  bool_user_data prop         la variable
 * @return bool     La valeur
 */
native bool rp_GetClientBool(int client, bool_user_data prop);
/**
 * Récupère la propriétée flotant d'un joueur
 * @param  int           client        le joueur
 * @param  float_user_data prop         la variable
 * @return float     La valeur
 */
native float rp_GetClientFloat(int client, float_user_data prop);
/**
 * Récupérer un attribu chaine de caractère d'un joueur
 * @param  int          client        Le joueur
 * @param  sz_user_data prop          La variable
 * @param  char[]       value         La valeur
 * @param  int          length        La longueur max
 */
native void rp_GetClientString(int client, sz_user_data prop, char[] value, int length);
/**
 * Récupère la propriétée "stat" d'un joueur
 * @param  int           client        Le joueur
 * @param  int_stat_data prop          La variable
 * @return int               La valeur
 */
native int rp_GetClientStat(int client, int_stat_data prop);
/**
 * Modifie la propriétée entier d'un joueur
 * @param  int           client        Le joueur
 * @param  int_user_data prop          La variable
 * @param  int           value         La valeur
 */
native void rp_SetClientInt(int client, int_user_data prop, int value);
/**
 * Modifie la propriétée boléan d'un joueur
 * @param  int            client        Le joueur
 * @param  bool_user_data prop          La variable
 * @param  bool           value         La valeur
 * @return                [description]
 */
native void rp_SetClientBool(int client, bool_user_data prop, bool value);
/**
 * Modifie la propriétée flotant d'un joueur
 * @param  int             client        Le joueur
 * @param  float_user_data prop          La variable
 * @param  float           value         La valeur
 */
native void rp_SetClientFloat(int client, float_user_data prop, float value);
/**
 * Modifie la propriétée chaine de caractère d'un joueur
 * @param  int          client        Le joueur
 * @param  sz_user_data prop          La variable
 * @param  char[]       value         La valeur
 * @param  int          length        La taille maximum du string
 */
native void rp_SetClientString(int client, sz_user_data prop, char[] value, int length);
/**
 * Modifie la propriétée "stat" d'un joueur
 * @param  int           client        Le joueur
 * @param  int_stat_data prop          La variable
 * @param  int           value         La valeur
 */
native void rp_SetClientStat(int client, int_stat_data prop, int value);
// ----------------------------------------------------------------------------
//                                                          JobID + GroupID
// ----------------------------------------------------------------------------
/**
 * Récupérer le numéro du job auquel le joueur appartient. cf: https://www.ts-x.eu/node/apidoc/#api-Jobs-GetJobs
 * @param  int client        Le joueur
 * @return int  JobID
 */
native int rp_GetClientJobID(int client);
/**
 * Récupérer le numéro du groupe auquel le joueur appartient. cf: https://www.ts-x.eu/node/apidoc/#api-Groups-GetGroups
 * @param  {[type]} int client        Le joueur
 * @return int     GroupID
 */
native int rp_GetClientGroupID(int client);
/**
 * Augmenter la chance d'un joueur
 * @param  {[type]} int client        Le joueur
 */
native void rp_IncrementLuck(int client);
// ----------------------------------------------------------------------------
//                                                           rp_Is
// ----------------------------------------------------------------------------
/**
 * L'entité est-elle en zone PvP?
 * @param  {[type]} int entity        L'entité
 * @return bool   Vrai si elle est en zone pvp
 */
native bool rp_IsInPVP(int entity);
/**
 * Le joueur est-il proche de l'entité
 * @param  {[type]} int   client        Le joueur
 * @param  {[type]} int   entity        L'entité
 * @param  {[type]} bool  tresProche    =             false à vrai, signifie que le joueur doit coller  et viser cette entité
 * @param  {[type]} float cache         =             0.25  Durée de mise en cache
 * @return bool       Vrai si le joueur est proche
 */
native bool rp_IsEntitiesNear(int client, int entity, bool tresProche = false, float cache = 0.25);
/**
 * Le joueur a-t-il terminé le tutorial?
 * @param  {[type]} int client        Le joueur
 * @return bool     Vrai s'il a terminé le tutorial, faux s'il est dedans
 */
native bool rp_IsTutorialOver(int client);
/**
 * Le joueur peut-il construire là ou il est?
 * @param  {[type]} int  client        Le joueur
 * @param  {[type]} bool silent        =             false Afficher un message d'erreur
 * @return bool     Vrai s'il peut construire
 */
native bool rp_IsBuildingAllowed(int client, bool silent = false);
/**
 * Le joueur est-il chanceux
 * @param  {[type]} int client        Le joueur
 * @return bool     Vrai s'il est chanceux
 */
native bool rp_IsClientLucky(int client);
/**
 * Le joueur est-il nouveau?
 * @param  {[type]} int client        Le joueur
 * @return bool     Vrai si le joueur à jouer moins de 20 heures sur le serveur
 */
native bool rp_IsClientNew(int client);
/**
 * Le joueur peut-il voir la cible?
 * @param  {[type]} int client        Le joueur
 * @param  {[type]} int target        La cible
 * @return bool     Vrai s'il peut la voir
 */
native bool rp_IsTargetSeen(int client, int target);
/**
 * Le joueur peut-il entendre la cible?
 * @param  {[type]} int client        Le joueur
 * @param  {[type]} int target        La cible
 * @return bool     Vrai s'il peut l'entendre
 */
native bool rp_IsTargetHear(int client, int target);
/**
 * Est-ce que l'entité est une porte "rp"?
 * @param  {[type]} int ent           L'entité
 * @return bool    Vrai si c'est une porte connue du serveur
 */
native bool rp_IsValidDoor(int ent);
/**
 * Est-ce que l'entité est prise en +force?
 * @param  {[type]} int entity        L'entité
 * @return  bool Vrai si elle est prise en +force
 */
native bool rp_IsGrabbed(int entity);
/**
 * Est-ce qu'il fait nuit?
 * @return bool Vrai s'il fait nuit
 */
native bool rp_IsNight();
// ----------------------------------------------------------------------------
//                                                           Véhicule
// ----------------------------------------------------------------------------
/**
 * Est-ce que l'entité est un véhicule "rp"?
 * @param  {[type]} int entity        L'entité
 * @return bool     Vrai si c'est un véhicule
 */
native bool rp_IsValidVehicle(int entity);
/**
 * Définir les clés d'un joueur d'un véhicules
 * @param  {[type]} int  client        Le joueur
 * @param  {[type]} int  vehicleID     Le véhicule
 * @param  {[type]} bool status=false  S'il a la clé
 */
native void rp_SetClientKeyVehicle(int client, int vehicleID, bool status=false);
/**
 * Le joueur a-t-il la clé d'un véhicule?
 * @param  {[type]} int client        Le joueur
 * @param  {[type]} int vehicleID     Le véhicules
 * @return bool     Vrai s'il a la clé
 */
native bool rp_GetClientKeyVehicle(int client, int vehicleID);
/**
 * Sortir un joueur du véhicule. Peut échouer s'il y a pas de place
 * @param  {[type]} int  client        Le joueur
 * @param  {[type]} int  vehicleID     Le véhicule
 * @param  {[type]} bool forced=false  Force le joueur à sortir, même s'il est bloqué
 */
native void rp_ClientVehicleExit(int client, int vehicleID, bool forced=false);
/**
 * Place le joueur en tant que conducteur d'un véhicule
 * @param  {[type]} int  client        Le joueur
 * @param  {[type]} int  vehicleID     L'ID du véhicule
 * @param  {[type]} bool force=false   Doit-on TP le joueur vers la voiture
 */
native void rp_SetClientVehicle(int client, int vehicleID, bool force=false);
/**
 * Le joueur est-il conducteur d'une voiture?
 * @param  {[type]} int client        Le joueur
 * @return int     vehicleID>0 Le véhicule, sinon pas de véhicule.
 */
stock int rp_GetClientVehicle(int client) {
  return GetEntPropEnt(client, Prop_Send, "m_hVehicle");
}
/**
 * Sortir le passager du véhicule.
 * @param  {[type]} int  client        Le joueur
 * @param  {[type]} int  vehicleID     Le véhicule
 */
native void rp_ClientVehiclePassagerExit(int client, int vehicleID);
/**
 * Le joueur est-il passagé d'une voiture?
 * @param  {[type]} int client        Le joueur
 * @return int     vehicleID>0 Le véhicule, sinon pas de véhicule.
 */
native int rp_GetClientVehiclePassager(int client);
/**
 * Place le joueur en tant que passager d'un véhicule
 * @param  {[type]} int client        Le joueur
 * @param  {[type]} int vehicleID     Le véhicule
 * @return  bool    Vrai si le joueur a été correctement placé.
 */
native bool rp_SetClientVehiclePassager(int client, int vehicleID);
/**
 * Définir une propriétée d'un véhicule
 * @param  {[type]} int      vehicleID     le véhicule
 * @param  {[type]} car_data typeID        la propriétée
 * @param  {[type]} int      value         la valeur
 */
native void rp_SetVehicleInt(int vehicleID, car_data typeID, int value);
/**
 * Récupère la propriétée d'un véhicule
 * @param  {[type]} int      vehicleID     Le véhicule
 * @param  {[type]} car_data typeID        La propriétée
 * @return int      La valeur
 */
native int rp_GetVehicleInt(int vehicleID, car_data typeID);
/**
 * Crée un véhicule
 * @param  {[type]} float  origin[3]     coordonnée
 * @param  {[type]} float  angle[3]      angle
 * @param  {[type]} char[] model         Le model doit être mis en cache avant d'appeler cette fonction.
 * @param  {[type]} int    skin          Le numéro du skin
 * @param  {[type]} int    client        =             0 Le propriétaire.
 * @return {[type]}        retourne le numéro de la voiture
 */
native int rp_CreateVehicle(float origin[3], float angle[3], char[] model, int skin, int client = 0);
// ----------------------------------------------------------------------------
/**
 * Définir une propriétée d'un appartement
 * @param  {[type]} int               appartID      Le numéro de l'appart, de 1 à 200
 * @param  {[type]} type_appart_bonus typeID        La propriétée
 * @param  {[type]} int               value         sa valeur
 */
native void rp_SetAppartementInt(int appartID, type_appart_bonus typeID, int value);
/**
 * Récupérer une propriétée d'un appartement
 * @param  {[type]} int               appartID      Le numéro de l'appart, de 1 à 200
 * @param  {[type]} type_appart_bonus typeID        La propriétée
 * @return {[type]}                   Sa valeur
 */
native int rp_GetAppartementInt(int appartID, type_appart_bonus typeID);
/**
 * Définir si un joueur a la clé d'un appartement
 * @param  {[type]} int  client        Le joueur
 * @param  {[type]} int  appartID      Le numéro de l'appart, de 1 à 200
 * @param  {[type]} bool status=false  Vrai il l'a, faux il a pas la clé
 * @return {[type]}      [description]
 */
native void rp_SetClientKeyAppartement(int client, int appartID, bool status=false);
/**
 * Le joueur a t-il la clé d'un appartement?
 * @param  {[type]} int client        Le joueur
 * @param  {[type]} int appartID      Le numéro de l'appart, de 1 à 200
 * @return {[type]}     Vrai, s'il a la clé.
 */
native bool rp_GetClientKeyAppartement(int client, int appartID);
// ----------------------------------------------------------------------------
native void rp_Effect_PropExplode(int entityID, bool tazer = false);					/* Explose un props, s'il est piégé */
native void rp_Effect_Smoke(int client, float duration = 30.0);						/* Petit effect de fumée de cigarette */
native void rp_Effect_VisionTrouble(int client, float duration = 30.0);					/* Trouble la vision d'un joueur */
native void rp_Effect_ShakingVision(int client, float duration = 30.0);					/* Fait trembler la vue d'un joueur */
native int rp_Effect_Particle(int entity, char[] effect, float duration=0.0001);		/* Affiche une particule */
native int rp_Effect_ParticlePath(int entity, char[] effect, const float src[3], const float angle[3], const float dest[3]); /* Affiche une particule à un endroit précis */
native void rp_Effect_Tazer(int client, int target);								/* Affiche un trait du tazer entre un joueur et une cible */
native int rp_Effect_SpawnMoney(float origin[3], bool away = false, bool high = false);						/* Spawn des billets 20-50$. High = true -> 200-500$. Penser à retirer la thune d'un capital */
native void rp_Effect_BeamBox(int client, int target = -1, float origin[3] = NULL_VECTOR, int red = 0, int green = 255, int blue = 0); /* Affiche un lazer tracant entre un joueur et une cible */
native void rp_Effect_LoadingBar(char[] str, int length, float percent);
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
native int rp_GetZoneFromPoint(float pos[3]);
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
native void rp_GetLocationData(int zoneID, location_type typeID, char[] str, int length);		/* Récupère les données d'une position (spawn, jail)*/
native void rp_GetZoneData(int zoneID, zone_type typeID, char[] str, int length);			/* Récupère les données d'une zone banque, police, hosto... */
native void rp_GetJobData(int jobID, rp_job_type typeID, char[] str, int length);			/* Récupère les données d'un job */
native void rp_GetGroupData(int groupID, rp_group_type typeID, char[] str, int length);			/* Récupère les données d'un group */
native void rp_GetItemData(int itemID, rp_item_type typeID, char[] str, int length);		/* Récupère les données d'un item */
native int rp_GetBuildingData(int ent, building_prop_data typeID);					/* Récupère les données d'une constuction. Attention utilise un entier*/
native void rp_SetBuildingData(int ent, building_prop_data typeID, int data);				/* Définir les données d'une constuction. Attention utilise un entier*/
// ----------------------------------------------------------------------------
native void rp_ScheduleEntityInput(int entity, float time, char[] input);				/* Programme un input dans le futur. cf: https://developer.valvesoftware.com/wiki/Inputs_and_Outputs */
native int rp_GetEntityCount();
// ----------------------------------------------------------------------------
native Handle rp_GetDatabase();											/* Récupère un pointeur sur la DB */
native Handle rp_CreateSellingMenu();										/* Récupère un pointeur sur le menu de vente... cf... Je sais plus quel job. */
// ----------------------------------------------------------------------------
native void rp_GetDate(char[] str, int length);
native void rp_GetTime(int& hour, int& minutes);
native void rp_GetServerString(rp_serv typeID, char[] str, int length);
native void rp_SetServerString(rp_serv typeID, char[] str, int length);
// ----------------------------------------------------------------------------
native int rp_SetCaptureInt(rp_capture_zone zoneID, int value);
native int rp_GetCaptureInt(rp_capture_zone zoneID);
native int rp_GetClientPvPBonus(int client, rp_capture_zone typeID);					/* Est-ce qu'un joueur à le droit à un bonus de type PVP ? typeID==> cap_nuclear, cap_tower, cap_villa */
// ----------------------------------------------------------------------------
native bool rp_ClientCanDrawPanel(int client);
native void rp_SendPanelToClient(Handle& panel, int client, float duration);
typedef QuestFctInit = function bool (int client);
typedef QuestFct = function void (int objectiveID, int client);
public void QUEST_NULL(int objectiveID, int client) { }
native void rp_QuestStepComplete(int client, int objectiveID);
native void rp_QuestStepFail(int client, int objectiveID);
native int rp_RegisterQuest(char uniqID[32], char name[64], quest_type_type type, QuestFctInit CanStart);
native void rp_QuestAddStep(int questID, int stepID, QuestFct start, QuestFct frame, QuestFct abort, QuestFct done);
native int rp_QuestCreateInstance(int client, char model[PLATFORM_MAX_PATH], float vecPos[3]);
native void rp_QuestSetGroupCreationFct(int questID, QuestFctInit fwd);
native void rp_QuestStart(int client, int questID);
native void rp_QuestCancel(int client, int questID);
native bool rp_QuestComplete(int client, char uniqID[32], bool status);
// ----------------------------------------------------------------------------
native int rp_GetClientTarget(int client, float dst[3] = {0.0, 0.0, 0.0});
native int rp_GetClientSSO(int client, char[] sso, int length);
// ----------------------------------------------------------------------------
native void rp_ClientFloodIncrement(int client, int target, fd_user_data type, float cooldown);
native bool rp_ClientFloodTriggered(int client, int target, fd_user_data type);
// ----------------------------------------------------------------------------
enum BM_Int {
	BM_Owner = 0,
	BM_Prix,
	BM_Munition,
	BM_Chargeur,
	BM_PvP,
	BM_Type,
	BM_Max
}
native int rp_WeaponMenu_GetOwner(int wepID);
native DataPack rp_WeaponMenu_Create();
native void rp_WeaponMenu_Clear(DataPack& hBuyMenu);
native void rp_WeaponMenu_Reset(DataPack hBuyMenu);
native void rp_WeaponMenu_SetPosition(DataPack hBuyMenu, DataPackPos position);
native DataPackPos rp_WeaponMenu_GetPosition(DataPack hBuyMenu);
native DataPackPos rp_WeaponMenu_GetMax(DataPack hBuyMenu);
native bool rp_WeaponMenu_Add(DataPack hBuyMenu, int weaponID, int owner);
native void rp_WeaponMenu_Delete(DataPack& hBuyMenu, DataPackPos pos);
native void rp_WeaponMenu_Get(DataPack hBuyMenu, DataPackPos pos, char weapon[65], int data[BM_Max]);
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

#define MAX_ITEMS	311
#define MAX_JOBS	230

// ----------------------------------------------------------------------------
enum bool_user_data {
	b_isConnected,	// Money,bank, item
	b_isConnected2, // Success
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
	b_Lube,
	b_Map,
	b_CAPSLOCK,
	b_NoDonateurSkin,
	b_AdminHeal,
	b_HasMail,
	b_HasGrave,
	b_HasShoes,
	b_SpawnToGrave,
	b_Pissing,
	b_IsAFK,
	b_IsMuteGlobal,
	b_IsMuteLocal,
	b_IsMuteVocal,
	b_IsMuteEvent,
	b_IsMuteGive,
	b_IsMutePvP,
	b_IsMuteKILL,
	b_IsNoPyj,
	b_HasProtImmu,
	b_HasQuest,
	b_IsSearchByTribunal,
	b_SpawnToMetro,
	b_SpawnToTribunal,
	b_SpawnToTueur,
	b_HasVilla,
	b_CanSort,
	b_MayUseUltimate,
	ch_Force,
	ch_Speed,
	ch_Jump,
	ch_Regen,
	ch_Heal,
	ch_Kevlar,
	ch_Yeux,
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
	i_LastVolTime,
	i_LastVolAmount,
	i_LastVolTarget,
	i_LastVolVehicle,
	i_LastVolVehicleTime,
	i_BurnedBy,
	i_JailledBy,
	i_Cryptage,
	i_LastTime,
	i_SpawnAmount,
	i_jailTime_Last,
	i_jailTime_Reason,
	i_Perquiz,
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
	i_Mask,
	i_MaskCount,
	i_AppartCount,
	i_LastKillTime,
	i_AddToPay,
	i_TimeAFK,
	i_TimeAFK_today,
	i_TimeAFK_total,
	i_MarriedTo,

	i_ItemCount,
	i_ItemBankCount,
	i_ItemCountSaved,

	i_LastAgression,
	i_LastShot,
	i_LastAmende,
	i_LastAmendeBy,

	i_Avocat,

	i_ArtisanXP,
	i_ArtisanLevel,
	i_ArtisanPoints,
	i_FakeClient,
	
	i_KillMonth,
	i_DeathMonth,
	i_Kill31Days,
	i_Death31Days,

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
	Float:fl_RespawnTime,
	Float:fl_ArtisanFatigue,
	Float:fl_LastPoison,
	Float:fl_LastCrochettage,

	fl_udata_max
};
enum sz_user_data {
	String:sz_Skin,

	sz_udata_max
};
enum fd_user_data {
	fd_flash,
	fd_menotte,
	fd_fouet,
	fd_vol,
	fd_job,
	fd_kidnapping,

	fd_udata_max
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
	BD_FromBuild,
	
	building_prop_data_max
};
enum rp_capture_zone {
	cap_bunker =  0,
	cap_villa,
	cap_disableItem,
	cap_pvpRow,
	capture_max
};
enum enum_ball_type {
	ball_type_none,
	ball_type_fire,
	ball_type_caoutchouc,
	ball_type_poison,
	ball_type_vampire,
	ball_type_antikevlar,
	ball_type_paintball,
	ball_type_reflexive,
	ball_type_explode,
	ball_type_revitalisante,
	ball_type_nosteal,
	ball_type_notk,
	ball_type_braquage,
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
	item_type_taxes,
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
enum rp_serv {
	villaOwnerID = 0,
	villaOwnerName,
	lotoCagnotte,

	rp_serv_max
};

enum rp_group_type {
	group_type_name = 0,

	group_type_chef,
	group_type_own_chef,

	group_type_capital,
	group_type_color,
	group_type_buy,
	group_type_skin,
	group_type_tag,

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
	zone_type_private,

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
	car_light = 0,
	car_light_r,
	car_light_g,
	car_light_b,
	car_boost,
	car_thirdperson_id,
	car_klaxon,
	car_owner,
	car_item_id,
	car_health,
	car_awayTick,
	car_maxPassager,
	car_battery,
	car_particle,
	car_donateur,
	
	car_data_max,
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
	quest_group
}
enum int_stat_data {
	i_nostat = 0,
	i_Money_OnConnection,

	i_MoneyEarned_Pay, // Salaire + vita + appart
	i_MoneyEarned_Phone, // Telephone + valeur des items ramassés
	i_MoneyEarned_Mission, // Missions + valeur des items ramassés
	i_MoneyEarned_Sales, // Ventes ou Vols
	i_MoneyEarned_Pickup,
	i_MoneyEarned_CashMachine,
	i_MoneyEarned_Give,

	i_MoneySpent_Fines,
	i_MoneySpent_Shop,
	i_MoneySpent_Give,
	i_MoneySpent_Stolen,

	i_Vitality_OnConnection,

	i_LotoSpent,
	i_LotoWon,

	i_DrugPickedUp,

	i_Kills,
	i_Deaths,

	i_ItemUsed,
	i_ItemUsedPrice,

	i_PVP_OnConnection,

	i_TotalBuild,

	i_RunDistance,

	i_JobSucess, // Mafia 18th Tueur
	i_JobFails,


	i_LastDeathTimestamp,
	i_LastKillTimestamp,

	i_uStat_nosavemax,

	i_uStat_Save = 100,

	i_S_MoneyEarned_Pay,
	i_S_MoneyEarned_Phone,
	i_S_MoneyEarned_Mission,
	i_S_MoneyEarned_Sales,
	i_S_MoneyEarned_Pickup,
	i_S_MoneyEarned_CashMachine,
	i_S_MoneyEarned_Give,

	i_S_MoneySpent_Fines,
	i_S_MoneySpent_Shop,
	i_S_MoneySpent_Give,
	i_S_MoneySpent_Stolen,

	i_S_LotoSpent,
	i_S_LotoWon,

	i_S_DrugPickedUp,

	i_S_Kills,
	i_S_Deaths,

	i_S_ItemUsed,
	i_S_ItemUsedPrice,

	i_S_TotalBuild,

	i_S_RunDistance,

	i_S_JobSucess,
	i_S_JobFails,

	i_uStat_max
};

#include <rp_tools.inc>
