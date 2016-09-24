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
#include <smlib>
#include <colors_csgo>
#include <basecomm>

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

char g_szMonthLong[12][16] =  { "Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre" };
bool g_bWaitingMairieCommand[65];
int g_iMairieQuestionID[65];

public Plugin myinfo =  {
	name = "Utils: Mairie", author = "KoSSoLaX", 
	description = "RolePlay - Utils: Mairie", 
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};
public void OnPluginStart() {
	for (int i = 1; i <= MaxClients; i++)
	if (IsValidClient(i))
		OnClientPostAdminCheck(i);
}
public void OnClientPostAdminCheck(int client) {
	g_iMairieQuestionID[client] = 0;
	g_bWaitingMairieCommand[client] = false;
	rp_HookEvent(client, RP_OnPlayerUse, fwdPlayerUse);
}
public Action fwdPlayerUse(int client) {
	if( rp_GetPlayerZone(client) == MAIRIE_ZONE )
		Draw_Mairie_Main(client);
}
public void fwdCompleteFirstname(int client, any data, char[] message) {
	char tmp[128];
	String_CleanupName(message, tmp, sizeof(tmp));
	g_bWaitingMairieCommand[client] = false;
	
	if (strlen(tmp) >= 3) {
		rp_SetClientString(client, sz_FirstName, tmp, sizeof(tmp));
		Draw_Mairie_Register(client, data + 1);
	}
	else {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre prénom est trop court, veuillez en entrer un autre.");
		Draw_Mairie_Register(client, data);
	}
}
public void fwdCompleteLastname(int client, any data, char[] message) {
	char tmp[128];
	String_CleanupName(message, tmp, sizeof(tmp));
	g_bWaitingMairieCommand[client] = false;
	
	if (strlen(tmp) >= 4) {
		rp_SetClientString(client, sz_LastName, tmp, sizeof(tmp));
		Draw_Mairie_Register(client, data + 1);
		
		char query[1024], tmp2[256];
		rp_GetClientString(client, sz_FirstName, tmp2, sizeof(tmp2));
		Format(tmp2, sizeof(tmp2), "%s%s", tmp2, tmp);
		
		while (ReplaceString(tmp2, sizeof(tmp2), " ", "")) {  }
		while (ReplaceString(tmp2, sizeof(tmp2), "'", "")) {  }
		while (ReplaceString(tmp2, sizeof(tmp2), "\'", "")) {  }
		
		String_ToLower(tmp2, tmp2, sizeof(tmp2));
		
		Format(query, sizeof(query), "SELECT COUNT(*)  FROM `rp_users` WHERE LOWER(REPLACE(REPLACE(REPLACE(CONCAT(`firstname`, '', `lastname`), ' ', ''), '-', ''), '\'', '')) LIKE '%s'", tmp2);
		SQL_TQuery(rp_GetDatabase(), fwdCompleteLastname_Query, query, client, DBPrio_High);
	}
	else {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre nom est trop cours, veuillez en entrer un autre.");
		Draw_Mairie_Register(client, data);
	}
}
public void fwdCompleteLastname_Query(Handle owner, Handle handle, const char[] error, any client) {
	if (SQL_FetchRow(handle)) {
		int res = SQL_FetchInt(handle, 0);
		if (res > 0) {
			CPrintToChat(client, "{lightblue}[TSX-RP]{default} Votre nom/prénom correspond à un autre citoyen, veuillez en entrer un autre.");
			
			rp_SetClientString(client, sz_FirstName, "", 1);
			rp_SetClientString(client, sz_LastName, "", 1);
			rp_ClientSave(client);
			
			Draw_Mairie_Register(client, 1);
			return;
		}
	}
	
	Draw_Mairie_Register(client, 4);
}
void Draw_Mairie_Main(int client) {
	
	if (rp_GetClientInt(client, i_PlayerLVL) >= 6 && rp_GetClientInt(client, i_BirthDay) <= 0) {
		Draw_Mairie_Register(client, 0);
		return;
	}
	if (rp_GetClientInt(client, i_PlayerLVL) >= 20 && !rp_GetClientBool(client, b_PassedRulesTest) ) {
		Draw_Mairie_Questionnaire(client, 0, g_iMairieQuestionID[client]);
		return;
	}
	
	//	PrintToChat(client, "%d --> %d", rp_GetClientPlaytimeJob(client, rp_GetClientJobID(client), true), rp_GetClientPlaytimeJob(client, rp_GetClientInt(client, i_Job), false));
}
void Draw_Mairie_Questionnaire(int client, int step, int qid) {
	char query[1024];
	
	if( step == 0 ) {		
		Menu menu = new Menu(Handle_Mairie);
		
		Format(query, sizeof(query), "Mairie de Princeton\n ");
		Format(query, sizeof(query), "%s\nLes citoyens de Princeton doivent passer un test", query);
		Format(query, sizeof(query), "%s\nsur les connaissances du règlement communal.", query);
		Format(query, sizeof(query), "%s\n \nRépondez correctement à 5 questions en suivant, ", query);
		Format(query, sizeof(query), "%s\npour gagner un gros cadeau!\n ", query);
		menu.SetTitle(query);
		
		menu.AddItem("2 0 1", "Commencer");
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else {
		 
		Format(query, sizeof(query), "SELECT R.`idQuestion`, CONVERT(CONVERT(CONVERT(`question` USING latin1) USING binary) USING UTF8), CONVERT(CONVERT(CONVERT(`reponse` USING latin1) USING binary) USING UTF8), `estVraie` FROM ");
		
		if( qid == 0 ) {
			Format(query, sizeof(query), "%s ( SELECT R.`idQuestion` FROM `ts-x`.`site_nopyj_reponses` R INNER JOIN `ts-x`.`site_nopyj_question` Q ON Q.`id`=R.`idQuestion` WHERE `categorie`=1 GROUP BY `idQuestion` ORDER BY RAND() LIMIT 1) AS A", query);
		}
		else {
			Format(query, sizeof(query), "%s ( SELECT '%d' as `idQuestion` ) AS A", query, g_iMairieQuestionID[client]);
		}
		Format(query, sizeof(query), "%s INNER JOIN `ts-x`.`site_nopyj_reponses` R ON A.`idQuestion`=R.`idQuestion` INNER JOIN `ts-x`.`site_nopyj_question` Q ON Q.`id`=R.`idQuestion`", query);
		Format(query, sizeof(query), "%s WHERE LENGTH(`reponse`)>1 ORDER BY RAND()", query);
		
		SQL_TQuery(rp_GetDatabase(), QUERY_MairieQuestionnaire, query, client + step*1000);
	}
}
public void QUERY_MairieQuestionnaire(Handle owner, Handle handle, const char[] error, any data) {
	
	int client = data % 1000;
	int step = (data - client) / 1000;
	char question[256], response[256], tmp[256], title[1024];
	int estVraie;
	
	Menu menu = new Menu(Handle_Mairie);
	
	while( SQL_FetchRow(handle) ) {
		g_iMairieQuestionID[client] = SQL_FetchInt(handle, 0);
		SQL_FetchString(handle, 1, question, sizeof(question));
		SQL_FetchString(handle, 2, response, sizeof(response));
		estVraie = SQL_FetchInt(handle, 3);
		
		Format(tmp, sizeof(tmp), "2 %d %d", step, estVraie);
		menu.AddItem(tmp, response);
	}
	
	Format(title, sizeof(title), "Mairie de Princeton\n ");
	Format(title, sizeof(title), "%s\nLes citoyens de Princeton doivent passer un test", title);
	Format(title, sizeof(title), "%s\nsur les connaissances du règlement communal.", title);
	
	Format(question, sizeof(question), "Question %d: %s", step, question);
	String_WordWrap(question, 65);
	Format(title, sizeof(title), "%s\n%s\n ", title, question);
	menu.SetTitle(title);
	
	menu.Display(client, MENU_TIME_FOREVER);
}
void Draw_Mairie_Register(int client, int step) {
	Menu menu = new Menu(Handle_Mairie);
	char title[1024], tmp[128], tmp2[128], tmp3[2][32];
	Format(title, sizeof(title), "Mairie de Princeton\n ");
	
	Format(title, sizeof(title), "%s\nLes nouveaux citoyens de Princeton", title);
	Format(title, sizeof(title), "%s\ndoivent s'enregistrer auprès de l'administration.\n ", title);
	
	Format(title, sizeof(title), "%s\nCes informations ne doivent pas obligatoirement", title);
	Format(title, sizeof(title), "%s\ncorrespondent à votre vie réel. Il s'agit", title);
	Format(title, sizeof(title), "%s\nde commencer ici votre vie roleplay.\n ", title);
	
	
	switch (step) {
		case 0: {
			Format(title, sizeof(title), "%s\nÊtes-vous un homme ou une femme?", title);
			
			menu.AddItem("1 0 0", "Je suis un homme");
			menu.AddItem("1 0 1", "Je suis une femme");
		}
		case 1: {
			Format(title, sizeof(title), "%s\nQuel est votre prénom?", title);
			menu.AddItem("_", "Entrez votre prénom RP dans le chat", ITEMDRAW_DISABLED);
			if (!g_bWaitingMairieCommand[client])
				rp_GetClientNextMessage(client, step, fwdCompleteFirstname);
			g_bWaitingMairieCommand[client] = true;
		}
		case 2: {
			rp_GetClientString(client, sz_FirstName, tmp, sizeof(tmp));
			
			Format(title, sizeof(title), "%s\nVotre prénom est-il bien %s ?", title, tmp);
			menu.AddItem("1 2 0", "Non, je souhaite changer");
			menu.AddItem("1 2 1", "Oui, je confirme");
		}
		case 3: {
			Format(title, sizeof(title), "%s\nQuel est votre nom de famille?", title);
			menu.AddItem("_", "Entrez votre nom de famille RP dans le chat", ITEMDRAW_DISABLED);
			if (!g_bWaitingMairieCommand[client])
				rp_GetClientNextMessage(client, step, fwdCompleteLastname);
			g_bWaitingMairieCommand[client] = true;
		}
		case 4: {
			rp_GetClientString(client, sz_LastName, tmp, sizeof(tmp));
			
			Format(title, sizeof(title), "%s\nVotre nom de famille est-il bien %s ?", title, tmp);
			menu.AddItem("1 4 0", "Non, je souhaite changer");
			menu.AddItem("1 4 1", "Oui, je confirme");
		}
		case 5: {
			Format(title, sizeof(title), "%s\nQuel est votre mois de naissance?", title);
			
			menu.AddItem("1 5 1", "Janvier");
			menu.AddItem("1 5 2", "Février");
			menu.AddItem("1 5 3", "Mars");
			menu.AddItem("1 5 4", "Avril");
			menu.AddItem("1 5 5", "Mai");
			menu.AddItem("1 5 6", "Juin");
			menu.AddItem("1 5 7", "Juillet");
			menu.AddItem("1 5 8", "Aout");
			menu.AddItem("1 5 9", "Septembre");
			menu.AddItem("1 5 10", "Octobre");
			menu.AddItem("1 5 11", "Novembre");
			menu.AddItem("1 5 12", "Décembre");
		}
		case 6: {
			Format(title, sizeof(title), "%s\nQuel est votre jour de naissance?", title);
			
			int m = rp_GetClientInt(client, i_BirthMonth);
			
			for (int i = 1; i <= 31; i++) {
				if (i == 31 && (m == 2 || m == 4 || m == 6 || m == 9 || m == 11))
					continue;
				if (i >= 29 && (m == 2))
					continue;
				
				Format(tmp3[0], sizeof(tmp3[]), "1 6 %d", i);
				Format(tmp3[1], sizeof(tmp3[]), "%d%s %s", i, i == 1 ? "ier" : "", g_szMonthLong[m - 1]);
				menu.AddItem(tmp3[0], tmp3[1]);
			}
		}
		case 7: {
			
			rp_GetClientString(client, sz_FirstName, tmp, sizeof(tmp));
			rp_GetClientString(client, sz_LastName, tmp2, sizeof(tmp2));
			
			bool female = rp_GetClientBool(client, b_isFemale);
			int day = rp_GetClientInt(client, i_BirthDay);
			int month = rp_GetClientInt(client, i_BirthMonth);
			
			Format(title, sizeof(title), "%s\nVous êtes donc...", title);
			Format(title, sizeof(title), "%s\%s %s %s,", title, female ? "Mademoiselle" : "Monsieur", tmp, tmp2);
			Format(title, sizeof(title), "%s\nné%s le %d%s %s?", title, female ? "e" : "", -day, day == -1 ? "ier" : "", g_szMonthLong[month - 1]);
			
			menu.AddItem("1 7 0", "Non, je souhaite changer");
			menu.AddItem("1 7 1", "Oui, je confirme");
		}
	}
	
	menu.SetTitle(title);
	menu.Display(client, MENU_TIME_FOREVER);
}
public int Handle_Mairie(Handle menu, MenuAction action, int client, int param2) {
	#if defined DEBUG
	PrintToServer("Handle_Mairie");
	#endif
	if (action == MenuAction_Select) {
		char options[64], explo[3][32];
		GetMenuItem(menu, param2, options, sizeof(options));
		ExplodeString(options, " ", explo, sizeof(explo), sizeof(explo[]));
		PrintToChatAll(options);
		
		int a = StringToInt(explo[0]);
		int b = StringToInt(explo[1]);
		int c = StringToInt(explo[2]);
		
		if (a == 1) {
			switch (b) {
				case 0: {
					rp_SetClientBool(client, b_isFemale, c == 1);
				}
				case 2: {
					if (c != 1) {
						Draw_Mairie_Register(client, b - 1);
						return;
					}
				}
				case 4: {
					if (c != 1) {
						Draw_Mairie_Register(client, b - 1);
						return;
					}
				}
				case 5: {
					rp_SetClientInt(client, i_BirthMonth, c);
				}
				case 6: {
					rp_SetClientInt(client, i_BirthDay, -c);
				}
				case 7: {
					if (c != 1) {
						rp_SetClientInt(client, i_BirthDay, 0);
						Draw_Mairie_Register(client, 0);
						return;
					}
					rp_SetClientInt(client, i_BirthDay, -rp_GetClientInt(client, i_BirthDay));
					PrintHintText(client, "Vous êtes enregistré à la mairie, merci !");
				}
				
			}
			
			Draw_Mairie_Register(client, b + 1);
		}
		if (a == 2) {
			if( c == 1 && b == 5 ) {
				PrintHintText(client, " \n Bravo !");
				rp_SetClientBool(client, b_PassedRulesTest, true);
			}
			else if( c == 1 ) {
				if( b != 0 )
					PrintHintText(client, " \n Bonne réponse !");
				Draw_Mairie_Questionnaire(client, b+1, b == 0 ? g_iMairieQuestionID[client] : 0);
			}
			else {
				PrintHintText(client, " \n Mauvaise réponse :(");
				Draw_Mairie_Questionnaire(client, 1, g_iMairieQuestionID[client]);
			}
			return;
		}
	}
	else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}
