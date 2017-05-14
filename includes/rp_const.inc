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
#if defined _rp_const_included_
  #endinput
#endif
#define _rp_const_included_

#define __LAST_REV__			"6.6 - Phoénix"

//#define DEBUG
#define MAX_LOCATIONS			150
#define MAX_ZONES				310
#define MAX_GROUPS				150
#define MAX_AREA_DIST			500
#define CONTACT_DIST			150
#define STEAL_MAX				500
#define STEAL_TIME				30.0
#define RESPAWN_TIME			20.0
#define DRUG_DURATION			90.0
#define MENU_TIME_DURATION		60
#define TP_CD_DURATION 			30.0
#define TP_CHANNEL_DURATION		5.0
#define	MARCHEMAFIA_PC			50
#define MARCHEMAFIA_POS			view_as<float>({-400.0, 835.0, -2120.0})
#define MAIRIE_ZONE				259
#define MAIRIE_BUR_ZONE			308
#define MAIRIE_POS				{522.0, 2002.0, -2135.0}

// DO NOT EDIT BELLOW.
#define WORLDINDEX				0				
#define MAX_ENTITIES			2049
#define EF_NODRAW 				32
#define ITEMDRAW_SPACER_NOSLOT ((1<<1)|(1<<3))


// Maths:
#define PI		3.1415926
#if defined FLT_MAX
#else
	#define FLT_MAX	2147483647.0
#endif
#define FLT_MIN -FLT_MAX


// Models:
#define MODEL_ATM 			"models/DeadlyDesire/props/atm01.mdl"
#define MODEL_CASH			"models/props_mall/cash_register.mdl"
#define MODEL_CASHBIG		"models/props_interiors/copymachine01.mdl"
#define MODEL_KNIFE			"models/weapons/w_knife_flip.mdl"
#define MODEL_GRAVE 		"models/props/de_inferno/church_ornament_01.mdl"
#define MODEL_PRISONNIER	"models/player/custom_player/legacy/sprisioner/sprisioner.mdl"
#define MODEL_BARRIERE		"models/props_fortifications/police_barrier001_128_reference.mdl"
#define MODEL_TABLE1 		"models/props/de_boathouse/table_drafting01.mdl"
#define MODEL_TABLE2		"models/props/de_boathouse/table_drafting02.mdl"
#define	MODEL_PANNEAU		"models/props/de_cbble/cobble_sign02.mdl"
#define MODEL_PLANT_0		"models/custom_prop/marijuana/marijuana_0.mdl"
#define MODEL_PLANT_1		"models/custom_prop/marijuana/marijuana_1.mdl"
#define MODEL_PLANT_2		"models/custom_prop/marijuana/marijuana_2.mdl"
#define MODEL_PLANT_3		"models/custom_prop/marijuana/marijuana_3.mdl"
#define MODEL_HEALBOX		"models/pg_props/pg_hospital/pg_ekg.mdl"
#define MODEL_KEVLARBOX 	"models/props/cs_office/box_office_indoor_32.mdl"
#define MODEL_GRAVE 		"models/props/de_inferno/church_ornament_01.mdl"

// Items:
#define ITEM_PIEDBICHE		1
#define ITEM_KITCROCHTAGE	2
#define ITEM_KITEXPLOSIF	3
#define ITEM_MANDAT			4
#define ITEM_FITNESS		30
#define ITEM_TICKETID		76
#define ITEM_CADEAU			132
#define	ITEM_GPS			144
#define	ITEM_REPAIR			176
#define	ITEM_PARTICULES		181
#define	ITEM_NEONS			193
#define	ITEM_JETONROUGE		276
#define ITEM_JETONBLEU		286
#define ITEM_CHEQUE			304

// Zone:
#define	METRO_PAIX		60
#define METRO_STATION	61
#define METRO_INNO		62
#define METRO_BELMON	201

#define ZONE_HALLDEALER	95
#define	ZONE_VILLA2		156
#define	ZONE_CABINE 	173
#define ZONE_RESPAWN	190
#define	ZONE_BUNKER		194
#define ZONE_VILLA		245

#define TRIBUJAIL_1	287
#define TRIBUJAIL_2	288
#define TRIBUNAL_1	289
#define TRIBUNAL_2	290
#define BUREAU_1   	291
#define BUREAU_2	292
#define JURRY_2		293

// PvP:
#define	FLAG_SPEED		280.0
#define	FLAG_POINT_MAX	150
#define FLAG_POINT_MIN	50
#define FLAG_MAX		10

#define ELO_FACTEUR_K	40.0
#define MAX_ANNOUNCES	32
#define ANNONCES_DELAY	12
#define	ANNONCES_VOLUME 0.33
