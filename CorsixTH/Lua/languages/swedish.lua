--[[ Copyright (c) 2010-2016 Manuel "Roujin" Wolf, Edvin "Lego3" Linge

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
Language("Svenska", "Swedish", "sv", "swe")
Inherit("english")
Inherit("original_strings", 5)
Encoding(utf8)
IsArabicNumerals(true)

-------------------------------  OVERRIDE  ----------------------------------
object.reception_desk = "Reception"

-- "Psyket" means something entirely different than "Psykiatrin"
rooms_long.psychiatric = "Den psykiatriska avdelningen"
rooms_short.psychiatric = "Psykiatri"
tooltip.rooms.psychiatry = "I den psykiatriska avdelningen kureras galningar och man hjälper också till med diagnoser av andra patienter. Här behövs en läkare med psykiatrisk kompetens"
adviser.staff_place_advice.only_psychiatrists = "Läkare utan psykiatrisk examen kan inte arbeta inom psykiatrin."
adviser.room_requirements.psychiatry_need_psychiatrist = "Nu när du byggt en psykiatrisk avdelning måste du också anställa en psykiater."
room_descriptions.psych = {
  "Den psykiatriska avdelningen//",
  "Patienter som får diagnosen psykisk sjukdom måste uppsöka den psykiatriska avdelningen för att få behandling. Psykiatriker kan också ställa diagnoser, ta reda på vilken typ av sjukdom patienterna har och, i det fall det är mentalt behandla dem på den pålitliga gamla britsen.//",
  "Här behövs en läkare utbildad i psykiatri. "
}
introduction_texts.level1 = "Välkommen till ditt första sjukhus!//Sätt igång genom att placera ut en reception och bygga en allmänpraktik, anställ en receptionist och en läkare. " ..
                            "Vänta därefter på att jobben ska trilla in. En bra idé vore att bygga en psykmottagning och anställa en läkare med psykiatrisk kompetens. " ..
                            "Ett apotek och en syster behövs också för att du ska kunna bota dina patienter. Se upp för svåra fall av pöshuvud - ett pumprum behövs för att greja dessa. " ..
                            "Försök bota 10 personer och se till att ditt anseende inte sjunker under 200."

tooltip.staff_list.next_person = "Visa nästa sida"
tooltip.staff_list.prev_person = "Visa föregående sida"

-- Improve tooltips in staff window to mention hidden features
tooltip.staff_window.face = "Vederbörandes ansikte - klicka för att öppna personalhanteraren"
tooltip.staff_window.center_view = "Vänsterklicka för att komma till personen, högerklicka för att gå igenom personalen en och en"

confirmation.restart_level = "Är du säker på att du vill starta om nivån?"

-- In English the squits becomes the the squits, see issue 1646. In Swedish it stays the same, but it
-- still needs to be defined.
adviser.research.drug_improved_1 = "Medicinen mot %s har förbättrats av din forskaravdelning."
-------------------------------  NEW STRINGS  -------------------------------
object.litter = "Skräp"
tooltip.objects.litter = "Skräp: Lämnat åt sitt öde eftersom patienten inte kunde hitta någon papperskorg."

tooltip.fax.close = "Stäng fönstret utan att ta bort meddelandet"
tooltip.message.button = "Vänsterklicka för att öppna meddelandet"
tooltip.message.button_dismiss = "Vänsterklicka för att öppna meddelandet, högerklicka för att ta bort det"
tooltip.casebook.cure_requirement.hire_staff = "Du behöver anställa personal att hantera behandlingen"
tooltip.casebook.cure_type.unknown = "Du vet ännu inte hur denna sjukdom botas"
tooltip.research_policy.no_research = "Det pågår ingen forskning i den här kategorin just nu"
tooltip.research_policy.research_progress = "Framsteg inför nästa upptäckt i denna kategori: %1%/%2%"

handyman_window.all_parcels = "Alla tomter"
handyman_window.parcel = "Tomt"

tooltip.handyman_window.parcel_select = "Tomten där vaktmästaren accepterar uppdrag. Klicka för att ändra"
tooltip.new_game_window.player_name = "Skriv in det namn du vill kallas i spelet"
new_game_window.player_name = "Namn"

menu.player_count = "ANTAL SPELARE"

menu_options = {
  lock_windows = "  LÅS FÖNSTER  ",
  edge_scrolling = "  KANTRULLNING  ",
  adviser_disabled = "  (%1%) MEDHJÄLPARE  ",
  warmth_colors = "  VÄRMEFÄRGER  ",
  wage_increase = "  LÖNFÖRFRÅGNINGAR  ",
  twentyfour_hour_clock = "  24-TIMMARSKLOCKA  "
}

menu_options_game_speed = {
  pause               = "  (%1%) PAUSA  ",
  slowest             = "  (%1%) LÅNGSAMMAST  ",
  slower              = "  (%1%) LÅNGSAMMARE  ",
  normal              = "  (%1%) NORMAL  ",
  max_speed           = "  (%1%) MAXHASTIGHET  ",
  and_then_some_more  = "  (%1%) OCH SÅ LITE TILL  ",
}

menu_options_warmth_colors = {
  choice_1 = "  RÖD  ",
  choice_2 = "  BLÅ GRÖN RÖD  ",
  choice_3 = "  GUL ORANGE RÖD  ",
}

menu_options_wage_increase = {
  grant = "    BEVIJLA ",
  deny =  "    NEKA ",
}

-- Add F-keys to entries in charts menu (except briefing), also town_map was added.
menu_charts = {
  bank_manager  = "  (%1%) BANKKAMRER  ",
  statement     = "  (%1%) KONTOUTDRAG  ",
  staff_listing = "  (%1%) PERSONALLEDNING  ",
  town_map      = "  (%1%) STADSKARTA  ",
  casebook      = "  (%1%) MEDICINJOURNAL  ",
  research      = "  (%1%) FORSKNING  ",
  status        = "  (%1%) STATUS  ",
  graphs        = "  (%1%) GRAFER  ",
  policy        = "  (%1%) POLICY  ",
}

menu_file.restart = "  (%1%) STARTA OM  "

menu_debug = {
  jump_to_level               = "  HOPPA TILL NIVÅ  ",
  connect_debugger            = "  (%1%) KOPPLA LUA DBGp SERVER  ",
  transparent_walls           = "  (%1%) TRANSPARENTA VÄGGAR  ",
  limit_camera                = "  BEGRÄNSA KAMERAN  ",
  disable_salary_raise        = "  STÄNG AV LÖNEÖKNINGAR  ",
  make_debug_fax              = "  SKAPA DEBUGFAX  ",
  make_debug_patient          = "  SKAPA DEBUGPATIENT  ",
  cheats                      = "  (%1%) FUSK  ",
  lua_console                 = "  (%1%) LUATERMINAL  ",
  debug_script                = "  (%1%) KÖR DEBUGSKRIPT  ",
  calls_dispatcher            = "  ANROPSKLARERARE  ",
  dump_strings                = "  (%1%) SKAPA TEXTFILER  ",
  dump_gamelog                = "  (%1%) DUMPA SPELLOGG  ",
  map_overlay                 = "  KARTÖVERSIKT  ",
  sprite_viewer               = "  GRAFIKVISARE  ",
}
menu_debug_overlay = {
  none                        = "  INGET  ",
  flags                       = "  FLAGGOR  ",
  positions                   = "  KOORDINATER  ",
  heat                        = "  TEMPERATUR  ",
  byte_0_1                    = "  BYTE 0 & 1  ",
  byte_floor                  = "  BYTE GOLV  ",
  byte_n_wall                 = "  BYTE N VÄGG  ",
  byte_w_wall                 = "  BYTE W VÄGG  ",
  byte_5                      = "  BYTE 5  ",
  byte_6                      = "  BYTE 6  ",
  byte_7                      = "  BYTE 7  ",
  parcel                      = "  TOMT  ",
}

menu_player_count = {
  players_1 = "  1 SPELARE  ",
  players_2 = "  2 SPELARE  ",
  players_3 = "  3 SPELARE  ",
  players_4 = "  4 SPELARE  ",
}

adviser = {
  room_forbidden_non_reachable_parts = "Rummet kan inte placeras här eftersom delar av sjukhuset då blir oåtkomliga.",
  warnings = {
    no_desk = "Det kanske börjar bli dags att bygga en reception och anställa en receptionist?",
    no_desk_1 = "Om du vill att det ska komma patienter till sjukhuset så behövs en receptionist och en reception där hon kan jobba!",
    no_desk_2 = "Snyggt jobbat, det måste vara ett världsrekord: nästan ett år och inte en enda patient! Om du vill fortsätta som chef på det här sjukhuset så måste du anställa en receptionist och bygga en reception som hon kan jobba i!",
    no_desk_3 = "Helt otroligt, nästan ett år och du har fortfarande ingen bemannad reception! Tror du det kommer några patienter då? Sluta leka omkring och fixa till det här nu!",
    no_desk_4 = "En receptionist behöver ha en egen disk som hon kan hälsa patienterna välkomna vid",
    no_desk_5 = "Det var på tiden, nu borde det snart börja dyka upp patienter!",
    no_desk_6 = "Du har en receptionist, det kanske är dags att bygga en reception som hon kan arbeta vid?",
    no_desk_7 = "Nu har du en reception, vad sägs om att anlita en receptionist också? Det lär inte komma några patienter förrän du gjort det!",
    cannot_afford = "Du har inte tillräckligt med pengar på banken för att anställa den personen!",
    cannot_afford_2 = "du har inte tillräckligt med pengar på banken för att genomföra det köpet!",
    falling_1 = "Nämen! Det där inte kul, om du inte ser dig för var du klickar så kan någon skada sig!",
    falling_2 = "Sluta strula omkring, hur tror du det känns?",
    falling_3 = "Ajaj, det måste ha gjort ont. Ring en läkare!",
    falling_4 = "Det här är ett sjukhus, inte ett nöjesfält!",
    falling_5 = "Jag tror inte det här är rätt arena att knuffa omkull folk på, det är sjuka vet du!",
    falling_6 = "Det här är inte en bowlinghall, sjuka människor ska inte behandlas så!",
    research_screen_open_1 = "Du behöver bygga en forskningsavdelning innan du får tillgång till forskningsskärmen.",
    research_screen_open_2 = "På den här nivån finns det ingen möjlighet till forskning.",
    researcher_needs_desk_1 = "Varje forskare behöver ett skrivbord att jobba vid.",
    researcher_needs_desk_2 = "Din forskare är nöjd över att få en välbehövlig paus. Om du ville ha flera forskare aktiva samtidigt så behöver de få var sitt skrivbord.",
    researcher_needs_desk_3 = "En forskare behöver alltid ett skrivbord.",
    nurse_needs_desk_1 = "Varje sköterska behöver ett eget skrivbord.",
    nurse_needs_desk_2 = "Din sköterska är glad att få en paus. Du kanske ville ha flera personer att jobba på avdelningen? Då behöver de var sitt skrivbord.",
    low_prices = "Du tar för lite betalt för %s. Det lockar visserligen fler patienter, men du kommer inte att tjäna så mycket på var och en.",
    high_prices = "Avgiften på %s är hög. Du tjänar mycket kortsiktigt, men till slut kommer du att driva iväg folk.",
    fair_prices = "Avgiften på %s verkar rimlig och balanserad.",
    patient_not_paying = "En patient lämnade just sjukhuset utan att betala för %s eftersom det är alldeles för dyrt!",
  },
  cheats = {
    th_cheat = "Ojoj, nån vill fuska sig till segern!",
    roujin_on_cheat = "Roujin's utmaning aktiverad! Lycka till...",
    roujin_off_cheat = "Roujin's utmaning avaktiverad.",
  },
}

dynamic_info.patient.actions.no_gp_available = "Väntar på att du ska bygga en allmänpraktik"
dynamic_info.staff.actions.heading_for = "På väg till %s"
dynamic_info.staff.actions.fired = "Sparkad"
dynamic_info.patient.actions.epidemic_vaccinated = "Jag smittar inte längre"

progress_report.free_build = "FRITT BYGGANDE"

fax = {
  choices = {
    return_to_main_menu = "Gå till huvudmenyn",
    accept_new_level = "Gå vidare till nästa nivå",
    decline_new_level = "Fortsätt spela ett tag till",
  },
  emergency = {
    num_disease_singular = "Vi har 1 person som kräver omedelbar vård med %s.",
    free_build = "Om du lyckas ökar ditt anseende, men om du misslyckas kommer ditt anseende att få en rejäl känga."
  },
  vip_visit_result = {
    remarks = {
      free_build = {
        "Det var ju ett trevligt sjukhus du har! Inte så svårt att få det så bra utan begränsande budget dock, eller hur?",
        "Jag är ingen ekonom, men jag tror att jag också hade kunnat driva det här sjukhuset, om du förstår vad jag menar...",
        "Ett mycket väld fungerande sjukhus må jag säga. Akta lågkonjunkturen bara! Just det... du behöver inte oroa dig över pengar nä.",
      }
    }
  }
}

letter = {
  dear_player = "Käre %s",
  custom_level_completed = "Bra gjort! Du klarade alla mål på den här specialnivån!",
  return_to_main_menu = "Vill du gå tillbaka till huvudmenyn eller fortsätta spela?",
  campaign_level_completed = "Bra jobbat! Du klarade nivån, men det är inte över än!\n Vill du ha jobbet som chef vid %s?",
  campaign_completed = "Otroligt! Du lyckades med alla nivåer. Nu är det bara att mysa och njuta av att fylla forum överallt på nätet om dina bedrifter. Lycka till!",
  campaign_level_missing = "Ledsen, men det verkar som att nästa nivå på den här kampanjen saknas. (Namn: %s)",
}

install = {
  title = "--------------------------------- CorsixTH Setup ---------------------------------",
  th_directory = "CorsixTH behöver en kopia av filerna från det ursprungliga spelet (eller dess demo) för att kunna köras. Använd väljaren nedan för att lokalisera mappen där Theme Hospital installerats.",
  ok = "OK",
  exit = "Avsluta",
  cancel = "Avbryt",
}

misc.not_yet_implemented = "(ej tillgänglig ännu)"
misc.no_heliport = "Antingen har inga sjukdomar upptäckts ännu, eller så finns det ingen helikopterplatta på den här nivån."

main_menu = {
  new_game = "Originalkampanjen",
  custom_campaign = "Nya kampanjer",
  custom_level = "Enskild nivå",
  continue = "Fortsätt spel",
  load_game = "Ladda spel",
  options = "Alternativ",
  map_edit = "Kartredigerare",
  savegame_version = "Sparningsversion: ",
  version = "Version: ",
  exit = "Avsluta",
}

tooltip.main_menu = {
  new_game = "Starta nivå ett i originalkampanjen från Theme Hospital",
  custom_campaign = "Spela en kampanj som är skapad av andra spelare",
  custom_level = "Bygg ditt sjukhus på en valfri nivå",
  load_game = "Ladda ett sparat spel",
  options = "Fixa till dina inställningar",
  map_edit = "Starta kartredigeraren för att skapa din egen karta",
  exit = "Nej! Du vill väl inte sluta redan?",
  quit = "Du håller på att avsluta CorsixTH. Är du säker på att du vill det?"
}

load_game_window = {
  caption = "Ladda spel",
}

tooltip.load_game_window = {
  load_game = "Ladda %s",
  load_game_number = "Ladda spel %d",
  load_autosave = "Ladda autosparningen",
}

custom_game_window = {
  caption = "Enskilda nivåer",
  free_build = "Bygg fritt",
  load_selected_level = "Starta",
}

tooltip.custom_game_window = {
  choose_game = "Välj en nivå för att läsa mer om den",
  free_build = "Bocka för den här rutan om du vill spela utan pengar och vinst- och förlustkriterier",
  load_selected_level = "Ladda och spela den valda nivån",
}

custom_campaign_window = {
  caption = "Nya kampanjer",
  start_selected_campaign = "Starta kampanj",
}

tooltip.custom_campaign_window = {
  choose_campaign = "Välj en kampanj för att läsa mer om den",
  start_selected_campaign = "Ladda den första nivån på den valda kampanjen",
}

save_game_window = {
  caption = "Spara spel",
  new_save_game = "Ny sparfil",
}

tooltip.save_game_window = {
  save_game = "Skriv över %s",
  new_save_game = "Skriv namnet på den nya filen",
}

save_map_window = {
  caption = "Spara karta (%1%)",
  new_map = "Ny karta",
}

tooltip.save_map_window = {
  map = "Skriv över kartan %s",
  new_map = "Skriv ett kartnamn",
}

menu_list_window = {
  name = "Namn",
  save_date = "Senast ändrad",
  back = "Tillbaka",
}

tooltip.menu_list_window = {
  name = "Klicka här för att sortera listan efter namn",
  save_date = "Klicka här för att sortera listan efter daturm då spelen sparades",
  back = "Stäng detta fönster",
}

options_window = {
  caption = "Alternativ",
  option_on = "På",
  option_off = "Av",
  customise = "Anpassa",
  folder = "Mappar",
  language = "Spelspråk",
  back = "Tillbaka",
}
graphics_window = {
  fullscreen = "Helskärm",
  width = "Bredd",
  height = "Höjd",
  option_on = "På",
  option_off = "Av",
  apply = "Tillämpa",
  cancel = "Avbryt",
}

tooltip.options_window = {
  customise = "Fler inställningar som kan ändras för att anpassa din spelupplevelse",
  folder = "Mappinställningar",
  language = "Text i spelet kommer att visas på det här språket",
  select_language = "Väljs spelspråk",
  language_dropdown_item = "Ändra till %s som språk",
  back = "Stäng alternativmenyn",
}
tooltip.graphics_window = {
  fullscreen = "Om spelet ska köras i fullskärmsläge eller fönsterläge",
  fullscreen_button = "Klicka för att gå mellan fönster och helskärm",
  width = "Fyll i önskad skärmbredd",
  height = "Fyll i önskad skärmhöjd",
  apply = "Tillämpa den valda upplösningen",
  cancel = "Återvänd utan att ändra upplösning",
}

audio_window = {
  audio = "Globalt ljud",
  back = "Tillbaka",
}

tooltip.audio_window = {
  audio_button = "Stäng av eller sätt på allt ljud i spelet",
  audio_toggle = "Slå av eller på",
}

customise_window = {
  caption = "Extra inställningar",
  option_on = "På",
  option_off = "Av",
  back = "Tillbaka",
  movies = "Global filmkontroll",
  play_intro = "Spela introfilmen",
  allow_user_actions_while_paused = "Bygg i pausläge",
  alien_dna_only_by_emergency = "Utomjordingar",
  disable_fractured_bones_females = "Krossad patient",
  enable_avg_contents = "Genomsnittsinnehåll",
}

tooltip.customise_window = {
  movies = "Välj om filmer ska spelas överhuvudtaget",
  play_intro = "Skippa introfilmen när du startar spelet. Global filmkontroll måste vara påslagen om du spela introfilmen varje gång du laddar CorsixTH",
  allow_user_actions_while_paused = "I Theme Hospital fick spelaren bara använda verktygsfältet längst upp när spelet var pausat. Så är det i CorsixTH också såvida du inte aktiverar funktionen att bygga även när spelet är pausat här",
  alien_dna_only_by_emergency = "Eftersom det inte finns ordentliga animeringar har vi gjort så att patienter med utomjordiskt DNA endast dyker upp som akutfall. Stäng av det här för att kunna få utomjordiskt DNA-fall även som vanliga besök",
  disable_fractured_bones_females = "På grund av en dålig animering har vi stängt av kvinnliga patienter med frakturer (Krossad patient). Stäng av det här, så kommer det att dyka upp även kvinnor med den åkomman",
  enable_avg_contents = "Om du vill att spelet ska komma ihåg vilka extra föremål du normalt sett brukar handla till nya rum, slå på detta alternativ",
  back = "Stäng den här menyn och gå tillbaka till Alternativmenyn",
}

folders_window = {
  caption = "Mappinställningar",
  data_label = "TH Data",
  font_label = "Typsnitt",
  music_label = "MP3",
  savegames_label = "Sparningar",
  screenshots_label = "Skärmbilder",
  -- next four are the captions for the browser window, which are called from the folder setting menu
  new_th_location = "Här kan du välja en ny sökväg där Theme Hospital ligger. Så fort du väljer en ny mapp kommer spelet att startas om!",
  savegames_location = "Välj var sparade spel ska läggas.",
  music_location = "Välj en mapp med musik i för att spela den i spelet.",
  screenshots_location = "Välj vilken mapp du vill spara skärmbilder till.",
  back  = "Tillbaka",
}

tooltip.folders_window = {
  browse = "Bläddra efter mappsökväg",
  data_location = "Mapp där originalspelet Theme Hospital finns. Krävs för att spela CorsixTH",
  font_location = "Sökväg till en typsnittsfil som kan visa Unicode-tecken som krävs för ditt språk. Om detta inte är specificerat kommer du inte att kunna välja sådana språk, till exempel ryska och kinesiska",
  savegames_location = "Som standard läggs sparade spel i en mapp som ligger bredvid konfigurationsfilen. Om det inte fungerar kan du välja en egen här",
  screenshots_location = "Skärmbilder sparas som standard i en mapp bredvid konfigurationsfilen. Här kan du välja en annan mapp istället",
  music_location = "Välj en sökväg där du har mp3-filer. Mappen måste redan finnas",
  browse_data = "Bläddra efter en ny sökväg till Theme Hospital  ( nuvarande sökväg: %1% )",
  browse_font = "Bläddra efter en annan typsnittsfil  ( nuvarande sökväg:: %1% )",
  browse_saves = "Bläddra efter en annan mapp att lägga sparade spel i  ( nuvarande sökväg:: %1% ) ",
  browse_screenshots = "Bläddra efter en annan mapp för skärmbilder  ( nuvarande sökväg:: %1% ) ",
  browse_music = "Bläddra efter en annan mapp med musik  ( nuvarande sökväg:: %1% ) ",
  no_font_specified = "Ingen typsnittsfil vald än!",
  not_specified = "Ingen sökväg vald än!",
  default = "Standardsökväg",
  reset_to_default = "Återställ mappen till standardsökvägen ( %1% )",
  back  = "Stäng den här dialogen och återgå till alternativmenyn",
}

font_location_window = {
  caption = "Välj typsnitt (%1%)",
}

new_game_window = {
  caption = "Kampanj",
  option_on = "På",
  option_off = "Av",
  difficulty = "Svårighetsgrad",
  easy = "Junior (Lätt)",
  medium = "Läkare (Medel)",
  hard = "Konsult (Svår)",
  tutorial = "Starthjälp",
  start = "Börja",
  cancel = "Avbryt",
}

tooltip.new_game_window = {
  easy = "Om du känner dig ny på denna typ av spel är detta läget för dig",
  medium = "Detta är den gyllene medelvägen om du är osäker på vad du ska välja",
  hard = "Känner du för en utmaning och är van vid den här typen av spel är det här rätt val",
  difficulty = "Välj vilken svårighetsgrad spelet ska ha",
  start = "Börja spela med dessa inställningar",
  tutorial = "Vill du ha lite hjälp på traven i början, tryck ner den här rutan",
  cancel = "Oj, det var ju egentligen inte meningen att starta ett nytt spel!",
}

lua_console = {
  execute_code = "Exekvera",
  close = "Stäng",
}

tooltip.lua_console = {
  textbox = "Skriv in Luakod att köra här",
  execute_code = "Kör koden du skrivit",
  close = "Stäng terminalen",
}

tooltip.toolbar = {
  status = "Status (%s)",
  casebook = "Medicinjournal (%s)",
  objects = "Placera ut prylar i korridorerna (%s)",
  edit = "Redigera rum/föremål (%s)",
  reputation = "Ditt anseende",
  research = "Forskare (%s)",
  date = "Datum",
  bank_button = "Vänsterklicka (%s) för bankkamrer, högerklicka (%s) för kontoutdrag",
  balance = "Ditt saldo",
  machine_menu = "Machine menu (%s)",
  town_map = "Stadskarta (%s)",
  charts = "Diagram (%s)",
  hire = "Anställ folk (%s)",
  policy = "Policy (%s)",
  staff_list = "Personalledning (%s)",
  rooms = "Bygg ett rum (%s)",
}

errors = {
  dialog_missing_graphics = "Tyvärr innehåller demon inte den här dialogrutan.",
  save_prefix = "Fel när spelet skulle sparas: ",
  load_prefix = "Fel när spelet skulle laddas: ",
  no_games_to_contine = "Det finns inga sparade spel.",
  load_quick_save = "Fel, kan inte ladda en snabbsparning eftersom det inte finns någon. Men oroa dig inte, nu har vi skapat en åt dig!",
  map_file_missing = "Kunde inte hitta kartfilen %s till den här nivån!",
  minimum_screen_size = "Skärmupplösningen måste vara åtminstone %dx%d.",
  unavailable_screen_size = "Skärmupplösningen du valde finns inte i fullskärmsläge.",
  alien_dna_only_by_emergency = "NOTERA: Det finns inga animeringar för patienter med utomjordiskt DNA när de sitter ner, öppnar dörrar osv. Precis som i Theme Hospital gör de därför det i mänsklig skepnad. Dessa patienter anländer som vanligt endast om nivån du spelar definierat att sjukdomen ska finnas",
  disable_fractured_bones_females = "NOTERA: Animeringen för kvinnliga Krossade patienter är inte perfekt",
  could_not_load_campaign = "Kunde inte ladda kampanjen %s",
  could_not_find_first_campaign_level = "Kunde inte hitta den första nivån på den här kampanjen: %s",
}

warnings = {
  levelfile_variable_is_deprecated = "Notera: Nivån '%s' innehåller en föråldrad variabeldefinition i nivåfilen." ..
                                     "'%LevelFile' har bytt namn till '%MapFile'. Meddela nivåskaparen att uppdatera nivån.",
}

confirmation = {
  needs_restart = "Att ändra denna inställning kräver en omstart av spelet. Osparad data kommer att gå förlorad. Är du säker på att du vill göra detta?",
  abort_edit_room = "Du håller på att bygga eller ändra ett rum. Om alla obligatoriska föremål är placerade kommer rummet att färdigställas som det är, annars tas det bort. Fortsätta?",
  maximum_screen_size = "Upplösningen du valt är större än 3000 x 2000. Större upplösningar är möjliga, men kräver bättre hårdvara. Är du säker på att du vill fortsätta?",
  music_warning = "Notera: När du väljer att använda mp3-filer som spelmusik behövs smpeg.dll eller motsvarande för ditt operativsystem, annars blir det ingen musik i spelet. Vill du fortsätta?",
}

information = {
  custom_game = "Välkommen till CorsixTH. Ha nu riktigt kul med den här specialnivån!",
  no_custom_game_in_demo = "Ledsen, men det går inte att spela enskilda nivåer med demofilerna.",
  cannot_restart = "Tyvärr sparades detta spel innan funktionen att starta om hade implementerats.",
  very_old_save = "Det har hänt en hel del med spelet sedan du startade den här nivån. För att vara säker på att allt fungerar som det är tänkt kan det vara bra att överväga att starta om nivån.",
  level_lost = {
    "Attans! Du förlorade. Bättre lycka nästa gång!",
    "Anledning till att du förlorade:",
    reputation = "Ditt anseende föll under %d.",
    balance = "Din bankbalans sjönk till under %d.",
    percentage_killed = "Du dödade mer än %d procent av dina patienter.",
    cheat = "Var det verkligen ditt val eller tryckte du bara på fel knapp? Så du kan inte ens fuska ordentligt, tråkigt för dig...",
  },
  cheat_not_possible = "Det går inte att använda det fusket på den här nivån. Du misslyckas till och med att fuska, det kan inte vara roligt!",
}

tooltip.information = {
  close = "Stäng informationsrutan",
}

totd_window = {
  tips = {
    "Alla sjukhus behöver en reception och en allmänpraktik för att fungera. Sedan beror allt på vad det är för patienter som besöker sjukhuset. Ett hett tips är att börja med ett apotek.",
    "Maskiner som till exempel pumpen behöver underhåll då och då. Anställ en vaktmästare eller två för att reparera dem, annars riskeras personalens och patienternas hälsa.",
    "Efter ett tag kommer din personal att bli trött. Se till att göra ett personalrum så att de kan slappna av lite.",
    "För att inte dina anställda och alla patienter ska bli arga gäller det att ha tillräckligt med element utplacerade lite här och där. Använd stadskartan för att hitta ställen som behöver mer värme.",
    "En läkares kompetensnivå påverkar kvaliteten och hastigheten på hans diagnoser ganska mycket. Sätt en riktigt kompetent läkare i allmänpraktiken så behövs det inte så många andra diagnosrum.",
    "Juniorer och läkare kan höja sin kompetensnivå genom att gå i träning hos en konsult i utbildningsrummet. Om konsulten har någon färdighet (kirurg, psykiater eller forskare) kommer han också att lära ut detta till sina elever.",
    "Har du testat att slå numret till SOS Alarm på faxen? Se till att ljudet är påslaget...",
    "Det går att göra vissa inställningar som till exempel upplösning och språk i alternativmenyn som finns både i huvudmenyn och inuti spelet.",
    "Hittar du en massa text på engelska i spelet? Hjälp oss översätta färdigt till Svenska!",
    "Teamet bakom CorsixTH söker förstärkning! Vill du koda, översätta eller skapa grafik till spelet? Kontakta oss i forumet, på mejllistan eller i IRC-kanalen (corsix-th at freenode).",
    "Om du hittar en bugg, rapportera den gärna i vår bugghanterare på adressen th-issues.corsix.org.",
    "Varje nivå har vissa krav som ska uppfyllas innan du kan gå vidare till nästa. Kolla statusfönstret för att se hur nära målen du är.",
    "Om du vill ändra eller ta bort ett existerande rum kan du göra det med hjälp av ändra rum-knappen i panelen längst ner (saxen).",
    "Om du ur högen av patienter vill ta reda på vilka som köar till ett visst rum är det bara att föra muspekaren över rummet.",
    "Klicka på dörren till ett rum för att se kön till det. Sedan går det att genomföra finlir som att ändra ordning eller skicka en patient till ett annat likadant rum.",
    "Olycklig personal frågar efter löneökning ofta. Se till att de jobbar i en behaglig miljö så händer det inte.",
    "Patienter blir törstiga när de väntar på sin tur, ännu mer om du sätter upp värmen! Sätt ut läskautomater på strategiska platser för lite extra inkomst.",
    "Det går att avbryta diagnosprocessen för en patient i förtid och gissa behandling om sjukdomen är känd. Notera att detta ökar risken för felbehandling - och dödsfall.",
    "Akutfall kan vara ett smidigt sätt att få in lite extra stålar, såvida du har kapacitet att hantera alla patienter i tid vill säga.",
  },
  previous = "Föregående tips",
  next = "Nästa tips",
}

tooltip.totd_window = {
  previous = "Visa föregående tips",
  next = "Visa nästa tips",
}

debug_patient_window = {
  caption = "Debug Patient",
}

cheats_window = {
  caption = "Fusk",
  warning = "Varning: Du kommer inte att få bonuspoäng på slutet av nivån om du fuskar!",
  cheated = {
    no = "Har fuskat: Nej",
    yes = "Har fuskat: Ja",
  },
  cheats = {
    money = "Pengar",
    all_research = "All forskning",
    emergency = "Skapa akutfall",
    vip = "Skapa VIP",
    earthquake = "Skapa jordbävning",
    epidemic = "Skapa en smittande patient",
    toggle_infected = "Visa infekterad-ikonen",
    create_patient = "Skapa patient",
    end_month = "Månadsslut",
    end_year = "Hoppa till nyår",
    lose_level = "Förlora nivå",
    win_level = "Vinn nivå",
    increase_prices = "Öka priser",
    decrease_prices = "Minska priser",
  },
  close = "Stäng",
}

tooltip.cheats_window = {
  close = "Stäng fuskfönstret",
  cheats = {
    money = "Ökar din balans med 10 000.",
    all_research = "Färdigställer all forskning.",
    emergency = "Skapar ett akutfall.",
    vip = "Skapar en Mycket Viktig Person (VIP)",
    earthquake = "Skapar en jordbävning med slumpad styrka",
    epidemic = "Skapar en person som smittar så att en epidemi kan starta",
    toggle_infected = "Växlar mellan att visa ikoner vid en upptäckt, aktiv epidemi",
    create_patient = "Skapar en patient vid kanten av kartan.",
    end_month = "Hoppar till slutet av månaden.",
    end_year = "Hoppar till slutet av året.",
    lose_level = "Förlora nuvarande nivå.",
    win_level = "Vinn nuvarande nivå.",
    increase_prices = "Öka alla priser med 50% (max. 200%)",
    decrease_prices = "Minska alla priser med 50% (min. 50%)",
  }
}

introduction_texts = {
  demo =
    "Välkommen till demosjukhuset!//" ..
    "Tyvärr innehåller demon bara denna nivå. Ändå finns det garanterat tillräckligt att göra ett tag framöver! " ..
    "Du kommer att råka ut för diverse sjukdomar som kräver olika rum för att botas. " ..
    "Ibland kan olyckor hända, så att det kommer akutfall till sjukhuset. Dessutom behöver du forska för att upptäcka fler rum. " ..
    "Målet är att tjäna $100,000, ha ett sjukhusvärde av $70,000 och 700 i anseende, samtidigt som du botar minst 75% av patienterna. " ..
    "Se till att ditt anseende inte sjunker under 300 och att du inte dödar mer än 40% av dina patienter, annars förlorar du.//" ..
    "Lycka till!",
}

calls_dispatcher = {
  -- Dispatcher description message. Visible in Calls Dispatcher dialog
  summary = "%d anrop; %d tilldelade",
  staff = "%s - %s",
  watering = "Vattnar @ %d,%d",
  repair = "Reparera %s",
  close = "Stäng",
}

tooltip.calls_dispatcher = {
  task = "Lista över uppgifter - klicka på en uppgift för att öppna tilldelad personals fönster och flytta vyn till det ställe där uppgiften finns.",
  assigned = "Denna ruta är markerad om någon har fått uppgiften tilldelad till sig.",
  close = "Stäng anropsklarerardialogen",
}

update_window = {
  caption = "Updatering tillgänglig!",
  new_version = "Ny version:",
  current_version = "Din version:",
  download = "Gå till nedladdningssidan",
  ignore = "Skippa och gå till huvudmenyn",
}

tooltip.update_window = {
  download = "gå till nedladdningssidan där du hittar den absolut senaste versionen av CorsixTH",
  ignore = "Skippa updateringen just nu. Du kommer att få en ny notis nästa gång du öppnar CorsixTH",
}

map_editor_window = {
  pages = {
    inside = "Inomhus",
    outside = "Utomhus",
    foliage = "Grönska",
    hedgerow = "Häck",
    pond = "Damm",
    road = "Väg",
    north_wall = "Nordlig vägg",
    west_wall = "Västlig vägg",
    helipad = "Helikopterplatta",
    delete_wall = "Ta bort väggar",
    parcel_0 = "Tomt 0",
    parcel_1 = "Tomt 1",
    parcel_2 = "Tomt 2",
    parcel_3 = "Tomt 3",
    parcel_4 = "Tomt 4",
    parcel_5 = "Tomt 5",
    parcel_6 = "Tomt 6",
    parcel_7 = "Tomt 7",
    parcel_8 = "Tomt 8",
    parcel_9 = "Tomt 9",
    camera_1 = "Kamera 1",
    camera_2 = "Kamera 2",
    camera_3 = "Kamera 3",
    camera_4 = "Kamera 4",
    heliport_1 = "Heliport 1",
    heliport_2 = "Heliport 2",
    heliport_3 = "Heliport 3",
    heliport_4 = "Heliport 4",
    paste = "Klistra in",
  }
}

date_format.daymonth = "%1% %2:months%"

original_credits[301] = ":Operations"
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
original_credits[327] = ":All at Bullfrog Productions"
original_credits[328] = " "
original_credits[329] = " "
original_credits[330] = " "
original_credits[331] = ":Special Thanks to"
original_credits[332] = ","
original_credits[333] = "Everyone at Frimley Park Hospital"
original_credits[334] = " "
original_credits[335] = ":Especially"
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



--------------------------------  UNUSED  -----------------------------------
------------------- (kept for backwards compatibility) ----------------------

-------------------------------------------------------------------------------
--   Multiplayer (network play): the room, game options, auctions, bots and the rest
--   of the multiplayer windows. Translated from english.lua; the keys
--   missing here show in English.
-------------------------------------------------------------------------------
hotkey_window.ingame_mp_chat = "Flerspelarchatt"
hotkey_window.ingame_mp_next_hospital = "Nästa sjukhus (MP)"
main_menu.multiplayer = "Flerspelare"
map_editor_window.pages.camera_n = "Kamera %d"
map_editor_window.pages.heliport_n = "Heliport %d"
map_editor_window.pages.player = "Spelare %d"
menu.map_size = "KARTSTORLEK"
menu_map_size.size = "  NY KARTA %d x %d  "
menu_player_count.players_5 = "  5 SPELARE  "
menu_player_count.players_6 = "  6 SPELARE  "
menu_player_count.players_7 = "  7 SPELARE  "
menu_player_count.players_8 = "  8 SPELARE  "
multiplayer_window.add_bot = "väntar på en spelare... (klicka: lägg till en bot)"
multiplayer_window.ask_amount = "Belopp: $%d"
multiplayer_window.ask_asked = "Förfrågan skickad. Väntar på svar."
multiplayer_window.ask_balance_line = "Spelarens saldo: $%d."
multiplayer_window.ask_button = "Fråga"
multiplayer_window.ask_caption = "Be %s om pengar"
multiplayer_window.ask_decline = "Neka"
multiplayer_window.ask_declined_note = "%s nekade att skicka $%d till dig."
multiplayer_window.ask_line = "%s ber dig om $%d."
multiplayer_window.ask_money = "Fråga en spelare"
multiplayer_window.ask_no_money_asker_note = "%s kunde inte betala dig."
multiplayer_window.ask_no_money_note = "Du kan inte betala $%d."
multiplayer_window.ask_pay = "Betala $%d"
multiplayer_window.ask_sent_note = "Du bad om $%d av %s. Väntar på svar."
multiplayer_window.auction_back = "Tillbaka till auktionen"
multiplayer_window.auction_bid = "Bjud $%d"
multiplayer_window.auction_borrow_tooltip = "Låna $5,000 av banken"
multiplayer_window.auction_close = "Stäng"
multiplayer_window.auction_dropped = "Du hoppade av."
multiplayer_window.auction_going_once = "Första..."
multiplayer_window.auction_going_twice = "Andra..."
multiplayer_window.auction_leader = "Högsta bud: $%d, %s"
multiplayer_window.auction_leading = "Du leder. Vänta på de andra."
multiplayer_window.auction_loan = "$%d, lån $%d"
multiplayer_window.auction_loan_tooltip = "Ditt saldo och ditt banklån"
multiplayer_window.auction_no_money = "Du har inte råd med nästa bud."
multiplayer_window.auction_no_money_loan = "Du har inte råd med nästa bud: låna med + nedan."
multiplayer_window.auction_not_sold = "Tomt %d såldes inte."
multiplayer_window.auction_out = "ute"
multiplayer_window.auction_pass = "Hoppa av"
multiplayer_window.auction_paused = "Spelet står still under auktionen."
multiplayer_window.auction_price = "Pris $%d, varje bud $%d mer"
multiplayer_window.auction_repay_tooltip = "Betala tillbaka $5,000 av lånet"
multiplayer_window.auction_sold = "Tomt %d såldes till %s för $%d."
multiplayer_window.auction_started = "%s vill ha tomt %d. Andra spelare kan vilja ha den också: den går till auktion."
multiplayer_window.auction_title = "Tomtauktion: tomt %d"
multiplayer_window.auction_wants = "%s vill köpa den markerade tomten."
multiplayer_window.auction_bid_more = "Varje bud är $%d mer."
multiplayer_window.auction_winning = "Vinnande budgivare"
multiplayer_window.auction_wait = "Auktion pågår, vänta..."
multiplayer_window.auction_watching = "Din mark gränsar inte till den här tomten."
multiplayer_window.auctions_all = "Alla"
multiplayer_window.auctions_caption = "Tomtauktioner"
multiplayer_window.auctions_near = "Omstridda"
multiplayer_window.auctions_none = "Inga"
multiplayer_window.back = "Tillbaka"
multiplayer_window.back_to_lobby = "Tillbaka till lobbyn"
multiplayer_window.bot_named = "%s (%s)"
multiplayer_window.bot_remove = "  klicka: ta bort"
multiplayer_window.bot_kind_easy = "lätt bot"
multiplayer_window.bot_kind_normal = "normal bot"
multiplayer_window.bot_kind_hard = "svår bot"
multiplayer_window.bot_menu_easy = "Lätt"
multiplayer_window.bot_menu_normal = "Normal"
multiplayer_window.bot_menu_hard = "Svår"
multiplayer_window.bot_starting = "en bot startar..."
multiplayer_window.caption = "Flerspelare"
multiplayer_window.cert_changed_help = "Certifikatet för %s är inte det som spelet kom ihåg från förra gången. Antingen har servern satts upp på nytt, eller så står någon mellan dig och servern. Spelet anslöt inte. Om du vet att servern har ett nytt certifikat, ta bort dess rad i %s och anslut igen."
multiplayer_window.chat_private_in = "%s (till dig): %s"
multiplayer_window.chat_private_out = "Till %s: %s"
multiplayer_window.chat_team_in = "%s (till laget): %s"
multiplayer_window.chat_team_out = "Till laget: %s"
multiplayer_window.chat_to = "Till %s:"
multiplayer_window.chat_to_all = "Till alla:"
multiplayer_window.chat_to_team = "Till laget:"
multiplayer_window.chat_to_allies = "Till allierade:"
multiplayer_window.chat_allies_in = "%s (till allierade): %s"
multiplayer_window.chat_allies_out = "Till allierade: %s"
multiplayer_window.clear_destroyed_room = "Röja bort det förstörda rummet för $%d? Utrymmet blir då ledigt för något annat."
multiplayer_window.colour_names[1] = "Gul"
multiplayer_window.colour_names[2] = "Röd"
multiplayer_window.colour_names[3] = "Lila"
multiplayer_window.colour_names[4] = "Vit"
multiplayer_window.colour_names[5] = "Grön"
multiplayer_window.colour_names[6] = "Blå"
multiplayer_window.colour_names[7] = "Turkos"
multiplayer_window.colour_names[8] = "Svart"
multiplayer_window.connect = "Anslut"
multiplayer_window.connecting = "Ansluter till %s..."
multiplayer_window.continue_save = "Fortsätt: %s"
multiplayer_window.continuing = "sparat %s"
multiplayer_window.create = "Skapa"
multiplayer_window.data_mismatch_help = "Serverns Theme Hospital-filer kommer från en annan utgåva av spelet än dina (nivåerna och flerspelarkartorna skiljer sig åt), och spel med båda skulle inte hålla sig lika. Peka CorsixTH på samma utgåva som serverns (Alternativ, Mappar, Theme Hospital-mappen), till exempel GOG-versionen, och anslut igen."
multiplayer_window.disconnect = "Koppla från"
multiplayer_window.download = "Ladda ner %s från GitHub"
multiplayer_window.emergency_refused = "Att tacka nej till akutfallet kostade sjukhuset %d i anseende."
multiplayer_window.encrypted = "Krypterad anslutning (TLS)"
multiplayer_window.every_plot_auctioned = "alla tomter auktioneras"
multiplayer_window.game_options = "Spelalternativ"
multiplayer_window.goal_limit = "gräns:"
multiplayer_window.goal_other.balance = "%s: saldo $%d (%s $%d)"
multiplayer_window.goal_other.num_cured = "%s: %d botade patienter (%s %d)"
multiplayer_window.goal_other.percentage_cured = "%s: %d%% av patienterna botade (%s %d%%)"
multiplayer_window.goal_other.percentage_killed = "%s: %d%% av patienterna dog (%s %d%%)"
multiplayer_window.goal_other.reputation = "%s: anseende %d (%s %d)"
multiplayer_window.goal_other.value = "%s: sjukhusvärde $%d (%s $%d)"
multiplayer_window.goal_target = "mål:"
multiplayer_window.goals_done = "uppnått"
multiplayer_window.goals_failed_other = "%s har misslyckats med den här nivåns mål. Hjälp till att rätta till det till slutet av nästa år (pengar eller personal), annars förlorar hela laget."
multiplayer_window.goals_failed_team = "Ditt sjukhus har misslyckats med den här nivåns mål. Rätta till det till slutet av nästa år, annars förlorar hela laget. De andra spelarna kan skicka pengar eller personal till dig."
multiplayer_window.goals_failing = "misslyckas"
multiplayer_window.goals_open = "-"
multiplayer_window.goals_reached_loan = "Ditt sjukhus uppfyller alla den här nivåns mål men är fortfarande skyldigt banken $%d. Betala av lånet (klicka på dina pengar längst ner) så räknas målen som uppnådda."
multiplayer_window.goals_reached_other = "%s har uppnått den här nivåns mål. Återstår: %s."
multiplayer_window.goals_reached_team = "Ditt sjukhus har uppnått den här nivåns mål! Återstår: %s."
multiplayer_window.goals_recovered = "%s misslyckas inte längre med den här nivåns mål."
multiplayer_window.helpers_off = "Allierade bottar bygger: av"
multiplayer_window.helpers_on = "Allierade bottar bygger: på"
multiplayer_window.hold_left = "Spelet fortsätter senast om %s."
multiplayer_window.hold_win = "Väntar på att %s ska svara på faxet..."
multiplayer_window.hold_year = "Väntar på att %s ska stänga årsrapporten..."
multiplayer_window.is_ready = "redo"
multiplayer_window.join = "Gå med"
multiplayer_window.keep_playing = "Fortsätt spela"
multiplayer_window.kick_player = "Ta bort %s från rummet"
multiplayer_window.kicked = "%s, rummets ägare, tog bort dig från rummet."
multiplayer_window.leave = "Lämna rummet"
multiplayer_window.level = "Nivå %d"
multiplayer_window.level7_breakthrough = "Medicinskt genombrott: %s upptäckte %s först och får $%d."
multiplayer_window.level7_breakthrough_bonus = "Genombrottsbonus"
multiplayer_window.level7_job_fair = "Jobbmässan är öppen: specialister finns på anställningslistan den här månaden."
multiplayer_window.level7_job_fair_soon = "En jobbmässa öppnar nästa månad: kirurger, psykiatrar, forskare och konsulter hamnar på anställningslistan. Först till kvarn."
multiplayer_window.level7_quarter = "Hälsoministeriets rankning: %s botade flest patienter det här kvartalet (%d) och ökar sitt anseende."
multiplayer_window.level7_race_bonus = "Bonus för tävlingsakutfall"
multiplayer_window.level7_race_emergency = "Ett tävlingsakutfall: alla sjukhus får samma akutfall nu. Den första som räddar alla patienter får $%d och ökat anseende."
multiplayer_window.level7_race_won = "%s räddade alla patienter i tävlingsakutfallet först och får $%d."
multiplayer_window.level7_rat_bounty = "Råttpremie"
multiplayer_window.level7_trick_of_month = "Månadens trick: %s kostar halva priset tills månaden är slut."
multiplayer_window.level7_truce_over = "Vapenvilan är slut: nu kan fula tricks köpas (FLERSPELARE > FULA TRICKS)."
multiplayer_window.level_intro_6 = "Akutfall! Sjukhusen i den här staden tar emot alla akutfall som helikoptern kan flyga in. Under det första året kommer de fyra gånger i månaden, till vart och ett av dina sjukhus i tur och ordning: uppblåsta huvuden och psykfall från februari (och några till apoteket), operationsfall från maj, slappa tungor och benbrott från juni. I maj får alla sjukhus patienter med slapp tunga, så forska fram tungkliniken i god tid. Att tacka nej till ett akutfall kostar anseende, men att förlora patienter på grund av dem ses mer mellan fingrarna än vanligt, och du kan skicka akutpatienter vidare till en väns sjukhus som kan bota dem. Färre vanliga patienter kommer så länge akutfallen pågår; från andra året kommer fler, och epidemier sveper över staden varannan eller var tredje månad. Råttorna trivs här också. Anställ konsulter medan du kan: från nionde månaden är det bara juniorläkare som söker jobb. För att vinna behöver varje sjukhus 550 i anseende, $60,000 på banken, 150 botade patienter, en botningsgrad på 40 procent och det sjukhusvärde som visas i Framstegsrapporten."
multiplayer_window.level_intro_7 = "Hänsynslöst. Alla sjukhus i den här staden vill vara bäst, och inget av dem spelar rent. Det råder vapenvila till mars; sedan öppnas de fula tricksen månad för månad: råttattacker, smutskastningskampanjer och trasiga pannor först, onda vaktmästare, epidemier och spionage från juni, påtvingade akutfall och headhunters från september, och den starkaste nivån av varje trick från andra året. Varje månad säljs ett trick till halva priset, det sjukhus som ligger sist betalar hälften för alla, och ledaren betalar hälften så mycket till. Värt att slåss om: jobbmässor i april, oktober, nästa april och nästa oktober ger kirurger, psykiatrar, forskare och konsulter på anställningslistan, först till kvarn. I augusti, februari och nästa augusti får alla sjukhus samma akutfall på en gång, och den första som räddar alla patienter får $10,000 och ökat anseende. Den första som upptäcker röntgen, skannern eller blodmaskinen får också $10,000 (stulna ritningar räknas inte), och varje kvartal ökar anseendet för det sjukhus som botat flest patienter. Råttor som en rival skickat ger $100 styck när de skjuts. Maskiner slits ut snabbare här, och fyra jordbävningar skakar staden, var och en starkare än den förra. För att vinna behöver ett sjukhus 650 i anseende, $150,000 på banken, 300 botade patienter, en botningsgrad på 55 procent och det sjukhusvärde som visas i Framstegsrapporten. Med fyra spelare är staden Matroftts karta."
multiplayer_window.level_intro_8 = "Lagstaden, Matroftts karta, är gjord för två mot två: de fyra sjukhusen ligger parvis mitt i staden, lagkamraterna sida vid sida, med gott om tomter till salu åt alla håll. Lägg vännerna i samma lag och tävla mot det andra paret. För att vinna behöver varje sjukhus 650 i anseende, $100,000 på banken, 200 botade patienter, en botningsgrad på 50 procent och det sjukhusvärde som visas i Framstegsrapporten. Med två eller tre spelare spelas den på en annan stads karta."
multiplayer_window.level_intro_9 = "Korsvägen, Matroftts karta, har plats för åtta: staden är indelad i tre rader om tre, med åtta sjukhus som redan har murar, runt fyra små tomter till salu i mitten, där stigarna korsas. De fyra hörnsjukhusen är lite större. Med fyra spelare eller färre tas bara hörnen, och de andra sjukhusen är också till salu. Patienterna kommer in från stadens alla kanter. För att vinna behöver varje sjukhus ett rykte på 650, $150 000 på banken, 300 botade patienter, en botningsgrad på 55 procent och det sjukhusvärde som visas i framstegsrapporten."
multiplayer_window.level_rats_notice = "Råttor! En flock har tagit sig in på sjukhuset. Klicka på dem för att skjuta dem innan de förökar sig i skräpet."
multiplayer_window.level_slack_tongue_warning = "Rapporter kommer in om slappa tungor i hela staden. I maj får alla sjukhus akutfall med slapp tunga: forska fram tungkliniken innan dess."
multiplayer_window.level_won_end = "Du vann nivån. Bra jobbat!"
multiplayer_window.levels_caption = "Nivåer"
multiplayer_window.levels_choose = "Välj nivå %d"
multiplayer_window.levels_events = "HÄNDELSER: %s"
multiplayer_window.levels_from_campaign = "Rum, sjukdomar och forskning som i %s (kampanjnivå %d)."
multiplayer_window.levels_goal_balance = "$%s på banken"
multiplayer_window.levels_goal_cure_rate = "Botningsgrad %d%%"
multiplayer_window.levels_goal_cured = "%d botade"
multiplayer_window.levels_goal_reputation = "Anseende %d"
multiplayer_window.levels_goal_value = "Värde +$%s"
multiplayer_window.levels_goals = "För att vinna:"
multiplayer_window.levels_legend = "Färgade: starttomter. Grå: till salu."
multiplayer_window.levels_map_by = "Karta av %s"
multiplayer_window.levels_map_players = "Karta för %d spelare"
multiplayer_window.levels_money = "Pengar: $%s"
multiplayer_window.levels_no_map = "Den här kartan finns inte i din Theme Hospital-data."
multiplayer_window.levels_several = "Flera sjukhus"
multiplayer_window.levels_shared = "Ett gemensamt sjukhus"
multiplayer_window.levels_shared_note = "Kampanjnivå %d: ett sjukhus som alla bygger tillsammans, med kampanjens mål."
multiplayer_window.load_caption = "Ladda ett flerspelarspel"
multiplayer_window.load_game = "Ladda MP-spel"
multiplayer_window.loading = "LADDAR..."
multiplayer_window.locked = "  (lösenord)"
multiplayer_window.looking_at = "Tittar på %s"
multiplayer_window.measuring = "Mäter anslutningen..."
multiplayer_window.menu_caption = "  FLERSPELARE  "
multiplayer_window.menu_chat = "  SKICKA MEDDELANDE (%1%)  "
multiplayer_window.menu_colours = "  SPELARFÄRGER  "
multiplayer_window.menu_colours_all = "  ALLAS FOLK  "
multiplayer_window.menu_colours_off = "  AV  "
multiplayer_window.menu_bot_chat = "  BOTTARNAS PRAT  "
multiplayer_window.menu_bot_chat_all = "  ALLT  "
multiplayer_window.menu_bot_chat_auto = "  UTAN SMÅPRAT FRÅN 3 BOTTAR  "
multiplayer_window.menu_bot_chat_useful = "  UTAN SMÅPRAT  "
multiplayer_window.menu_bot_chat_off = "  AV  "
multiplayer_window.menu_colours_others = "  ANDRA SPELARES FOLK  "
multiplayer_window.menu_players = "  SPELARE  "
multiplayer_window.menu_research = "  DELA FORSKNING  "
multiplayer_window.menu_sabotage = "  FULA TRICKS  "
multiplayer_window.menu_trade = "  HANDLA MED ANDRA SPELARE  "
multiplayer_window.mode_competitive = "Tävling: var och en för sig"
multiplayer_window.mode_coop = "Samarbete: alla vinner tillsammans"
multiplayer_window.mode_mixed = "Lagtävling"
multiplayer_window.mode_shared = "Ett gemensamt sjukhus"
multiplayer_window.mode_teams = "Tävling mellan två lag"
multiplayer_window.mode_teamshared = "Tävling mellan lagsjukhus"
multiplayer_window.money_received = "Pengar från %s"
multiplayer_window.money_received_note = "%s skickade $%d till dig."
multiplayer_window.money_sent = "Pengar skickade till %s"
multiplayer_window.mp_level = "%s (med flera sjukhus: nivå %d)"
multiplayer_window.name = "Ditt namn"
multiplayer_window.new_room = "Nytt rum"
multiplayer_window.no_auctions = "inga auktioner"
multiplayer_window.no_helper_building = "bottar bygger inte"
multiplayer_window.no_rooms = "Inga rum ännu. Skapa ett nedan."
multiplayer_window.no_sharing = "ingen delning"
multiplayer_window.no_socket = "Den här versionen saknar nätverksstöd (LuaSocket saknas)."
multiplayer_window.no_tricks = "inga tricks"
multiplayer_window.not_encrypted = "Inte krypterad"
multiplayer_window.not_encrypted_build = "Inte krypterad: det här spelet har inte LuaSec"
multiplayer_window.not_encrypted_server = "Inte krypterad: den här servern har inget certifikat"
multiplayer_window.not_ready = "inte redo"
multiplayer_window.offer_ability = "Skicklighet: %d%%"
multiplayer_window.offer_accept = "Acceptera"
multiplayer_window.offer_accept_pay = "Betala $%d"
multiplayer_window.offer_accept_price = "Acceptera och betala $%d"
multiplayer_window.offer_accepted_note = "%s accepterade: %s."
multiplayer_window.offer_accepted_price_note = "%s accepterade: %s, för $%d."
multiplayer_window.offer_caption = "Erbjudande från %s"
multiplayer_window.offer_decline = "Neka"
multiplayer_window.offer_declined_note = "%s tackade nej: %s."
multiplayer_window.offer_free_banner = "GRATIS: den här personalen kostar inget"
multiplayer_window.offer_gone_note = "%s finns inte kvar."
multiplayer_window.offer_happy = "Humör: %d%%"
multiplayer_window.offer_health = "Hälsa: %d%%"
multiplayer_window.offer_illness = "Sjukdom: %s"
multiplayer_window.offer_job = "Jobb: %s"
multiplayer_window.offer_later = "Senare"
multiplayer_window.offer_no_money_note = "Du har inte råd med de $%d som begärs för %s."
multiplayer_window.offer_no_money_sender_note = "%s hade inte råd med priset för %s."
multiplayer_window.offer_no_skills = "Specialkunskaper: inga"
multiplayer_window.offer_not_diagnosed = "Inte diagnostiserad än (%d%% klart)"
multiplayer_window.offer_patient_known = "en patient med %s"
multiplayer_window.offer_patient_line = "%s skickar en patient till dig:"
multiplayer_window.offer_patient_unknown = "en odiagnostiserad patient"
multiplayer_window.offer_price_banner = "PRIS: $%d, betalas bara om du accepterar"
multiplayer_window.offer_price_line = "PRIS: $%d. Det är vad de begär för den här personalen."
multiplayer_window.offer_raise = "Ber om löneökning"
multiplayer_window.offer_sent_note = "%s erbjöds till %s. Väntar på svar."
multiplayer_window.offer_sent_price_note = "%s erbjöds till %s för $%d. Väntar på svar."
multiplayer_window.offer_show = "Visa"
multiplayer_window.offer_skills = "Specialkunskaper: %s"
multiplayer_window.offer_staff_line = "%s erbjuder dig en i personalen:"
multiplayer_window.offer_tired = "Trötthet: %d%%"
multiplayer_window.offer_wage = "Lön: $%d i månaden"
multiplayer_window.options_close = "Stäng"
multiplayer_window.options_host_only = "Bara värden ändrar dessa."
multiplayer_window.options_off_line = "Alternativ: %s"
multiplayer_window.other_build = "  (annan spelversion)"
multiplayer_window.owner_mark = " (värd)"
multiplayer_window.password = "Lösenord"
multiplayer_window.password_clear = "Inte krypterad: lösenordet skickas i klartext. Tryck igen för att skicka."
multiplayer_window.patient_arrived_note = "En patient som %s skickat har kommit."
multiplayer_window.patient_on_the_way = "Skickad till %s"
multiplayer_window.places[1] = "1:a"
multiplayer_window.places[2] = "2:a"
multiplayer_window.places[3] = "3:e"
multiplayer_window.places[4] = "4:e"
multiplayer_window.places[5] = "5:e"
multiplayer_window.places[6] = "6:e"
multiplayer_window.places[7] = "7:e"
multiplayer_window.places[8] = "8:e"
multiplayer_window.player_away_note = "%s har lämnat: sjukhuset räknas inte med i lagets mål förrän spelaren kommer tillbaka (samma rum, samma namn)."
multiplayer_window.player_back_note = "%s är tillbaka: sjukhuset räknas med i lagets mål igen."
multiplayer_window.player_line = "%s%s   %s ms   %s"
multiplayer_window.players = "%d spelare"
multiplayer_window.players_balance = "Saldo"
multiplayer_window.players_behind = "%d timmar efter"
multiplayer_window.players_caption = "Spelare"
multiplayer_window.players_goals = "Mål"
multiplayer_window.players_hospital = "Sjukhus"
multiplayer_window.players_left = "lämnade spelet"
multiplayer_window.players_ms = "%d ms"
multiplayer_window.players_name = "Spelare"
multiplayer_window.players_note = "Ping: medelvärde de senaste 10 sekunderna. Värde: sjukhusvärdet (ett nivåmål)."
multiplayer_window.players_ping = "Ping"
multiplayer_window.players_playing = "spelar"
multiplayer_window.players_quiet = "inget svar på %d s"
multiplayer_window.players_reputation = "Ans."
multiplayer_window.players_status = "Status"
multiplayer_window.players_team = "Lag"
multiplayer_window.players_value = "Värde"
multiplayer_window.players_waiting = "Väntar på serverns lista..."
multiplayer_window.players_you = "du"
multiplayer_window.plot_bought_transaction = "Mark från %s (tomt %d)"
multiplayer_window.plot_give_button = "Erbjud tomten"
multiplayer_window.plot_give_cancel = "Avbryt"
multiplayer_window.plot_give_caption = "Överlåt tomt %d"
multiplayer_window.plot_give_free = "Pris: gratis"
multiplayer_window.plot_give_hint = "Ge den här tomten till en allierad, gratis eller för ett pris"
multiplayer_window.plot_give_none = "Det finns ingen att överlåta en tomt till."
multiplayer_window.plot_give_offered = "Erbjuden. Tomten byter ägare om den andra spelaren accepterar."
multiplayer_window.plot_give_price = "Pris: $%d"
multiplayer_window.plot_give_to = "Till vilken allierad:"
multiplayer_window.plot_given_transaction = "Mark till %s (tomt %d)"
multiplayer_window.plot_offer_accepted_note = "%s accepterade tomt %d."
multiplayer_window.plot_offer_accepted_price_note = "%s accepterade tomt %d för $%d."
multiplayer_window.plot_offer_declined_note = "%s nekade tomt %d."
multiplayer_window.plot_offer_free_line = "GRATIS: ingen kostnad för den här tomten."
multiplayer_window.plot_offer_gone_note = "Erbjudandet på tomt %d är ogiltigt: saker har ändrats."
multiplayer_window.plot_offer_line = "%s erbjuder dig tomt %d (%d rutor mark)."
multiplayer_window.plot_offer_no_money_note = "Du har inte råd med de $%d som begärs för tomt %d."
multiplayer_window.plot_offer_no_money_sender_note = "%s hade inte råd med tomt %d."
multiplayer_window.plot_offer_price_line = "PRIS: $%d, betalas bara om du accepterar."
multiplayer_window.plot_offer_sent_note = "Tomt %d erbjöds till %s som gåva. Väntar på svar."
multiplayer_window.plot_offer_sent_price_note = "Tomt %d erbjöds till %s för $%d. Väntar på svar."
multiplayer_window.plot_received_note = "Tomt %d är din nu, från %s."
multiplayer_window.plot_sell_hint = "Sälj den här tomten tillbaka till banken (den måste vara tom)"
multiplayer_window.plot_sell_question = "Vill du sälja den här tomten? Du får $%d tillbaka."
multiplayer_window.plot_sold_note = "Tomt %d såldes tillbaka till banken för $%d."
multiplayer_window.plot_sold_others_note = "%s sålde tillbaka tomt %d. Den är till salu igen."
multiplayer_window.plot_sold_transaction = "Tomt %d såld tillbaka"
multiplayer_window.race_and = " och "
multiplayer_window.race_failing = "Ditt sjukhus har misslyckats med den här nivåns mål. Rätta till det till slutet av nästa år, annars är du ute ur tävlingen."
multiplayer_window.race_failing_other = "%s har misslyckats med den här nivåns mål; är ute om det misslyckas igen nästa år."
multiplayer_window.race_left_end = "Du lämnade tävlingen. De andra spelar vidare om nästa placeringar."
multiplayer_window.race_out[1] = "Dåliga nyheter."
multiplayer_window.race_out[2] = "Ditt sjukhus misslyckades med den här nivåns mål två år i rad: det är ute ur tävlingen, på %s plats."
multiplayer_window.race_out[3] = "Tillbaka till lobbyn, eller titta på de andra?"
multiplayer_window.race_out_other = "%s misslyckades med målen två år i rad och är ute ur tävlingen (%s plats)."
multiplayer_window.race_out_short = "ute"
multiplayer_window.race_over[1] = "Tävlingen är slut. Slutresultat:"
multiplayer_window.race_over[2] = "Tillbaka till lobbyn, eller fortsätta spela?"
multiplayer_window.race_over_won = "Grattis, ditt lag har vunnit tävlingen! Slutresultat:"
multiplayer_window.race_placed_other = "%s har uppnått den här nivåns mål: %s plats. Tävlingen fortsätter."
multiplayer_window.race_standing = "%s %s"
multiplayer_window.race_standing_out = " (ute)"
multiplayer_window.race_watch = "Titta"
multiplayer_window.race_won[1] = "Grattis!"
multiplayer_window.race_won[2] = "Ditt sjukhus har uppnått den här nivåns mål: %s plats."
multiplayer_window.race_won[3] = "De andra tävlar vidare om nästa placeringar. Tillbaka till lobbyn, eller titta?"
multiplayer_window.race_won_question = "De andra tävlar vidare om nästa placeringar. Vill du tillbaka till lobbyn?"
multiplayer_window.race_won_allies = "Du och %s klarade det! Bra jobbat!"
multiplayer_window.race_won_allies_first = "Du och %s klarade det! Fint jobbat!"
multiplayer_window.race_won_first = "Ditt sjukhus är först med att uppnå alla mål i %s. Du har vunnit tävlingen!"
multiplayer_window.race_won_place = "Ditt sjukhus har uppnått alla mål i %s: %s plats."
multiplayer_window.race_won_team_first = "Ditt lag är först med att uppnå alla mål i %s. Du har vunnit tävlingen!"
multiplayer_window.race_won_team_place = "Ditt lag har uppnått alla mål i %s: %s plats."
multiplayer_window.race_won_together = "Ni klarade det tillsammans! Bra jobbat!"
multiplayer_window.race_won_together_first = "Ni klarade det tillsammans! Fint jobbat!"
multiplayer_window.race_won_well_done = "Bra jobbat!"
multiplayer_window.rat_attacks = "råttattacker"
multiplayer_window.rats_off = "Råttattack (tävlingar): inte tillåten"
multiplayer_window.rats_on = "Råttattack (tävlingar): tillåten"
multiplayer_window.ready = "Redo"
multiplayer_window.rebuild_destroyed_room = "Det här rummet förstördes. Röja bort det för $%d och bygga det igen?"
multiplayer_window.recommendation = "Upp till %s; handlingar tar %s ms"
multiplayer_window.refer_button = "Skicka patient"
multiplayer_window.refer_choose = "Skicka till vilket sjukhus?"
multiplayer_window.refer_fax_choice = "Skicka till ett annat sjukhus"
multiplayer_window.referral_cured_here_note = "Du botade en patient som %s skickat: +%d extra anseende."
multiplayer_window.referral_cured_note = "%s botade patienten du skickade: +%d anseende."
multiplayer_window.refresh = "Uppdatera"
multiplayer_window.rep_amount = "Poäng: %d"
multiplayer_window.rep_give_button = "Ge dem %d av dina anseendepoäng"
multiplayer_window.rep_given_note = "Du gick i god för %s: du gav %d anseendepoäng."
multiplayer_window.rep_received_note = "%s går i god för ditt sjukhus: du fick %d anseendepoäng."
multiplayer_window.rep_rivals = "Bara allierade kan gå i god för varandra."
multiplayer_window.rep_sent = "Klart. Poängen flyttas om en stund."
multiplayer_window.rep_vouch_caption = "Gå i god för: ge av ditt anseende"
multiplayer_window.repair_destroyed_room = "Det här rummet förstördes. Reparera det för $%d, priset för ett nytt med möbler? (Nej: röj bort det.)"
multiplayer_window.research_accept = "Jag ACCEPTERAR den här forskningskunskapen"
multiplayer_window.research_accept_price = "Jag ACCEPTERAR den här forskningskunskapen för $%d"
multiplayer_window.research_accepted_note = "%s accepterade din forskning (betalade $%d)."
multiplayer_window.research_all = "Alla"
multiplayer_window.research_and_more = "och %d till"
multiplayer_window.research_bought_transaction = "Forskning från %s"
multiplayer_window.research_caption = "Dela forskning med %s"
multiplayer_window.research_decline = "Jag AVSLÅR den här forskningskunskapen"
multiplayer_window.research_declined_note = "%s tackade nej till din forskning."
multiplayer_window.research_free = "Pris: gratis"
multiplayer_window.research_free_line = "GRATIS: den här överföringen kostar inget."
multiplayer_window.research_item_drug = "Medicin: %s"
multiplayer_window.research_item_machine = "Förbättrad %s"
multiplayer_window.research_known_note = "Du kan redan all den forskningen."
multiplayer_window.research_known_sender_note = "%s kunde redan all den forskningen."
multiplayer_window.research_next = "Mer"
multiplayer_window.research_no_money_note = "Du har inte råd med den forskningen ($%d)."
multiplayer_window.research_no_money_sender_note = "%s hade inte råd med din forskning."
multiplayer_window.research_none = "Du har ingen forskning som saknas hos spelaren."
multiplayer_window.research_none_selected = "Välj först någon forskning."
multiplayer_window.research_offer = "Erbjud"
multiplayer_window.research_offer_line = "%s vill dela följande forskning med dig:"
multiplayer_window.research_offered = "Erbjudet. Väntar på svar."
multiplayer_window.research_page = "Sida %d av %d"
multiplayer_window.research_previous = "Tillbaka"
multiplayer_window.research_price = "Pris: $%d"
multiplayer_window.research_price_line = "PRIS: $%d. Du betalar bara om du accepterar."
multiplayer_window.research_received_note = "Ny forskning: %s."
multiplayer_window.research_sent_note = "Forskning erbjuden till %s. Väntar på svar."
multiplayer_window.research_sold_transaction = "Forskning såld till %s"
multiplayer_window.room_caption = "Rum: %s"
multiplayer_window.room_hint = "Samma färg: ett sjukhus. Samma lag: ni vinner tillsammans."
multiplayer_window.room_line = "%s   %d av %d   %s   nivå %s%s"
multiplayer_window.rooms_caption = "Rum på %s"
multiplayer_window.sabotage_again = "Klicka på L%d igen för att köpa det för $%d."
multiplayer_window.sabotage_alone = "Det finns ingen rival kvar att spela spratt med."
multiplayer_window.sabotage_arrived = "Din onda vaktmästare har börjat arbeta på %s."
multiplayer_window.sabotage_boiler = "Trasig panna"
multiplayer_window.sabotage_boiler_notice = "Pannan har gått sönder, och det var ingen olycka. Dina vaktmästare reparerar den: ju fler, desto snabbare."
multiplayer_window.sabotage_caption = "Fula tricks mot %s"
multiplayer_window.sabotage_caught = "Du kastade ut en vaktmästare som inte var din: %s skickade honom. Han åker tillbaka till dem."
multiplayer_window.sabotage_caught_owner = "%s fångade din onda vaktmästare. Han kommer tillbaka och jobbar för dig."
multiplayer_window.sabotage_close = "Stäng"
multiplayer_window.sabotage_done.boiler = "Pannan hos %s har gått sönder."
multiplayer_window.sabotage_done.emergency = "Ett akutfall är på väg till %s."
multiplayer_window.sabotage_done.epidemic = "De smittsamma patienterna är på väg till %s."
multiplayer_window.sabotage_done.espionage = "Din spion har varit hos %s."
multiplayer_window.sabotage_done.handyman = "Din onda vaktmästare är på väg till %s."
multiplayer_window.sabotage_done.headhunter = "Din headhunter har lagt ett bud till en i personalen hos %s."
multiplayer_window.sabotage_done.rats = "Råttorna flyttar in hos %s."
multiplayer_window.sabotage_done.smear = "Smutskastningskampanjen mot %s har börjat."
multiplayer_window.sabotage_emergency = "Akutfall"
multiplayer_window.sabotage_emergency_fax[1] = "Ett akutfall har skickats till dig, och du kan inte tacka nej."
multiplayer_window.sabotage_emergency_fax[2] = "%d patienter med %s kommer med helikopter."
multiplayer_window.sabotage_emergency_fax[3] = "Behandla så många du kan innan tiden är ute."
multiplayer_window.sabotage_epidemic = "Epidemi"
multiplayer_window.sabotage_espionage = "Spionage"
multiplayer_window.sabotage_espionage_got = "Din spion tog med sig: %s."
multiplayer_window.sabotage_espionage_notice = "Någon har kopierat filer från forskningsavdelningen."
multiplayer_window.sabotage_espionage_notice_3 = "Någon har brutit sig in på forskningsavdelningen: filer kopierade, och den pågående forskningen har satts tillbaka till hälften."
multiplayer_window.sabotage_handyman = "Ond vaktmästare"
multiplayer_window.sabotage_handyman_hint = {"Din utrustning har gått sönder mycket på sistone. Kan det finnas en ond vaktmästare på ditt sjukhus?", "Det går hela tiden fel här. Är varje vaktmästare verkligen din? Avskeda en som inte är det.", "En vaktmästare som ingen minns att ha anställt strövar runt i dina korridorer. Titta på dina vaktmästare: en främling kan kastas ut."}
multiplayer_window.sabotage_headhunter = "Headhunter"
multiplayer_window.sabotage_headhunter_left = "%s har gått till ett bättre erbjudande."
multiplayer_window.sabotage_headhunter_notice = "%s har fått ett bättre jobberbjudande från ett annat sjukhus och begär en löneökning på $%d. Gå med på det inom 10 dagar, annars slutar personen."
multiplayer_window.sabotage_headhunter_won = "%s lämnade sitt sjukhus och står på anställningslistan: anställ personen inom %d dagar, innan någon annan får."
multiplayer_window.sabotage_level = "L%d  $%d"
multiplayer_window.sabotage_level_locked = "L%d  månad %d"
multiplayer_window.sabotage_level_off = "L%d  av"
multiplayer_window.sabotage_levels.boiler[1] = "Deras panna går sönder: för kallt på vintern, för varmt på sommaren, tills deras vaktmästare har reparerat den (en kort reparation)."
multiplayer_window.sabotage_levels.boiler[2] = "Deras panna går sönder, ungefär dubbelt så länge. Fler vaktmästare reparerar den snabbare."
multiplayer_window.sabotage_levels.boiler[3] = "Deras panna går sönder ordentligt: en lång reparation. Fler vaktmästare reparerar den snabbare."
multiplayer_window.sabotage_levels.emergency[1] = "Ett akutfall de inte kan tacka nej till: 3 patienter med helikopter, med en sjukdom de känner till."
multiplayer_window.sabotage_levels.emergency[2] = "Ett akutfall de inte kan tacka nej till: 6 patienter med helikopter, med en sjukdom de känner till."
multiplayer_window.sabotage_levels.emergency[3] = "Ett akutfall de inte kan tacka nej till: 10 patienter med helikopter, kanske med en sjukdom de inte har upptäckt."
multiplayer_window.sabotage_levels.epidemic[1] = "2 smittsamma patienter med samma sjukdom kommer till deras sjukhus."
multiplayer_window.sabotage_levels.epidemic[2] = "4 smittsamma patienter med samma sjukdom kommer till deras sjukhus."
multiplayer_window.sabotage_levels.epidemic[3] = "7 smittsamma patienter med samma sjukdom kommer till deras sjukhus."
multiplayer_window.sabotage_levels.espionage[1] = "Kopiera en förbättring av en medicin eller maskin som de har och du inte har: du väljer vilken."
multiplayer_window.sabotage_levels.espionage[2] = "Kopiera en upptäckt (en maskin eller ett rum) som de har och du inte har: du väljer vilken."
multiplayer_window.sabotage_levels.espionage[3] = "Kopiera två av deras förbättringar eller upptäckter (du väljer) och sätt tillbaka deras pågående forskning till hälften."
multiplayer_window.sabotage_levels.handyman[1] = "En vaktmästare som ser ut som deras men inte gör något jobb, i 4 månader. Om de hittar honom och sparkar honom kommer han och jobbar för dig."
multiplayer_window.sabotage_levels.handyman[2] = "Som L1, och han slänger skräp i deras korridorer två gånger om dagen, i 3 månader."
multiplayer_window.sabotage_levels.handyman[3] = "Som L2, och var tredje dag låtsas han reparera en maskin och lämnar den nästan trasig. Stannar i 2 månader."
multiplayer_window.sabotage_levels.headhunter[1] = "Deras bästa juniorläkare eller sköterska får ett bättre erbjudande: de betalar 50% löneökning inom 10 dagar, annars hamnar personen på anställningslistan (reserverad åt dig i 2 veckor)."
multiplayer_window.sabotage_levels.headhunter[2] = "Deras bästa läkare får ett bättre erbjudande: de betalar 75% löneökning inom 10 dagar, annars hamnar personen på anställningslistan (reserverad åt dig i 2 veckor)."
multiplayer_window.sabotage_levels.headhunter[3] = "Deras bästa konsult eller specialist får ett bättre erbjudande: de dubblerar lönen inom 10 dagar, annars hamnar personen på anställningslistan (reserverad åt dig i 2 veckor)."
multiplayer_window.sabotage_levels.rats[1] = "5 råttor flyttar in. Medan de springer omkring kostar de dem upp till 1 i anseende om dagen (i upp till 30 dagar), tills de skjutits."
multiplayer_window.sabotage_levels.rats[2] = "10 råttor flyttar in. Medan de springer omkring kostar de dem upp till 2 i anseende om dagen (i upp till 30 dagar), tills de skjutits."
multiplayer_window.sabotage_levels.rats[3] = "20 råttor flyttar in. Medan de springer omkring kostar de dem upp till 3 i anseende om dagen (i upp till 30 dagar), tills de skjutits."
multiplayer_window.sabotage_levels.smear[1] = "Dålig press i en månad: 3 av 10 av deras nya patienter går till de andra sjukhusen i stället."
multiplayer_window.sabotage_levels.smear[2] = "Dålig press i 2 månader: 4 av 10 av deras nya patienter går till de andra sjukhusen i stället."
multiplayer_window.sabotage_levels.smear[3] = "Dålig press i 3 månader: hälften av deras nya patienter går till de andra sjukhusen i stället."
multiplayer_window.sabotage_locked_tooltip = "På den här nivån kan det köpas från månad %d i spelet."
multiplayer_window.sabotage_next = "Nästa rival"
multiplayer_window.sabotage_off_tooltip = "Värden tillät inte det här tricket i det här spelet (spelalternativ)."
multiplayer_window.sabotage_pick = "Klicka på en nivå för att se vad den gör. Klicka igen för att köpa den."
multiplayer_window.sabotage_rats = "Råttattack"
multiplayer_window.sabotage_rats_notice = "Råttor! En flock har flyttat in på sjukhuset. Medan de springer omkring kostar de anseende varje dag: klicka på dem för att skjuta dem."
multiplayer_window.sabotage_rats_reminder = "%d råttor springer fortfarande omkring på sjukhuset och kostar anseende varje dag."
multiplayer_window.sabotage_rats_reminders = {"%d råttor springer fortfarande omkring på sjukhuset och kostar anseende varje dag. Klicka på dem för att skjuta dem.", "Råttorna är kvar, %d stycken, och patienterna pratar om det. Skjut dem!", "Ditt sjukhus har fortfarande %d råttor. Varje dag de stannar kostar dig anseende."}
multiplayer_window.sabotage_refused = "Det fula tricket går inte att göra: %s."
multiplayer_window.sabotage_sent = "Beställt. Du betalar när det är gjort."
multiplayer_window.sabotage_smear = "Smutskastning"
multiplayer_window.sabotage_smear_notice = "Dålig press: en smutskastningskampanj mot sjukhuset håller borta en del patienter i %d månad(er)."
multiplayer_window.sabotage_smear_over = "Smutskastningskampanjen är slut: patienterna kommer till sjukhuset som förut."
multiplayer_window.sabotage_spy_caption = "Spionera på %s: välj %d"
multiplayer_window.sabotage_spy_pick = "Välj vad din spion ska kopiera och tryck på Stjäl."
multiplayer_window.sabotage_spy_steal = "Stjäl ($%d)"
multiplayer_window.sabotage_transaction = "Fula tricks"
multiplayer_window.sabotage_went_home = "Din onda vaktmästares tid hos %s är slut. Han har åkt hem."
multiplayer_window.saved_flag = "  sparat spel"
multiplayer_window.saved_note = "Spelet sparades: %s"
multiplayer_window.saving_note = "Sparar spelet på alla spelares datorer..."
multiplayer_window.select_room = "Välj ett rum först."
multiplayer_window.server = "Server"
multiplayer_window.server_eu1 = "EU1: stabil"
multiplayer_window.server_eu2 = "EU2: testversioner"
multiplayer_window.server_version = "serverns version"
multiplayer_window.share_research = "Dela forskning"
multiplayer_window.shared_won = "Att gå vidare till nästa nivå finns inte i flerspelarläget."
multiplayer_window.sharing_off = "Forskningsdelning: av"
multiplayer_window.sharing_on = "Forskningsdelning: på"
multiplayer_window.staff_arrived_note = "%s har kommit och börjar arbeta."
multiplayer_window.staff_bought_transaction = "Personal från %s"
multiplayer_window.staff_on_the_way = "På väg till %s"
multiplayer_window.staff_received_note = "%s skickade en i personalen till dig: %s"
multiplayer_window.staff_sold_transaction = "Personal till %s"
multiplayer_window.start = "Starta spelet"
multiplayer_window.team_button = "Lag %d"
multiplayer_window.team_lost = "%s misslyckades fortfarande med den här nivåns mål vid årets slut, så laget har förlorat nivån."
multiplayer_window.team_member_out = "Ditt sjukhus misslyckades med den här nivåns mål två år i rad och är ute ur tävlingen. Ditt lag tävlar vidare."
multiplayer_window.team_member_out_other = "%s misslyckades med målen två år i rad och är ute ur tävlingen; dess lag tävlar vidare."
multiplayer_window.team_race_mate_reached_fax[1] = "Din lagkamrat %s har uppnått den här nivåns mål!"
multiplayer_window.team_race_mate_reached_fax[2] = "Ditt lag vinner när ditt sjukhus också kommer dit. Återstår: %s."
multiplayer_window.team_race_mate_reached_fax[3] = "Din lagkamrat kan hjälpa dig med pengar, personal eller patienter."
multiplayer_window.team_race_reached_fax[1] = "Ditt sjukhus har uppnått den här nivåns mål!"
multiplayer_window.team_race_reached_fax[2] = "Tävlingen är inte vunnen än: ditt lag vinner när alla dess sjukhus kommer dit. Återstår: %s."
multiplayer_window.team_race_reached_fax[3] = "Håll ditt sjukhus igång och hjälp dem med pengar, personal eller patienter."
multiplayer_window.team_race_reached_other = "%s har uppnått den här nivåns mål (lag %s)."
multiplayer_window.team_won[1] = "Grattis!"
multiplayer_window.team_won[2] = "Alla sjukhus har uppnått den här nivåns mål: laget har vunnit nivån."
multiplayer_window.team_won[3] = "Tillbaka till lobbyn, eller fortsätta spela?"
multiplayer_window.too_many_hospitals = "Banan rymmer %d sjukhus: dela färger"
multiplayer_window.trade_alone = "Det finns ingen att handla med."
multiplayer_window.trade_caption = "Handla med %s"
multiplayer_window.trade_close = "Stäng"
multiplayer_window.trade_free = "Pris: gratis"
multiplayer_window.trade_money_allies_only = "Pengar kan bara skickas till allierade."
multiplayer_window.running_flag = "pågår"
multiplayer_window.running_places = "pågår, %d lediga"
multiplayer_window.seats_caption = "Platser i %s"
multiplayer_window.seats_hint = "Ta över platsen från en bot eller en spelare som har gått:"
multiplayer_window.seat_on = "%s, spelar"
multiplayer_window.seat_standin = "%s (har gått, en bot spelar så länge)"
multiplayer_window.seat_left = "%s (har gått)"
multiplayer_window.players_standin = "borta - bot"
multiplayer_window.trade_next_player = "Nästa spelare"
multiplayer_window.trade_no_staff = "Du har ingen personal att skicka."
multiplayer_window.trade_offered = "Erbjudet. Personen ansluter till dig om den andra spelaren accepterar."
multiplayer_window.trade_on_the_way = "- erbjuden"
multiplayer_window.trade_price = "Pris: $%d"
multiplayer_window.trade_select_staff = "Klicka på en i personalen först."
multiplayer_window.trade_send_money = "Skicka $%d"
multiplayer_window.trade_send_staff = "Erbjud vald personal"
multiplayer_window.trade_sent = "Skickat. Det kommer fram om en stund."
multiplayer_window.trade_money_confirm = "Vill du verkligen skicka $%d till %s?"
multiplayer_window.trade_money_short = "Du har inte så mycket pengar."
multiplayer_window.tricks_off = "Fula tricks (tävlingar): av"
multiplayer_window.tricks_on = "Fula tricks (tävlingar): på"
multiplayer_window.vaccination_mode_hint = "Vaccinationsläge: klicka på de smittade patienterna så vaccinerar en sköterska dem. Högerklicka, tryck Esc eller klicka på sprutan igen för att sluta."
multiplayer_window.vote_agree = "Godkänn"
multiplayer_window.vote_asked = "Du bad de andra att ändra hastigheten till %s."
multiplayer_window.vote_confirm = "Be de andra spelarna ändra spelets hastighet till %s?"
multiplayer_window.vote_decline = "Neka"
multiplayer_window.vote_declined = "%s nekade ändringen av hastigheten till %s."
multiplayer_window.vote_lapsed = "För få spelare höll med i tid: hastigheten förblir som den var."
multiplayer_window.vote_open = "En hastighetsändring röstas redan om."
multiplayer_window.vote_passed = "Spelarna var överens: hastigheten är nu %s."
multiplayer_window.vote_passed_paused = "Spelarna var överens om %s: spelet fortsätter i den hastigheten när det tas ur paus."
multiplayer_window.vote_request = "%s vill ändra spelhastigheten"
multiplayer_window.vote_request_speed = "till %s."
multiplayer_window.waiting_player = "väntar på en spelare..."
tooltip.main_menu.multiplayer = "Spela med andra via en flerspelarserver (experimentell)"
tooltip.multiplayer_window.bot_level = "Högerklick: en lätt, normal eller svår bot"
tooltip.multiplayer_window.ask_money = "Be en annan spelare om pengar. Spelaren bestämmer om hen betalar."
tooltip.multiplayer_window.auctions = "Värden bestämmer vilka tomter som går till auktion när en spelare vill köpa en"
tooltip.multiplayer_window.auctions_all = "Alla tomter går till auktion bland alla sjukhus som får köpa dem"
tooltip.multiplayer_window.auctions_near = "Tomter på en annan spelares sida eller intill ett annat sjukhus går till auktion; de andra köps helt enkelt"
tooltip.multiplayer_window.auctions_none = "Inga auktioner: den som frågar först köper tomten"
tooltip.multiplayer_window.colour = "Färgen på ditt sjukhus: spelare med samma färg bygger ett sjukhus tillsammans. Klicka för att ändra (värden kan ändra allas, även bottars)"
tooltip.multiplayer_window.connect = "Anslut till servern och visa dess rum"
tooltip.multiplayer_window.continue_game = "Fortsätt ett flerspelarspel som sparats tidigare (Arkiv > Spara, eller den månatliga autosparningen): välj det i listan. Utan val startar rummet ett nytt spel"
tooltip.multiplayer_window.download = "Den här servern kör en annan version av spelet: öppna dess nedladdningssida i din webbläsare"
tooltip.multiplayer_window.game_options = "Spelets alternativ: tomtauktioner och mer (värden ställer in dem)"
tooltip.multiplayer_window.helpers = "Värden bestämmer: en bot som delar sjukhus med en person bygger rum och ställer saker i korridorerna, eller lämnar det åt personen (den anställer fortfarande, betalar bonusar, delar forskning, budar på auktioner och köper tomter)"
tooltip.multiplayer_window.level = "Välj nivå i en lista med mål och karta. Ett gemensamt sjukhus spelar kampanjens nivåer; flera sjukhus spelar flerspelarnivåerna (1 till 8, ett högre nummer spelar nivå 8). Nivå 6 är Akutfall!: akutfall fyra gånger i månaden under första året, sedan epidemier; nivå 7 är Hänsynslöst, gjord för en tävling: fula tricks månad för månad, jobbmässor, tävlingsakutfall och jordbävningar; nivå 8 är Lagstaden, Matroftts karta gjord för två mot två"
tooltip.multiplayer_window.levels_players = "Kartan för så här många spelare (varje antal spelare har sin egen karta)"
tooltip.multiplayer_window.name = "Namnet som andra spelare ser"
tooltip.multiplayer_window.new_game = "Starta ett nytt spel i stället för det sparade"
tooltip.multiplayer_window.password = "Lösenord för rummet du ansluter till eller skapar (tomt: inget lösenord)"
tooltip.multiplayer_window.player_row = "Klick: visa den här spelarens sjukhus (N: nästa sjukhus)"
tooltip.multiplayer_window.chat_target = "Vem meddelandet är till: alla, ditt lag (i en kapplöpning mellan lag) eller en spelare. Klicka eller tryck Tab för nästa"
tooltip.multiplayer_window.players = "Hur många spelare rummet är för"
tooltip.multiplayer_window.rats = "Värden bestämmer: i en tävling med fula tricks får spelare släppa lös råttor på en rivals sjukhus (de kostar det anseende), eller inte"
tooltip.multiplayer_window.ready = "Tala om för värden att du är redo att starta"
tooltip.multiplayer_window.refer_button = "Erbjud den här patienten till en annan spelares sjukhus. Spelaren måste acceptera."
tooltip.multiplayer_window.send_staff = "Skicka den här personalen till en annan spelares sjukhus. Spelaren måste acceptera."
tooltip.multiplayer_window.server = "Adressen till flerspelarservern, till exempel eu2.bachelor-tech.com:47800"
tooltip.multiplayer_window.server_eu1 = "eu1.bachelor-tech.com: den senaste stabila versionen"
tooltip.multiplayer_window.server_eu2 = "eu2.bachelor-tech.com: den senaste testversionen"
tooltip.multiplayer_window.share_research = "Erbjud forskning du har till en annan spelares sjukhus, gratis eller mot betalning. Spelaren måste acceptera."
tooltip.multiplayer_window.sharing = "Värden bestämmer: spelare får dela eller sälja forskning till varandra, eller inte (som i originalspelet)"
tooltip.multiplayer_window.start = "Starta spelet för alla i rummet"
tooltip.multiplayer_window.team = "Ditt lag: samma lag vinner tillsammans, olika lag tävlar om målen och kan spela fula tricks mot varandra. Klicka för att ändra (värden kan ändra allas, även bottars)"
tooltip.multiplayer_window.tricks = "Värden bestämmer: i en tävling får spelare köpa fula tricks mot rivaler, eller inte (som i originalspelet)"
