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
#define QUEST_UNIQID	"000-tutorial"
#define	QUEST_NAME		"Tutorial"
#define	QUEST_TYPE		quest_story

public Plugin myinfo = {
	name = "Quête: Tutorial", author = "KoSSoLaX",
	description = "RolePlay - Quête: Tutorial",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_iQuest;

char qualif[][] =  	{ "Recommandé", "Amusant", "Difficile", "Métier de vente", "Non recommandé"};
int g_iJob[] =  			{ 16,25, 35, 46, 55, 65, 76, 87, 96, 116, 135, 176, 195, 216, 226 };
int g_iRecom[MAX_JOBS];
	
// TODO: Déplacer les récompenses dans les fonctions appropriées
// TODO: Trié les jobs par sous quota, ou quota "non respecté"

int g_iQ9, g_iQ12, g_iQ14, g_iClientDoingQ[65];
public void OnPluginStart() {
	g_iRecom[116] = g_iRecom[176] = 0;
	g_iRecom[87] = g_iRecom[96] = g_iRecom[226] = 1;
	g_iRecom[46] = g_iRecom[35] = 2;
	g_iRecom[16] = g_iRecom[25] = g_iRecom[55] = g_iRecom[65] = g_iRecom[76] = g_iRecom[135] = g_iRecom[176] = g_iRecom[216] = 3;
	g_iRecom[195] = 4;
	
	RegServerCmd("rp_quest_reload", Cmd_Reload);
	
	for (int j = 1; j <= MaxClients; j++)
		if( IsValidClient(j) )
			OnClientPostAdminCheck(j);
}
public void OnAllPluginsLoaded() {
	g_iQuest = rp_RegisterQuest(QUEST_UNIQID, QUEST_NAME, QUEST_TYPE, fwdCanStart);
	if( g_iQuest == -1 )
		SetFailState("Erreur lors de la création de la quête %s %s", QUEST_UNIQID, QUEST_NAME);
	
	int i;
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q1_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q2_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q3_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q4_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q5_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q6_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q7_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q8_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q9_Start,	Q9_Frame,	Q9_Abort,	Q9_Abort);
	rp_QuestAddStep(g_iQuest, i++, Q92_Start,	Q92_Frame,	Q92_Abort,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q10_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, Q11_Start,	Q11_Frame,	Q11_Abort,	Q11_Abort);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q12_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q13_Frame,	QUEST_NULL,	QUEST_NULL);
	rp_QuestAddStep(g_iQuest, i++, QUEST_NULL,	Q14_Frame,	QUEST_NULL,	QUEST_NULL);
}
public Action Cmd_Reload(int args) {
	char name[64];
	GetPluginFilename(INVALID_HANDLE, name, sizeof(name));
	ServerCommand("sm plugins reload %s", name);
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
public void OnClientPostAdminCheck(int client) {
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
}
public Action fwdCommand(int client, char[] command, char[] arg) {	
	if( StrEqual(command, "aide") || StrEqual(command, "aides") || StrEqual(command, "help")  ) { // C'est pour nous !
		
		OpenHelpMenu(client, 1, 0);
		
		if( g_iClientDoingQ[client] > 0 ) {
			rp_QuestStepComplete(client, g_iClientDoingQ[client]);
		}
		
		return Plugin_Handled;
	}
	else if( StrEqual(command, "wiki") ) {
		QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(ClientConVar), client);
		ShowMOTDPanel(client, "Role-Play: WiKi", "http://www.ts-x.eu/popup.php?url=/wiki/", MOTDPANEL_TYPE_URL);
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public void ClientConVar(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue) {
	if( StrEqual(cvarName, "cl_disablehtmlmotd", false) ) {
		if( StrEqual(cvarValue, "0") == false ) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Des problèmes d'affichage? Entrez cl_disablehtmlmotd 0 dans votre console puis relancez CS:GO.");
		}
	}	
}
// ----------------------------------------------------------------------------
public bool fwdCanStart(int client) {
	return true;
}
// ----------------------------------------------------------------------------
public void Q1_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {1372.0, 30.0, -2146.0};
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Bienvenue sur le serveur RolePlay");
		DrawPanelText(panel, " C'est votre première connexion,");
		DrawPanelText(panel, "vous devez donc faire notre tutoriel ");
		DrawPanelText(panel, "afin de vous familiariser avec ce mode");
		DrawPanelText(panel, "de jeu. A la fin de celui-ci vous");
		DrawPanelText(panel, "gagnerez 25.000$: la monnaie du jeu");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Ce mode Roleplay est une sorte de simulation");
		DrawPanelText(panel, "de vie: vous pouvez avoir de l'argent,");
		DrawPanelText(panel, "un emploi etc.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Rendez-vous devant la statue de la");
		DrawPanelText(panel, "place de l'indépendance afin de commencer");
		DrawPanelText(panel, "votre apprentissage.");
		DrawPanelText(panel, "Les flèches vous guideront tout");
		DrawPanelText(panel, "au long de ce tutoriel.");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}

	
	if( GetVectorDistance(target, origin) < 64.0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	}
}
public void Q2_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {2034.0, 1391.0, -2014.0};
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 1: La ville");
		DrawPanelText(panel, " Princeton est la ville dans laquelle");
		DrawPanelText(panel, "vous êtes, c'est la map du serveur. La ");
		DrawPanelText(panel, "justice y fait souvent défaut. De nombreux");
		DrawPanelText(panel, "meurtres y sont commis, et parfois impunis.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Bien que de nombreux citoyens s'entretuent");
		DrawPanelText(panel, "sachez, avant tout, que vous risquez de rester");
		DrawPanelText(panel, "de longues minutes en prison pour de telles actions.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Rendez-vous devant le commissariat afin");
		DrawPanelText(panel, "de continuer votre apprentissage.");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
	
	if( GetVectorDistance(target, origin) < 64.0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	}
}
public void Q3_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {2189.0, -12.0, -2134.0};
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 2: Le commissariat");
		DrawPanelText(panel, " Selon le règlement de la police, vous");
		DrawPanelText(panel, "pouvez être mis en prison dans ce");
		DrawPanelText(panel, "commissariat pour différentes raisons.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Les principales raisons d’incarcération");
		DrawPanelText(panel, "sont: Le meurtre ou la tentative");
		DrawPanelText(panel, "de meurtre, le tir dans la rue, le vol,");
		DrawPanelText(panel, "les nuisances sonores, le trafic illégal");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Votre futur emploi définira votre");
		DrawPanelText(panel, "camp. Par exemple, un mafieux vole de l'argent,");
		DrawPanelText(panel, "un mercenaire exécute des contrats, un");
		DrawPanelText(panel, "policier tentera de les en empêcher.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Rendez-vous devant la banque.");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
	
	if( GetVectorDistance(target, origin) < 64.0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu 2500$.");
		rp_SetClientInt(client, i_Money, rp_GetClientInt(client, i_Money)+ 2500);
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	}
}
public void Q4_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {2288.0, 136.0, -2134.0};
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 3: Mettre son argent en sécurité");
		DrawPanelText(panel, " Dans un premier temps pour éviter de vous");
		DrawPanelText(panel, "faire voler votre argent, déposez-le");
		DrawPanelText(panel, "en banque.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Pour cela, positionnez-vous devant un");
		DrawPanelText(panel, "distributeur, utilisez votre touche action (E).");
		DrawPanelText(panel, "Selectionnez l'action déposer argent.");
		DrawPanelText(panel, "Déposez-y le montant que vous souhaitez");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Sachez tout de même que les banquiers vendent");
		DrawPanelText(panel, "des cartes et des comptes bancaires qui vous");
		DrawPanelText(panel, "faciliterons la vie plus tard sur le serveur.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Déposez tout votre argent en banque.");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
	
	if( rp_GetClientInt(client, i_Money) <= 0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	}
}
public void Q5_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {156.8, -859.9, -2143.9};
	
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 4: Le Tribunal");
		DrawPanelText(panel, " Sachez qu'un policier n'a pas le droit de mettre");
		DrawPanelText(panel, "en prison pour des faits qui ne se sont pas déroulés devant");
		DrawPanelText(panel, "ses yeux.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Si vous connaissez le nom de la personne qui vous a tué");
		DrawPanelText(panel, "et qu'un juge est présent, adressez-vous à lui.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " En vérifiant l'historique du serveur, le juge ");
		DrawPanelText(panel, "appliquera une condamnation adaptée aux faits");
		DrawPanelText(panel, "reprochés. (Meurtre, vol, ...)");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Rendez-vous devant le tribunal.");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}


	if( GetVectorDistance(target, origin) < 64.0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu en récompense 1 Desert Eagle.");
		rp_ClientGiveItem(client, 150);
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	}
}
public void Q6_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {-1900.0, 604.0, -2134.0};
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 5: L'armurerie");
		DrawPanelText(panel, " Les flèches vous dirige vers l'armurerie où ");
		DrawPanelText(panel, "vous pourrez vous procurer des armes.");
		DrawPanelText(panel, "N'oubliez pas d'acheter un permis");
		DrawPanelText(panel, "de port d'arme à un banquier. Dans le cas contraire");
		DrawPanelText(panel, "un policier est en droit de vous arrêter.");
		DrawPanelText(panel, " Restez discret, rangez la dans votre poche!");
		DrawPanelText(panel, " Une arme a été ajoutée dans votre inventaire.");
		DrawPanelText(panel, "→ Entrez la commande /item dans le chat général,");
		DrawPanelText(panel, "Appuyez sur la touche 1 afin de l'utiliser");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Notez que votre inventaire disparaît en cas");
		DrawPanelText(panel, "de déconnexion.");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
	
	if( rp_GetClientItem(client, 150) <= 0) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	}
}
public void Q7_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {-1192.0, -778.0, -2135.0};
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 6: Les appartements");
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		DrawPanelText(panel, " Un appartement vous permet d'augmenter");
		DrawPanelText(panel, "votre paye. Lorsque vous aurez décroché");
		DrawPanelText(panel, "votre premier emploi, il est généralement");
		DrawPanelText(panel, "conseillé de louer un appart. Celui-ci");
		DrawPanelText(panel, "augmentera votre paie et vous rend votre vie.");
		DrawPanelText(panel, "Vous pouvez aussi y cacher différents objets");
		DrawPanelText(panel, "du jeu, tel que les machines à faux-billets");
		DrawPanelText(panel, "plants de drogue, armes, etc.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Rendez-vous devant les appartements afin");
		DrawPanelText(panel, "de continuer votre apprentissage.");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
	
	if( GetVectorDistance(target, origin) < 64.0 ) {
		
		rp_ClientGiveItem(client, 81);
		rp_ClientGiveItem(client, 103);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez reçu en récompense 1 Plant de drogue et 1 Machine à faux-billets.");
		
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	}
}
public void Q8_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {-611.0, -1286.0, -2016.0};
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 7: Un trafic illégal");
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		DrawPanelText(panel, " Une imprimante à faux-billets et un plant");
		DrawPanelText(panel, "de drogue ont été ajoutés à votre");
		DrawPanelText(panel, "inventaire.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Trouvez-vous une cachette, et utilisez");
		DrawPanelText(panel, "ces objets (/item). Si vous êtes mal");
		DrawPanelText(panel, "caché, un policier est en droit de vous");
		DrawPanelText(panel, "arrêter ! ");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Déposez une machine, et un plant de");
		DrawPanelText(panel, "drogue afin de continuer votre");
		DrawPanelText(panel, "apprentissage.");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
	
	if( rp_GetClientItem(client, 81) <= 0 && rp_GetClientItem(client, 103) <= 0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	}
}
public void Q9_Frame(int objectiveID, int client) {
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 8: Le Tchat général");
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		DrawPanelText(panel, " Le Tchat est divisé en plusieurs");
		DrawPanelText(panel, "catégories.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Le Tchat général, celui qui permet");
		DrawPanelText(panel, "de communiquer avec tout citoyen");
		DrawPanelText(panel, "présent en ville, mais aussi d'exécuter");
		DrawPanelText(panel, "diverses commandes (comme le /item qu'on vient de voir).");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Le Tchat équipe, permet de communiquer");
		DrawPanelText(panel, "avec les citoyens à coté de vous.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Faites un coucou dans le chat local");
		DrawPanelText(panel, "(chat équipe) afin de continuer votre");
		DrawPanelText(panel, "apprentissage.");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
}
public void Q9_Start(int objectiveID, int client) {
	g_iQ9 = objectiveID;
	rp_HookEvent(client, RP_PrePlayerTalk, OnPlayerTalk);
}
public void Q9_Abort(int objectiveID, int client) {
	rp_UnhookEvent(client, RP_PrePlayerTalk, OnPlayerTalk);
}
public Action OnPlayerTalk(int client, char[] szSayText, int length, bool local) {
	if( local ) {
		rp_QuestStepComplete(client, g_iQ9);
	}
}
// ----------------------------------------------------------------------------
int g_iQ92;
public void Q92_Start(int objectiveID, int client) {
	g_iQ92 = objectiveID;
	rp_HookEvent(client, RP_OnPlayerUse, fwdUsePhone);
}
public void Q92_Abort(int objectiveID, int client) {
	rp_UnhookEvent(client, RP_OnPlayerUse, fwdUsePhone);
}
public Action fwdUsePhone(int client) {
	float origin[3], target[3] = {-452.0, -2065.0, -2000.0};
	GetClientAbsOrigin(client, origin);
	
	if( GetVectorDistance(origin, target) < 40.0 ) {
		ServerCommand("sm_effect_copter 0 -2364");
		rp_UnhookEvent(client, RP_OnPlayerUse, fwdUsePhone);
		rp_QuestStepComplete(client, g_iQ92);
		
		Handle panel = CreateMenu(MenuNothing);
		SetMenuTitle(panel, "== Objectif 9: Les quêtes\n\n Un hélicoptère vous envois un colis.\nIl sera envoyé près de vous,\ndans la rue du commerce.");
		AddMenuItem(panel, "_", "Récupérez le.", ITEMDRAW_DISABLED);
		DisplayMenu(panel, client, 10);
	}
}
public int MenuNothing(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("MenuNothing");
	#endif
	if( action == MenuAction_Select ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
	else if( action == MenuAction_End ) {
		if( menu != INVALID_HANDLE )
			CloseHandle(menu);
	}
}
public void Q92_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {-452.0, -2065.0, -2000.0};
	GetClientAbsOrigin(client, origin);
	
	ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	
	if( rp_ClientCanDrawPanel(client) ) {
		Handle panel = CreatePanel();
		
		if( GetTime() %3 == 0 ) {
			EmitSoundToClientAny(client, "DeadlyDesire/princeton/ambiant/phone1.mp3", SOUND_FROM_WORLD, _, _, _, _, _, _, target);
		}
		
		SetPanelTitle(panel, "== Objectif 9: Les quêtes");
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		DrawPanelText(panel, " Les téléphones de la ville sont très");
		DrawPanelText(panel, "utiles pour gagner de l'argent facilement.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " De temps à autres, ceux-ci se mettent");
		DrawPanelText(panel, "à sonner. Si vous décrochez, un colis");
		DrawPanelText(panel, "vous est envoyé par hélicoptère.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " De plus, de nombreuses quêtes sont disponibles");
		DrawPanelText(panel, "selon votre job. Il suffit de se rendre");
		DrawPanelText(panel, "à un téléphone pour débuter l'une d'entre elle.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Décrochez au téléphonne à l'aide");
		DrawPanelText(panel, "de votre touche utiliser (E par défaut).");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
}
// ----------------------------------------------------------------------------
public void Q10_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {763.0,-4748.0, -2014.0};
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 10: Les commandes utiles");
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		DrawPanelText(panel, " Il existe de nombreuses commandes sur le");
		DrawPanelText(panel, "serveur. La plupart liées à votre");
		DrawPanelText(panel, "métier, que vous apprendrez sur le tas.");
		DrawPanelText(panel, " - /give montant permet de donner votre argent");
		DrawPanelText(panel, " - /vendre pour vendre un objet");
		DrawPanelText(panel, " - /job Permet de voir les différents jobs connectés");
		DrawPanelText(panel, " Afin de trouver un emploi, jetez un oeil à cette");
		DrawPanelText(panel, "commande. Elle permet de voir qui est chef,");
		DrawPanelText(panel, "vous saurez donc à qui vous adresser pour trouver");
		DrawPanelText(panel, "un emploi.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Rendez-vous maintenant sur la place Station");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
	
	if( GetVectorDistance(target, origin) < 64.0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	}
}
// ----------------------------------------------------------------------------
public void Q11_Frame(int objectiveID, int client) {
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 11: Le site, le forum, le WiKi");
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		DrawPanelText(panel, " Le forum et notre site sont deux parties");
		DrawPanelText(panel, "importantes du serveur. Si vous y êtes");
		DrawPanelText(panel, "inscrit, et confirmé comme ayant 16 ans ou");
		DrawPanelText(panel, "plus (le rang no-pyj). Vous augmentez vos");
		DrawPanelText(panel, "chances de trouver un emploi intéressant.");
		DrawPanelText(panel, "Besoin d'aide? Consultez notre FAQ");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Allez faire un tour sur notre FAQ ( dites /aide ) ");
		DrawPanelText(panel, " afin d'obtenir davantage d'aide et de");
		DrawPanelText(panel, "continuer votre apprentissage.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Site: https://www.ts-x.eu");
		DrawPanelText(panel, " WiKi: https://www.ts-x.eu/wiki/");
		DrawPanelText(panel, " TeamSpeak: ts.ts-x.eu");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
}
public void Q11_Start(int objectiveID, int client) {
	g_iClientDoingQ[client] = objectiveID;
}
public void Q11_Abort(int objectiveID, int client) {
	g_iClientDoingQ[client] = -1;
}
// ----------------------------------------------------------------------------
public void Q12_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {2472.0, -1063.0, -2144.0};
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 12: Le mot de la fin");
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		DrawPanelText(panel, " Derniers conseils avant de vous laisser");
		DrawPanelText(panel, "partir sur de bonnes bases.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "- Nous sommes sur CSGO, pas sur ARMA ni GMOD.");
		DrawPanelText(panel, "Il y a donc BEAUCOUP de meurtre en ville, armez vous.");
		DrawPanelText(panel, "- Seul les policiers et les juges sont là pour");
		DrawPanelText(panel, "sanctionner les meurtres. CACHEZ-VOUS.");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "- Trouvez vous un job");
		DrawPanelText(panel, "- Décrochez le rang no-pyj");
		DrawPanelText(panel, "- Faites un tour sur notre TeamSpeak");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Bon jeu!");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Rendez-vous devant l'hôpital afin de");
		DrawPanelText(panel, "commencer votre aventure RolePlay.");
		
		rp_SendPanelToClient(panel, client, 1.1);
		CreateTimer(1.1, PostKillHandle, panel);
	}
	
	if( GetVectorDistance(target, origin) < 64.0 ) {
		rp_QuestStepComplete(client, objectiveID);
	}
	else {
		ServerCommand("sm_effect_gps %d %f %f %f", client, target[0], target[1], target[2]);
	}
}
public void Q13_Frame(int objectiveID, int client) {
	
	if( rp_ClientCanDrawPanel(client) ) {
		g_iQ12 = objectiveID;
		
		Handle menu = CreateMenu(MenuSelectParrain);
		SetMenuTitle(menu, "== Parrainage");
					
		AddMenuItem(menu, "", "Quelqu'un de présent vous a t-il invité",		ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "à jouer sur notre serveur?  Si oui, qui?",		ITEMDRAW_DISABLED);
		
		AddMenuItem(menu, "none", "Personne, j'ai connu autrement le serveur");
//		AddMenuItem(menu, "youtube", "Youtube, en regardant une vidéo");
				
		char szSteamID[64], szName[128];
		for( int i=1;i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( i == client )
				continue;
			if( rp_IsClientNew(i) )
				continue;
						
			GetClientAuthId(i, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
			Format(szName, sizeof(szName), "%N", i);
						
			AddMenuItem(menu, szSteamID, szName);
		}
					
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 60);
	}
}
public int MenuSelectParrain(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		
		if( !StrEqual(options, "none") ) {
			char szQuery[1024], szSteamID[64];
			GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID), false);
			
			Format(szQuery, sizeof(szQuery), "INSERT INTO `rp_parrain` (`steamid`, `parent`, `timestamp`) VALUES ('%s', '%s', UNIX_TIMESTAMP());", szSteamID, options);
			SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, szQuery);
		}
		
		rp_QuestStepComplete(client, g_iQ12);
		rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + 7500);
		
		
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}

public void Q14_Frame(int objectiveID, int client) {

	
	if( rp_ClientCanDrawPanel(client) ) {
		g_iQ14 = objectiveID;
		
		Handle menu = CreateMenu(MenuSelectJob);
		SetMenuTitle(menu, "== Votre premier job vous est offert");
		AddMenuItem(menu, "", "Sachez que plus tard, vous devrez le trouver", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "vous-même et être recruté par le chef d'un job.", ITEMDRAW_DISABLED);
			
		char tmp[128], tmp2[8];
		SortIntegers(g_iJob, sizeof(g_iJob), Sort_Random);
	
		for( int i=1;i<sizeof(g_iJob); i++) {
			
			if( rp_GetJobInt((g_iJob[i] - (g_iJob[i] % 10))+1, job_type_current) >= (rp_GetJobInt((g_iJob[i] - (g_iJob[i] % 10))+1, job_type_quota)*2) )
				continue;
			
			rp_GetJobData(g_iJob[i], job_type_name, tmp, sizeof(tmp));
			Format(tmp, sizeof(tmp), "%s: %s", qualif[g_iRecom[g_iJob[i]]], tmp);
			Format(tmp2, sizeof(tmp2), "%d", g_iJob[i]+1000);
			AddMenuItem(menu, tmp2, tmp);
		}
					
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 60);
	}
}
public int MenuSelectJob(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64];
		GetMenuItem(menu, param2, options, sizeof(options));
		int job = StringToInt(options);
		
		if( job > 1000 ) {
			job -= 1000;
			rp_GetJobData(job, job_type_name, options, sizeof(options));
			
			Handle menu2 = CreateMenu(MenuSelectJob);
			
			Format(options, sizeof(options), "%s: %s", qualif[g_iRecom[job]], options);
			SetMenuTitle(menu2, "== Votre premier job vous est offert\nVous avez choisis comme métier\n%s\n \nSachez que plus tard, vous devrez le trouver\nVOUS-MÊME et être recruté par le chef d'un job.\n---------------------", options);
			
			Format(options, sizeof(options), "%d", job);
			AddMenuItem(menu2, "0", "Je veux choisir un autre job");
			AddMenuItem(menu2, options, "Je confirme mon choix");
			SetMenuExitButton(menu2, true);
			DisplayMenu(menu2, client, 60);
		}
		else if( job > 0 ) {
			
			rp_SetClientInt(client, i_Job, job);
			rp_SetClientInt(client, i_JetonRouge, (job - (job % 10))+1);
			
			rp_GetJobData(job, job_type_name, options, sizeof(options));
			LogToGame("[TSX-RP] [TUTORIAL] %L a terminé son tutoriel. Il a choisi %s comme job.", client, options);
			FakeClientCommand(client, "say /shownotes");
			
			rp_SetClientInt(client, i_Tutorial, 20);
			rp_ClientGiveItem(client, 223);
			rp_QuestStepComplete(client, g_iQ14);
			rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + 15000);
			
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez terminé le tutoriel, une voiture vous a été offerte. (Faites /item !)");
			
			for (int i = 1; i <= MaxClients; i++) {
				if( !IsValidClient(i) )
					continue;
				if( i == client )
					continue;
				CPrintToChat(i, "{lightblue}[TSX-RP]{default} %N vient de terminé son tutorial, il est %s. Aidez le !", client, options);
			}
		}
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public Action PostKillHandle(Handle timer, any data) {
	if( data != INVALID_HANDLE )
		CloseHandle(data);
}



// ------------------------------------------------------------
void OpenHelpMenu(int client, int section, int parent) {
	char query[1024];
	Format(query, sizeof(query), "SELECT `id`, `goto`, `txt`  FROM `rp_shared`.`rp_help_question` WHERE `qid`=%d OR `id`=%d", section, parent);
	
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, parent);
	
	SQL_TQuery(rp_GetDatabase(), SQL_OpenHelpMenu, query, pack, DBPrio_High);
}
public void SQL_OpenHelpMenu(Handle owner, Handle hQuery, const char[] error, any pack) {
	ResetPack(pack);
	int client, parent, id, go;
	char txt[255], tmp[16];
	
	client = ReadPackCell(pack);
	parent = ReadPackCell(pack);
	
	Menu menu = CreateMenu(helpMenu);
	menu.SetTitle("Besoin d'aide?\n--------------------\n ");
	
	while( SQL_FetchRow(hQuery) ) {
		id = SQL_FetchInt(hQuery, 0);
		go = SQL_FetchInt(hQuery, 1);
		SQL_FetchString(hQuery, 2, txt, sizeof(txt));
		
		
		if( id == parent )
			menu.SetTitle("%s\n--------------------\n <", txt);
		else {
			Format(tmp, sizeof(tmp), "%d %d", id, go);
			
			menu.AddItem(tmp, txt, go > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
	}
	
	if( parent != 0 ) {
		menu.ExitBackButton = true;
		menu.Pagination = 8;
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}


public int helpMenu(Handle hItem, MenuAction oAction, int client, int param) {
	#if defined DEBUG
	PrintToServer("helpMenu");
	#endif
	
	if (oAction == MenuAction_Select) {
		char options[64], tmp[2][16];
		if( GetMenuItem(hItem, param, options, sizeof(options)) ) {
			ExplodeString(options, " ", tmp, sizeof(tmp), sizeof(tmp[]));
			OpenHelpMenu(client, StringToInt(tmp[1]), StringToInt(tmp[0]));
		}
	}
	else if (oAction == MenuAction_Cancel && param == MenuCancel_ExitBack  ) {
		OpenHelpMenu(client, 1, 0);
	}
	else if (oAction == MenuAction_End ) {
		CloseHandle(hItem);
	}
}
