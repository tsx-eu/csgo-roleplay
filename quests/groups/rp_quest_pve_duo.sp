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
#include <sdktools>
#include <cstrike>
#include <colors_csgo>  // https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>      	// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#pragma newdecls required
#include <roleplay.inc>   // https://www.ts-x.eu
#include <pve.inc>
#include <phun_nav.inc>
#include <custom_weapon_mod.inc>

#define		QUEST_UNIQID   	"pve-duo"
#define		QUEST_NAME      "PVE: Duo - BETA"
#define		QUEST_TYPE     	quest_group
#define		QUEST_ARENA		311

#define		REQUIRED_PLAYER	2
#define 	QUEST_MID		view_as<float>({3270.0, -10705.0, -7703.0})
#define		QUEST_BONUS		view_as<float>({2688.0, -9573.0, -7828.0})

char g_szSpawnQueue[][][PLATFORM_MAX_PATH] = {
	{"1", "zombie"}, {"2", "skeleton_arrow"}, {"3", "skeleton"},
	{"1", "zombie"}, {"2", "skeleton_arrow"}, {"3", "skeleton_heavy"},
	{"1", "zombie"}, {"2", "skeleton_arrow"}, {"3", "skeleton"},
	{"5", "zombie"}, {"3", "skeleton_arrow"}
	{"5", "zombie"}
};

public Plugin myinfo =  {
	name = "Quête: "...QUEST_NAME, author = "KoSSoLaX", 
	description = "RolePlay - Quête "...QUEST_NAME, 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

#include "rp_quest_pve.inc"
