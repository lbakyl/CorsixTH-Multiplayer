 --[[ Copyright (c) 2010 Manuel "Roujin" Wolf

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. --]]
-- Translator warning:
-- Theme Hospital's original bitmap fonts have a limited character set, and
-- some letters are missing; supported characters are case-sensitive.
-- Unsupported characters appear as "?" in game. See the supported characters:
-- https://github.com/CorsixTH/CorsixTH/wiki/Localization
-- Translators may use plain-character substitutions (for example, "e" for an
-- accented "e").
-- If substitutions are unsuitable, change Font("cp437") to Font("unicode")
-- to use the Unicode font instead. You may translate this note into this
-- file's language if that would help other translators.

-- Thanks to Michael "michederoide" Armbruster for some additional corrections!

-- Note: This file contains UTF-8 text. Make sure your editor is set to UTF-8.

Font("cp437")
Language("Deutsch", "German", "de", "ger", "deu")
Inherit("english")
Inherit("original_strings", 2)
IsArabicNumerals(true)

-------------------------------  OVERRIDE  ----------------------------------
diseases.broken_wind.cure = " Therapie: Eine spezielle Mixtur aus der Pharma-Theke sorgt für Windstille." -- original string mentioned inflation, which is plain wrong.
diseases.corrugated_ankles.cure = "Therapie: Eine Schwester verabreicht dem Patienten ein leicht toxisches Gebräu, welches das Bein wieder strafft." -- original string mentioned applying a cast, which is wrong and misleads people to think of fracture clinic
fax.vip_visit_query.vip_name = "%s hat den Wunsch geäußert, Ihr Krankenhaus besuchen zu wollen." -- text was missing
fax.vip_visit_query.choices.invite = "Lassen Sie dem V.I.P. eine offizielle Einladung zukommen." -- text was ferusing instead of inviting

fax.vip_visit_query.choices.refuse = "Speisen Sie den V.I.P. mit einer Entschuldigung ab." -- text was missing

fax.vip_visit_result.vip_remarked_name = "%s hat Ihr Krankenhaus besucht."
fax.vip_visit_result.cash_grant = "Ihnen wurde ein Geldbonus von %d gewährt."
fax.vip_visit_result.rep_boost = "Ihr Ruf in der Öffentlichkeit hat sich gebessert."
fax.vip_visit_result.rep_loss = "Ihr Ruf hat gelitten."
fax.vip_visit_result.close_text = "Danke, dass Sie unser Krankenhaus besucht haben." -- text was missing

fax.emergency.choices.accept = "Ja, ich übernehme diesen Notfall!"
fax.emergency.choices.refuse = "Nein, ich weigere mich diesen Notfall zu übernehmen!"
fax.emergency.location = "Wir haben einen Notruf aus dem %s erhalten." -- wrong spelling
fax.emergency.num_disease = "Es handelt sich um %d Personen mit %s, die sofort behandelt werden müssen." -- wrong spelling
fax.emergency.num_disease_singular = "Es handelt sich um eine Person mit %s, die sofort behandelt werden muss." -- wrong spelling
fax.emergency.cure_possible = "Wir können diesen Notfall übernehmen."
fax.emergency.cure_not_possible_build_and_employ = "Um den Notfall übernehmen zu können, müssen wir eine %s bauen und zusätzliches Personal einstellen."
fax.emergency.cure_not_possible_build = "Um den Notfall übernehmen zu können, müssen wir eine %s bauen."
fax.emergency.cure_not_possible_employ = "Um den Notfall übernehmen zu können, müssen wir zusätzliches Personal einstellen."
fax.emergency.cure_not_possible = "Wir können diesen Notfall im Moment keinesfalls übernehmen."
fax.emergency.bonus = "Wenn wir keinen Patienten verlieren, erhalten wir einen Geldbonus von maximal %d. Sollten wir es jedoch vermasseln, wird unser Ruf Schaden nehmen."
fax.emergency_result.close_text = "Danke, ich habe gerne geholfen."
fax.emergency_result.earned_money = "Sie erhalten von maximal %d einen Geldbonus von %d."
fax.emergency_result.saved_people = "Vielen Dank für Ihre Hilfe! Sie haben %d von insgesamt %d gerettet."

fax.disease_discovered_patient_choice.choices.send_home = "Schicken Sie den Patienten nach Hause." -- wrong text for button
fax.disease_discovered_patient_choice.choices.wait = "Sorgen Sie dafür, dass der Patient eine Weile im Krankenhaus wartet." -- wrong text for button
fax.disease_discovered_patient_choice.choices.research = "Schicken Sie den Patienten in die Forschungsabteilung." -- wrong text for button
fax.disease_discovered_patient_choice.need_to_build_and_employ = "Um diese Krankheit heilen zu können, müssen wir eine %s bauen und zusätzliches Personal einstellen." -- text was missing
fax.disease_discovered_patient_choice.need_to_build = "Um diese Krankheit heilen zu können, müssen wir eine %s bauen." -- text was missing
fax.disease_discovered_patient_choice.need_to_employ = "Um diese Krankheit heilen zu können, müssen wir zusätzliches Personal einstellen."
fax.disease_discovered_patient_choice.can_not_cure = "Im Moment können wir diese Krankheit nicht behandeln."
fax.disease_discovered_patient_choice.disease_name = "Unser Ärzteteam hat herausgefunden, an was für einer Art von %s der Patient leidet." -- text was missing
fax.disease_discovered_patient_choice.what_to_do_question = "Was sollen wir jetzt mit dem Patienten anstellen?" -- text was missing
fax.disease_discovered_patient_choice.guessed_percentage_name = "Unser Ärzteteam ist sich zu %d Prozent sicher, dass der Patient an einer Form von %s leidet." -- text was missing
fax.disease_discovered.close_text = "Eine neue Krankheit wurde entdeckt."
fax.disease_discovered.can_cure = "Wir können diese Krankheit problemlos behandeln." -- text was missing
fax.disease_discovered.need_to_build_and_employ = "Um diese Krankheit heilen zu können, müssen wir eine %s bauen und zusätzliches Personal einstellen." -- text was missing
fax.disease_discovered.need_to_build = "Um diese Krankheit heilen zu können, müssen wir eine %s bauen." -- text was missing
fax.disease_discovered.need_to_employ = "Um diese Krankheit heilen zu können, müssen wir zusätzliches Personal einstellen."
fax.disease_discovered.discovered_name = "Unser Ärzteteam hat einen Fall von %s entdeckt."

fax.diagnosis_failed.choices.send_home = "Schicken Sie den Patienten nach Hause." -- wrong text for button
fax.diagnosis_failed.choices.take_chance = "Nehmen Sie die wahrscheinliche Möglichkeit zur Heilung wahr." -- wrong text for button
fax.diagnosis_failed.choices.wait = "Der Patient soll eine Weile im Krankenhaus warten, wir stellen bald neue Diagnosearten zur Verfügung."
fax.diagnosis_failed.situation = "Dieser Patient hat all unsere Diagnosegeräte zum qualmen gebracht. Trotzdem wissen wir immer noch nicht genau, was ihm fehlt." -- text was missing
fax.diagnosis_failed.what_to_do_question = "Was sollen wir jetzt mit dem Patienten anstellen?" -- wrong spelling
fax.diagnosis_failed.partial_diagnosis_percentage_name = "Unser Ärzteteam ist sich zu %d Prozent sicher, dass der Patient an einer Form von %s leidet."

fax.epidemic.choices.declare = "Wir melden die Epidemie und zahlen die Geldstrafe!"
fax.epidemic.choices.cover_up = "Wir versuchen die Epidemie einzudämmen bevor sie das Krankenhaus verlässt!"
fax.epidemic.declare_explanation_fine = "Wenn wir die Epidemie melden, zahlen wir eine Strafe von %d und unser Ruf leidet. Dafür werden die Patienten automatisch geimpft." -- extend to mention reputation hit and automatic vaccination
fax.epidemic.cover_up_explanation_1 = "Wenn wir versuchen, die Epidemie zu vertuschen, müssen wir die Infizierten heilen, bevor das Gesundheitsministerium davon Wind bekommt."
fax.epidemic.cover_up_explanation_2 = "Wenn der Gesundheitsinspektor die Vertuschungsaktion bemerkt, wird das Konsequenzen haben."
fax.epidemic.disease_name = "Unser Ärzteteam hat eine hochgradig ansteckende Form von %s entdeckt!"
fax.epidemic_result.close_text = "Hurra!"
fax.epidemic_result.failed.part_1_name = "Ihr Versuch diese %s-Epidemie zu vertuschen ist fehlgeschlagen! Sie konnten nicht verhindern,"
fax.epidemic_result.failed.part_2 = "dass sich die Epidemie in Ihrem ganzen Krankenhaus ausbreitet."
fax.epidemic_result.succeeded.part_1_name = "Dem Gesundheitsinspektor ist zu Ohren gekommen, dass Sie mit einem schweren Fall von %s zu kämpfen haben."
fax.epidemic_result.succeeded.part_2 = "Allerdings hat er dafür keine Beweise finden können."
fax.epidemic_result.compensation_amount = "Die Behörden haben beschlossen, Sie für die entstandene Rufschädigung mit %d zu entschädigen."
fax.epidemic_result.fine_amount = "Die Behörden haben den nationalen Notstand ausgerufen und sie zu einer Geldstrafe von %d verurteilt."
fax.epidemic_result.rep_loss_fine_amount = "Die Zeitungen haben Wind von der Epidemie bekommen und ziehen Ihren Ruf in den Dreck. Darüber hinaus hat man zu einer Geldstrafe von %d verurteilt."
fax.epidemic_result.hospital_evacuated = "Die Behörden haben keine andere Wahl, als Ihr Krankenhaus zu evakuieren."

dynamic_info.patient.actions.dying = "Ins Jenseits befördert!" -- wrong verb case
dynamic_info.patient.actions.epidemic_vaccinated = "Ich bin nicht mehr infiziert."
adviser.research.drug_fully_researched = "Sie haben die Effektivität Ihres %s-Medikaments auf 100% gesteigert." -- grammatical error in original
tooltip.graphs.reputation = "Ruf ein- und ausschalten" -- original mentioned hospital value, while it's actually reputation.
staff_title.researcher = "Forscher" -- one of the most annoying (since prominent) wrong strings in original
bank_manager.insurance_owed = "Zahlungen von Vers." -- original was too long
graphs.deaths = "Todesfälle" -- origin was too long
insurance_companies[7] = "Leben-und-Tod KG" -- %% in original string (maybe this was rendered as &)
object.skeleton = "Skelett" -- second most annoying mistake in german translation
tooltip.staff_list.detail = "Aufmerksamkeit" -- was translated as an imperative
tooltip.staff_list.surgeon_train = "Wurde zu %d%% zum Chirurgen ausgebildet." -- the three strings made no sense grammatically
tooltip.staff_list.psychiatrist_train = "Wurde zu %d%% zum Psychiater ausgebildet."
tooltip.staff_list.researcher_train = "Wurde zu %d%% zum Forscher ausgebildet."
-- tooltip.staff_list.next_person, prev_person is rather next/prev page (also in english)
tooltip.staff_list.next_person = "Zur nächsten Seite blättern"
tooltip.staff_list.prev_person = "Zur vorherigen Seite blättern"

tooltip.queue_window.inc_queue_size = "Warteschlange vergrößern"
tooltip.queue_window.dec_queue_size = "Warteschlange verkleinern"

-- Improve tooltips in staff window to mention hidden features
tooltip.staff_window.face = "Gesicht dieser Person - klicken, um das Personal-Management zu öffnen"
tooltip.staff_window.center_view = "Linksklick, um zur Person zu springen, Rechtsklick um durch das Personal zu blättern"

-- These strings are missing in some versions of TH (unpatched?)
confirmation.restart_level = "Sind Sie sicher, dass Sie das aktuelle Level von vorne beginnen möchten?"



-- reported as missing, although they are only in OVERRIDE section of english.lua
level_progress.hospital_value_enough = "Halten Sie den Wert des Krankenhauses über %d und kümmern Sie sich um ihre anderen Probleme um das Level zu gewinnen."
level_progress.cured_enough_patients = "Sie haben genug Patienten geheilt, aber die Qualität des Krankenhauses muss zunehmen um das Level zu gewinnen."

--
multiplayer.players_failed = "Der/die folgende(n) Spieler hat/haben das letzte Ziel nicht erreicht:"
multiplayer.everyone_failed = "Alle haben das letzte Ziel nicht erreicht. Also können alle weiterspielen!"

--
disease_discovered_patient_choice.need_to_employ = "Stellen Sie eine(n) %s ein um diese Situation lösen zu können."


-- remove invisible hyphens. unfortunately it is impossible to fix the wrong case, since
-- the case determines the font
policy = {
  diag_termination = "diagnoseerstellung",
  diag_procedure = "diagnoseverfahren",
}

-- remove hyphen since it makes it use the wrong font. again, the case cannot be fixed
casebook = {
  deaths = "ablebensfälle", --the ä looks weird as well
}

-- only drug_improved_1 is in OVERRIDE section of english.lua
-- ..._1 is used to prevent 'the the squits' AKA orig [4,30], which is simply "Durchfall"
-- so the sane thing is to duplicate drug_improved
adviser = {
  research = {
    drug_improved = "Die Effektivität Ihres %s-Medikaments wurde von Ihrer Forschungsabteilung verbessert.",
    drug_improved_1 = "Die Effektivität Ihres %s-Medikaments wurde von Ihrer Forschungsabteilung verbessert.",
  },
}

-------------------------------  NEW STRINGS  -------------------------------
date_format = {
  daymonth = "%1%. %2:months%",
}

object.litter = "Müll"
tooltip.objects.litter = "Müll: Wurde von einem Patienten fallen gelassen, nachdem er keinen Mülleimer fand."

object.rathole = "Rattenloch"
tooltip.objects.rathole = "Heimat einer Rattenfamilie, die Ihr Krankenhaus dreckig genug fand um hier zu leben."

tooltip.fax.close = "Das Fenster schließen, ohne die Nachricht zu löschen"
tooltip.message.button = "Linksklick, um die Nachricht zu öffnen"
tooltip.message.button_dismiss = "Linksklick, um die Nachricht zu öffnen, Rechtsklick um sie zu entfernen"
tooltip.casebook.cure_requirement.hire_staff = "Sie müssen Personal einstellen, um diese Behandlung durchführen zu können"
tooltip.casebook.cure_type.unknown = "Sie wissen noch nicht, wie Sie diese Krankheit behandeln können"
tooltip.research_policy.no_research = "In dieser Kategorie wird momentan keine Forschung durchgeführt"
tooltip.research_policy.research_progress = "Fortschritt in dieser Kategorie: %1%/%2%"

menu["player_count"] = "SPIELERZAHL"

menu_file = {
  load =    "  (%1%) LADEN  ",
  save =    "  (%1%) SPEICHERN   ",
  restart = "  (%1%) NEUSTART",
  quit =    "  (%1%) VERLASSEN   "
}

menu_options = {
  sound = "  (%1%) AUDIO   ",
  announcements = "  (%1%) DURCHSAGEN   ",
  music = "  (%1%) MUSIK   ",
  jukebox = "  (%1%) JUKEBOX  ",
  lock_windows     = "  FENSTER FESTHALTEN  ",
  edge_scrolling   = "  AM BILDSCHIRMRAND SCROLLEN  ",
  capture_mouse = "  MAUSZEIGER EINFANGEN  ",
  adviser_disabled = "  (%1%) BERATER  ",
  warmth_colors    = "  FARBEN FÜR WÄRMEDARSTELLUNG  ",
  wage_increase = "  GEHALTSERHÖHUNGEN  ",
  twentyfour_hour_clock = "  24-STUNDEN-UHR  ",
}

menu_options_game_speed = {
  pause               = "  (%1%) PAUSE  ",
  slowest             = "  (%1%) AM LANGSAMSTEN  ",
  slower              = "  (%1%) LANGSAM  ",
  normal              = "  (%1%) NORMAL  ",
  max_speed           = "  (%1%) MAXIMALE GESCHWINDIGKEIT  ",
  and_then_some_more  = "  (%1%) UND NOCH MEHR  ",
}

menu_options_warmth_colors = {
  choice_1 = "  ROTTÖNE  ",
  choice_2 = "  BLAU-GRÜN-ROT  ",
  choice_3 = "  GELB-ORANGE-ROT  ",
}

menu_options_wage_increase = {
  grant = "    GEWÄHREN ",
  deny =  "    ABLEHNEN ",
}

-- Add F-keys to entries in charts menu (except briefing), also town_map was added.
menu_charts = {
  bank_manager  = "  (%1%) BANK-MANAGER  ",
  statement     = "  (%1%) BILANZ  ",
  staff_listing = "  (%1%) PERSONALLISTE  ",
  town_map      = "  (%1%) ÜBERSICHTSKARTE  ",
  casebook      = "  (%1%) BEHANDLUNGSMAPPE  ",
  research      = "  (%1%) FORSCHUNG  ",
  status        = "  (%1%) STATUS  ",
  graphs        = "  (%1%) DIAGRAMME  ",
  policy        = "  (%1%) EINSTELLUNGEN  ",
}



-- The demo does not contain this string
menu_file.restart = "  NEUSTART  "

menu_debug = {
  jump_to_level               = "  SPRINGE ZU LEVEL  ",
  connect_debugger            = "  (%1%) ZUM LUA-DEBUG-SERVER VERBINDEN  ",
  transparent_walls           = "  (%1%) DURCHSICHTIGE WÄNDE  ",
  limit_camera                = "  KAMERA BEGRENZEN  ",
  disable_salary_raise        = "  KEINE GEHALTSERHÖHUNGEN  ",
  allow_blocking_off_areas    = "  ERLAUBE BEREICHE ZU SPERREN  ",
  make_debug_fax              = "  DEBUG-FAX ERSTELLEN  ",
  make_debug_patient          = "  DEBUG-PATIENTEN ERSTELLEN  ",
  cheats                      = "  (%1%) CHEATS  ",
  lua_console                 = "  (%1%) LUA-KONSOLE  ",
  debug_script                = "  (%1%) DEBUG-SKRIPT STARTEN  ",
  calls_dispatcher            = "  AUFRUF-VERTEILER  ",
  dump_strings                = "  (%1%) TEXTE ABSPEICHERN  ",
  dump_gamelog                = "  (STRG+D) SPIELPROTOKOLL ABSPEICHERN  ",
  map_overlay                 = "  KARTEN-OVERLAY  ",
  sprite_viewer               = "  SPRITE-BETRACHTER  ",
}
menu_debug_overlay = {
  none                        = "  KEIN  ",
  flags                       = "  FLAGS  ",
  positions                   = "  POSITION  ",
  heat                        = "  TEMPERATUR  ",
  byte_0_1                    = "  BYTE 0 & 1  ",
  byte_floor                  = "  BYTE BODEN  ",
  byte_n_wall                 = "  BYTE N-WAND  ",
  byte_w_wall                 = "  BYTE W-WAND  ",
  byte_5                      = "  BYTE 5  ",
  byte_6                      = "  BYTE 6  ",
  byte_7                      = "  BYTE 7  ",
  parcel                      = "  GRUNDSTÜCK  ",
}
menu_player_count = {
  players_1 = "  1 Spieler  ",
  players_2 = "  2 Spieler  ",
  players_3 = "  3 Spieler  ",
  players_4 = "  4 Spieler  ",
}
adviser = {
  room_forbidden_non_reachable_parts = "Sie können den Raum hier nicht bauen, da dann Teile des Krankenhauses nicht mehr erreichbar wären.",
  warnings = {
    no_desk ="Sie sollten beizeiten mal eine Rezeption bauen und eine Empfangsdame einstellen!",
    no_desk_1 = "Wenn Sie wollen, dass Patienten in Ihr Krankenhaus kommen, müssen Sie eine Empfangsdame einstellen und eine Rezeption für sie bauen!",
    no_desk_2 = "Na Klasse, das muss ja ein Weltrekord sein: Fast ein Jahr ohne einen einzigen Patienten! Wenn Sie dieses Krankenhaus weiter leiten wollen, müssen Sie eine Empfangsdame einstellen und eine Rezeption bauen!",
    no_desk_3 = "Ich glaub ich spinne, fast ein Jahr ist um und Sie haben keine besetzte Rezeption! Wie denken Sie denn, dass die Patienten zu Ihnen finden? Schauen Sie mal zu, dass Sie Ihren Kram auf die Reihe bekommen!",
    no_desk_4 = "Eine Empfangsdame muss ihren eigenen Arbeitsplatz haben, um die Patienten bei ihrer Ankunft zu begrüßen.",
    no_desk_5 = "Na, das wurde aber auch Zeit! Sie sollten in Kürze ein paar Patienten hier eintreffen sehen!",
    no_desk_6 = "Sie haben eine Empfangsdame, also sollten Sie eine Rezeption für sie bauen.",
    no_desk_7 = "Sie haben die Rezeption gebaut, also wie wäre es damit, eine Empfangsdame einzustellen? Sie werden keine Patienten sehen, bis sie das geregelt haben, wissen Sie?",
    another_desk = "Sie müssen einen weitere Rezeption für die neue Empfangsdame bauen.",
    cannot_afford = "Sie haben nicht genügend Geld auf dem Konto, um diese Person einzustellen!",
    cannot_afford_2 = "Sie haben nicht genügend Geld auf dem Konto, um dies zu kaufen!",
    falling_1 = "He! Vorsicht mit dem Mauszeiger, jemand könnte sich verletzen!",
    falling_2 = "Hören Sie schon auf damit, wie würde das Ihnen denn gefallen?",
    falling_3 = "Autsch, das sah schmerzhaft aus. Ruft einen Arzt!",
    falling_4 = "Dies ist ein Krankenhaus, kein Vergnügungspark!",
    falling_5 = "Sie sind nicht hier um Leute umzustoßen. Sie sind krank, okay?",
    falling_6 = "Dies ist keine Bowlingbahn. Patienten sollten nicht so behandelt werden!",
    research_screen_open_1 = "Sie müssen eine Forschungseinrichtung errichten, um auf das Forschungsmenü zugreifen zu können.",
    research_screen_open_2 = "Forschung ist im aktuellen Level nicht verfügbar.",
    researcher_needs_desk_1 = "Ein Forscher braucht einen Schreibtisch, um daran arbeiten zu können.",
    researcher_needs_desk_2 = "Ihr Forscher ist froh darüber, dass Sie ihm eine Pause gegönnt haben. Falls Sie vorhatten, dass noch mehr Personal forscht, dann müssen Sie jedem Forscher einen eigenen Schreibtisch zur Verfügung stellen.",
    researcher_needs_desk_3 = "Jeder Forscher braucht einen eigenen Schreibtisch, an dem er arbeiten kann.",
    nurse_needs_desk_1 = "Jede Krankenschwester braucht ihren eignen Schreibtisch, an dem sie arbeiten kann.",
    nurse_needs_desk_2 = "Ihre Krankenschwester ist froh darüber, dass Sie ihr eine Pause gegönnt haben. Falls Sie vorhatten, dass mehr als nur eine Krankenschwester in der Station arbeitet, dann müssen Sie jeder Krankenschwester einen eigenen Schreibtisch zur Verfügung stellen.",
    low_prices = "Sie berechnen zu wenig für %s. Dadurch bekommen Sie viele Patienten, verdienen aber wenig an jedem einzelnen von ihnen.",
    high_prices = "Sie berechnen zu viel für %s. Dadurch verdienen Sie kurzfristig viel Geld, aber langfristig vertreiben Sie die damit Patienten aus ihrem Krankenhaus.",
    fair_prices = "Die Behandlungskosten für %s sind fair und angemessen.",
    patient_not_paying = "Ein Patient ist gegangen ohne für %s zu bezahlen weil es zu teuer ist!",
  },

  cheats = {
    th_cheat = "Gratulation, Sie haben die Cheats aktiviert!",
    roujin_on_cheat = "Roujins Herausforderungs-Cheat aktiviert! Viel Glück ...",
    roujin_off_cheat = "Roujins Herausforderung deaktiviert.",
  },
}

dynamic_info.patient.actions.no_gp_available = "Wartet darauf, dass Sie eine Allgemeinmedizin bauen"
dynamic_info.staff.actions.heading_for = "Geht zu: %s"
dynamic_info.staff.actions.fired = "Gefeuert"
dynamic_info.staff.actions.vaccine = "Impft einen Patienten"
dynamic_info.patient.actions.epidemic_vaccinated = "Ich bin nicht mehr ansteckend"
dynamic_info.object.strength_extra_info = "Stärke %d (Regenerierbar zu %d)" -- literal translation would be "erweiterbar"

progress_report.free_build = "FREIES SPIEL"

fax = {
  choices = {
    return_to_main_menu = "Ins Hauptmenü zurückkehren",
    accept_new_level = "Zum nächsten Level wechseln",
    decline_new_level = "Noch ein wenig im aktuellen Level weiterspielen",
  },
  emergency = {
    num_disease_singular = "Hier ist eine Person mit %s, sie braucht sofortige Aufmerksamkeit.",
    free_build = "Wenn wir erfolgreich sind, wird unser Ruf steigen. Falls wir versagen, wird unser Ruf Schaden nehmen.",
  },
  vip_visit_result = {
    remarks = {
      free_build = {
        "Echt ein hübsches Krankenhaus haben Sie da! War aber wohl nicht so schwer zum Laufen zu bekommen, so ohne finanzielle Beschränkungen, was? Haha ...",
        "Ich bin zwar kein BWLer, aber ich denke, dieses Krankenhaus könnte ich auch führen. Sie wissen schon, was ich meine.",
        "Ein gut organisiertes Krankenhaus. Aber hüten Sie sich vor der Finanzkrise! Ach ja ... da müssen Sie sich ja keine Sorgen machen.",
      }
    }
  }
}

letter = {
  dear_player = "Hallo %s\n",
  custom_level_completed = "Gut gemacht! Sie haben alle Ziele dieses eigenen Levels erreicht!",
  return_to_main_menu = "Möchten Sie ins Hauptmenü zurückkehren, oder weiterspielen?",
  campaign_level_completed = "Gute Arbeit! Sie haben das Level geschafft. Aber es ist noch nicht vorbei!\n Möchten Sie eine Position im %s Krankenhaus?",
  campaign_completed = "Unglaublich! Sie haben alle Level abgeschlossen. Nun können Sie sich entspannen und genießen Foren mit Berichten ihrer Heldentaten zu fluten. Viel Glück!",
  campaign_level_missing = "Entschuldigung, aber das nächste Level dieser Kampagne scheint zu fehlen. (Name: %s)",
}

install = {
  title = "----------------------------- CorsixTH-Konfiguration -----------------------------",
  th_directory = "CorsixTH benötigt einige Dateien des Originalspiels Theme Hospital (oder der Demo davon), um zu funktionieren. Bitte das Installationsverzeichnis von Theme Hospital auswählen.",
  ok = "OK",
  exit = "Beenden",
  cancel = "Abbrechen",
}

misc.not_yet_implemented = "(noch nicht implementiert)"
misc.no_heliport = "Entweder wurden noch keine Krankheiten entdeckt, oder es existiert kein Heliport auf dieser Karte."
misc.cant_treat_emergency = "Ihr Krankenhaus kann diesen Notfall nicht behandeln, da die entsprechende Krankheit noch nicht entdeckt wurde. Versuchen Sie es später wieder."

main_menu = {
  new_game = "Kampagne",
  custom_campaign = "Benutzerdef. Kampagne", -- everything sensible is too long
  custom_level = "Einzelnes Level",
  continue = "Spiel fortsetzen",
  load_game = "Spiel laden",
  options = "Optionen",
  map_edit = "Karten-Editor",
  savegame_version = "Spielstandsversion: ",
  version = "Version: ",
  exit = "Verlassen",
}

tooltip.main_menu = {
  new_game = "Das erste Level der Kampagne beginnen",
  custom_campaign = "Eine von Nutzern erstellte Kampagne spielen",
  custom_level = "Ein Krankenhaus in einem einzelnem Level errichten",
  continue = "Den letzten Spielstand fortsetzen",
  load_game = "Ein zuvor gespeichertes Spiel fortsetzen",
  options = "Diverse Einstellungen verändern",
  map_edit = "Eine eigene Karte erstellen",
  exit = "Bitte lassen Sie mich nicht allein!",
  quit = "Sie sind im Begriff, CorsixTH zu verlassen. Sind Sie sich sicher, dass Sie das tun wollen?",
}

load_game_window = {
  caption = "Spiel laden (%1%)",
}

tooltip.load_game_window = {
  load_game = "Spiel %s laden",
  load_game_number = "Spiel %d laden",
  load_autosave = "Automatisch gespeichertes Spiel laden",
}

custom_game_window = {
  caption = "Einzelnes Level",
  free_build = "Freies Spiel",
  load_selected_level = "Los",
}

tooltip.custom_game_window = {
  choose_game = "Ein Level auswählen, um mehr über es zu erfahren",
  free_build = "Auswählen, um mit unbegrenztem Geld und ohne Sieg- bzw. Niederlagebedingungen zu spielen",
  load_selected_level = "Ausgewähltes Level laden und spielen",
}

custom_campaign_window = {
  caption = "Eigene Kampagne",
  start_selected_campaign = "Kampagne starten",
}

tooltip.custom_campaign_window = {
  choose_campaign = "Eine Kampagne auswählen, um mehr über sie zu erfahren",
  start_selected_campaign = "Das erste Level dieser Kampagne laden",
}

save_game_window = {
  caption = "Spiel Speichern",
  new_save_game = "Neuer Spielstand",
}

tooltip.save_game_window = {
  save_game = "Spielstand %s überschreiben",
  new_save_game = "Namen für einen neuen Spielstand eingeben",
}

save_map_window = {
  caption = "Karte speichern (%1%)",
  new_map = "Neue Karte",
}

tooltip.save_map_window = {
  map = "Karte %s überschreiben",
  new_map = "Namen für Karten-Speicherstand eingeben",
}

menu_list_window = {
  name = "Dateiname",
  save_date = "Änderungsdatum",
  back = "Zurück",
}

tooltip.menu_list_window = {
  name = "Hier klicken, um nach Dateinamen zu sortieren",
  save_date = "Hier klicken, um nach dem letzten Änderungsdatum zu sortieren",
  back = "Das Fenster schließen",
}

-- Scroll vs Scrolling: I would tend to use Scroll, but Duden suggests Scrolling
options_window = {
  caption = "Einstellungen",
  option_on = "Ein",
  option_off = "Aus",
  capture_mouse = "Maus einfangen",
  customise = "Spezialeinstellungen",
  folder = "Pfade",
  language = "Spielsprache",
  back = "Zurück",
  hotkey = "Tastenkürzel",
}
graphics_window = {
  fullscreen = "Vollbild",
  width = "Breite",
  height = "Höhe",
  option_on = "Ein",
  option_off = "Aus",
  apply = "Übernehmen",
  cancel = "Abbrechen",
}

tooltip.options_window = {
  capture_mouse = "Ein- bzw. Ausschalten, ob der Mauszeiger das Fenster verlassen kann",
  customise = "Weitere Einstellungen, die Sie ändern können, um Ihr Spielerlebnis anzupassen",
  folder = "Verzeichniseinstellungen",
  language = "Die Sprache, in der Texte im Spiel erscheinen",
  select_language = "Die Spielsprache ändern",
  language_dropdown_item = "%s als Sprache auswählen",
  back = "Das Optionsfenster schließen",
  hotkey = "Tastenkürzel ändern.",
}
tooltip.graphics_window = {
  fullscreen = "Darstellung im Vollbild- oder Fenstermodus",
  fullscreen_button = "Klicken, um zwischen Vollbild- und Fenstermodus zu wechseln",
  width = "Gewünschte Bildschirmbreite eingeben",
  height = "Gewünschte Bildschirmhöhe eingeben",
  apply = "Die eingegebene Auflösung übernehmen",
  cancel = "Zurückkehren, ohne die Auflösung zu ändern",
}

audio_window = {
  audio = "Audio", -- "Globale Audio-Einstellungen" would match eng, but it's too long
  jukebox = "Jukebox",
  back = "Zurück",
}

tooltip.audio_window = {
  audio_button = "Sämtliche Toneffekte des Spiels ein- bzw. ausschalten",
  audio_toggle = "Ein- oder ausschalten",
}

customise_window = {
  caption = "Spezialeinstellungen",
  option_on = "Ein",
  option_off = "Aus",
  back = "Zurück",
  movies = "Alle Filme zeigen",
  play_intro = "Introfilm abspielen",
  allow_user_actions_while_paused = "In Pause bauen",
  volume = "Leiser-Taste",
  alien_dna_only_by_emergency = "Alien-Patienten", -- "Außerirdische Patienten"/"Ex­t­ra­ter­res­t­risch Patienten" is too long
  disable_fractured_bones_females = "Gebrochene Knochen",
  enable_avg_contents = "Einrichtung merken",
  remove_destroyed_rooms = "Behebbare Zerstörung", -- "Entfernbare zerstörte Räume" is too long
}

tooltip.customise_window = {
  movies = "Globale Filmsteuerung: Hiermit können Sie sämtliche Filme abschalten",
  play_intro = "Den Introfilm abschalten. Das Intro wird nur gespielt, wenn Sie nicht auch gleichzeitig alle Filme abgeschaltet haben.",
  allow_user_actions_while_paused = "In Theme Hospital würde es dem Spieler während der Pause nur gestattet sein, das obere Menü zu benutzen. Dies ist in CorsixTH ebenfalls die Standardeinstellung, aber wenn Sie dies einschalten, ist alles in der Pause erlaubt.",
  volume = "Wenn die Leiser-Taste auch das Fallbuch öffnet, dann schalten Sie dies ein, um die Schnellzugriffstaste für das Fallbuch auf Umschalt + C zu wechseln.",
  alien_dna_only_by_emergency = "Aufgrund des Fehlens einer anständigen Animation haben wir standardmäßig Patienten mit außerirdischer DNA deaktiviert, damit sie nur zu einem Notfall kommen. Um Patienten mit außerirdischer DNA es zu erlauben, Ihr Krankenhaus nicht nur bei Notfällen zu besuchen, schalten Sie dies ab.",
  disable_fractured_bones_females = "Aufgrund einer armseligen Animation haben wir uns entschieden, dass es standardmäßig keine weiblichen Patienten mit gebrochenen Knochen gibt. Wenn weibliche Patienten mit gebrochenen Knochen Ihr Krankenhaus besuchen sollen, dann schalten Sie dies ab.",
  enable_avg_contents = "Wenn Sie möchten, dass sich das Spiel merkt, welche zusätzlichen Objekte Sie üblicherweise beim Gebäudebau hinzufügen, dann schalten Sie diese Option ein.",
  remove_destroyed_rooms = "Aktivieren Sie diese Option wenn Sie wollen, dass zerstörte Räume nach Zahlung einer Gebühr entfernt werden können.",
  back = "Dieses Menü schließen und zum Einstellungsmenü zurückkehren",
}

folders_window = {
  caption = "Pfade",
  data_label = "TH-Daten",
  font_label = "Schrift",
  music_label = "Musik",
  savegames_label = "Spielstände",
  screenshots_label = "Screenshots",
  --
  new_th_location = "Hier können Sie ein neues Theme-Hospital-Installationsverzeichnis auswählen. Sobald Sie das neue Verzeichnis auswählen, wird das Spiel neu gestartet.",
  savegames_location = "Wählen Sie das Verzeichnis aus, das für Spielstände benutzt werden soll.",
  music_location = "Wählen Sie hier das Verzeichnis aus, in dem sich Ihre Musik befindet.",
  screenshots_location = "Wählen Sie das Verzeichnis aus, das für Screenshots benutzt werden soll.",
  back = "Zurück",
}

tooltip.folders_window = {
  browse = "Nach einem Verzeichnis durchsuchen",
  data_location = "Das Verzeichnis der original Theme-Hospital-Installation, die benötigt wird, um CorsixTH zu spielen",
  font_location = "Pfad einer Schrift-Datei, die Unicode-Zeichen Ihrer Sprache unterstützt. Wenn diese Einstellung nicht vorgenommen wird, können Sie keine Sprachen auswählen, die mehr Zeichen benötigen, als das Originalspiel unterstützt. Beispiel: Russisch und Chinesisch.",
  savegames_location = "Standardmäßig wird das Spielstandsverzeichnis im selben Verzeichnis wie die Konfigurationsdatei gespeichert und es wird benutzt, um die Spielstände darin abzuspeichern. Sollte das nicht erwünscht sein, können Sie sich ihr eigenes Verzeichnis aussuchen, wählen Sie einfach das Verzeichnis, das Sie verwenden möchten",
  screenshots_location = "Standardmäßig wird das Screenshotverzeichnis im selben Verzeichnis wie die Konfigurationsdatei gespeichert. Sollte das nicht erwünscht sein, können Sie sich ihr eigenes Verzeichnis aussuchen, wählen Sie einfach das Verzeichnis, das Sie verwenden möchten",
  music_location = "Wählen Sie einen Ort für ihre Musikddateien aus. Das Verzeichnis muss bereits vorhanden sein.",
  browse_data = "Nach einem anderem Ort einer Theme-Hospital-Installation durchsuchen (aktueller Ort: %1%)",
  browse_font = "Nach einer anderen Schriftdatei suchen (aktueller Ort: %1%)",
  browse_saves = "Nach einem anderem Ort für Ihr Spielstandsverzeichnis durchsuchen (aktueller Ort: %1%)",
  browse_screenshots = "Nach einem anderem Ort für ihr Screenshotverzeichnis suchen (aktueller Ort: %1%)",
  browse_music = "Nach einem anderem Ort für Ihr Musikverzeichnis durchsuchen (aktueller Ort: %1%)",
  no_font_specified = "Kein Schriftverzeichnis festgelegt!",
  not_specified = "Kein Verzeichnis festgelegt!",
  default = "Standard",
  reset_to_default = "Das Verzeichnis zur Standardeinstellung zurücksetzen (%1%)",
  --
  back = "Dieses Menü schließen und zum Einstellungsmenü zurückkehren",
}

accessibility_window = {
  scrollspeed = "Scrolling", -- "Scrolling-Geschwindigkeit" is too long
  shift_scrollspeed = "Scrolling (Mod.)", --"schnelles Scrollen" or "Umschalt-Scrolling-Geschwindigkeit" are worse
  zoom_speed = "Zoomen", --"Zoom-Geschwindigkeit" is too long
}

tooltip.accessibility_window = {
  scrollspeed = "Scrolling-Geschwindigkeit von 1 (langsamste) bis 10 (schnellste) einstellen. Standard ist 2.",
  shift_scrollspeed = "Scrolling-Geschwindigkeit während der Modifikator (Standard: Umschalttaste) gedrückt wird einstellen. 1 (langsamste) bis 10 (schnellste). Standard ist 4.",
  zoom_speed = "Zoom-Geschwindigkeit der Kamera von 10 (langsamste) bis 1000 (schnellste) einstellen. Standard ist 80.",
  apply_scrollspeed = "Eingegebene Scrolling-Geschwindigkeit anwenden.",
  cancel_scrollspeed = "Ohne Änderung der Scrolling-Geschwindigkeit zurückkehren.",
  apply_shift_scrollspeed = "Eingegebene Modifikator-Scrolling-Geschwindigkeit anwenden.",
  cancel_shift_scrollspeed = "Ohne Änderung der Modifikator-Scrolling-Geschwindigkeit zurückkehren.",
  apply_zoomspeed = "Eingegebene Zoom-Geschwindigkeit anwenden.",
  cancel_zoomspeed = "Ohne Änderung der Zoom-Geschwindigkeit zurückkehren.",
}

hotkey_window = {
  caption_main = "Tastenkürzel-Zuweisungen",
  caption_panels = "Dialog-Tasten",
  button_accept = "Übernehmen",
  button_defaults = "Einstellungen zurücksetzen",
  button_cancel = "Abbrechen",
  button_back = "Zurück",
  button_toggleKeys = "Umschalt-Tasten",
  button_gameSpeedKeys = "Spielgeschwindigkeits-Tasten",
  button_recallPosKeys = "Positions-Tasten",
  panel_globalKeys = "Globale Tasten",
  panel_generalInGameKeys = "Generelle Tasten",
  panel_scrollKeys = "Scrolling-Tasten",
  panel_zoomKeys = "Zoom-Tasten",
  panel_gameSpeedKeys = "Spielgeschwindigkeits-Tasten",
  panel_toggleKeys = "Umschalt-Tasten",
  panel_debugKeys = "Debug-Tasten",
  panel_storePosKeys = "Position merken",
  panel_recallPosKeys = "Position abrufen",
  panel_altPanelKeys = "Alternative Dialog-Tasten",
  global_confirm = "Bestätigen",
  global_confirm_alt = "Bestätigen (alternativ)",
  global_cancel = "Abbrechen",
  global_cancel_alt = "Abbrechen (alternativ)",
  global_fullscreen_toggle = "Vollbild",
  global_exitApp = "App verlassen",
  global_resetApp = "App zurücksetzen",
  global_releaseMouse = "Mauszeiger freigeben",
  global_connectDebugger = "Debugger",
  global_showLuaConsole = "Lua-Konsole",
  global_runDebugScript = "Skript debuggen",
  global_screenshot = "Screenshot",
  global_stop_movie_alt = "Film abbrechen",
  global_window_close_alt = "Fenster schließen",
  ingame_scroll_up = "Nach oben scrollen",
  ingame_scroll_down = "Nach unten scrollen",
  ingame_scroll_left = "Nach links scrollen",
  ingame_scroll_right = "Nach rechts scrollen",
  ingame_scroll_shift = "Geschwindigkeitsmodifikator",
  ingame_zoom_in = "Herein zoomen",
  ingame_zoom_in_more = "Weiter herein zoomen",
  ingame_zoom_out = "Heraus zoomen",
  ingame_zoom_out_more = "Weiter heraus zoomen",
  ingame_reset_zoom = "Zoom zurücksetzen",
  ingame_showmenubar = "Menüleiste zeigen",
  ingame_showCheatWindow = "Cheat-Menü",
  ingame_loadMenu = "Spiel laden",
  ingame_saveMenu = "Spiel speichern",
  ingame_jukebox = "Jukebox",
  ingame_openFirstMessage = "Level-Nachrichten",
  ingame_pause = "Pause",
  ingame_gamespeed_slowest = "Langsamst",
  ingame_gamespeed_slower = "Langsam",
  ingame_gamespeed_normal = "Normal",
  ingame_gamespeed_max = "Maximum",
  ingame_gamespeed_thensome = "Noch mehr",
  ingame_gamespeed_speedup = "Beschleunigen",
  ingame_panel_bankManager = "Bank-Manager",
  ingame_panel_bankStats = "Bank-Status",
  ingame_panel_staffManage = "Personal verwalten",
  ingame_panel_townMap = "Übersichtskarte",
  ingame_panel_casebook = "Behandlungsmappe",
  ingame_panel_research = "Forschung",
  ingame_panel_status = "Status",
  ingame_panel_charts = "Diagramme",
  ingame_panel_policy = "Einstellungen",
  ingame_panel_map_alt = "Übersichtskarte 2",
  ingame_panel_research_alt = "Forschung 2",
  ingame_panel_casebook_alt = "Behandlungsmappe 2",
  ingame_panel_casebook_alt02 = "Behandlungsmappe 3",
  ingame_panel_buildRoom = "Raum bauen",
  ingame_panel_furnishCorridor = "Flur möblieren",
  ingame_panel_editRoom = "Raum bearbeiten",
  ingame_panel_hireStaff = "Personal einstellen",
  ingame_rotateobject = "Gegenstand rotieren",
  ingame_quickSave = "Schnellspeichern",
  ingame_quickLoad = "Schnellladen",
  ingame_restartLevel = "Level zurücksetzen",
  ingame_quitLevel = "Level verlassen",
  ingame_setTransparent = "Transparenz",
  ingame_toggleAnnouncements = "Durchsagen",
  ingame_toggleSounds = "Klänge",
  ingame_toggleMusic = "Musik",
  ingame_toggleAdvisor = "Ratgeber",
  ingame_toggleInfo = "Info",
  ingame_poopLog = "Protokoll-Dump", -- Duden says it's okay
  ingame_poopStrings = "Übersetzungs-Dump",
  ingame_patient_gohome = "Nach Hause schicken",
  ingame_storePosition_1 = "1",
  ingame_storePosition_2 = "2",
  ingame_storePosition_3 = "3",
  ingame_storePosition_4 = "4",
  ingame_storePosition_5 = "5",
  ingame_storePosition_6 = "6",
  ingame_storePosition_7 = "7",
  ingame_storePosition_8 = "8",
  ingame_storePosition_9 = "9",
  ingame_storePosition_0 = "10",
  ingame_recallPosition_1 = "1",
  ingame_recallPosition_2 = "2",
  ingame_recallPosition_3 = "3",
  ingame_recallPosition_4 = "4",
  ingame_recallPosition_5 = "5",
  ingame_recallPosition_6 = "6",
  ingame_recallPosition_7 = "7",
  ingame_recallPosition_8 = "8",
  ingame_recallPosition_9 = "9",
  ingame_recallPosition_0 = "10",
}

tooltip.hotkey_window = {
  button_accept = "Tastenkürzel-Zuweisungen übernehmen und speichern",
  button_defaults = "Alle Tastenkürzel auf Standard zurücksetzen",
  button_cancel = "Zuweisung abbrechen und zum Optionsmenü zurückkehren",
  caption_panels = "Fenster zur Zuweisung von Dialog-Tasten öffnen",
  button_gameSpeedKeys = "Fenster zur Zuweisung von Tasten zur Steuerung der Spielgeschwindigkeit öffnen",
  button_recallPosKeys = "Fenster zur Zuweisung von Tasten zum Merken und Abrufen der Kameraposition öffnen",
  button_back_02 = "Zurück zum generellen Tastenkürzel-Fenster. Geänderte Tastenkürzel aus diesem Fenster können dort akzeptiert werden",
}

font_location_window = {
  caption = "Schrift wählen (%1%)",
}

handyman_window = {
  all_parcels = "Alle Grundstücke",
  parcel = "Grundstück",
}

tooltip.toolbar = {
  machine_menu = "Maschinenmenü (%s)",
  reputation = "Ihr Ruf",
  edit = "Bearbeiten Sie Räume/Gegenstände (%s)",
  bank_button = "Linksklick (%s) für den Bank-Manager, Rechtsklick (%s) für den Kontoauszug",
  objects = "Plazieren Sie Flurausstattung (%s)",
  date = "Das Datum",
  staff_list = "Personal-Management (%s)",
  hire = "Stellen Sie Personal ein (%s)",
  town_map = "Übersichtskarte (%s)",
  charts = "Grafik (%s)",
  research = "Forschung (%s)",
  policy = "Einstellungen (%s)",
  casebook = "Behandlungsmappe (%s)",
  status = "Status (%s)",
  rooms = "Bauen Sie Räume (%s)",
  balance = "Ihr Kontostand",
}

tooltip.handyman_window = {
  parcel_select = "Der Arbeitsbereich des Handlangers. Klicken zum Ändern.",
}

new_game_window = {
  caption = "Neues Spiel",
  player_name = "Spielername",
  option_on = "Ein",
  option_off = "Aus",
  difficulty = "Schwierigkeit",
  easy = "AIP (Einfach)",
  medium = "Arzt (Mittel)",
  hard = "Berater (Schwer)",
  tutorial = "Tutorial", -- Duden says it's okay
  start = "Start",
  cancel = "Abbrechen",
}

tooltip.new_game_window = {
  player_name = "Geben Sie den Namen ein, mit dem Sie im Spiel genannt werden möchten",
  difficulty = "Hier kann der Schwierigkeitsgrad des Spiels eingestellt werden",
  easy = "Die richtige Option für Simulations-Neulinge",
  medium = "Der Mittelweg - für diejenigen, die sich nicht entscheiden können",
  hard = "Wer diese Art von Spielen schon gewöhnt ist und eine Herausforderung will, sollte hier klicken",
  tutorial = "Dieses Feld abhaken, um zu Beginn des Spieles eine Einführung zu erhalten",
  start = "Das Spiel mit den gewählten Einstellungen starten",
  cancel = "Oh, eigentlich wollte ich gar kein neues Spiel starten!",
}

lua_console = {
  execute_code = "Ausführen",
  close = "Schließen",
}

tooltip.lua_console = {
  textbox = "Hier Lua-Code zum Ausführen eingeben",
  execute_code = "Den eingegebenen Code ausführen",
  close = "Die Konsole schließen",
}

errors = {
  dialog_missing_graphics = "Entschuldigung, aber dieses Fenster ist in den Demo-Dateien nicht enthalten.",
  save_prefix = "Fehler beim Speichern: ",
  load_prefix = "Fehler beim Laden: ",
  no_games_to_contine = "Es gibt keine Spielstände.",
  load_quick_save = "Fehler: Der Schnellspeicherspielstand konnte nicht geladen werden, weil er nicht existiert. Kein Grund zur Sorge, wir haben nun einen für Sie erzeugt!",
  map_file_missing = "Die Kartendatei %s für das Level konnte nicht gefunden werden!",
  minimum_screen_size = "Bitte eine Auflösung von mindestens %d×%d eingeben.",
  unavailable_screen_size = "Die gewünschte Auflösung ist im Vollbildmodus nicht verfügbar.",
  alien_dna_only_by_emergency = "BEACHTEN SIE: Für außerirdische Patienten gibt es keine Animationen für das Sitzen, das Öffnen von Türen, das Anklopfen, usw. Daher werden sie, wie bei Theme Hospital, normal aussehen und sich dann wieder zurückverwandeln. Patienten mit außerirdischer DNA werden nur auftauchen, wenn sie in der Leveldatei gesetzt sind.",
  disable_fractured_bones_females = "BEACHTEN SIE: Die Animation für weibliche Patienten mit gebrochenen Knochen ist nicht perfekt.",
  could_not_load_campaign = "Konnte die Kampagne nicht laden: %s",
  could_not_find_first_campaign_level = "Konnte das erste Level dieser Kampagne nicht finden: %s",
  save_to_tmp = "Die Datei %s konnte nicht verwendet werden. Das Spiel wurde als %s gespeichert. Fehler: %s",
  dialog_empty_queue = "Entschuldigung, eine Person hat keine weiteren Aktionen geplant und weiß nicht weiter. Weitere Details hierzu können der Konsole entnommen werden. Soll die Person das Krankenhaus verlassen?",
  compatibility_error = {
    new_in_old = "Entschuldigung, dieser Spielstand wurde mit einer neueren Version von CorsixTH erstellt und ist inkompatibel. Bitte wechseln Sie zu einer aktuelleren Version.",
    demo_in_full = "Entschuldigung, ein Spielstand der Demo kann nicht mit den Spieldaten der Vollversion geladen werden. Bitte passen Sie ihre TH-Daten-Einstellung an.",
    full_in_demo = "Entschuldigung, ein Spielstand der Vollversion kann nicht mit den Spieldaten der Demo geladen werden. Bitte passen Sie ihre TH-Daten-Einstellung an.",
  },
}

warnings = {
  levelfile_variable_is_deprecated = "Hinweise: Das Level '%s' enthält eine veraltete Variablendefinition." ..
                                     "'%LevelFile' wurde in '%MapFile' umbenannt. Bitte informieren Sie den Autor, dass er das Level aktualisieren sollte.",
  newersave = "Warnung: Sie haben einen Spielstand von einer neueren Version von CorsixTH geladen. Es ist nicht empfehlenswert fortzufahren, da es zu Abstürzen kommen kann. Weiterspielen auf eigenes Risiko."
}

confirmation = {
  needs_restart = "Um diese Änderung, vorzunehmen muss CorsixTH neu gestartet werden. Nicht gespeicherter Fortschritt geht verloren. Sicher, dass Sie fortfahren wollen?",
  abort_edit_room = "Sie bauen oder ändern gerade einen Raum. Wenn alle benötigten Objekte platziert sind, wird der Raum fertiggestellt, ansonsten wird er gelöscht. Fortfahren?",
  maximum_screen_size = "Die von Ihnen gewählte Bildschirmauflösung ist größer als 3000×2000. Größere Auflösungen sind möglich, aber erfordern eine bessere Hardware, um eine akzeptable Bildwiederholrate zu gewährleisten. Sind Sie sich sicher, dass Sie fortfahren möchten?",
  remove_destroyed_room = "Möchten Sie den Raum für $%d entfernen?",
  replace_machine_extra_info = "Die neue Maschine wird eine Stärke von %d haben (aktuell %d).",
}

information = {
  custom_game = "Willkommen zu CorsixTH. Viel Spaß mit diesem eigenen Level!",
  no_custom_game_in_demo = "Tut uns Leid, aber in der Demo-Version sind keine eigenen Level spielbar.",
  cannot_restart = "Leider wurde dieses eigene Level vor Implementierung des Neustart-Features gespeichert.",
  very_old_save = "Seit dieses Level gestartet wurde, wurden einige Änderungen am Spiel durchgeführt. Sie sollten ein neues Spiel starten, damit alle Änderungen wirksam werden.",
  level_lost = {
    "So ein Mist! Sie haben das Level leider nicht geschafft. Vielleicht klappt's ja beim nächsten Mal!",
    "Der Grund, warum Sie verloren haben:",
    reputation = "Ihr Ruf ist unter %d gesunken.",
    balance = "Ihr Kontostand ist unter %d gesunken.",
    percentage_killed = "Sie haben mehr als %d Prozent der Patienten getötet.",
    cheat = "Sie haben das selbst so gewollt. Oder haben Sie etwa auf den falschen Knopf gedrückt? Sie können also nicht mal richtig schummeln. Traurig.",
  },
  cheat_not_possible = "Dieser Cheat ist in diesem Level nicht verfügbar. Sogar beim Schummeln versagen Sie, wie armselig!",
}

tooltip.information = {
  close = "Das Informationsfenster schließen",
}

totd_window = {
  tips = {
    "Zu Beginn benötigt jedes Krankenhaus eine Rezeption und eine Allgemeinmedizin. Danach kommt es darauf an, was für Patienten im Krankenhaus auftauchen. Eine Pharma-Theke ist aber immer eine gute Wahl.",
    "Maschinen wie die Entlüftung müssen gewartet werden. Stellen Sie ein paar Handlanger ein, oder die Patienten und das Personal könnte verletzt werden.",
    "Nach einer Weile wird das Personal müde. Bauen Sie unbedingt einen Personalraum, damit es sich ausruhen kann.",
    "Platzieren Sie genug Heizkörper, um das Personal und die Patienten warm zu halten, sonst werden sie unglücklich. Benutzen Sie die Übersichtskarte, um Stellen im Krankenhaus zu finden, die noch etwas besser beheizt werden müssen.",
    "Der Fähigkeiten-Level eines Arztes beeinflusst die Qualität und Geschwindigkeit seiner Diagnosen deutlich. Ein geübter Arzt in der Allgemeinmedizin erspart so manchen zusätzlichen Diagnoseraum.",
    "AIPler und Ärzte können ihre Fähigkeiten verbessern, indem sie in der Ausbildung von Beratern lernen. Wenn der Berater eine zusätzliche Qualifikation (Chirurg, Psychiater oder Forscher) besitzt, gibt er dieses Wissen ebenfalls weiter.",
    "Haben Sie schon versucht, die europäische Notruf-Nummer (112) in das Faxgerät einzugeben? Schalten Sie vorher den Sound an!",
    "Im Optionsmenü hier im Hauptmenü oder im laufenden Spiel können Einstellungen wie die Auflösung oder die Sprache geändert werden.",
    "Haben Sie eine andere Sprache als Englisch ausgewählt, aber es erscheinen englische Texte? Helfen Sie uns, die Übersetzung zu vervollständigen, indem Sie fehlende Texte in Ihre Sprache übersetzten!",
    "Das CorsixTH-Team sucht Verstärkung! Haben Sie Interesse, beim Programmieren, Übersetzen oder der Grafikerstellung zu helfen? Kontaktieren Sie uns in unserem Forum, der Mailing-Liste oder unserem IRC-Kanal (#Corsix-TH auf Freenode).",
    "Wenn Sie einen Bug finden, bitte melden Sie ihn in unserem Bug-Tracker: th-issues.corsix.org",
    "In jedem Level müssen bestimmte Voraussetzungen erfüllt werden, bevor man zum Nächsten wechseln kann. Im Status-Fenster können Sie Ihren Fortschritt bezüglich der Levelziele sehen.",
    "Um existierende Räume zu bearbeiten oder gar zu löschen, kann man den Raum-Bearbeiten-Knopf in der unteren Werkzeugleiste verwenden.",
    "Um aus einer Horde wartender Patienten diejenigen zu finden, die für einen bestimmten Raum warten, einfach mit dem Mauszeiger über den entsprechenden Raum fahren.",
    "Klicken Sie auf die Tür eines Raumes, um seine Warteschlange zu sehen. Hier kann man nützliche Feineinstellungen vornehmen, wie etwa die Warteschlange umsortieren oder einen Patienten zu einem anderen Raum senden.",
    "Unglückliches Personal verlangt öfter Gehaltserhöhungen. Gestalten Sie die Arbeitsumgebung Ihres Personals möglichst angenehm, um dies zu verhindern.",
    "Patienten werden beim Warten durstig, besonders wenn die Heizungen aufgedreht sind! Strategisch platzierte Getränkeautomaten sind eine nette zusätzliche Einnahmequelle.",
    "Sie können die Diagnose für einen Patienten vorzeitig abbrechen und ihn direkt zur Behandlung schicken, falls seine Krankheit zuvor schon entdeckt wurde. Allerdings erhöht sich dadurch das Risiko, dass das Heilmittel falsch ist und der Patient stirbt.",
    "Notfälle können eine gute Einnahmequelle abgeben, sofern genügend Kapazitäten vorhanden sind, um die Notfallpatienten rechtzeitig zu behandeln.",
    "Wussten Sie, dass sie Handlangern spezifische Grundstücke zuweisen können? Klicken Sie einfach auf den Text 'Alle Grundstücke' im Personalprofil um zwischen ihnen zu wechseln!",
  },
  previous = "Vorheriger Tipp",
  next = "Nächster Tipp",
}

tooltip.totd_window = {
  previous = "Den vorherigen Tipp anzeigen",
  next = "Den nächsten Tipp anzeigen",
}

debug_patient_window = {
  caption = "Debug-Patient",
}

cheats_window = {
  caption = "Cheats",
  warning = "Warnung: Cheater bekommen am Ende des Levels keine Bonus-Punkte!",
  cheated = {
    no = "Cheats benutzt: Nein",
    yes = "Cheats benutzt: Ja",
  },
  cheats = {
    money = "Geld-Cheat",
    all_research = "Alle-Forschungen-Cheat",
    emergency = "Notfall erzeugen",
    vip = "VIP erzeugen",
    earthquake = "Erdbeben starten",
    epidemic = "Infizierten Patienten erzeugen",
    toggle_infected = "Infektions-Symbole umschalten",
    create_patient = "Patienten erzeugen",
    end_month = "Ende des Monats",
    end_year = "Ende des Jahres",
    lose_level = "Level verlieren",
    win_level = "Level gewinnen",
    increase_prices = "Preise erhöhen",
    decrease_prices = "Preise senken",
  },
  close = "Schließen",
}

tooltip.cheats_window = {
  close = "Das Cheat-Fenster schließen",
  cheats = {
    money = "10.000 zum Konto hinzufügen.",
    all_research = "Alle Forschungen abschließen.",
    emergency = "Einen Notfall erzeugen.",
    vip = "Einen VIP vorbeischicken.",
    earthquake = "Ein Erdbeben starten.",
    epidemic = "Einen infizierten Patienten, der eine Epidemie auslösen kann, erzeugen.",
    toggle_infected = "Die Infektions-Symbole für die aktive, entdeckte Epidemie umschalten.",
    create_patient = "Einen Patienten am Kartenrand erzeugen.",
    end_month = "Zum Monatsende springen.",
    end_year = "Zum Jahresende springen.",
    lose_level = "Das aktuelle Level verlieren.",
    win_level = "Das aktuelle Level gewinnen.",
    increase_prices = "Alle Preise um 50% erhöhen (Max. 200%)",
    decrease_prices = "Alle Preise um 50% senken (Min. 50%)",
  }
}

introduction_texts = {
  demo =
    "Willkommen im Demo-Krankenhaus!//" ..
    "Leider beinhaltet die Demo-Version nur dieses eine Level. Dafür gibt es hier aber mehr als genug zu tun, um Sie eine Weile zu beschäftigen! " ..
    "Sie werden diversen Krankheiten begegnen, die unterschiedliche Räume zur Behandlung benötigen. Ab und zu können auch Notfälle eintreffen. " ..
    "Und Sie werden mithilfe einer Forschungsabteilung neue Räume erforschen müssen. " ..
    "Ihr Ziel ist es, 100.000 DM zu verdienen, einen Krankenhauswert von 70.000 DM und einen Ruf von 700 vorzuweisen, und gleichzeitig mindestens 75% der Patienten erfolgreich zu behandeln. " ..
    "Stellen Sie sicher, dass Ihr Ruf nicht unter 300 fällt und dass Sie nicht mehr als 40% ihrer Patienten sterben lassen, oder Sie werden verlieren.//" ..
    "Viel Glück!",
}

calls_dispatcher = {
  --
  summary = "%d Aufrufe; %d zugewiesen",
  staff = "%s - %s",
  watering = "Bewässert @ %d,%d",
  repair = "Repariert %s",
  close = "Schließen",
}

tooltip.calls_dispatcher = {
  task = "Liste der Aufgaben - Aufgabe anklicken, um das Fenster des zugewiesenen Personalmitglieds zu öffnen und zum Ort der Aufgabe zu scrollen.",
  assigned = "Diese Box ist markiert, wenn jemand der Aufgabe zugewiesen ist.",
  close = "Das Aufruf-Verteiler-Fenster schließen",
}

update_window = {
  caption = "Update verfügbar!",
  new_version = "Neue Version:",
  current_version = "Aktuelle Version:",
  download = "Zur Downloadseite gehen",
  ignore = "Überspringen und zum Hauptmenü gehen",
}

tooltip.update_window = {
  download = "Zur Downloadseite für die allerneueste Version von CorsixTH gehen",
  ignore = "Dieses Update im Moment ignorieren. Sie werden erneut benachrichtigt, wenn Sie CorsixTH das nächste Mal starten.",
}

map_editor_window = {
  pages = {
    inside = "Innen",
    outside = "Außen",
    foliage = "Grünzeug",
    hedgerow = "Hecke",
    pond = "Teich",
    road = "Straße",
    north_wall = "Nord-Wand",
    west_wall = "West-Wand",
    helipad = "Helipad",
    delete_wall = "Wände löschen",
    parcel_0 = "Grundstück 0",
    parcel_1 = "Grundstück 1",
    parcel_2 = "Grundstück 2",
    parcel_3 = "Grundstück 3",
    parcel_4 = "Grundstück 4",
    parcel_5 = "Grundstück 5",
    parcel_6 = "Grundstück 6",
    parcel_7 = "Grundstück 7",
    parcel_8 = "Grundstück 8",
    parcel_9 = "Grundstück 9",
    camera_1 = "Kamera 1",
    camera_2 = "Kamera 2",
    camera_3 = "Kamera 3",
    camera_4 = "Kamera 4",
    heliport_1 = "Heliport 1",
    heliport_2 = "Heliport 2",
    heliport_3 = "Heliport 3",
    heliport_4 = "Heliport 4",
    paste = "Bereich einfügen",
  }
}

hotkeys_file_err = {
  file_err_01 = "Konnte hotkeys.txt nicht laden. Bitte stellen Sie sicher, " ..
        "dass CorsixTH Lese-/Schreibrechte hat ",
  file_err_02 = ", oder verwenden Sie die --hotkeys-file=filename Kommandozeilenoption um eine schreibbare Datei anzugeben. " ..
        "Für Referenzzwecke, der Fehler beim laden der Tastenlürzel-Datei war: ",
}

transactions.remove_room = "Bauen: Entferne zerstörten Raum"

-------------------------------  FIX FOR MISSING CREDITS LINES  ----------------------------------

original_credits[301] = " "
original_credits[302] = " "
original_credits[303] = " "
original_credits[304] = " "
original_credits[305] = " "
original_credits[306] = " "
original_credits[307] = " "
original_credits[308] = " "
original_credits[309] = " "
original_credits[310] = " "
original_credits[311] = " "
original_credits[312] = " "
original_credits[313] = " "
original_credits[314] = " "
original_credits[315] = " "
original_credits[316] = " "
original_credits[317] = " "
original_credits[318] = " "
original_credits[319] = " "
original_credits[320] = " "
original_credits[321] = " "
original_credits[322] = " "
original_credits[323] = " "
original_credits[324] = " "
original_credits[325] = " "
original_credits[326] = " "
original_credits[327] = " "
original_credits[328] = " "
original_credits[329] = " "
original_credits[330] = " "
original_credits[331] = " "
original_credits[332] = " "
original_credits[333] = " "
original_credits[334] = " "
original_credits[335] = " "
original_credits[336] = " "
original_credits[337] = " "
original_credits[338] = " "
original_credits[339] = " "
original_credits[340] = " "
original_credits[341] = " "
original_credits[342] = " "
original_credits[343] = " "
original_credits[344] = " "
original_credits[345] = " "
original_credits[346] = " "
original_credits[347] = " "
original_credits[348] = " "
original_credits[349] = " "
original_credits[350] = " "
original_credits[351] = " "
original_credits[352] = " "
original_credits[353] = " "
original_credits[354] = " "
original_credits[355] = " "
original_credits[356] = " "
original_credits[357] = " "
original_credits[358] = " "
original_credits[359] = " "
original_credits[360] = " "
original_credits[361] = " "

--------------------------------  UNUSED  -----------------------------------
------------------- (kept for backwards compatibility) ----------------------

-------------------------------------------------------------------------------
--   Multiplayer (network play): the room, game options, auctions, bots and the rest
--   of the multiplayer windows. Translated from english.lua; the keys
--   missing here show in English.
-------------------------------------------------------------------------------
hotkey_window.ingame_mp_chat = "Mehrspieler-Chat"
hotkey_window.ingame_mp_next_hospital = "Nächstes Krankenhaus (MP)"
main_menu.multiplayer = "Mehrspieler"
map_editor_window.pages.camera_n = "Kamera %d"
map_editor_window.pages.heliport_n = "Heliport %d"
map_editor_window.pages.player = "Spieler %d"
menu.map_size = "KARTENGRÖSSE"
menu_map_size.size = "  NEUE KARTE %d x %d  "
menu_player_count.players_5 = "  5 Spieler  "
menu_player_count.players_6 = "  6 Spieler  "
menu_player_count.players_7 = "  7 Spieler  "
menu_player_count.players_8 = "  8 Spieler  "
multiplayer_window.add_bot = "wartet auf einen Spieler... (Klick: Bot hinzufügen)"
multiplayer_window.ask_amount = "Betrag: $%d"
multiplayer_window.ask_asked = "Angefragt. Warte auf die Antwort."
multiplayer_window.ask_balance_line = "Kontostand: $%d."
multiplayer_window.ask_button = "Fragen"
multiplayer_window.ask_caption = "%s um Geld bitten"
multiplayer_window.ask_decline = "Ablehnen"
multiplayer_window.ask_declined_note = "%s hat abgelehnt, Ihnen $%d zu schicken."
multiplayer_window.ask_line = "%s bittet Sie um $%d."
multiplayer_window.ask_money = "Spieler fragen"
multiplayer_window.ask_no_money_asker_note = "%s konnte nicht zahlen."
multiplayer_window.ask_no_money_note = "Sie können $%d nicht bezahlen."
multiplayer_window.ask_pay = "$%d zahlen"
multiplayer_window.ask_sent_note = "Sie haben $%d von %s erbeten. Warte auf die Antwort."
multiplayer_window.auction_back = "Zurück zur Auktion"
multiplayer_window.auction_bid = "Biete $%d"
multiplayer_window.auction_borrow_tooltip = "$5,000 von der Bank leihen"
multiplayer_window.auction_close = "Schließen"
multiplayer_window.auction_dropped = "Sie sind ausgestiegen."
multiplayer_window.auction_going_once = "Zum Ersten..."
multiplayer_window.auction_going_twice = "Zum Zweiten..."
multiplayer_window.auction_leader = "Höchstgebot: $%d, %s"
multiplayer_window.auction_leading = "Sie führen. Warten Sie auf die anderen."
multiplayer_window.auction_loan = "$%d, Darlehen $%d"
multiplayer_window.auction_loan_tooltip = "Ihr Kontostand und Ihr Bankdarlehen"
multiplayer_window.auction_no_money = "Sie können sich das nächste Gebot nicht leisten."
multiplayer_window.auction_no_money_loan = "Sie können sich das nächste Gebot nicht leisten: leihen Sie mit + unten."
multiplayer_window.auction_not_sold = "Grundstück %d wurde nicht verkauft."
multiplayer_window.auction_out = "raus"
multiplayer_window.auction_pass = "Aussteigen"
multiplayer_window.auction_paused = "Das Spiel steht während der Auktion still."
multiplayer_window.auction_price = "Preis $%d, jedes Gebot $%d mehr"
multiplayer_window.auction_repay_tooltip = "$5,000 des Darlehens zurückzahlen"
multiplayer_window.auction_sold = "Grundstück %d an %s für $%d verkauft."
multiplayer_window.auction_started = "%s will Grundstück %d. Andere Spieler wollen es vielleicht auch: es kommt unter den Hammer."
multiplayer_window.auction_title = "Landauktion: Grundstück %d"
multiplayer_window.auction_wants = "%s will das markierte Grundstück kaufen."
multiplayer_window.auction_bid_more = "Jedes Gebot ist $%d mehr."
multiplayer_window.auction_winning = "Höchstbietender"
multiplayer_window.auction_wait = "Auktion läuft, bitte warten..."
multiplayer_window.auction_watching = "Ihr Land grenzt nicht an dieses Grundstück."
multiplayer_window.auctions_all = "Alle Grundstücke"
multiplayer_window.auctions_caption = "Landauktionen"
multiplayer_window.auctions_near = "Umkämpfte"
multiplayer_window.auctions_none = "Aus"
multiplayer_window.back = "Zurück"
multiplayer_window.back_to_lobby = "Zurück zur Lobby"
multiplayer_window.bot_named = "%s (%s)"
multiplayer_window.bot_remove = "  Klick: weg"
multiplayer_window.bot_kind_easy = "leichter Bot"
multiplayer_window.bot_kind_normal = "normaler Bot"
multiplayer_window.bot_kind_hard = "schwerer Bot"
multiplayer_window.bot_menu_easy = "Leicht"
multiplayer_window.bot_menu_normal = "Normal"
multiplayer_window.bot_menu_hard = "Schwer"
multiplayer_window.bot_starting = "ein Bot startet..."
multiplayer_window.caption = "Mehrspieler"
multiplayer_window.cert_changed_help = "Das Zertifikat von %s ist nicht das, das sich dieses Spiel vom letzten Mal gemerkt hat. Entweder wurde der Server neu eingerichtet, oder jemand sitzt zwischen Ihnen und dem Server. Das Spiel hat sich nicht verbunden. Wenn Sie wissen, dass der Server ein neues Zertifikat hat, löschen Sie dessen Zeile in %s und verbinden Sie sich erneut."
multiplayer_window.chat_private_in = "%s (an Sie): %s"
multiplayer_window.chat_private_out = "An %s: %s"
multiplayer_window.chat_team_in = "%s (ans Team): %s"
multiplayer_window.chat_team_out = "Ans Team: %s"
multiplayer_window.chat_to = "An %s:"
multiplayer_window.chat_to_all = "An alle:"
multiplayer_window.chat_to_team = "Ans Team:"
multiplayer_window.chat_to_allies = "An Verbündete:"
multiplayer_window.chat_allies_in = "%s (an Verbündete): %s"
multiplayer_window.chat_allies_out = "An Verbündete: %s"
multiplayer_window.clear_destroyed_room = "Den zerstörten Raum für $%d wegräumen? Der Platz ist dann frei für etwas anderes."
multiplayer_window.colour_names[1] = "Gelb"
multiplayer_window.colour_names[2] = "Rot"
multiplayer_window.colour_names[3] = "Lila"
multiplayer_window.colour_names[4] = "Weiß"
multiplayer_window.colour_names[5] = "Grün"
multiplayer_window.colour_names[6] = "Blau"
multiplayer_window.colour_names[7] = "Türkis"
multiplayer_window.colour_names[8] = "Schwarz"
multiplayer_window.connect = "Verbinden"
multiplayer_window.connecting = "Verbinde mit %s..."
multiplayer_window.continue_save = "Fortsetzen: %s"
multiplayer_window.continuing = "Spielstand %s"
multiplayer_window.create = "Erstellen"
multiplayer_window.data_mismatch_help = "Die Theme-Hospital-Dateien dieses Servers stammen aus einer anderen Edition des Spiels als Ihre (die Level und Mehrspielerkarten unterscheiden sich), und Spiele mit beiden würden nicht synchron bleiben. Stellen Sie CorsixTH auf dieselbe Edition wie die des Servers ein (Optionen, Ordner-Optionen, Theme-Hospital-Ordner), zum Beispiel die GOG-Version, und verbinden Sie sich erneut."
multiplayer_window.disconnect = "Trennen"
multiplayer_window.download = "%s von GitHub herunterladen"
multiplayer_window.emergency_refused = "Die Ablehnung des Notfalls hat das Krankenhaus %d Ruf gekostet."
multiplayer_window.encrypted = "Verschlüsselte Verbindung (TLS)"
multiplayer_window.every_plot_auctioned = "alle Grundstücke versteigert"
multiplayer_window.game_options = "Spieloptionen"
multiplayer_window.goal_limit = "Limit:"
multiplayer_window.goal_other.balance = "%s: Kontostand $%d (%s $%d)"
multiplayer_window.goal_other.num_cured = "%s: %d Patienten geheilt (%s %d)"
multiplayer_window.goal_other.percentage_cured = "%s: %d%% der Patienten geheilt (%s %d%%)"
multiplayer_window.goal_other.percentage_killed = "%s: %d%% der Patienten gestorben (%s %d%%)"
multiplayer_window.goal_other.reputation = "%s: Ruf %d (%s %d)"
multiplayer_window.goal_other.value = "%s: Krankenhauswert $%d (%s $%d)"
multiplayer_window.goal_target = "Ziel:"
multiplayer_window.goals_done = "erreicht"
multiplayer_window.goals_failed_other = "%s hat die Ziele dieses Levels verfehlt. Helfen Sie, bis Ende nächsten Jahres wieder auf die Beine zu kommen (Geld oder Personal), sonst verliert das ganze Team."
multiplayer_window.goals_failed_team = "Ihr Krankenhaus hat die Ziele dieses Levels verfehlt. Erholen Sie sich bis Ende nächsten Jahres, sonst verliert das ganze Team. Die anderen Spieler können Ihnen Geld oder Personal schicken."
multiplayer_window.goals_failing = "verfehlt"
multiplayer_window.goals_open = "-"
multiplayer_window.goals_reached_loan = "Ihr Krankenhaus erfüllt alle Ziele dieses Levels, schuldet der Bank aber noch $%d. Zahlen Sie das Darlehen zurück (klicken Sie unten auf Ihr Geld), dann gelten sie als erreicht."
multiplayer_window.goals_reached_other = "%s hat die Ziele dieses Levels erreicht. Es fehlt noch: %s."
multiplayer_window.goals_reached_team = "Ihr Krankenhaus hat die Ziele dieses Levels erreicht! Es fehlt noch: %s."
multiplayer_window.goals_recovered = "%s verfehlt die Ziele dieses Levels nicht mehr."
multiplayer_window.helpers_off = "Verbündete Bots bauen: aus"
multiplayer_window.helpers_on = "Verbündete Bots bauen: an"
multiplayer_window.hold_left = "Das Spiel geht spätestens in %s weiter."
multiplayer_window.hold_win = "Warten, bis %s das Fax beantwortet..."
multiplayer_window.hold_year = "Warten, bis %s den Jahresbericht schließt..."
multiplayer_window.is_ready = "bereit"
multiplayer_window.join = "Beitreten"
multiplayer_window.keep_playing = "Weiterspielen"
multiplayer_window.kick_player = "%s aus dem Raum entfernen"
multiplayer_window.kicked = "%s, der Host des Raums, hat Sie aus dem Raum entfernt."
multiplayer_window.leave = "Raum verlassen"
multiplayer_window.level = "Level %d"
multiplayer_window.level7_breakthrough = "Medizinischer Durchbruch: %s hat zuerst Folgendes entdeckt: %s. Belohnung: $%d."
multiplayer_window.level7_breakthrough_bonus = "Durchbruch-Bonus"
multiplayer_window.level7_job_fair = "Die Jobmesse ist eröffnet: Diesen Monat stehen Spezialisten auf der Bewerberliste."
multiplayer_window.level7_job_fair_soon = "Nächsten Monat öffnet eine Jobmesse: Chirurgen, Psychiater, Forscher und Berater stehen dann auf der Bewerberliste. Wer zuerst kommt, mahlt zuerst."
multiplayer_window.level7_quarter = "Rangliste des Gesundheitsministeriums: %s hat dieses Quartal die meisten Patienten geheilt (%d) und gewinnt Ruf."
multiplayer_window.level7_race_bonus = "Renn-Notfall-Bonus"
multiplayer_window.level7_race_emergency = "Ein Renn-Notfall: Jedes Krankenhaus bekommt jetzt denselben Notfall. Wer zuerst alle Patienten rettet, erhält $%d und Ruf."
multiplayer_window.level7_race_won = "%s hat als Erster alle Patienten des Renn-Notfalls gerettet und erhält $%d."
multiplayer_window.level7_rat_bounty = "Rattenprämie"
multiplayer_window.level7_trick_of_month = "Trick des Monats: %s kostet bis Monatsende nur die Hälfte."
multiplayer_window.level7_truce_over = "Der Waffenstillstand ist vorbei: Fiese Tricks können ab jetzt gekauft werden (MEHRSPIELER > FIESE TRICKS)."
multiplayer_window.level_intro_6 = "Emergency! Die Krankenhäuser dieser Stadt übernehmen jeden Notfall, den der Hubschrauber heranfliegen kann. Im ersten Jahr kommt er viermal im Monat, nacheinander zu jedem Ihrer Krankenhäuser: Aufblas- und Psychiatriefälle ab Februar (und ein paar für die Apotheke), Operationsfälle ab Mai, Schlaffe Zungen und Knochenbrüche ab Juni. Im Mai bekommt jedes Krankenhaus Patienten mit Schlaffer Zunge, erforschen Sie die Zungenklinik also früh. Einen Notfall abzulehnen kostet Ruf, aber Patienten an Notfällen zu verlieren wird mehr als sonst verziehen, und Sie können Notfallpatienten an das Krankenhaus eines Freundes überweisen, das sie heilen kann. Solange die Notfälle andauern, kommen weniger Patienten von allein; ab dem zweiten Jahr kommen mehr, und alle zwei bis drei Monate ziehen Epidemien durch jedes Krankenhaus. Ratten gefällt es hier auch. Stellen Sie Berater ein, solange es geht: ab dem neunten Monat suchen nur noch Assistenzärzte Arbeit. Um zu gewinnen, braucht jedes Krankenhaus einen Ruf von 550, $60,000 auf der Bank, 150 geheilte Patienten, eine Heilungsrate von 40 Prozent und den im Status-Fenster angezeigten Krankenhauswert."
multiplayer_window.level_intro_7 = "Cutthroat. Jedes Krankenhaus in dieser Stadt will das beste sein, und keines spielt fair. Bis März herrscht Waffenstillstand; dann werden die fiesen Tricks Monat für Monat freigeschaltet: zuerst Rattenangriffe, Hetzkampagnen und kaputte Heizkessel, ab Juni böse Hausmeister, Epidemien und Spionage, ab September erzwungene Notfälle und Abwerber, und ab dem zweiten Jahr die stärkste Stufe jedes Tricks. Jeden Monat wird ein Trick zum halben Preis verkauft, das Krankenhaus am weitesten hinten zahlt für alle die Hälfte, und der Spitzenreiter zahlt nochmal die Hälfte mehr. Es lohnt sich zu kämpfen: Jobmessen im April, Oktober, nächsten April und nächsten Oktober bringen Chirurgen, Psychiater, Forscher und Berater auf die Bewerberliste, wer zuerst kommt, mahlt zuerst. Im August, Februar und im August danach bekommt jedes Krankenhaus gleichzeitig denselben Notfall, und wer zuerst alle Patienten rettet, erhält $10,000 und Ruf. Wer zuerst das Röntgengerät, den Scanner oder die Blutmaschine entdeckt, erhält ebenfalls $10,000 (gestohlene Pläne zählen nicht), und jedes Quartal gewinnt das Krankenhaus, das die meisten Patienten geheilt hat, Ruf. Von einem Rivalen geschickte Ratten bringen $100 pro Abschuss. Maschinen verschleißen hier schneller, und vier Erdbeben erschüttern die Stadt, jedes stärker als das vorige. Um zu gewinnen, braucht ein Krankenhaus einen Ruf von 650, $150,000 auf der Bank, 300 geheilte Patienten, eine Heilungsrate von 55 Prozent und den im Status-Fenster angezeigten Krankenhauswert. Mit vier Spielern ist die Stadt Matroftts Karte."
multiplayer_window.level_intro_8 = "Team Town, Matroftts Karte, ist für zwei gegen zwei gemacht: Die vier Krankenhäuser stehen paarweise in der Mitte der Stadt, Teamkollegen Seite an Seite, mit viel Land zum Verkauf auf allen Seiten. Setzen Sie Freunde ins selbe Team und treten Sie gegen das andere Paar an. Um zu gewinnen, braucht jedes Krankenhaus einen Ruf von 650, $100,000 auf der Bank, 200 geheilte Patienten, eine Heilungsrate von 50 Prozent und den im Status-Fenster angezeigten Krankenhauswert. Mit zwei oder drei Spielern wird die Karte einer anderen Stadt gespielt."
multiplayer_window.level_intro_9 = "Kreuzung, Matroftts Karte, hat Platz für acht: Die Stadt ist in drei Reihen zu je drei aufgeteilt, mit acht schon ummauerten Krankenhäusern um vier kleine Grundstücke zum Verkauf in der Mitte, wo sich die Wege kreuzen. Die vier Eckkrankenhäuser sind etwas größer. Mit vier Spielern oder weniger werden nur die Ecken besetzt, und die anderen Krankenhäuser stehen ebenfalls zum Verkauf. Patienten kommen von allen Seiten in die Stadt. Zum Sieg braucht jedes Krankenhaus einen Ruf von 650, $150.000 auf der Bank, 300 geheilte Patienten, eine Heilungsrate von 55 Prozent und den im Fortschrittsbericht angezeigten Krankenhauswert."
multiplayer_window.level_rats_notice = "Ratten! Ein Schwarm hat sich ins Krankenhaus geschlichen. Klicken Sie sie an, um sie abzuschießen, bevor sie sich im Müll vermehren."
multiplayer_window.level_slack_tongue_warning = "Aus der ganzen Stadt häufen sich Meldungen über Schlaffe Zungen. Im Mai bekommt jedes Krankenhaus Notfälle mit Schlaffer Zunge: erforschen Sie vorher die Zungenklinik."
multiplayer_window.level_won_end = "Sie haben das Level gewonnen. Gut gemacht!"
multiplayer_window.levels_caption = "Level"
multiplayer_window.levels_choose = "Level %d wählen"
multiplayer_window.levels_events = "%s-EREIGNISSE"
multiplayer_window.levels_from_campaign = "Räume, Krankheiten und Forschung wie in %s (Kampagnenlevel %d)."
multiplayer_window.levels_goal_balance = "$%s auf der Bank"
multiplayer_window.levels_goal_cure_rate = "Heilungsrate %d%%"
multiplayer_window.levels_goal_cured = "%d geheilt"
multiplayer_window.levels_goal_reputation = "Ruf %d"
multiplayer_window.levels_goal_value = "Wert +$%s"
multiplayer_window.levels_goals = "Zum Sieg:"
multiplayer_window.levels_legend = "Farbig: Startgrundstücke. Grau: zu verkaufen."
multiplayer_window.levels_map_by = "Karte von %s"
multiplayer_window.levels_map_players = "Karte für %d Spieler"
multiplayer_window.levels_money = "Geld: $%s"
multiplayer_window.levels_no_map = "Diese Karte ist nicht in Ihren Theme-Hospital-Daten."
multiplayer_window.levels_several = "Mehrere Krankenhäuser"
multiplayer_window.levels_shared = "Ein gemeinsames Krankenhaus"
multiplayer_window.levels_shared_note = "Kampagnenlevel %d: ein Krankenhaus, das alle gemeinsam bauen, mit den Zielen der Kampagne."
multiplayer_window.load_caption = "Mehrspielerspiel laden"
multiplayer_window.load_game = "MP-Spiel laden"
multiplayer_window.loading = "LADEN..."
multiplayer_window.locked = "  (Passwort)"
multiplayer_window.looking_at = "Ansicht: %s"
multiplayer_window.measuring = "Verbindung wird gemessen..."
multiplayer_window.menu_caption = "  MEHRSPIELER  "
multiplayer_window.menu_chat = "  NACHRICHT SENDEN (%1%)  "
multiplayer_window.menu_colours = "  SPIELERFARBEN  "
multiplayer_window.menu_colours_all = "  ALLE PERSONEN  "
multiplayer_window.menu_colours_off = "  AUS  "
multiplayer_window.menu_bot_chat = "  BOT-CHAT  "
multiplayer_window.menu_bot_chat_all = "  ALLES  "
multiplayer_window.menu_bot_chat_auto = "  OHNE SMALLTALK VON 3 BOTS AN  "
multiplayer_window.menu_bot_chat_useful = "  OHNE SMALLTALK  "
multiplayer_window.menu_bot_chat_off = "  AUS  "
multiplayer_window.menu_colours_others = "  PERSONEN DER ANDEREN  "
multiplayer_window.menu_players = "  SPIELER  "
multiplayer_window.menu_research = "  FORSCHUNG TEILEN  "
multiplayer_window.menu_sabotage = "  FIESE TRICKS  "
multiplayer_window.menu_trade = "  HANDEL MIT ANDEREN SPIELERN  "
multiplayer_window.mode_competitive = "Rennen: jeder für sich"
multiplayer_window.mode_coop = "Koop: alle gewinnen gemeinsam"
multiplayer_window.mode_mixed = "Rennen der Teams"
multiplayer_window.mode_shared = "Ein gemeinsames Krankenhaus"
multiplayer_window.mode_teams = "Rennen zweier Teams"
multiplayer_window.mode_teamshared = "Rennen der Team-Krankenhäuser"
multiplayer_window.money_received = "Geld von %s"
multiplayer_window.money_received_note = "%s hat Ihnen $%d geschickt."
multiplayer_window.money_sent = "Geld an %s gesendet"
multiplayer_window.mp_level = "%s (mit mehreren Krankenhäusern: Level %d)"
multiplayer_window.name = "Ihr Name"
multiplayer_window.new_room = "Neuer Raum"
multiplayer_window.no_auctions = "keine Auktionen"
multiplayer_window.no_helper_building = "Bots bauen nicht"
multiplayer_window.no_rooms = "Noch keine Räume. Erstellen Sie unten einen."
multiplayer_window.no_sharing = "kein Teilen"
multiplayer_window.no_socket = "Dieser Build hat keine Netzwerkunterstützung (LuaSocket fehlt)."
multiplayer_window.no_tricks = "keine Tricks"
multiplayer_window.not_encrypted = "Nicht verschlüsselt"
multiplayer_window.not_encrypted_build = "Nicht verschlüsselt: Dieses Spiel hat kein LuaSec"
multiplayer_window.not_encrypted_server = "Nicht verschlüsselt: Dieser Server hat kein Zertifikat"
multiplayer_window.not_ready = "nicht bereit"
multiplayer_window.offer_ability = "Fähigkeit: %d%%"
multiplayer_window.offer_accept = "Annehmen"
multiplayer_window.offer_accept_pay = "$%d zahlen"
multiplayer_window.offer_accept_price = "Annehmen und $%d zahlen"
multiplayer_window.offer_accepted_note = "%s hat angenommen: %s."
multiplayer_window.offer_accepted_price_note = "%s hat angenommen: %s, für $%d."
multiplayer_window.offer_caption = "Angebot von %s"
multiplayer_window.offer_decline = "Ablehnen"
multiplayer_window.offer_declined_note = "%s hat abgelehnt: %s."
multiplayer_window.offer_free_banner = "GRATIS: kostenlos für diesen Mitarbeiter"
multiplayer_window.offer_gone_note = "%s ist nicht mehr verfügbar."
multiplayer_window.offer_happy = "Zufriedenheit: %d%%"
multiplayer_window.offer_health = "Gesundheit: %d%%"
multiplayer_window.offer_illness = "Krankheit: %s"
multiplayer_window.offer_job = "Beruf: %s"
multiplayer_window.offer_later = "Später"
multiplayer_window.offer_no_money_note = "Sie können sich die geforderten $%d für %s nicht leisten."
multiplayer_window.offer_no_money_sender_note = "%s konnte sich den Preis für %s nicht leisten."
multiplayer_window.offer_no_skills = "Besondere Fähigkeiten: keine"
multiplayer_window.offer_not_diagnosed = "Noch nicht diagnostiziert (%d%% fertig)"
multiplayer_window.offer_patient_known = "ein Patient mit %s"
multiplayer_window.offer_patient_line = "%s überweist Ihnen einen Patienten:"
multiplayer_window.offer_patient_unknown = "ein nicht diagnostizierter Patient"
multiplayer_window.offer_price_banner = "PREIS: $%d, nur bei Annahme fällig"
multiplayer_window.offer_price_line = "PREIS: $%d. Verlangt für diesen Mitarbeiter."
multiplayer_window.offer_raise = "Verlangt eine Gehaltserhöhung"
multiplayer_window.offer_sent_note = "%s wurde %s angeboten. Warte auf die Antwort."
multiplayer_window.offer_sent_price_note = "%s wurde %s für $%d angeboten. Warte auf die Antwort."
multiplayer_window.offer_show = "Zeigen"
multiplayer_window.offer_skills = "Besondere Fähigkeiten: %s"
multiplayer_window.offer_staff_line = "%s bietet Ihnen einen Mitarbeiter an:"
multiplayer_window.offer_tired = "Müdigkeit: %d%%"
multiplayer_window.offer_wage = "Gehalt: $%d im Monat"
multiplayer_window.options_close = "Schließen"
multiplayer_window.options_host_only = "Nur der Host ändert diese."
multiplayer_window.options_off_line = "Optionen: %s"
multiplayer_window.other_build = "  (andere Spielversion)"
multiplayer_window.owner_mark = " (Host)"
multiplayer_window.password = "Passwort"
multiplayer_window.password_clear = "Nicht verschlüsselt: Das Passwort geht im Klartext raus. Zum Senden noch einmal drücken."
multiplayer_window.patient_arrived_note = "Ein von %s überwiesener Patient ist eingetroffen."
multiplayer_window.patient_on_the_way = "Überwiesen an %s"
multiplayer_window.places[1] = "1."
multiplayer_window.places[2] = "2."
multiplayer_window.places[3] = "3."
multiplayer_window.places[4] = "4."
multiplayer_window.places[5] = "5."
multiplayer_window.places[6] = "6."
multiplayer_window.places[7] = "7."
multiplayer_window.places[8] = "8."
multiplayer_window.player_away_note = "%s hat das Spiel verlassen: Das Krankenhaus zählt nicht für die Teamziele, bis die Person wieder beitritt (gleicher Raum, gleicher Name)."
multiplayer_window.player_back_note = "%s ist zurück: Das Krankenhaus zählt wieder für die Teamziele."
multiplayer_window.player_joined_game = "%s ist dem Spiel beigetreten."
multiplayer_window.player_rejoined_game = "%s ist wieder im Spiel."
multiplayer_window.player_line = "%s%s   %s ms   %s"
multiplayer_window.players = "%d Spieler"
multiplayer_window.players_balance = "Kontostand"
multiplayer_window.players_behind = "%d Stunden zurück"
multiplayer_window.players_caption = "Spieler"
multiplayer_window.players_goals = "Ziele"
multiplayer_window.players_hospital = "Krankenhaus"
multiplayer_window.players_left = "hat das Spiel verlassen"
multiplayer_window.players_ms = "%d ms"
multiplayer_window.players_name = "Spieler"
multiplayer_window.players_note = "Ping: Durchschnitt der letzten 10 Sekunden. Wert: der Krankenhauswert (ein Levelziel)."
multiplayer_window.players_ping = "Ping"
multiplayer_window.players_playing = "spielt"
multiplayer_window.players_quiet = "keine Antwort seit %d s"
multiplayer_window.players_reputation = "Ruf"
multiplayer_window.players_status = "Status"
multiplayer_window.players_team = "Team"
multiplayer_window.players_value = "Wert"
multiplayer_window.players_waiting = "Warte auf die Liste des Servers..."
multiplayer_window.players_you = "Sie"
multiplayer_window.plot_bought_transaction = "Land von %s (Grundstück %d)"
multiplayer_window.plot_give_button = "Grundstück anbieten"
multiplayer_window.plot_give_cancel = "Abbrechen"
multiplayer_window.plot_give_caption = "Grundstück %d übergeben"
multiplayer_window.plot_give_free = "Preis: gratis"
multiplayer_window.plot_give_hint = "Dieses Grundstück einem Verbündeten überlassen, gratis oder für einen Preis"
multiplayer_window.plot_auction_hint = "Wird versteigert: %s kann mitbieten"
multiplayer_window.plot_buy_hint = "Keine Auktion: du kaufst es sofort"
multiplayer_window.plot_give_none = "Es gibt niemanden, dem Sie ein Grundstück überlassen können."
multiplayer_window.plot_give_offered = "Angeboten. Das Grundstück wechselt den Besitzer, wenn der andere Spieler annimmt."
multiplayer_window.plot_give_price = "Preis: $%d"
multiplayer_window.plot_give_to = "An welchen Verbündeten:"
multiplayer_window.plot_given_transaction = "Land an %s (Grundstück %d)"
multiplayer_window.plot_offer_accepted_note = "%s hat Grundstück %d angenommen."
multiplayer_window.plot_offer_accepted_price_note = "%s hat Grundstück %d für $%d angenommen."
multiplayer_window.plot_offer_declined_note = "%s hat Grundstück %d abgelehnt."
multiplayer_window.plot_offer_free_line = "GRATIS: kostenlos für dieses Grundstück."
multiplayer_window.plot_offer_gone_note = "Das Angebot für Grundstück %d ist hinfällig: Die Lage hat sich geändert."
multiplayer_window.plot_offer_line = "%s bietet Ihnen Grundstück %d an (%d Felder Land)."
multiplayer_window.plot_offer_no_money_note = "Sie können sich die $%d für Grundstück %d nicht leisten."
multiplayer_window.plot_offer_no_money_sender_note = "%s konnte sich Grundstück %d nicht leisten."
multiplayer_window.plot_offer_price_line = "PREIS: $%d, nur bei Annahme fällig."
multiplayer_window.plot_offer_sent_note = "Grundstück %d wurde %s als Geschenk angeboten. Warte auf die Antwort."
multiplayer_window.plot_offer_sent_price_note = "Grundstück %d wurde %s für $%d angeboten. Warte auf die Antwort."
multiplayer_window.plot_received_note = "Grundstück %d gehört jetzt Ihnen, von %s."
multiplayer_window.plot_sell_hint = "Dieses Grundstück an die Bank zurückverkaufen (es muss leer sein)"
multiplayer_window.plot_sell_question = "Möchten Sie dieses Grundstück verkaufen? Sie bekommen $%d zurück."
multiplayer_window.plot_sold_note = "Grundstück %d wurde für $%d an die Bank zurückverkauft."
multiplayer_window.plot_sold_others_note = "%s hat Grundstück %d zurückverkauft. Es steht wieder zum Verkauf."
multiplayer_window.plot_sold_transaction = "Grundstück %d zurückverkauft"
multiplayer_window.race_and = " und "
multiplayer_window.race_failing = "Ihr Krankenhaus hat die Ziele dieses Levels verfehlt. Erholen Sie sich bis Ende nächsten Jahres, sonst sind Sie aus dem Rennen."
multiplayer_window.race_failing_other = "%s hat die Ziele dieses Levels verfehlt; scheidet aus, wenn sie nächstes Jahr wieder verfehlt werden."
multiplayer_window.race_left_end = "Sie haben das Rennen verlassen. Die anderen spielen um die nächsten Plätze weiter."
multiplayer_window.race_out[1] = "Schlechte Nachrichten."
multiplayer_window.race_out[2] = "Ihr Krankenhaus hat die Ziele dieses Levels zwei Jahre in Folge verfehlt: Es ist aus dem Rennen, auf dem %s Platz."
multiplayer_window.race_out[3] = "Zurück zur Lobby oder den anderen zusehen?"
multiplayer_window.race_out_other = "%s hat die Ziele zwei Jahre in Folge verfehlt und ist aus dem Rennen (%s Platz)."
multiplayer_window.race_out_short = "raus"
multiplayer_window.race_over[1] = "Das Rennen ist vorbei. Endstand:"
multiplayer_window.race_over[2] = "Zurück zur Lobby oder weiterspielen?"
multiplayer_window.race_over_won = "Glückwunsch, Ihr Team hat das Rennen gewonnen! Endstand:"
multiplayer_window.race_placed_other = "%s hat die Ziele dieses Levels erreicht: %s Platz. Das Rennen geht weiter."
multiplayer_window.race_standing = "%s %s"
multiplayer_window.race_standing_out = " (raus)"
multiplayer_window.race_watch = "Zusehen"
multiplayer_window.race_won[1] = "Glückwunsch!"
multiplayer_window.race_won[2] = "Ihr Krankenhaus hat die Ziele dieses Levels erreicht: %s Platz."
multiplayer_window.race_won[3] = "Die anderen kämpfen um die nächsten Plätze. Zurück zur Lobby oder zusehen?"
multiplayer_window.race_won_question = "Die anderen kämpfen um die nächsten Plätze. Möchten Sie zurück zur Lobby?"
multiplayer_window.race_won_allies = "Sie und %s haben es geschafft! Gut gemacht!"
multiplayer_window.race_won_allies_first = "Sie und %s haben es geschafft! Tolle Arbeit!"
multiplayer_window.race_won_first = "Ihr Krankenhaus hat als erstes alle Ziele von %s erreicht. Sie haben das Rennen gewonnen!"
multiplayer_window.race_won_place = "Ihr Krankenhaus hat alle Ziele von %s erreicht: %s Platz."
multiplayer_window.race_won_team_first = "Ihr Team hat als erstes alle Ziele von %s erreicht. Sie haben das Rennen gewonnen!"
multiplayer_window.race_won_team_place = "Ihr Team hat alle Ziele von %s erreicht: %s Platz."
multiplayer_window.race_won_together = "Sie haben es gemeinsam geschafft! Gut gemacht!"
multiplayer_window.race_won_together_first = "Sie haben es gemeinsam geschafft! Tolle Arbeit!"
multiplayer_window.race_won_well_done = "Gut gemacht!"
multiplayer_window.rat_attacks = "Rattenangriffe"
multiplayer_window.rats_off = "Rattenangriff (Rennen): nicht erlaubt"
multiplayer_window.rats_on = "Rattenangriff (Rennen): erlaubt"
multiplayer_window.ready = "Bereit"
multiplayer_window.rebuild_destroyed_room = "Dieser Raum wurde zerstört. Für $%d wegräumen und neu bauen?"
multiplayer_window.recommendation = "Bis zu %s; Aktionen dauern %s ms"
multiplayer_window.refer_button = "Patient überweisen"
multiplayer_window.refer_choose = "An welches Krankenhaus überweisen?"
multiplayer_window.refer_fax_choice = "An ein anderes Krankenhaus überweisen"
multiplayer_window.referral_cured_here_note = "Sie haben einen von %s überwiesenen Patienten geheilt: +%d Ruf extra."
multiplayer_window.referral_cured_note = "%s hat den von Ihnen überwiesenen Patienten geheilt: +%d Ruf."
multiplayer_window.refresh = "Aktualisieren"
multiplayer_window.rep_amount = "Punkte: %d"
multiplayer_window.rep_give_button = "%d Ihrer Rufpunkte abgeben"
multiplayer_window.rep_given_note = "Sie haben für %s gebürgt: Sie haben %d Rufpunkte abgegeben."
multiplayer_window.rep_received_note = "%s bürgt für Ihr Krankenhaus: Sie haben %d Rufpunkte gewonnen."
multiplayer_window.rep_rivals = "Nur Verbündete können füreinander bürgen."
multiplayer_window.rep_sent = "Erledigt. Die Punkte wechseln gleich den Besitzer."
multiplayer_window.rep_vouch_caption = "Bürgen: Rufpunkte von Ihnen abgeben"
multiplayer_window.repair_destroyed_room = "Dieser Raum wurde zerstört. Für $%d reparieren, den Preis eines neuen mit Einrichtung? (Nein: stattdessen wegräumen.)"
multiplayer_window.research_accept = "Ich NEHME dieses Forschungswissen AN"
multiplayer_window.research_accept_price = "Ich NEHME dieses Forschungswissen für $%d AN"
multiplayer_window.research_accepted_note = "%s hat Ihre Forschung angenommen (bezahlt: $%d)."
multiplayer_window.research_all = "Alle"
multiplayer_window.research_and_more = "und %d weitere"
multiplayer_window.research_bought_transaction = "Forschung von %s"
multiplayer_window.research_caption = "Forschung mit %s teilen"
multiplayer_window.research_decline = "Ich LEHNE dieses Forschungswissen AB"
multiplayer_window.research_declined_note = "%s hat Ihre Forschung abgelehnt."
multiplayer_window.research_free = "Preis: gratis"
multiplayer_window.research_free_line = "GRATIS: Diese Übertragung kostet nichts."
multiplayer_window.research_item_drug = "Medikament: %s"
multiplayer_window.research_item_machine = "Verbessert: %s"
multiplayer_window.research_known_note = "Sie kennen diese Forschung bereits komplett."
multiplayer_window.research_known_sender_note = "%s kannte diese Forschung bereits komplett."
multiplayer_window.research_next = "Mehr"
multiplayer_window.research_no_money_note = "Sie können sich diese Forschung nicht leisten ($%d)."
multiplayer_window.research_no_money_sender_note = "%s konnte sich Ihre Forschung nicht leisten."
multiplayer_window.research_none = "Sie haben keine Forschung, die dem Spieler fehlt."
multiplayer_window.research_none_selected = "Wählen Sie zuerst Forschung aus."
multiplayer_window.research_offer = "Anbieten"
multiplayer_window.research_offer_line = "%s möchte folgende Forschung mit Ihnen teilen:"
multiplayer_window.research_offered = "Angeboten. Warte auf die Antwort."
multiplayer_window.research_page = "Seite %d von %d"
multiplayer_window.research_previous = "Zurück"
multiplayer_window.research_price = "Preis: $%d"
multiplayer_window.research_price_line = "PREIS: $%d. Sie zahlen nur bei Annahme."
multiplayer_window.research_received_note = "Neue Forschung: %s."
multiplayer_window.research_sent_note = "Forschung an %s angeboten. Warte auf die Antwort."
multiplayer_window.research_sold_transaction = "Forschung verkauft an %s"
multiplayer_window.room_caption = "Raum: %s"
multiplayer_window.room_hint = "Gleiche Farbe: ein Krankenhaus. Gleiches Team: Sie gewinnen gemeinsam."
multiplayer_window.room_line = "%s   %d von %d   %s   Level %s%s"
multiplayer_window.rooms_caption = "Räume auf %s"
multiplayer_window.sabotage_again = "Klicken Sie erneut auf L%d, um es für $%d zu kaufen."
multiplayer_window.sabotage_alone = "Es ist kein Rivale mehr übrig, dem man Streiche spielen kann."
multiplayer_window.sabotage_arrived = "Ihr böser Hausmeister hat bei %s die Arbeit aufgenommen."
multiplayer_window.sabotage_boiler = "Heizkessel kaputt"
multiplayer_window.sabotage_boiler_notice = "Der Heizkessel ist ausgefallen, und das war kein Zufall. Ihre Hausmeister reparieren ihn: je mehr, desto schneller."
multiplayer_window.sabotage_caption = "Fiese Tricks gegen %s"
multiplayer_window.sabotage_caught = "Sie haben einen Hausmeister rausgeworfen, der nicht Ihrer war: %s hat ihn geschickt. Er geht zu ihm zurück."
multiplayer_window.sabotage_caught_owner = "%s hat Ihren bösen Hausmeister erwischt. Er kommt zurück und arbeitet wieder für Sie."
multiplayer_window.sabotage_close = "Schließen"
multiplayer_window.sabotage_done.boiler = "Der Heizkessel bei %s ist ausgefallen."
multiplayer_window.sabotage_done.emergency = "Ein Notfall ist auf dem Weg zu %s."
multiplayer_window.sabotage_done.epidemic = "Die ansteckenden Patienten sind auf dem Weg zu %s."
multiplayer_window.sabotage_done.espionage = "Ihr Spion war bei %s."
multiplayer_window.sabotage_done.handyman = "Ihr böser Hausmeister ist auf dem Weg zu %s."
multiplayer_window.sabotage_done.headhunter = "Ihr Abwerber hat einem Mitarbeiter von %s ein Angebot gemacht."
multiplayer_window.sabotage_done.rats = "Die Ratten ziehen bei %s ein."
multiplayer_window.sabotage_done.smear = "Die Hetzkampagne gegen %s hat begonnen."
multiplayer_window.sabotage_emergency = "Notfall"
multiplayer_window.sabotage_emergency_fax[1] = "Ein Notfall wurde zu Ihnen geschickt, und Sie können ihn nicht ablehnen."
multiplayer_window.sabotage_emergency_fax[2] = "%d Patienten mit %s treffen per Hubschrauber ein."
multiplayer_window.sabotage_emergency_fax[3] = "Behandeln Sie so viele wie möglich, bevor die Zeit abläuft."
multiplayer_window.sabotage_epidemic = "Epidemie"
multiplayer_window.sabotage_espionage = "Spionage"
multiplayer_window.sabotage_espionage_got = "Ihr Spion hat mitgebracht: %s."
multiplayer_window.sabotage_espionage_notice = "Jemand hat Dateien aus der Forschungsabteilung kopiert."
multiplayer_window.sabotage_espionage_notice_3 = "Jemand ist in die Forschungsabteilung eingebrochen: Dateien kopiert und die aktuelle Forschung um die Hälfte zurückgeworfen."
multiplayer_window.sabotage_handyman = "Böser Hausmeister"
multiplayer_window.sabotage_handyman_hint = {"Ihre Geräte gehen in letzter Zeit oft kaputt. Könnte ein böser Hausmeister in Ihrem Krankenhaus sein?", "Hier geht ständig etwas schief. Gehört wirklich jeder Ihrer Hausmeister zu Ihnen? Feuern Sie einen, der es nicht tut.", "Ein Hausmeister, an dessen Einstellung sich niemand erinnert, streift durch Ihre Gänge. Sehen Sie sich Ihre Hausmeister an: Ein Fremder kann rausgeworfen werden."}
multiplayer_window.sabotage_headhunter = "Abwerber"
multiplayer_window.sabotage_headhunter_left = "%s ist für ein besseres Angebot gegangen."
multiplayer_window.sabotage_headhunter_notice = "%s hat ein besseres Jobangebot von einem anderen Krankenhaus bekommen und verlangt $%d mehr Gehalt. Stimmen Sie innerhalb von 10 Tagen zu, sonst geht die Person."
multiplayer_window.sabotage_headhunter_won = "%s hat das Krankenhaus verlassen und steht auf der Bewerberliste: Stellen Sie die Person innerhalb von %d Tagen ein, bevor es jemand anderes darf."
multiplayer_window.sabotage_level = "L%d  $%d"
multiplayer_window.sabotage_level_locked = "L%d  Monat %d"
multiplayer_window.sabotage_level_off = "L%d  aus"
multiplayer_window.sabotage_levels.boiler[1] = "Der Heizkessel des Rivalen fällt aus: im Winter zu kalt, im Sommer zu heiß, bis seine Hausmeister ihn reparieren (kurze Reparatur)."
multiplayer_window.sabotage_levels.boiler[2] = "Der Heizkessel des Rivalen fällt aus, etwa doppelt so lange. Mehr Hausmeister reparieren ihn schneller."
multiplayer_window.sabotage_levels.boiler[3] = "Der Heizkessel des Rivalen fällt schwer aus: lange Reparatur. Mehr Hausmeister reparieren ihn schneller."
multiplayer_window.sabotage_levels.emergency[1] = "Ein Notfall, den der Rivale nicht ablehnen kann: 3 Patienten per Hubschrauber, mit einer Krankheit, die er kennt."
multiplayer_window.sabotage_levels.emergency[2] = "Ein Notfall, den der Rivale nicht ablehnen kann: 6 Patienten per Hubschrauber, mit einer Krankheit, die er kennt."
multiplayer_window.sabotage_levels.emergency[3] = "Ein Notfall, den der Rivale nicht ablehnen kann: 10 Patienten per Hubschrauber, vielleicht mit einer Krankheit, die er noch nicht entdeckt hat."
multiplayer_window.sabotage_levels.epidemic[1] = "2 ansteckende Patienten einer Krankheit kommen in sein Krankenhaus."
multiplayer_window.sabotage_levels.epidemic[2] = "4 ansteckende Patienten einer Krankheit kommen in sein Krankenhaus."
multiplayer_window.sabotage_levels.epidemic[3] = "7 ansteckende Patienten einer Krankheit kommen in sein Krankenhaus."
multiplayer_window.sabotage_levels.espionage[1] = "Kopieren Sie eine Verbesserung für ein Medikament oder Gerät, die der Rivale hat und Sie nicht: Sie wählen welche."
multiplayer_window.sabotage_levels.espionage[2] = "Kopieren Sie eine Entdeckung (ein Gerät oder einen Raum), die der Rivale hat und Sie nicht: Sie wählen welche."
multiplayer_window.sabotage_levels.espionage[3] = "Kopieren Sie zwei seiner Verbesserungen oder Entdeckungen (Ihre Wahl) und werfen Sie seine aktuelle Forschung um die Hälfte zurück."
multiplayer_window.sabotage_levels.handyman[1] = "Ein Hausmeister, der aussieht wie einer von ihnen, aber nicht arbeitet, 4 Monate lang. Wenn sie ihn finden und feuern, arbeitet er für Sie."
multiplayer_window.sabotage_levels.handyman[2] = "Wie L1, und er wirft zweimal am Tag Müll in ihre Gänge, 3 Monate lang."
multiplayer_window.sabotage_levels.handyman[3] = "Wie L2, und alle 3 Tage tut er so, als würde er eine Maschine reparieren, und lässt sie fast kaputt zurück. Bleibt 2 Monate."
multiplayer_window.sabotage_levels.headhunter[1] = "Der beste Assistenzarzt oder die beste Schwester des Rivalen bekommt ein besseres Angebot: Er zahlt innerhalb von 10 Tagen 50% mehr Gehalt oder verliert die Person an die Bewerberliste (2 Wochen für Sie reserviert)."
multiplayer_window.sabotage_levels.headhunter[2] = "Der beste Arzt des Rivalen bekommt ein besseres Angebot: Er zahlt innerhalb von 10 Tagen 75% mehr Gehalt oder verliert die Person an die Bewerberliste (2 Wochen für Sie reserviert)."
multiplayer_window.sabotage_levels.headhunter[3] = "Der beste Berater oder Facharzt des Rivalen bekommt ein besseres Angebot: Er verdoppelt das Gehalt innerhalb von 10 Tagen oder verliert die Person an die Bewerberliste (2 Wochen für Sie reserviert)."
multiplayer_window.sabotage_levels.rats[1] = "5 Ratten ziehen ein. Solange sie herumlaufen, kosten sie den Rivalen bis zu 1 Ruf pro Tag (bis zu 30 Tage), bis sie abgeschossen sind."
multiplayer_window.sabotage_levels.rats[2] = "10 Ratten ziehen ein. Solange sie herumlaufen, kosten sie den Rivalen bis zu 2 Ruf pro Tag (bis zu 30 Tage), bis sie abgeschossen sind."
multiplayer_window.sabotage_levels.rats[3] = "20 Ratten ziehen ein. Solange sie herumlaufen, kosten sie den Rivalen bis zu 3 Ruf pro Tag (bis zu 30 Tage), bis sie abgeschossen sind."
multiplayer_window.sabotage_levels.smear[1] = "Schlechte Presse für einen Monat: 3 von 10 neuen Patienten des Rivalen gehen stattdessen in die anderen Krankenhäuser."
multiplayer_window.sabotage_levels.smear[2] = "Schlechte Presse für 2 Monate: 4 von 10 neuen Patienten des Rivalen gehen stattdessen in die anderen Krankenhäuser."
multiplayer_window.sabotage_levels.smear[3] = "Schlechte Presse für 3 Monate: die Hälfte der neuen Patienten des Rivalen geht stattdessen in die anderen Krankenhäuser."
multiplayer_window.sabotage_locked_tooltip = "Auf diesem Level ist es ab Monat %d des Spiels kaufbar."
multiplayer_window.sabotage_next = "Nächster Rivale"
multiplayer_window.sabotage_off_tooltip = "Der Host hat diesen Trick in diesem Spiel nicht erlaubt (Spieloptionen)."
multiplayer_window.sabotage_pick = "Klicken Sie auf eine Stufe, um zu sehen, was sie bewirkt. Klicken Sie erneut, um sie zu kaufen."
multiplayer_window.sabotage_rats = "Rattenangriff"
multiplayer_window.sabotage_rats_notice = "Ratten! Ein Schwarm ist ins Krankenhaus eingezogen. Solange sie herumlaufen, kosten sie jeden Tag Ruf: Klicken Sie sie an, um sie abzuschießen."
multiplayer_window.sabotage_rats_reminder = "%d Ratten laufen noch im Krankenhaus herum und kosten jeden Tag Ruf."
multiplayer_window.sabotage_rats_reminders = {"%d Ratten laufen noch im Krankenhaus herum und kosten jeden Tag Ruf. Klicken Sie sie an, um sie abzuschießen.", "Die Ratten sind noch da, %d an der Zahl, und die Patienten reden darüber. Schießen Sie sie ab!", "Ihr Krankenhaus hat noch %d Ratten. Jeder Tag, den sie bleiben, kostet Sie Ruf."}
multiplayer_window.sabotage_refused = "Dieser fiese Trick geht nicht: %s."
multiplayer_window.sabotage_sent = "Bestellt. Sie zahlen, wenn er ausgeführt ist."
multiplayer_window.sabotage_smear = "Hetzkampagne"
multiplayer_window.sabotage_smear_notice = "Schlechte Presse: Eine Hetzkampagne gegen das Krankenhaus hält einige Patienten für %d Monat(e) fern."
multiplayer_window.sabotage_smear_over = "Die Hetzkampagne ist vorbei: Die Patienten kommen wieder wie zuvor ins Krankenhaus."
multiplayer_window.sabotage_spy_caption = "%s ausspionieren: wählen Sie %d"
multiplayer_window.sabotage_spy_pick = "Wählen Sie, was Ihr Spion kopieren soll, und drücken Sie dann Stehlen."
multiplayer_window.sabotage_spy_steal = "Stehlen ($%d)"
multiplayer_window.sabotage_transaction = "Fiese Tricks"
multiplayer_window.sabotage_went_home = "Die Zeit Ihres bösen Hausmeisters bei %s ist um. Er ist nach Hause gegangen."
multiplayer_window.saved_flag = "  gespeichertes Spiel"
multiplayer_window.saved_note = "Spiel gespeichert: %s"
multiplayer_window.saving_note = "Das Spiel wird auf dem Computer jedes Spielers gespeichert..."
multiplayer_window.select_room = "Wählen Sie zuerst einen Raum."
multiplayer_window.server = "Server"
multiplayer_window.server_eu1 = "EU1: stabil"
multiplayer_window.server_eu2 = "EU2: Testversionen"
multiplayer_window.server_version = "die Version des Servers"
multiplayer_window.share_research = "Forschung teilen"
multiplayer_window.shared_won = "Der Wechsel zum nächsten Level ist im Mehrspielermodus nicht verfügbar."
multiplayer_window.sharing_off = "Forschung teilen: aus"
multiplayer_window.sharing_on = "Forschung teilen: an"
multiplayer_window.staff_arrived_note = "%s ist eingetroffen und beginnt zu arbeiten."
multiplayer_window.staff_bought_transaction = "Personal von %s"
multiplayer_window.staff_on_the_way = "Unterwegs zu %s"
multiplayer_window.staff_received_note = "%s hat Ihnen einen Mitarbeiter geschickt: %s"
multiplayer_window.staff_sold_transaction = "Personal an %s"
multiplayer_window.start = "Spiel starten"
multiplayer_window.team_button = "Team %d"
multiplayer_window.team_lost = "%s hat die Ziele dieses Levels am Jahresende immer noch verfehlt, deshalb hat das Team das Level verloren."
multiplayer_window.team_member_out = "Ihr Krankenhaus hat die Ziele dieses Levels zwei Jahre in Folge verfehlt und ist aus dem Rennen. Ihr Team rennt weiter."
multiplayer_window.team_member_out_other = "%s hat die Ziele zwei Jahre in Folge verfehlt und ist aus dem Rennen; das Team rennt weiter."
multiplayer_window.team_race_mate_reached_fax[1] = "Ihr Teamkollege %s hat die Ziele dieses Levels erreicht!"
multiplayer_window.team_race_mate_reached_fax[2] = "Ihr Team gewinnt, sobald auch Ihr Krankenhaus es geschafft hat. Noch offen: %s."
multiplayer_window.team_race_mate_reached_fax[3] = "Ihr Teamkollege kann Ihnen mit Geld, Personal oder Patienten helfen."
multiplayer_window.team_race_reached_fax[1] = "Ihr Krankenhaus hat die Ziele dieses Levels erreicht!"
multiplayer_window.team_race_reached_fax[2] = "Das Rennen ist noch nicht gewonnen: Ihr Team gewinnt, sobald jedes seiner Krankenhäuser es geschafft hat. Noch offen: %s."
multiplayer_window.team_race_reached_fax[3] = "Halten Sie Ihr Krankenhaus am Laufen und helfen Sie den anderen mit Geld, Personal oder Patienten."
multiplayer_window.team_race_reached_other = "%s hat die Ziele dieses Levels erreicht (Team %s)."
multiplayer_window.team_won[1] = "Glückwunsch!"
multiplayer_window.team_won[2] = "Jedes Krankenhaus hat die Ziele dieses Levels erreicht: Das Team hat das Level gewonnen."
multiplayer_window.team_won[3] = "Zurück zur Lobby oder weiterspielen?"
multiplayer_window.too_many_hospitals = "Dieses Level fasst %d Krankenhäuser: Farben teilen"
multiplayer_window.trade_alone = "Es gibt niemanden, mit dem man handeln kann."
multiplayer_window.trade_caption = "Handel mit %s"
multiplayer_window.trade_close = "Schließen"
multiplayer_window.trade_free = "Preis: gratis"
multiplayer_window.trade_money_allies_only = "Geld geht nur an Verbündete."
multiplayer_window.running_flag = "läuft"
multiplayer_window.running_places = "läuft, %d frei"
multiplayer_window.seats_caption = "Plätze in %s"
multiplayer_window.seats_hint = "Übernehmen Sie den Platz eines Bots oder eines Spielers, der gegangen ist:"
multiplayer_window.seat_on = "%s, spielt"
multiplayer_window.seat_standin = "%s (gegangen, vorerst spielt ein Bot)"
multiplayer_window.seat_left = "%s (gegangen)"
multiplayer_window.players_standin = "weg - Bot"
multiplayer_window.trade_next_player = "Nächster Spieler"
multiplayer_window.trade_no_staff = "Sie haben kein Personal zum Senden."
multiplayer_window.trade_offered = "Angeboten. Die Person schließt sich an, wenn der andere Spieler annimmt."
multiplayer_window.trade_on_the_way = "- angeboten"
multiplayer_window.trade_price = "Preis: $%d"
multiplayer_window.trade_select_staff = "Klicken Sie zuerst auf einen Mitarbeiter."
multiplayer_window.trade_send_money = "$%d senden"
multiplayer_window.trade_request_money = "$%d anfordern"
multiplayer_window.trade_send_money_to = "$%d an %s senden"
multiplayer_window.trade_request_money_from = "%s um $%d bitten"
multiplayer_window.trade_send_staff_to = "Gewählte Kraft %s anbieten"
multiplayer_window.trade_who = "%s  -  %s"
multiplayer_window.trade_ally = "dein Verbündeter"
multiplayer_window.trade_rival = "dein Rivale"
multiplayer_window.trade_is_bot = "ein Bot"
multiplayer_window.trade_previous_player = "Zurück"
multiplayer_window.trade_next_player_short = "Weiter"
multiplayer_window.rep_give_button_to = "%s %d deiner Rufpunkte geben"
multiplayer_window.trade_money_confirm = "Willst du wirklich $%d an %s schicken?"
multiplayer_window.trade_money_short = "So viel Geld hast du nicht."
multiplayer_window.trade_send_staff = "Ausgewählten Mitarbeiter anbieten"
multiplayer_window.trade_sent = "Gesendet. Es kommt gleich an."
multiplayer_window.tricks_off = "Fiese Tricks (Rennen): aus"
multiplayer_window.tricks_on = "Fiese Tricks (Rennen): an"
multiplayer_window.vaccination_mode_hint = "Impfmodus: Klicken Sie auf die infizierten Patienten, damit eine Schwester sie impft. Rechtsklick, Esc oder erneuter Klick auf die Spritze beendet den Modus."
multiplayer_window.vote_agree = "Zustimmen"
multiplayer_window.vote_asked = "Sie haben die anderen gebeten, die Geschwindigkeit auf %s zu ändern."
multiplayer_window.vote_confirm = "Die anderen Spieler bitten, die Geschwindigkeit des Spiels auf %s zu ändern?"
multiplayer_window.vote_decline = "Ablehnen"
multiplayer_window.vote_declined = "%s hat die Änderung der Geschwindigkeit auf %s abgelehnt."
multiplayer_window.vote_lapsed = "Nicht genug Spieler haben rechtzeitig zugestimmt: Die Geschwindigkeit bleibt, wie sie war."
multiplayer_window.vote_open = "Über eine Geschwindigkeitsänderung wird bereits abgestimmt."
multiplayer_window.vote_passed = "Die Spieler haben zugestimmt: Die Geschwindigkeit ist jetzt %s."
multiplayer_window.vote_passed_paused = "Die Spieler haben sich auf %s geeinigt: Das Spiel läuft mit dieser Geschwindigkeit weiter, sobald die Pause endet."
multiplayer_window.vote_request = "%s möchte die Spielgeschwindigkeit ändern"
multiplayer_window.vote_request_speed = "auf %s."
multiplayer_window.waiting_player = "wartet auf einen Spieler..."
tooltip.main_menu.multiplayer = "Mit anderen über einen Mehrspieler-Server spielen (experimentell)"
tooltip.multiplayer_window.bot_level = "Rechtsklick: ein leichter, normaler oder schwerer Bot"
tooltip.multiplayer_window.ask_money = "Einen anderen Spieler um Geld bitten. Er entscheidet, ob er zahlt."
tooltip.multiplayer_window.auctions = "Der Host entscheidet, welche Grundstücke versteigert werden, wenn ein Spieler eines kaufen will"
tooltip.multiplayer_window.auctions_all = "Jedes Grundstück wird unter allen Krankenhäusern versteigert, die es kaufen dürfen"
tooltip.multiplayer_window.auctions_near = "Grundstücke auf der Seite eines anderen Spielers oder neben dem Land eines anderen Krankenhauses werden versteigert; die anderen werden einfach gekauft"
tooltip.multiplayer_window.auctions_none = "Keine Auktionen: Wer zuerst fragt, kauft das Grundstück"
tooltip.multiplayer_window.colour = "Die Farbe Ihres Krankenhauses: Spieler mit derselben Farbe bauen gemeinsam ein Krankenhaus. Zum Ändern klicken (der Host kann die Farbe aller ändern, auch die von Bots)"
tooltip.multiplayer_window.connect = "Mit dem Server verbinden und seine Räume anzeigen"
tooltip.multiplayer_window.continue_game = "Ein früher gespeichertes Mehrspielerspiel fortsetzen (Datei > Speichern oder der monatliche Autosave): Wählen Sie es aus der Liste. Ohne Auswahl startet der Raum ein neues Spiel"
tooltip.multiplayer_window.download = "Dieser Server verwendet eine andere Spielversion: Die Download-Seite im Webbrowser öffnen"
tooltip.multiplayer_window.game_options = "Die Spieloptionen: Landauktionen und mehr (der Host legt sie fest)"
tooltip.multiplayer_window.helpers = "Der Gastgeber entscheidet: Ein Bot, der sich ein Krankenhaus mit einem Menschen teilt, baut Räume und stellt Dinge in die Flure, oder überlässt das dem Menschen (er stellt weiter Personal ein, zahlt Prämien, teilt Forschung, bietet bei Auktionen und kauft Grundstücke)"
tooltip.multiplayer_window.level = "Das Level aus einer Liste mit Zielen und Karte auswählen. Ein gemeinsames Krankenhaus spielt die Level der Kampagne; mehrere Krankenhäuser spielen die Mehrspielerlevel (1 bis 8, eine höhere Zahl spielt Level 8). Level 6 ist Emergency!: im ersten Jahr viermal im Monat Notfälle, danach Epidemien; Level 7 ist Cutthroat, gemacht für ein Rennen gegeneinander: fiese Tricks Monat für Monat, Jobmessen, Renn-Notfälle und Erdbeben; Level 8 ist Team Town, Matroftts Karte für zwei gegen zwei"
tooltip.multiplayer_window.levels_players = "Die Karte für diese Spielerzahl (jede Spielerzahl hat eine eigene Karte)"
tooltip.multiplayer_window.name = "Der Name, den andere Spieler sehen"
tooltip.multiplayer_window.new_game = "Ein neues Spiel starten statt des gespeicherten"
tooltip.multiplayer_window.password = "Passwort des Raums, dem Sie beitreten oder den Sie erstellen (leer: kein Passwort)"
tooltip.multiplayer_window.player_row = "Klick: das Krankenhaus dieses Spielers ansehen (N: das nächste Krankenhaus)"
tooltip.multiplayer_window.chat_target = "An wen die Nachricht geht: alle, dein Team (in einem Rennen der Teams) oder ein Spieler. Klick oder Tab für den nächsten"
tooltip.multiplayer_window.players = "Für wie viele Spieler der Raum gedacht ist"
tooltip.multiplayer_window.rats = "Der Host entscheidet: In einem Rennen mit fiesen Tricks dürfen Spieler Ratten im Krankenhaus eines Rivalen loslassen (das kostet ihn Ruf), oder nicht"
tooltip.multiplayer_window.ready = "Dem Host mitteilen, dass Sie startbereit sind"
tooltip.multiplayer_window.refer_button = "Diesen Patienten dem Krankenhaus eines anderen Spielers anbieten. Er muss annehmen."
tooltip.multiplayer_window.send_staff = "Diesen Mitarbeiter in das Krankenhaus eines anderen Spielers schicken. Er muss annehmen."
tooltip.multiplayer_window.server = "Adresse des Mehrspielerservers, zum Beispiel eu2.bachelor-tech.com:47800"
tooltip.multiplayer_window.server_eu1 = "eu1.bachelor-tech.com: die neueste stabile Version"
tooltip.multiplayer_window.server_eu2 = "eu2.bachelor-tech.com: der neueste Testbuild"
tooltip.multiplayer_window.share_research = "Forschung, die Sie haben, dem Krankenhaus eines anderen Spielers anbieten, gratis oder für einen Preis. Er muss annehmen."
tooltip.multiplayer_window.sharing = "Der Host entscheidet: Spieler dürfen Forschung untereinander teilen oder verkaufen, oder nicht (wie im Originalspiel)"
tooltip.multiplayer_window.start = "Das Spiel für alle im Raum starten"
tooltip.multiplayer_window.team = "Ihr Team: Dasselbe Team gewinnt gemeinsam, verschiedene Teams rennen zu den Zielen und dürfen sich fiese Tricks spielen. Zum Ändern klicken (der Host kann das Team aller ändern, auch von Bots)"
tooltip.multiplayer_window.tricks = "Der Host entscheidet: In einem Rennen dürfen Spieler fiese Tricks gegen Rivalen kaufen, oder nicht (wie im Originalspiel)"
