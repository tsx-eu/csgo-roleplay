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
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ 		"v:0.1.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define QUEST_UNIQID	"000-safety"
#define	QUEST_NAME		"En sécurité à princeton?"
#define	QUEST_TYPE		quest_story

public Plugin myinfo = {
	name = "Quête: Safety", author = "KoSSoLaX",
	description = "RolePlay - Quête: En sécurité à princeton?",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest;
public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++,	Q1_Start,	Q1_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++,	Q2_Start,	QUEST_NULL,	QUEST_NULL,	QUEST_NULL);
}
public void OnMapStart() {
	AddFileToDownloadsTable("sound/DeadlyDesire/halloween/zombie/mumbling1.mp3");
	AddFileToDownloadsTable("sound/DeadlyDesire/halloween/zombie/foot1.mp3");
	
	PrecacheSoundAny("DeadlyDesire/halloween/zombie/mumbling1.mp3", true);
	PrecacheSoundAny("DeadlyDesire/halloween/zombie/foot1.mp3", true);
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	return true;
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "-----------------", ITEMDRAW_RAWLINE);
	
	menu.AddItem("", "Vous entendez comme des chuchotements endehors de cette église.", ITEMDRAW_RAWLINE);
	menu.AddItem("", "Etant de nature curieuse vous décidez de vous en approchez", ITEMDRAW_RAWLINE);
	menu.AddItem("", "pour écoute. Malheureusement, vous ne percevez que de petit bout de phrase...", ITEMDRAW_RAWLINE);
	menu.AddItem("", "", ITEMDRAW_RAWLINE);
	menu.AddItem("", "ςεττε vιℓℓε η'εsτ ραs sμя ρяοςμяεя vομs μηε αямε ρομя vομs δéfεηδяε.", ITEMDRAW_RAWLINE);
	menu.AddItem("", "", ITEMDRAW_RAWLINE);
	menu.AddItem("", "Par inadvetance, vous renversez la statue de Cupidon, juste derrière vous..", ITEMDRAW_RAWLINE);
	menu.AddItem("", "Vous entendez des bruits de pas s'éloigner.", ITEMDRAW_RAWLINE);
	menu.AddItem("", "", ITEMDRAW_RAWLINE);
	menu.AddItem("", "Vous décidez d'aller enquêter en direction du bruit.", ITEMDRAW_RAWLINE);	
	
	menu.ExitButton = false;
	menu.Display(client, 30);
}
public void Q1_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {4877.0, 1286.0, -2076.0};
	GetClientAbsOrigin(client, origin);
	
	if( GetVectorDistance(origin, target) < 64.0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		rp_Effect_BeamBox(client, 0, target);
		if( Math_GetRandomInt(1, 5) == 3 )
			EmitSoundToClientAny(client, "DeadlyDesire/halloween/zombie/mumbling1.mp3", SOUND_FROM_WORLD, _, _, _, _, _, _, target);
	}
}
public void Q2_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	menu.SetTitle("Quète: %s", QUEST_NAME);
	
	menu.AddItem("", "-----------------", ITEMDRAW_RAWLINE);
	
	menu.AddItem("", "Vous avez suivit les bruits... Jusqu'à une tombe.", ITEMDRAW_RAWLINE);
	menu.AddItem("", "On dirait qu'il y a quelqu'un d'entérrer vivant !!", ITEMDRAW_RAWLINE);
	menu.AddItem("", "Il semblerai que cette ville cache bien des secrets.", ITEMDRAW_RAWLINE);
	
	menu.AddItem("", "Vous courrez jusqu'à l'armurerie... Vous décidez", ITEMDRAW_RAWLINE);
	menu.AddItem("", "de vous procurer une arme afin de pouvoir mieux dormir la nuit", ITEMDRAW_RAWLINE);
	menu.AddItem("", "et surtout de vous protéger si jamais on viendrais à vous attaquez.", ITEMDRAW_RAWLINE);
	
	menu.ExitButton = false;
	menu.Display(client, 30);
}
// ----------------------------------------------------------------------------
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}