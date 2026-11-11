--[[ Copyright (c) 2010 Manuel "Roujin" Wolf, 2024 Peppe "Inkub0" Malara,
   2024 Sebastiano Pistore

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

Font("cp437")
Language("Italiano", "Italian", "it", "ita")
Inherit("english")
Inherit("original_strings", 3)
Encoding(utf8)
IsArabicNumerals(true)

-- override
-- TODO? Any more original strings that are off in italian translation?
adviser.warnings.money_low = "Stai finendo i soldi!"
-- TODO: tooltip.graphs.reputation -- this tooltip talks about hospital value. Actually it should say reputation.
-- TODO: tooltip.status.close -- it's called status window, not overview window.

-- The originals of these two contain one space too much
fax.emergency.cure_not_possible_build = "E' necessario costruire un %s" -- È unsupported by TH font
fax.emergency.cure_not_possible_build_and_employ = "E' necessario costruire un %s e assumere un %s" -- È unsupported in TH font

-- An override for the squits becoming the the squits see issue 1646
adviser.research.drug_improved_1 = "Il medicinale per %s è stato migliorato dal Reparto ricerca."

-------------------------------  NEW STRINGS  -------------------------------
date_format = {
  daymonth = "%1% %2:months%",
}

object.litter = "Spazzatura"
tooltip.objects.litter = "Spazzatura: Lasciata sul pavimento da un paziente perché non ha trovato un cestino in cui gettarla."

object.rathole = "Tana di ratti"
tooltip.objects.rathole = "Casa di una famiglia di ratti che trova l'ospedale abbastanza sporco da poterci vivere."

tooltip.fax.close = "Chiudi questa finestra senza cancellare il messaggio"
tooltip.message.button = "Click sinistro per aprire il messaggio"
tooltip.message.button_dismiss = "Click sinistro per aprire il messaggio, click destro per eliminarlo"
tooltip.casebook.cure_requirement.hire_staff = "Hai bisogno di assumere personale per somministrare questa cura"
tooltip.casebook.cure_type.unknown = "Ancora non sei a conoscenza di una cura per questa malattia"
tooltip.research_policy.no_research = "Non c'è nessuna ricerca in corso in questa categoria al momento"
tooltip.research_policy.research_progress = "Progresso verso una nuova scoperta in questa categoria: %1%/%2%"

menu["player_count"] = "NUMERO GIOCATORI"

menu_file = {
  load =    " (%1%) CARICA   ",
  save =    " (%1%) SALVA   ",
  restart = " (%1%) RIAVVIA",
  quit =    " (%1%) ESCI   "
}

menu_options = {
  sound = "  (%1%) SUONO   ",
  announcements = "  (%1%) ANNUNCI   ",
  music = "  (%1%) MUSICA   ",
  jukebox = "  (%1%) JUKEBOX  ",
  lock_windows = "  BLOCCA FINESTRE  ",
  edge_scrolling = "  SCORRIMENTO AI BORDI  ",
  capture_mouse = "  CATTURA MOUSE  ",
  adviser_disabled = "  (%1%) CONSIGLIERE  ",
  warmth_colors = "  COLORI RISCALDAMENTO  ",
  wage_increase = "  RICHIESTE STIPENDI",
  twentyfour_hour_clock = "  OROLOGIO 24 ORE  "
}

menu_options_game_speed = {
  pause               = "  (%1%) PAUSA  ",
  slowest             = "  (%1%) LENTISSIMO  ",
  slower              = "  (%1%) LENTO  ",
  normal              = "  (%1%) NORMALE  ",
  max_speed           = "  (%1%) VELOCITA' MASSIMA  ",
  and_then_some_more  = "  (%1%) E ANCORA DI PIU'  ",
}

menu_options_warmth_colors = {
  choice_1 = "  ROSSO  ",
  choice_2 = "  BLU VERDE ROSSO  ",
  choice_3 = "  GIALLO ARANCIONE ROSSO  ",
}

menu_options_wage_increase = {
  grant = "    CONCEDI ",
  deny =  "    NEGA ",
}

-- Add F-keys to entries in charts menu (except briefing), also town_map was added.
menu_charts = {
  bank_manager  = "  (%1%) BANCA  ",
  statement     = "  (%1%) RENDICONTO  ",
  staff_listing = "  (%1%) PERSONALE  ",
  town_map      = "  (%1%) MAPPA CITTADINA  ",
  casebook      = "  (%1%) REGISTRO CURE  ",
  research      = "  (%1%) RICERCA  ",
  status        = "  (%1%) RIEPILOGO  ",
  graphs        = "  (%1%) GRAFICI  ",
  policy        = "  (%1%) GESTIONE  ",
}


-- The demo does not contain this string
menu_file.restart = "  RIAVVIA  "

menu_debug = {
  jump_to_level               = "  SALTA AL LIVELLO  ",
  connect_debugger            = "  (%1%) CONNETTI SERVER LUA DBGp  ",
  transparent_walls           = "  (%1%) MURI TRASPARENTI  ",
  limit_camera                = "  LIMITA TELECAMERA  ",
  disable_salary_raise        = "  DISABILITA AUMENTI DI SALARIO  ",
  make_debug_fax              = "  CREA FAX DI DEBUG  ",
  make_debug_patient          = "  CREA PAZIENTE DI DEBUG  ",
  cheats                      = "  (%1%) CHEAT  ",
  lua_console                 = "  (%1%) CONSOLE LUA  ",
  debug_script                = "  (%1%) ESEGUI SCRIPT DI DEBUG  ",
  calls_dispatcher            = "  GESTORE CHIAMATE  ",
  dump_strings                = "  (%1%) DUMP DELLE STRINGHE  ",
  dump_gamelog                = "  (%1%) DUMP DEL GAMELOG  ",
  map_overlay                 = "  MAPPA IN SOVRAPPOSIZIONE  ",
  sprite_viewer               = "  VISUALIZZATORE SPRITE  ",
  allow_blocking_off_areas    = " CONSENTI IL BLOCCO DI ALCUNE AREE ",
}
menu_debug_overlay = {
  none                        = "  NESSUN OVERLAY  ",
  flags                       = "  FLAG  ",
  positions                   = "  POSIZIONI  ",
  heat                        = "  TEMPERATURA  ",
  byte_0_1                    = "  BYTE 0 & 1  ",
  byte_floor                  = "  BYTE PAVIMENTO  ",
  byte_n_wall                 = "  BYTE N MURO  ",
  byte_w_wall                 = "  BYTE W MURO  ",
  byte_5                      = "  BYTE 5  ",
  byte_6                      = "  BYTE 6  ",
  byte_7                      = "  BYTE 7  ",
  parcel                      = "  LOTTO  ",
}
menu_player_count = {
    players_1 = "  1 GIOCATORE  ",
    players_2 = "  2 GIOCATORI  ",
    players_3 = "  3 GIOCATORI  ",
    players_4 = "  4 GIOCATORI  ",
}
adviser = {
  room_forbidden_non_reachable_parts = "Mettere la stanza in questa posizione bloccherebbe l'accesso ad alcune parti dell'ospedale.",
  staff_place_advice = {
    not_enough_lecture_chairs = "Agli studenti di medicina serve sempre uno sgabello per sedersi!",
  },
  warnings = {
    no_desk = "Dovresti costruire un banco di accettazione ed assumere una receptionist!",
    no_desk_1 = "Se vuoi che i pazienti vengano nel tuo ospedale dovrai assumere una receptionist e costruirle un banco accettazione dove farla lavorare!",
    no_desk_2 = "Ben fatto, deve essere un record mondiale: quasi un anno e nessun paziente! Se vuoi continuare come Manager di questo ospedale dovrai assumere una receptionist e costruire un banco di accettazione dove farla lavorare!",
    no_desk_3 = "Grandioso, quasi un anno e ancora non hai personale all'accettazione! Come ti aspetti di trovare pazienti, ora vedi di rimediare e di non fare più casini!",
    no_desk_4 = "Una receptionist ha bisogno del banco accettazione per accogliere i clienti quando arrivano",
    no_desk_5 = "Beh, era ora, presto dovresti cominciare a vedere arrivare i pazienti!",
    no_desk_6 = "Hai una receptionist, che ne dici quindi di costruirle un banco di accettazione dove poter lavorare?",
    no_desk_7 = "Hai costruito il banco di accettazione, quindi che ne dici di assumere una receptionist? Non vedrai pazienti finché non risolvi questa cosa!",
    cannot_afford = "Non hai abbastanza soldi in banca per assumere quella persona!", -- I can't see anything like this in the original strings
    cannot_afford_2 = "Non hai abbastanza soldi in banca per fare quell'acquisto!",
    falling_1 = "Ehi! Non è divertente, attento a dove clicchi: qualcuno potrebbe farsi male!",
    falling_2 = "Basta fare casini, a te piacerebbe?",
    falling_3 = "Ahi, deve far male, qualcuno chiami un dottore!",
    falling_4 = "Questo è un ospedale, non un parco giochi!",
    falling_5 = "Non è il luogo adatto per far cadere le persone, sono malate sai!",
    falling_6 = "Non è una sala da bowling, i malati non dovrebbero essere trattati così!",
    research_screen_open_1 = "Devi costruire un Reparto Ricerca prima di poter accedere alla schermata Ricerca.",
    research_screen_open_2 = "La ricerca è disabilitata in questo livello.",
    researcher_needs_desk_1 = "Un ricercatore ha bisogno di una scrivania su cui lavorare.",
    researcher_needs_desk_2 = "Al tuo ricercatore ha fatto piacere tu gli abbia concesso una pausa. Se invece volevi assegnare più personale alla ricerca devi procurare a ognuno di loro una scrivania sulla quale lavorare.",
    researcher_needs_desk_3 = "Ogni ricercatore ha bisogno della propria scrivania su cui poter lavorare.",
    nurse_needs_desk_1 = "Ogni infermiera ha bisogno della propria scrivania su cui poter lavorare.",
    nurse_needs_desk_2 = "Alla tua infermiera ha fatto piacere tu le abbia concesso una pausa. Se invece volevi assegnare più personale al reparto devi procurare a ognuna di loro una scrivania sulla quale lavorare.",
    low_prices = "I tuoi prezzi per %s sono troppo bassi. Questo attirerà più persone nel tuo ospedale, ma non guadagnerai molto da ognuno di loro.",
    high_prices = "I tuoi prezzi per %s sono alti. In questo modo vedrai buoni guadagni sul breve periodo, ma a lungo andare spingerai molte persone ad andarsene.",
    fair_prices = "I tuoi prezzi per %s sembrano giusti ed equilibrati.",
    patient_not_paying = "Un paziente è andato via senza pagare %s perché è troppo costosa!",
    another_desk = "Dovrai costruire un'altra scrivania per la nuova receptionist.",
    cannot_afford_machine = "Ti servono almeno $%1% in banca per pagare %2%!",
  },
  cheats = {
    th_cheat = "Congratulazioni, hai sbloccato i cheat!",
    roujin_on_cheat = "Sfida di Roujin attivata! Buona fortuna...",
    roujin_off_cheat = "Sfida di Roujin disattivata.",
    norest_off_cheat = "Uff! Sembra che quel ronzio finalmente sia svanito. Ora il tuo staff riposerà adeguatamente.",
    norest_on_cheat = "Oh no! Sembra che il tuo personale abbia assunto troppa caffeina e non senta più il bisogno di riposare.",
  },
}

dynamic_info.patient.actions.no_gp_available = "In attesa che venga costruito un ambulatorio"
dynamic_info.staff.actions.heading_for = "Sta andando verso %s"
dynamic_info.staff.actions.fired = "Licenziato"
dynamic_info.patient.actions.epidemic_vaccinated = "Non sono più infetto"
dynamic_info.object.strength_extra_info = "Forza %d (Migliorabile a %d)"
dynamic_info.staff.actions.vaccine = "Sta vaccinando un paziente"

progress_report.free_build = "COSTRUZIONE LIBERA"

fax = {
   choices = {
    return_to_main_menu = "Ritorna al menu principale",
    accept_new_level = "Vai al livello successivo",
    decline_new_level = "Continua a giocare un altro po'",
  },
  emergency = {
    num_disease_singular = "C'è una persona con %s che richiede la tua immediata attenzione.",
    free_build = "Se hai successo la tua reputazione aumenterà, ma se fallisci la tua reputazione verrà intaccata pesantemente.",
  },
  vip_visit_result = {
    remarks = {
      free_build = {
        "Hai proprio un bell'ospedale! Anche se non è difficile ottenerlo con fondi illimitati, eh?",
        "Non sono un economista, ma penso che anch'io avrei potuto dirigere quest'ospedale, non so se mi spiego...",
        "Un ospedale molto ben gestito. Attento alla crisi economica però! Ah, giusto... non te ne sei dovuto preoccupare.",
      }
    }
  }
}

letter = {
  dear_player = "Caro %s\n",
  custom_level_completed = "Ben fatto! Hai completato tutti gli obiettivi di questo livello personalizzato!",
  return_to_main_menu = "Vuoi tornare al menu principale o vuoi continuare a giocare?",
  campaign_level_completed = "Ottimo lavoro! Hai completato il livello. Ma non è ancora finita!\n Saresti interessato a una posizione nell'ospedale %s?",
  campaign_completed = "Incredibile! Sei riuscito a completare tutti i livelli. Ora puoi rilassarti e divertirti a riempire i forum su internet con i tuoi fantastici risultati. Buona fortuna!",
  campaign_level_missing = "Mi dispiace, ma sembra che il livello successivo di questa campagna non sia presente. (Nome: %s)",
}

install = {
  title = "----------------------------- Installazione CorsixTH -----------------------------",
  th_directory = "CorsixTH ha bisogno di una copia dei file dati di Theme Hospital (o della demo) per essere eseguito. Per favore indica la posizione della cartella HOSP nell'installazione di Theme Hospital.",
  ok = "Ok",
  exit = "Esci",
  cancel = "Annulla",
}

misc = {
  not_yet_implemented = "(non ancora implementato)",
  no_heliport = "Non è stata ancora scoperta nessuna malattia, non c'è un eliporto sulla mappa oppure potrebbe essere necessario costruire un banco accettazione e assumere una receptionist",
  epidemic_no_icon_to_toggle = "Impossibile mostrare/nascondere icone infezione - non ci sono epidemie in corso che non siano gia' state rivelate",
  epidemic_no_diseases = "Impossibile creare epidemia - non ci sono malattie contagiose disponibili.",
  cant_treat_emergency = "Il tuo ospedale non può affrontare questa emergenza perché la sua malattia non è stata scoperta. Sentiti libero di riprovare.",
  earthquakes_on = "I terremoti sono abilitati",
  epidemics_on = "Le epidemie sono abilitate",
  epidemic_no_receptionist = "Impossibile creare epidemia - nessuna reception funzioante",
  epidemics_off = "Le epidemie sono disabilitate",
  earthquakes_off = "I terremoti sono disabilitati",
}

hotkeys_file_err.file_err_01 = "Impossibile caricare il file hotkeys.txt. Assicurati che CorsixTH abbia permessi in lettura/scrittura "
hotkeys_file_err.file_err_02 = ", oppure usa l'opzione --hotkeys-file=filename in riga di comando per specificare un file con tali permessi. Per riferimento, l'errore durante il caricamento era: "

main_menu = {
  new_game = "Nuova partita",
  custom_campaign = "Campagna personalizzata",
  custom_level = "Livello personalizzato",
  continue = "Continua partita",
  load_game = "Carica partita",
  options = "Opzioni",
  map_edit = "Editor mappe",
  savegame_version = "Versione salvataggi: ",
  version = "Versione: ",
  exit = "Esci",
  updates_off = "Disabilita aggiornamenti",
}

tooltip.main_menu = {
  new_game = "Nuova partita",
  custom_campaign = "Gioca una campagna creata dalla comunità",
  custom_level = "Costruisci il tuo ospedale in un livello personalizzato",
  load_game = "Carica una partita salvata in precedenza",
  options = "Modifica le impostazioni",
  map_edit = "Crea una mappa personalizzata",
  exit = "No, per favore non andartene!",
}

load_game_window = {
  caption = "Carica partita (%1%)",
}

tooltip.load_game_window = {
  load_game = "Carica la partita %s",
  load_game_number = "Carica la partita %d",
  load_autosave = "Carica autosalvataggio",
}

custom_game_window = {
  caption = "Partita personalizzata",
  free_build = "Costruzione libera",
  load_selected_level = "Inizia",
}

tooltip.custom_game_window = {
  choose_game = "Clicca su un livello per avere più informazioni",
  free_build = "Spunta questa casella per giocare senza soldi, né vittoria o sconfitta",
  load_selected_level = "Carica e gioca il livello selezionato",
}

custom_campaign_window = {
  caption = "Campagna personalizzata",
  start_selected_campaign = "Inizia campagna",
}

tooltip.custom_campaign_window = {
  choose_campaign = "Seleziona una campagna per avere più informazioni",
  start_selected_campaign = "Carica il primo livello di questa campagna",
}

save_game_window = {
  caption = "Salva partita (%1%)",
  new_save_game = "Nuovo salvataggio",
}

tooltip.save_game_window = {
  save_game = "Sovrascrivere salvataggio %s",
  new_save_game = "Inserisci il nome per un nuovo salvataggio",
}

save_map_window = {
  caption = "Salva mappa (%1%)",
  new_map = "Nuova mappa",
}

tooltip.save_map_window = {
  map = "Sovrascrivi mappa %s",
  new_map = "Inserisci il nome per il salvataggio della mappa",
}

menu_list_window = {
  name = "Nome",
  save_date = "Modificata",
  back = "Indietro",
  ok = "OK",
}

tooltip.menu_list_window = {
  name = "Clicca qui per ordinare la lista in ordine alfabetico",
  save_date = "Clicca qui per ordinare la lista in base alla data dell'ultima modifica",
  back = "Chiudi questa finestra",
  ok = "Conferma scelta",
}

-- Width / height's translation doesn't fit - had to write "larghezza" and "altezza" shorter
options_window = {
  caption = "Opzioni",
  option_on = "On",
  option_off = "Off",
  capture_mouse = "Cattura Mouse",
  option_enabled = "Attiv.",
  check_for_updates = "Cerca aggiornamenti",
  customise = "Personalizza",
  folder = "Cartelle",
  language = "Lingua del gioco",
  hotkey = "Scorciatoie",
  back = "Indietro",
  option_disabled = "Disabilitato",
  hotkey = "Scorciatoie",
  option_enabled = "Abilitato",
  right_mouse_scrolling_option_right = "Bottone Destro",
  right_mouse_scrolling_option_middle = "Bottone Centrale",
  right_mouse_scrolling = "Scorrimento con Mouse",
}
graphics_window = {
  fullscreen = "Schermo intero",
  width = "Largh",
  height = "Alt",
  option_on = "On",
  option_off = "Off",
  apply = "Applica",
  cancel = "Cancella",
}

tooltip.options_window = {
  capture_mouse = "Clicca per attivare o disattivare la cattura del puntatore all'interno della finestra di gioco",
  customise = "Altre impostazioni che puoi cambiare per personalizzare la tua esperienza di gioco",
  folder = "Opzioni cartelle",
  language = "La lingua in cui verrà mostrato il testo",
  select_language = "Seleziona la lingua del gioco",
  language_dropdown_item = "Seleziona %s come lingua",
  back = "Chiudi la finestra delle opzioni",
  hotkey = "Cambia le scorciatoie da tastiera.",
  language_dropdown_no_font = "Seleziona un font nelle impostazioni delle cartelle per abilitare questa lingua",
  cancel_zoomspeed = "Esci senza cambiare la velocità di zoom",
  cancel_shift_scrollspeed = "Esci senza cambiare la velocità di scorrimento con Maiusc.",
  check_for_updates = "Imposta se il gioco deve cercare aggiornamenti all'avvio.",
}
tooltip.graphics_window = {
  fullscreen = "Decidi se il gioco verrà eseguito a schermo intero o in finestra",
  fullscreen_button = "Clicca per attivare o disattivare la modalità a schermo intero",
  width = "Inserisci la larghezza dello schermo desiderata",
  height = "Inserisci l'altezza dello schermo desiderata",
  apply = "Applica la risoluzione inserita",
  cancel = "Esci senza cambiare la risoluzione",
}

accessibility_window = {
  scrollspeed = "Vel. scorrimento",
  shift_scrollspeed = "Vel. scorrimento veloce",
  zoom_speed = "Velocità zoom",
}

tooltip.accessibility_window = {
  scrollspeed = "Imposta la velocità di scorrimento con il mouse tra 1 (più bassa) e 10 (più veloce). Il default è 2.",
  shift_scrollspeed = "Imposta la velocità di scorrimento con il tasto MAIUSC premuto tra 1 (più bassa) e 10 (più veloce). Il default è 4.",
  scrollspeed = "Imposta la velocità di scorrimento tra 1 (minimo) e 10 (massimo). Il valore predefinito è 2.",
  shift_scrollspeed = "Imposta la velocità di scorrimento mentre si tiene premuto il tasto Maiusc. Da 1 (minimo) a 10 (massimo). Il valore predefinito è 4.",
  apply_shift_scrollspeed = "Applica la velocità di scorrimento dello spostamento selezionata.",
  cancel_scrollspeed = "Esci senza cambiare la velocità di scorrimento.",
  zoom_speed = "Imposta la velocità di zoom della telecamera da 10 (minimo) a 1000 (massimo). Il valore predefinito è 80.",
  cancel_zoomspeed = "Esci senza cambiare la velocità di zoom",
  cancel_shift_scrollspeed = "Esci senza cambiare la velocità di scorrimento con Maiusc.",
  apply_zoomspeed = "Applica la velocità di zoom selezionata.",
  apply_scrollspeed = "Applica la velocità di scorrimento selezionata.",
}

audio_window = {
  audio = "Audio globale",
  jukebox = "Jukebox",
  back = "Indietro",
}

tooltip.audio_window = {
  audio_button = "Attiva o disattiva tutti i suoni del gioco",
  audio_toggle = "Attiva o Disattiva Audio",
  jukebox = "Apri il Jukebox per controllare la musica",
}

customise_window = {
  caption = "Impostazioni personalizzate",
  option_on = "On",
  option_off = "Off",
  back = "Indietro",
  movies = "Controllo filmati globale",
  play_intro = "Riproduci filmato introduttivo",
  allow_user_actions_while_paused = "Costruzione durante la pausa",
  volume = "Scorciatoia volume basso",
  alien_dna_only_by_emergency = "Pazienti alieni",
  disable_fractured_bones_females = "Ossa rotte",
  enable_avg_contents = "Oggetti frequenti",
  remove_destroyed_rooms = "Rimuovi stanze distrutte",
}

tooltip.customise_window = {
  movies = "Controllo filmati globale, questo ti permette di disattivare tutti i filmati",
  play_intro = "Disattiva o attiva la riproduzione del filmato introduttivo. I filmati globali devono essere attivati se vuoi che il filmato introduttivo venga riprodotto ogni volta che avvii CorsixTH",
  allow_user_actions_while_paused = "In Theme Hospital al giocatore è consentito utilizzare il menu in alto solo se il gioco è in pausa. Questa è l'impostazione predefinita anche in CorsixTH, ma attivandola tutto è consentito mentre il gioco è in pausa",
  volume = "Se il pulsante per abbassare il volume ti fa aprire anche il Registro Cure, attiva questa opzione per impostare Shift + C come scorciatoia per il Registro Cure",
  alien_dna_only_by_emergency = "A causa dell'assenza delle giuste animazioni abbiamo fatto sì che i pazienti con DNA Alieno possano arrivare solo con un'emergenza. Per permettere ai pazienti con DNA Alieno di visitare il tuo ospedale anche al di fuori delle emergenze disattiva questa opzione",
  disable_fractured_bones_females = "A causa della scarsa qualità di alcune animazioni abbiamo fatto sì che non ci siano pazienti donne con Ossa Rotte. Per far sì che donne con Ossa Rotte visitino il tuo ospedale, disattiva questa opzione",
  enable_avg_contents = "Se vuoi che il gioco ricordi quali oggetti extra aggiungi di solito quando crei una stanza attiva questa opzione",
  back = "Chiudi questo menù e torna al menù delle impostazioni",
  remove_destroyed_rooms = "Se desideri poter rimuovere le stanze distrutte a pagamento, attiva questa opzione",
}

folders_window = {
  caption = "Posizione cartelle",
  data_label = "Posizione TH",
  font_label = "Font",
  music_label = "Musica",
  savegames_label = "Salvataggi",
  screenshots_label = "Screenshot",
  -- next four are the captions for the browser window, which are called from the folder setting menu
  new_th_location = "Qui puoi specificare una nuova directory di installazione di Theme Hospital o un file ISO. Non appena scegli la nuova directory, il gioco verrà riavviato. Tieni presente che le estensioni dei file non sono attualmente visualizzate.",
  savegames_location = "Seleziona la cartella che vuoi usare per i salvataggi",
  music_location = "Seleziona la cartella che vuoi usare per la tua musica",
  screenshots_location = "Seleziona la cartella che vuoi usare per i tuoi screenshot",
  back  = "Indietro",
}

tooltip.folders_window = {
  browse = "Sfoglia le cartelle",
  data_location = "La cartella dell'installazione originale di Theme Hospital, che è richiesto per eseguire CorsixTH",
  font_location = "Posizione di un font che è in grado di mostrare i caratteri Unicode richiesti dalla tua lingua. Se non specificata, non potrai scegliere lingue che hanno bisogno di più caratteri rispetto a quelli di cui dispone il gioco originale. Esempio: Russo e Cinese",
  savegames_location = "Per impostazione predefinita, la cartella dei salvataggi si trova accanto al file di configurazione e verrà utilizzata per archiviare i giochi salvati. In alternativa, puoi usarne un'altra selezionando quella che desideri utilizzare.",
  screenshots_location = "Per impostazione predefinita, la cartella dei salvataggi si trova accanto al file di configurazione. In alternativa, puoi usarne un'altra selezionando quella che desideri utilizzare.",
  music_location = "Seleziona la posizione per i tuoi file MP3. Devi aver già creato la cartella e poi selezionare la cartella che hai creato.",
  browse_data = "Sfoglia per selezionare un percorso diverso per l'installazione di Theme Hospital ( Percorso attuale: %1% )",
  browse_font = "Sfoglia per selezionare un altro file font ( posizione attuale: %1% )",
  browse_saves = "Sfoglia per selezionare un percorso diverso per la tua cartella dei salvataggi ( Percorso attuale: %1% ) ",
  browse_screenshots = "Sfoglia per selezionare percorso diverso per la tua cartella degli screenshot ( Percorso attuale: %1% ) ",
  browse_music = "Sfoglia per selezionare un percorso diverso per la tua cartella della musica ( Percorso attuale: %1% ) ",
  no_font_specified = "Non è stata ancora specificata nessuna posizione per il font!",
  not_specified = "Non è stato ancora specificato nessun percorso per la cartella!",
  default = "Posizione di default",
  reset_to_default = "Ripristina la cartella al suo percorso originario ( %1% )",
  back  = "Chiudi questo menù e torna al menù delle impostazioni",
}

hotkey_window = {
  button_accept = "Accetta",
  button_back = "Indietro",
  button_cancel = "Cancella",
  button_defaults = "Ripristina impostazioni predefinite",
  button_gameSpeedKeys = "Tasti Velocità Gioco",
  button_recallPosKeys = "Richiama tasti Posizione",
  button_toggleKeys = "Attiva/Disattiva Tasti",
  caption_main = "Assegnazione Scorciatoie",
  caption_panels = "Tasti Pannello",
  global_cancel = "Cancella",
  global_cancel_alt = "Cancel Alt",
  global_confirm = "Conferma",
  global_confirm_alt = "Conferma Alt",
  global_connectDebugger = "Debugger",
  global_exitApp = "Esci da App",
  global_fullscreen_toggle = "Schermo Intero",
  global_releaseMouse = "Rilascia Puntatore",
  global_resetApp = "Reset App",
  global_runDebugScript = "Script per Debug",
  global_screenshot = "Screenshot",
  global_showLuaConsole = "Console Lua",
  global_stop_movie_alt = "Ferma Video",
  global_window_close_alt = "Chiudi Finestra",
  ingame_gamespeed_max = "Max",
  ingame_gamespeed_normal = "Normale",
  ingame_gamespeed_slower = "Rallenta",
  ingame_gamespeed_slowest = "Lentissimo",
  ingame_gamespeed_speedup = "Accellera",
  ingame_gamespeed_thensome = "E ancora",
  ingame_jukebox = "Jukebox",
  ingame_loadMenu = "Carica Gioco",
  ingame_openFirstMessage = "Messaggio Livello",
  ingame_panel_bankManager = "Azioni Banca",
  ingame_panel_bankStats = "Saldo in Banca",
  ingame_panel_buildRoom = "Costruisci Stanza",
  ingame_panel_casebook = "Diario clinico",
  ingame_panel_casebook_alt = "Diario clinico 2",
  ingame_panel_casebook_alt02 = "Diario clinico 3",
  ingame_panel_charts = "Grafici",
  ingame_panel_editRoom = "Modifica Stanza",
  ingame_panel_furnishCorridor = "Arreda Corridoio",
  ingame_panel_hireStaff = "Assumi Personale",
  ingame_panel_map_alt = "Mappa Città 2",
  ingame_panel_policy = "Policy",
  ingame_panel_research = "Ricerca",
  ingame_panel_research_alt = "Ricerca 2",
  ingame_panel_staffManage = "Gestisci il Personale",
  ingame_panel_status = "Status",
  ingame_panel_townMap = "Mappa Città",
  ingame_patient_gohome = "Manda a Casa",
  ingame_pause = "Pausa",
  ingame_poopLog = "Visualizza Log",
  ingame_poopStrings = "Visualizza Stringhe",
  ingame_quickLoad = "Carica Salvataggio Veloce",
  ingame_quickSave = "Salvataggio Veloce",
  ingame_quitLevel = "Esci dal Livello",
  ingame_recallPosition_0 = "10",
  ingame_recallPosition_1 = "1",
  ingame_recallPosition_2 = "2",
  ingame_recallPosition_3 = "3",
  ingame_recallPosition_4 = "4",
  ingame_recallPosition_5 = "5",
  ingame_recallPosition_6 = "6",
  ingame_recallPosition_7 = "7",
  ingame_recallPosition_8 = "8",
  ingame_recallPosition_9 = "9",
  ingame_reset_zoom = "Reimposta Zoom",
  ingame_restartLevel = "Riavvia Livello",
  ingame_rotateobject = "Ruota Oggetto",
  ingame_saveMenu = "Salva Gioco",
  ingame_scroll_down = "Scorri in Basso",
  ingame_scroll_left = "Scorri a Sinistra",
  ingame_scroll_right = "Scorri a Destra",
  ingame_scroll_shift = "Velocità Maiusc",
  ingame_scroll_up = "Scorri in Alto",
  ingame_setTransparent = "Trasparente",
  ingame_showCheatWindow = "Menu Cheat",
  ingame_showmenubar = "Mostra barra dei Menu",
  ingame_storePosition_0 = "10",
  ingame_storePosition_1 = "1",
  ingame_storePosition_2 = "2",
  ingame_storePosition_3 = "3",
  ingame_storePosition_4 = "4",
  ingame_storePosition_5 = "5",
  ingame_storePosition_6 = "6",
  ingame_storePosition_7 = "7",
  ingame_storePosition_8 = "8",
  ingame_storePosition_9 = "9",
  ingame_toggleAdvisor = "Consulente",
  ingame_toggleAnnouncements = "Annunci",
  ingame_toggleInfo = "Info",
  ingame_toggleMusic = "Musica",
  ingame_toggleSounds = "Suoni",
  ingame_zoom_in = "Zoom",
  ingame_zoom_in_more = "Ingrandisci",
  ingame_zoom_out = "Rimpicciolisci",
  ingame_zoom_out_more = "Rimpicciolisci",
  panel_altPanelKeys = "Tasti Pannello Alternativi",
  panel_debugKeys = "Tasti Debug",
  panel_gameSpeedKeys = "Tasti Velocità Gioco",
  panel_generalInGameKeys = "Tasti Generali di Gioco",
  panel_globalKeys = "Tasti Generali",
  panel_recallPosKeys = "Richiama Tasti di Posizione",
  panel_scrollKeys = "Tasti Scorrimento",
  panel_storePosKeys = "Salvare Tasti di Posizione",
  panel_toggleKeys = "Attiva/Disattiva Tasti",
  panel_zoomKeys = "Tasti Zoom",
}

font_location_window = {
  caption = "Scegli il font (%1%)",
}

handyman_window = {
  all_parcels = "Tutti i lotti",
  parcel = "Lotto"
}

tooltip.handyman_window = {
  parcel_select = "Il lotto dove l'inserviente può operare, clicca per cambiarlo"
}

new_game_window = {
  caption = "Campagna",
  player_name = "Nome del giocatore",
  option_on = "On",
  option_off = "Off",
  difficulty = "Difficoltà",
  easy = "Assistente (Facile)",
  medium = "Dottore (Medio)",
  hard = "Consulente (Difficile)",
  tutorial = "Tutorial",
  start = "Comincia",
  cancel = "Annulla",
}

tooltip.new_game_window = {
  player_name = "Inserisci il nome col quale vuoi essere chiamato nel gioco",
  difficulty = "Seleziona il livello di difficoltà a cui vuoi giocare",
  easy = "Se non sei pratico di simulatori questa è l'opzione per te",
  medium = "Questa è la via di mezzo se non sei sicuro su cosa scegliere",
  hard = "Se sei abituato a questo tipo di giochi e vuoi una sfida più impegnativa, scegli questa opzione",
  tutorial = "Se vuoi aiuto per cominciare mentre sei in gioco, spunta questa casella",
  start = "Avvia il gioco con le impostazioni scelte",
  cancel = "Oh, non volevo davvero cominciare una nuova partita!",
}

lua_console = {
  execute_code = "Esegui",
  close = "Chiudi",
}

tooltip.lua_console = {
  textbox = "Inserisci qui il codice Lua da eseguire",
  execute_code = "Esegui il codice che hai inserito",
  close = "Chiudi la console",
}

tooltip.toolbar = {
  status = "Riepilogo (%s)",
  casebook = "Registro cure (%s)",
  objects = "Sistemazione oggetti di corridoio (%s)",
  edit = "Modifica stanze/oggetti (%s)",
  reputation = "La tua reputazione",
  research = "Ricerca (%s)",
  date = "La data",
  bank_button = "Tasto Sinistro (%s) per la Gestione Bancaria, Tasto Destro (%s) per il Rendiconto",
  balance = "Il tuo bilancio ",
  machine_menu = "Machine menu (%s)",
  town_map = "Pianta della città (%s)",
  charts = "Grafici (%s)",
  hire = "Assunzione personale (%s)",
  policy = "Gestione (%s)",
  staff_list = "Personale (%s)",
  rooms = "Costruzione stanze (%s)",
}

errors = {
  dialog_missing_graphics = "I file dei dati della demo non contengono questa stringa.",
  save_prefix = "Errore durante il salvataggio: ",
  load_prefix = "Errore durante il caricamento: ",
  no_games_to_contine = "Non ci sono partite salvate.",
  load_quick_save = "Errore, non è possibile caricare il salvataggio veloce perché non esiste, ma non preoccuparti: ne abbiamo appena creato uno al posto tuo!",
  map_file_missing = "Non ho potuto trovare la mappa %s per questo livello!",
  minimum_screen_size = "Per favore inserisci almeno una risoluzione di %dx%d.",
  unavailable_screen_size = "La risoluzione che hai richiesto non è disponibile a schermo intero.",
  alien_dna_only_by_emergency = "NOTA: Non ci sono animazioni per i pazienti Alieni per quando si siedono, aprono o bussano sulle porte etc. Quindi, così come in Theme Hospital, mentre fanno queste cose appariranno normali per poi tornare ad apparire alieni. I pazienti con DNA Alieno appariranno solo se impostati dal file del livello",
  disable_fractured_bones_females = "NOTA: L'animazione per i pazienti donne con Ossa Rotte non è perfetta",
  could_not_load_campaign = "Errore nel caricare la campagna: %s",
  could_not_find_first_campaign_level = "Non è stato possibile trovare il primo livello di questa campagna: %s",
  load_map_prefix = "Errore nel caricamento della Mappa: ",
  save_to_tmp = "Il file al percorso %s non può essere usato. Il gioco è stato salvato qui %s. Errore: %s",
  load_level_prefix = "Errore durante il caricamento del livello: ",
  compatibility_error = {
    new_in_old = "Mi dispiace, ma questo salvataggio è stato creato con una versione più recente di CorsixTH e non è compatibile. Per favore, aggiorna a una versione più recente.",
    full_in_demo = "Mi dispicae, non puoi aprire un salvataggio completo del gioco con i file demo caricati. Aggiorna il percorso della cartella Dati di TH.",
    demo_in_full = "Spiacenti, non puoi aprire un salvataggio demo con i file di gioco completi caricati. Aggiorna il percorso della cartella Dati di TH.",
  },
  dialog_empty_queue = "Mi dispiace, un umanoide aveva una coda di azioni vuota, il che significa che non sapeva cosa doveva fare. Consultare la finestra di comando per informazioni più dettagliate. È stato aperto un dialogo con l'umanoide incriminato. Vorresti che lasciasse l'ospedale?",
}

warnings = {
  levelfile_variable_is_deprecated = "Attenzione: Il livello %s contiene una definizione di variabile deprecata nel file di livello." ..
                                     "'%LevelFile' è stato rinominato in '%MapFile'. Per favore richiedi al creatore della mappa di aggiornare il livello.",
  newersave = "Attenzione, hai caricato un salvataggio da una versione più recente di CorsixTH. Non è consigliabile continuare poiché potrebbero verificarsi arresti anomali. Gioca a tuo rischio.",
}

confirmation = {
  needs_restart = "Cambiare questa impostazione richiede che CorsixTH sia riavviato. Ogni progresso non salvato sarà perduto. Sei sicuro di volerlo fare?",
  abort_edit_room = "Stai attualmente costruendo o modificando una stanza. Se tutti gli oggetti richiesti sono stati posizionati sarà completata, altrimenti sarà cancellata. Continuare?",
  maximum_screen_size = "La risoluzione che hai inserito è superiore a 3000x2000. Risoluzioni maggiori sono supportate, ma richiederanno un hardware migliore per mantenere un livello di frame rate giocabile. Sei sicuro di voler continuare?",
  music_warning = "Nota: è necessario avere la libreria smpeg.dll o equivalente nel tuo sistema operativo, altrimenti non sentirai alcuna musica nel gioco. Vuoi continuare?",
 --This next line isn't in the english.lua, but when strings are dump it is reported missing
  restart_level = "Sei sicuro di voler riavviare il livello?",
  remove_destroyed_room = "Vuoi rimuovere la stanza per $X?",
}

information = {
  custom_game = "Benvenuto in CorsixTH. Divertiti con questa mappa personalizzata!",
  no_custom_game_in_demo = "Spiacente, ma nella versione demo non puoi giocare mappe personalizzate.",
  cannot_restart = "Sfortunatamente questa mappa personalizzata è stata salvata prima che venisse implementata la funzione per riavviare.",
  very_old_save = "Il gioco è stato molto aggiornato da quando hai avviato questo livello. Per assicurarti che tutto funzioni a dovere, considera l'idea di riavviarlo.",
  level_lost = {
    "Peccato! Hai perso il livello. Avrai più fortuna la prossima volta!",
    "Hai perso perchè:",
    reputation = "Hai ucciso più del %d percento dei pazienti.",
    balance = "Il tuo conto in banca è sceso sotto %d.",
    percentage_killed = "Hai ucciso più del %d dei pazienti.",
    cheat = "È stata una tua scelta o hai selezionato il pulsante sbagliato? Non riesci nemmeno a barare correttamente. Divertente, vero?",
  },
  cheat_not_possible = "Non puoi usare questo cheat in questo livello. Non riesci nemmeno a barare correttamente. Divertente, vero?",
}

tooltip.information = {
  close = "Chiudi la finestra delle informazioni",
}

totd_window = {
  tips = {
    "Ogni ospedale per funzionare ha bisogno di alcune strutture di base. Inizia con una reception e un ambulatorio, e il personale necessario. Una volta iniziato, dipenderà tutto dal tipo di pazienti che visiteranno il tuo ospedale. Qualche stanza per le diagnosi e una farmacia sono una buona scelta per iniziare.",
    "I macchinari come la Pompa hanno bisogno di manutenzione più o meno costante. Assumi qualche tuttofare per ripararle, o rischierai che i pazienti e il tuo staff si facciano male.",
    "Il tuo staff lavora duramente, e ogni tanto ha bisogno di riposare. Costruisci una sala del personale per loro.",
    "Ricordati di fornire il tuo ospedale di un impianto di riscaldamento funzionante, o lo staff ed i pazienti rimarranno infelici e infreddoliti.",
    "Il livello di competenza influenza in maniera enorme la qualità e la velocità delle diagnosi. Assegnando un dottore molto abile al tuo ambulatorio non avrai bisogno di costruire molte strutture di diagnosi addizionali.",
    "Assistenti e dottori possono aumentare il loro livello di competenza imparando da un consulente nella sala tirocinio. Se il consulente è anche uno specialista (chirurgo, psichiatra e/o ricercatore), passerà le sue conoscente ai suoi studenti.",
    "Hai provato a digitare il numero di emergenza europea (112) nel fax? Assicurati di avere l'audio attivato!",
    "Il menu d'opzioni non è ancora implementato, ma puoi regolare le impostazioni modificando il file config.txt nella directory di gioco.",
    "Hai selezionato la tua lingua, ma è tutto in Inglese? Aiutaci a tradurre il gioco!",
    "Il team di CorsixTH sta cercando rinforzi!  Ti piacerebbe programmare, tradurre o creare nuovi elementi grafici per CorsixTH? Contattaci nei forum, tramite mail o sul canale IRC (corsix-th su freenode).",
    "Hai trovato un bug? Vuoi segnalare un errore di qualsiasi genere? Invia una segnalazione al nostro bug tracker: th-issues.corsix.org",
    "Ogni livello ha degli obiettivi da raggiungere prima di poter passare al successivo. Controlla la finestra di riepilogo per vedere a che punto sei.",
    "Se vuoi modificare o rimuovere una stanza esistente, puoi farlo con il tasto modifica stanza nella barra degli strumenti in basso.",
    "In un'orda di pazienti in attesa, puoi vedere velocemente chi sta aspettando il proprio turno per una stanza particolare spostando il mouse sulla stanza.",
    "Clicca sulla porta di una stanza per vederne la coda. Puoi fare diverse cose utili, come riordinare la coda o mandare il paziente in un'altra stanza.",
    "Se il personale è infelice chiederà spesso aumenti di salario. Assicurati che il tuo staff stia lavorando in un'ambiente di lavoro confortevole per evitare che accada.",
    "I pazienti avranno sete durante le attese, soprattutto se alzi il riscaldamento! Piazza i distributori di bevande in posizioni strategiche per un po' di guadagni extra. ",
    "Puoi cancellare prematuramente il processo di diagnosi per un paziente e deciderne la cura se hai già incontrato la malattia. Fai attenzione però, dato che fare ciò può incrementare il rischio di una cura sbagliata, risultando nella morte del paziente.",
    "Le emergenze possono essere una buona fonte di guadagno extra, sempre che tu abbia i mezzi sufficienti a gestire l'emergenza in tempo.",
    "Sapevi che puoi assegnare i Tuttofare ad aree specifiche? Basta fare clic sul testo Tutte le aree nel profilo dello staff per scorrerle!",
  },
  previous = "Suggerimento precedente",
  next = "Suggerimento successivo",
}

tooltip.totd_window = {
  previous = "Passa al suggerimento precedente",
  next = "Passa al suggerimento successivo",
}

debug_patient_window = {
  caption = "Debug paziente",
}

tooltip.debug_patient_window = {
  item = "Crea un paziente debug con %s",
}

cheats_window = {
  caption = "Cheat",
  warning = "Attenzione: non riceverai alcun punto bonus alla fine del livello se usi i trucchi!",
  cheated = {
    no = "Cheat usati: No",
    yes = "Cheat usati: Sì",
  },
  cheats = {
    money = "Cheat soldi",
    all_research = "Completa ricerche",
    emergency = "Crea emergenza",
    vip = "Crea VIP",
    earthquake = "Crea terremoto",
    epidemic = "Genera paziente contagioso",
    toggle_infected = "Attiva o disattiva icone infetti",
    create_patient = "Crea paziente",
    end_month = "Fine mese",
    end_year = "Fine anno",
    lose_level = "Perdi livello",
    win_level = "Vinci livello",
    increase_prices = "Aumenta prezzi",
    decrease_prices = "Diminuisci prezzi",
    toggle_earthquake = "Attiva/Disattiva terremoti",
    reset_death_count = "Azzera il conto dei decessi",
    max_reputation = "Reputazione Massima",
    toggle_epidemic = "Attiva/Disattiva epidemie",
    show_infected = "Mostra/Nascondi icone infezione",
  },
  close = "Chiudi",
}

tooltip.cheats_window = {
  close = "Chiudi il menu dei trucchi",
  cheats = {
    money = "Aggiunge 10.000 al tuo conto in banca.",
    all_research = "Completa tutte le ricerche.",
    emergency = "Crea un'emergenza.",
    vip = "Crea un VIP.",
    earthquake = "Crea un terremoto.",
    epidemic = "Crea un paziente contagioso che potrebbe causare un'epidemia",
    toggle_infected = "Attiva o disattiva le icone infetti per le epidemie attive scoperte",
    create_patient = "Crea un paziente sul bordo della mappa.",
    end_month = "Salta alla fine del mese.",
    end_year = "Salta alla fine dell'anno.",
    lose_level = "Perdi il livello corrente.",
    win_level = "Vinci il livello corrente.",
    increase_prices = "Aumenta tutti i prezzi del 50% (max 200%)",
    decrease_prices = "Diminuisci tutti i prezzi del 50% (min 50%)",
    toggle_earthquake = "Attiva/Disattiva terremoti",
    reset_death_count = "Azzerare il conteggio dei decessi in ospedale",
    max_reputation = "Imposta la reputazione dell'ospedale al massimo",
    toggle_epidemic = "Attiva/Disattiva la possibilità di epidemie",
    show_infected = "Mostra/nascondi le icone infezione per l'epidemia attiva e scoperta",
  }
}

introduction_texts = {
  demo =
    "Benvenuto nell'ospedale demo!//" ..
    "Sfortunatamente la versione demo contiene solo questo livello. Ad ogni modo c'è abbastanza da fare per tenerti occupato per un bel po'! " ..
    "Incontrerai diverse malattie che richiederanno diverse cliniche per essere curate. Ogni tanto potrebbero presentarsi delle emergenze. " ..
    "E avrai bisogno di ricercare nuove strumentazioni tramite il centro ricerche. " ..
    "Il tuo obiettivo è di guadagnare $100,000, avere un ospedale che valga $70,000 e una reputazione di 700, oltre che curare almeno il 75% dei tuoi pazienti. " ..
    "Assicurati che la tua reputazione non scenda al di sotto di 300 e di non uccidere più del 40% dei tuoi pazienti, o perderai.//" ..
    "Buona fortuna!",
}

calls_dispatcher = {
  -- Dispatcher description message. Visible in Calls Dispatcher dialog
  summary = "%d chiamate; %d assegnate",
  staff = "%s - %s",
  watering = "Annaffiare @ %d,%d",
  repair = "Riparazione %s",
  close = "Chiudi",
}

tooltip.calls_dispatcher = {
  task = "Lista dei compiti - clicca il compito per aprire la finestra del membro del personale assegnato e scorrere alla posizione del compito",
  assigned = "Questo box è segnato se qualcuno è assegnato al compito corrispondente.",
  close = "Chiude la finestra del gestore chiamate",
}

update_window = {
  caption = "Aggiornamento disponibile!",
  new_version = "Nuova versione:",
  current_version = "Versione attuale:",
  download = "Vai alla pagina del download",
  ignore = "Salta e vai al menù principale",
}

tooltip.update_window = {
  download = "Vai alla pagina di download per trovare l'ultima versione di CorsixTH",
  ignore = "Ignora l'aggiornamento per ora. Questa notifica apparirà di nuovo al prossimo avvio di CorsixTH",
}

map_editor_window = {
  pages = {
    inside = "Interno",
    outside = "Esterno",
    foliage = "Fogliame",
    hedgerow = "Siepe",
    pond = "Laghetto",
    road = "Strada",
    north_wall = "Muro nord",
    west_wall = "Muro ovest",
    helipad = "Eliporto",
    delete_wall = "Cancella muri",
    parcel = "Pacco %d",
    set_parcel = "Imposta num pacco",
    set_parcel_tooltip = "Scegli un numero e premi Invio.",
    camera_1 = "Telecamera 1",
    camera_2 = "Telecamera 2",
    camera_3 = "Telecamera 3",
    camera_4 = "Telecamera 4",
    heliport_1 = "Eliporto 1",
    heliport_2 = "Eliporto 2",
    heliport_3 = "Eliporto 3",
    heliport_4 = "Eliporto 4",
    paste = "Incolla area",
  },
  checks = {
    spawn_points_and_path = "Avvertenza: i pazienti non possono raggiungere l'ospedale. Hanno bisogno di caselle 'strada' o caselle grigie 'esterne' sul bordo della mappa e di un percorso fino all'ingresso dell'ospedale.",
  },
}

tooltip = {
  hotkey_window = {
    button_accept = "Accetta e salva i tasti scorciatoia",
    button_cancel = "Cancella l'assegnazione e torna al menu opzioni",
    button_recallPosKeys = "Apri una finestra per impostare scorciatoie per salvare e richiamare posizioni della telecamera",
    caption_panels = "Open window to assign panel keys",
    button_back_02 = "Torna alla finestra principale delle scorciatoie. Cio' che hai cambiato in questa finestra può essere salvato li'",
    button_defaults = "Ripristina tutte le scorciatoie alle impostazioni predefinite del programma",
    button_gameSpeedKeys = "Apri la finestra per impostare i tasti che controllano la velocità del gioco",
  }
}

level_progress = {
  cured_enough_patients = "Hai curato abbastanza pazienti, ma devi migliorare ancora il tuo ospedale per vincere il livello.",
  hospital_value_enough = "Mantieni il valore del tuo ospedale al di sopra di %d e occupati dei tuoi altri problemi per vincere il livello.",
}

disease_discovered_patient_choice.need_to_employ = "Assumi un %s per poter gestire questa sitazione."

transactions.remove_room = "Costruzione: rimuovi stanza distrutta"

multiplayer.everyone_failed = "Nessuno è riuscito ad arrivare a duell'ultimo obiettivo. Quindi tutti possono continuare a giocare!"
multiplayer.players_failed = "I seguenti giocatori non sono riusciti a raggiungere l'ultimo obiettivo:"


--------------------------------  UNUSED  -----------------------------------
------------------- (kept for backwards compatibility) ----------------------

-- I added those lines because I didn't like 'em to show up in every diff dump!
original_credits[302] = ","
original_credits[303] = "Steve Fitton"
original_credits[304] = " "
original_credits[305] = " "
original_credits[306] = " "
original_credits[307] = ":Company Administration"
original_credits[308] = ","
original_credits[309] = "Audrey Adams"
original_credits[310] = "Annette Dabb"
original_credits[311] = "Emma Gibbs"
original_credits[312] = "Lucia Gobbo"
original_credits[313] = "Jo Goodwin"
original_credits[314] = "Sian Jones"
original_credits[315] = "Kathy McEntee"
original_credits[316] = "Louise Ratcliffe"
original_credits[317] = " "
original_credits[318] = " "
original_credits[319] = " "
original_credits[320] = ":Company Management"
original_credits[321] = ","
original_credits[322] = "Les Edgar"
original_credits[323] = "Peter Molyneux"
original_credits[324] = "David Byrne"
original_credits[325] = " "
original_credits[326] = " "
original_credits[327] = ":Tutti alla Bullfrog Productions"
original_credits[328] = " "
original_credits[329] = " "
original_credits[330] = " "
original_credits[331] = ":Un Ringraziamento Speciale A"
original_credits[332] = ","
original_credits[333] = "Tutti al Frimley Park Hospital"
original_credits[334] = " "
original_credits[335] = ":Specialmente"
original_credits[336] = ","
original_credits[337] = "Beverley Cannell"
original_credits[338] = "Doug Carlisle"
original_credits[339] = " "
original_credits[340] = " "
original_credits[341] = " "
original_credits[342] = ":Keep On Thinking"
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
original_credits[361] = "."

-------------------------------------------------------------------------------
--   Multiplayer (network play): the room, game options, auctions, bots and the rest
--   of the multiplayer windows. Translated from english.lua; the keys
--   missing here show in English.
-------------------------------------------------------------------------------
hotkey_window.ingame_mp_chat = "Chat multigiocatore"
hotkey_window.ingame_mp_next_hospital = "Ospedale successivo (MG)"
main_menu.multiplayer = "Multigiocatore"
map_editor_window.pages.camera_n = "Telecamera %d"
map_editor_window.pages.heliport_n = "Eliporto %d"
map_editor_window.pages.player = "Giocatore %d"
menu.map_size = "DIMENSIONE MAPPA"
menu_map_size.size = "  NUOVA MAPPA %d x %d  "
menu_player_count.players_5 = "  5 GIOCATORI  "
menu_player_count.players_6 = "  6 GIOCATORI  "
menu_player_count.players_7 = "  7 GIOCATORI  "
menu_player_count.players_8 = "  8 GIOCATORI  "
multiplayer_window.add_bot = "in attesa di un giocatore... (clic: aggiungi un bot)"
multiplayer_window.ask_amount = "Importo: $%d"
multiplayer_window.ask_asked = "Richiesta inviata. In attesa della risposta."
multiplayer_window.ask_balance_line = "Il suo saldo: $%d."
multiplayer_window.ask_button = "Chiedi"
multiplayer_window.ask_caption = "Chiedi soldi a %s"
multiplayer_window.ask_decline = "Rifiuta"
multiplayer_window.ask_declined_note = "%s ha rifiutato di mandarti $%d."
multiplayer_window.ask_line = "%s ti chiede $%d."
multiplayer_window.ask_money = "Chiedi a un giocatore"
multiplayer_window.ask_no_money_asker_note = "%s non ha potuto pagarti."
multiplayer_window.ask_no_money_note = "Non puoi pagare $%d."
multiplayer_window.ask_pay = "Paga $%d"
multiplayer_window.ask_sent_note = "Hai chiesto $%d a %s. In attesa della risposta."
multiplayer_window.auction_back = "Torna all'asta"
multiplayer_window.auction_bid = "Offri $%d"
multiplayer_window.auction_borrow_tooltip = "Prendi in prestito $5,000 dalla banca"
multiplayer_window.auction_close = "Chiudi"
multiplayer_window.auction_dropped = "Ti sei ritirato."
multiplayer_window.auction_going_once = "Uno..."
multiplayer_window.auction_going_twice = "Due..."
multiplayer_window.auction_leader = "Offerta più alta: $%d, %s"
multiplayer_window.auction_leading = "Sei in testa. Aspetta gli altri."
multiplayer_window.auction_loan = "$%d, prestito $%d"
multiplayer_window.auction_loan_tooltip = "Il tuo saldo e il tuo prestito in banca"
multiplayer_window.auction_no_money = "Non puoi permetterti la prossima offerta."
multiplayer_window.auction_no_money_loan = "Non puoi permetterti la prossima offerta: chiedi un prestito con + qui sotto."
multiplayer_window.auction_not_sold = "Il lotto %d non è stato venduto."
multiplayer_window.auction_out = "fuori"
multiplayer_window.auction_pass = "Ritirati"
multiplayer_window.auction_paused = "Il gioco resta fermo durante l'asta."
multiplayer_window.auction_price = "Prezzo $%d, ogni offerta $%d in più"
multiplayer_window.auction_repay_tooltip = "Restituisci $5,000 del prestito"
multiplayer_window.auction_sold = "Lotto %d venduto a %s per $%d."
multiplayer_window.auction_started = "%s vuole il lotto %d. Anche altri giocatori potrebbero volerlo: va all'asta."
multiplayer_window.auction_title = "Asta di terreni: lotto %d"
multiplayer_window.auction_wait = "Asta in corso, attendi..."
multiplayer_window.auction_watching = "Il tuo terreno non confina con questo lotto."
multiplayer_window.auctions_all = "Tutti"
multiplayer_window.auctions_caption = "Aste di terreni"
multiplayer_window.auctions_near = "Contesi"
multiplayer_window.auctions_none = "No"
multiplayer_window.back = "Indietro"
multiplayer_window.back_to_lobby = "Torna alla lobby"
multiplayer_window.bot_line = "%s   (bot)%s"
multiplayer_window.bot_remove = "   clic: rimuovi"
multiplayer_window.bot_starting = "un bot si sta avviando..."
multiplayer_window.caption = "Multigiocatore"
multiplayer_window.cert_changed_help = "Il certificato di %s non è quello che questo gioco ricordava dall'ultima volta. O il server è stato configurato di nuovo, o qualcuno si è messo tra te e il server. Il gioco non si è connesso. Se sai che il server ha un nuovo certificato, cancella la sua riga da %s e connettiti di nuovo."
multiplayer_window.chat_private_in = "%s (a te): %s"
multiplayer_window.chat_private_out = "A %s: %s"
multiplayer_window.chat_team_in = "%s (alla squadra): %s"
multiplayer_window.chat_team_out = "Alla squadra: %s"
multiplayer_window.chat_to = "A %s:"
multiplayer_window.chat_to_all = "A tutti:"
multiplayer_window.chat_to_team = "Alla squadra:"
multiplayer_window.chat_to_allies = "Agli alleati:"
multiplayer_window.chat_allies_in = "%s (agli alleati): %s"
multiplayer_window.chat_allies_out = "Agli alleati: %s"
multiplayer_window.clear_destroyed_room = "Sgomberare la stanza distrutta per $%d? Lo spazio sarà poi libero per altro."
multiplayer_window.colour_names[1] = "Giallo"
multiplayer_window.colour_names[2] = "Rosso"
multiplayer_window.colour_names[3] = "Viola"
multiplayer_window.colour_names[4] = "Bianco"
multiplayer_window.colour_names[5] = "Verde"
multiplayer_window.colour_names[6] = "Blu"
multiplayer_window.colour_names[7] = "Turchese"
multiplayer_window.colour_names[8] = "Nero"
multiplayer_window.connect = "Connetti"
multiplayer_window.connecting = "Connessione a %s..."
multiplayer_window.continue_save = "Continua: %s"
multiplayer_window.continuing = "salvataggio %s"
multiplayer_window.create = "Crea"
multiplayer_window.data_mismatch_help = "I file di Theme Hospital di questo server sono di un'altra edizione del gioco rispetto ai tuoi (i livelli e le mappe multigiocatore sono diversi), e le partite con entrambi non resterebbero uguali. Indica a CorsixTH la stessa edizione del server (Opzioni, Opzioni cartelle, posizione di Theme Hospital), per esempio la versione GOG, e connettiti di nuovo."
multiplayer_window.disconnect = "Disconnetti"
multiplayer_window.download = "Scarica %s da GitHub"
multiplayer_window.emergency_refused = "Rifiutare l'emergenza è costato all'ospedale %d di reputazione."
multiplayer_window.encrypted = "Connessione cifrata (TLS)"
multiplayer_window.every_plot_auctioned = "tutti i lotti all'asta"
multiplayer_window.game_options = "Opzioni di gioco"
multiplayer_window.goal_limit = "limite:"
multiplayer_window.goal_other.balance = "%s: saldo $%d (%s $%d)"
multiplayer_window.goal_other.num_cured = "%s: %d pazienti curati (%s %d)"
multiplayer_window.goal_other.percentage_cured = "%s: %d%% di pazienti curati (%s %d%%)"
multiplayer_window.goal_other.percentage_killed = "%s: %d%% di pazienti morti (%s %d%%)"
multiplayer_window.goal_other.reputation = "%s: reputazione %d (%s %d)"
multiplayer_window.goal_other.value = "%s: valore dell'ospedale $%d (%s $%d)"
multiplayer_window.goal_target = "obiettivo:"
multiplayer_window.goals_done = "raggiunto"
multiplayer_window.goals_failed_other = "%s ha fallito gli obiettivi di questo livello. Aiutalo a riprendersi entro la fine del prossimo anno (soldi o personale), o perde tutta la squadra."
multiplayer_window.goals_failed_team = "Il tuo ospedale ha fallito gli obiettivi di questo livello. Riprenditi entro la fine del prossimo anno, o perde tutta la squadra. Gli altri giocatori possono mandarti soldi o personale."
multiplayer_window.goals_failing = "in difficoltà"
multiplayer_window.goals_open = "-"
multiplayer_window.goals_reached_loan = "Il tuo ospedale rispetta tutti gli obiettivi di questo livello ma deve ancora $%d alla banca. Salda il prestito (clicca sui tuoi soldi in basso) e conteranno come raggiunti."
multiplayer_window.goals_reached_other = "%s ha raggiunto gli obiettivi di questo livello. Manca ancora: %s."
multiplayer_window.goals_reached_team = "Il tuo ospedale ha raggiunto gli obiettivi di questo livello! Manca ancora: %s."
multiplayer_window.goals_recovered = "%s non fallisce più gli obiettivi di questo livello."
multiplayer_window.helpers_off = "I bot alleati costruiscono: no"
multiplayer_window.helpers_on = "I bot alleati costruiscono: sì"
multiplayer_window.hold_left = "Il gioco riprende al massimo tra %s."
multiplayer_window.hold_win = "In attesa che %s risponda al fax..."
multiplayer_window.hold_year = "In attesa che %s chiuda il rapporto annuale..."
multiplayer_window.is_ready = "pronto"
multiplayer_window.join = "Entra"
multiplayer_window.keep_playing = "Continua a giocare"
multiplayer_window.kick_player = "Rimuovi %s dalla stanza"
multiplayer_window.kicked = "%s, il proprietario della stanza, ti ha rimosso dalla stanza."
multiplayer_window.leave = "Esci dalla stanza"
multiplayer_window.level = "Livello %d"
multiplayer_window.level7_breakthrough = "Svolta medica: %s ha scoperto per primo: %s, e guadagna $%d."
multiplayer_window.level7_breakthrough_bonus = "Bonus svolta"
multiplayer_window.level7_job_fair = "La fiera del lavoro è aperta: questo mese ci sono specialisti nella lista di assunzione."
multiplayer_window.level7_job_fair_soon = "Il mese prossimo apre una fiera del lavoro: chirurghi, psichiatri, ricercatori e consulenti saranno nella lista di assunzione. Chi prima arriva, meglio alloggia."
multiplayer_window.level7_quarter = "Classifica del Ministero della Salute: %s ha curato più pazienti questo trimestre (%d) e guadagna reputazione."
multiplayer_window.level7_race_bonus = "Bonus emergenza gara"
multiplayer_window.level7_race_emergency = "Un'emergenza di gara: ora ogni ospedale riceve la stessa emergenza. Il primo a salvare tutti i pazienti guadagna $%d e reputazione."
multiplayer_window.level7_race_won = "%s ha salvato per primo tutti i pazienti dell'emergenza di gara e guadagna $%d."
multiplayer_window.level7_rat_bounty = "Taglia sui ratti"
multiplayer_window.level7_trick_of_month = "Colpo del mese: %s costa metà prezzo fino alla fine del mese."
multiplayer_window.level7_truce_over = "La tregua è finita: da ora si possono comprare i colpi bassi (MULTIGIOCATORE > COLPI BASSI)."
multiplayer_window.level_intro_6 = "Emergenza! Gli ospedali di questa città accolgono ogni emergenza che l'elicottero riesce a portare. Per il primo anno ne arrivano quattro al mese, a turno in ognuno dei tuoi ospedali: casi di gonfiore e psichiatria da febbraio (e alcuni per la farmacia), casi di sala operatoria da maggio, lingua lunga e fratture da giugno. A maggio ogni ospedale riceve pazienti con la lingua lunga, quindi ricerca presto la Clinica della lingua. Rifiutare un'emergenza costa reputazione, ma i pazienti persi a causa loro vengono perdonati più del solito, e puoi mandare i pazienti d'emergenza all'ospedale di un amico che sa curarli. Finché durano le emergenze entrano meno pazienti; dal secondo anno ne arrivano di più, e ogni due o tre mesi le epidemie attraversano tutti gli ospedali. Anche ai ratti qui piace. Assumi consulenti finché puoi: dal nono mese cercano lavoro solo medici junior. Per vincere, ogni ospedale deve avere una reputazione di 550, $60,000 in banca, 150 pazienti curati, un tasso di guarigione del 40 per cento e il valore dell'ospedale indicato nel Rapporto sui progressi."
multiplayer_window.level_intro_7 = "Senza pietà. Ogni ospedale di questa città vuole essere il migliore, e nessuno gioca pulito. C'è una tregua fino a marzo; poi i colpi bassi si aprono mese dopo mese: prima attacchi di ratti, campagne diffamatorie e caldaie rotte, poi tuttofare malvagi, epidemie e spionaggio da giugno, emergenze forzate e cacciatori di teste da settembre, e il livello più forte di ogni colpo dal secondo anno. Ogni mese un colpo si vende a metà prezzo, l'ospedale più indietro paga metà per tutti, e chi è in testa paga una volta e mezza. Da conquistare: le fiere del lavoro di aprile, ottobre, del prossimo aprile e del prossimo ottobre portano chirurghi, psichiatri, ricercatori e consulenti nella lista di assunzione, chi prima arriva meglio alloggia. In agosto, febbraio e nell'agosto dopo, ogni ospedale riceve la stessa emergenza nello stesso momento, e il primo a salvare tutti i pazienti guadagna $10,000 e reputazione. Anche il primo a scoprire i raggi X, lo scanner o la macchina del sangue guadagna $10,000 (i progetti rubati non contano), e ogni trimestre l'ospedale che ha curato più pazienti guadagna reputazione. I ratti mandati da un rivale rendono $100 l'uno quando vengono abbattuti. Qui i macchinari si usurano più in fretta, e quattro terremoti scuoteranno la città, ognuno più forte del precedente. Per vincere, un ospedale deve avere una reputazione di 650, $150,000 in banca, 300 pazienti curati, un tasso di guarigione del 55 per cento e il valore dell'ospedale indicato nel Rapporto sui progressi. Con quattro giocatori la città è la mappa di Matroftt."
multiplayer_window.level_intro_8 = "Team Town, la mappa di Matroftt, è fatta per due contro due: i quattro ospedali stanno a coppie in centro, i compagni di squadra fianco a fianco, con molto terreno in vendita su ogni lato. Metti gli amici nella stessa squadra e sfida l'altra coppia. Per vincere, ogni ospedale deve avere una reputazione di 650, $100,000 in banca, 200 pazienti curati, un tasso di guarigione del 50 per cento e il valore dell'ospedale indicato nel Rapporto sui progressi. Con due o tre giocatori si gioca sulla mappa di un'altra città."
multiplayer_window.level_intro_9 = "Crocevia, la mappa di Matroftt, ha posto per otto: la città è divisa in tre file da tre, con otto ospedali già murati intorno a quattro piccoli lotti in vendita nel mezzo, dove i sentieri si incrociano. I quattro ospedali d'angolo sono un po' più grandi. Con quattro giocatori o meno vengono occupati solo gli angoli e anche gli altri ospedali sono in vendita. I pazienti arrivano da ogni lato della città. Per vincere, ogni ospedale deve avere una reputazione di 650, $150.000 in banca, 300 pazienti curati, un tasso di guarigione del 55 per cento e il valore dell'ospedale indicato nel Rapporto sui progressi."
multiplayer_window.level_rats_notice = "Ratti! Uno sciame è entrato nell'ospedale. Cliccaci sopra per abbatterli prima che si riproducano nella spazzatura."
multiplayer_window.level_slack_tongue_warning = "Arrivano notizie di lingue lunghe in tutta la città. A maggio ogni ospedale riceverà emergenze di lingua lunga: ricerca la Clinica della lingua prima di allora."
multiplayer_window.level_won_end = "Hai vinto il livello. Ben fatto!"
multiplayer_window.levels_caption = "Livelli"
multiplayer_window.levels_choose = "Scegli il livello %d"
multiplayer_window.levels_events = "EVENTI %s"
multiplayer_window.levels_from_campaign = "Stanze, malattie e ricerca come in %s (livello %d della campagna)."
multiplayer_window.levels_goal_balance = "$%s in banca"
multiplayer_window.levels_goal_cure_rate = "Guarigione %d%%"
multiplayer_window.levels_goal_cured = "%d curati"
multiplayer_window.levels_goal_reputation = "Reputazione %d"
multiplayer_window.levels_goal_value = "Valore +$%s"
multiplayer_window.levels_goals = "Per vincere:"
multiplayer_window.levels_legend = "A colori: lotti iniziali. Grigio: in vendita."
multiplayer_window.levels_map_by = "Mappa di %s"
multiplayer_window.levels_map_players = "Mappa per %d giocatori"
multiplayer_window.levels_money = "Soldi: $%s"
multiplayer_window.levels_no_map = "Questa mappa non è nei tuoi dati di Theme Hospital."
multiplayer_window.levels_several = "Più ospedali"
multiplayer_window.levels_shared = "Un ospedale condiviso"
multiplayer_window.levels_shared_note = "Livello %d della campagna: un ospedale che costruiscono tutti insieme, con gli obiettivi della campagna."
multiplayer_window.load_caption = "Carica una partita multigiocatore"
multiplayer_window.load_game = "Carica partita MG"
multiplayer_window.loading = "CARICAMENTO..."
multiplayer_window.locked = "  (password)"
multiplayer_window.looking_at = "Vista su %s"
multiplayer_window.measuring = "Misurazione della connessione..."
multiplayer_window.menu_caption = "  MULTIGIOCATORE  "
multiplayer_window.menu_chat = "  INVIA UN MESSAGGIO (%1%)  "
multiplayer_window.menu_colours = "  COLORI DEI GIOCATORI  "
multiplayer_window.menu_colours_all = "  PERSONE DI TUTTI  "
multiplayer_window.menu_colours_off = "  NO  "
multiplayer_window.menu_bot_chat = "  CHAT DEI BOT  "
multiplayer_window.menu_bot_chat_all = "  TUTTO  "
multiplayer_window.menu_bot_chat_auto = "  SENZA CHIACCHIERE DA 3 BOT IN SU  "
multiplayer_window.menu_bot_chat_useful = "  SENZA CHIACCHIERE  "
multiplayer_window.menu_bot_chat_off = "  NO  "
multiplayer_window.menu_colours_others = "  PERSONE DEGLI ALTRI  "
multiplayer_window.menu_players = "  GIOCATORI  "
multiplayer_window.menu_research = "  CONDIVIDI RICERCA  "
multiplayer_window.menu_sabotage = "  COLPI BASSI  "
multiplayer_window.menu_trade = "  SCAMBIA CON ALTRI GIOCATORI  "
multiplayer_window.mode_competitive = "Gara: ognuno per sé"
multiplayer_window.mode_coop = "Coop: si vince tutti insieme"
multiplayer_window.mode_mixed = "Gara di squadre"
multiplayer_window.mode_shared = "Un ospedale condiviso"
multiplayer_window.mode_teams = "Gara di due squadre"
multiplayer_window.mode_teamshared = "Gara di ospedali di squadra"
multiplayer_window.money_received = "Soldi da %s"
multiplayer_window.money_received_note = "%s ti ha mandato $%d."
multiplayer_window.money_sent = "Soldi mandati a %s"
multiplayer_window.mp_level = "%s (con più ospedali: livello %d)"
multiplayer_window.name = "Il tuo nome"
multiplayer_window.new_room = "Nuova stanza"
multiplayer_window.no_auctions = "nessuna asta"
multiplayer_window.no_helper_building = "i bot non costruiscono"
multiplayer_window.no_rooms = "Ancora nessuna stanza. Creane una qui sotto."
multiplayer_window.no_sharing = "nessuna condivisione"
multiplayer_window.no_socket = "Questa versione non ha il supporto di rete (manca LuaSocket)."
multiplayer_window.no_tricks = "nessun colpo basso"
multiplayer_window.not_encrypted = "Non cifrata"
multiplayer_window.not_encrypted_build = "Non cifrata: questo gioco non ha LuaSec"
multiplayer_window.not_encrypted_server = "Non cifrata: questo server non ha un certificato"
multiplayer_window.not_ready = "non pronto"
multiplayer_window.offer_ability = "Abilità: %d%%"
multiplayer_window.offer_accept = "Accetta"
multiplayer_window.offer_accept_pay = "Paga $%d"
multiplayer_window.offer_accept_price = "Accetta e paga $%d"
multiplayer_window.offer_accepted_note = "%s ha accettato: %s."
multiplayer_window.offer_accepted_price_note = "%s ha accettato: %s, per $%d."
multiplayer_window.offer_caption = "Offerta da %s"
multiplayer_window.offer_decline = "Rifiuta"
multiplayer_window.offer_declined_note = "%s ha rifiutato: %s."
multiplayer_window.offer_free_banner = "GRATIS: nessun costo per questo membro del personale"
multiplayer_window.offer_gone_note = "%s non è più disponibile."
multiplayer_window.offer_happy = "Felicità: %d%%"
multiplayer_window.offer_health = "Salute: %d%%"
multiplayer_window.offer_illness = "Malattia: %s"
multiplayer_window.offer_job = "Lavoro: %s"
multiplayer_window.offer_later = "Dopo"
multiplayer_window.offer_no_money_note = "Non puoi permetterti i $%d richiesti per %s."
multiplayer_window.offer_no_money_sender_note = "%s non ha potuto permettersi il prezzo per %s."
multiplayer_window.offer_no_skills = "Abilità speciali: nessuna"
multiplayer_window.offer_not_diagnosed = "Non ancora diagnosticato (%d%% fatto)"
multiplayer_window.offer_patient_known = "un paziente con %s"
multiplayer_window.offer_patient_line = "%s ti manda un paziente:"
multiplayer_window.offer_patient_unknown = "un paziente non diagnosticato"
multiplayer_window.offer_price_banner = "PREZZO: $%d, pagato solo se accetti"
multiplayer_window.offer_price_line = "PREZZO: $%d. Lo chiedono per questo membro del personale."
multiplayer_window.offer_raise = "Chiede un aumento"
multiplayer_window.offer_sent_note = "%s è stato offerto a %s. In attesa della risposta."
multiplayer_window.offer_sent_price_note = "%s è stato offerto a %s per $%d. In attesa della risposta."
multiplayer_window.offer_show = "Mostra"
multiplayer_window.offer_skills = "Abilità speciali: %s"
multiplayer_window.offer_staff_line = "%s ti offre un membro del personale:"
multiplayer_window.offer_tired = "Stanchezza: %d%%"
multiplayer_window.offer_wage = "Stipendio: $%d al mese"
multiplayer_window.options_close = "Chiudi"
multiplayer_window.options_host_only = "Solo l'host le cambia."
multiplayer_window.options_off_line = "Opzioni: %s"
multiplayer_window.other_build = "  (altra versione del gioco)"
multiplayer_window.owner_mark = " (host)"
multiplayer_window.password = "Password"
multiplayer_window.password_clear = "Non cifrata: la password viaggia in chiaro. Premi di nuovo per inviare."
multiplayer_window.patient_arrived_note = "E arrivato un paziente mandato da %s."
multiplayer_window.patient_on_the_way = "Mandato a %s"
multiplayer_window.places[1] = "1º"
multiplayer_window.places[2] = "2º"
multiplayer_window.places[3] = "3º"
multiplayer_window.places[4] = "4º"
multiplayer_window.places[5] = "5º"
multiplayer_window.places[6] = "6º"
multiplayer_window.places[7] = "7º"
multiplayer_window.places[8] = "8º"
multiplayer_window.player_away_note = "%s è uscito: il suo ospedale non conta per gli obiettivi della squadra finché non rientra (stessa stanza, stesso nome)."
multiplayer_window.player_back_note = "%s è tornato: il suo ospedale conta di nuovo per gli obiettivi della squadra."
multiplayer_window.player_line = "%s%s   %s ms   %s"
multiplayer_window.players = "%d giocatori"
multiplayer_window.players_balance = "Saldo"
multiplayer_window.players_behind = "%d ore indietro"
multiplayer_window.players_caption = "Giocatori"
multiplayer_window.players_goals = "Obiettivi"
multiplayer_window.players_hospital = "Ospedale"
multiplayer_window.players_left = "ha lasciato la partita"
multiplayer_window.players_ms = "%d ms"
multiplayer_window.players_name = "Giocatore"
multiplayer_window.players_note = "Ping: media degli ultimi 10 secondi. Valore: il valore dell'ospedale (un obiettivo del livello)."
multiplayer_window.players_ping = "Ping"
multiplayer_window.players_playing = "in gioco"
multiplayer_window.players_quiet = "nessuna risposta da %d s"
multiplayer_window.players_reputation = "Reputazione"
multiplayer_window.players_status = "Stato"
multiplayer_window.players_team = "%s (squadra %d)"
multiplayer_window.players_value = "Valore"
multiplayer_window.players_waiting = "In attesa dell'elenco del server..."
multiplayer_window.players_you = "tu"
multiplayer_window.plot_bought_transaction = "Terreno da %s (lotto %d)"
multiplayer_window.plot_give_button = "Offri il lotto"
multiplayer_window.plot_give_cancel = "Annulla"
multiplayer_window.plot_give_caption = "Cedi il lotto %d"
multiplayer_window.plot_give_free = "Prezzo: gratis"
multiplayer_window.plot_give_hint = "Cedere questo lotto a un alleato, gratis o a un prezzo"
multiplayer_window.plot_give_none = "Non c'è nessuno a cui cedere un lotto."
multiplayer_window.plot_give_offered = "Offerto. Il lotto cambia proprietario se l'altro giocatore accetta."
multiplayer_window.plot_give_price = "Prezzo: $%d"
multiplayer_window.plot_give_to = "A quale alleato:"
multiplayer_window.plot_given_transaction = "Terreno a %s (lotto %d)"
multiplayer_window.plot_offer_accepted_note = "%s ha accettato il lotto %d."
multiplayer_window.plot_offer_accepted_price_note = "%s ha accettato il lotto %d per $%d."
multiplayer_window.plot_offer_declined_note = "%s ha rifiutato il lotto %d."
multiplayer_window.plot_offer_free_line = "GRATIS: nessun costo per questo lotto."
multiplayer_window.plot_offer_gone_note = "L'offerta per il lotto %d non vale più: le cose sono cambiate."
multiplayer_window.plot_offer_line = "%s ti offre il lotto %d (%d caselle di terreno)."
multiplayer_window.plot_offer_no_money_note = "Non puoi permetterti i $%d richiesti per il lotto %d."
multiplayer_window.plot_offer_no_money_sender_note = "%s non ha potuto permettersi il lotto %d."
multiplayer_window.plot_offer_price_line = "PREZZO: $%d, pagato solo se accetti."
multiplayer_window.plot_offer_sent_note = "Il lotto %d è stato offerto a %s in regalo. In attesa della risposta."
multiplayer_window.plot_offer_sent_price_note = "Il lotto %d è stato offerto a %s per $%d. In attesa della risposta."
multiplayer_window.plot_received_note = "Il lotto %d è ora tuo, da parte di %s."
multiplayer_window.plot_sell_hint = "Rivendere questo lotto alla banca (deve essere vuoto)"
multiplayer_window.plot_sell_question = "Vuoi vendere questo lotto? Riceverai indietro $%d."
multiplayer_window.plot_sold_note = "Il lotto %d è stato rivenduto alla banca per $%d."
multiplayer_window.plot_sold_others_note = "%s ha rivenduto il lotto %d. Torna in vendita."
multiplayer_window.plot_sold_transaction = "Lotto %d rivenduto"
multiplayer_window.race_and = " e "
multiplayer_window.race_failing = "Il tuo ospedale ha fallito gli obiettivi di questo livello. Riprenditi entro la fine del prossimo anno, o sei fuori dalla gara."
multiplayer_window.race_failing_other = "%s ha fallito gli obiettivi di questo livello; è fuori se li fallisce ancora il prossimo anno."
multiplayer_window.race_left_end = "Hai lasciato la gara. Gli altri continuano per i posti successivi."
multiplayer_window.race_out[1] = "Brutte notizie."
multiplayer_window.race_out[2] = "Il tuo ospedale ha fallito gli obiettivi di questo livello due anni di fila: è fuori dalla gara, al posto: %s."
multiplayer_window.race_out[3] = "Tornare alla lobby o guardare gli altri?"
multiplayer_window.race_out_other = "%s ha fallito gli obiettivi due anni di fila ed è fuori dalla gara (posto: %s)."
multiplayer_window.race_out_short = "fuori"
multiplayer_window.race_over[1] = "La gara è finita. Classifica finale:"
multiplayer_window.race_over[2] = "Tornare alla lobby o continuare a giocare?"
multiplayer_window.race_over_won = "Complimenti, la tua squadra ha vinto la gara! Classifica finale:"
multiplayer_window.race_placed_other = "%s ha raggiunto gli obiettivi di questo livello: posto %s. La gara continua."
multiplayer_window.race_standing = "%s %s"
multiplayer_window.race_standing_out = " (fuori)"
multiplayer_window.race_watch = "Guarda"
multiplayer_window.race_won[1] = "Complimenti!"
multiplayer_window.race_won[2] = "Il tuo ospedale ha raggiunto gli obiettivi di questo livello: posto %s."
multiplayer_window.race_won[3] = "Gli altri gareggiano per i posti successivi. Tornare alla lobby o guardare?"
multiplayer_window.race_won_question = "Gli altri gareggiano per i posti successivi. Vuoi tornare alla lobby?"
multiplayer_window.race_won_allies = "Tu e %s ce l'avete fatta! Ben fatto!"
multiplayer_window.race_won_allies_first = "Tu e %s ce l'avete fatta! Ottimo lavoro!"
multiplayer_window.race_won_first = "Il tuo ospedale è il primo a raggiungere tutti gli obiettivi di %s. Hai vinto la gara!"
multiplayer_window.race_won_place = "Il tuo ospedale ha raggiunto tutti gli obiettivi di %s: posto %s."
multiplayer_window.race_won_team_first = "La tua squadra è la prima a raggiungere tutti gli obiettivi di %s. Hai vinto la gara!"
multiplayer_window.race_won_team_place = "La tua squadra ha raggiunto tutti gli obiettivi di %s: posto %s."
multiplayer_window.race_won_together = "Ce l'avete fatta insieme! Ben fatto!"
multiplayer_window.race_won_together_first = "Ce l'avete fatta insieme! Ottimo lavoro!"
multiplayer_window.race_won_well_done = "Ben fatto!"
multiplayer_window.rat_attacks = "attacchi di ratti"
multiplayer_window.rats_off = "Attacco di ratti (gare): non consentito"
multiplayer_window.rats_on = "Attacco di ratti (gare): consentito"
multiplayer_window.ready = "Pronto"
multiplayer_window.rebuild_destroyed_room = "Questa stanza è stata distrutta. Sgomberarla per $%d e ricostruirla?"
multiplayer_window.recommendation = "Fino a %s; le azioni richiedono %s ms"
multiplayer_window.refer_button = "Manda paziente"
multiplayer_window.refer_choose = "A quale ospedale mandarlo?"
multiplayer_window.refer_fax_choice = "Manda a un altro ospedale"
multiplayer_window.referral_cured_here_note = "Hai curato un paziente mandato da %s: +%d di reputazione in più."
multiplayer_window.referral_cured_note = "%s ha curato il paziente che hai mandato: +%d di reputazione."
multiplayer_window.refresh = "Aggiorna"
multiplayer_window.rep_amount = "Punti: %d"
multiplayer_window.rep_give_button = "Dai %d dei tuoi punti di reputazione"
multiplayer_window.rep_given_note = "Hai garantito per %s: hai dato %d punti di reputazione."
multiplayer_window.rep_received_note = "%s garantisce per il tuo ospedale: hai guadagnato %d punti di reputazione."
multiplayer_window.rep_rivals = "Solo gli alleati possono garantire l'uno per l'altro."
multiplayer_window.rep_sent = "Fatto. I punti passano tra un attimo."
multiplayer_window.rep_vouch_caption = "Garanzia: dai parte della tua reputazione"
multiplayer_window.repair_destroyed_room = "Questa stanza è stata distrutta. Ripararla per $%d, il prezzo di una nuova con i suoi arredi? (No: sgomberala invece.)"
multiplayer_window.research_accept = "ACCETTO questa ricerca"
multiplayer_window.research_accept_price = "ACCETTO questa ricerca per $%d"
multiplayer_window.research_accepted_note = "%s ha accettato la tua ricerca (ha pagato $%d)."
multiplayer_window.research_all = "Tutte"
multiplayer_window.research_and_more = "e altre %d"
multiplayer_window.research_bought_transaction = "Ricerca da %s"
multiplayer_window.research_caption = "Condividi ricerca con %s"
multiplayer_window.research_decline = "RIFIUTO questa ricerca"
multiplayer_window.research_declined_note = "%s ha rifiutato la tua ricerca."
multiplayer_window.research_free = "Prezzo: gratis"
multiplayer_window.research_free_line = "GRATIS: questo trasferimento non costa nulla."
multiplayer_window.research_item_drug = "Medicinale: %s"
multiplayer_window.research_item_machine = "Migliorato: %s"
multiplayer_window.research_known_note = "Conosci già tutta quella ricerca."
multiplayer_window.research_known_sender_note = "%s conosceva già tutta quella ricerca."
multiplayer_window.research_next = "Altro"
multiplayer_window.research_no_money_note = "Non puoi permetterti quella ricerca ($%d)."
multiplayer_window.research_no_money_sender_note = "%s non ha potuto permettersi la tua ricerca."
multiplayer_window.research_none = "Non hai ricerche che a loro mancano."
multiplayer_window.research_none_selected = "Seleziona prima qualche ricerca."
multiplayer_window.research_offer = "Offri"
multiplayer_window.research_offer_line = "%s vuole condividere con te questa ricerca:"
multiplayer_window.research_offered = "Offerta fatta. In attesa della risposta."
multiplayer_window.research_page = "Pagina %d di %d"
multiplayer_window.research_previous = "Indietro"
multiplayer_window.research_price = "Prezzo: $%d"
multiplayer_window.research_price_line = "PREZZO: $%d. Lo paghi solo se accetti."
multiplayer_window.research_received_note = "Nuova ricerca: %s."
multiplayer_window.research_sent_note = "Ricerca offerta a %s. In attesa della risposta."
multiplayer_window.research_sold_transaction = "Ricerca venduta a %s"
multiplayer_window.room_caption = "Stanza: %s"
multiplayer_window.room_hint = "Stesso colore: un solo ospedale. Stessa squadra: vincete insieme."
multiplayer_window.room_line = "%s   %d di %d   %s   livello %s%s"
multiplayer_window.rooms_caption = "Stanze su %s"
multiplayer_window.sabotage_again = "Clicca di nuovo L%d per comprarlo a $%d."
multiplayer_window.sabotage_alone = "Non è rimasto nessun rivale a cui fare scherzi."
multiplayer_window.sabotage_arrived = "Il tuo tuttofare malvagio ha iniziato a lavorare da %s."
multiplayer_window.sabotage_boiler = "Caldaia rotta"
multiplayer_window.sabotage_boiler_notice = "La caldaia si è rotta, e non è stato un caso. I tuoi tuttofare la riparano: più sono, prima finiscono."
multiplayer_window.sabotage_caption = "Colpi bassi contro %s"
multiplayer_window.sabotage_caught = "Hai cacciato un tuttofare che non era tuo: lo ha mandato %s. Torna da loro."
multiplayer_window.sabotage_caught_owner = "%s ha scoperto il tuo tuttofare malvagio. Torna a lavorare per te."
multiplayer_window.sabotage_close = "Chiudi"
multiplayer_window.sabotage_done.boiler = "La caldaia di %s si è rotta."
multiplayer_window.sabotage_done.emergency = "Un'emergenza sta arrivando da %s."
multiplayer_window.sabotage_done.epidemic = "I pazienti contagiosi stanno arrivando da %s."
multiplayer_window.sabotage_done.espionage = "La tua spia è stata da %s."
multiplayer_window.sabotage_done.handyman = "Il tuo tuttofare malvagio sta andando da %s."
multiplayer_window.sabotage_done.headhunter = "Il tuo cacciatore di teste ha fatto un'offerta a un membro del personale di %s."
multiplayer_window.sabotage_done.rats = "I ratti si stanno trasferendo da %s."
multiplayer_window.sabotage_done.smear = "La campagna diffamatoria contro %s è iniziata."
multiplayer_window.sabotage_emergency = "Emergenza"
multiplayer_window.sabotage_emergency_fax[1] = "Ti è stata mandata un'emergenza, e non puoi rifiutarla."
multiplayer_window.sabotage_emergency_fax[2] = "%d pazienti con %s stanno arrivando in elicottero."
multiplayer_window.sabotage_emergency_fax[3] = "Cura più pazienti che puoi prima che scada il tempo."
multiplayer_window.sabotage_epidemic = "Epidemia"
multiplayer_window.sabotage_espionage = "Spionaggio"
multiplayer_window.sabotage_espionage_got = "La tua spia ha portato: %s."
multiplayer_window.sabotage_espionage_notice = "Qualcuno ha copiato dei file dal reparto ricerca."
multiplayer_window.sabotage_espionage_notice_3 = "Qualcuno è entrato nel reparto ricerca: file copiati, e la ricerca in corso è tornata indietro della metà."
multiplayer_window.sabotage_handyman = "Tuttofare malvagio"
multiplayer_window.sabotage_handyman_hint = {"Le tue attrezzature si sono rotte spesso ultimamente. Che ci sia un tuttofare malvagio nel tuo ospedale?", "Qui continua ad andare tutto storto. Ogni tuo tuttofare è davvero tuo? Licenzia quello che non lo è.", "Un tuttofare che nessuno ricorda di aver assunto si aggira per i tuoi corridoi. Guarda i tuoi tuttofare: uno sconosciuto si può cacciare."}
multiplayer_window.sabotage_headhunter = "Cacciatore di teste"
multiplayer_window.sabotage_headhunter_left = "%s se n'è andato per un'offerta migliore."
multiplayer_window.sabotage_headhunter_notice = "A %s è stato offerto un lavoro migliore in un altro ospedale e chiede un aumento di $%d. Accetta entro 10 giorni, o se ne va."
multiplayer_window.sabotage_headhunter_won = "%s ha lasciato il suo ospedale ed è nella lista di assunzione: assumilo entro %d giorni, prima che possa farlo qualcun altro."
multiplayer_window.sabotage_level = "L%d  $%d"
multiplayer_window.sabotage_level_locked = "L%d  mese %d"
multiplayer_window.sabotage_level_off = "L%d  no"
multiplayer_window.sabotage_levels.boiler[1] = "La loro caldaia si rompe: troppo freddo in inverno, troppo caldo in estate, finché i loro tuttofare non la riparano (riparazione breve)."
multiplayer_window.sabotage_levels.boiler[2] = "La loro caldaia si rompe, per circa il doppio del tempo. Più tuttofare la riparano prima."
multiplayer_window.sabotage_levels.boiler[3] = "La loro caldaia si rompe malamente: riparazione lunga. Più tuttofare la riparano prima."
multiplayer_window.sabotage_levels.emergency[1] = "Un'emergenza che non possono rifiutare: 3 pazienti in elicottero, con una malattia che conoscono."
multiplayer_window.sabotage_levels.emergency[2] = "Un'emergenza che non possono rifiutare: 6 pazienti in elicottero, con una malattia che conoscono."
multiplayer_window.sabotage_levels.emergency[3] = "Un'emergenza che non possono rifiutare: 10 pazienti in elicottero, forse con una malattia che non hanno scoperto."
multiplayer_window.sabotage_levels.epidemic[1] = "2 pazienti contagiosi della stessa malattia arrivano nel loro ospedale."
multiplayer_window.sabotage_levels.epidemic[2] = "4 pazienti contagiosi della stessa malattia arrivano nel loro ospedale."
multiplayer_window.sabotage_levels.epidemic[3] = "7 pazienti contagiosi della stessa malattia arrivano nel loro ospedale."
multiplayer_window.sabotage_levels.espionage[1] = "Copia un miglioramento di un medicinale o di una macchina che hanno loro e tu no: scegli tu quale."
multiplayer_window.sabotage_levels.espionage[2] = "Copia una scoperta (una macchina o una stanza) che hanno loro e tu no: scegli tu quale."
multiplayer_window.sabotage_levels.espionage[3] = "Copia due loro miglioramenti o scoperte (scegli tu) e fai tornare indietro della metà la loro ricerca in corso."
multiplayer_window.sabotage_levels.handyman[1] = "Un tuttofare che sembra il loro ma non lavora, per 4 mesi. Se lo trovano e lo licenziano, viene a lavorare per te."
multiplayer_window.sabotage_levels.handyman[2] = "Come L1, e due volte al giorno getta rifiuti nei loro corridoi, per 3 mesi."
multiplayer_window.sabotage_levels.handyman[3] = "Come L2, e ogni 3 giorni finge di riparare una macchina, lasciandola quasi rotta. Resta 2 mesi."
multiplayer_window.sabotage_levels.headhunter[1] = "Il loro miglior medico junior o infermiere riceve un'offerta migliore: pagano un aumento del 50 per cento entro 10 giorni, o lo perdono a favore della lista di assunzione (tenuto per te 2 settimane)."
multiplayer_window.sabotage_levels.headhunter[2] = "Il loro miglior dottore riceve un'offerta migliore: pagano un aumento del 75 per cento entro 10 giorni, o lo perdono a favore della lista di assunzione (tenuto per te 2 settimane)."
multiplayer_window.sabotage_levels.headhunter[3] = "Il loro miglior consulente o specialista riceve un'offerta migliore: raddoppiano il suo stipendio entro 10 giorni, o lo perdono a favore della lista di assunzione (tenuto per te 2 settimane)."
multiplayer_window.sabotage_levels.rats[1] = "5 ratti si trasferiscono. Finché corrono in giro costano loro fino a 1 di reputazione al giorno (fino a 30 giorni), finché non vengono abbattuti."
multiplayer_window.sabotage_levels.rats[2] = "10 ratti si trasferiscono. Finché corrono in giro costano loro fino a 2 di reputazione al giorno (fino a 30 giorni), finché non vengono abbattuti."
multiplayer_window.sabotage_levels.rats[3] = "20 ratti si trasferiscono. Finché corrono in giro costano loro fino a 3 di reputazione al giorno (fino a 30 giorni), finché non vengono abbattuti."
multiplayer_window.sabotage_levels.smear[1] = "Stampa negativa per un mese: 3 nuovi pazienti su 10 vanno invece negli altri ospedali."
multiplayer_window.sabotage_levels.smear[2] = "Stampa negativa per 2 mesi: 4 nuovi pazienti su 10 vanno invece negli altri ospedali."
multiplayer_window.sabotage_levels.smear[3] = "Stampa negativa per 3 mesi: metà dei loro nuovi pazienti va invece negli altri ospedali."
multiplayer_window.sabotage_locked_tooltip = "A questo livello si può comprare dal mese %d della partita."
multiplayer_window.sabotage_next = "Rivale seguente"
multiplayer_window.sabotage_off_tooltip = "L'host non ha consentito questo colpo basso in questa partita (opzioni di gioco)."
multiplayer_window.sabotage_pick = "Clicca su un livello per vedere cosa fa. Cliccalo di nuovo per comprarlo."
multiplayer_window.sabotage_rats = "Attacco di ratti"
multiplayer_window.sabotage_rats_notice = "Ratti! Uno sciame si è trasferito nell'ospedale. Finché corrono in giro costano reputazione ogni giorno: cliccaci sopra per abbatterli."
multiplayer_window.sabotage_rats_reminder = "%d ratti corrono ancora per l'ospedale e costano reputazione ogni giorno."
multiplayer_window.sabotage_rats_reminders = {"%d ratti corrono ancora per l'ospedale e costano reputazione ogni giorno. Clicca su di loro per abbatterli.", "I ratti sono ancora qui, %d in tutto, e i pazienti ne parlano. Abbattili!", "Il tuo ospedale ha ancora %d ratti. Ogni giorno che restano ti costa reputazione."}
multiplayer_window.sabotage_refused = "Questo colpo basso non si può fare: %s."
multiplayer_window.sabotage_sent = "Ordinato. Paghi quando è fatto."
multiplayer_window.sabotage_smear = "Campagna diffamatoria"
multiplayer_window.sabotage_smear_notice = "Stampa negativa: una campagna diffamatoria contro l'ospedale tiene lontani alcuni pazienti per %d mese/i."
multiplayer_window.sabotage_smear_over = "La campagna diffamatoria è finita: i pazienti vengono in ospedale come prima."
multiplayer_window.sabotage_spy_caption = "Spia %s: scegli %d"
multiplayer_window.sabotage_spy_pick = "Scegli cosa deve copiare la tua spia, poi premi Ruba."
multiplayer_window.sabotage_spy_steal = "Ruba ($%d)"
multiplayer_window.sabotage_transaction = "Colpi bassi"
multiplayer_window.sabotage_went_home = "Il tempo del tuo tuttofare malvagio da %s è scaduto. E tornato a casa."
multiplayer_window.saved_flag = "  partita salvata"
multiplayer_window.saved_note = "Partita salvata: %s"
multiplayer_window.saving_note = "Salvataggio della partita sul computer di ogni giocatore..."
multiplayer_window.select_room = "Seleziona prima una stanza."
multiplayer_window.server = "Server"
multiplayer_window.server_eu1 = "EU1: stabile"
multiplayer_window.server_eu2 = "EU2: versioni di prova"
multiplayer_window.server_version = "la versione del server"
multiplayer_window.share_research = "Condividi ricerca"
multiplayer_window.shared_won = "Passare al livello successivo non è disponibile in multigiocatore."
multiplayer_window.sharing_off = "Condivisione ricerca: no"
multiplayer_window.sharing_on = "Condivisione ricerca: sì"
multiplayer_window.staff_arrived_note = "%s è arrivato e inizia a lavorare."
multiplayer_window.staff_bought_transaction = "Personale da %s"
multiplayer_window.staff_on_the_way = "In viaggio verso %s"
multiplayer_window.staff_received_note = "%s ti ha mandato un membro del personale: %s"
multiplayer_window.staff_sold_transaction = "Personale a %s"
multiplayer_window.start = "Inizia partita"
multiplayer_window.team_button = "Squadra %d"
multiplayer_window.team_lost = "%s ha ancora fallito gli obiettivi di questo livello a fine anno, quindi la squadra ha perso il livello."
multiplayer_window.team_member_out = "Il tuo ospedale ha fallito gli obiettivi di questo livello due anni di fila ed è fuori dalla gara. La tua squadra continua."
multiplayer_window.team_member_out_other = "%s ha fallito gli obiettivi due anni di fila ed è fuori dalla gara; la sua squadra continua."
multiplayer_window.team_race_mate_reached_fax[1] = "Il tuo compagno di squadra %s ha raggiunto gli obiettivi di questo livello!"
multiplayer_window.team_race_mate_reached_fax[2] = "La tua squadra vince quando ci arriva anche il tuo ospedale. Manca ancora: %s."
multiplayer_window.team_race_mate_reached_fax[3] = "Il tuo compagno di squadra può aiutarti con soldi, personale o pazienti."
multiplayer_window.team_race_reached_fax[1] = "Il tuo ospedale ha raggiunto gli obiettivi di questo livello!"
multiplayer_window.team_race_reached_fax[2] = "La gara non è ancora vinta: la tua squadra vince quando ci arriva ogni suo ospedale. Manca ancora: %s."
multiplayer_window.team_race_reached_fax[3] = "Tieni in funzione il tuo ospedale e aiutali con soldi, personale o pazienti."
multiplayer_window.team_race_reached_other = "%s ha raggiunto gli obiettivi di questo livello (squadra %s)."
multiplayer_window.team_won[1] = "Complimenti!"
multiplayer_window.team_won[2] = "Ogni ospedale ha raggiunto gli obiettivi di questo livello: la squadra ha vinto il livello."
multiplayer_window.team_won[3] = "Tornare alla lobby o continuare a giocare?"
multiplayer_window.too_many_hospitals = "Il livello ospita %d ospedali: condividete i colori"
multiplayer_window.trade_alone = "Non c'è nessuno con cui scambiare."
multiplayer_window.trade_caption = "Scambia con %s"
multiplayer_window.trade_close = "Chiudi"
multiplayer_window.trade_free = "Prezzo: gratis"
multiplayer_window.trade_money_allies_only = "Il denaro va solo agli alleati."
multiplayer_window.trade_next_player = "Giocatore seguente"
multiplayer_window.trade_no_staff = "Non hai personale da mandare."
multiplayer_window.trade_offered = "Offerto. Si unisce a te se l'altro giocatore accetta."
multiplayer_window.trade_on_the_way = "- offerto"
multiplayer_window.trade_price = "Prezzo: $%d"
multiplayer_window.trade_select_staff = "Clicca prima su un membro del personale."
multiplayer_window.trade_send_money = "Manda $%d"
multiplayer_window.trade_send_staff = "Offri il personale scelto"
multiplayer_window.trade_sent = "Mandato. Arriva tra un attimo."
multiplayer_window.tricks_off = "Colpi bassi (gare): no"
multiplayer_window.tricks_on = "Colpi bassi (gare): sì"
multiplayer_window.vaccination_mode_hint = "Modalità vaccinazione: clicca sui pazienti infetti perché un'infermiera li vaccini. Clic destro, Esc o un nuovo clic sulla siringa per smettere."
multiplayer_window.vote_agree = "D'accordo"
multiplayer_window.vote_asked = "Hai chiesto agli altri di cambiare la velocità a %s."
multiplayer_window.vote_confirm = "Chiedere agli altri giocatori di cambiare la velocità di gioco a %s?"
multiplayer_window.vote_decline = "Rifiuta"
multiplayer_window.vote_declined = "%s ha rifiutato il cambio di velocità a %s."
multiplayer_window.vote_lapsed = "Non abbastanza giocatori d'accordo in tempo: la velocità resta com'era."
multiplayer_window.vote_open = "Un cambio di velocità è già in votazione."
multiplayer_window.vote_passed = "I giocatori sono d'accordo: la velocità ora è %s."
multiplayer_window.vote_passed_paused = "I giocatori hanno scelto %s: la partita continua a quella velocità quando esce dalla pausa."
multiplayer_window.vote_request = "%s vorrebbe cambiare la velocità di gioco"
multiplayer_window.vote_request_speed = "a %s."
multiplayer_window.waiting_player = "in attesa di un giocatore..."
tooltip.main_menu.multiplayer = "Gioca con altri tramite un server multigiocatore (sperimentale)"
tooltip.multiplayer_window.ask_money = "Chiedi soldi a un altro giocatore. Decide lui se pagare."
tooltip.multiplayer_window.auctions = "L'host decide quali lotti di terreno vanno all'asta quando un giocatore chiede di comprarne uno"
tooltip.multiplayer_window.auctions_all = "Ogni lotto va all'asta tra tutti gli ospedali che possono comprarlo"
tooltip.multiplayer_window.auctions_near = "I lotti dal lato di un altro giocatore o accanto al terreno di un altro ospedale vanno all'asta; gli altri si comprano e basta"
tooltip.multiplayer_window.auctions_none = "Nessuna asta: chi chiede per primo compra il lotto"
tooltip.multiplayer_window.colour = "Il colore del tuo ospedale: i giocatori con lo stesso colore costruiscono un ospedale insieme. Clicca per cambiarlo (l'host può cambiare quello di tutti, anche dei bot)"
tooltip.multiplayer_window.connect = "Connettiti al server e mostra le sue stanze"
tooltip.multiplayer_window.continue_game = "Continua una partita multigiocatore salvata in precedenza (File > Salva, o il salvataggio automatico mensile): sceglila dall'elenco. Senza salvataggio la stanza inizia una nuova partita"
tooltip.multiplayer_window.download = "Questo server usa un'altra versione del gioco: apri la sua pagina di download nel browser"
tooltip.multiplayer_window.game_options = "Le opzioni della partita: aste di terreni e altro (le imposta l'host)"
tooltip.multiplayer_window.helpers = "Decide l'host: un bot che condivide l'ospedale di una persona costruisce stanze e mette oggetti nei corridoi, oppure lo lascia fare alla persona (continua ad assumere, pagare premi, condividere la ricerca, fare offerte alle aste e comprare terreni)"
tooltip.multiplayer_window.level = "Scegli il livello in un elenco con i suoi obiettivi e una mappa. Un ospedale condiviso gioca i livelli della campagna; più ospedali giocano i livelli multigiocatore (da 1 a 8, un numero più alto gioca il livello 8). Il livello 6 è Emergenza!: emergenze quattro volte al mese nel primo anno, poi epidemie; il livello 7 è Senza pietà, fatto per una gara competitiva: colpi bassi mese dopo mese, fiere del lavoro, emergenze di gara e terremoti; il livello 8 è Team Town, la mappa di Matroftt fatta per due contro due"
tooltip.multiplayer_window.levels_players = "La mappa per questo numero di giocatori (ogni numero di giocatori ha la sua mappa)"
tooltip.multiplayer_window.name = "Il nome che vedono gli altri giocatori"
tooltip.multiplayer_window.new_game = "Inizia una nuova partita invece di quella salvata"
tooltip.multiplayer_window.password = "Password della stanza a cui entrare o da creare (vuota: nessuna password)"
tooltip.multiplayer_window.player_row = "Clic: guarda l'ospedale di questo giocatore (N: l'ospedale successivo)"
tooltip.multiplayer_window.chat_target = "A chi va il messaggio: a tutti, alla tua squadra (in una gara a squadre) o a un giocatore. Clicca o premi Tab per il successivo"
tooltip.multiplayer_window.players = "Per quanti giocatori è la stanza"
tooltip.multiplayer_window.rats = "Decide l'host: in una gara con colpi bassi i giocatori possono liberare dei ratti nell'ospedale di un rivale (gli costano reputazione), oppure no"
tooltip.multiplayer_window.ready = "Dì all'host che sei pronto a iniziare"
tooltip.multiplayer_window.refer_button = "Offri questo paziente all'ospedale di un altro giocatore. Deve accettare."
tooltip.multiplayer_window.send_staff = "Manda questo membro del personale all'ospedale di un altro giocatore. Deve accettare."
tooltip.multiplayer_window.server = "Indirizzo del server multigiocatore, per esempio eu2.bachelor-tech.com:47800"
tooltip.multiplayer_window.server_eu1 = "eu1.bachelor-tech.com: l'ultima versione stabile"
tooltip.multiplayer_window.server_eu2 = "eu2.bachelor-tech.com: l'ultima versione di prova"
tooltip.multiplayer_window.share_research = "Offri la ricerca che hai all'ospedale di un altro giocatore, gratis o a un prezzo. Deve accettare."
tooltip.multiplayer_window.sharing = "Decide l'host: i giocatori possono condividere o vendersi la ricerca, oppure no (come nel gioco originale)"
tooltip.multiplayer_window.start = "Inizia la partita per tutti nella stanza"
tooltip.multiplayer_window.team = "La tua squadra: la stessa squadra vince insieme, squadre diverse gareggiano verso gli obiettivi e possono farsi colpi bassi. Clicca per cambiarla (l'host può cambiare quella di tutti, anche dei bot)"
tooltip.multiplayer_window.tricks = "Decide l'host: in una gara i giocatori possono comprare colpi bassi contro i rivali, oppure no (come nel gioco originale)"
