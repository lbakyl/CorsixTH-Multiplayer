
--[[ Copyright (c) 2011 David "ChronosHD" Horváth & Adam Kirkósa

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
SOFTWARE.

-------------------------------------------------------------------------------
   A FEW NOTES
-------------------------------------------------------------------------------

As the Nowegian translation seemd very well structured, i've used that file.
Thanks for the Norwegian translators for their work.

-------------------------------------------------------------------------------
   READ BEFORE DOING ANY CHANGES
-------------------------------------------------------------------------------

Since the Hungarian language isn't in the original Theme Hospital game, this
file is split in two sections (A and B). The first section contains all the new
language strings, made by the Corsix-TH team, and the second section contains
the override translation of all the original english strings.

FORMATING AND HUNGARIAN LETTERS
This file contains UTF-8 text. Make sure your editor is set to UTF-8.


-------------------------------------------------------------------------------
    Table of Contents
-------------------------------------------------------------------------------

 -- SECTION A - NEW STRINGS

   1. Global settings
   2. Faxes
   3. Objects
   4. Menu
   5. Adviser
   6. Dynamic info
   7. Tooltip

 -- SECTION B - OLD STRINGS (OVERRIDE)

   Huge section with all original strings, translated from english.



-----------------------------------------------------------------------------]]


-------------------------------------------------------------------------------
--   SECTION A - NEW STRINGS
-------------------------------------------------------------------------------


Font("unicode")
Language("Magyar", "Hungarian", "hu", "hun")
Inherit("English")
Encoding(utf8)
IsArabicNumerals(true)


-- 2. Faxes

fax = {
  choices = {
    return_to_main_menu   = "Vissza a főmenübe",
    accept_new_level    = "Ugrás a következő pályára",
    decline_new_level    = "Pálya folytatása még egy kicsit",
  },
}

letter = {
  dear_player      = "Kedves %s",
  custom_level_completed   = "Ez igen! Minden kitűzött célt elértél ezen az egyedi pályán!",
  return_to_main_menu    = "Szeretnél visszaugrani a főmenübe, vagy inkább játszol tovább?",
}

install = {
  title       = "--------------------------------- CorsixTH Beállítások ---------------------------------",
  th_directory      = "CorsixTH-nak a futáshoz szüksége van az eredeti (teljes vagy demó) játék adatfájljaira. Kérlek az alábbi választómenü segítségével keresd ki a Theme Hospital telepítőfájljait tartalmazó könyvtárat.",
  exit        = "Kilépés",
}


-- 3. Objects
object = {
  litter       = "Szemét",
}

tooltip.fax.close     = "Ablak bezárása az üzenet törlése nélkül"
tooltip.message.button    = "Bal klikk az üzenet megnyitásához"
tooltip.message.button_dismiss  = "Bal klikk az üzenet megnyitásához, jobb klikk a figyelmen kívül hagyáshoz"

-- 4. Menu
menu_options = {
  lock_windows     = "  Ablak rögzítése  ",
  edge_scrolling     = "  Görgetés széleknél  ",
  settings       = "  Beállítások  ",
}

menu_options_game_speed.pause   = "  Játék megállítása  "

-- The demo does not contain this string
menu_file.restart     = "  Újrakezdés  "

menu_debug = {
  jump_to_level               = "  UGRÁS PÁLYÁRA  ",
  transparent_walls           = "  (%1%) ÁTLÁTSZÓ FALAK  ",
  limit_camera                = "  KAMERA HATÁROLÁSA  ",
  disable_salary_raise        = "  FIZETÉSEMELÉS KIKAPCSOLÁSA  ",
  make_debug_fax              = "  FAX HIBAKERESÉS  ",
  make_debug_patient          = "  BETEG HIBAKERESÉS  ",
  cheats                      = "  (%1%) CSALÁSOK  ",
  lua_console                 = "  (%1%) LUA KONZOL  ",
  calls_dispatcher            = "  HÍVÁS ELOSZTÓ  ",
  dump_strings                = "  (%1%) SZTRINGEK LEMENTÉSE  ",
  dump_gamelog                = "  (%1%) JÁTÉK LOG LEMENTÉSE  ",
  map_overlay                 = "  TÉRKÉP RÉTEG  ",
  sprite_viewer               = "  SPRITE NÉZEGETŐ  ",
}
menu_debug_overlay = {
  none                        = "  SEMMI  ",
  flags                       = "  ZÁSZLÓK  ",
  positions                   = "  POZÍCIÓK  ",
  heat                        = "  HŐMÉRSÉKLET  ",
  byte_0_1                    = "  BYTE 0 & 1  ",
  byte_floor                  = "  BYTE TALAPZAT  ",
  byte_n_wall                 = "  BYTE N FAL  ",
  byte_w_wall                 = "  BYTE W FAL  ",
  byte_5                      = "  BYTE 5  ",
  byte_6                      = "  BYTE 6  ",
  byte_7                      = "  BYTE 7  ",
  parcel                      = "  TELEKRÉSZ  ",
}

-- 5. Adviser
adviser = {
  room_forbidden_non_reachable_parts = "A szoba jelenlegi elhelyezése elérhetetlenné tenne bizonyos részeket a kórház területén.",
  praise = {
    plants_are_well = "Kellemes látvány. Ügyesen gondoskodtál a növényekről. Szép munka.",
    few_have_to_stand = "Majdhogynem senkinek se kell állnia a kórházadban. A betegek hálásak ezért.",
    plenty_of_benches = "Rengetek az ülőhely, úgyhogy gond egy szál se.",
    plants_thriving = "Nagyon jó. A növények virítanak. Kellemes látvány. Ha így folytatod, még trófeát is kaphatsz értük."
  },
}

-- 6. Dynamic info
dynamic_info.patient.actions.no_gp_available   = "Várakozás, hogy több általános rendelőt építs"
dynamic_info.staff.actions.heading_for       = "Ide megy: %s"
dynamic_info.staff.actions.fired = "Elbocsájtott"

-- 7. Tooltip
tooltip.objects.litter     = "Szemét: Egy haszontalan tárgy, amit a beteg azért dobott a földre, mert nem talált szemetest."

-- Misc
misc.not_yet_implemented   = "(Még nem beépített)"
misc.no_heliport       = "Nem lett még új betegség felfedezve, vagy nincs helikopterleszálló ezen a pályán."


-- Main menu
main_menu = {
  new_game     = "Új játék",
  custom_level   = "Egyedi pálya",
  load_game   = "Betöltés",
  options     = "Beállítások",
  exit       = "Kilépés",
}

tooltip.main_menu = {
  new_game = "Egy teljesen új játék kezdése az alapoktól",
  custom_level = "Saját kórház építése egy egyedi pályán",
  load_game = "Elmentett játék betöltése",
  options = "Beállítások megváltoztatása",
  exit = "Ne, ne! Kérlek ne lépj ki!",
}

load_game_window = {
  caption = "Játék betöltése",
}

tooltip.load_game_window = {
  load_game =  "%s betöltése",
  load_game_number =  "%d betöltése",
  load_autosave = "Automatikus mentés betöltése",
}

custom_game_window = {
  caption = "Egyedi játék",
}

tooltip.custom_game_window = {
  start_game_with_name = "%s pálya betöltése",
}

save_game_window = {
  caption = "Játék mentése",
  new_save_game = "Új mentés",
}

tooltip.save_game_window = {
  save_game = "%s mentés felülírása",
  new_save_game = "Írd be az új mentés nevét",
}

menu_list_window = {
  back = "Vissza",
}

tooltip.menu_list_window = {
  back = "Ablak bezárása",
}

options_window = {
  browse = "Tallózás...",
  new_th_directory = "Itt egy új Theme Hospital telepítési útvonalat adhatsz meg. Amint kiválasztottad az új könyvtárat, a játék újraindul.",
  back = "Vissza",
}
graphics_window = {
  caption = "Graphics",
  fullscreen = "Teljes képernyő",
  width = "Szélesség",
  height = "Magasság",
  cancel = "Mégse",
}

tooltip.options_window = {
  language = "%s nyelv kiválasztása",
  browse = "Másik elérési útvonal kiválasztása a Theme Hospital fájljaihoz",
  back = "Beállítások ablak bezárása",
}
tooltip.graphics_window = {
  fullscreen_button = "Kattints a teljes képernyős módba való váltáshoz",
  width = "Add meg a kívánt szélességet",
  height = "Add meg a kívánt magasságot",
}

calls_dispatcher = {
  -- Dispatcher description message. Visible in Calls Dispatcher dialog
  summary = "%d hívás; %d hozzárendelve",
  staff = "%s - %s",
  watering = "Öntözés @ %d,%d",
  repair = "%s Javítás",
  close = "Bezárás",
}

tooltip.calls_dispatcher = {
  task = "Teendők listája - kattints, hogy megnyitsd a beosztott személyzet ablakát és a teendő helyszínéhez gördülj.",
  assigned = "Ez a doboz akkor van bejelölve, ha a teendőhöz már van rendelve alkalmazott.",
  close = "Hozzárendelő ablak bezárása",
}

cheats_window = {
  caption = "Csalás",
  warning = "Figyelem: Nem fogsz bónuszpontokat kapni a pálya végén, ha csalsz!",

  cheated = {
    no = "Csalás aktív: Nem",
    yes = "Csalás aktív: Igen",
  },
  cheats = {
    money = "Pénz csalás",
    all_research = "Minden kutatás kész csalás",
    emergency = "Vészhelyzet létrehozása",
    create_patient = "Beteg létrehozása",
    end_month = "Ugrás hónap végére",
    end_year = "Ugrás év végére",
    lose_level = "Pálya elvesztése",
    win_level = "Pálya megnyerése",
  },
  close = "Bezárás",
}

tooltip.cheats_window = {
  close = "Csalás párbeszédablak bezárása",
  cheats = {
    money = "Egyenleghez $10.000 hozzáadása.",
    all_research = "Összes kutatás kész.",
    emergency = "Vészhelyzet előidézése.",
    create_patient = "Beteg létrehozása a térkép határán.",
    end_month = "Ugrás hónap végére.",
    end_year = "Ugrás év végére.",
    lose_level = "Pálya elvesztése.",
    win_level = "Pálya megnyerése.",
  }
}

new_game_window = {
  easy = "Rezidens (Könnyű)",
  medium = "Doktor (Közepes)",
  hard = "Konzuláns (Nehéz)",
  tutorial = "Oktatópálya",
  cancel = "Mégse",
}

tooltip.new_game_window = {
  easy = "Amennyiben a szimulációs játék fogalma számodra új, ez az opció való neked.",
  medium = "Ez a középút, ajánlott ha bizonytalan vagy melyiket válaszd.",
  hard = "Ha hozzá vagy szokva az ilyenfajta játékokhoz és szeretnél kihívást, válaszd ezt",
  tutorial = "Ha szeretnél játék közben segítséget kapni a kezdéshez, jelöld be ezt a négyzetet",
  cancel = "Áh, nem is akarok igazán új játékot kezdeni!!",
}

lua_console = {
  execute_code = "Végrehajtás",
  close = "Bezárás",
}

tooltip.lua_console = {
  textbox = "Írd ide a Lua kódot a futtatáshoz",
  execute_code = "Beírt kód futtatása",
  close = "Konzol bezárása",
}

errors = {
  dialog_missing_graphics = "Sajnálom, a demó fájlok nem tartalmazzák ezt a párbeszédet",
  save_prefix = "Hiba mentés közben",
  load_prefix = "Hiba betöltés közben",
  map_file_missing = "Nem találom a %s fájlt ehhez a pályához!",
  minimum_screen_size = "Kérlek írj be olyan felbontást ami nagyobb mint %dx%d.",
  maximum_screen_size = "Kérlek olyan felbontást írj be ami kisebb mint 3000x2000.",
  unavailable_screen_size = "A felbontás amit szeretnél nem elérhető teljes képernyős módban.",
}

confirmation = {
  needs_restart = "Ezen beállítás megváltoztatása megköveteli CorsixTH újraindulását. Minden nem mentett állás el fog veszni. Biztos vagy benne hogy ezt szeretnéd?",
  abort_edit_room = "Éppen építesz vagy szerkesztesz egy szobát. Ha minden szükséges tárgyat elhelyezel, a szoba kész lesz, ellenkező esetben azonban törlődik. Folytatod?",
}

information = {
  custom_game = "Üdvözöllek a CorsixTH-ban. Jó szórakozást ehhez az egyedi pályához!",
  cannot_restart = "Sajnos ez az egyedi pálya az újrakezdés funkció implementálása előtt lett mentve.",
  level_lost = {
    "A fenébe! Elbuktál a pályán. Több szerencsét legközelebb!",
    "A vesztés oka:",
    reputation = "A hírneved %d alá esett.",
    balance = "A banki egyenleged %d alá esett.",
    percentage_killed = "Több mint %d százalékát ölted meg a betegeknek.",
  },
}

tooltip.information = {
  close = "Információs ablak bezárása",
}

-- Tips
totd_window = {
  tips = {
    "A kezdéshez minden kórháznak szüksége van egy recepciós asztalra és egy orvosi irodára (GP's office). Innentől kezdve minden azon múlik, hogy milyen betegek látogatják a kórházadat. Akárhogy is: egy gyógyszertár mindenképpen jó döntés.",
    "A gépek, mint például a Felfújó, karbantartást igényelnek. Alkalmazz egy-két ezermestert, hogy megjavítság a készülékeidet, máskülönben a személyzetet és a betegeket teszed ki veszélynek.",
    "Kis idő elteltével a személyezeted elfárad. Bizonyosodj meg róla, hogy építettél személyzeti szobát, hogy pihenni tudjanak.",
    "Helyezz el megfelelő mennyiségű radiátort, hogy a személyzeted és a betegek ne fázzanak, máskülönben szomorúak lesznek. Használd a térképet, hogy megtaláld azokat a helyeket a kórházadban, melyek fűtést igányelnek.",
    "Egy doktor szakképzettsége nagyban befolyásolja a diagnózisainak minőségét és gyorsaságát. Helyezz az orvosi irodába (GP's office) egy szakképzett doktort és nem lesz szükséged annyi diagnózishoz szükséges szobára.",
    "Rezidensek (junior) és doktorok úgy tudják fejleszteni a szaktudásukat, hogy a tréning szobában (training room) tanulnak egy konzutlánstól. Ha a konzultánsnak különleges szaktudása is van (segész, pszichológus vagy kutató), azt is átadja a tanulóinak.",
    "Próbáltad már beütni a faxba az európai segélyhívó számot (112)? Legyenek bekapcsolva a hangszóróid!",
    "A képernyőfelbontást, a nyelvet és más jellegzetességeket a beállítások alatt tudod meghatározni, mely elérhető a főmenüben és a játék közben is.",
    "Nem angol nyelvet választottál ki és angol szöveget látsz mindenfelé? Segíts nekünk lefordítani a hiányzó szövegeket a saját nyelvedre!",
    "A CorsixTH csapatnak erősítésre van szüksége! Szeretnél programozni, fordítani vagy grafikákat készíteni a CorsixTH-nak? Értesíts minket a Fórumban, a levelező listánkon vagy az IRC csatornánkon(corsix-th at freenode).",
    "Ha találsz valamilyen hibát, kérünk téged, jelezd azt a hibanyomkövetőnknél, a: th-issues.corsix.org címen!",
    "Minden szint teljesítéséhez különböző követelményeknek kell megfelelned, hogy a következő szintre léphess. Ellenőrizd az állapotjelző ablakot, hogy hogy állsz.",
    "Ha szerkeszteni vagy törölni szeretnél egy szobát, azt az alsó eszközsoron található szerkesztő gombbal tudod megtenni.",
    "Ha nagyon sok várakozó beteggel futsz össze, úgy tudod gyorsan megállapítani, hogy ki mire vár, hogy a szobák fölé húzod az egered mutatóját, .",
    "Kattints egy szoba ajtajára, hogy megjelenítsd az oda várakozó sort. Itt további finomhangolásokra van lehetőséged, mint például a sorrend megváltoztatása vagy egy-egy beteg másik szobához küldése.",
    "A nem elégedett személyzet gyakran fog fizetésemelést kérni. Győződj meg róla, hogy a személyzeted kényelmes körülmények között dolgozik és így elkerülheted ezt.",
    "A betegek várakozás közben szomlyasak lesznek, különösen akkor, ha a fűtés nagyon fel van tekerve! Helyezz el italautomatákat megfelelő helyeken, hogy egy kis pluszbevételhez juss.",
    "Véglegesen megszakíthatod egy beteg diagnózisának felállítását és megtippelheted a betegségét, ha már találkoztál azzal a kórral. Tudd viszont, hogy ez növeli a rossz gyógymód veszélyét, ami a páciens halálát jelenti.",
    "A vészhelyzetek kiváló pluszbevételt jelentenek abban az esetben, ha elegendő kapacitásod van ahhoz, hogy időben ellásd a betegeket.",
  },
  previous = "Előző tipp",
  next = "Következő tipp",
}

tooltip.totd_window = {
  previous = "Mutasd az előző tippet",
  next = "Mutasd az következő tippet",
}

-------------------------------------------------------------------------------
--   SECTION B - OLD STRINGS (OVERRIDE)
-------------------------------------------------------------------------------

-- Staff class
-- each of these corresponds to a sprite
staff_class = {
  nurse                 = "Nővér",
  doctor                = "Orvos",
  handyman              = "Gondnok",
  receptionist          = "Recepciós",
  surgeon               = "Sebész",
}

-- Staff titles
-- these are titles used e.g. in the dynamic info bar
staff_title = {
  receptionist          = "Recepciós",
  general               = "Általános", -- unused?
  nurse                 = "Nővér",
  junior                = "Rezidens",
  doctor                = "Doktor",
  surgeon               = "Sebész",
  psychiatrist          = "Pszichiáter",
  consultant            = "Konzuláns",
  researcher            = "Kutató",
}

-- Pay rises
pay_rise = {
   definite_quit = "Semmit sem tehetsz annak érdekében, hogy itt tarts. Elegem van ebből a helyből!",
   regular = {
     "Teljesen kimerültem. Szükségem van egy kis pihenésre és egy %d -os fizetésemelésre ha nem akarod látni, ahogy a folyosón nyafogok.",
     "Nagyon fáradt vagyok. Szükségem van egy kis pihenésre és egy %d -os emelésre, hogy összesen total% d -t keressek, te zsarnok!", --% d (rise)% d (new total)
     "Ne csináld már! Úgy dolgozom itt, mint egy igás ló. Adj egy %d -os bónuszt és a kórháznál maradok.", --% d (rise)
     "Annyira el vagyok keseredve. Követelek egy %d -os emelést, amivel összesen % d -t fogok keresni, különben végeztem ezzel a hellyel.", --% d (rise)% d (new total)
     "A szüleim azt mondták nekem, hogy az orvosi pályán sok pénzt fogok keresni. Úgyhogy adj nekedm egy %d -os emelést, máskülönben végeztünk egymással.", --% d (rise)
     "Mérges vagyok! Adj nekem rendes fizetést! Nagyjából %d elegendő is volna.", --% d (rise)
   },
   poached = "% d ajánlott nekem % s. Ha nem kapok ugyanennyit, lelépek.", --% d (new total)% s (Competitor)
}

-- Staff descriptions
staff_descriptions = {
  good = {
  [1] = "Nagyon gyors és szorgalmas.",
     [2] = "Nagyon lelkiismeretes és gondos.",
     [3] = "Nagyon sokoldalú.",
     [4] = "Barátságos és mindig jókedvű.",
     [5] = "Rettenetesen kitartó. Reggeltől estig dolgozik.",
     [6] = "Nagyon udvarias és jó modorú.",
     [7] = "Hihetetlenül tehetséges és hozzáértő.",
     [8] = "Nagyon szeret teljesíteni a munkában.",
     [9] = "Maximalista, aki soha nem adja fel.",
     [10] = "Mosolyával mindig jobb kedvre deríti az embereket.",
     [11] = "Elragadó, udvarias és segítőkész.",
     [12] = "Motivált és elkötelezett a munka iránt.",
     [13] = "Természetesen viselkedik és keményen dolgozik.",
     [14] = "Hűséges és barátságos.",
     [15] = "Figyelmes és lehet rá számítani vészhelyzetekben.",
  },
  misc = {
     [1] = "Golfozik.",
     [2] = "Kagylóbúvárkodik.",
     [3] = "Jégszobrai vannak.",
     [4] = "Szereti a borokat.",
     [5] = "Versenyez.",
     [6] = "Bungee jumpingol.",
     [7] = "Poháralátéteket gyűjt.",
     [8] = "Szeret koncerten a közönségre ugrani.",
     [9] = "Szeret szörfölni.",
     [10] = "Szeret folyókat tágítani.",
     [11] = "Whiskey-t párol.",
     [12] = "Csináld-magad szakember.",
     [13] = "Szereti a francia művészfilmeket.",
     [14] = "Sokszor játszik a Theme Park-kal.",
     [15] = "C-típusú bizonyítványa van.",
     [16] = "Motorversenyző.",
     [17] = "Hegedűn és csellón játszik.",
     [18] = "Megszállott vonatrajongó.",
     [19] = "Kutyabarát.",
     [20] = "Rádiós.",
     [21] = "Gyakran jár fürdőkbe.",
     [22] = "Bambuszács szakkör vezetője.",
     [23] = "Zöldségből készült szappantartói vannak.",
     [24] = "Részmunkaidős bányászengedélye van.",
     [25] = "Egy kvíműsor házigazdája.",
     [26] = "2. világháborús ereklyéket gyűjt.",
     [27] = "Szeret átalakítani.",
     [28] = "Rave és trip-hop zenét hallgat.",
     [29] = "Dezodorral öli meg a rovarokat.",
     [30] = "Kiszúrja a rossz standup-osokat.",
     [31] = "Vásárol a kórház bizottságának.",
     [32] = "Titokban kertészkedik.",
     [33] = "Hamis karórákat csempész.",
     [34] = "Egy rock'n'roll bandában énekes.",
     [35] = "Imád napközben televíziót nézni.",
     [36] = "Pisztrángra horgászik.",
     [37] = "Turista minden múzeumban.",

  },
  bad = {
     [1] = "Lassú és kicsinyes.",
     [2] = "Lusta és nem ambíciózus.",
     [3] = "Rosszul képzett és használhatatlan.",
     [4] = "Buta és fárasztó. Tartalékos katona.",
     [5] = "Alacsony tűrőképességű. Rossz a magatartása.",
     [6] = "Süket mint az ágyú. Káposzta szaga van.",
     [7] = "Piszkos munkát végez. Nem vállal nagy felelősséget.",
     [8] = "Nehezen koncentrál és könnyen elterelődik a figyelme. ",
     [9] = "Stresszre hajlamos és sok hibát vét.",
     [10] = "könnyen dühbe jön. Sok gyűlölet van benne.",
     [11] = "Inkorrekt és alkalmatlan.",
     [12] = "nem érdekli a munka. Tétlen.",
     [13] = "Felelőtlen és gondatlan.",
     [14] = "Zsémbes, ravasz és mindenki agyára megy.",
     [15] = "Arogáns és felsőbbrendűsködő.",
  },
}

-- Staff list
staff_list = {
  morale       = "Morál",
  tiredness    = "Fáradtság",
  skill        = "Szakismeret",
  total_wages  = "Teljes kereset",
}



-- Objects
object = {
  desk                  = "Íróasztal",
  cabinet               = "Szekrény",
  door                  = "Ajtó",
  bench                 = "Pad",
  table1                = "Asztal", -- unused object
  chair                 = "Szék",
  drinks_machine        = "Üdítőautomata",
  bed                   = "Ágy",
  inflator              = "Pumpa",
  pool_table            = "Biliárdasztal",
  reception_desk        = "Recepcióspult",
  table2                = "Asztal", -- unused object & duplicate
  cardio                = "Kardió",
  scanner               = "Szkenner",
  console               = "Konzol",
  screen                = "Képernyő",
  litter_bomb           = "Szemétbomba",
  couch                 = "Dívány",
  sofa                  = "Szófa",
  crash_trolley         = "Gurulós szekrény",
  tv                    = "TV",
  ultrascanner          = "Ultrahang",
  dna_fixer             = "DNS javító",
  cast_remover          = "Gipszhámozó",
  hair_restorer         = "Hajvisszanövesztő",
  slicer                = "Szeletelő",
  x_ray                 = "Röntgen",
  radiation_shield      = "Sugárzás elleni pajzs",
  x_ray_viewer          = "Röntgenvizsgáló",
  operating_table       = "Operálóasztal",
  lamp                  = "Lámpa", -- unused object
  toilet_sink           = "WC kagyló",
  op_sink1              = "WC kagyló",
  op_sink2              = "WC kagyló",
  surgeon_screen        = "Függöny",
  lecture_chair         = "Hallgatói szék",
  projector             = "Vetítő",
  bed2                  = "Ágy", -- unused duplicate
  pharmacy_cabinet      = "Gyógyszeres vitrin",
  computer              = "Számítógép",
  atom_analyser         = "Atomelemző",
  blood_machine         = "Vérkezelő-gép",
  fire_extinguisher     = "Tűzoltókészülék",
  radiator              = "Fűtőtest",
  plant                 = "Növény",
  electrolyser          = "Elektrolizáló",
  jelly_moulder         = "Zselésítő",
  gates_of_hell         = "Pokol kapuja",
  bed3                  = "Ágy", -- unused duplicate
  bin                   = "Szemetes",
  toilet                = "Mosdó",
  swing_door1           = "Lengőajtó",
  swing_door2           = "Lengőajtó",
  shower                = "Zuhany",
  auto_autopsy          = "Auto-boncoló",
  bookcase              = "Könyvespolc",
  video_game            = "Videojáték",
  entrance_left         = "Bejárat bal ajtó",
  entrance_right        = "Bejárat jobb ajtó",
  skeleton              = "Csontváz",
  comfortable_chair     = "Kényelmes szék",
}


-- Place objects window
place_objects_window = {
  drag_blueprint     = "Addig állítsd az alaprejzot, amíg megfelelő méretűnek nem találod,",
  place_door      = "Válaszd ki az ajtó helyét,",
  place_windows     = "Csinálj pár ablakot, ha szeretnél. Véglegesítsd, ha kész vagy",
  place_objects     = "Helyezd el a tárgyakat. Véglegesítsd, ha boldog vagy,",
  confirm_or_buy_objects   = "Befejezheted a szobát vagy vásárolhatsz még további tárgyakat is,",
  pick_up_object     = "Kattints egy tárgyra, hogy felemeld vagy válassz ki valami mást a dobozból",
  place_objects_in_corridor  = "Helyezd el a tárgyakat a folyosón",
}
-- Months
months = {
  "Jan",
  "Feb",
  "Már",
  "Ápr",
  "Máj",
  "Jún",
  "Júl",
  "Aug",
  "Szep",
  "Okt",
  "Nov",
  "Dec",
}

-- Date format
date_format.daymonth = "%1% %2:months%"

-- Graphs
graphs = {
  money_in   = "Bevétel",
  money_out  = "Kiadás",
  wages      = "Fizetések",
  balance    = "Mérleg",
  visitors   = "Látogatók",
  cures      = "Gyógyulások",
  deaths     = "Halálesetek",
  reputation = "Hírnév",

  time_spans = {
    "1 óra",
    "12 óra",
    "48 óra",
  }
}
-- Transactions
transactions = {
  --null               = S[8][ 1], -- not needed
  wages                = "Fizetések",
  hire_staff           = "Személyzet felvétele",
  buy_object           = "Tárgy vásárlása.",
  build_room           = "Szoba építése",
  cure                 = "Gyógyítás",
  buy_land             = "Telek felvásárlása",
  treat_colon          = "Kezelés:",
  final_treat_colon    = "Teljes kezelés:",
  cure_colon           = "Gyógyult:",
  deposit              = "Letét",
  advance_colon        = "Előlép:",
  research             = "Kutatás költsége",
  drinks               = "Bevétel: Üdítők",
  jukebox              = "Bevétel: Zenegép", -- unused
  cheat                = "Monopolipénz",
  heating              = "Fűtésköltség",
  insurance_colon      = "Biztosítás:",
  bank_loan            = "Hitel",
  loan_repayment       = "Banki letét",
  loan_interest        = "Banki kamat",
  research_bonus       = "Kutatási bónusz",
  drug_cost            = "Gógyszerár",
  overdraft            = "Hiteltúllépési kamat",
  severance            = "Végkielégítés",
  general_bonus        = "Általános bónusz",
  sell_object          = "Tárgy eladás",
  personal_bonus       = "Személyi bónsuz",
  emergency_bonus      = "Vészhelyzet bónusz",
  vaccination          = "Védőoltás",
  epidemy_coverup_fine = "Járványeltitkolási bírság",
  compensation         = "Kompenzáció",
  vip_award            = "VIP-jutalom",
  epidemy_fine         = "Járványbírság",
  eoy_bonus_penalty    = "Év végi bónusz/büntetés",
  eoy_trophy_bonus     = "Év végi trófea-bónusz",
  machine_replacement  = "Gépcsere",
}
-- Town map
town_map = {
  chat         = "Térképcsevegés",
  for_sale     = "Eladó",
  not_for_sale = "Nem eladó",
  number       = "Telekszám",
  owner        = "Tulajdonos",
  area         = "Telekfelszín",
  price        = "Telekár",
}


-- Rooms short
-- NB: includes some special "rooms"
-- reception, destroyed room and "corridor objects"
rooms_short = {
  reception         = "Recepció",
  destroyed         = "Megsemmisült",
  corridor_objects  = "Folyosói tárgyak",

  gps_office        = "Orvosi iroda",
  psychiatric       = "Pszichiátria",
  ward              = "Kórterem",
  operating_theatre = "Műtő",
  pharmacy          = "Gyógyszertár",
  cardiogram        = "Kardiogramm",
  scanner           = "Szkenner",
  ultrascan         = "Ultrahang",
  blood_machine     = "Vérgép",
  x_ray             = "Röntgen",
  inflation         = "Pumpa",
  dna_fixer         = "DNS-klinika",
  hair_restoration  = "Hajklinika",
  tongue_clinic     = "Nyelvklinika",
  fracture_clinic   = "Gipszelő",
  training_room     = "Tréningszoba",
  electrolysis      = "Elektrolizáló",
  jelly_vat         = "Kocsonyakád",
  staffroom         = "Személyzeti szoba",
  -- rehabilitation = "Rehabilitering", -- unused
  general_diag      = "Általános vizsgáló",
  research_room     = "Kutatószoba.",
  toilets           = "WC",
  decontamination   = "Fertőtlenítő",
}

-- Rooms long
rooms_long = {
  general           = "ÁLtalános", -- unused?
  emergency         = "Vészhelyzet",
  corridors         = "Folyosó",

  gps_office        = "Orvosi iroda",
  psychiatric       = "Pszichiátria",
  ward              = "Kórterem",
  operating_theatre = "Műtő",
  pharmacy          = "Gyógyszertár",
  cardiogram        = "Kardiogramm",
  scanner           = "Szkenner",
  ultrascan         = "Ultrahang",
  blood_machine     = "Vérgép",
  x_ray             = "Röntgen",
  inflation         = "Pumpa",
  dna_fixer         = "DNS-klinika",
  hair_restoration  = "Hajklinika",
  tongue_clinic     = "Nyelvklinika",
  fracture_clinic   = "Gipszelő",
  training_room     = "Tréning szoba",
  electrolysis      = "Elektrolizáló",
  jelly_vat         = "Kocsonyakád",
  staffroom         = "Személyzeti szoba",
  -- rehabilitation = "Rehabiliteringsrom", -- unused
  general_diag      = "Általános vizsgáló",
  research_room     = "Kutatószoba",
  toilets           = "WC",
  decontamination   = "Fertőtlenítő",
}
-- Drug companies
drug_companies = {
  "Gyógyi Neked Kft.",
  "Meggyógyít Zrt.",
  "Tabi Mámor Kft.",
  "Jótabletta Zrt.",
  "Mindenre Jó Zrt.",
}

-- Build rooms
build_room_window = {
  pick_department   = "Osztály kiválasztása",
  pick_room_type    = "Típus kiválasztása",
  cost              = "Ár: ",
}

-- Build objects
buy_objects_window = {
  choose_items      = "Elemek kiválasztása",
  price             = "Ár:",
  total             = "Összesen:",
}

-- Research
research = {
  categories = {
    cure            = "Gyógymód",
    diagnosis       = "Diagnózis",
    drugs           = "Gyógyszerek",
    improvements    = "Fejlesztések",
    specialisation  = "Specializáció",
  },

  funds_allocation  = "Tőke elosztás",
  allocated_amount  = "Elosztott összeg",
}

-- Research policy tooltip
tooltip.research_policy = {
research_progress = "Előrehaladottság ebben a felfedezés-kategóriában: %1%/%2%",
no_research = "Nem végzel kutatást ebben a kategóriában",
}

-- Policy screen
policy = {
  header            = "Kórházi szabályzat",
  diag_procedure    = "Diagnózis állása",
  diag_termination  = "Diagnózis lezárása",
  staff_rest        = "Személyzet pihenőre küldése",
  staff_leave_rooms = "Személyzet szobákból való kiküldése",

  sliders = {
    guess           = "Gyógykezelés megtippelése", -- belongs to diag_procedure
    send_home       = "Hazaküldés", -- also belongs to diag_procedure
    stop            = "Kezelés leállítása", -- belongs to diag_termination
    staff_room      = "Személyzeti szobába küldés", -- belongs to staff_rest
  }
}

-- Rooms
room_classes = {
  -- S[19][2] -- "corridors" - unused for now
  diagnosis  = "Diagnózis",
  treatment  = "Kezelés",
  clinics    = "Klinikák",
  facilities = "Egyéb létesítmények",
}
-- Insurance companies
insurance_companies = {
  out_of_business   = "Üzemen kívül",
  "Hattyúlevél Kft.",
  "Norfolk Hagyma Bt.",
  "Darázsheg Kft.",
  "Úszó Hólyag Zrt.",
  "Barát Béla Kft.",
  "DagiDezső Holdings",
  "Lusta Leon Vállalat",
  "Ping és Pong Kft.",
  "Vidám Biztosító Vállalat",
  "Szakszervezeti Biztosító",
  "Kölcsönös Előny Zrt.",
}

-- Menu root
-- Keep 2 spaces as prefix and suffix
menu = {
  file                  = "  Fájl  ",
  options               = "  Beállítások  ",
  display               = "  Nézet  ",
  charts                = "  Grafikonok  ",
  debug                 = "  Hibakeresés  ",
}

-- Menu File
menu_file = {
  load                  = "  (%1%) Betöltés  ",
  save                  = "  (%1%) Mentés  ",
  restart               = "  (%1%) Újrakezdés  ",
  quit                  = "  (%1%) Kilépés  ",
}
menu_file_load = {
  [1] = "  Mentés 1  ",
  [2] = "  Mentés 2  ",
  [3] = "  Mentés 3  ",
  [4] = "  Mentés 4  ",
  [5] = "  Mentés 5  ",
  [6] = "  Mentés 6  ",
  [7] = "  Mentés 7  ",
  [8] = "  Mentés 8  ",
}
menu_file_save = {
  [1] = "  Mentés 1  ",
  [2] = "  Mentés 2  ",
  [3] = "  Mentés 3  ",
  [4] = "  Mentés 4  ",
  [5] = "  Mentés 5  ",
  [6] = "  Mentés 6  ",
  [7] = "  Mentés 7  ",
  [8] = "  Mentés 8  ",
}

-- Menu Options
menu_options = {
  sound               = "  (%1%) Hang  ",
  announcements       = "  (%1%) Hangosbemondó  ",
  music               = "  (%1%) Zene  ",
  sound_vol           = "  Hangerő  ",
  announcements_vol   = "  Hangosbemondó hangereje  ",
  music_vol           = "  Zene hangereje  ",
  autosave            = "  Automatikus mentés  ",
  game_speed          = "  Játék sebessége  ",
  jukebox             = "  (%1%) Zenegép  ",
}

-- Menu Options Volume
menu_options_volume = {
  [10] = "  10%  ",
  [20] = "  20%  ",
  [30] = "  30%  ",
  [40] = "  40%  ",
  [50] = "  50%  ",
  [60] = "  60%  ",
  [70] = "  70%  ",
  [80] = "  80%  ",
  [90] = "  90%  ",
  [100] = "  100%  ",
}

-- Menu Options Game Speed
menu_options_game_speed = {
  slowest             = "  (%1%) Leglassabb  ",
  slower              = "  (%1%) Lassú  ",
  normal              = "  (%1%) Normál  ",
  max_speed           = "  (%1%) Maximum sebesség  ",
  and_then_some_more  = "  (%1%) Még egy kicsivel több  ",
}

-- Menu Display
menu_display = {
  high_res            = "  Jó felbontás  ",
  mcga_lo_res         = "  MCGA alacsony felbontás  ",
  shadows             = "  Árnyékok  ",
}

-- Menu Charts
menu_charts = {
  statement           = "  (%1%) Egyenleg  ",
  casebook            = "  (%1%) Esetek  ",
  policy              = "  (%1%) Szabályzat  ",
  research            = "  (%1%) Kutatás  ",
  graphs              = "  (%1%) Grafikonok  ",
  staff_listing       = "  (%1%) Személyzet  ",
  bank_manager        = "  (%1%) Bankár  ",
  status              = "  (%1%) Állapot  ",
  briefing            = "  Eligazítás  ",
}

-- Menu Debug
menu_debug = {
  object_cells        = "  Objektumcellák        ",
  entry_cells         = "  Bejáratcellák      ",
  keep_clear_cells    = "  Szabadon hagyandó cellák   ",
  nav_bits            = "  Navigációs bitek            ",
  remove_walls        = "  Falak eltávolítása        ",
  remove_objects      = "  Objektumok eltávolítása ",
  display_pager       = "  Személyhívó megjelenítése           ",
  mapwho_checking     = "  MAPWHO ellenőrzés        ",
  plant_pagers        = "  PLANT PAGERS        ",
  porter_pagers       = "  PORTER PAGERS       ",
  pixbuf_cells        = "  PIXBUff CELLS        ",
  enter_nav_debug     = "  NAV hibakereső beütése     ",
  show_nav_cells      = "  Navigációs cellák mutatása      ",
  machine_pagers      = "  Gép PAGEREK       ",
  display_room_status = "  Szoba állapotának mutatása       ",
  display_big_cells   = "  Nagy cellák mutatása    ",
  show_help_hotspot   = "  Segédpontok mutatása  ",
  win_game_anim       = "  Játék megnyerésének animációja       ",
  win_level_anim      = "  Pálya megnyerésének animációja      ",
  lose_game_anim = {
    [1]  = "  Játék elveszítése animáció 1  ",
    [2]  = "  Játék elveszítése animáció 2  ",
    [3]  = "  Játék elveszítése animáció 3  ",
    [4]  = "  Játék elveszítése animáció 4  ",
    [5]  = "  Játék elveszítése animáció 5  ",
    [6]  = "  Játék elveszítése animáció 6  ",
    [7]  = "  Játék elveszítése animáció 7  ",
  },
}

debug_patient_window = {
  caption = "Próbabeteg",
}

-- High score screen
high_score = {
  pos          = "Poz",
  player       = "Játékos",
  score        = "Eredmény",
  best_scores  = "Legjobbak csarnoka",
  worst_scores = "Szégyenfal",
  killed       = "Megölt", -- is this used?

  categories = {
    money             = "Pénz",
    salary            = "Kereset",
    clean             = "Tiszta",
    cures             = "Gyógyulás",
    deaths            = "Haláleset",
    cure_death_ratio  = "Gyógyulás és halálesetek aránya",
    patient_happiness = "Betegek elégedettsége",
    staff_happiness   = "Személyzet elégedettsége",
    staff_number      = "Személyzet száma",
    visitors          = "Látogatók",
    total_value       = "Teljes érték",
  },
}
-- Casebook screen
casebook = {
  reputation           = "népszerűség",
  treatment_charge     = "gyógyítás díja",
  earned_money         = "összegyüjtött pénz",
  cured                = "meggyógyítottak",
  deaths               = "halálesetek sázma",
  sent_home            = "hazaküldöttek száma",
  research             = "kutatás",
  cure                 = "gyógymód",
  cure_desc = {
    build_room         = "Javaslom építs ilyen szobát: %s", -- %s (room name)
    build_ward         = "Még mindíg szükség van egy kórteremre.",
    hire_doctors       = "Szükség van még orvosra.",
    hire_surgeons      = "Vegyél fel sebészt.",
    hire_psychiatrists = "Vegyél fel pszichológust.",
    hire_nurses        = "Vegyél fel nővért.",
    no_cure_known      = "Nincs ismert gyógymód.",
    cure_known         = "Van gyógymód.",
    improve_cure       = "Gyógymód fejlesztése",
  },
}

-- Tooltips
tooltip = {

  -- Build room window
  build_room_window = {
    room_classes = {
      diagnosis        = "Diagnózis",
      treatment        = "Kezelés",
      clinic           = "Klinikák",
      facilities       = "Egyéb létesítmények",
    },
    cost               = "Ár",
    close              = "Bezárás",
  },

  -- Toolbar
  toolbar = {
    bank_button        = "Bal gombbal a bankmenedzser-ablakod nyitod meg, jobbal pedig a banki kimutatást",
    balance            = "Egyenleged",
    reputation         = "Hírneved: ", -- NB: no %d! Append " ([reputation])".
    date               = "A dátum",
    rooms              = "Szobák építése",
    objects            = "Folyosók díszítése",
    edit               = "Szobák/tárgyak szerkesztése",
    hire               = "Alkalmazottak szerződtetése",
    staff_list         = "Személyzetmenedzsment",
    town_map           = "Várostérkép",
    casebook           = "Esetnapló",
    research           = "Kutatás",
    status             = "Állapot",
    charts             = "Grafikonok",
    policy             = "Házirend",
  },

  -- Hire staff window
  hire_staff_window = {
    doctors            = "Az elérhető doktorok áttekintése",
    nurses             = "Az elérhető nővérek áttekintése",
    handymen           = "Az elérhető ezermesterek áttekintése",
    receptionists      = "Az elérhető recepciósok áttekintése",
    prev_person        = "Előző személy",
    next_person        = "Következő személy",
    hire               = "A személy felvétele",
    cancel             = "Mégsem",
    doctor_seniority   = "A doktor fokozata (rezidens, doktor, konzuláns)",
    staff_ability      = "A jelentkező képességei",
    salary             = "Fizetés",
    qualifications     = "A doktor további végzettségei",
    surgeon            = "Sebész",
    psychiatrist       = "Pszichológus",
    researcher         = "Kutató",
  },

  -- Buy objects window
  buy_objects_window = {
    price              = "A tárgy ára",
    total_value        = "A megrendelt tárgyak összára",
    confirm            = "Tárgy(ak) megvásárlása",
    cancel             = "Mégsem",
    increase           = "Eggyel több tárgy vásárlása ebből",
    decrease           = "Eggyel kevesebb tárgy vásárlása ebből",
  },

  -- Staff list
  staff_list = {
    doctors            = "Az alkalmazott doktorok listájának megjelenítése",
    nurses             = "Az alkalmazott nővérek listájának megjelenítése",
    handymen           = "Az alkalmazott ezermesterek listájának megjelenítése",
    receptionists      = "Az alkalmazott recepciósok listájának megjelenítése",

    happiness          = "A kiválasztott alkalmazottak boldogsága",
    tiredness          = "A kiválasztott alkalmazottak fáradtsága",
    ability            = "A kiválasztott alkalmazottak képessége",
    salary             = "Az alkalmazott jelenlegi fizetése",

    happiness_2        = "Az alkalmazott morálja",
    tiredness_2        = "Az alkalmazottak fáradtsága",
    ability_2          = "Az alkalmazott képessége",

    prev_person        = "Következő oldal",
    next_person        = "Előző oldal",

    bonus              = "10 suzázalékos bónusz fizetése ennek az alkalmazottnak",
    sack               = "Az alkalmazott kirúgása",
    pay_rise           = "Az alkalmazott fizetésének megemelése 10 százalékkal",

    close              = "Kilépés és visszatérés a játékba",

    doctor_seniority   = "A doktor fokozata",
    detail             = "Részleteknek odafigyelés",

    view_staff         = "Személyre közelítés",

    surgeon            = "Képzett sebész",
    psychiatrist       = "Képzett pszichológus",
    researcher         = "Képzett kutató",
    surgeon_train      = "Sebésszé képzés mértéke: %d%%", -- %d (percentage trained)
    psychiatrist_train = "Pszichológussá képzés mértéke: %d%%", -- %d (percentage trained)
    researcher_train   = "Kutatóvá képzés mértéke: %d%%", -- %d (percentage trained)

    skills             = "További készségek",
  },

  -- Queue window
  queue_window = {
    num_in_queue       = "A sor hossza",
    num_expected       = "A recepciós szerint ennyien fognak nemsokára a sorba állni",
    num_entered        = "Ennyian jártak a szobában",
    max_queue_size     = "A sor maximális mérete",
    dec_queue_size     = "Sor maximális méretének csökkentése",
    inc_queue_size     = "Sor maximális méretének növelése",
    front_of_queue     = "Húzz egy beteget ehhez az ikonhoz, hogy a sor elejére állítsd",
    end_of_queue       = "Húzz egy beteget ehhez az ikonhoz, hogy a sor végére állítsd",
    close              = "Bezárás",
    patient            = "Húzd a betegeket a soron belül bal gombbal, küldd haza vagy a rivális kórházak valamelyikébe jobb gombbal.",
    patient_dropdown = {
      reception        = "Beteg küldése a recepcióhoz",
      send_home        = "Beteg hazaküldése",
      hospital_1       = "Beteg átirányítása egy másik kórházba",
      hospital_2       = "Beteg átirányítása egy másik kórházba",
      hospital_3       = "Beteg átirányítása egy másik kórházba",
    },
  },

  -- Main menu
  main_menu = {
    new_game           = "Új kampány kezdése",
    load_game          = "Korábbi játék betöltése",
    continue           = "Korábbi játék folytatása",
    network            = "Hálózati játék kezdése",
    quit               = "Kilépés",
    load_menu = {
      load_slot        = "  Mentés [slotnumber]  ", -- NB: no %d! Append " [slotnumber]".
      empty_slot       = "  Üres  ",
    },
  },
  -- Window general
  window_general = {
    cancel             = "Mégse",
    confirm            = "Megerősít",
  },
  -- Patient window
  patient_window = {
    close              = "Ablak bezárása",
    graph              = "Kattints, hogy átválts a beteg egészség-grafikonja és kezelésnaplója között",
    happiness          = "A beteg boldogsága",
    thirst             = "A beteg szomjúsága",
    warmth             = "A beteg melegség érzete",
    casebook           = "Részletek megjelenítése a személy betegségéről",
    send_home          = "A beteg elbocsátása ebből a kórházból",
    center_view        = "A kamera betegre rögzítése",
    abort_diagnosis    = "A beteg azonnali kezelése, a diagnózis befejezése helyett",
    queue              = "Részletek megjelenítése a beteg előtt álló sorról",
  },
  -- window
  staff_window = {
    name               = "Alkalmazott neve",
    close              = "Ablak bezárása",
    face               = "A személy arca - kattints, hogy megnyitsd a kezelőablakot",
    happiness          = "Boldogság",
    tiredness          = "Fáradtság",
    ability            = "Képesség",
    doctor_seniority   = "Doktor fokozata (Rezidens, Doktor, Konzuláns)",
    skills             = "Képességek",
    surgeon            = "Sebész",
    psychiatrist       = "Pszichológus",
    researcher         = "Kutató",
    salary             = "Fizetés",
    center_view        = "Kattints bal gombbal a közelítéshez, jobb gombbal pedig az alkalmazottak közötti lapozáshoz.",
    sack               = "Kirúgás",
    pick_up            = "Felkapás",
  },
  -- Machine window
  machine_window = {
    name               = "Név",
    close              = "Ablak bezárása",
    times_used         = "Ennyiszer volt használatban a gép",
    status             = "A gép állapota",
    repair             = "Ezermester hívása, hogy megjavítsa a gépet",
    replace            = "Gép kicserélése",
  },


  -- Handyman window
  -- Spparently handymen have their own set of strings (partly) containing "handyman".
  -- We could just get rid of this category and include the three prios into staff_window.
  handyman_window = {
    name               = "Ezermester neve", -- contains "handyman"
    close              = "Ablak bezárása",
    face               = "Ezermester arca", -- contains "handyman"
    happiness          = "Boldogság",
    tiredness          = "Fáradtság",
    ability            = "Képesség",
    prio_litter        = "Szemétszedés prioritásának növelése ennél az ezermesternél", -- contains "handyman"
    prio_plants        = "Növényápolás prioritásának növelése ennél az ezermesternél", -- contains "handyman"
    prio_machines      = "Gépszerelés prioritásának növelése ennél az ezermesternél", -- contains "handyman"
    salary             = "Fizetés",
    center_view        = "Ugrás az ezermesterre", -- contains "handyman"
    sack               = "Kirúgás",
    pick_up            = "Felkapás",
  },

  -- Place objects window
  place_objects_window = {
    cancel             = "Mégsem",
    buy_sell           = "Tárgyak vásárlása/eladása",
    pick_up            = "Tárgy felemelése",
    confirm            = "Megerősít",
  },

  -- Casebook
  casebook = {
    up                 = "Felfelé gördítés",
    down               = "Lefelé gördítés",
    close              = "Gyógyszeres könyv bezárása",
    reputation         = "A kezelés népszerűsége",
    treatment_charge   = "Kezelés költsége",
    earned_money       = "A kezelésből eddig befolyt bevétel",
    cured              = "Sikeres kezelések száma",
    deaths             = "Halálesetet előidéző kezelések száma",
    sent_home          = "Elutasított betegek száma",
    decrease           = "Ár csökkentése",
    increase           = "Ár növelése",
    research           = "Kattints, hogy a specializációkra szánt kutatási pénzt erre a kezelésre használd",
    cure_type = {
      drug             = "A kezeléshez gyógyszerre van szükség",
      drug_percentage  = "A kezeléshez gyógyszerre van szükség - a tiéd %d%% hatásos", -- %d (effectiveness percentage)
      psychiatrist     = "Pszichológus végzi ezt a kezelést",
      surgery          = "Sebész végzi ezt a kezelést",
      machine          = "Ehhez a kezeléshez egy gépre van szükség",
      unknown          = "Egyelőre nem tudod, hogy miként kell kezelni ezt a betegséget",
    },

    cure_requirement = {
      possible         = "Kezelni tudod ezt a betegséget",
      research_machine = "Fel kell találnod pár gépet, hogy ezt a betegséget kezelni tudd",
      build_room       = "Egy szoba megépítésére van szükség, hogy ezt a betegséget kezelni tudd", -- NB: no %s!
      hire_surgeons    = "Két sebészt kell alkalmaznod, hogy operációkat tudj végrehajtani",
      hire_surgeon     = "Egy második sebészre is szükséged van, hogy operációkat tudj végrehajtani",
      hire_staff       = "Az alábbi személyzetre van szükséged ehhez a kezeléshez: %s", -- %s (staff type)
      hire_staff_old   = "Az alábbi személyzetre van szükséged ehhez a kezeléshez: %s",
      build_ward       = "Ehhez a kezeléshez egy kórteremre van szükséged",
      ward_hire_nurse  = "Egy kórteremben dolgozó nővérre van szükséged ennek a betegségnek a kezeléséhez",
      not_possible     = "Még nem tudod kezelni ezt a betegséget",
    },
  },

  -- Statement
  statement = {
    close              = "Bezárás",
  },

  -- Research
  research = {
    close              = "Kutatás ablak bezárása",
    cure_dec           = "Kutatás mértékének csökkentése",
    diagnosis_dec      = "Berendezéskutatás mértékének csökkentése",
    drugs_dec          = "Gyógyszerkutatás mértékének csökkentése",
    improvements_dec   = "Fejlesztéskutatás mértékének csökkentése ",
    specialisation_dec = "Specializációs kutatás mértékének csökkentése",
    cure_inc           = "Kutatás mértékéne növelése",
    diagnosis_inc      = "Berendezéskutatás mértékének növelése",
    drugs_inc          = "Gyógyszerkutatás mértékének növelése",
    improvements_inc   = "Fejlesztéskutatás mértékének növelése",
    specialisation_inc = "Specializációs kutatás mértékének növelése",
    allocated_amount   = "A büdzséből erre szánt összeg",
  },

  -- Graphs
  graphs = {
    close              = "Grafikonok ablak bezárása",
    scale              = "Skála",
    money_in           = "Bevétel bekapcsolása/kikapcsolása",
    money_out          = "Kiadás bekapcsolása/kikapcsolása",
    wages              = "Fizetések bekapcsolása/kikapcsolása",
    balance            = "Banki egyenleg bekapcsolása/kikapcsolása",
    visitors           = "Látogatók számának bekapcsolása/kikapcsolása",
    cures              = "Sikeres kezelések számának bekapcsolása/kikapcsolása",
    deaths             = "Halálozások számának bekapcsolása/kikapcsolása",
    reputation         = "Hírnév bekapcsolása/kikapcsolása",
  },

  -- Town map
  town_map = {
    people             = "Emberek bekapcsolása/kikapcsolása",
    plants             = "Növények bekapcsolása/kikapcsolása",
    fire_extinguishers = "Poroltók bekapcsolása/kikapcsolása",
    objects            = "Táryak bekapcsolása/kikapcsolása",
    radiators          = "Radiátorok bekapcsolása/kikapcsolása",
    heat_level         = "Hő bekapcsolása/kikapcsolása",
    heat_inc           = "Hőmérséklet növelése",
    heat_dec           = "Hőmérséklet csökkentése",
    heating_bill       = "Gázszámla",
    balance            = "Egyenleg",
    close              = "Térkép bezárása",
  },

  -- Jukebox.
  jukebox = {
    current_title      = "Zenegép",
    close              = "Zenegép bezárása",
    play               = "Zenegép elindítása",
    rewind             = "Visszatekerés",
    fast_forward       = "Előretekerés",
    stop               = "Zenedoboz megállítása",
    loop               = "Lejtászás végtelenítése",
  },

  -- Bank Manager
  bank_manager = {
    hospital_value     = "A kórház pillanatnyi értéke",
    balance            = "Bankegyenleged",
    current_loan       = "Kölcsöneid jelenlegi mértéke",
    repay_5000         = "$5000 visszafizetése a banknak",
    borrow_5000        = "$5000 hitel felvétele",
    interest_payment   = "Havi kamat",
    inflation_rate     = "Éves inflációs ráta",
    interest_rate      = "Éves kamatráta",
    close              = "Ablak bezárása",
    insurance_owed     = "Ennyivel tartozik neked %s", -- %s (name of debitor)
    show_graph         = "%s várható kifizetésének mértéke", -- %s (name of debitor)
    graph              = "%s várható kifizetéseinek grafikonja", -- %s (name of debitor)
    graph_return       = "Visszatérés az előző nézetre",
  },

  -- Status
  status = {
    percentage_cured   = "A betegek %d% -át kell meggyógyítanod. Egyelőre %d% -ot gyógyítottál meg",
    thirst             = "A betegek szomjúsága összesen",
    close              = "Az áttekintő ablak bezárása",
    population_chart   = "A diagramm, ami a azt mutatja, hogy a helyi lakosság mekkora részét gyógyította meg egy-egy kórház",
    win_progress_own   = "A nyeréshez szükséges kritérium teljesítettségének mutatása",
    reputation        = "A népszerűségednek legalább ennyinek kell lennie: %d. Jelenleg ennyi: %d",
    population        = "A helyi lakosság legalább %d%% -ának kell a te kórházadba jönnie",
    warmth             = "A betegek melegség érzete összesen",
    percentage_killed  = "A cél az, hogy a betegeid legfeljebb %d%% -át öld meg. Eddig %d%% -ukat ölted meg",
    balance        = "A banki egyenlegednek legalább ennyinek kell lennie: %d. Jelenleg ennyi: %d",
    value          = "A kórházad értékének legalább ennyinek kell lennie: $%d. Jelenleg ennyi: $%d",
    win_progress_other = "%s nyerési előremenetelének mutatása", -- %s (name of competitor)
    num_cured        = "Legalább %d beteget kell meggyógyítanod. Eddig ennyit gyógyítottál meg: %d",
    happiness          = "A kórházad betegeinek boldogsága",
  },

  -- Policy
  policy = {
    close              = "Ablak bezárása",
    staff_leave        = "Kattintással utasíthatod a jelenleg nem elfoglalt orvosaidat a többiek megsegítésére",
    staff_stay         = "Kattintással maradásra utasítod az adott orvost abban a szobában, ahová helyezted",
    diag_procedure     = "Ha egy orvos diagnózisa kevésbé biztos, mint a HAZAKÜLDÉS korlátja, a beteget hazaküldik. Ha a diagnózis biztosabb, mint a KEZELÉS MEGTIPPELÉSE mérték, a beteget kezelni fogják",
    diag_termination   = "Egy beteg diagnosztizálása addig tart, ameddig a doktorok bizonyossága el nem éri a FOLYAMAT LEÁLLÍTÁSA szintet vagy pedig meg nem próbálnak minden lehetséges diagnósztizáló eszközt",
    staff_rest         = "Azt mutatja, hogy mennyire lehet fáradt a személyzet, mielőtt a személyzeti szobába menne",
  },

  -- Pay rise window
  pay_rise_window = {
    accept             = "Beleegyezés a fizetésemelésbe",
    decline            = "Nem emeled a fizetést - inkább kirúgod",
  },

  -- Watch
  watch = {
    hospital_opening   = "Építési idő: ennyi időd maradt a kórházad nyitásáig. Kattintással azonnal megnyithatod a kórházat.",
    emergency          = "Vészhelyzet: azt mutatja, hogy mennyi időd van az összes veszélyeztetett beteged meggyógyítására",
    epidemic           = "Járvány: ennyi időd maradt felszámolni a járványt. Ha az időd lejárt VAGY egy fertőző beteg elhagyja a kórházadat, egy tisztiorvos jön látogatóba. A gombbal az beoltás üzemmódot tudod be illetve kikapcsolni. Kattints egy betegre, hogy beoltasd egy nővérrel.",
  },

  -- Rooms
  rooms = {
    gps_office         = "A betegek az orvosi irodában konzultálnak orvosaikkal és kapják meg leleteik eredményét",
    psychiatry         = "Az pszichiátra meggyógyítja az őrülteket és segít más betegséket diagnosztizálásában, azonban a működtetéséhez szükséged van egy pszichológus végzettségű orvosra",
    ward               = "A kórtermek mind a diagnosztizálásra, mind pedig a kezelésre alkalmasak. Ide kerülnek a betegek megfigyelésre és felépülésre egyaránt, melyhez egy nővérre van szükség",
    operating_theatre  = "A műtőnek a működéshez két szebész végzettségű orvosra van szüksége",
    pharmacy           = "Egy nővér osztja ki a megfelelő gyógyszereket a betegeknek",
    cardiogram         = "Egy doktor kezeli a kardiogrammot a diagnózis felállításához",
    scanner            = "Egy doktor kezeli a szkennert a diagnózis felállításához",
    ultrascan          = "Egy doktor kezeli az ultrahangot a diagnózis felállításához",
    blood_machine      = "Egy doktor kezeli a vérgépet a diagnózis felállításához",
    x_ray              = "Egy doktor kezeli a röntgent a diagnózis felállításához",
    inflation          = "Egy doktor kezeli a fejfúvót a duzzadt fejű betegek kezeléséhez",
    dna_fixer          = "Egy doktor kezeli a DNS-javítót az idegen DNS-es betegek kezeléséhez",
    hair_restoration   = "Egy doktor kezeli a hajnövesztőt a kopasz betegek kezeléséhez ",
    tongue_clinic      = "Egy doktor kezeli a nyelvmetszőt a petyhüdt nyelvű betegek kezeléséhez",
    fracture_clinic    = "Egy nővér üzemelteti a gipszklinikát a törött csontok helyreállításához",
    training_room      = "A tréning szoba doktorok továbbképzésére alkalmas, ha egy konzuláns fokozatú doktor üzemelteti",
    electrolysis       = "Egy doktor kezeli az elektrolizálót a hajitiszes betegek kezeléséhez ",
    jelly_vat          = "Egy doktor kezeli a zselékádat a kocsonyásodott betegek gyógyításához ",
    staffroom          = "Doktorok, nővérek és ezermesterek pihennek a személyzeti szobában, hogy kiheverjék fáradalmaikat",
    -- rehabilitation  = S[33][27], -- unused
    general_diag       = "Egy doktor tudja ellátni az általános kivizsgálót az elsődleges diagnózis felállításához. Olcsó és sokszor nagyon hatásos",
    research_room      = "Kutató végzettségű orvosok tudnak kifejleszteni új gépeket és gyógyszereket a kutatószobában",
    toilets            = "Építs WC-t annak érdekében, hogy a betegeid ne csináljanak nagy felfordulást a kórházadban!",
    decontamination    = "Egy doktor kezeli a fertőtlenítő készüléket a radioaktív betegek gyógyításához",
  },

  -- Objects
  objects = {
    -- NB: most objects do not have a tooltip because they're not (extra-)buyable
    desk                 = "Íróasztal: Nélkülönözhetetlen az orvosok számára. Erre teszik a számítógépüket.",
    cabinet              = "Szekrény: Kórlapokat, jegyzeteket és kutatási anyagokat tartalmaz.",
    door                 = "Ajtó: az emberek gyakran nyitják és csukják ezeket.",
    bench                = "Pad: helyet teremt a várakozó betegeknek, kényelmesebbé téve ezzel a múló perceket.",
    table1               = "Asztal (eltávolított): magazinokat tartalmaz, hogy a betegeknek gyorsabban teljes az idő.",
    chair                = "Szék: ide ül a beteg, hogy elmondja a bajait.",
    drinks_machine       = "Italautomata: Csökkenti a betegek szomját és egy kis bevételt hoz neked.",
    bed                  = "Ágy: az igazán beteg emberek ezen fekszenek.",
    inflator             = "Pumpa: .",
  },
}

-- Confirmation
confirmation = {
  quit                 = "Tényleg ki szeretnél lépni a játékból? ",
  return_to_blueprint  = "Biztosan vissza szeretnél lépni tervrajz módba?",
  replace_machine      = "Biztosan ki szeretnéd cserélni %s-t ennyiért $%d?", -- %s (machine name) %d (price)

  overwrite_save       = "Egy állás már létezik ezen a helyen. Biztos hogy felül akarod írni?",
  delete_room          = "Biztosan le akarod bontani ezt a szobát?",
  sack_staff           = "Biztos hogy ki akarod rúgni ezt a dolgozót?",
  restart_level        = "Biztos hogy újra akarod kezdeni ezt a pályát?",
}

-- Miscellangelous
-- Category of strings that fit nowhere else or we are not sure where they belong.
-- If you think a string of these fits somewhere else, please move it there.
-- Don't forget to change all references in the code and other language files.
misc = {
  grade_adverb = {
    mildly     = "lágyan",
    moderately = "közepesen",
    extremely  = "extrémen",
  },
  done  = "Kész",
  pause = "Megállít",

  send_message     = "Üzenet küldése %d játékosnak", -- %d (player number)
  send_message_all = "Üzenet küldése az összes játékosnak",

  save_success = "Mentés sikeres",
  save_failed  = "HIBA: Mentés sikertelen",

  hospital_open = "Korház megnyitott",
  out_of_sync   = "A játék kiesett a szinkronból",

  load_failed  = "Nem tudtam betölteni az állást",
  low_res      = "Alacsony felbontás.",
  balance      = "Egyenleg:",

  mouse        = "Egér",
  force        = "Kényszerít",
}

-- Original credits (untranslated)
original_credits = {
  [1] = " ",
  [2] = " ",
  [3] = " ",
  [4] = " ",
  [5] = " ",
  [6] = " ",
  [7] = " ",
  [8] = " ",
  [9] = " ",
  [10] = " ",
  [11] = " ",
  [12] = ":Designed and Created by",
  [13] = ":Bullfrog Productions",
  [14] = " ",
  [15] = ":Pluto Development Team",
  [16] = ",",
  [17] = "Mark Webley",
  [18] = "Gary Carr",
  [19] = "Matt Chilton",
  [20] = "Matt Sullivan",
  [21] = "Jo Rider",
  [22] = "Rajan Tande",
  [23] = "Wayne Imlach",
  [24] = "Andy Bass",
  [25] = "Jon Rennie",
  [26] = "Adam Coglan",
  [27] = "Natalie White",
  [28] = " ",
  [29] = " ",
  [30] = " ",
  [31] = ":Programming",
  [32] = ",",
  [33] = "Mark Webley",
  [34] = "Matt Chilton",
  [35] = "Matt Sullivan",
  [36] = "Rajan Tande",
  [37] = " ",
  [38] = " ",
  [39] = " ",
  [40] = ":Art",
  [41] = ",",
  [42] = "Gary Carr",
  [43] = "Jo Rider",
  [44] = "Andy Bass",
  [45] = "Adam Coglan",
  [46] = " ",
  [47] = " ",
  [48] = " ",
  [49] = ":Additional Programming",
  [50] = ",",
  [51] = "Ben Deane",
  [52] = "Gary Morgan",
  [53] = "Jonty Barnes",
  [54] = " ",
  [55] = " ",
  [56] = " ",
  [57] = ":Additional Art",
  [58] = ",",
  [59] = "Eoin Rogan",
  [60] = "George Svarovsky",
  [61] = "Saurev Sarkar",
  [62] = "Jason Brown",
  [63] = "John Kershaw",
  [64] = "Dee Lee",
  [65] = " ",
  [66] = " ",
  [67] = " ",
  [68] = ":Intro Sequence",
  [69] = ",",
  [70] = "Stuart Black",
  [71] = " ",
  [72] = " ",
  [73] = " ",
  [74] = ":Music and Sound Effects",
  [75] = ",",
  [76] = "Russell Shaw",
  [77] = "Adrian Moore",
  [78] = " ",
  [79] = " ",
  [80] = " ",
  [81] = ":Additional Music",
  [82] = ",",
  [83] = "Jeremy Longley",
  [84] = "Andy Wood",
  [85] = " ",
  [86] = " ",
  [87] = " ",
  [88] = ":Announcer Voiceover",
  [89] = ",",
  [90] = "Rebecca Green",
  [91] = " ",
  [92] = " ",
  [93] = " ",
  [94] = ":Level Design",
  [95] = ",",
  [96] = "Wayne Imlach",
  [97] = "Natalie White",
  [98] = "Steven Jarrett",
  [99] = "Shin Kanaoya",
  [100] = " ",
  [101] = " ",
  [102] = " ",
  [103] = ":Scripting",
  [104] = ",",
  [105] = "James Leach",
  [106] = "Sean Masterson",
  [107] = "Neil Cook",
  [108] = " ",
  [109] = " ",
  [110] = " ",
  [111] = ":R&D",
  [112] = " ",
  [113] = ":Graphics Engine",
  [114] = ",",
  [115] = "Andy Cakebread",
  [116] = "Richard Reed",
  [117] = " ",
  [118] = " ",
  [119] = " ",
  [120] = ":R&D Support",
  [121] = ",",
  [122] = "Glenn Corpes",
  [123] = "Martin Bell",
  [124] = "Ian Shaw",
  [125] = "Jan Svarovsky",
  [126] = " ",
  [127] = " ",
  [128] = " ",
  [129] = ":Library and Tools",
  [130] = " ",
  [131] = "Dos and Win 95 Library",
  [132] = ",",
  [133] = "Mark Huntley",
  [134] = "Alex Peters",
  [135] = "Rik Heywood",
  [136] = " ",
  [137] = " ",
  [138] = " ",
  [139] = ":Network Library",
  [140] = ",",
  [141] = "Ian Shippen",
  [142] = "Mark Lamport",
  [143] = " ",
  [144] = " ",
  [145] = " ",
  [146] = ":Sound Library",
  [147] = ",",
  [148] = "Russell Shaw",
  [149] = "Tony Cox",
  [150] = " ",
  [151] = " ",
  [152] = " ",
  [153] = ":Installer Programming",
  [154] = ",",
  [155] = "Andy Nuttall",
  [156] = "Tony Cox",
  [157] = "Andy Cakebread",
  [158] = " ",
  [159] = " ",
  [160] = " ",
  [161] = ":Moral Support",
  [162] = ",",
  [163] = "Peter Molyneux",
  [164] = " ",
  [165] = " ",
  [166] = " ",
  [167] = ":Testing Manager",
  [168] = ",",
  [169] = "Andy Robson",
  [170] = " ",
  [171] = " ",
  [172] = " ",
  [173] = ":Lead Testers",
  [174] = ",",
  [175] = "Wayne Imlach",
  [176] = "Jon Rennie",
  [177] = " ",
  [178] = " ",
  [179] = " ",
  [180] = ":Play Testers",
  [181] = ",",
  [182] = "Jeff Brutus",
  [183] = "Wayne Frost",
  [184] = "Steven Lawrie",
  [185] = "Tristan Paramor",
  [186] = "Nathan Smethurst",
  [187] = " ",
  [188] = "Ryan Corkery",
  [189] = "Simon Doherty",
  [190] = "James Dormer",
  [191] = "Martin Gregory",
  [192] = "Ben Lawley",
  [193] = "Joel Lewis",
  [194] = "David Lowe",
  [195] = "Robert Monczak",
  [196] = "Dominic Mortoza",
  [197] = "Karl O'Keeffe",
  [198] = "Michael Singletary",
  [199] = "Andrew Skipper",
  [200] = "Stuart Stephen",
  [201] = "David Wallington",
  [202] = " ",
  [203] = "And all our other Work Experience Play Testers",
  [204] = " ",
  [205] = " ",
  [206] = " ",
  [207] = ":Technical Support",
  [208] = ",",
  [209] = "Kevin Donkin",
  [210] = "Mike Burnham",
  [211] = "Simon Handby",
  [212] = " ",
  [213] = " ",
  [214] = " ",
  [215] = ":Marketing",
  [216] = ",",
  [217] = "Pete Murphy",
  [218] = "Sean Ratcliffe",
  [219] = " ",
  [220] = " ",
  [221] = " ",
  [222] = ":With thanks to:",
  [223] = ",",
  [224] = "Tamara Burke",
  [225] = "Annabel Roose",
  [226] = "Chris Morgan",
  [227] = "Pete Larsen",
  [228] = " ",
  [229] = " ",
  [230] = " ",
  [231] = ":PR",
  [232] = ",",
  [233] = "Cathy Campos",
  [234] = " ",
  [235] = " ",
  [236] = " ",
  [237] = ":Documentation",
  [238] = ",",
  [239] = "Mark Casey",
  [240] = "Richard Johnston",
  [241] = "James Lenoel",
  [242] = "Jon Rennie",
  [243] = " ",
  [244] = " ",
  [245] = " ",
  [246] = ":Documentation & Packaging Design",
  [247] = ",",
  [248] = "Caroline Arthur",
  [249] = "James Nolan",
  [250] = " ",
  [251] = " ",
  [252] = " ",
  [253] = ":Localisation Project Manager",
  [254] = ",",
  [255] = "Carol Aggett",
  [256] = " ",
  [257] = " ",
  [258] = " ",
  [259] = ":Localisation",
  [260] = ",",
  [261] = "Sandra Picaper",
  [262] = "Sonia 'Sam' Yazmadjian",
  [263] = " ",
  [264] = "Bettina Klos",
  [265] = "Alexa Kortsch",
  [266] = "Bianca Normann",
  [267] = " ",
  [268] = "C.T.O. S.p.A. Zola Predosa (BO)",
  [269] = "Gian Maria Battistini",
  [270] = "Maria Ziino",
  [271] = "Gabriele Vegetti",
  [272] = " ",
  [273] = "Elena Ruiz de Velasco",
  [274] = "Julio Valladares",
  [275] = "Ricardo Martínez",
  [276] = " ",
  [277] = "Kia Collin",
  [278] = "CBG Consult",
  [279] = "Ulf Thor",
  [280] = " ",
  [281] = " ",
  [282] = " ",
  [283] = ":Production",
  [284] = ",",
  [285] = "Rachel Holman",
  [286] = " ",
  [287] = " ",
  [288] = " ",
  [289] = ":Producer",
  [290] = ",",
  [291] = "Mark Webley",
  [292] = " ",
  [293] = " ",
  [294] = " ",
  [295] = ":Associate Producer",
  [296] = ",",
  [297] = "Andy Nuttall",
  [298] = " ",
  [299] = " ",
  [300] = " ",
  [301] = ":Operations",
  [302] = ",",
  [303] = "Steve Fitton",
  [304] = " ",
  [305] = " ",
  [306] = " ",
  [307] = ":Company Administration",
  [308] = ",",
  [309] = "Audrey Adams",
  [310] = "Annette Dabb",
  [311] = "Emma Gibbs",
  [312] = "Lucia Gobbo",
  [313] = "Jo Goodwin",
  [314] = "Sian Jones",
  [315] = "Kathy McEntee",
  [316] = "Louise Ratcliffe",
  [317] = " ",
  [318] = " ",
  [319] = " ",
  [320] = ":Company Management",
  [321] = ",",
  [322] = "Les Edgar",
  [323] = "Peter Molyneux",
  [324] = "David Byrne",
  [325] = " ",
  [326] = " ",
  [327] = ":All at Bullfrog Productions",
  [328] = " ",
  [329] = " ",
  [330] = " ",
  [331] = ":Special Thanks to",
  [332] = ",",
  [333] = "Everyone at Frimley Park Hospital",
  [334] = " ",
  [335] = ":Especially",
  [336] = ",",
  [337] = "Beverley Cannell",
  [338] = "Doug Carlisle",
  [339] = " ",
  [340] = " ",
  [341] = " ",
  [342] = ":Keep On Thinking",
  [343] = " ",
  [344] = " ",
  [345] = " ",
  [346] = " ",
  [347] = " ",
  [348] = " ",
  [349] = " ",
  [350] = " ",
  [351] = " ",
  [352] = " ",
  [353] = " ",
  [354] = " ",
  [355] = " ",
  [356] = " ",
  [357] = " ",
  [358] = " ",
  [359] = " ",
  [360] = " ",
  [361] = ".",
}
confirmation.maximum_screen_size = "Az általad beállított képernyőfelbontás magasabb mint 3000 X 2000. Van lehetőség ilyen felbontások beállítására, viszont ezekhez erősebb hardver szükségeltetik az akadozásmentes futtatáshoz. Biztosan folytatod?"
confirmation.music_warning = "Mielőtt kiválaszthatnád az mp3-akat amelyek játék közben fognak szólni szükséged lesz az smpeg.dll nevű (vagy azzal egyenértékű) file-ra, különben nem lesz zene. Folytatod?"
menu_options_wage_increase.deny = " MEGTAGAD"
menu_options_wage_increase.grant = " ENGEDÉLYEZ"
tooltip.audio_window.audio_button = "Minden hang ki/be kapcsolása"
tooltip.audio_window.audio_toggle = "Ki vagy bekapcsol"
tooltip.options_window.folder = "Könyvtár opciók"
tooltip.options_window.customise = "További beállítások, hogy finomhangolhasd a játékélményt"
tooltip.update_window.download = "Látogasd meg a letöltőoldalt, hogy megszerezhesd a CorsixTH legfrissebb verzióját"
tooltip.update_window.ignore = "A frissítés kihagyása. Újra értesítést fogsz kapni róla, amikor legközelebb elindítod a CorsixTH-t"
tooltip.folders_window.browse_font = "Válassz másik betűtípusfile-t ( jelenlegi hely: %1% )"
tooltip.folders_window.screenshots_location = "Alaphelyzetben a kilopott képek a konfigurációs file-ok könyvtárába kerülnek. Amennyiben máshova szeretnéd menteni őket csak tallózd ki a számodra megfelelő célkönyvtárat."
tooltip.folders_window.reset_to_default = "Elérési út alaphelyzetbe állítása ( %1% )"
tooltip.folders_window.back = "Menü bezárása, és vissza a Beállításokhoz"
tooltip.folders_window.music_location = "Válaszd ki az mp3 file-jaid elérési útját. A könyvtárt először létre kell hoznod, utána pedig  ki kell választanod."
tooltip.folders_window.font_location = "Szükség van egy olyan betűtípusfile elérési útjára, amely alkalmas a magyar nyelv betűit Unicode karakterek segítségével megjeleníteni. Amennyiben ezt elmulasztod nem leszel képes olyan nyelveket beállítani, amelyeknek szükségük van a játék eredeti nyelvében nem fellelhető karakterekre. Például: orosz és kínai"
tooltip.folders_window.savegames_location = "Alaphelyzetben a játék mentéseit tartalmazó file-ok a konfigurációs file-ok könyvtárába kerülnek. Amennyiben máshova szeretnéd menteni őket csak tallózd ki a számodra megfelelő célkönyvtárat."
tooltip.folders_window.browse_data = "Tallózd ki a Theme Hospital telepítési helyét (jelenlegi hely: %1%)"
tooltip.folders_window.browse = "Tallózz elérési utat"
tooltip.folders_window.browse_screenshots = "Válassz másik könyvtárat a kilopott képeidnek ( jelenlegi hely: %1% )"
tooltip.folders_window.browse_music = "Válassz másik könyvtárat a zenéidnek ( jelenlegi hely: %1% )"
tooltip.folders_window.no_font_specified = "Még nem adtál meg betűtípusfile elérési utat!"
tooltip.folders_window.not_specified = "Még nem adtál meg könyvtár elérési utat!"
tooltip.folders_window.browse_saves = "Válassz másik könyvtárat az elmentett játékállásaidnak ( jelenlegi hely: %1% )"
tooltip.folders_window.default = "Alapértelmezett elérési út"
tooltip.folders_window.data_location = "Az eredeti Theme Hospital telepítési helye (szükséges a CorsixTH futtatásához)"
tooltip.customise_window.alien_dna_only_by_emergency = "Mivel nincsenek megfelelő animációink az idegen DNA-val rendelkező páciensek megjelenítésére, ezért ők csak vészhelyzetek esetén jelennek meg a kórházadban. Ha szeretnéd, hogy ne csak ilyen esetekben jöjjenek, akkor ezt kapcsold ki"
tooltip.customise_window.enable_avg_contents = "Ha szeretnéd, hogy a játék megjegyezze milyen extra tárgyakkal szoktad a szobákat általában berendezni, akkor kapcsold be ezt"
tooltip.customise_window.back = "Menü bezárása, és vissza a Beállításokhoz"
tooltip.customise_window.movies = "Ezzel le tudod tiltani az összes átvezető videót"
tooltip.customise_window.disable_fractured_bones_females = "Mivel csak félkész animációink van a törött csontú női páciensek megjelenítésére, ezért ők nem jelennek meg a kórházadban. Ha mégis szeretnéd, hogy érkezzenek ilyen betegek is, akkor ezt kapcsold ki"
tooltip.customise_window.play_intro = "A bevezető videó (intro) ki/be kapcsolása - az átvezető videóknak engedélyezve kell lenniük, ha szeretnéd ezt bekapcsolni"
tooltip.customise_window.allow_user_actions_while_paused = "Az eredeti Theme Hospitalban a játékos csak a felső menüt használhatta ha a játék szüneteltetve volt. Ez az alapbeállítás a CorsixTH-ban is, de ha ezt bekapcsolod, akkor szüneteltetés alatt is elérsz minden menüt"
update_window.caption = "Frissítés elérhető!"
update_window.new_version = "Új verzió:"
update_window.current_version = "Jelenlegi verzió:"
update_window.download = "Ugrás a letöltőoldalra"
update_window.ignore = "Kihagy és tovább a főmenühöz"
errors.disable_fractured_bones_females = "MEGJEGYZÉS: a törött csontú női páciens animációja nem tökéletes"
errors.alien_dna_only_by_emergency = "MEGJEGYZÉS: nincsenek megfelelő animációink az idegen DNA-val rendelkező páciensek helyes megjelenítésére (például: leülés, ajtón kopogás, stb.), ezért amikor ezeket a cselekvéseket végzik olyankor átváltoznak normális kinézetűre, majd annak végeztével vissza. Az idegen DNA-val rendelkező páciensek csak akkor jelennek meg, ha a pálya file-jában ezt beállítottad"
errors.load_quick_save = "Hiba történt: a gyorsmentés betöltése sikertelen volt, mivel nem állt rendelkezésre betölthető állás. Nincs ok az aggodalomra,  ugyanis most létrehoztunk neked egyet!"
folders_window.data_label = "TH adat"
folders_window.music_location = "Válaszd ki a könyvtárat ahol a zenéidet tárolod"
folders_window.music_label = "MP3-ak"
folders_window.new_th_location = "Itt tudsz beállítani új Theme Hospital telepítési könyvtárat. Mihelyst kiválasztod a játék újra fog indulni."
folders_window.caption = "Könyvtár elérési utak"
folders_window.screenshots_label = "Kilopott képek"
folders_window.font_label = "Betűtípus"
folders_window.savegames_label = "Játékállások"
folders_window.back = "Vissza"
folders_window.savegames_location = "Válaszd ki a könyvtárat ahová a játékállásaid kerüljenek"
folders_window.screenshots_location = "Válaszd ki a könyvtárat ahová a kilopott képeid kerüljenek"
customise_window.enable_avg_contents = "Átlagos tartalmak"
customise_window.option_on = "Be"
customise_window.allow_user_actions_while_paused = "Építés szüneteltetés közben"
customise_window.option_off = "Ki"
customise_window.play_intro = "Bevezető videó lejátszása"
customise_window.caption = "Egyéni beállítások"
customise_window.back = "Vissza"
customise_window.movies = "Általános átvezető videó vezérlő"
customise_window.alien_dna_only_by_emergency = "Alien páciensek"
customise_window.disable_fractured_bones_females = "Törött Csontok"
options_window.folder = "Könyvtárak"
options_window.customise = "Személyre szab"
audio_window.audio = "Fő hangerő"
menu_options.twentyfour_hour_clock = " 24 ÓRÁS MEGJELENÍTÉS"
menu_options.wage_increase = " FIZETÉSIGÉNYEK"
install.ok = "OK"
install.cancel = "Mégse"
adviser.research.drug_improved_1 = "A kutatórészleged feljavította a %s szer hatását."
adviser.warnings.no_desk_7 = "Most hogy leraktál egy recepciós pultot mi lenne ha felvennél egy recepcióst is? Amíg ez meg nincs nem fogsz tudni páciensekkel foglalkozni!"
adviser.warnings.researcher_needs_desk_1 = "A Kutatónak szüksége van egy íróasztalra aminél dolgozhatna."
adviser.warnings.no_desk_6 = "Már van egy recepciósod. Mi lenne, ha leraknál neki egy recepciós pultot, ahol dolgozhatna?"
adviser.warnings.nurse_needs_desk_1 = "Minden Nővérkének szüksége van egy saját íróasztalra, ahol dolgozhat."
adviser.warnings.researcher_needs_desk_2 = "A kutatód boldog, hogy megengedted neki, hogy szünetet tartson. Ha a kutatórészleg személyzetének bővítését fontolgatod ne felejtsd el, hogy mindegyiknek szüksége lesz külön asztalra."
adviser.warnings.no_desk_5 = "Éppen ideje volt már, hamarosan megérkeznek az első betegek!"
adviser.warnings.no_desk_4 = "A recepciósnak szüksége van egy saját pultra, hogy üdvözölhesse az érkező betegeket"
adviser.warnings.researcher_needs_desk_3 = "Minden Kutatónak szüksége van egy íróasztalra aminél dolgozhat."
adviser.warnings.cannot_afford_2 = "Nincs elég pénzed a számládon ehhez a vásárláshoz!"
adviser.warnings.nurse_needs_desk_2 = "A nővérke boldog, hogy megengedted neki, hogy szünetet tartson. Ha a kórtermeid személyzetének bővítését fontolgatod ne felejtsd el, hogy mindegyiknek szüksége lesz külön asztalra."

-------------------------------------------------------------------------------
--   Multiplayer (network play): the room, game options, auctions, bots and the rest
--   of the multiplayer windows. Translated from english.lua; the keys
--   missing here show in English.
-------------------------------------------------------------------------------
multiplayer_window.add_bot = "várakozás játékosra... (kattints: bot hozzáadása)"
multiplayer_window.ask_amount = "Összeg: $%d"
multiplayer_window.ask_asked = "Elküldve. Várakozás a válaszra."
multiplayer_window.ask_balance_line = "Az egyenlege: $%d."
multiplayer_window.ask_button = "Kérés"
multiplayer_window.ask_caption = "Pénzt kérsz tőle: %s"
multiplayer_window.ask_decline = "Elutasítás"
multiplayer_window.ask_declined_note = "%s elutasította a pénzküldést ($%d)."
multiplayer_window.ask_line = "%s pénzt kér tőled: $%d."
multiplayer_window.ask_money = "Kérj egy játékostól"
multiplayer_window.ask_no_money_asker_note = "%s nem tudott neked fizetni."
multiplayer_window.ask_no_money_note = "Nem tudsz fizetni: $%d."
multiplayer_window.ask_pay = "Fizetés: $%d"
multiplayer_window.ask_sent_note = "Kérés: $%d, tőle: %s. Várakozás a válaszra."
multiplayer_window.auction_back = "Vissza az árverésre"
multiplayer_window.auction_bid = "Licit: $%d"
multiplayer_window.auction_borrow_tooltip = "$5,000 kölcsönkérése a banktól"
multiplayer_window.auction_close = "Bezár"
multiplayer_window.auction_dropped = "Kiszálltál."
multiplayer_window.auction_going_once = "Először..."
multiplayer_window.auction_going_twice = "Másodszor..."
multiplayer_window.auction_leader = "Legmagasabb licit: $%d, %s"
multiplayer_window.auction_leading = "Te vezetsz. Várj a többiekre."
multiplayer_window.auction_loan = "$%d, hitel $%d"
multiplayer_window.auction_loan_tooltip = "Az egyenleged és a banki hiteled"
multiplayer_window.auction_no_money = "Nem tudod megadni a következő licitet."
multiplayer_window.auction_no_money_loan = "Nem tudod megadni a következő licitet: vegyél fel hitelt a lenti + gombbal."
multiplayer_window.auction_not_sold = "A(z) %d. telek nem kelt el."
multiplayer_window.auction_out = "kiesett"
multiplayer_window.auction_pass = "Kiszállok"
multiplayer_window.auction_paused = "Az árverés alatt a játék áll."
multiplayer_window.auction_price = "Ár: $%d, minden licit +$%d"
multiplayer_window.auction_repay_tooltip = "$5,000 visszafizetése a hitelből"
multiplayer_window.auction_sold = "A(z) %d. telket %s vette meg: $%d."
multiplayer_window.auction_started = "%s meg akarja venni a(z) %d. telket. Mások is akarhatják, ezért árverésre kerül."
multiplayer_window.auction_title = "Telekárverés: %d. telek"
multiplayer_window.auction_wait = "Árverés folyik, kérlek várj..."
multiplayer_window.auction_watching = "A földed nem határos ezzel a telekkel."
multiplayer_window.auctions_all = "Minden telek"
multiplayer_window.auctions_caption = "Telekárverések"
multiplayer_window.auctions_near = "Vitatott"
multiplayer_window.auctions_none = "Ki"
multiplayer_window.back = "Vissza"
multiplayer_window.back_to_lobby = "Vissza a lobbiba"
multiplayer_window.bot_line = "%s   (bot)%s"
multiplayer_window.bot_remove = "   kattints: eltávolítás"
multiplayer_window.bot_starting = "a bot indul..."
multiplayer_window.caption = "Többjátékos"
multiplayer_window.chat_private_in = "%s (neked): %s"
multiplayer_window.chat_private_out = "Neki (%s): %s"
multiplayer_window.chat_team_in = "%s (csapatnak): %s"
multiplayer_window.chat_team_out = "Csapatnak: %s"
multiplayer_window.chat_to = "Neki (%s):"
multiplayer_window.chat_to_all = "Mindenkinek:"
multiplayer_window.chat_to_team = "Csapatnak:"
multiplayer_window.clear_destroyed_room = "Elbontod a lerombolt szobát? Ára: $%d. A hely utána szabad lesz másra."
multiplayer_window.colour_names[1] = "Sárga"
multiplayer_window.colour_names[2] = "Piros"
multiplayer_window.colour_names[3] = "Lila"
multiplayer_window.colour_names[4] = "Fehér"
multiplayer_window.colour_names[5] = "Zöld"
multiplayer_window.colour_names[6] = "Kék"
multiplayer_window.colour_names[7] = "Türkiz"
multiplayer_window.colour_names[8] = "Rózsaszín"
multiplayer_window.connect = "Csatlakozás"
multiplayer_window.connecting = "Csatlakozás ide: %s..."
multiplayer_window.continue_save = "Folytatás: %s"
multiplayer_window.continuing = "mentés: %s"
multiplayer_window.create = "Létrehozás"
multiplayer_window.data_mismatch_help = "A szerver Theme Hospital fájljai a játék egy másik kiadásából származnak, mint a tieid (a pályák és a többjátékos térképek eltérnek), és a két kiadással a játékok nem maradnának egyformák. Állítsd be a CorsixTH-t a szerverével azonos kiadásra (Beállítások, Mappabeállítások, Theme Hospital helye), például a GOG-os verzióra, és csatlakozz újra."
multiplayer_window.disconnect = "Kapcsolat bontása"
multiplayer_window.download = "%s letöltése a GitHubról"
multiplayer_window.emergency_refused = "A vészhelyzet elutasítása %d hírnévbe került a kórháznak."
multiplayer_window.every_plot_auctioned = "minden telek árverésre kerül"
multiplayer_window.game_options = "Játékbeállítások"
multiplayer_window.goal_limit = "határ:"
multiplayer_window.goal_other.balance = "%s: egyenleg $%d (%s $%d)"
multiplayer_window.goal_other.num_cured = "%s: %d meggyógyított beteg (%s %d)"
multiplayer_window.goal_other.percentage_cured = "%s: a betegek %d%%-a meggyógyítva (%s %d%%)"
multiplayer_window.goal_other.percentage_killed = "%s: a betegek %d%%-a meghalt (%s %d%%)"
multiplayer_window.goal_other.reputation = "%s: hírnév %d (%s %d)"
multiplayer_window.goal_other.value = "%s: a kórház értéke $%d (%s $%d)"
multiplayer_window.goal_target = "cél:"
multiplayer_window.goals_done = "teljesítve"
multiplayer_window.goals_failed_other = "%s kórháza nem teljesítette a szint céljait. Segíts neki talpra állni a jövő év végéig (pénzzel vagy személyzettel), különben az egész csapat veszít."
multiplayer_window.goals_failed_team = "A kórházad nem teljesítette a szint céljait. Hozd helyre a jövő év végéig, különben az egész csapat veszít. A többi játékos küldhet neked pénzt vagy személyzetet."
multiplayer_window.goals_failing = "bukásra áll"
multiplayer_window.goals_open = "-"
multiplayer_window.goals_reached_loan = "A kórházad teljesíti a szint összes célját, de még tartozik a banknak: $%d. Fizesd vissza a hitelt (kattints lent a pénzedre), és akkor teljesítettnek számít."
multiplayer_window.goals_reached_other = "%s kórháza teljesítette a szint céljait. Még hátravan: %s."
multiplayer_window.goals_reached_team = "A kórházad teljesítette a szint céljait! Még hátravan: %s."
multiplayer_window.goals_recovered = "%s kórháza már nem bukik el a szint céljain."
multiplayer_window.hold_win = "A játék arra vár, hogy %s válaszoljon a faxra..."
multiplayer_window.hold_year = "A játék arra vár, hogy %s bezárja az éves jelentést..."
multiplayer_window.is_ready = "kész"
multiplayer_window.join = "Belépés"
multiplayer_window.keep_playing = "Játék folytatása"
multiplayer_window.kick_player = "%s eltávolítása a szobából"
multiplayer_window.kicked = "%s, a szoba tulajdonosa, kitett a szobából."
multiplayer_window.leave = "Szoba elhagyása"
multiplayer_window.level = "%d. szint"
multiplayer_window.level7_breakthrough = "Orvosi áttörés: %s elsőként fedezte fel: %s. Jutalom: $%d."
multiplayer_window.level7_breakthrough_bonus = "Áttörési bónusz"
multiplayer_window.level7_job_fair = "Az állásbörze nyitva: ebben a hónapban szakemberek vannak a felvehetők listáján."
multiplayer_window.level7_job_fair_soon = "Jövő hónapban állásbörze nyílik: sebészek, pszichiáterek, kutatók és konzulánsok kerülnek a felvehetők listájára. Aki előbb jön, előbb fog."
multiplayer_window.level7_quarter = "Egészségügyi Minisztérium rangsora: a negyedév legtöbb betegét %s gyógyította meg (%d), és hírnevet nyer."
multiplayer_window.level7_race_bonus = "Versenyvészhelyzeti bónusz"
multiplayer_window.level7_race_emergency = "Versenyvészhelyzet: most minden kórház ugyanazt a vészhelyzetet kapja. Aki elsőként menti meg az összes beteget, jutalma $%d és hírnév."
multiplayer_window.level7_race_won = "%s mentette meg elsőként a versenyvészhelyzet összes betegét. Jutalma: $%d."
multiplayer_window.level7_rat_bounty = "Patkányfejpénz"
multiplayer_window.level7_trick_of_month = "A hónap trükkje: %s féláron kapható a hónap végéig."
multiplayer_window.level7_truce_over = "A fegyverszünet véget ért: mostantól vehetők piszkos trükkök (TÖBBJÁTÉKOS > PISZKOS TRÜKKÖK)."
multiplayer_window.level_intro_6 = "Vészhelyzet! A város kórházai minden esetet fogadnak, amit a helikopter ide tud szállítani. Az első évben havonta négyszer jön, sorban a kórházaidhoz: februártól felfújt fejű és pszichiátriai esetek (meg néhány a gyógyszertárnak), májustól műtős esetek, júniustól lógó nyelvek és csonttörések. Májusban minden kórház lógó nyelvű betegeket kap, ezért a Nyelvklinikát kutasd ki időben. A vészhelyzet elutasítása hírnévbe kerül, de a betegek elvesztését most jobban megbocsátják, és a vészhelyzeti betegeket átküldheted egy barátod kórházába, ahol meg tudják gyógyítani őket. Amíg a vészhelyzetek tartanak, kevesebb beteg jön magától; a második évtől többen jönnek, és két-három havonta járvány söpör végig minden kórházon. A patkányoknak is tetszik itt. Szerződtess konzulánsokat, amíg lehet: a kilencedik hónaptól csak rezidensek keresnek munkát. A győzelemhez minden kórháznak 550 hírnév, $60,000 a bankban, 150 meggyógyított beteg, 40 százalékos gyógyítási arány és a Haladási jelentésben látható kórházérték kell."
multiplayer_window.level_intro_7 = "Könyörtelen. A város minden kórháza a legjobb akar lenni, és egyik sem játszik tisztán. Márciusig fegyverszünet van; utána havonta nyílnak meg a piszkos trükkök: először patkánytámadás, lejárató kampány és elromlott kazán, júniustól gonosz gondnokok, járványok és kémkedés, szeptembertől kényszervészhelyzetek és fejvadászok, a második évtől pedig minden trükk legerősebb fokozata. Havonta egy trükk féláron kapható, a legtöbbet lemaradt kórház mindegyikért feleannyit fizet, a vezető pedig másfélszer annyit. Érdemes harcolni az állásbörzékért: áprilisban, októberben, jövő áprilisban és jövő októberben sebészek, pszichiáterek, kutatók és konzulánsok kerülnek a felvehetők listájára, aki előbb jön, előbb fog. Augusztusban, februárban és a következő augusztusban minden kórház egyszerre ugyanazt a vészhelyzetet kapja, és aki elsőként menti meg az összes beteget, jutalma $10,000 és hírnév. Aki elsőként fedezi fel a röntgent, a szkennert vagy a vérgépet, szintén $10,000 a jutalma (az ellopott tervek nem számítanak), és minden negyedévben a legtöbb beteget meggyógyító kórház hírnevet nyer. A riválisod által küldött patkányokért lelövésükkor $100 jár darabonként. A gépek itt gyorsabban kopnak, és négy földrengés rázza meg a várost, mindegyik erősebb az előzőnél. A győzelemhez a kórháznak 650 hírnév, $150,000 a bankban, 300 meggyógyított beteg, 55 százalékos gyógyítási arány és a Haladási jelentésben látható kórházérték kell. Négy játékossal a város Matroftt térképe."
multiplayer_window.level_intro_8 = "A Team Town, Matroftt térképe, két-a-kettő ellen való: a négy kórház párokban áll a város közepén, a csapattársak egymás mellett, és minden oldalon rengeteg eladó föld van. Tedd a barátaidat ugyanabba a csapatba, és versenyezz a másik párral. A győzelemhez minden kórháznak 650 hírnév, $100,000 a bankban, 200 meggyógyított beteg, 50 százalékos gyógyítási arány és a Haladási jelentésben látható kórházérték kell. Két vagy három játékossal egy másik város térképén játszható."
multiplayer_window.level_rats_notice = "Patkányok! Egy raj jutott be a kórházba. Kattints rájuk, és lődd le őket, mielőtt elszaporodnak a szemétben."
multiplayer_window.level_slack_tongue_warning = "A város minden pontjáról lógó nyelvekről érkeznek jelentések. Májusban minden kórház lógó nyelvű vészhelyzeteket kap: addig kutasd ki a Nyelvklinikát."
multiplayer_window.level_won_end = "Megnyerted a szintet. Szép munka!"
multiplayer_window.levels_caption = "Szintek"
multiplayer_window.levels_choose = "%d. szint kiválasztása"
multiplayer_window.levels_events = "ESEMÉNYEK: %s"
multiplayer_window.levels_from_campaign = "Szobák, betegségek és kutatás mint itt: %s (kampányszint: %d)."
multiplayer_window.levels_goal_balance = "$%s a bankban"
multiplayer_window.levels_goal_cure_rate = "Gyógyítási arány: %d%%"
multiplayer_window.levels_goal_cured = "%d meggyógyítva"
multiplayer_window.levels_goal_reputation = "Hírnév: %d"
multiplayer_window.levels_goal_value = "Érték: +$%s"
multiplayer_window.levels_goals = "A győzelemhez:"
multiplayer_window.levels_legend = "Színes: kezdő telkek. Szürke: eladó."
multiplayer_window.levels_map_by = "A térkép készítője: %s"
multiplayer_window.levels_map_players = "Térkép %d játékosnak"
multiplayer_window.levels_money = "Pénz: $%s"
multiplayer_window.levels_no_map = "Ez a térkép nincs meg a Theme Hospital adataid között."
multiplayer_window.levels_several = "Több kórház"
multiplayer_window.levels_shared = "Egy közös kórház"
multiplayer_window.levels_shared_note = "%d. kampányszint: egy kórház, amit mindenki közösen épít, a kampány céljaival."
multiplayer_window.load_caption = "Többjátékos játék betöltése"
multiplayer_window.load_game = "MP játék betöltése"
multiplayer_window.loading = "BETÖLTÉS..."
multiplayer_window.locked = "  (jelszó)"
multiplayer_window.looking_at = "Nézet: %s"
multiplayer_window.measuring = "A kapcsolat mérése..."
multiplayer_window.menu_caption = "  TÖBBJÁTÉKOS  "
multiplayer_window.menu_chat = "  ÜZENET KÜLDÉSE (%1%)  "
multiplayer_window.menu_colours = "  JÁTÉKOSSZÍNEK  "
multiplayer_window.menu_colours_all = "  MINDENKI EMBEREI  "
multiplayer_window.menu_colours_off = "  KI  "
multiplayer_window.menu_colours_others = "  MÁSOK EMBEREI  "
multiplayer_window.menu_players = "  JÁTÉKOSOK  "
multiplayer_window.menu_research = "  KUTATÁS MEGOSZTÁSA  "
multiplayer_window.menu_sabotage = "  PISZKOS TRÜKKÖK  "
multiplayer_window.menu_trade = "  KERESKEDÉS JÁTÉKOSOKKAL  "
multiplayer_window.mode_competitive = "Verseny: mindenki magáért"
multiplayer_window.mode_coop = "Együttműködés: mindenki együtt nyer"
multiplayer_window.mode_mixed = "Csapatok versenye"
multiplayer_window.mode_shared = "Egy közös kórház"
multiplayer_window.mode_teams = "Két csapat versenye"
multiplayer_window.mode_teamshared = "Csapatkórházak versenye"
multiplayer_window.money_received = "Pénz tőle: %s"
multiplayer_window.money_received_note = "%s pénzt küldött neked: $%d."
multiplayer_window.money_sent = "Pénz küldve neki: %s"
multiplayer_window.mp_level = "%s (több kórházzal: %d. szint)"
multiplayer_window.name = "A neved"
multiplayer_window.new_room = "Új szoba"
multiplayer_window.no_auctions = "nincs árverés"
multiplayer_window.no_rooms = "Még nincs szoba. Hozz létre egyet lent."
multiplayer_window.no_sharing = "nincs megosztás"
multiplayer_window.no_socket = "Ebben a verzióban nincs hálózati támogatás (hiányzik a LuaSocket)."
multiplayer_window.no_tricks = "nincs trükk"
multiplayer_window.not_ready = "nem kész"
multiplayer_window.offer_ability = "Képesség: %d%%"
multiplayer_window.offer_accept = "Elfogadás"
multiplayer_window.offer_accept_pay = "Fizetés: $%d"
multiplayer_window.offer_accept_price = "Elfogadás és fizetés: $%d"
multiplayer_window.offer_accepted_note = "%s elfogadta: %s."
multiplayer_window.offer_accepted_price_note = "%s elfogadta: %s, ára: $%d."
multiplayer_window.offer_caption = "Ajánlat tőle: %s"
multiplayer_window.offer_decline = "Elutasítás"
multiplayer_window.offer_declined_note = "%s elutasította: %s."
multiplayer_window.offer_free_banner = "INGYEN: ezért az alkalmazottért nem kell fizetni"
multiplayer_window.offer_gone_note = "%s már nem elérhető."
multiplayer_window.offer_happy = "Boldogság: %d%%"
multiplayer_window.offer_health = "Egészség: %d%%"
multiplayer_window.offer_illness = "Betegség: %s"
multiplayer_window.offer_job = "Munka: %s"
multiplayer_window.offer_later = "Később"
multiplayer_window.offer_no_money_note = "Nem tudod kifizetni a kért árat ($%d): %s."
multiplayer_window.offer_no_money_sender_note = "%s nem tudta kifizetni az árat: %s."
multiplayer_window.offer_no_skills = "Különleges képességek: nincs"
multiplayer_window.offer_not_diagnosed = "Még nincs diagnózis (%d%% kész)"
multiplayer_window.offer_patient_known = "beteg, betegsége: %s"
multiplayer_window.offer_patient_line = "%s beteget küld neked:"
multiplayer_window.offer_patient_unknown = "diagnosztizálatlan beteg"
multiplayer_window.offer_price_banner = "ÁR: $%d, csak elfogadás esetén fizetendő"
multiplayer_window.offer_price_line = "ÁR: $%d. Ennyit kér ezért az alkalmazottért."
multiplayer_window.offer_raise = "Béremelést kér"
multiplayer_window.offer_sent_note = "Felajánlva: %s - címzett: %s. Várakozás a válaszra."
multiplayer_window.offer_sent_price_note = "Felajánlva: %s - címzett: %s, ára: $%d. Várakozás a válaszra."
multiplayer_window.offer_show = "Megmutat"
multiplayer_window.offer_skills = "Különleges képességek: %s"
multiplayer_window.offer_staff_line = "%s alkalmazottat ajánl neked:"
multiplayer_window.offer_tired = "Fáradtság: %d%%"
multiplayer_window.offer_wage = "Fizetés: $%d havonta"
multiplayer_window.options_close = "Bezár"
multiplayer_window.options_host_only = "Ezeket csak a házigazda állíthatja."
multiplayer_window.options_off_line = "Beállítások: %s"
multiplayer_window.other_build = "  (másik játékverzió)"
multiplayer_window.owner_mark = " (házigazda)"
multiplayer_window.password = "Jelszó"
multiplayer_window.patient_arrived_note = "A(z) %s által küldött beteg megérkezett."
multiplayer_window.patient_on_the_way = "Küldve ide: %s"
multiplayer_window.places[1] = "1."
multiplayer_window.places[2] = "2."
multiplayer_window.places[3] = "3."
multiplayer_window.places[4] = "4."
multiplayer_window.player_away_note = "%s kilépett: a kórháza nem számít bele a csapat céljaiba, amíg vissza nem tér (ugyanabba a szobába, ugyanazzal a névvel)."
multiplayer_window.player_back_note = "%s visszatért: a kórháza újra beleszámít a csapat céljaiba."
multiplayer_window.player_line = "%s%s   %s ms   %s"
multiplayer_window.players = "%d játékos"
multiplayer_window.players_balance = "Egyenleg"
multiplayer_window.players_behind = "%d órával lemaradva"
multiplayer_window.players_caption = "Játékosok"
multiplayer_window.players_goals = "Célok"
multiplayer_window.players_hospital = "Kórház"
multiplayer_window.players_left = "kilépett a játékból"
multiplayer_window.players_ms = "%d ms"
multiplayer_window.players_name = "Játékos"
multiplayer_window.players_note = "Ping: az utolsó 10 másodperc átlaga. Érték: a kórház értéke (szintcél)."
multiplayer_window.players_ping = "Ping"
multiplayer_window.players_playing = "játékban"
multiplayer_window.players_quiet = "%d mp-ig nincs válasz"
multiplayer_window.players_reputation = "Hírnév"
multiplayer_window.players_status = "Állapot"
multiplayer_window.players_team = "%s (%d. csapat)"
multiplayer_window.players_value = "Érték"
multiplayer_window.players_waiting = "Várakozás a szerver listájára..."
multiplayer_window.players_you = "te"
multiplayer_window.race_failing = "A kórházad nem teljesítette a szint céljait. Hozd helyre a jövő év végéig, különben kiesel a versenyből."
multiplayer_window.race_failing_other = "%s nem teljesítette a szint céljait; kiesik, ha jövőre sem teljesíti."
multiplayer_window.race_left_end = "Elhagytad a versenyt. A többiek tovább játszanak a következő helyekért."
multiplayer_window.race_out[1] = "Rossz hír."
multiplayer_window.race_out[2] = "A kórházad két éve egymás után nem teljesítette a szint céljait: kiestél a versenyből, %s helyen."
multiplayer_window.race_out[3] = "Visszamész a lobbiba, vagy nézed a többieket?"
multiplayer_window.race_out_other = "%s két éve egymás után nem teljesítette a célokat, és kiesett a versenyből (%s helyen)."
multiplayer_window.race_out_short = "kiesett"
multiplayer_window.race_over[1] = "A verseny véget ért. Végeredmény:"
multiplayer_window.race_over[2] = "Visszamész a lobbiba, vagy folytatod a játékot?"
multiplayer_window.race_over_won = "Gratulálunk, a csapatod megnyerte a versenyt! Végeredmény:"
multiplayer_window.race_placed_other = "%s teljesítette a szint céljait: %s helyen. A verseny folytatódik."
multiplayer_window.race_standing = "%s %s"
multiplayer_window.race_standing_out = " (kiesett)"
multiplayer_window.race_watch = "Nézés"
multiplayer_window.race_won[1] = "Gratulálunk!"
multiplayer_window.race_won[2] = "A kórházad teljesítette a szint céljait: %s helyen."
multiplayer_window.race_won[3] = "A többiek tovább versenyeznek a következő helyekért. Visszamész a lobbiba, vagy nézed őket?"
multiplayer_window.ready = "Kész"
multiplayer_window.rebuild_destroyed_room = "Ez a szoba megsemmisült. Elbontod és újraépíted? Ára: $%d."
multiplayer_window.recommendation = "Legfeljebb %s; a műveletek ideje: %s ms"
multiplayer_window.refer_button = "Beteg átküldése"
multiplayer_window.refer_choose = "Melyik kórházba küldöd?"
multiplayer_window.refer_fax_choice = "Átküldés másik kórházba"
multiplayer_window.refresh = "Frissítés"
multiplayer_window.repair_destroyed_room = "Ez a szoba megsemmisült. Kijavítod? Ára: $%d, annyi, mint egy új szobáé a bútoraival együtt. (Nem: inkább bontsd el.)"
multiplayer_window.research_accept = "ELFOGADOM ezt a kutatási tudást"
multiplayer_window.research_accept_price = "ELFOGADOM ezt a kutatási tudást, ára: $%d"
multiplayer_window.research_accepted_note = "%s elfogadta a kutatásodat (fizetett: $%d)."
multiplayer_window.research_all = "Mind"
multiplayer_window.research_and_more = "és még %d"
multiplayer_window.research_bought_transaction = "Kutatás tőle: %s"
multiplayer_window.research_caption = "Kutatás megosztása vele: %s"
multiplayer_window.research_decline = "ELUTASÍTOM ezt a kutatási tudást"
multiplayer_window.research_declined_note = "%s elutasította a kutatásodat."
multiplayer_window.research_free = "Ár: ingyen"
multiplayer_window.research_free_line = "INGYEN: ezért az átadásért nem kell fizetni."
multiplayer_window.research_item_drug = "Gyógyszer: %s"
multiplayer_window.research_item_machine = "Fejlesztés: %s"
multiplayer_window.research_known_note = "Ezt a kutatást már mind ismered."
multiplayer_window.research_known_sender_note = "%s ezt a kutatást már mind ismerte."
multiplayer_window.research_next = "Tovább"
multiplayer_window.research_no_money_note = "Nem tudod kifizetni ezt a kutatást ($%d)."
multiplayer_window.research_no_money_sender_note = "%s nem tudta kifizetni a kutatásodat."
multiplayer_window.research_none = "Nincs olyan kutatásod, ami neki hiányzik."
multiplayer_window.research_none_selected = "Előbb válassz ki valamilyen kutatást."
multiplayer_window.research_offer = "Felajánlás"
multiplayer_window.research_offer_line = "%s megosztaná veled a következő kutatást:"
multiplayer_window.research_offered = "Felajánlva. Várakozás a válaszra."
multiplayer_window.research_page = "%d. oldal / %d"
multiplayer_window.research_previous = "Vissza"
multiplayer_window.research_price = "Ár: $%d"
multiplayer_window.research_price_line = "ÁR: $%d. Csak akkor fizetsz, ha elfogadod."
multiplayer_window.research_received_note = "Új kutatás: %s."
multiplayer_window.research_sent_note = "Kutatás felajánlva neki: %s. Várakozás a válaszra."
multiplayer_window.research_sold_transaction = "Kutatás eladva neki: %s"
multiplayer_window.room_caption = "Szoba: %s"
multiplayer_window.room_hint = "Azonos szín: egy kórház. Azonos csapat: együtt nyertek."
multiplayer_window.room_line = "%s   %d / %d   %s   %s. szint%s"
multiplayer_window.rooms_caption = "Szobák itt: %s"
multiplayer_window.sabotage_again = "Kattints újra az L%d gombra a megvételhez: $%d."
multiplayer_window.sabotage_alone = "Nincs több rivális, akinek trükköt lehetne csinálni."
multiplayer_window.sabotage_arrived = "A gonosz gondnokod munkába állt %s kórházában."
multiplayer_window.sabotage_boiler = "Elromlott kazán"
multiplayer_window.sabotage_boiler_notice = "A kazán elromlott, és ez nem baleset volt. A gondnokaid javítják: minél többen vannak, annál hamarabb végeznek."
multiplayer_window.sabotage_caption = "Piszkos trükkök ellene: %s"
multiplayer_window.sabotage_caught = "Kidobtál egy gondnokot, aki nem a tiéd volt: %s küldte. Visszamegy hozzá."
multiplayer_window.sabotage_caught_owner = "%s elkapta a gonosz gondnokodat. Visszatér, és újra neked dolgozik."
multiplayer_window.sabotage_close = "Bezár"
multiplayer_window.sabotage_done.boiler = "%s kazánja elromlott."
multiplayer_window.sabotage_done.emergency = "Vészhelyzet indult %s kórháza felé."
multiplayer_window.sabotage_done.epidemic = "A fertőző betegek %s kórháza felé tartanak."
multiplayer_window.sabotage_done.espionage = "A kémed járt %s kórházában."
multiplayer_window.sabotage_done.handyman = "A gonosz gondnokod úton van %s kórházához."
multiplayer_window.sabotage_done.headhunter = "A fejvadászod ajánlatot tett %s egyik alkalmazottjának."
multiplayer_window.sabotage_done.rats = "A patkányok beköltöznek %s kórházába."
multiplayer_window.sabotage_done.smear = "A lejárató kampány %s ellen elkezdődött."
multiplayer_window.sabotage_emergency = "Vészhelyzet"
multiplayer_window.sabotage_emergency_fax[1] = "Vészhelyzetet küldtek rád, és nem utasíthatod vissza."
multiplayer_window.sabotage_emergency_fax[2] = "%d beteg érkezik helikopterrel, betegségük: %s."
multiplayer_window.sabotage_emergency_fax[3] = "Gyógyíts meg közülük annyit, amennyit csak tudsz, mielőtt lejár az idő."
multiplayer_window.sabotage_epidemic = "Járvány"
multiplayer_window.sabotage_espionage = "Kémkedés"
multiplayer_window.sabotage_espionage_got = "A kémed ezt hozta: %s."
multiplayer_window.sabotage_espionage_notice = "Valaki fájlokat másolt le a kutatóosztályról."
multiplayer_window.sabotage_espionage_notice_3 = "Valaki betört a kutatóosztályra: fájlokat másolt le, és a folyamatban lévő kutatást a felével visszavetette."
multiplayer_window.sabotage_handyman = "Gonosz gondnok"
multiplayer_window.sabotage_headhunter = "Fejvadász"
multiplayer_window.sabotage_headhunter_left = "%s elment egy jobb ajánlatért."
multiplayer_window.sabotage_headhunter_notice = "%s jobb állásajánlatot kapott egy másik kórháztól, és $%d béremelést kér. Egyezz bele 10 napon belül, különben elmegy."
multiplayer_window.sabotage_headhunter_won = "%s otthagyta a kórházát, és felkerült a felvehetők listájára: vedd fel %d napon belül, mielőtt bárki más megtehetné."
multiplayer_window.sabotage_level = "L%d  $%d"
multiplayer_window.sabotage_level_locked = "L%d  %d. hónap"
multiplayer_window.sabotage_levels.boiler[1] = "Az ő kazánjuk elromlik: télen túl hideg, nyáron túl meleg lesz, amíg a gondnokaik meg nem javítják (rövid javítás)."
multiplayer_window.sabotage_levels.boiler[2] = "Az ő kazánjuk elromlik, nagyjából kétszer olyan hosszú időre. Több gondnok hamarabb megjavítja."
multiplayer_window.sabotage_levels.boiler[3] = "Az ő kazánjuk súlyosan elromlik: hosszú javítás. Több gondnok hamarabb megjavítja."
multiplayer_window.sabotage_levels.emergency[1] = "Vészhelyzet, amit nem utasíthatnak vissza: 3 beteg érkezik helikopterrel, olyan betegséggel, amit ismernek."
multiplayer_window.sabotage_levels.emergency[2] = "Vészhelyzet, amit nem utasíthatnak vissza: 6 beteg érkezik helikopterrel, olyan betegséggel, amit ismernek."
multiplayer_window.sabotage_levels.emergency[3] = "Vészhelyzet, amit nem utasíthatnak vissza: 10 beteg érkezik helikopterrel, talán olyan betegséggel, amit még nem fedeztek fel."
multiplayer_window.sabotage_levels.epidemic[1] = "2 fertőző beteg érkezik a kórházukba ugyanazzal a betegséggel."
multiplayer_window.sabotage_levels.epidemic[2] = "4 fertőző beteg érkezik a kórházukba ugyanazzal a betegséggel."
multiplayer_window.sabotage_levels.epidemic[3] = "7 fertőző beteg érkezik a kórházukba ugyanazzal a betegséggel."
multiplayer_window.sabotage_levels.espionage[1] = "Lemásolhatod egy gyógyszer vagy gép egy fejlesztését, ami nekik megvan, neked nincs: te választod ki."
multiplayer_window.sabotage_levels.espionage[2] = "Lemásolhatod egy felfedezésüket (gép vagy szoba), ami nekik megvan, neked nincs: te választod ki."
multiplayer_window.sabotage_levels.espionage[3] = "Lemásolhatod két fejlesztésüket vagy felfedezésüket (te választasz), és a jelenlegi kutatásukat a felével visszavetheted."
multiplayer_window.sabotage_levels.handyman[1] = "Egy gondnok, aki úgy néz ki, mint az övék, de nem dolgozik, 4 hónapig. Ha megtalálják és kirúgják, hozzád jön dolgozni."
multiplayer_window.sabotage_levels.handyman[2] = "Mint az L1, és emellett naponta kétszer szemetet szór a folyosóikon, 3 hónapig."
multiplayer_window.sabotage_levels.handyman[3] = "Mint az L2, és emellett 3 naponta úgy tesz, mintha megjavítana egy gépet, de majdnem tönkreteszi. 2 hónapig marad."
multiplayer_window.sabotage_levels.headhunter[1] = "Legjobb rezidensük vagy nővérük jobb ajánlatot kap: 10 napon belül 50%-os béremelést fizetnek, vagy elveszítik a felvehetők listájára (2 hétig megőrizve neked)."
multiplayer_window.sabotage_levels.headhunter[2] = "Legjobb doktoruk jobb ajánlatot kap: 10 napon belül 75%-os béremelést fizetnek, vagy elveszítik a felvehetők listájára (2 hétig megőrizve neked)."
multiplayer_window.sabotage_levels.headhunter[3] = "Legjobb konzulánsuk vagy szakorvosuk jobb ajánlatot kap: 10 napon belül megduplázzák a fizetését, vagy elveszítik a felvehetők listájára (2 hétig megőrizve neked)."
multiplayer_window.sabotage_levels.rats[1] = "5 patkány költözik be. Amíg szaladgálnak, naponta legfeljebb 1 hírnévbe kerülnek nekik (legfeljebb 30 napig), amíg le nem lövik őket."
multiplayer_window.sabotage_levels.rats[2] = "10 patkány költözik be. Amíg szaladgálnak, naponta legfeljebb 2 hírnévbe kerülnek nekik (legfeljebb 30 napig), amíg le nem lövik őket."
multiplayer_window.sabotage_levels.rats[3] = "20 patkány költözik be. Amíg szaladgálnak, naponta legfeljebb 3 hírnévbe kerülnek nekik (legfeljebb 30 napig), amíg le nem lövik őket."
multiplayer_window.sabotage_levels.smear[1] = "Rossz sajtó egy hónapig: az új betegeik 10-ből 3 inkább a többi kórházba megy."
multiplayer_window.sabotage_levels.smear[2] = "Rossz sajtó 2 hónapig: az új betegeik 10-ből 4 inkább a többi kórházba megy."
multiplayer_window.sabotage_levels.smear[3] = "Rossz sajtó 3 hónapig: az új betegeik fele inkább a többi kórházba megy."
multiplayer_window.sabotage_locked_tooltip = "Ezen a szinten a játék %d. hónapjától vásárolható meg."
multiplayer_window.sabotage_next = "Következő rivális"
multiplayer_window.sabotage_pick = "Kattints egy fokozatra, hogy lásd, mit csinál. Kattints rá újra a megvételhez."
multiplayer_window.sabotage_rats = "Patkánytámadás"
multiplayer_window.sabotage_rats_notice = "Patkányok! Egy raj költözött a kórházba. Amíg szaladgálnak, naponta hírnévbe kerülnek: kattints rájuk, és lődd le őket."
multiplayer_window.sabotage_rats_reminder = "Még %d patkány szaladgál a kórházban, és naponta hírnévbe kerülnek."
multiplayer_window.sabotage_refused = "Ez a piszkos trükk nem hajtható végre: %s."
multiplayer_window.sabotage_sent = "Megrendelve. Akkor fizetsz, ha megtörtént."
multiplayer_window.sabotage_smear = "Lejárató kampány"
multiplayer_window.sabotage_smear_notice = "Rossz sajtó: a kórház elleni lejárató kampány távol tart néhány beteget (hónapok: %d)."
multiplayer_window.sabotage_smear_over = "A lejárató kampánynak vége: a betegek újra úgy jönnek a kórházba, mint azelőtt."
multiplayer_window.sabotage_spy_caption = "Kémkedés: %s, választható: %d"
multiplayer_window.sabotage_spy_pick = "Válaszd ki, mit másoljon le a kémed, aztán nyomd meg a Lopás gombot."
multiplayer_window.sabotage_spy_steal = "Lopás ($%d)"
multiplayer_window.sabotage_transaction = "Piszkos trükkök"
multiplayer_window.sabotage_went_home = "A gonosz gondnokod ideje %s kórházában lejárt. Hazament."
multiplayer_window.saved_flag = "  mentett játék"
multiplayer_window.saved_note = "Játék elmentve: %s"
multiplayer_window.saving_note = "A játék mentése minden játékos gépén..."
multiplayer_window.select_room = "Előbb válassz egy szobát."
multiplayer_window.server = "Szerver"
multiplayer_window.server_eu1 = "EU1: stabil"
multiplayer_window.server_eu2 = "EU2: tesztverziók"
multiplayer_window.server_version = "a szerver verziója"
multiplayer_window.share_research = "Kutatás megosztása"
multiplayer_window.shared_won = "A következő szintre lépés többjátékos módban nem elérhető."
multiplayer_window.sharing_off = "Kutatásmegosztás: ki"
multiplayer_window.sharing_on = "Kutatásmegosztás: be"
multiplayer_window.staff_arrived_note = "%s megérkezett, és munkába áll."
multiplayer_window.staff_bought_transaction = "Személyzet tőle: %s"
multiplayer_window.staff_on_the_way = "Úton ide: %s"
multiplayer_window.staff_received_note = "%s alkalmazottat küldött neked: %s"
multiplayer_window.staff_sold_transaction = "Személyzet neki: %s"
multiplayer_window.start = "Játék indítása"
multiplayer_window.team_button = "%d. csapat"
multiplayer_window.team_lost = "%s az év végén sem teljesítette a szint céljait, ezért a csapat elvesztette a szintet."
multiplayer_window.team_member_out = "A kórházad két éve egymás után nem teljesítette a szint céljait, és kiesett a versenyből. A csapatod versenyez tovább."
multiplayer_window.team_member_out_other = "%s két éve egymás után nem teljesítette a célokat, és kiesett a versenyből; a csapata versenyez tovább."
multiplayer_window.team_race_mate_reached_fax[1] = "A csapattársad, %s teljesítette a szint céljait!"
multiplayer_window.team_race_mate_reached_fax[2] = "A csapatod akkor nyer, ha a te kórházad is eléri őket. Még hátravan: %s."
multiplayer_window.team_race_mate_reached_fax[3] = "A csapattársad segíthet neked pénzzel, személyzettel vagy betegekkel."
multiplayer_window.team_race_reached_fax[1] = "A kórházad teljesítette a szint céljait!"
multiplayer_window.team_race_reached_fax[2] = "A verseny még nincs megnyerve: a csapatod akkor nyer, ha minden kórháza eléri a célokat. Még hátravan: %s."
multiplayer_window.team_race_reached_fax[3] = "Tartsd működésben a kórházadat, és segíts nekik pénzzel, személyzettel vagy betegekkel."
multiplayer_window.team_race_reached_other = "%s teljesítette a szint céljait (%s. csapat)."
multiplayer_window.team_won[1] = "Gratulálunk!"
multiplayer_window.team_won[2] = "Minden kórház teljesítette a szint céljait: a csapat megnyerte a szintet."
multiplayer_window.team_won[3] = "Visszamész a lobbiba, vagy folytatod a játékot?"
multiplayer_window.too_many_hospitals = "A pályára %d kórház fér: osszatok meg színeket"
multiplayer_window.trade_alone = "Nincs kivel kereskedni."
multiplayer_window.trade_caption = "Kereskedés vele: %s"
multiplayer_window.trade_close = "Bezár"
multiplayer_window.trade_free = "Ár: ingyen"
multiplayer_window.trade_next_player = "Következő játékos"
multiplayer_window.trade_no_staff = "Nincs elküldhető alkalmazottad."
multiplayer_window.trade_offered = "Felajánlva. Hozzád csatlakozik, ha a másik játékos elfogadja."
multiplayer_window.trade_on_the_way = "- felajánlva"
multiplayer_window.trade_price = "Ár: $%d"
multiplayer_window.trade_select_staff = "Előbb kattints egy alkalmazottra."
multiplayer_window.trade_send_money = "Küldés: $%d"
multiplayer_window.trade_send_staff = "A kijelölt felajánlása"
multiplayer_window.trade_sent = "Elküldve. Mindjárt megérkezik."
multiplayer_window.tricks_off = "Piszkos trükkök (versenyek): ki"
multiplayer_window.tricks_on = "Piszkos trükkök (versenyek): be"
multiplayer_window.vaccination_mode_hint = "Oltási mód: kattints a fertőzött betegekre, hogy egy nővér beoltsa őket. Jobb kattintás, Esc vagy újabb kattintás a fecskendőre kilép az üzemmódból."
multiplayer_window.vote_agree = "Egyetértek"
multiplayer_window.vote_asked = "Megkérted a többieket, hogy a sebesség legyen: %s."
multiplayer_window.vote_decline = "Elutasítás"
multiplayer_window.vote_declined = "%s elutasította a sebességváltást: %s."
multiplayer_window.vote_lapsed = "Időben nem értett egyet elég játékos: a sebesség marad, ami volt."
multiplayer_window.vote_open = "A sebességváltásról már szavaznak."
multiplayer_window.vote_passed = "A játékosok egyetértettek: a sebesség most: %s."
multiplayer_window.vote_passed_paused = "A játékosok ebben egyeztek meg: %s - a játék ezzel a sebességgel folytatódik a szünet után."
multiplayer_window.vote_request = "%s szeretné megváltoztatni a játék sebességét"
multiplayer_window.vote_request_speed = "erre: %s."
multiplayer_window.waiting_player = "várakozás játékosra..."
tooltip.multiplayer_window.ask_money = "Kérj pénzt egy másik játékostól. Ő dönti el, fizet-e."
tooltip.multiplayer_window.auctions = "A házigazda dönti el, mely telkek kerülnek árverésre, amikor egy játékos meg akar venni egyet"
tooltip.multiplayer_window.auctions_all = "Minden telek árverésre kerül az összes olyan kórház között, amely megvehetné"
tooltip.multiplayer_window.auctions_near = "A másik játékos oldalán lévő vagy egy másik kórház földje melletti telkek árverésre kerülnek; a többit egyszerűen megveszik"
tooltip.multiplayer_window.auctions_none = "Nincs árverés: a telket az veszi meg, aki előbb kéri"
tooltip.multiplayer_window.colour = "A kórházad színe: az azonos színű játékosok közösen építenek egy kórházat. Kattints a módosításához (a házigazda bárkiét módosíthatja, a botokét is)"
tooltip.multiplayer_window.connect = "Csatlakozás a szerverhez, és a szobáinak megjelenítése"
tooltip.multiplayer_window.continue_game = "Egy korábban mentett többjátékos játék folytatása (Fájl > Mentés, vagy a havi automatikus mentés): válaszd ki a listából. Kijelölés nélkül a szoba új játékot indít"
tooltip.multiplayer_window.download = "Ez a szerver a játék egy másik verzióját futtatja: nyisd meg a letöltési oldalát a böngésződben"
tooltip.multiplayer_window.game_options = "A játék beállításai: telekárverések és más (a házigazda állítja be)"
tooltip.multiplayer_window.level = "Válaszd ki a szintet egy listából a céljaival és egy térképpel. Az egy közös kórház a kampány szintjeit játssza; több kórház a többjátékos szinteket (1-től 8-ig, a nagyobb szám a 8. szintet játssza). A 6. szint a Vészhelyzet!: az első évben havonta négy vészhelyzet, aztán járványok; a 7. szint a Könyörtelen, versenyre való: havonta újabb piszkos trükkök, állásbörzék, versenyvészhelyzetek és földrengések; a 8. szint a Team Town, Matroftt térképe két-a-kettő ellen"
tooltip.multiplayer_window.levels_players = "A térkép ennyi játékosnak (minden játékosszámnak saját térképe van)"
tooltip.multiplayer_window.name = "A név, amit a többi játékos lát"
tooltip.multiplayer_window.new_game = "Új játék indítása a mentett helyett"
tooltip.multiplayer_window.password = "A csatlakozandó vagy létrehozandó szoba jelszava (üres: nincs jelszó)"
tooltip.multiplayer_window.player_row = "Kattintás: a játékos kórházának megtekintése (N: a következő kórház)"
tooltip.multiplayer_window.players = "Hány játékosnak készül a szoba"
tooltip.multiplayer_window.ready = "Jelezd a házigazdának, hogy készen állsz az indulásra"
tooltip.multiplayer_window.refer_button = "Felajánlod ezt a beteget egy másik játékos kórházának. El kell fogadnia."
tooltip.multiplayer_window.send_staff = "Elküldöd ezt az alkalmazottat egy másik játékos kórházába. El kell fogadnia."
tooltip.multiplayer_window.server = "A többjátékos szerver címe, például eu2.bachelor-tech.com:47800"
tooltip.multiplayer_window.server_eu1 = "eu1.bachelor-tech.com: a legújabb stabil kiadás"
tooltip.multiplayer_window.server_eu2 = "eu2.bachelor-tech.com: a legújabb tesztverzió"
tooltip.multiplayer_window.share_research = "Ajánld fel a meglévő kutatásodat egy másik játékos kórházának, ingyen vagy áron. El kell fogadnia."
tooltip.multiplayer_window.sharing = "A házigazda dönt: a játékosok megoszthatják vagy eladhatják egymásnak a kutatást, vagy nem (mint az eredeti játékban)"
tooltip.multiplayer_window.start = "A játék elindítása mindenkinek a szobában"
tooltip.multiplayer_window.team = "A csapatod: az azonos csapat együtt nyer, a különböző csapatok versenyeznek a célokért, és piszkos trükköket játszhatnak egymással. Kattints a módosításához (a házigazda bárkiét módosíthatja, a botokét is)"
tooltip.multiplayer_window.tricks = "A házigazda dönt: versenyben a játékosok vehetnek piszkos trükköket a riválisok ellen, vagy nem (mint az eredeti játékban)"
