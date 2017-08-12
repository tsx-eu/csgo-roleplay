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
#include <sdkhooks>
#include <smlib>		// https://github.com/bcserv/smlib
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <advanced_motd>// https://forums.alliedmods.net/showthread.php?t=232476

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

public Plugin myinfo = {
	
	name = "Jobs: Tribunal", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Tribunal",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

enum TribunalData {
	td_Plaignant,
	td_Suspect,
	td_Time,
	td_Owner,
	td_ArticlesCount,
	td_AvocatPlaignant,
	td_AvocatSuspect,
	td_TimeMercenaire,
	td_EnquetePlaignant,
	td_EnqueteSuspect,
	td_DoneDedommagement,
	td_Dedommagement,
	td_Dedommagement2,
	td_SuspectArrive,
	
	td_Max
};
int g_cBeam;

// Numéro, Résumé, Heures, Amende, Dédo, Détails
char g_szArticles[30][6][512] = {
	{"221-1-a",		"Meurtre d'un civil",							"18",	"1250",		"1000",	"Toutes atteintes volontaires à la vie d’un citoyen sont condamnées à une peine maximale de 18h de prison et 1250$ d’amende." },
	{"221-1-b",		"Meurtre d'un policier",						"24",	"5500",		"1500",	"Toutes atteintes volontaires à la vie d’un officier des forces de l’ordre sont condamnées à une peine maximale de 24h de prison et 5 500$ d’amende." },
	{"221-1-c",		"Tentative de meurtre",							"12",	"500",		"500",	"Les coups et blessures volontaires ayant provoqué des lésions corporelles sont condamnés à une peine maximale de 12h de prison et 500$ d’amende." },
	{"221-1-d",		"Agression physique",							"6",	"250",		"100",	"Les coups et blessures involontaires n’ayant pas provoqué des lésions corporelles sont condamnés à une peine maximale de 6h de prison et 250$ d’amende." },
	{"221-2",		"Vol",											"6",	"450",		"-1",	"Le vol est un acte punis d’une peine maximale de 6h de prison et 450$ d’amende." },
	{"221-3",		"Manquement convocation",						"18",	"4000",		"0",	"Le manquement à une convocation devant les tribunaux sans motif valable est puni d’une peine maximale de 18h de prison et 4.000$ d'amende." },
	{"221-4",		"Faux aveux / Dénonciations calomnieuses",		"6",	"1500",		"300",	"Les faux aveux ou les dénonciations calomnieuses sont punis d’une peine maximale de 6h de prison et 1500$ d’amende." },
	{"221-5-a",		"Nuisances sonores", 							"6",	"1500", 	"0",	"Les nuisances sonores sont punies d’une peine maximale de 6h de prison et 1 500$ d'amende." },
	{"221-5-b",		"Insultes / irrespect", 						"6",	"1000", 	"1250",	"Les insultes sont passibles d’une peine maximale de 6h de prison et 1000$ d’amende." },
	{"221-5-c",		"Harcèlements / Menaces", 						"6",	"800",		"300",	"Les actes de harcèlement et/ou menaces sont passibles d'une peine maximale de 6h de prison et 800$ d'amende." },
	{"221-6",		"Récidive",										"6",	"15000",	"0",	"Toute personne condamnée pour une récidive vis-à-vis de meurtre ou d'une infraction déjà jugée sera condamnée à une peine plus lourde, l'amende peut-être augmentée progressivement de 15 000$ et la peine de prison de 6h." },
	{"221-7",		"Obstruction ",									"6",	"650",		"0",	"Tout acte obstruant les forces de l’ordre (Masque/Suicide/Pilule/Pots de vins, que ce soit avant ou pendant l’audience/Changement de pseudo délibéré, pendant la recherche du criminel et GHB), ou la fuite délibérée, ou mutinerie, sont passibles d’une peine maximale de 6h de prison et 650$ d'amende. " },
	{"221-8",		"Bavure policière",								"24",	"3000",		"2000",	"Tout acte de maltraitance policière (taser, balle perdue, jail/déjail répétitif...) pourra être rapporté devant les tribunaux. La maltraitance est passible de 24h de prison au maximum, et d'une amende de 3 000$ au maximum" },
	{"221-9",		"Abus de métier",								"6",	"1000",		"500",	"Tout abus d’un métier est passible d’une peine maximale de 6h de prison et 1 000$ d'amende, ainsi qu’un remboursement intégral de la caution prélevée (si abus Justice/Police)." },
	{"221-10-a",	"Fraude",										"24",	"5000",		"0",	"Tout acte de fraude (transaction d'argent) pour éviter des sanctions juridiques peut être rapporté et signalé. Les personnes étant complices de cette fraude peuvent encourir une peine maximale de 24h de prison et 5000$ d'amende." },
	{"221-10-b",	"Association de malfaiteurs",					"6",	"500",		"0",	"Toute association de malfaiteurs (Défense lors de perquisitions notamment) est punissable d’une peine maximale de 6h de prison et 500$ d’amende." },
	{"221-11-a",	"Vente forcée",									"12",	"5000",		"-1",	"Toute personne essayant de vendre sans le consentement libre et éclairé d'une personne peut-être condamnée à une peine maximale de 12h de prison et 5.000$ d’amende, ainsi qu'un remboursement de la totalité de ce dernier. (Le remboursement n’est pas un dédommagement est n’est donc pas soumis aux avocats)." },
	{"221-11-b",	"Refus de vente",								"6",	"1500",		"0",	"Tout refus de vente est punissable par 6h de prison et une amende de 1.500$ au maximum." },
	{"221-12",		"Profiter de la vulnérabilité d’une personne",	"18",	"3000",		"1500",	"Le fait de soumettre une personne à un acte criminel en abusant de sa vulnérabilité ou de sa dépendance à son travail est punis d’une peine maximale de 18h de prison et 3 000$ d’amende en plus de la peine du crime commis" },
	{"221-13-a",	"Destruction de biens d’autrui",				"6",	"1500",		"1000",	"Tout acte volontaire ou involontaire de destruction de biens d'autrui et ce quelque soit les méthodes de destruction utilisées, peut-être condamné par 6h de prison et 1500$ au maximum" },
	{"221-13-b",	"Atteinte à la vie privée",						"6",	"950",		"500",	"Les atteintes à la vie privée telles que l’espionnage, ou l’enregistrement d’une conversation intime, sont punies d’une peine maximale de 6h de prison et 950$ d'amende" },
	{"221-13-c",	"Intrusion dans une propriété privée",			"6",	"800",		"500",	"La violation d’une propriété privée est punie d’une peine maximale de 6h de prison et 800$ d’amende." },
	{"221-13-d",	"Intrusion dans un batiment fédéral",			"18",	"5000",		"500",	"La violation d’un batiment fédéral est punie d’une peine maximale de 18h de prison et 5000$ d’amende." },
	{"221-14-a",	"Usage de produits illicites",					"6",	"1000",		"250",	"Droguer ou alcooliser une personne à son insu est un acte punis d’une peine maximale de 6h de prison et 1000$ d’amende. " },
	{"221-15-a",	"Tentative de corruption",						"24",	"10000",	"0",	"Tout acte de corruption ou de tentative de corruption, est puni d’une peine maximale de 24h de prison et 10 000$ d’amende." },
	{"221-15-b",	"Escroquerie",									"18",	"5000",		"-1",	"Tout acte d’escroquerie est puni d’une peine maximale de 24h de prison et 5 000$ d’amende." },
	{"221-16",		"Séquestration",								"6",	"800",		"500",	"Les actes de séquestrations sont passibles d'une peine maximale de 6h de prison et 800$ d'amende." },
	{"221-17",		"Acte de proxénétisme / prostitution",			"6",	"450",		"0",	"Tout acte de proxénétisme ou de prostitution est passible d'une peine maximale de 6h de prison et 450$ d’amende." },
	{"221-18",		"Asile politique",								"24",	"1500",		"1000",	"Le tribunal est une zone internationale indépendante des lois de la police, tout citoyen y est protégé par asile juridique. De ce fait, tout policier mettant une personne étant dans le tribunal en prison encourt une peine maximale de 24h de prison et 1 500$ d'amende." }
};
char g_szAcquittement[6][32] = { "Non coupable", "Conciliation", "Impossible de prouver les faits", "Déjà condamné", "Plainte annulée", "Nouveau"};
char g_szCondamnation[6][32] = { "Très indulgent", "Indulgent", "Juste", "Sévère", "Très sévère", "Déconnexion"};
float g_flCondamnation[6] = {0.2, 0.4, 0.6, 0.8, 1.0, 1.5};
float g_flCoords[3][2][3];

int g_iArticles[3][ sizeof(g_szArticles) ];
int g_iTribunalData[3][td_Max];
char g_szJugementDATA[65][3][32];
bool g_bClientDisconnected[65];



#define isTribunalDisponible(%1) (g_iTribunalData[%1][td_Owner]<=0?true:false)
#define GetTribunalZone(%1) (%1==1?TRIBUNAL_1:TRIBUNAL_2)
#define GetTribunalJail(%1) (%1==1?TRIBUJAIL_1:TRIBUJAIL_2)

public void OnPluginStart() {
	
	g_flCoords[1][0] = view_as<float>( { -508.0, -818.0, -1870.0 } );
	g_flCoords[1][1] = view_as<float>( { -508.0, -712.0, -1870.0 } );
	
	g_flCoords[2][0] = view_as<float>( { 308.0, -1530.0, -1870.0 } );
	g_flCoords[2][1] = view_as<float>( { 200.0, -1530.0, -1870.0 } );
	
	RegServerCmd("rp_item_enquete",		Cmd_ItemEnquete,		"RP-ITEM",	FCVAR_UNREGISTERED);
	CreateTimer(1.0, Timer_Light, _, TIMER_REPEAT);
	
	for (int i = 1; i <= MaxClients; i++)
		if( IsValidClient(i) )
			OnClientPostAdminCheck(i);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt");
}
public void OnClientPostAdminCheck(int client) {
	g_bClientDisconnected[client] = false;
	rp_HookEvent(client, RP_OnPlayerCommand, fwdCommand);
	
	for (int i = 1; i <= 2; i++) {
		if( !isTribunalDisponible(i) )
			rp_HookEvent(client, RP_OnPlayerHUD, fwdHUD);
	}
}
public void OnClientDisconnect(int client) {
	g_bClientDisconnected[client] = true;
	
	for (int type = 1; type <= 2; type++) {
		
		if( g_iTribunalData[type][td_AvocatPlaignant] == client )
			g_iTribunalData[type][td_AvocatPlaignant] = 0;
		if( g_iTribunalData[type][td_AvocatSuspect] == client )
			g_iTribunalData[type][td_AvocatSuspect] = 0;
		
		if( g_iTribunalData[type][td_Owner] == client || g_iTribunalData[type][td_Plaignant] == client )
			AUDIENCE_Stop(type);
		
		if( g_iTribunalData[type][td_Suspect] == client ) {
			AUDIENCE_Condamner(type, 5);
		}
	}
}
public Action Timer_Light(Handle timer, any none) {
	
	for (int i = 1; i <= 2; i++) {
		TE_SetupBeamPoints(g_flCoords[i][0], g_flCoords[i][1], g_cBeam, g_cBeam, 0, 0, 1.1, 4.0, 4.0, 0, 0.0, tribunalColor(i), 0);
		TE_SendToAll();
		
		
		if( g_iTribunalData[i][td_Suspect] > 0 && g_iTribunalData[i][td_SuspectArrive] == 1 ) {
			int zone = rp_GetPlayerZone(g_iTribunalData[i][td_Suspect]);
			if( GetTribunalType(zone) != i ) {
				float pos[3];
				pos = getZoneMiddle(GetTribunalJail(i));
				rp_ClientTeleport(g_iTribunalData[i][td_Suspect], pos);
			}
		}
	}
	
}
// ----------------------------------------------------------------------------
public Action fwdCommand(int client, char[] command, char[] arg) {
	if( StrContains(command, "tb") == 0 || StrEqual(command, "tribunal") ) {
		return Draw_Menu(client);
	}
	else if( StrContains(command, "jgmt") == 0 ) {
		return Cmd_Jugement(client, arg);
	}
	return Plugin_Continue;
}
public Action Cmd_Jugement(int client, char[] arg) {
	
	int size, heure, amende, p;
	int id = StringToInt(g_szJugementDATA[client][1]);
	int type = StringToInt(g_szJugementDATA[client][2]);
	int length = strlen(arg);
	char buffers[4][32], nick[64], pseudo[sizeof(nick) * 2 + 1];
	
	if( type == 1 )
		size = 4;
	if( type == 2 || type == 3 )
		size = 2;
	
	if( size == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Veuillez selectionner une plainte du Tribunal forum en premier.");
		return Plugin_Handled;
	}
	
	for (int i = 0; i < size; i++) {
		p = SplitString(arg, " ", buffers[i], sizeof(buffers[]));
		if( p > 0 ) {
			for (int j = 0; j <= (length - p); j++)
				arg[j] = arg[j + p];
		}
	}
	
	heure = StringToInt(buffers[2]);
	amende = StringToInt(buffers[3]);
	
	if( !StrEqual(buffers[1], g_szJugementDATA[client][0]) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le code de confirmation est incorrect.");
		return Plugin_Handled;
	}
	
	char query[1024], szSteamID[32];
	char[] escape = new char[length * 2 + 1];
	GetClientAuthId(client, AuthId_Engine, szSteamID, sizeof(szSteamID));
	SQL_EscapeString(rp_GetDatabase(), arg, escape, length*2 + 1);
	
	Format(query, sizeof(query), "UPDATE `ts-x`.`site_report` SET `jail`='%d', `amende`='%d', `juge`='%s', `reason`='%s' WHERE `id`='%d' LIMIT 1;", heure, amende, szSteamID, escape, id);
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
	
	if( type != 3 ) {
		Format(query, sizeof(query), "INSERT INTO `rp_csgo`.`rp_users2` (`steamid`, `xp`, `pseudo`) (SELECT `steamid`, '100', 'Tribunal Forum' FROM `ts-x`.`site_report_votes` WHERE `reportid`=%d AND `vote`=%d GROUP BY `steamid`)", id, type == 1 ? 1 : 0);
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
	}
	
	if( type == 1 ) {
		GetClientName(client, nick, sizeof(nick));
		SQL_EscapeString(rp_GetDatabase(), nick, pseudo, sizeof(pseudo));
		
		Format(query, sizeof(query), "INSERT INTO `rp_csgo`.`rp_users2` (`steamid`, `money`, `jail`, `pseudo`, `steamid2`, `raison`) ( SELECT `report_steamid`, '%d', '%d', '%s', '%s', '%s' FROM `ts-x`.`site_report` WHERE `id`='%d' )", -amende, heure*60, pseudo, szSteamID, escape, id); 
		SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
	}
	
	switch(type) {
		case 1: CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le joueur a été condamné.");
		case 2: CPrintToChat(client, "{lightblue}[TSX-RP]{default} Le joueur a été acquitté.");
		case 3: CPrintToChat(client, "{lightblue}[TSX-RP]{default} La plainte troll a été supprimée.");
		
	}
	
	return Plugin_Handled;
}
Action Draw_Menu(int client) {
	
	int type = GetTribunalType(rp_GetPlayerZone(client));
	
	if( type == 0 )
		return Plugin_Stop;
	if( rp_GetClientJobID(client) != 101 )
		return Plugin_Stop;
	if( rp_GetClientInt(client, i_Job) == 107 && !FormationCanBeMade(type) )
		return Plugin_Stop;
	
	
	if( isTribunalDisponible(type) ) {
		
		Menu menu = new Menu(MenuTribunal);
		menu.SetTitle("Tribunal de Princeton\n ");
		menu.AddItem("start -1", "Débuter une audience");
		menu.AddItem("mariage", "Gestion du mariage");
		if( rp_GetClientInt(client, i_Job) <= 104 && GetConVarInt(FindConVar("hostport")) == 27015 )
			menu.AddItem("forum", "Traiter les plaintes forum");
		
		menu.AddItem("identity", "Changer l'identité");
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else {
		
		char title[512];
		Menu menu = new Menu(MenuTribunal);
		g_iTribunalData[type][td_Dedommagement] = calculerDedo(type);
		
		fwdHUD(client, title, sizeof(title));		
		menu.SetTitle(title);
		
		int admin = (g_iTribunalData[type][td_Owner] == client) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED;
		bool injail = (g_iTribunalData[type][td_SuspectArrive] == 1 ? true:false);
		
		if( admin == ITEMDRAW_DEFAULT ) {
						
			menu.AddItem("articles", "Gestion des articles");
			menu.AddItem("avocat", "Gestion des avocats");
			menu.AddItem("enquete", "Enquêter", (injail) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			
			menu.AddItem("condamner -1", "Condamner", (injail) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
			menu.AddItem("dedomager -1", "Dédommager", (g_iTribunalData[type][td_DoneDedommagement] == 0 && injail && (g_iTribunalData[type][td_AvocatPlaignant] > 0 || g_iTribunalData[type][td_AvocatSuspect] > 0)) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
			menu.AddItem("acquitter -1", "Acquitter", (injail) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
			menu.AddItem("stop 1", "Annuler l'audience", (!injail) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			menu.AddItem("inverser", "Inverser plaignant-suspect", (injail) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
			menu.AddItem("forward", "Changer de juge");
		}
		menu.Display(client, MENU_TIME_FOREVER);
	}
	
	return Plugin_Handled;
}
// ----------------------------------------------------------------------------
Menu AUDIENCE_Start(int client, int type, int plaignant, int suspect) {
	Menu subMenu = null;
	char tmp[64], tmp2[64];
	
	if( plaignant <= 0 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Qui est le plaignant?\n ");
		
		for (int i = 1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			
			if( GetTribunalZone(type) != rp_GetPlayerZone(i) )
				continue;
			
			Format(tmp, sizeof(tmp), "start %d", i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else if( suspect <= 0 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Qui est le suspect?\n ");
		
		for (int i = 1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
#if !defined DEBUG
			if( i == client )
				continue;
			if( i == plaignant )
				continue;
#endif
			Format(tmp, sizeof(tmp), "start %d %d", plaignant, i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else if( g_iTribunalData[type][td_Owner] <= 0 ) {
		g_iTribunalData[type][td_Suspect] = suspect;
		g_iTribunalData[type][td_Plaignant] = plaignant;		
		g_iTribunalData[type][td_Owner] = client;
		
		if( GetClientTeam(client) == CS_TEAM_T ) {
			FakeClientCommand(client, "say /cop");
		}
		
		LogToGame("[TRIBUNAL] [AUDIENCE] Le juge %L convoque %L dans l'affaire l'opposant à %L.", client, suspect, plaignant);
		
		CreateTimer(1.0, Timer_AUDIENCE, type, TIMER_REPEAT);
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			rp_HookEvent(i, RP_OnPlayerHUD, fwdHUD);
		}
	}
	
	return subMenu;
}
Menu AUDIENCE_Stop(int type, int needConfirmation = 0) {
	
	if( needConfirmation == 1 ) {
		
		bool injail = (g_iTribunalData[type][td_SuspectArrive] == 1 ? true:false);
		
		Menu subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Êtes vous sur d'annuler l'audience?\n ");
		
		subMenu.AddItem("tb", "Ne pas annuler l'audience");
		subMenu.AddItem("stop 0", "Annuler l'audience", (!injail) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		
		return subMenu;
	}
	
	if( IsValidClient(g_iTribunalData[type][td_Suspect]) ) {
		rp_SetClientInt(g_iTribunalData[type][td_Suspect], i_SearchLVL, 0);
		rp_SetClientBool(g_iTribunalData[type][td_Suspect], b_IsSearchByTribunal, false);
	}
	
	for (int i = 0; i < view_as<int>(td_Max); i++)
		g_iTribunalData[type][i] = 0;
	
	for (int i = 0; i < sizeof(g_iArticles[]); i++)
		g_iArticles[type][i] = 0;
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		rp_UnhookEvent(i, RP_OnPlayerHUD, fwdHUD);
	}
	return null;
}
Menu AUDIENCE_Articles(int type, int a, int b, int c) {
	Menu subMenu = null;
	char tmp[64];
	
	if( a == 0 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Gestion des articles \n ");
		subMenu.AddItem("articles 1 -1", "Ajouter un article", getMaxArticles(g_iTribunalData[type][td_Owner]) > g_iTribunalData[type][td_ArticlesCount] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
		subMenu.AddItem("articles 2 -1", "Retirer un article", g_iTribunalData[type][td_ArticlesCount] > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
		
	}
	else if( a == 1 && b == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Liste des articles\n ");
		for (int i = 0; i < sizeof(g_szArticles); i++) {
			Format(tmp, sizeof(tmp), "articles 1 %d", i);
			
			subMenu.AddItem(tmp, g_szArticles[i][1]);
		}
	}
	else if( a == 2 && b == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Liste des articles\n ");
		for (int i = 0; i < sizeof(g_szArticles); i++) {
			if( g_iArticles[type][i] <= 0 )
				continue;
			Format(tmp, sizeof(tmp), "articles 2 %d", i);
			
			subMenu.AddItem(tmp, g_szArticles[i][1]);
		}
	}
	else if( a == 1 && b >= 0 ) {
		
		if( StringToInt(g_szArticles[b][4]) == -1 && c != 42 ) {
			
			g_iTribunalData[type][td_Dedommagement2] += c;
			if( g_iTribunalData[type][td_Dedommagement2] < 0 )
				g_iTribunalData[type][td_Dedommagement2] = 0;
			
			subMenu = new Menu(MenuTribunal);
			subMenu.SetTitle("Quel est la valeur de %s?\n   %d$\n ", g_szArticles[b][1], g_iTribunalData[type][td_Dedommagement2]);
			
			Format(tmp, sizeof(tmp), "articles 1 %d %d", b, 5);		subMenu.AddItem(tmp, "Ajouter 5$");
			Format(tmp, sizeof(tmp), "articles 1 %d %d", b, 50);	subMenu.AddItem(tmp, "Ajouter 50$");
			Format(tmp, sizeof(tmp), "articles 1 %d %d", b, 500);	subMenu.AddItem(tmp, "Ajouter 500$\n ");
			
			Format(tmp, sizeof(tmp), "articles 1 %d %d", b, -5);	subMenu.AddItem(tmp, "Retirer 5$");
			Format(tmp, sizeof(tmp), "articles 1 %d %d", b, -50);	subMenu.AddItem(tmp, "Retirer 50$");
			Format(tmp, sizeof(tmp), "articles 1 %d %d", b, -500);	subMenu.AddItem(tmp, "Retirer 500$");
			
			Format(tmp, sizeof(tmp), "articles 1 %d %d", b, 42);	subMenu.AddItem(tmp, "Valider");
		}
		else {
			g_iArticles[type][b]++;
			g_iTribunalData[type][td_ArticlesCount]++;
		}
	}
	else if( a == 2 && b >= 0 ) {
		g_iArticles[type][b]--;
		g_iTribunalData[type][td_ArticlesCount]--;
	}
	
	return subMenu;
}
Menu AUDIENCE_Condamner(int type, int articles) {
	Menu subMenu = null;
	char tmp[64], tmp2[64];
	
	if( IsVolAndRecidive(type) ) {
		CPrintToChatSearch(type, "{lightblue}[TSX-RP]{default} Le juge %N a tenté de faire un abus. Cet incident a été reporté.", g_iTribunalData[type][td_Owner]);
		LogToGame("[CHEATING] [JUGE] [CONDAMNER] %L a tenté de faire une condamnation pour récidive de vol.", g_iTribunalData[type][td_Owner]);
		return null;
	}
	
	if( articles == -1 ) {
		int severity = timeToSeverity(g_iTribunalData[type][td_Time]) - g_iTribunalData[type][td_DoneDedommagement];
		
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Quel est votre verdict?\n ");
		
		int heure, amende;
		calculerJail(type, heure, amende);
		
		for (int i = 0; i < sizeof(g_szCondamnation); i++) {
			Format(tmp, sizeof(tmp), "condamner %d", i);
			Format(tmp2, sizeof(tmp2), "%s %dh %d$", g_szCondamnation[i], RoundFloat(float(heure) * g_flCondamnation[i]),  RoundFloat(float(amende) * g_flCondamnation[i]));
			
			subMenu.AddItem(tmp, tmp2, (i>=severity-1&&i<=severity+1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
		}
	}
	else {
		
		int heure, amende;
		calculerJail(type, heure, amende);
		
		heure = RoundFloat(float(heure) * g_flCondamnation[articles]);
		amende = RoundFloat(float(amende) * g_flCondamnation[articles]);
		
		SQL_Insert(type, 1, articles, heure, amende);
		CPrintToChatSearch(type, "{lightblue}[TSX-RP]{default} %N a été condamné à %d heure%s et %d$ d'amende. Le juge a été %s.", g_iTribunalData[type][td_Suspect], heure, heure >= 2 ? "s" :"",amende, g_szCondamnation[articles]);
		
		AUDIENCE_Stop(type);
	}
	
	return subMenu;
}
Menu AUDIENCE_Acquitter(int type, int articles) {
	Menu subMenu = null;
	char tmp[64];
	if( articles == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Pour quelle raison doit-il être acquitté?\n ");
		for (int i = 0; i < sizeof(g_szAcquittement); i++) {
			Format(tmp, sizeof(tmp), "acquitter %d", i);
			
			subMenu.AddItem(tmp, g_szAcquittement[i]);
		}
	}
	else {
		
		SQL_Insert(type, 0, articles, 0, 0);
		
		CPrintToChatSearch(type, "{lightblue}[TSX-RP]{default} %N a été acquitté: %s.", g_iTribunalData[type][td_Suspect], g_szAcquittement[articles]);
		AUDIENCE_Stop(type);
	}
	
	return subMenu;
}
Menu AUDIENCE_Avocat(int type, int a, int b) {
	Menu subMenu = null;
	char tmp[64], tmp2[64];
	
	if( a == 0 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Quel type d'avocat gérer?\n ");
		subMenu.AddItem("avocat 1 -1", "Avocat de la victime");
		subMenu.AddItem("avocat 2 -1", "Avocat de la défense");
	}
	else if( b == -1 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Qui mettre comme avocat?\n ");
		Format(tmp, sizeof(tmp), "avocat %d 0", a);
		subMenu.AddItem(tmp, "Personne");
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( rp_GetClientInt(i, i_Avocat) <= 0 )
				continue;
			if( g_iTribunalData[type][td_Plaignant] == i )
				continue;
			if( g_iTribunalData[type][td_Suspect] == i )
				continue;
			if( g_iTribunalData[type][td_AvocatPlaignant] == i )
				continue;
			if( g_iTribunalData[type][td_AvocatSuspect] == i )
				continue;
			
			Format(tmp, sizeof(tmp), "avocat %d %d", a, i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else {
		g_iTribunalData[type][a == 1 ? td_AvocatPlaignant : td_AvocatSuspect] = b;
	}
	
	return subMenu;
}
Menu AUDIENCE_Dedommagement(int type) {
	
	if( g_iTribunalData[type][td_DoneDedommagement] == 0 ) {
		
		if( IsVolAndRecidive(type) ) {
			CPrintToChatSearch(type, "{lightblue}[TSX-RP]{default} Le juge %N a tenté de faire un abus. Cet incident a été reporté.", g_iTribunalData[type][td_Owner]);
			LogToGame("[CHEATING] [JUGE] [DEDO] %L a tenté de faire une dédo pour récidive de vol.", g_iTribunalData[type][td_Owner]);
			return null;
		}
		
		g_iTribunalData[type][td_DoneDedommagement] = 1;
		
		int money = calculerDedo(type);
		int client = g_iTribunalData[type][td_Plaignant];
		int target = g_iTribunalData[type][td_Suspect];
		
		rp_ClientMoney(target, i_Money, -money);
		rp_ClientMoney(client, i_Money, money);
		
		CPrintToChatSearch(type, "{lightblue}[TSX-RP]{default} %N a dédommagé %N de %d$.", target, client, money);
	}
	
	return null;
	
}
Menu AUDIENCE_Enquete(int type, int a, int b) {
	Menu subMenu = null;
	char tmp[64], tmp2[64];
	
	if( a == 0 ) {
		
		if( g_iTribunalData[type][td_TimeMercenaire] == 0 && !hasMercenaire() )
			g_iTribunalData[type][td_TimeMercenaire] = 60;
		
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Enquêter\n ");
		subMenu.AddItem("enquete 1", "Convoquer les mercenaires", g_iTribunalData[type][td_TimeMercenaire] < 60 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		subMenu.AddItem("enquete 2", "Enquêter sans mercenaire (100$)", g_iTribunalData[type][td_TimeMercenaire] >= 60 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		subMenu.AddItem("enquete 3", "Enquêter dans les logs", (g_iTribunalData[type][td_EnquetePlaignant] + g_iTribunalData[type][td_EnqueteSuspect]) >= 2 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED );
		
	}
	else if( a == 1 ) {
		if( g_iTribunalData[type][td_TimeMercenaire] < 60 ) {
			CreateTimer(1.0, Timer_MERCENAIRE, type, TIMER_REPEAT);
		}
		
		CPrintToChatSearch(type, "{lightblue}[TSX-RP]{default} Les mercenaires ont été convoqués au Tribunal %d.", type);
	}
	else if( a == 2 || a == 3 ) {
		if( a == 2 &&  b > 0 ) {
			ServerCommand("rp_item_enquete \"%i\" \"%i\"", g_iTribunalData[type][td_Owner], b);
			
			if( b == g_iTribunalData[type][td_Plaignant] )
				g_iTribunalData[type][td_EnquetePlaignant] = 1;
			if( b == g_iTribunalData[type][td_Suspect] )
				g_iTribunalData[type][td_EnqueteSuspect] = 1;
			
			rp_ClientMoney(g_iTribunalData[type][td_Owner], i_Money, -100);
		}
		else if( a == 3 &&  b > 0 ) {
			
			char szURL[512];
			rp_GetClientSSO(g_iTribunalData[type][td_Owner], tmp, sizeof(tmp));
			GetClientAuthId(b, AuthId_Engine, tmp2, sizeof(tmp2));
			
			Format(szURL, sizeof(szURL), "https://www.ts-x.eu/popup.php?&url=/index.php?page=roleplay2%s&hashh=/tribunal/case/%s", tmp, tmp2);
			PrintToConsole(g_iTribunalData[type][td_Owner], "https://www.ts-x.eu/index.php?page=roleplay2#/tribunal/case/%s", tmp2);
			
			AdvMOTD_ShowMOTDPanel(g_iTribunalData[type][td_Owner], "Tribunal", szURL, MOTDPANEL_TYPE_URL);
		}
		else {
			subMenu = new Menu(MenuTribunal);
			subMenu.SetTitle("Enquêter\n ");
			
			int zone;
			int tribu = GetTribunalZone(type);
			int jail = GetTribunalJail(type);
			
			
			for (int i = 1; i <= MaxClients; i++) {
				if( !IsValidClient(i) )
					continue;
				zone = rp_GetPlayerZone(i);
				if( zone == tribu || zone == jail ) {
					Format(tmp, sizeof(tmp), "enquete %d %d", a, i);
					Format(tmp2, sizeof(tmp2), "%N", i);
					subMenu.AddItem(tmp, tmp2);
				}
			}
		}
	}
	
	return subMenu;
}
Menu AUDIENCE_Inverser(int type) {
	int p = g_iTribunalData[type][td_Plaignant];
	int q = g_iTribunalData[type][td_Suspect];
	int r = g_iTribunalData[type][td_AvocatPlaignant];
	int s = g_iTribunalData[type][td_AvocatSuspect];
	
	g_iTribunalData[type][td_Plaignant] = q;
	g_iTribunalData[type][td_Suspect] = p;
	g_iTribunalData[type][td_AvocatPlaignant] = s;
	g_iTribunalData[type][td_AvocatSuspect] = r;

	rp_SetClientInt(q, i_SearchLVL, rp_GetClientInt(p, i_SearchLVL));
	rp_SetClientInt(p, i_SearchLVL, 0);
	rp_SetClientBool(q, b_IsSearchByTribunal, rp_GetClientBool(p, b_IsSearchByTribunal));
	rp_SetClientBool(p, b_IsSearchByTribunal, false);
	
	return null;
}
Menu AUDIENCE_Forward(int type, int a) {
	Menu subMenu;
	char tmp[64], tmp2[64];
	
	if( a == 0 ) {
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Qui mettre comme nouveau juge?\n ");
		
		for (int i = 1; i <= MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			if( rp_GetClientJobID(i) != 101 )
				continue;
			if( i == g_iTribunalData[type][td_Owner] )
				continue;
			
			Format(tmp, sizeof(tmp), "forward %d", i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else {
		CPrintToChatSearch(type, "{lightblue}[TSX-RP]{default} %N cède sa place de juge à %N.", g_iTribunalData[type][td_Owner], a);
		g_iTribunalData[type][td_Owner] = a;
	}
	return subMenu;
}
Menu AUDIENCE_Forum(int client, int a, int b) {
	char query[1024], tmp[64];
	Menu subMenu;
	
	if( a == 0 ) {
		GetClientAuthId(client, AuthId_Engine, tmp, sizeof(tmp));
		
		Format(query, sizeof(query), "SELECT R.`id`, `report_steamid`, COUNT(`vote`) cpt, `name`, SUM(IF(`vote`=1,1,0)) as cpt2 FROM `ts-x`.`site_report` R INNER JOIN `ts-x`.`site_report_votes` V ON V.`reportid`=R.`id` INNER JOIN `rp_csgo`.`rp_users` U ON U.`steamid`=R.`report_steamid` WHERE V.`vote`<>'2' AND R.`jail`=-1 AND R.`own_steamid`<>'%s' AND R.`report_steamid`<>'%s' GROUP BY R.`id` HAVING cpt>=5 ORDER BY cpt DESC;", tmp, tmp);
		SQL_TQuery(rp_GetDatabase(), SQL_AUDIENCE_Forum, query, client);
	}
	else if( b == 0 ) {
		
		rp_GetClientSSO(client, tmp, sizeof(tmp));
			
		Format(query, sizeof(query), "https://www.ts-x.eu/popup.php?&url=/index.php?page=roleplay2%s&hashh=/tribunal/case/%d", tmp, a);
		PrintToConsole(client, "https://www.ts-x.eu/index.php?page=roleplay2#/tribunal/case/%d", a);
		
		AdvMOTD_ShowMOTDPanel(client, "Tribunal", query, MOTDPANEL_TYPE_URL);
		
	 	subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Que faire?\n ");
		
		Format(tmp, sizeof(tmp), "forum %d 1", a); subMenu.AddItem(tmp, "Condamner");
		Format(tmp, sizeof(tmp), "forum %d 2", a); subMenu.AddItem(tmp, "Acquitter");
		Format(tmp, sizeof(tmp), "forum %d 3", a); subMenu.AddItem(tmp, "Plainte troll");
		
	}
	else {
		
		String_GetRandom(g_szJugementDATA[client][0], sizeof(g_szJugementDATA[][]), 4, "23456789abcdefgpqrstuvxyz");
		Format(g_szJugementDATA[client][1], sizeof(g_szJugementDATA[][]), "%d", a);
		Format(g_szJugementDATA[client][2], sizeof(g_szJugementDATA[][]), "%d", b);
		
		if( b == 1 )
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Afin de confirmer votre jugement, tappez maintenant /jgmt %s heure amende raison", g_szJugementDATA[client][0]);
		else if( b == 2 || b == 3 )
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Afin de confirmer votre jugement, tappez maintenant /jgmt %s raison", g_szJugementDATA[client][0]);
	}
	
	return subMenu;
}
Menu AUDIENCE_Identity(int& client, int a, int b, int c) {
	Menu subMenu = null;
	char tmp[64], tmp2[64];
	
	if( a == 0 && b == 0 ) {
		a = client;
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Qui veux changer de sexe?\n ");
		
		for (int i = 1; i<=MaxClients; i++) {
			if( !IsValidClient(i) )
				continue;
			
			if( rp_GetPlayerZone(a) != rp_GetPlayerZone(i) )
				continue;
			
			Format(tmp, sizeof(tmp), "identity %d %d", a, i);
			Format(tmp2, sizeof(tmp2), "%N", i);
			
			subMenu.AddItem(tmp, tmp2);
		}
	}
	else if( c == 0 ) {
		client = b;
		
		subMenu = new Menu(MenuTribunal);
		subMenu.SetTitle("Souhaitez-vous changer de sexe?\nCette opération vous coûtera 2.500$.\n ");
		Format(tmp, sizeof(tmp), "identity %d %d 1", a, b);	subMenu.AddItem(tmp, "Non");
		Format(tmp, sizeof(tmp), "identity %d %d 2", a, b);	subMenu.AddItem(tmp, "Oui");
		
	}
	else {
		
		if( c == 2 ) {
			rp_ClientMoney(client, i_Money, -2500);
			rp_ClientMoney(a, i_Money, 1250);
			rp_SetJobCapital(101, rp_GetJobCapital(101) + 1250);
			
			rp_SetClientBool(client, b_isFemale, !rp_GetClientBool(client, b_isFemale));
			PrintToChatZone( rp_GetPlayerZone(client) , "%N est maintenant ... %s.", client, rp_GetClientBool(client, b_isFemale) ? "une femme" : "un homme");
		}
		else {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous avez refusé de changer de sexe.");
			CPrintToChat(a, "{lightblue}[TSX-RP]{default} %N a refusé de changer de sexe.", client);
			
		}
	}
	
	return subMenu;
}
public void SQL_AUDIENCE_Forum(Handle owner, Handle handle, const char[] error, any client) {
	
	
	if( SQL_GetRowCount(handle) == 0 ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Il n'y a aucun cas à traiter pour le moment.");
		return;
	}
	
	Menu subMenu = new Menu(MenuTribunal);
	subMenu.SetTitle("Plainte du Tribunal Forum\n ");
	int id, vote, cond;
	char tmp[4][64];
	
	while( SQL_FetchRow(handle) ) {
		id = SQL_FetchInt(handle, 0);
		vote = SQL_FetchInt(handle, 2);
		cond = SQL_FetchInt(handle, 4);
		SQL_FetchString(handle, 1, tmp[0], sizeof(tmp[]));
		SQL_FetchString(handle, 3, tmp[1], sizeof(tmp[]));
		
		Format(tmp[2], sizeof(tmp[]), "forum %d", id);
		Format(tmp[3], sizeof(tmp[]), "%s - %d/%d", tmp[1], cond, vote);
		
		subMenu.AddItem(tmp[2], tmp[3]);
	}
	
	subMenu.Display(client, MENU_TIME_FOREVER);
	
	return;
}
// ----------------------------------------------------------------------------
public int MenuTribunal(Handle menu, MenuAction action, int client, int param2) {
	if( action == MenuAction_Select ) {
		char options[64], expl[4][32];
		GetMenuItem(menu, param2, options, sizeof(options));
		
		ExplodeString(options, " ", expl, sizeof(expl), sizeof(expl[]));
		int a = StringToInt(expl[1]);
		int b = StringToInt(expl[2]);
		int c = StringToInt(expl[3]);
		
		int type = GetTribunalType(rp_GetPlayerZone(client));
		Menu subMenu = null;
		bool subCommand = false;
		
		if( StrEqual(expl[0], "start") )
			subMenu = AUDIENCE_Start(client, type, a, b);
		else if( StrEqual(expl[0], "forum") )
			subMenu = AUDIENCE_Forum(client, a, b);
		else if( StrEqual(expl[0], "stop") )
			subMenu = AUDIENCE_Stop(type, a);
		else if( StrEqual(expl[0], "articles") )
			subMenu = AUDIENCE_Articles(type, a, b, c);
		else if( StrEqual(expl[0], "acquitter") )
			subMenu = AUDIENCE_Acquitter(type, a);
		else if( StrEqual(expl[0], "condamner") )
			subMenu = AUDIENCE_Condamner(type, a);
		else if( StrEqual(expl[0], "avocat") )
			subMenu = AUDIENCE_Avocat(type, a, b);
		else if( StrEqual(expl[0], "enquete") )
			subMenu = AUDIENCE_Enquete(type, a, b);
		else if( StrEqual(expl[0], "dedomager") )
			subMenu = AUDIENCE_Dedommagement(type);
		else if( StrEqual(expl[0], "inverser") )
			subMenu = AUDIENCE_Inverser(type);
		else if( StrEqual(expl[0], "forward") )
			subMenu = AUDIENCE_Forward(type, a);
		else if( StrEqual(expl[0], "identity") )
			subMenu = AUDIENCE_Identity(client, a, b, c);
		else
			subCommand = true;
		
		if( subCommand )
			FakeClientCommand(client, "say /%s", expl[0]);
		else if( subMenu == null )
			Draw_Menu(client);
		else
			subMenu.Display(client, MENU_TIME_FOREVER);
	}
	else if( action == MenuAction_End ) {
		CloseHandle(menu);
	}
	return 0;
}
public Action Timer_MERCENAIRE(Handle timer, any type) {
	if( g_iTribunalData[type][td_TimeMercenaire] > 60 )
		return Plugin_Stop;
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetClientJobID(i) == 41 ) {
			if( rp_GetPlayerZone(i) == GetTribunalZone(type) )
				return Plugin_Stop;
			
			PrintHintText(i, "Vos services d'enquêteur sont requis au Tribunal n°%d.", type);
		}
	}
	
	g_iTribunalData[type][td_TimeMercenaire]++;
	return Plugin_Continue;
}
public Action Timer_AUDIENCE(Handle timer, any type) {
	
	int target = g_iTribunalData[type][td_Suspect];
	int time = g_iTribunalData[type][td_Time];
	int zone = rp_GetPlayerZone(target);
	int jail = GetTribunalJail(type);
	
	if( !IsValidClient(target) ) {
		AUDIENCE_Stop(type);
		return Plugin_Stop;
	}
	
	if( g_iTribunalData[type][td_ArticlesCount] == 0 ) {
		PrintHintText(g_iTribunalData[type][td_Owner], "La convocation commencera dès que vous aurez ajoutez le premier article.");
		return Plugin_Continue;
	}
		
	if( time < 60 && time % 20 == 0 ) {
		CPrintToChatSearch(type, "{lightblue}[TSX-RP]{default} %N est convoqué par le {green}Tribunal n°%d{default} de Princeton [%d/3].", target, type, time/20 + 1);
		LogToGame("[TRIBUNAL] [AUDIENCE] Le juge %L a convoque %L [%d/3].", g_iTribunalData[type][td_Owner], target, time/20 + 1);
	}
	else if( time % 60 == 0 ) {
		CPrintToChatSearch(type, "{lightblue}[TSX-RP]{default} %N est recherché par le {green}Tribunal n°%d{default} de Princeton depuis %d minutes.", target, type, time/60);
		LogToGame("[TRIBUNAL] [AUDIENCE] Le juge %L recherche %L depuis %d minutes.", g_iTribunalData[type][td_Owner], target, time/60);
		
		if( time >= 24*60 )
			rp_SetClientInt(target, i_SearchLVL, 5);
		else
			rp_SetClientInt(target, i_SearchLVL, timeToSeverity(time));
		
		rp_SetClientBool(target, b_IsSearchByTribunal, true);
	}
	
	if( zone == jail ) {
		CPrintToChatSearch(type, "{lightblue}[TSX-RP]{default} %N est arrivé après %d minutes.", target, time/60);
		LogToGame("[TRIBUNAL] [AUDIENCE] Le juge %L termine la convocation de %L après %d minute%s.", g_iTribunalData[type][td_Owner], target, time/60, time/60 >= 2 ? "s":"");
		g_iTribunalData[type][td_SuspectArrive] = 1;
		rp_SetClientBool(target, b_IsSearchByTribunal, false);
		Draw_Menu(g_iTribunalData[type][td_Owner]);
		return Plugin_Stop;
	}
	
	float mid[3];
	mid = getZoneMiddle(jail);
	
	ServerCommand("sm_effect_gps %d %f %f %f", target, mid[0], mid[1], mid[2]);
	PrintHintText(target, "Vous êtes attendu au tribunal n°%d de Princeton. Venez <u>immédiatement</u> pour un jugement <font color='#00cc00'>%s</font>.", type, g_szCondamnation[timeToSeverity(time)]);
	
	g_iTribunalData[type][td_Time]++;
	return Plugin_Continue;
}
public Action fwdHUD(int client, char[] szHUD, const int size) {
	int type = GetTribunalType( rp_GetPlayerZone(client) );
	
	if( type > 0 && !isTribunalDisponible(type) ) {
		int heure, amende;
		Format(szHUD, size, "Tribunal de Princeton, affaire opposant\n%N   et   %N\nJuge: %N", g_iTribunalData[type][td_Plaignant], g_iTribunalData[type][td_Suspect], g_iTribunalData[type][td_Owner]);
		
		if( g_iTribunalData[type][td_AvocatPlaignant] ) {
			Format(szHUD, size, "%s\nAvocat de la victime: %N", szHUD, g_iTribunalData[type][td_AvocatPlaignant]);
		}
		if( g_iTribunalData[type][td_AvocatSuspect] ) {
			Format(szHUD, size, "%s\nAvocat de la défense: %N", szHUD, g_iTribunalData[type][td_AvocatSuspect]);
		}
		
		Format(szHUD, size, "%s\n ", szHUD);
		
		if( g_iTribunalData[type][td_ArticlesCount] > 0 ) {
			Format(szHUD, size, "%s\n \nCharges:\n ", szHUD);
			for (int i = 0; i < sizeof(g_szArticles); i++) {
				if( g_iArticles[type][i] <= 0 )
					continue;
				
				Format(szHUD, size, "%s %2dx   %s\n ", szHUD, g_iArticles[type][i], g_szArticles[i][1]);
				
				heure += (g_iArticles[type][i] * StringToInt(g_szArticles[i][2]));
				amende += (g_iArticles[type][i] * StringToInt(g_szArticles[i][3]));
			}
			Format(szHUD, size, "%s\nPeine encourue: %d heure%s %d$ d'amende", szHUD, heure, heure >= 2 ? "s" : "",amende);
			if( g_iTribunalData[type][td_Dedommagement] > 0 )
				Format(szHUD, size, "%s\nDédommagement possible: %d$", szHUD, g_iTribunalData[type][td_Dedommagement]);
		}
		else {
			Format(szHUD, size, "%s\nEn attente d'un article pour débuter l'audience", szHUD, heure, amende);
		}
		
		Format(szHUD, size, "%s\n ", szHUD);
		return Plugin_Changed;
	}
	else if( rp_GetClientInt(client, i_Avocat) > 0 ) {
		for (int i = 1; i <= 2; i++) {
			if( g_iTribunalData[i][td_AvocatPlaignant] == client || g_iTribunalData[i][td_AvocatSuspect] == client )
				PrintHintText(client, "Vos services d'avocat sont requis au Tribunal n°%d", i);
		}
	}
	return Plugin_Continue;
}
// ----------------------------------------------------------------------------
int[] tribunalColor(int type) {
	int color[4];
	color[3] = 128;
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		
		if( rp_GetClientJobID(i) == 101 && !rp_GetClientBool(i, b_IsAFK) ) {
			if( type == 1 && rp_GetPlayerZone(i) == TRIBUNAL_1 )
				color[1] = 255;
			else if( type == 2 && rp_GetPlayerZone(i) == TRIBUNAL_2 )
				color[1] = 255;
		}
	}
	if( color[1] == 0 ) {
		color[0] = 255;
		color[1] = 255;
	}
	
	if( !isTribunalDisponible(type) ) {
		color[0] = 255;
		color[1] = 0;
	}
	
	return color;
}
stock void CPrintToChatSearch(int type, const char[] message, any...) {
	char buffer[MAX_MESSAGE_LENGTH];
	VFormat(buffer, sizeof(buffer), message, 3);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i))
			continue;
		
		if( i == g_iTribunalData[type][td_Suspect] || GetTribunalType(rp_GetPlayerZone(i)) == type || rp_GetClientJobID(i) == 1 || rp_GetClientJobID(i) == 101 ) {
			CPrintToChat(i, "{lightblue} ================================ ");
			CPrintToChat(i, buffer);
			CPrintToChat(i, "{lightblue} ================================ ");
		}
	}
}
float[] getZoneMiddle(int zone) {
	float middle[3];
	middle[0] = (rp_GetZoneFloat(zone, zone_type_min_x) + rp_GetZoneFloat(zone, zone_type_max_x)) / 2.0;
	middle[1] = (rp_GetZoneFloat(zone, zone_type_min_y) + rp_GetZoneFloat(zone, zone_type_max_y)) / 2.0;
	middle[2] = (rp_GetZoneFloat(zone, zone_type_min_z) + rp_GetZoneFloat(zone, zone_type_max_z)) / 2.0 - 64.0;
	return middle;
}
int timeToSeverity(int time) {
	if( time < (1*60) )	return 0;
	if( time < (4*60) )	return 1;
	if( time < (8*60) )	return 2;
	if( time < (12*60))	return 3;
	return 4;
}
int getMaxArticles(int client) {
	int job = rp_GetClientInt(client, i_Job);
	switch (job) {
		case 101: return 20;
		case 102: return 20;
		case 103: return 15;
		case 104: return 10;
		case 105: return 5;
		case 106: return 3;
		case 107: return 2;		
	}
	return 0;
}
int GetTribunalType(int zone) {
	if( zone == TRIBUNAL_1 || zone == TRIBUJAIL_1 || zone == BUREAU_1 )
		return 1;
	if( zone == TRIBUNAL_2 || zone == TRIBUJAIL_2 || zone == BUREAU_2 || zone == JURRY_2 )
		return 2;
	
	return 0;
}
bool FormationCanBeMade(int type) {
	
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetClientJobID(i) != 101 )
			continue;
		if( rp_GetClientInt(i, i_Job) == 107 )
			continue;
		if( rp_GetClientBool(i, b_IsAFK) == true )
			continue;
		if( GetTribunalType(rp_GetPlayerZone(i)) != type )
			continue;
		
		return true;
	}
	return false;
}
void SQL_Insert(int type, int condamne, int condamnation, int heure, int amende) {
	char query[1024], szSteamID[5][32], charges[128], nick[64], pseudo[ sizeof(nick)*2+1 ];
	
	
	
	int dedommage = 0;
	if( g_iTribunalData[type][td_DoneDedommagement] == 1 )
		dedommage = calculerDedo(type);
	
	for (int i = 0; i < sizeof(g_szArticles); i++) {
		if( g_iArticles[type][i] <= 0 )
			continue;
		
		Format(charges, sizeof(charges), "%s%dX %s, ", charges, g_iArticles[type][i], g_szArticles[i][0]);
	}
	
	int data[6];
	data[0] = g_iTribunalData[type][td_Plaignant];
	data[1] = g_iTribunalData[type][td_Suspect];
	data[2] = heure;
	data[3] = amende;
	data[4] = dedommage;
	data[5] = g_iTribunalData[type][td_Time];	
	
	Action a;
	Call_StartForward(rp_GetForwardHandle(g_iTribunalData[type][td_Owner], RP_OnJugementOver));
	Call_PushCell(g_iTribunalData[type][td_Owner]);
	Call_PushArray(data, sizeof(data) );
	Call_PushArray(g_iArticles[type], sizeof(g_iArticles[]) );
	Call_Finish(a);
	
	
	charges[strlen(charges) - 2] = 0;
	
	rp_SetJobCapital(101, rp_GetJobCapital(101) + amende);
	
	rp_ClientMoney(g_iTribunalData[type][td_Owner], i_AddToPay, 500);
	rp_SetJobCapital(101, rp_GetJobCapital(101) - 500);
	
	if( g_iTribunalData[type][td_EnquetePlaignant] ) {
		rp_ClientMoney(g_iTribunalData[type][td_Owner], i_AddToPay, 100);
		rp_SetJobCapital(101, rp_GetJobCapital(101) - 100);
	}
	if( g_iTribunalData[type][td_EnqueteSuspect] ) {
		rp_ClientMoney(g_iTribunalData[type][td_Owner], i_AddToPay, 100);
		rp_SetJobCapital(101, rp_GetJobCapital(101) - 100);
	}
	
	rp_ClientXPIncrement(g_iTribunalData[type][td_Owner], 250);
	
	GetClientAuthId(g_iTribunalData[type][td_Owner], AuthId_Engine, szSteamID[0], sizeof(szSteamID[]));
	GetClientAuthId(g_iTribunalData[type][td_Plaignant], AuthId_Engine, szSteamID[1], sizeof(szSteamID[]));
	GetClientAuthId(g_iTribunalData[type][td_Suspect], AuthId_Engine, szSteamID[2], sizeof(szSteamID[]));
	
	if( IsValidClient(g_iTribunalData[type][td_AvocatPlaignant]) ) {
		GetClientAuthId(g_iTribunalData[type][td_AvocatPlaignant], AuthId_Engine, szSteamID[3], sizeof(szSteamID[]));
		rp_ClientXPIncrement(g_iTribunalData[type][td_AvocatPlaignant], 100);
	}
	if( IsValidClient(g_iTribunalData[type][td_AvocatSuspect]) ) {
		GetClientAuthId(g_iTribunalData[type][td_AvocatSuspect], AuthId_Engine, szSteamID[4], sizeof(szSteamID[]));
		rp_ClientXPIncrement(g_iTribunalData[type][td_AvocatSuspect], 100);
	}
	
	Format(query, sizeof(query), "INSERT INTO `rp_audiences` (`id`, `juge`, `plaignant`, `suspect`, `avocat-plaignant`, `avocat-suspect`, `temps`, `condamne`, `charges`, `condamnation`, `heure`, `amende`, `dedommage`) VALUES(NULL,");
	Format(query, sizeof(query), "%s '%s', '%s', '%s', '%s', '%s', '%d', '%d', '%s', '%d', '%d', '%d', '%d');", query, szSteamID[0], szSteamID[1], szSteamID[2], szSteamID[3], szSteamID[4],
	g_iTribunalData[type][td_Time], condamne, charges, condamnation, heure, amende, dedommage);	
	SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
	
	if( condamne ) {
		
		if( IsValidClient(g_iTribunalData[type][td_Suspect]) && !g_bClientDisconnected[ g_iTribunalData[type][td_Suspect] ] ) {
			rp_ClientMoney(g_iTribunalData[type][td_Suspect], i_Bank, -amende);
			rp_SetClientInt(g_iTribunalData[type][td_Suspect], i_JailTime, rp_GetClientInt(g_iTribunalData[type][td_Suspect], i_JailTime) + (heure * 60));
			
			rp_SetClientInt(g_iTribunalData[type][td_Suspect], i_JailledBy, g_iTribunalData[type][td_Owner]);
			
			ServerCommand("rp_SendToJail %d", g_iTribunalData[type][td_Suspect]);
		}
		else {
		
			GetClientName(g_iTribunalData[type][td_Owner], nick, sizeof(nick));
			SQL_EscapeString(rp_GetDatabase(), nick, pseudo, sizeof(pseudo));
			
			int dedo = calculerDedo(type);
			
			Format(query, sizeof(query), "INSERT INTO `rp_users2` (`id`, `steamid`, `money`, `jail`, `pseudo`, `steamid2`, `raison`) VALUES (NULL,");
			Format(query, sizeof(query), "%s '%s', '%d', '%d', '%s', '%s', '%s');", query, szSteamID[2], - amende - dedo, heure * 60, pseudo, szSteamID[0], "condamné par le Tribunal"); 
			SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
			
			Format(query, sizeof(query), "INSERT INTO `rp_users2` (`id`, `steamid`, `money`, `pseudo`, `steamid2`, `raison`) VALUES (NULL,");
			Format(query, sizeof(query), "%s '%s', '%d', '%s', '%s', '%s');", query, szSteamID[1], dedo, pseudo, szSteamID[2], "dédommagement"); 
			SQL_TQuery(rp_GetDatabase(), SQL_QueryCallBack, query);
			
		}
	}
}
bool hasMercenaire() {
	for (int i = 1; i <= MaxClients; i++) {
		if( !IsValidClient(i) )
			continue;
		if( rp_GetClientJobID(i) == 41 )
			return true;
	}
	return false;
}
int calculerDedo(int type) {
	
	int amende;
	for (int i = 0; i < sizeof(g_szArticles); i++) {
		if( g_iArticles[type][i] <= 0 )
			continue;
		
		amende += (g_iArticles[type][i] * StringToInt(g_szArticles[i][4]));
	}
	return RoundToCeil(float(amende) * getAvocatRatio(g_iTribunalData[type][td_AvocatPlaignant])) + g_iTribunalData[type][td_Dedommagement2];
}
void calculerJail(int type, int& heure, int& amende) {
	for (int i = 0; i < sizeof(g_szArticles); i++) {
		if( g_iArticles[type][i] <= 0 )
			continue;
		heure += (g_iArticles[type][i] * StringToInt(g_szArticles[i][2]));
		amende += (g_iArticles[type][i] * StringToInt(g_szArticles[i][3]));
	}
}
float getAvocatRatio(int client) {
	int pay = rp_GetClientInt(client, i_Avocat);
	if (pay <= 0)	return 0.0;
	if (pay < 175)	return 0.5;
	if (pay < 300)	return 0.75;
	return 1.0;
	
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemEnquete(int args) {
	
	int client = GetCmdArgInt(1);
	int target = GetCmdArgInt(2);
	char tmp[255];
	
	if( rp_GetClientJobID(client) == 101 ) {
		int type = GetTribunalType( rp_GetPlayerZone(client) );
		if( type > 0 ) {
			if( target == g_iTribunalData[type][td_Plaignant] )
				g_iTribunalData[type][td_EnquetePlaignant] = 1;
			if( target == g_iTribunalData[type][td_Suspect] )
				g_iTribunalData[type][td_EnqueteSuspect] = 1;
		}
	}
	
	
	
	rp_IncrementSuccess(client, success_list_detective);
	Handle menu = CreateMenu(MenuNothing);
	SetMenuTitle(menu, "Information sur %N\n ", target);
	
	PrintToConsole(client, "\n\n\n\n\n -------------------------------------------------------------------------------------------- ");
	
	rp_GetZoneData(rp_GetPlayerZone(target), zone_type_name, tmp, sizeof(tmp));
	
	AddMenu_Blank(client, menu, "Localisation: %s", tmp);	
	
	int killedBy = rp_GetClientInt(target, i_LastKilled_Reverse);
	if( IsValidClient(killedBy) ) {
		
		if( rp_GetClientInt(target, i_SearchLVL) >= 4 ) {
			rp_SetClientInt(target, i_Cryptage, 0);
		}
		
		if( Math_GetRandomInt(1, 100) < rp_GetClientInt(target, i_Cryptage)*20 ) {
			
			String_GetRandom(tmp, sizeof(tmp), 24);
			
			AddMenu_Blank(client, menu, "Il a tué: %s", tmp);
			CPrintToChat(target, "{lightblue}[TSX-RP]{default} Votre pot de vin envers un mercenaire vient de vous sauver.");
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L n'a pas montré qui l'a tué pour cause de pot de vin.", target);
		}
		else {	
			AddMenu_Blank(client, menu, "Il a tué: %N", killedBy);
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a montré qu'il a tué %L.", target, killedBy);
		}
	}
	else{
		LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a révélé qu'il n'a tué personne", target, killedBy);
	}
	
	if( rp_GetClientInt(target, i_KillingSpread) > 0 )
		AddMenu_Blank(client, menu, "Meurtre consécutif: %i", rp_GetClientInt(target, i_KillingSpread) );
	
	int killed = rp_GetClientInt(target, i_LastKilled);
	if( IsValidClient(killed) ) {
		
		if( rp_GetClientInt(killed, i_SearchLVL) >= 4 ) {
			rp_SetClientInt(killed, i_Cryptage, 0);
		}
		
		if( Math_GetRandomInt(1, 100) < rp_GetClientInt(killed, i_Cryptage)*20 ) {	
			
			String_GetRandom(tmp, sizeof(tmp), 24);
			
			AddMenu_Blank(client, menu, "%s, l'a tué", tmp);
			CPrintToChat(killed, "{lightblue}[TSX-RP]{default} Votre pot de vin envers un mercenaire vient de vous sauver.");
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L n'a pas montré qui l'a tué pour cause de pot de vin.", target);
		}
		else {
			AddMenu_Blank(client, menu, "%N, l'a tué", killed);
			LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a montré que %L l'a tué.", target, killed);
		}
	}
	else{
		LogToGame("[TSX-RP] [ENQUETE] Une enquête effectuée sur %L a révélé qu'il n'a été tué par personne.", target, killed);
	}
	
	if( IsValidClient(rp_GetClientInt(target, i_LastVol)) ) 
		AddMenu_Blank(client, menu, "%N, l'a volé", rp_GetClientInt(target, i_LastVol) );
	
	AddMenu_Blank(client, menu, "--------------------------------");
	
	AddMenu_Blank(client, menu, "Niveau d'entraînement: %i", rp_GetClientInt(target, i_KnifeTrain));
	AddMenu_Blank(client, menu, "Précision de tir: %.2f", rp_GetClientFloat(target, fl_WeaponTrain));
	
	int count=0;
	Format(tmp, sizeof(tmp), "Permis possédé:");
	
	if( rp_GetClientBool(target, b_License1) ) {	Format(tmp, sizeof(tmp), "%s léger", tmp);	count++;	}
	if( rp_GetClientBool(target, b_License2) ) {	Format(tmp, sizeof(tmp), "%s lourd", tmp);	count++;	}
	if( rp_GetClientBool(target, b_LicenseSell) ) {	Format(tmp, sizeof(tmp), "%s vente", tmp);	count++;	}
	
	if( count == 0 ) {
		Format(tmp, sizeof(tmp), "%s Aucun", tmp);
	}
	AddMenu_Blank(client, menu, "%s.", tmp);
	
	AddMenu_Blank(client, menu, "Argent: %i$ - Banque: %i$", rp_GetClientInt(target, i_Money), rp_GetClientInt(target, i_Bank));
	
	count = 0;
	Format(tmp, sizeof(tmp), "Appartement possédé: ");
	for (int i = 1; i <= 100; i++) {
		if( rp_GetClientKeyAppartement(target, i) ) {
			count++;
			if( count > 1 )
				Format(tmp, sizeof(tmp), "%s, ", tmp);
			Format(tmp, sizeof(tmp), "%s%d", tmp, i);
		}	
	}
	
	if( count == 0 )
		Format(tmp, sizeof(tmp), "%s Aucun", tmp);
	
	AddMenu_Blank(client, menu, tmp);
	
	AddMenu_Blank(client, menu, "Taux d'alcoolémie: %.3f", rp_GetClientFloat(client, fl_Alcool));
	
	CPrintToChat(client, "{lightblue}[TSX-RP]{default} Ces informations ont été envoyées dans votre console.");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_DURATION);
}
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
bool IsVolAndRecidive(int type) {
	int vol = 0;
	int recidive = 0;
	int other = 0;
	
	for (int i = 0; i < sizeof(g_iArticles[]); i++) {
		if( g_iArticles[type][i] <= 0 )
			continue;
		if( i == 2 )
			vol++;
		else if( i == 8 )
			recidive++;
		else
			other++;
	}
	if( vol > 0 && recidive > 0 && other == 0 )
		return true;
	return false;
}
// ----------------------------------------------------------------------------
void AddMenu_Blank(int client, Handle menu, const char[] myString , any ...) {
	char[] str = new char[ strlen(myString)+255 ];
	VFormat(str, (strlen(myString)+255), myString, 4);
	
	AddMenuItem(menu, "none", str, ITEMDRAW_DISABLED);
	PrintToConsole(client, str);
}
