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
#include <colors_csgo> // https://forums.alliedmods.net/showthrea ... ost2205447
#include <smlib> // https://github.com/bcserv/smlib
#include <emitsoundany> // https://forums.alliedmods.net/showthread.php?t=237045

#define __LAST_REV__ "v:0.1.0"

#pragma newdecls required
#include <roleplay.inc> // https://www.ts-x.eu
// Pour Financer cette quête : Prélever 1$ d'un 1 capital au hasard chaque Seconde = 60$ par minute = 3600$ en une heure. La personne qui réussi la quête gagne le total accumulé depuis la dernière fois qu'elle a été réussie.
//#define DEBUG
#define QUEST_UNIQID "enquete-002"				// Ce qu'il reste à faire : tout
#define QUEST_NAME "Le trésor de Monsieur Gebel" // Pour cette quête je vais écrire une histoire rp que les gens devront lire pour trouver où se trouve la carte au trésor. Celle-ci les conduira directement au trésor des ancêtres de Monsieur Gebel.
#define QUEST_TYPE quest_daily 						 
#define QUEST_RESUME1 "Lisez l'histoire du trésor perdu"
#define QUEST_RESUME2 "Trouvez la carte au trésor"
#define QUEST_RESUME3 "Récupérez le trésor perdu"
#define QUEST_ITEM 220 /* Mini : ça doit être la récompense ça si j'ai bien compris, oui c'est une variable ok 
 ça dit en gros : Rechercher QUEST_ITEM et remplace par 236
	Quand tu tappe un truc, t'as la doc qui s'affiche si possible; essaye. Essayez quoi ?
	les i_Machins sont des nombres entiers. Donc "rp_GetclientInt"
	int zone = rp_GetPlayerZone(client);
	if( zone == 42 || rp_GetZoneInt(zone, zone_type_type) == 1 ) {
		 Sil 'est dans la zone 42, ou la zone de type "flic"
		rp_GetZoneInt(zone, zone_type_type) == rp_GetClientJobID(client);
		 Sil est dans al zone de son job..; etc
		
		 Bref, la doc c'est cool et t'as 50 exemple partout avec tt les jobs, quete, etc. GL.
	}
	if( rp_GetClientInt(client, i_Money) >= 100 ) {
		CPrintToChat(client, "[TSX-RP] Woah t'es trop riche ! t'as au moins %d$!", rp_GetClientInt(client, i_Money));
	}*/

public Plugin myinfo = {
	name = "Quête: Le Trésor de Monsieur Gebel", author = "Mini", 
	description = "RolePlay - Quête pour tous: Le Trésor de Monsieur Gebel", 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest, g_iDuration[MAXPLAYERS + 1], g_iGoing[MAXPLAYERS + 1], g_iCurrent[MAXPLAYERS + 1];

float g_flLocation[5][3] = { // [ligne][colone]
	{ 1037.5, -4858.1, -1800.7 },  // cl_ss_origin ; Positions à définir.

	{ -1693.7, -1078.9, -1936.7 }, 
	{ -401.8, -63.7, -1865.8 }, 
	{ 4303.2, 180.7, -2071.9 },
	{ -3906.0, -352.1, -1442.5 } // <-- jamais de virgule dernière ligne
};

public void OnPluginStart() {
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if (g_iQuest == -1)
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++, Q1_Start, Q1_Frame, Q1_Abort, Q1_Abort);
	//rp_QuestAddStep(id de la quete, queFaireAuDebutDeLetape1, queFaireChaqueSeconde, queFaireSiEchec, queFaireSiReussite)
	
	rp_QuestAddStep(g_iQuest, i++, Q2_Start, Q1_Frame, Q1_Abort, Q1_Abort);
	rp_QuestAddStep(g_iQuest, i++, Q2_Start, Q1_Frame, Q1_Abort, Q1_Abort);
	rp_QuestAddStep(g_iQuest, i++, Q2_Start, Q1_Frame, Q1_Abort, Q1_Abort);
	rp_QuestAddStep(g_iQuest, i++, Q2_Start, Q1_Frame, Q1_Abort, Q1_Abort);
	// QUEST_NULL = ne rien faire
	rp_QuestAddStep(g_iQuest, i++, Q3_Start, Q3_Frame, QUEST_NULL, Q3_End);
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
public void OnMapStart() {
	PrecacheModel("un/autrE/props.mdl");
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	return true; // Si c'est tlmd, il peut tjrs la commencé, donc c'est tjrs vrai.
}
public void Q1_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quête: %s", QUEST_NAME);
	menu.AddItem("", "Te revoilà. J'ai autre chose à te proposer que de chercher mon chat.", ITEMDRAW_DISABLED);
	menu.AddItem("", "La dernière fois j'ai pu tester ton aptitude à chercher et tu semble être bon.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Cette fois-ci tu vas chercher le trésor de mes ancêtres.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Avant tout, tu devras lire l'histoire de ce trésor bien gardé dans ma famille.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Si tu es assez farouche tu trouvera où se trouve la carte au trésor.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Pour finir, rien de plus simple que de récupérer ce trésor et me le ramener, en entier.", ITEMDRAW_DISABLED); // Pour moi : Proposer un choix -> Si tu ramène le trésor tu gagne 25% de la somme mais si tu garde le trésor Mr Gebel ne voudra plus de toi pour ses futures quêtes. [TSX-RP] Vous avez trahit la mémoire des ancêtres de Mr Gebel -> il ne vous fera plus confiance à moins que vous ne lui rameniez son trésor et une somme d'argent.
	menu.ExitButton = false;
	menu.Display(client, 60);
	
	g_iDuration[client] = 100 * 60; // Pour lire l'histoire mettre un lien via la commande /tresor
	g_iCurrent[client] = 0; // Donc, iCurrent pour ce joueur vaut 0, == la ligne 0 ==> { -130.6, 1330.9, -2096.4 },  dans ce cas
	g_iGoing[client] = rp_QuestCreateInstance(client, "un/autrE/props.mdl", g_flLocation[g_iCurrent[client]]);
	//Mini : Changer le props par autre chose (poisson / boite de conserve ?)

}
public void Q1_Abort(int objectiveID, int client) { // échec de la quete
	char classname[65];
	if (g_iGoing[client] > 0 && IsValidEdict(g_iGoing[client]) && IsValidEntity(g_iGoing[client])) {
		GetEdictClassname(g_iGoing[client], classname, sizeof(classname));
		if (StrContains(classname, "prop_dynamic_glow") == 0) {
			AcceptEntityInput(g_iGoing[client], "Kill");
			g_iGoing[client] = 0;
		}
	}
}
public void Q1_Frame(int objectiveID, int client) { // Chaque seconde

	g_iDuration[client]--;
	
	if (Entity_GetDistance(client, g_iGoing[client]) < 64.0) {
		AcceptEntityInput(g_iGoing[client], "Kill");
		g_iGoing[client] = 0;
		rp_QuestStepComplete(client, objectiveID); // étape réussie
		
		int cap = rp_GetRandomCapital(181);
		rp_SetJobCapital(cap, rp_GetJobCapital(cap) - 250);
		rp_SetClientInt(client, i_AddToPay, rp_GetClientInt(client, i_AddToPay) + 250);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous sentez une odeur de poisson. Vous en êtes maintenant sûr un chat est passé par ici.");
	}
	else if (g_iDuration[client] <= 0) {
		rp_QuestStepFail(client, objectiveID); // étape échouée
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez pris trop de temps pour suivre les traces du chat. Mr Gebel comptait sur vous...");
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME1);
		rp_Effect_BeamBox(client, g_iGoing[client], NULL_VECTOR, 255, 0, 0);
	}
}
public void Q2_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "C'est encore moi !", ITEMDRAW_DISABLED);
	menu.AddItem("", "Vous l'avez trouvé ? Non ? Alors continuez de chercher !", ITEMDRAW_DISABLED);

	menu.ExitButton = false;
	menu.Display(client, 30);
	
	g_iDuration[client] = 4 * 60;
	g_iCurrent[client]++;
	g_iGoing[client] = rp_QuestCreateInstance(client, "models/props/cs_office/box_office_indoor_32.mdl", g_flLocation[g_iCurrent[client]]); // // Mini : Changer le props par autre chose
}
public void Q2_Frame(int objectiveID, int client) {
	static int zoneDest = 94; // Attention qu'ici c'est un numéro de zone, tu peux demander à un admin, ou tester sur "api"
	static float dst[3] = { -1544.0, -2997.3, -1978.9 }; // a Changer je crois :x
	float vec[3];
	GetClientAbsOrigin(client, vec);
	
	g_iDuration[client]--;
	if (rp_GetPlayerZone(client) == zoneDest) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if (g_iDuration[client] <= 0) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME2);
		rp_Effect_BeamBox(client, -1, dst, 255, 255, 255);
	}
}

public void Q3_Start(int objectiveID, int client) {
	Menu menu = new Menu(MenuNothing);

	menu.SetTitle("Quète: %s", QUEST_NAME);
	menu.AddItem("", "Vous l'avez ? Ramenez moi mon chat mon brave.", ITEMDRAW_DISABLED);
	menu.AddItem("", "Je vous attends devant chez moi pour vous récompenser !", ITEMDRAW_DISABLED);
	menu.AddItem("", "J'habite au 8 rue de la Santé.", ITEMDRAW_DISABLED);
	menu.ExitButton = false;
	menu.Display(client, 30);
	
	g_iDuration[client] = 4 * 60;
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il semblerait qu'un chat commence à vous suivre.");
}
public void Q3_Frame(int objectiveID, int client) {
	float vec[3];
	GetClientAbsOrigin(client, vec);
	
	g_iDuration[client]--;
	if ( rp_GetClientJobID(client) == 62 //Exception pour job 62 							Je sais pas quoi faire pour l'enlever , pas envie de tout casser du coup j'ai mis un job impossible xD
		&& rp_GetPlayerZone(client) == 2 ) { //On les envoie dans la disco (zone "2")
		rp_QuestStepComplete(client, objectiveID);
	}
	else if ( rp_GetZoneInt(rp_GetPlayerZone(client), zone_type_type) == rp_GetClientJobID(client) ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else if (g_iDuration[client] <= 0) {
		rp_QuestStepFail(client, objectiveID);
	}
	else {
		PrintHintText(client, "<b>Quête</b>: %s\n<b>Temps restant</b>: %dsec\n<b>Objectif</b>: %s", QUEST_NAME, g_iDuration[client], QUEST_RESUME2);
	}
}
public void Q3_End(int objectiveID, int client) {

	Q1_Abort(objectiveID, client);
	
	Menu menu = new Menu(MenuNothing);
	
	menu.SetTitle("Quête: %s", QUEST_NAME);
	menu.AddItem("", "Ohhh merci", ITEMDRAW_DISABLED);
	menu.AddItem("", "C'est qu'elle m'avait manquée ma petite boule de poils !", ITEMDRAW_DISABLED);
	menu.AddItem("", "Prenez cette belle plante en gage de récompense !", ITEMDRAW_DISABLED); // Mini : Item a gagner ou argent à définir
	
	menu.ExitButton = false;
	menu.Display(client, 30);
	
	char item[64];
	rp_GetItemData(QUEST_ITEM, item_type_name, item, sizeof(item));
	rp_ClientGiveItem(client, QUEST_ITEM); // Plant de Cannabis pour cette quête, d'après Matt c'est le meilleur plant à gagner
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le chat qui vous suivait a arrêté de vous suivre. Vous avez reçu: %s de la part de Mr Gebel.", item);
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Mr Gebel est content de votre prestation. Il vous recontactera ultérieurement pour d'autres affaires.", item);
}
// ----------------------------------------------------------------------------
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	if (action == MenuAction_Select) {
		if (menu != INVALID_HANDLE)
			CloseHandle(menu);
	}
	else if (action == MenuAction_End) {
		if (menu != INVALID_HANDLE)
			CloseHandle(menu);
	}
}