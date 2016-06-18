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

// TODO: Déplacer les récompenses dans les fonctions appropriées
// TODO: Trié les jobs par sous quota, ou quota "non respecté"

int g_iQ9, g_iQ12, g_iQ14, g_iClientDoingQ[65];
public void OnPluginStart() {
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
	if( StrEqual(command, "aide") || StrEqual(command, "aides") || StrEqual(command, "wiki") || StrEqual(command, "help")  ) { // C'est pour nous !
		QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(ClientConVar), client);
		ShowMOTDPanel(client, "Role-Play: WiKi", "http://www.ts-x.eu/popup.php?url=/wiki/", MOTDPANEL_TYPE_URL);
		
		if( g_iClientDoingQ[client] > 0 ) {
			rp_QuestStepComplete(client, g_iClientDoingQ[client]);
		}
		
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
		DrawPanelText(panel, "gagnerez 10.000$: la monnaie du jeu");
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
// ----------------------------------------------------------------------------
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
public void Q10_Frame(int objectiveID, int client) {
	float origin[3], target[3] = {763.0,-4748.0, -2014.0};
	GetClientAbsOrigin(client, origin);
	
	if( rp_ClientCanDrawPanel(client) ) {
		
		Handle panel = CreatePanel();
		
		SetPanelTitle(panel, "== Objectif 9: Les commandes utiles");
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
		
		SetPanelTitle(panel, "== Objectif 10: Le site, le forum, le WiKi");
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		DrawPanelText(panel, " Le forum et notre site sont deux parties");
		DrawPanelText(panel, "importantes du serveur. Si vous y êtes");
		DrawPanelText(panel, "inscrit, et confirmé comme ayant 16 ans ou");
		DrawPanelText(panel, "plus (le rang no-pyj). Vous augmentez vos");
		DrawPanelText(panel, "chances de trouver un emploi intéressant.");
		DrawPanelText(panel, "Besoin d'aide? Consultez notre wiki");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, " Site: http://www.ts-x.eu");
		DrawPanelText(panel, " WiKi: http://www.ts-x.eu/wiki/");
		DrawPanelText(panel, " TeamSpeak: ts.ts-x.eu");
		DrawPanelText(panel, " ");
		DrawPanelText(panel, "→ Allez faire un tour sur notre wiki ( dites /aide ) ");
		DrawPanelText(panel, " afin d'obtenir davantage d'aide et de");
		DrawPanelText(panel, "continuer votre apprentissage.");
		
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
		
		SetPanelTitle(panel, "== Objectif 11: Le mot de la fin");
		DrawPanelItem(panel, "", ITEMDRAW_SPACER);
		DrawPanelText(panel, " Derniers conseils avant de vous laisser");
		DrawPanelText(panel, "partir sur de bonnes bases.");
		DrawPanelText(panel, "- Nous sommes sur CSGO, pas sur ARMA ni GMOD.");
		DrawPanelText(panel, "Il y a donc beaucoup de meurtre en ville, armez vous.");
		DrawPanelText(panel, "- Trouvez vous un job");
		DrawPanelText(panel, "- Attention aux arnaques");
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
		AddMenuItem(menu, "youtube", "Youtube, en regardant une vidéo");
				
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
	static int job[] =  { 16, 25, 35, 55, 65, 76, 87, 116, 135, 176, 195, 216, 226 };
	
	if( rp_ClientCanDrawPanel(client) ) {
		g_iQ14 = objectiveID;
		
		Handle menu = CreateMenu(MenuSelectJob);
		SetMenuTitle(menu, "== Votre premier job vous est offert");
		AddMenuItem(menu, "", "Sachez que plus tard, vous devrez le trouver", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "vous-même et être recruté par le chef d'un job.", ITEMDRAW_DISABLED);
			
		char tmp[128], tmp2[8];
		SortIntegers(job, sizeof(job), Sort_Random);
	
		for( int i=1;i<sizeof(job); i++) {
			rp_GetJobData(job[i], job_type_name, tmp, sizeof(tmp));
			
			Format(tmp2, sizeof(tmp2), "%d", job[i]);	
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
		
		if( !StrEqual(options, "") ) {
			int job = StringToInt(options);
			rp_SetClientInt(client, i_Job, job);
			
			rp_GetJobData(job, job_type_name, options, sizeof(options));
			LogToGame("[TSX-RP] [TUTORIAL] %L a terminé son tutoriel. Il a choisi %s comme job.", client, options);
			FakeClientCommand(client, "say /shownotes");
		}
		
		rp_SetClientInt(client, i_Tutorial, 20);
		rp_ClientGiveItem(client, 223);
		rp_QuestStepComplete(client, g_iQ14);
		rp_SetClientInt(client, i_Bank, rp_GetClientInt(client, i_Bank) + 15000);
		
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez terminé le tutoriel, une voiture vous a été offerte. (Faites /item !)");
		
		
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
}
public Action PostKillHandle(Handle timer, any data) {
	if( data != INVALID_HANDLE )
		CloseHandle(data);
}
