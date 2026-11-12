--[[ Copyright (c) 2010 Manuel "Roujin" Wolf, "Fabiomsouto"
Copyright (c) 2011 Sérgio "Get_It" Ribeiro
Copyright (c) 2012 <Filipe "Aka" Carvalho>

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
Language(utf8 "Português", "Portuguese", "pt", "pt")
Inherit("english")
IsArabicNumerals(true)

-------------------------------  OVERRIDE  ----------------------------------
adviser.warnings.money_low = "Estás a ficar sem dinheiro!" -- Funny. Exists in German translation, but not existent in english?
-- TODO: tooltip.graphs.reputation -- this tooltip talks about hospital value. Actually it should say reputation.
-- TODO: tooltip.status.close -- it's called status window, not overview window.

-- The originals of these two contain one space too much
fax.emergency.cure_not_possible_build = "Vais precisar de construir %s"
fax.emergency.cure_not_possible_build_and_employ = "Vais precisar de construir um %s e empregar um %s"

-- Improve tooltips in staff window to mention hidden features
tooltip.staff_window.face = "A cara desta pessoa - clique para abrir o ecrã de gestão de pessoal"
tooltip.staff_window.center_view = "Clique esquerdo para ir para onde está a pessoa, clique direito para navegador através dos funcionários"

-- These strings are missing in some versions of TH (unpatched?)
confirmation.restart_level = "Tem a certeza que deseja reiniciar este nível?"

-------------------------------  NEW STRINGS  -------------------------------
confirmation.maximum_screen_size = "A resolução de ecrã que escolheu é maior que 3000 x 2000. Resoluções mais altas são possíveis, mas requerem melhor hardware de forma a manter uma taxa de fotogramas (FPS) jogável. De certeza que deseja continuar?"
confirmation.music_warning = "Antes de escolher usar mp3 para a música dentro do jogo, necessita de ter o smpeg.dll ou equivalente para o seu sistema operativo, caso contrário, não terá música no jogo. Deseja continuar?"
menu_options_wage_increase.deny = "    NEGAR "
menu_options_wage_increase.grant = "    PERMITIR "
tooltip.audio_window.audio_button = "Ligar ou desligar todo o som do jogo"
tooltip.audio_window.audio_toggle = "Ligar ou desligar"
tooltip.options_window.folder = "Opções de pastas"
tooltip.options_window.customise = "Mais opões que pode alterar para personalizar a sua experiência de jogo."
tooltip.update_window.download = "Vá para a página de transferências para a última versão de CorsixTH"
tooltip.update_window.ignore = "Ignorar esta actualização agora. Será notificado de novo na próxima vez que inicializar CorsixTH"
tooltip.folders_window.browse_font = "Procurar outro tipo de letra (localização actual: %1% )"
tooltip.folders_window.screenshots_location = "Por defeito, as capturas de ecrã são armazenadas numa pasta junto do ficheiro de configuração. Caso isto não seja apropriado, pode escolher a sua própria, simplesmente indique qual a pasta que deseja utilizar."
tooltip.folders_window.reset_to_default = "Reinicializar a directoria para a localização por defeito ( %1% )"
tooltip.folders_window.clear_directory = "Limpar seleção de diretório atual"
tooltip.folders_window.back = "Fechar este menu e voltar às definições."
tooltip.folders_window.music_location = "Escolha a localização dos seus ficheiros mp3. A pasta já deve ter sido criada, e agora escolha o directório que acabou de criar."
tooltip.folders_window.font_location = "Localização de um tipo de letra capaz de mostrar caracteres Unicode requeridos pela sua língua. Se isto não for especificado, não será capaz de escolher línguas que necessitam de mais caracteres que o jogo original consegue fornecer. Exemplo: Russo e Chinês."
tooltip.folders_window.savegames_location = "Por defeito, os jogos gravados são armazenados numa pasta junto do ficheiro de configuração. Caso isto não seja apropriado, pode escolher a sua própria, simplesmente indique qual a pasta que deseja utilizar."
tooltip.folders_window.browse_data = "Escolha outra localização da instalação do Theme Hospital (localização actual: %1% )"
tooltip.folders_window.browse = "Escolha a localização da pasta"
tooltip.folders_window.browse_screenshots = "Escolha outra localização para a pasta das capturas de ecrã (Localização actual: %1%) "
tooltip.folders_window.browse_music = "Escolha outra localização para a pasta da música (Localização actual: %1%) "
tooltip.folders_window.no_font_specified = "Nenhum tipo de letra especificado!"
tooltip.folders_window.not_specified = "Nenhuma pasta especificada!"
tooltip.folders_window.browse_saves = "Escolha outra localização para a pasta dos jogos gravados (Localização actual: %1%) "
tooltip.folders_window.default = "Localização por defeito"
tooltip.folders_window.data_location = "O directório da instalação do Theme Hospital original, que é necessário para correr o CorsixTH"
tooltip.customise_window.alien_dna_only_by_emergency = "Devido à falta de animações apropriadas, colocamos por defeito que pacientes com ADN Extraterrestre só possam surgir numa emergência. Para permitir que estes pacientes possam visitar o hospital de outra forma, desligue esta opção."
tooltip.customise_window.enable_avg_contents = "Se quer que o jogo lhe lembre que objectos adicionais costuma adicionar quando cria uma sala, ligue esta opção."
tooltip.customise_window.back = "Fechar este menu e voltar às definições."
tooltip.customise_window.movies = "Controle geral de vídeos, isto irá permitir desligar todos os vídeos"
tooltip.customise_window.disable_fractured_bones_females = "Devido a uma má animação colocamos por defeito que não existem pacientes femininas com Ossos Partidos. De forma a permitir que pacientes femininas com Ossos Partidos visitem o hospital, desligue esta opção."
tooltip.customise_window.play_intro = "Ligar ou desligar o vídeo de introdução, o controle geral de vídeos tem que estar ligado se quer ver a introdução cada vez que começa o CorsixTH"
tooltip.customise_window.allow_user_actions_while_paused = "No Theme Hospital o jogador apenas podia utilizar o menu de topo se o jogo estivesse pausado. Esta é também a opção por defeito no CorsixTH, mas ao activar esta opção, tudo é permitido com o jogo pausado."
update_window.caption = "Actualização Disponível!"
update_window.new_version = "Nova Versão:"
update_window.current_version = "Versão Actual:"
update_window.download = "Ir à página de transferências"
update_window.ignore = "Saltar e ir para o menu principal"
errors.disable_fractured_bones_females = "AVISO: A animação para pacientes femininas com Ossos Partidos não é perfeita."
errors.alien_dna_only_by_emergency = "AVISO: Não existem animação para pacientes Extraterrestres a sentarem-se, abrir ou bater em portas, etc. Então, como no Theme Hospital, para executarem estas animações eles ficam com um aspecto normal, e depois voltam ao aspecto original. Pacientes com ADN Extraterrestre só irão aparecer se estiver previsto no nível."
errors.load_quick_save = "Erro, não foi possível carregar o quick save já que não existe. Nada de preocupações, já que criamos agora um para si!"
folders_window.data_label = "Dados TH"
folders_window.music_location = "Escolha a directoria que usar para a sua música"
folders_window.music_label = "MP3's"
folders_window.new_th_location = "Aqui pode especificar uma nova pasta de instalação do Theme Hospital. Assim que escolher a nova directoria, o jogo irá reiniciar."
folders_window.caption = "Localizações de pastas"
folders_window.screenshots_label = "Capturas de ecrã"
folders_window.font_label = "Tipos de letra"
folders_window.savegames_label = "Jogos gravados"
folders_window.back = "Retroceder"
folders_window.savegames_location = "Escolha a directoria que usar para jogos gravados"
folders_window.screenshots_location = "Escolha a directoria que usar para capturas de ecrã"
customise_window.enable_avg_contents = "Itens comuns"
customise_window.option_on = "Ligado"
customise_window.allow_user_actions_while_paused = "Construir com o jogo pausado"
customise_window.option_off = "Desligado"
customise_window.play_intro = "Reproduzir vídeo de introdução"
customise_window.caption = "Definições Personalizadas"
customise_window.back = "Retroceder"
customise_window.movies = "Controle Geral de Vídeos"
customise_window.alien_dna_only_by_emergency = "Pacientes Extraterrestres"
customise_window.disable_fractured_bones_females = "Ossos Partidos"
options_window.folder = "Pastas"
options_window.customise = "Personalizar"
audio_window.audio = "Som Geral"
menu_options.twentyfour_hour_clock = "  RELÓGIO DE 24 HORAS  "
menu_options.wage_increase = "  EXIGÊNCIAS SALARIAIS"
install.ok = "OK"
install.cancel = "Cancelar"
adviser.research.drug_improved_1 = "A droga para %s foi melhorada pelo Departamento de Pesquisa"
adviser.warnings.no_desk_7 = "Já construiu o balcão de atendimento, então que tal contratar uma recepcionista? Não irá atender clientes até que resolva isto!"
adviser.warnings.researcher_needs_desk_1 = "Um Investigador precisa de ter uma secretária onde trabalhar."
adviser.warnings.no_desk_6 = "Já tem a recepcionista, então que tal construir uma balcão de atendimento para ela trabalhar?"
adviser.warnings.nurse_needs_desk_1 = "Cada Enfermeira necessita de uma secretária onde trabalhar."
adviser.warnings.researcher_needs_desk_2 = "O seu Investigador está satisfeito que o tenha deixado descansar um pouco. Se quer ter mais pessoal a fazer pesquisa, então precisa de dar uma secretária a cada um deles."
adviser.warnings.no_desk_5 = "Está na hora, devem estar a chegar pacientes a qualquer momento!"
adviser.warnings.no_desk_4 = "Uma recepcionista precisa de ter o seu posto de trabalho para atender os pacientes assim que chegam."
adviser.warnings.researcher_needs_desk_3 = "Cada Investigador necessita de uma secretária onde trabalhar."
adviser.warnings.cannot_afford_2 = "Não tem dinheiro suficiente no banco para fazer essa compra!"
adviser.warnings.nurse_needs_desk_2 = "A sua Enfermeira está satisfeita que a tenha deixado descansar um pouco. Se quer ter mais que uma a trabalhar na enfermaria, então precisa de dar uma secretária a cada uma delas."
object.litter = "Lixo"
tooltip.objects.litter = "Lixo: Deitado fora por um paciente porque não encontrou um caixote do lixo onde o colocar."

menu_options.lock_windows = "  BLOQUEAR JANELAS  "
menu_options_game_speed.pause = "  (%1%) PAUSA  "

menu_debug = {
  transparent_walls           = "  (%1%) PAREDES TRANSPARENTES  ",
  limit_camera                = "  LIMITAR CAMARA  ",
  disable_salary_raise        = "  DESACTIVAR AUMENTO DOS SALÁRIOS  ",
  make_debug_patient          = "  MAKE DEBUG PATIENT  ",
  spawn_patient               = "  GERAR PACIENTE  ",
  make_adviser_talk           = "  MAKE ADVISER TALK  ",
  show_watch                  = "  MOSTRAR RELÓGIO  ",
  create_emergency            = "  CRIAR EMERGENCIA  ",
  place_objects               = "  COLOCAR OBJECTOS  ",
  dump_strings                = "  (%1%) DUMP DAS STRINGS  ",
  map_overlay                 = "  OVERLAY DO MAPA  ",
  sprite_viewer               = "  VISUALIZAR SPRITES  ",
}
menu_debug_overlay = {
  none                        = "  NENHUM  ",
  flags                       = "  FLAGS  ",
  positions                   = "  POSIÇOES  ",
  byte_0_1                    = "  BYTE 0 & 1  ",
  byte_floor                  = "  BYTE FLOOR  ",
  byte_n_wall                 = "  BYTE N WALL  ",
  byte_w_wall                 = "  BYTE W WALL  ",
  byte_5                      = "  BYTE 5  ",
  byte_6                      = "  BYTE 6  ",
  byte_7                      = "  BYTE 7  ",
  parcel                      = "  PARCEL  ",
}
adviser.room_forbidden_non_reachable_parts = "Colocar o espaço neste sítio bloquearia o acesso a zonas do hospital."

dynamic_info.patient.actions.no_gp_available = "À espera que seja construidos um consultório de CG."
dynamic_info.staff.actions.heading_for = "Indo para %s"

misc.not_yet_implemented = "(not yet implemented)"
misc.no_heliport = "Hm... Ou não foram desocbertas novas doenças ou não existe um heliporto neste mapa."

main_menu = {
  new_game = "Novo jogo",
  custom_level = "Nível Personalizado",
  load_game = "Carregar Jogo",
  options = "Opçoes",
  exit = "Sair",
}

tooltip.main_menu = {
  new_game = "Começar um jogo de raíz",
  custom_level = "Construir o meu hospital",
  load_game = "Carregar um jogo",
  options = "Ajustar preferencias",
  exit = "Nao, por favor, nao saias!",
}

load_game_window = {
  back = "Voltar",
}

tooltip.load_game_window = {
  load_game_number = "Carregar o jogo %d",
  load_autosave = "Carregar o jogo gravado automaticamente",
  back = "Fechar a janela de carregamento",
}


errors = {
  dialog_missing_graphics = "Desculpa, mas a versão de demonstração não tem este diálogo!",
  save_prefix = "Erro durante a gravação do jogo: ",
  load_prefix = "Erro durante o carregamento do jogos: ",
}

totd_window = {
  tips = {
    "Todos os hospitais precisam de uma recepção e de um consultório de CG para começar. Depois disso, depende do tipo de pacientes que recebes. Uma farmácia é sempre uma boa escolha, no entanto.",
    "Máquinas como a Bomba de Encher Cabeças precisam de manutenção. Contrata um ou dois funcionários para reparar as tuas máquinas, ou arriscas-te a que o pessoal ou os pacientes se aleijem quando elas avariarem.",
    "Após algum tempo, o teu pessoal vai ficar cansado. Constrói um Quarto do Pessoal, para que eles possam relaxar.",
    "Coloca radiadores em quantidade suficiente para que o teu pessoal e pacientes estejam quentinhos... caso contrário irao ficar aborrecidos!",
    "O nível de perícia de um médico influencia a qualidade e velocidade do seu diagnóstico. Coloca um médico com perícia nas salas de CGs, e não precisarás de tantas salas de diagnóstico.",
    "Médicos júniores e regulares podem aumentar a sua perícia se aprenderem com um consultante numa Sala de Treino. Se o consultante for especialista (cirurgiao, psiquiatra ou investigador), também ensinará a sua especialização aos seus pupilos.",
    "Já tentaste escrever o número de emergência (112) no fax? Não te esqueças de ligar as colunas!",
    "O menu de opçoes ainda não está implementado, mas podes ajustar algumas preferencias tais como resoluçao e língua no ficheiro config.txt na pasta do jogo.",
    "Seleccionaste outra linguagem além do Ingles, mas ves Ingles em todo o lado? Ajuda-nos a traduzir esse texto!",
    "A equipa do CorsixTH está à procura de reforços! Estás interessado em programar, traduzir ou criar arte gráfica para o CorsixTH? Contacta-nos no fórum, IRC (corsix-th no freenode) ou via Mailing List.",
    "Se encontrares um bug, diz-nos em: th-issues.corsix.org",
    "Tens que cumprir certos requisitos para poder avançar de nível. Consulta a tua janela de status para veres o progresso em relaçao aos objectivos do nível.", -- dicas juntas
    "Se quiseres alterar ou remover alguma sala existente,utiliza o botao editar na barra de ferramentas em baixo no teu ecra.",
    "Se tiveres muitos pacientes na fila de espera, podes saber rapidamente quais estao à espera de uma determinada sala passando com o cursor por cima desta.",
    "Clica numa porta para ver a lista de espera.Podes alterar a ordem dos pacientes ou mandá-los para outra sala.",
    "Staffs descontentes irao pedir aumentos de salário frequentemente , assegura que tens um bom ambiente de trabalho para isto não acontecer!",
    "Os pacientes ficarao com sede enquanto esperam no hospital,ainda mais se os radiadores estiverem muito quentes.Coloca máquinas de bebidas em locais estratégicos para ganhares mais uns trocos.",
    "Podes abortar o processo de diagnóstico para um paciente e tentar adivinhar a cura caso já tenhas descoberto a doença. Cuidado que este processo pode aumentar o risco de uma cura errada levando à morte do paciente.",
    "Emergencias sao uma boa forma de ganhar algum dinheiro extra,garante que o teu hospital tem condiçoes para as completar.",
  },
  previous = "Dica anterior",
  next = "Próxima dica",
}

tooltip.totd_window = {
  previous = "Mostrar dica anterior",
  next = "Mostrar a próxima dica",
}


debug_patient_window.caption = "Debug Paciente"



totd_window = {
  tips = {
    "Tens que cumprir certos requisitos para poder avançar de nível. Consulta a tua janela de status para veres o progresso em relaçao aos objectivos do nível.",
    "Se quiseres alterar ou remover alguma sala existente,utiliza o botao editar na barra de ferramentas em baixo no teu ecra.",
    "Se tiveres muitos pacientes na fila de espera, podes saber rapidamente quais estao à espera de uma determinada sala passando com o cursor por cima desta.",
    "Clica numa porta para ver a lista de espera.Podes alterar a ordem dos pacientes ou mandá-los para outra sala.",
    "Staffs descontentes irao pedir aumentos de salário frequentemente , assegura que tens um bom ambiente de trabalho para isto não acontecer!",
    "Os pacientes ficarao com sede enquanto esperam no hospital,ainda mais se os radiadores estiverem muito quentes.Coloca máquinas de bebidas em locais estratégicos para ganhares mais uns trocos.",
    "Podes abortar o processo de diagnóstico para um paciente e tentar adivinhar a cura caso já tenhas descoberto a doença. Cuidado que este processo pode aumentar o risco de uma cura errada levando à morte do paciente.",
    "Emergencias sao uma boa forma de ganhar algum dinheiro extra,garante que o teu hospital tem condiçoes para as completar.",
  },
}



tooltip.casebook.cure_requirement.hire_staff = "Precisas de contratar alguém para fazer este tratamento."
tooltip.casebook.cure_type.unknown = "Ainda não sabes tratar esta doença."
tooltip.information.close = "Fecha o diálogo de informação"
tooltip.load_game_window.load_game = "Ler jogo: %s"



tooltip = {
  message = {
    button = "Clica com o botão esquerdo para abrir a mensagem.",
    button_dismiss = "Click esquerdo para abrir a mensagem,click direito para apagar",
  },


  custom_game_window = {
    start_game_with_name = "Ir para o nível %s",
  },


  cheats_window = {
    close = "Fecha a janela dos truques",

    cheats = {
      end_month = "Salta para o final do mês.",
      create_patient =  "Cria um paciente no mapa.",
      money = "Adiciona 10000 à tua conta bancária",
      emergency = "Cria uma emergência",
      win_level = "Vence o nível.",
      lose_level = "Perde o nível.",
      vip = "Cria um VIP.",
      all_research = "Completa toda a pesquisa.",
      end_year = "Salta para o final do ano.",
      },
    },





  menu_list_window = {
    save_date = "Coloca a lista por data de modificação.",
    name = "Coloca a lista por nome.",
    back = "Fecha esta janela.",
    },


  new_game_window = {
    hard = "Se estás habituado a este tipo de jogos e procuras um desafio escolhe esta opçao.",
    cancel = "Oh mas eu não queria começar um jogo de novo!",
    tutorial = "Se precisas de umas dicas para começar a jogar,marca esta caixa.",
    easy = "Se és novo em jogos de simulaçoes,esta é a opçao para ti.",
    medium = "Se já te sentes à vontade tenta a opção média!",
    },


  save_game_window = {
    new_save_game = "Nome para salvar o jogo.",
    save_game = "Gravar por cima da gravação? %s",
    },


  calls_dispatcher = {
    assigned = "Esta caixa estrá marcada, se alguém esttiver a tratar da tarefa correspondente.",
    task = "Lista de tarefas - Clica em tarefas para abrir as tarefas atribuídas ao staff e encontrares a localização de determinada tarefa.",
    close = "Fecha a janela de diálogo do expedidor de chamadas.",
    },


  research_policy = {
    research_progress = "Progresso em relação à próxima descoberta: %1%/%2%",
    no_research = "Não está a ser feita nenhuma pesquisa de momento.",
    },


    lua_console = {
    textbox = "Coloca aqui o código Lua para executar",
    execute_code = "Executa o código colocado.",
    close =  "Fecha a consola.",
    },


    fax = {
      close = "Fecha esta janela sem apagar a mensagem.",
    },


  options_window = {
    browse = "Procura outra localizaçao da instalaçao original. %1%",
    language = "Escolhe %s como a tua linguagem.",
    back = "Fecha a janela de opçoes.",
    },
  graphics_window = {
    fullscreen_button = "Clica para modo de tela cheia",
    width = "Coloca a largura desejada.",
    height = "Coloca a altura desejada.",
  },

}



custom_game_window.caption = "Jogo Customizado"



cheats_window = {
  cheats = {
    end_month = "Fim do Mês",
    create_patient = "Criar Paciente",
    money = "Truque para Dinheiro",
    emergency = "Criar emergência",
    win_level = "Vencer nível",
    lose_level = "Perder nível",
    vip = "Criar VIP",
    all_research = "Pesquisa Completa",
    end_year = "Fim do Ano",
    },

    close = "Fechar",
    caption = "Truques",

  cheated = {
    no = "Truques usados?: Nao",
    yes = "Truques usados?: Sim",
    },

    warning = "Aviso:Se utilizares truques não irás ganhar pontos de reputação no final do nível!",
}



errors = {
  unavailable_screen_size = "Esta resolução não está disponível no modo de tela cheia.",
  maximum_screen_size = "Resolução máxima de 3000x2000.",
  map_file_missing = "Não foi encontrado o ficheiro do mapa %s para este nível!",
  minimum_screen_size = "Resolução mínima de %dx%d.",
}



date_format.daymonth = "%1% - %2% -"



menu_debug = {
  lua_console = "  (%1%) CONSOLA LUA",
  make_debug_fax = "  DEBUG FAX",
  calls_dispatcher = "  CHAMAR EXPEDIDOR",
  cheats = "  (%1%) TRUQUES",
  dump_gamelog = "  (%1%) CRIAR LOG DO JOGO",
  jump_to_level = "  SALTAR PARA OUTRO NIVEL",
}


menu_options = {
  edge_scrolling = "  EDGE SCROLLING  ",
  settings = "  PREFERENCIAS  ",
}



lua_console = {
  execute_code = "Executar",
  close = "Fechar",
}



install= {
  exit = "Sair",
  th_directory = "CorsixTH precisa dos ficheiros de dados da instalação original de Theme Hospital(ou demo) para funcionar. Localize a sua instalação atráves da caixa em baixo.",
  title = "--------------------------------- Instalação CorsixTH  ---------------------------------",
}



load_game_window.caption = "Ler Jogo"



adviser = {
 cheats = {
    th_cheat = "Parabéns batoteiro! Acabaste de desbloquear os truques!",
    hairyitis_cheat = "Activado cheat da doença Olfatis",
    roujin_on_cheat = "Activado o desafio Roujin! Boa sorte...",
    crazy_on_cheat = "Oh não! Os teus médicos estão malucos!",
    bloaty_off_cheat = "Desactivado truque das Cabeças Gigantes!",
    bloaty_cheat = "Activado truque das Cabeças Gigantes!",
    crazy_off_cheat = "Ufa... os teus médicos voltaram ao normal.",
    roujin_off_cheat = "Desafio Roujin desactivado.",
    hairyitis_off_cheat = "Desactivado truque da doença Olfatis",
    },


  warnings = {
    no_desk_2 = "Bom trabalho! Deve ser um recorde mundial: quase um ano completo e não há pacientes! Se desejas continuar a gerir este hospital tens que contratar uma recepcionista e construir uma recepção para receberes os pacientes!",
    no_desk = "Constrói uma recepçao e uma recepcionista para começar!",
    no_desk_1 = "Se queres que os pacientes venham ao teu hospital vais precisar de uma recepçao e uma recepcionista!",
    },
}


calls_dispatcher = {
  repair = "Reparar %s",
  summary = "%d Chamadas; %d atribuídas",
  close = "Fechar",
  watering = "Regar @ %d,%d",
  staff = "%s - %s ",
}

information = {
  level_lost = {
    "Que chatice! Perdeste. Mais sorte para a próxima!",
    "Razões da derrota:",
    reputation = "A tua reputação ficou abaixo de %d.",
    balance = "A tua conta bancària ficou abaixo de %d.",
    percentage_killed = "Mataste mais do que %d por cento dos pacientes.",
  },

  cannot_restart = "Infelizmente este jogo customizado foi gravado antes da implementação da função de reinício.",
  custom_game = "Bem-vindo ao CorsixTH. Diverte-te neste mapa customizado!",
}


new_game_window = {
  hard = "Consultor (Difícil)",
  cancel = "Cancelar",
  tutorial = "Tutorial ",
  easy = "Junior (Fácil)",
  medium = "Doutor (Médio)",
}


options_window = {
  browse = "Procurar...",
  new_th_directory = "Aqui podes escolher uma nova localizaçao da instalaçao de Theme Hospital,assim que o fizeres o jogo será reiniciado.",
  back = "Voltar",
}
graphics_window = {
  fullscreen = "Tela cheia",
  width = "Largura",
  height = "Altura",
  cancel = "Cancelar",
}

audio_window = {
  back = "Voltar",
}


menu_list_window = {
  save_date = "Modificado",
  name = "Nome",
  back = "Voltar",
}


save_game_window = {
  caption = "Gravar jogo",
  new_save_game = "Nova gravaçao",
}



fax.emergency.num_disease_singular = "Existe uma pessoa com %s e necessita de atenção imediata!"



fax.choices = {
  decline_new_level = "Continuar a jogar",
  accept_new_level = "Avançar para o nível seguinte",
  return_to_main_menu = "Voltar para o menu principal",
}



menu_debug_overlay.heat = "  TEMPERATURA  "


confirmation.abort_edit_room = "Estás a construir ou a editar uma sala. Se todos os objectos necessários estiverem colocados a sala estará terminada, caso contrário será eliminada. Continuar?"
confirmation.needs_restart = "Estas alterações requerem que reinicies o jogo,O progresso não gravado será perdido. Desejas continuar?"


dynamic_info.staff.actions.fired = "Despedido"



introduction_texts.demo =
  "Bem-vindo ao hospital do demo!//" ..
  "Infelizmente este demo só tem este nível.Contudo existe aqui muito trabalho para te manter ocupado! " ..
  "Encontrarás várias doenças que requerem salas diferentes para os seus tratamentos.Ao longo do tempo  " ..
  "irão ocorrer algumas emergências e precisarás de descobrir novos tratamentos atráves da sala de pesquisa. " ..
  "O teu objectivo é ganhar 100,000$,ter um hospital avaliado em 70,000$,uma reputação de 700 e uma cura de 75% dos pacientes. " ..
  "Garante que a tua reputação não cai abaixo de 300 e que não mates 40% dos teus pacientes senão perderás o nível.//" ..
  "Boa sorte!"



letter = {
  custom_level_completed = "Bom trabalho!Completaste todos os objectivos deste nível!",
  dear_player = "Caro %s",
  return_to_main_menu = "Desejas regressar ao menu principal ou continuar a jogar?",
}

staff_class = {
  nurse                 = "Enfermeira",
  doctor                = "Doutor",
  handyman              = "Contínuo",
  receptionist          = "Recepcionista",
  surgeon               = "Cirurgião",
}

-- Staff titles
-- these are titles used e.g. in the dynamic info bar
staff_title = {
  receptionist          = "Recepcionista",
  general               = "General", -- unused?
  nurse                 = "Enfermeira",
  junior                = "Junior",
  doctor                = "Doutor",
  surgeon               = "Cirurgião",
  psychiatrist          = "Psiquiatra",
  consultant            = "Consultor",
  researcher            = "Pesquisador",
}

staff_list = {
  morale       = "MORAL",
  tiredness    = "CANSAÇO",
  skill        = "QUALIFICAÇOES",
  total_wages  = "SALÁRIO",
}


-- Objects
object = {
  desk                  = "Secretária",
  cabinet               = "Arquivador",
  door                  = "Porta",
  bench                 = "Banco",
  table1                = "Mesa", -- unused object
  chair                 = "Cadeira",
  drinks_machine        = "Máquina de Bebidas",
  bed                   = "Cama",
  inflator              = "Inflador",
  pool_table            = "Mesa de Bilhar",
  reception_desk        = "Recepçao",
  table2                = "Mesa", -- unused object & duplicate
  cardio                = "Cardio",
  scanner               = "Scanner",
  console               = "Consola",
  screen                = "Ecra",
  litter_bomb           = "Bomba de lixo",
  couch                 = "Sofá",
  sofa                  = "Sofá",
  crash_trolley         = "Trolley",
  tv                    = "TV",
  ultrascanner          = "Ultrascanner",
  dna_fixer             = "Fixador de DNA",
  cast_remover          = "Removedor de Gesso",
  hair_restorer         = "Recuperador de Cabelo",
  slicer                = "Fatiador",
  x_ray                 = "Raio-X",
  radiation_shield      = "Escudo de Radiaçao",
  x_ray_viewer          = "Visualizador de Radiação",
  operating_table       = "Mesa de Operação",
  lamp                  = "Lampâda", -- unused object
  toilet_sink           = "Pia",
  op_sink1              = "Pia",
  op_sink2              = "Pia",
  surgeon_screen        = "Ecra de Operaçao",
  lecture_chair         = "Cadeira de aluno",
  projector             = "Projector",
  bed2                  = "Cama", -- unused duplicate
  pharmacy_cabinet      = "Gabinete de Farmácia",
  computer              = "Computador",
  atom_analyser         = "Analisador de Átomos",
  blood_machine         = "Máquina de Análise Sanguínea",
  fire_extinguisher     = "Extintor",
  radiator              = "Radiador",
  plant                 = "Planta",
  electrolyser          = "Electrolisador",
  jelly_moulder         = "Moldador gelatinoso",
  gates_of_hell         = "Portões do Inferno",
  bed3                  = "Cama", -- unused duplicate
  bin                   = "Balde do lixo",
  toilet                = "WC",
  swing_door1           = "Porta",
  swing_door2           = "Porta",
  shower                = "Chuveiro",
  auto_autopsy          = "Auto-Autópsia",
  bookcase              = "Estante",
  video_game            = "Máquina de Arcade",
  entrance_left         = "Entrada esquerda",
  entrance_right        = "Entrada direita",
  skeleton              = "Esqueleto",
  comfortable_chair     = "Cadeira de conforto",
}


-- Months
months = {
  "Jan",
  "Fev",
  "Mar",
  "Abr",
  "Mai",
  "Jun",
  "Jul",
  "Ago",
  "Set",
  "Out",
  "Nov",
  "Dez",
}

-- Rooms short
-- NB: includes some special "rooms"
-- reception, destroyed room and "corridor objects"
rooms_short = {
  reception         = "Recepçao",
  destroyed         = "Destruído",
  corridor_objects  = "Objectos de Corredor",

  gps_office        = "Consultório Geral",
  psychiatric       = "Psiquiatria",
  ward              = "Enfermaria",
  operating_theatre = "Sala de Operações",
  pharmacy          = "Farmácia",
  cardiogram        = "Cardio",
  scanner           = "Scanner",
  ultrascan         = "Ultrascanner",
  blood_machine     = "Sala de Análises Sanguíneas",
  x_ray             = "Raio-X",
  inflation         = "Inflador",
  dna_fixer         = "Fixador de DNA",
  hair_restoration  = "Recuperador de Cabelo",
  tongue_clinic     = "Fatiador",
  fracture_clinic   = "Clínica de Fracturas",
  training_room     = "Sala de Aprendizagem",
  electrolysis      = "Sala de Electrolisador",
  jelly_vat         = "Moldador Gelatinoso",
  staffroom         = "Sala do Pessoal",
  -- rehabilitation = "Reabilitação", -- unused
  general_diag      = "Diagnóstico Geral",
  research_room     = "Sala de Pesquisa",
  toilets           = "Casas de Banho",
  decontamination   = "Descontaminação",
}


-- Menu Options Game Speed
menu_options_game_speed = {
  slowest             = "  (%1%) MUITO LENTO  ",
  slower              = "  (%1%) LENTO  ",
  normal              = "  (%1%) NORMAL  ",
  max_speed           = "  (%1%) RAPIDO  ",
  and_then_some_more  = "  (%1%) AINDA MAIS RAPIDO  ",
}

-- Menu Display
menu_display = {
  high_res            = "  ALTA RESOLUÇAO  ",
  mcga_lo_res         = "  BAIXA RESOLUCAO  ",
  shadows             = "  SOMBRAS  ",
}

-- Menu Charts
menu_charts = {
  statement           = "  (%1%) INDICACOES  ",
  casebook            = "  (%1%) PONTUARIO DE DOENÇAS  ",
  policy              = "  (%1%) POLITICAS DO HOSPITAL  ",
  research            = "  (%1%) PESQUISA  ",
  graphs              = "  (%1%) GRAFICOS  ",
  staff_listing       = "  (%1%) LISTA DO STAFF  ",
  bank_manager        = "  (%1%) CONTA BANCARIA  ",
  status              = "  (%1%) STATUS  ",
  briefing            = "  BRIEFING  ",
}


menu = {
  file                  = "  FICHEIRO  ",
  options               = "  OPÇOES  ",
  display               = "  DISPLAY",
  charts                = "  TABELAS ",
  debug                 = "  DEBUG  ",
}

-- Menu File
menu_file = {
  load                  = "  (%1%) LER JOGO  ",
  save                  = "  (%1%) SALVAR JOGO  ",
  restart               = "  (%1%) REINICIAR  ",
  quit                  = "  (%1%) SAIR  ",
}


-- Menu Options
menu_options = {
  sound               = "  (%1%) SOM  ",
  announcements       = "  (%1%) ANUNCIOS  ",
  music               = "  (%1%) MUSICA  ",
  sound_vol           = "  VOLUME DOS SONS  ",
  announcements_vol   = "  SOM DOS ANUNCIOS  ",
  music_vol           = "  VOLUME DA MUSICA  ",
  autosave            = "  AUTOSAVE  ",
  game_speed          = "  VELOCIDADE DO JOGO  ",
  jukebox             = "  (%1%) JUKEBOX  ",
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

confirmation = {
  abort_edit_room = "Estás a construir ou a editar uma sala. Se todos os objectos necessários estiverem colocados a sala estará terminada, caso contrário será eliminada. Continuar?",
  return_to_blueprint = "Tens a certeza que desejas voltar ao modo de desenho?",
  restart_level = "Tens a certeza que queres reiniciar o nível?",
  delete_room = "Desejas apagar esta sala?",
  quit = "Queres mesmo sair do jogo?",
  needs_restart = "Estas alterações requerem que reinicies o jogo,O progresso não gravado será perdido. Desejas continuar?",
  overwrite_save = "Já existe uma gravação nesta slot.Desejas gravar por cima?",
  sack_staff = "Queres mesmo despedir este membro do staff?",
  replace_machine = "Queres mesmo repor %s por $%d?",
}


vip_names = {
  [1] = "Presidente da Cruz Vermelha",
  [2] = "Ricardo Araújo Pereira",
  [3] = "D. Duarte Pio de Bragança",
  [4] = "Joe Berardo",
  [5] = "José Mourinho",
  [6] = "Alberto João Jardim",
  [7] = "Marcelo Rebelo de Sousa",
  [8] = "Cavaco Silva",
  [9] = "Cristiano Ronaldo",
  [10] = "Tradutor Filipe Carvalho",
  health_minister = "Ministro da Saúde",
}

-- Rooms
room_classes = {
  -- S[19][2] -- "corridors" - unused for now
  diagnosis  = "Diagnóstico",
  treatment  = "Tratamento",
  clinics    = "Clínicas",
  facilities = "Acomodaçoes",
}

-------------------------------------------------------------------------------
--   Multiplayer (network play): the room, game options, auctions, bots and the rest
--   of the multiplayer windows. Translated from english.lua; the keys
--   missing here show in English.
-------------------------------------------------------------------------------
hotkey_window.ingame_mp_chat = "Chat multijogador"
hotkey_window.ingame_mp_next_hospital = "Hospital seguinte (MJ)"
main_menu.multiplayer = "Multijogador"
map_editor_window.pages.camera_n = "Câmara %d"
map_editor_window.pages.heliport_n = "Heliporto %d"
map_editor_window.pages.player = "Jogador %d"
menu.map_size = "TAMANHO DO MAPA"
menu_map_size.size = "  NOVO MAPA %d x %d  "
menu_player_count.players_5 = "  5 JOGADORES  "
menu_player_count.players_6 = "  6 JOGADORES  "
menu_player_count.players_7 = "  7 JOGADORES  "
menu_player_count.players_8 = "  8 JOGADORES  "
multiplayer_window.add_bot = "à espera de um jogador... (clica: adicionar bot)"
multiplayer_window.ask_amount = "Quantia: $%d"
multiplayer_window.ask_asked = "Pedido enviado. A espera da resposta."
multiplayer_window.ask_balance_line = "Saldo do jogador: $%d."
multiplayer_window.ask_button = "Pedir"
multiplayer_window.ask_caption = "Pedir dinheiro a %s"
multiplayer_window.ask_decline = "Recusar"
multiplayer_window.ask_declined_note = "%s recusou enviar-te $%d."
multiplayer_window.ask_line = "%s pede-te $%d."
multiplayer_window.ask_money = "Pedir a um jogador"
multiplayer_window.ask_no_money_asker_note = "%s näo conseguiu pagar-te."
multiplayer_window.ask_no_money_note = "Näo podes pagar $%d."
multiplayer_window.ask_pay = "Pagar $%d"
multiplayer_window.ask_sent_note = "Pediste $%d a %s. A espera da resposta."
multiplayer_window.auction_back = "Voltar ao leiläo"
multiplayer_window.auction_bid = "Licitar $%d"
multiplayer_window.auction_borrow_tooltip = "Pedir $5,000 emprestados ao banco"
multiplayer_window.auction_close = "Fechar"
multiplayer_window.auction_dropped = "Desististe."
multiplayer_window.auction_going_once = "Dou-lhe uma..."
multiplayer_window.auction_going_twice = "Dou-lhe duas..."
multiplayer_window.auction_leader = "Licitaçäo mais alta: $%d, %s"
multiplayer_window.auction_leading = "Estás na frente. Espera pelos outros."
multiplayer_window.auction_loan = "$%d, empréstimo $%d"
multiplayer_window.auction_loan_tooltip = "O teu saldo e o teu empréstimo bancário"
multiplayer_window.auction_no_money = "Näo podes pagar a próxima licitaçäo."
multiplayer_window.auction_no_money_loan = "Näo podes pagar a próxima licitaçäo: pede um empréstimo com + em baixo."
multiplayer_window.auction_not_sold = "O terreno %d näo foi vendido."
multiplayer_window.auction_out = "fora"
multiplayer_window.auction_pass = "Desistir"
multiplayer_window.auction_paused = "O jogo fica parado durante o leiläo."
multiplayer_window.auction_price = "Preço $%d, cada licitaçäo mais $%d"
multiplayer_window.auction_how = "Lance: o visto. Desistir: o X."
multiplayer_window.auction_repay_tooltip = "Pagar $5,000 do empréstimo"
multiplayer_window.auction_sold = "Terreno %d vendido a %s por $%d."
multiplayer_window.auction_started = "%s quer o terreno %d. Outros jogadores também o podem querer: vai a leiläo."
multiplayer_window.auction_title = "Leiläo de terrenos: terreno %d"
multiplayer_window.auction_wait = "Leiläo a decorrer, aguarda..."
multiplayer_window.auction_watching = "O teu terreno näo faz fronteira com este terreno."
multiplayer_window.auctions_all = "Todos"
multiplayer_window.auctions_caption = "Leilöes de terrenos"
multiplayer_window.auctions_near = "Disputados"
multiplayer_window.auctions_none = "Nenhum"
multiplayer_window.back = "Voltar"
multiplayer_window.back_to_lobby = "Voltar ao lobby"
multiplayer_window.bot_line = "%s   (bot)%s"
multiplayer_window.bot_remove = "   clica: retirar"
multiplayer_window.bot_starting = "um bot está a arrancar..."
multiplayer_window.caption = "Multijogador"
multiplayer_window.cert_changed_help = "O certificado de %s näo é o que este jogo guardou da última vez. Ou o servidor foi configurado de novo, ou alguém está entre ti e o servidor. O jogo näo se ligou. Se sabes que o servidor tem um certificado novo, apaga a linha dele em %s e liga-te outra vez."
multiplayer_window.chat_private_in = "%s (para ti): %s"
multiplayer_window.chat_private_out = "Para %s: %s"
multiplayer_window.chat_team_in = "%s (para a equipa): %s"
multiplayer_window.chat_team_out = "Para a equipa: %s"
multiplayer_window.chat_to = "Para %s:"
multiplayer_window.chat_to_all = "Para todos:"
multiplayer_window.chat_to_team = "Para a equipa:"
multiplayer_window.chat_to_allies = "Para os aliados:"
multiplayer_window.chat_allies_in = "%s (para os aliados): %s"
multiplayer_window.chat_allies_out = "Para os aliados: %s"
multiplayer_window.clear_destroyed_room = "Remover a sala destruída por $%d? O espaço fica livre para outra coisa."
multiplayer_window.colour_names[1] = "Amarelo"
multiplayer_window.colour_names[2] = "Vermelho"
multiplayer_window.colour_names[3] = "Roxo"
multiplayer_window.colour_names[4] = "Branco"
multiplayer_window.colour_names[5] = "Verde"
multiplayer_window.colour_names[6] = "Azul"
multiplayer_window.colour_names[7] = "Turquesa"
multiplayer_window.colour_names[8] = "Preto"
multiplayer_window.connect = "Ligar"
multiplayer_window.connecting = "A ligar a %s..."
multiplayer_window.continue_save = "Continuar: %s"
multiplayer_window.continuing = "gravado %s"
multiplayer_window.create = "Criar"
multiplayer_window.data_mismatch_help = "Os ficheiros do Theme Hospital deste servidor säo de outra ediçäo do jogo que a tua (os níveis e os mapas multijogador säo diferentes), e jogos com as duas näo ficariam iguais. Aponta o CorsixTH para a mesma ediçäo do servidor (Opçöes, Pastas, localizaçäo do Theme Hospital), por exemplo a versäo da GOG, e liga-te de novo."
multiplayer_window.disconnect = "Desligar"
multiplayer_window.download = "Descarregar %s do GitHub"
multiplayer_window.emergency_refused = "Recusar a emergência custou %d de reputaçäo ao hospital."
multiplayer_window.encrypted = "Ligaçäo cifrada (TLS)"
multiplayer_window.every_plot_auctioned = "todos os terrenos em leiläo"
multiplayer_window.game_options = "Opçöes do jogo"
multiplayer_window.goal_limit = "limite:"
multiplayer_window.goal_other.balance = "%s: saldo $%d (%s $%d)"
multiplayer_window.goal_other.num_cured = "%s: %d pacientes curados (%s %d)"
multiplayer_window.goal_other.percentage_cured = "%s: %d%% dos pacientes curados (%s %d%%)"
multiplayer_window.goal_other.percentage_killed = "%s: %d%% dos pacientes morreram (%s %d%%)"
multiplayer_window.goal_other.reputation = "%s: reputaçäo %d (%s %d)"
multiplayer_window.goal_other.value = "%s: valor do hospital $%d (%s $%d)"
multiplayer_window.goal_target = "objectivo:"
multiplayer_window.goals_done = "atingido"
multiplayer_window.goals_failed_other = "%s falhou os objectivos deste nível. Ajuda-o a recuperar até ao fim do próximo ano (dinheiro ou funcionários), ou a equipa toda perde."
multiplayer_window.goals_failed_team = "O teu hospital falhou os objectivos deste nível. Recupera até ao fim do próximo ano, ou a equipa toda perde. Os outros jogadores podem enviar-te dinheiro ou funcionários."
multiplayer_window.goals_failing = "a falhar"
multiplayer_window.goals_open = "-"
multiplayer_window.goals_reached_loan = "O teu hospital cumpre todos os objectivos deste nível, mas ainda deve $%d ao banco. Paga o empréstimo (clica no teu dinheiro em baixo) e passam a contar como atingidos."
multiplayer_window.goals_reached_other = "%s atingiu os objectivos deste nível. Ainda falta: %s."
multiplayer_window.goals_reached_team = "O teu hospital atingiu os objectivos deste nível! Ainda falta: %s."
multiplayer_window.goals_recovered = "%s já näo está a falhar os objectivos deste nível."
multiplayer_window.helpers_off = "Bots aliados constroem: näo"
multiplayer_window.helpers_on = "Bots aliados constroem: sim"
multiplayer_window.hold_left = "O jogo continua dentro de %s, no máximo."
multiplayer_window.hold_win = "À espera que %s responda ao fax..."
multiplayer_window.hold_year = "À espera que %s feche o relatório anual..."
multiplayer_window.is_ready = "pronto"
multiplayer_window.join = "Entrar"
multiplayer_window.keep_playing = "Continuar a jogar"
multiplayer_window.kick_player = "Retirar %s da sala"
multiplayer_window.kicked = "%s, o dono da sala, retirou-te da sala."
multiplayer_window.leave = "Sair da sala"
multiplayer_window.level = "Nível %d"
multiplayer_window.level7_breakthrough = "Avanço médico: %s descobriu %s primeiro e ganha $%d."
multiplayer_window.level7_breakthrough_bonus = "Bónus de avanço"
multiplayer_window.level7_job_fair = "A feira de emprego está aberta: há especialistas na lista de contrataçäo este mês."
multiplayer_window.level7_job_fair_soon = "Uma feira de emprego abre no próximo mês: cirurgiöes, psiquiatras, investigadores e consultores väo estar na lista de contrataçäo. Quem chegar primeiro leva."
multiplayer_window.level7_quarter = "Classificaçäo do Ministério da Saúde: %s curou mais pacientes neste trimestre (%d) e ganha reputaçäo."
multiplayer_window.level7_race_bonus = "Bónus de emergência da corrida"
multiplayer_window.level7_race_emergency = "Emergência da corrida: todos os hospitais recebem agora a mesma emergência. Quem salvar todos os pacientes primeiro ganha $%d e reputaçäo."
multiplayer_window.level7_race_won = "%s salvou primeiro todos os pacientes da emergência da corrida e ganha $%d."
multiplayer_window.level7_rat_bounty = "Prémio por rato"
multiplayer_window.level7_trick_of_month = "Truque do mês: %s custa metade do preço até ao fim do mês."
multiplayer_window.level7_truce_over = "A trégua acabou: a partir de agora podem comprar-se truques sujos (MULTIJOGADOR > TRUQUES SUJOS)."
multiplayer_window.level_intro_6 = "Emergência! Os hospitais desta cidade recebem todas as emergências que o helicóptero consegue trazer. No primeiro ano chegam quatro vezes por mês, a cada um dos teus hospitais à vez: casos de inflaçäo e de psiquiatria a partir de Fevereiro (e alguns para a farmácia), casos de cirurgia a partir de Maio, línguas compridas e ossos partidos a partir de Junho. Em Maio todos os hospitais recebem pacientes com língua comprida, por isso pesquisa cedo o Fatiador. Recusar uma emergência custa reputaçäo, mas perder pacientes por causa delas é mais perdoado do que o normal, e podes encaminhar pacientes de emergência para o hospital de um amigo que os consiga curar. Entram menos pacientes normais enquanto durarem as emergências; a partir do segundo ano entram mais, e as epidemias varrem a cidade de dois em dois ou de três em três meses. Os ratos também gostam disto. Contrata consultores enquanto podes: a partir do nono mês só há júniores à procura de emprego. Para vencer, cada hospital precisa de reputaçäo 550, $60,000 no banco, 150 pacientes curados, uma taxa de cura de 40 por cento e o valor do hospital que aparece no Relatório de Progresso."
multiplayer_window.level_intro_7 = "Sem Piedade. Todos os hospitais desta cidade querem ser os melhores, e nenhum joga limpo. Há uma trégua até Março; depois os truques sujos väo abrindo mês a mês: ataques de ratos, campanhas de difamaçäo e caldeiras avariadas primeiro; contínuos malvados, epidemias e espionagem a partir de Junho; emergências forçadas e caça-talentos a partir de Setembro; e o nível mais forte de cada truque a partir do segundo ano. Todos os meses um truque sai a metade do preço, o hospital mais atrasado paga metade por todos eles, e o líder paga outra vez metade. Vale a pena lutar: as feiras de emprego de Abril, Outubro, do próximo Abril e do próximo Outubro trazem cirurgiöes, psiquiatras, investigadores e consultores para a lista de contrataçäo, e quem chegar primeiro leva. Em Agosto, Fevereiro e no Agosto seguinte, todos os hospitais recebem a mesma emergência de uma só vez, e o primeiro a salvar todos os pacientes ganha $10,000 e reputaçäo. O primeiro a descobrir o Raio-X, o scanner ou a máquina do sangue também ganha $10,000 (planos roubados näo contam), e todos os trimestres o hospital que curou mais pacientes ganha reputaçäo. Os ratos enviados por um rival pagam $100 cada um quando abatidos. As máquinas desgastam-se mais depressa aqui, e quatro sismos väo abanar a cidade, cada um mais forte que o anterior. Para vencer, um hospital precisa de reputaçäo 650, $150,000 no banco, 300 pacientes curados, uma taxa de cura de 55 por cento e o valor do hospital que aparece no Relatório de Progresso. Com quatro jogadores a cidade é o mapa do Matroftt."
multiplayer_window.level_intro_8 = "A Cidade das Equipas, o mapa do Matroftt, foi feita para dois contra dois: os quatro hospitais ficam em pares no meio da cidade, com os colegas de equipa lado a lado e muito terreno à venda em todos os lados. Pöe os amigos na mesma equipa e corre contra a outra dupla. Para vencer, cada hospital precisa de reputaçäo 650, $100,000 no banco, 200 pacientes curados, uma taxa de cura de 50 por cento e o valor do hospital que aparece no Relatório de Progresso. Com dois ou três jogadores, joga-se no mapa de outra cidade."
multiplayer_window.level_intro_9 = "Encruzilhada, o mapa do Matroftt, tem lugar para oito: a cidade está dividida em três filas de três, com oito hospitais já murados à volta de quatro pequenos terrenos à venda no meio, onde os caminhos se cruzam. Os quatro hospitais dos cantos são um pouco maiores. Com quatro jogadores ou menos, só os cantos são ocupados e os outros hospitais também ficam à venda. Os pacientes chegam por todos os lados da cidade. Para ganhar, cada hospital precisa de uma reputação de 650, $150.000 no banco, 300 pacientes curados, uma taxa de cura de 55 por cento e o valor do hospital mostrado no Relatório de Progresso."
multiplayer_window.level_rats_notice = "Ratos! Um bando entrou no hospital. Clica neles para os abater antes que se reproduzam no lixo."
multiplayer_window.level_slack_tongue_warning = "Chegam relatos de línguas compridas por toda a cidade. Em Maio todos os hospitais väo receber emergências de língua comprida: pesquisa o Fatiador antes disso."
multiplayer_window.level_won_end = "Venceste o nível. Muito bem!"
multiplayer_window.levels_caption = "Níveis"
multiplayer_window.levels_choose = "Escolher o nível %d"
multiplayer_window.levels_events = "EVENTOS: %s"
multiplayer_window.levels_from_campaign = "Salas, doenças e pesquisa como em %s (nível %d da campanha)."
multiplayer_window.levels_goal_balance = "$%s no banco"
multiplayer_window.levels_goal_cure_rate = "Taxa de cura %d%%"
multiplayer_window.levels_goal_cured = "%d curados"
multiplayer_window.levels_goal_reputation = "Reputaçäo %d"
multiplayer_window.levels_goal_value = "Valor +$%s"
multiplayer_window.levels_goals = "Para vencer:"
multiplayer_window.levels_legend = "A cores: terrenos iniciais. Cinzento: à venda."
multiplayer_window.levels_map_by = "Mapa de %s"
multiplayer_window.levels_map_players = "Mapa para %d jogadores"
multiplayer_window.levels_money = "Dinheiro: $%s"
multiplayer_window.levels_no_map = "Este mapa näo está nos teus dados do Theme Hospital."
multiplayer_window.levels_several = "Vários hospitais"
multiplayer_window.levels_shared = "Um hospital partilhado"
multiplayer_window.levels_shared_note = "Nível %d da campanha: um hospital que todos constroem juntos, com os objectivos da campanha."
multiplayer_window.load_caption = "Carregar um jogo multijogador"
multiplayer_window.load_game = "Carregar jogo MP"
multiplayer_window.loading = "A CARREGAR..."
multiplayer_window.locked = "  (palavra-passe)"
multiplayer_window.looking_at = "A ver %s"
multiplayer_window.measuring = "A medir a ligaçäo..."
multiplayer_window.menu_caption = "  MULTIJOGADOR  "
multiplayer_window.menu_chat = "  ENVIAR MENSAGEM (%1%)  "
multiplayer_window.menu_colours = "  CORES DOS JOGADORES  "
multiplayer_window.menu_colours_all = "  PESSOAL DE TODOS  "
multiplayer_window.menu_colours_off = "  DESLIGADO  "
multiplayer_window.menu_bot_chat = "  CONVERSA DOS BOTS  "
multiplayer_window.menu_bot_chat_all = "  TUDO  "
multiplayer_window.menu_bot_chat_auto = "  SEM CONVERSA FIADA A PARTIR DE 3 BOTS  "
multiplayer_window.menu_bot_chat_useful = "  SEM CONVERSA FIADA  "
multiplayer_window.menu_bot_chat_off = "  DESLIGADO  "
multiplayer_window.menu_colours_others = "  PESSOAL DOS OUTROS JOGADORES  "
multiplayer_window.menu_players = "  JOGADORES  "
multiplayer_window.menu_research = "  PARTILHAR PESQUISA  "
multiplayer_window.menu_sabotage = "  TRUQUES SUJOS  "
multiplayer_window.menu_trade = "  NEGOCIAR COM OUTROS JOGADORES  "
multiplayer_window.mode_competitive = "Corrida: cada um por si"
multiplayer_window.mode_coop = "Cooperativo: todos ganham juntos"
multiplayer_window.mode_mixed = "Corrida de equipas"
multiplayer_window.mode_shared = "Um hospital partilhado"
multiplayer_window.mode_teams = "Corrida de duas equipas"
multiplayer_window.mode_teamshared = "Corrida de hospitais de equipa"
multiplayer_window.money_received = "Dinheiro de %s"
multiplayer_window.money_received_note = "%s enviou-te $%d."
multiplayer_window.money_sent = "Dinheiro enviado a %s"
multiplayer_window.mp_level = "%s (com vários hospitais: nível %d)"
multiplayer_window.name = "O teu nome"
multiplayer_window.new_room = "Nova sala"
multiplayer_window.no_auctions = "sem leilöes"
multiplayer_window.no_helper_building = "bots näo constroem"
multiplayer_window.no_rooms = "Ainda näo há salas. Cria uma em baixo."
multiplayer_window.no_sharing = "sem partilha"
multiplayer_window.no_socket = "Esta versäo näo tem suporte de rede (falta o LuaSocket)."
multiplayer_window.no_tricks = "sem truques"
multiplayer_window.not_encrypted = "Sem cifra"
multiplayer_window.not_encrypted_build = "Sem cifra: este jogo näo tem o LuaSec"
multiplayer_window.not_encrypted_server = "Sem cifra: este servidor näo tem certificado"
multiplayer_window.not_ready = "näo pronto"
multiplayer_window.offer_ability = "Aptidäo: %d%%"
multiplayer_window.offer_accept = "Aceitar"
multiplayer_window.offer_accept_pay = "Pagar $%d"
multiplayer_window.offer_accept_price = "Aceitar e pagar $%d"
multiplayer_window.offer_accepted_note = "%s aceitou: %s."
multiplayer_window.offer_accepted_price_note = "%s aceitou: %s, por $%d."
multiplayer_window.offer_caption = "Oferta de %s"
multiplayer_window.offer_decline = "Recusar"
multiplayer_window.offer_declined_note = "%s recusou: %s."
multiplayer_window.offer_free_banner = "GRATIS: este funcionário näo custa nada"
multiplayer_window.offer_gone_note = "%s já näo está disponível."
multiplayer_window.offer_happy = "Felicidade: %d%%"
multiplayer_window.offer_health = "Saúde: %d%%"
multiplayer_window.offer_illness = "Doença: %s"
multiplayer_window.offer_job = "Funçäo: %s"
multiplayer_window.offer_later = "Depois"
multiplayer_window.offer_no_money_note = "Näo podes pagar os $%d pedidos por %s."
multiplayer_window.offer_no_money_sender_note = "%s näo conseguiu pagar o preço de %s."
multiplayer_window.offer_no_skills = "Capacidades especiais: nenhuma"
multiplayer_window.offer_not_diagnosed = "Ainda sem diagnóstico (%d%% feito)"
multiplayer_window.offer_patient_known = "um paciente com %s"
multiplayer_window.offer_patient_line = "%s encaminha-te um paciente:"
multiplayer_window.offer_patient_unknown = "um paciente sem diagnóstico"
multiplayer_window.offer_price_banner = "PREÇO: $%d, pago só se aceitares"
multiplayer_window.offer_price_line = "PREÇO: $%d. É o que pedem por este funcionário."
multiplayer_window.offer_raise = "Pede um aumento de salário"
multiplayer_window.offer_sent_note = "%s foi oferecido a %s. A espera da resposta."
multiplayer_window.offer_sent_price_note = "%s foi oferecido a %s por $%d. A espera da resposta."
multiplayer_window.offer_show = "Mostrar"
multiplayer_window.offer_skills = "Capacidades especiais: %s"
multiplayer_window.offer_staff_line = "%s oferece-te um funcionário:"
multiplayer_window.offer_tired = "Cansaço: %d%%"
multiplayer_window.offer_wage = "Salário: $%d por mês"
multiplayer_window.options_close = "Fechar"
multiplayer_window.options_host_only = "Só o anfitriäo muda isto."
multiplayer_window.options_off_line = "Opçöes: %s"
multiplayer_window.other_build = "  (outra versäo do jogo)"
multiplayer_window.owner_mark = " (anfitriäo)"
multiplayer_window.password = "Palavra-passe"
multiplayer_window.password_clear = "Sem cifra: a palavra-passe vai em texto simples. Clica outra vez para enviar."
multiplayer_window.patient_arrived_note = "Chegou um paciente encaminhado por %s."
multiplayer_window.patient_on_the_way = "Encaminhado para %s"
multiplayer_window.places[1] = "1o"
multiplayer_window.places[2] = "2o"
multiplayer_window.places[3] = "3o"
multiplayer_window.places[4] = "4o"
multiplayer_window.places[5] = "5o"
multiplayer_window.places[6] = "6o"
multiplayer_window.places[7] = "7o"
multiplayer_window.places[8] = "8o"
multiplayer_window.player_away_note = "%s saiu: o hospital dele näo conta para os objectivos da equipa até voltar (mesma sala, mesmo nome)."
multiplayer_window.player_back_note = "%s voltou: o hospital dele conta outra vez para os objectivos da equipa."
multiplayer_window.player_line = "%s%s   %s ms   %s"
multiplayer_window.players = "%d jogadores"
multiplayer_window.players_balance = "Saldo"
multiplayer_window.players_behind = "%d horas atrasado"
multiplayer_window.players_caption = "Jogadores"
multiplayer_window.players_goals = "Objectivos"
multiplayer_window.players_hospital = "Hospital"
multiplayer_window.players_left = "saiu do jogo"
multiplayer_window.players_ms = "%d ms"
multiplayer_window.players_name = "Jogador"
multiplayer_window.players_note = "Ping: média dos últimos 10 segundos. Valor: o valor do hospital (um objectivo do nível)."
multiplayer_window.players_ping = "Ping"
multiplayer_window.players_playing = "a jogar"
multiplayer_window.players_quiet = "sem resposta há %d s"
multiplayer_window.players_reputation = "Reputaçäo"
multiplayer_window.players_status = "Estado"
multiplayer_window.players_team = "%s (equipa %d)"
multiplayer_window.players_value = "Valor"
multiplayer_window.players_waiting = "A espera da lista do servidor..."
multiplayer_window.players_you = "tu"
multiplayer_window.plot_bought_transaction = "Terreno de %s (terreno %d)"
multiplayer_window.plot_give_button = "Oferecer o terreno"
multiplayer_window.plot_give_cancel = "Cancelar"
multiplayer_window.plot_give_caption = "Passar o terreno %d"
multiplayer_window.plot_give_free = "Preço: de graça"
multiplayer_window.plot_give_hint = "Passar este terreno a um aliado, de graça ou por um preço"
multiplayer_window.plot_give_none = "Näo há ninguém a quem passar um terreno."
multiplayer_window.plot_give_offered = "Oferecido. O terreno muda de dono se o outro jogador aceitar."
multiplayer_window.plot_give_price = "Preço: $%d"
multiplayer_window.plot_give_to = "A que aliado:"
multiplayer_window.plot_given_transaction = "Terreno para %s (terreno %d)"
multiplayer_window.plot_offer_accepted_note = "%s aceitou o terreno %d."
multiplayer_window.plot_offer_accepted_price_note = "%s aceitou o terreno %d por $%d."
multiplayer_window.plot_offer_declined_note = "%s recusou o terreno %d."
multiplayer_window.plot_offer_free_line = "DE GRAÇA: sem custo por este terreno."
multiplayer_window.plot_offer_gone_note = "A oferta do terreno %d perdeu a validade: as coisas mudaram."
multiplayer_window.plot_offer_line = "%s oferece-te o terreno %d (%d quadrados de terra)."
multiplayer_window.plot_offer_no_money_note = "Näo podes pagar os $%d pedidos pelo terreno %d."
multiplayer_window.plot_offer_no_money_sender_note = "%s näo conseguiu pagar o terreno %d."
multiplayer_window.plot_offer_price_line = "PREÇO: $%d, pago só se aceitares."
multiplayer_window.plot_offer_sent_note = "O terreno %d foi oferecido a %s como presente. A espera da resposta."
multiplayer_window.plot_offer_sent_price_note = "O terreno %d foi oferecido a %s por $%d. A espera da resposta."
multiplayer_window.plot_received_note = "O terreno %d é agora teu, vindo de %s."
multiplayer_window.plot_sell_hint = "Vender este terreno de volta ao banco (tem de estar vazio)"
multiplayer_window.plot_sell_question = "Queres vender este terreno? Recebes $%d de volta."
multiplayer_window.plot_sold_note = "O terreno %d foi vendido de volta ao banco por $%d."
multiplayer_window.plot_sold_others_note = "%s vendeu o terreno %d de volta. Está outra vez à venda."
multiplayer_window.plot_sold_transaction = "Terreno %d vendido de volta"
multiplayer_window.race_and = " e "
multiplayer_window.race_failing = "O teu hospital falhou os objectivos deste nível. Recupera até ao fim do próximo ano, ou ficas fora da corrida."
multiplayer_window.race_failing_other = "%s falhou os objectivos deste nível; fica fora se voltar a falhar no próximo ano."
multiplayer_window.race_left_end = "Saíste da corrida. Os outros continuam a disputar os lugares seguintes."
multiplayer_window.race_out[1] = "Más notícias."
multiplayer_window.race_out[2] = "O teu hospital falhou os objectivos deste nível dois anos seguidos: está fora da corrida, em %s lugar."
multiplayer_window.race_out[3] = "Voltar ao lobby ou ver os outros?"
multiplayer_window.race_out_other = "%s falhou os objectivos dois anos seguidos e está fora da corrida (%s lugar)."
multiplayer_window.race_out_short = "fora"
multiplayer_window.race_over[1] = "A corrida acabou. Classificaçäo final:"
multiplayer_window.race_over[2] = "Voltar ao lobby ou continuar a jogar?"
multiplayer_window.race_over_won = "Parabéns, a tua equipa venceu a corrida! Classificaçäo final:"
multiplayer_window.race_placed_other = "%s atingiu os objectivos deste nível: %s lugar. A corrida continua."
multiplayer_window.race_standing = "%s %s"
multiplayer_window.race_standing_out = " (fora)"
multiplayer_window.race_watch = "Ver"
multiplayer_window.race_won[1] = "Parabéns!"
multiplayer_window.race_won[2] = "O teu hospital atingiu os objectivos deste nível: %s lugar."
multiplayer_window.race_won[3] = "Os outros disputam os lugares seguintes. Voltar ao lobby ou ver?"
multiplayer_window.race_won_question = "Os outros disputam os lugares seguintes. Queres voltar ao lobby?"
multiplayer_window.race_won_allies = "Tu e %s conseguiram! Muito bem!"
multiplayer_window.race_won_allies_first = "Tu e %s conseguiram! Excelente trabalho!"
multiplayer_window.race_won_first = "O teu hospital foi o primeiro a atingir todos os objectivos de %s. Ganhaste a corrida!"
multiplayer_window.race_won_place = "O teu hospital atingiu todos os objectivos de %s: %s lugar."
multiplayer_window.race_won_team_first = "A tua equipa foi a primeira a atingir todos os objectivos de %s. Ganhaste a corrida!"
multiplayer_window.race_won_team_place = "A tua equipa atingiu todos os objectivos de %s: %s lugar."
multiplayer_window.race_won_together = "Conseguiram juntos! Muito bem!"
multiplayer_window.race_won_together_first = "Conseguiram juntos! Excelente trabalho!"
multiplayer_window.race_won_well_done = "Muito bem!"
multiplayer_window.rat_attacks = "ataques de ratos"
multiplayer_window.rats_off = "Ataque de ratos (corridas): näo permitido"
multiplayer_window.rats_on = "Ataque de ratos (corridas): permitido"
multiplayer_window.ready = "Pronto"
multiplayer_window.rebuild_destroyed_room = "Esta sala foi destruída. Removê-la por $%d e construí-la de novo?"
multiplayer_window.recommendation = "Até %s; as acçöes demoram %s ms"
multiplayer_window.refer_button = "Encaminhar paciente"
multiplayer_window.refer_choose = "Encaminhar para que hospital?"
multiplayer_window.refer_fax_choice = "Encaminhar para outro hospital"
multiplayer_window.referral_cured_here_note = "Curaste um paciente encaminhado por %s: +%d de reputaçäo extra."
multiplayer_window.referral_cured_note = "%s curou o paciente que encaminhaste: +%d de reputaçäo."
multiplayer_window.refresh = "Actualizar"
multiplayer_window.rep_amount = "Pontos: %d"
multiplayer_window.rep_give_button = "Dar %d dos teus pontos de reputaçäo"
multiplayer_window.rep_given_note = "Deste aval a %s: deste %d pontos de reputaçäo."
multiplayer_window.rep_received_note = "%s dá aval ao teu hospital: ganhaste %d pontos de reputaçäo."
multiplayer_window.rep_rivals = "Só os aliados podem dar aval uns aos outros."
multiplayer_window.rep_sent = "Feito. Os pontos passam daqui a pouco."
multiplayer_window.rep_vouch_caption = "Aval: dá parte da tua reputaçäo"
multiplayer_window.repair_destroyed_room = "Esta sala foi destruída. Repará-la por $%d, o preço de uma nova com os móveis? (Näo: removê-la.)"
multiplayer_window.research_accept = "ACEITO este conhecimento de pesquisa"
multiplayer_window.research_accept_price = "ACEITO este conhecimento de pesquisa por $%d"
multiplayer_window.research_accepted_note = "%s aceitou a tua pesquisa (pagou $%d)."
multiplayer_window.research_all = "Tudo"
multiplayer_window.research_and_more = "e mais %d"
multiplayer_window.research_bought_transaction = "Pesquisa de %s"
multiplayer_window.research_caption = "Partilhar pesquisa com %s"
multiplayer_window.research_decline = "REJEITO este conhecimento de pesquisa"
multiplayer_window.research_declined_note = "%s recusou a tua pesquisa."
multiplayer_window.research_free = "Preço: grátis"
multiplayer_window.research_free_line = "GRATIS: esta transferência näo custa nada."
multiplayer_window.research_item_drug = "Medicamento: %s"
multiplayer_window.research_item_machine = "Melhoria: %s"
multiplayer_window.research_known_note = "Já conheces toda essa pesquisa."
multiplayer_window.research_known_sender_note = "%s já conhecia toda essa pesquisa."
multiplayer_window.research_next = "Mais"
multiplayer_window.research_no_money_note = "Näo podes pagar essa pesquisa ($%d)."
multiplayer_window.research_no_money_sender_note = "%s näo conseguiu pagar a tua pesquisa."
multiplayer_window.research_none = "Näo tens pesquisa que ele näo tenha."
multiplayer_window.research_none_selected = "Selecciona primeiro alguma pesquisa."
multiplayer_window.research_offer = "Oferecer"
multiplayer_window.research_offer_line = "%s quer partilhar contigo a seguinte pesquisa:"
multiplayer_window.research_offered = "Oferecido. A espera da resposta."
multiplayer_window.research_page = "Página %d de %d"
multiplayer_window.research_previous = "Voltar"
multiplayer_window.research_price = "Preço: $%d"
multiplayer_window.research_price_line = "PREÇO: $%d. Só pagas se aceitares."
multiplayer_window.research_received_note = "Nova pesquisa: %s."
multiplayer_window.research_sent_note = "Pesquisa oferecida a %s. A espera da resposta."
multiplayer_window.research_sold_transaction = "Pesquisa vendida a %s"
multiplayer_window.room_caption = "Sala: %s"
multiplayer_window.room_hint = "Mesma cor: um só hospital. Mesma equipa: ganham juntos."
multiplayer_window.room_line = "%s   %d de %d   %s   nível %s%s"
multiplayer_window.rooms_caption = "Salas em %s"
multiplayer_window.sabotage_again = "Clica em L%d outra vez para comprar por $%d."
multiplayer_window.sabotage_alone = "Já näo há nenhum rival para pregar partidas."
multiplayer_window.sabotage_arrived = "O teu contínuo malvado começou a trabalhar em %s."
multiplayer_window.sabotage_boiler = "Caldeira avariada"
multiplayer_window.sabotage_boiler_notice = "A caldeira avariou, e näo foi acidente. Os teus contínuos estäo a repará-la: quantos mais, mais depressa."
multiplayer_window.sabotage_caption = "Truques sujos contra %s"
multiplayer_window.sabotage_caught = "Expulsaste um contínuo que näo era teu: foi %s que o enviou. Ele volta para eles."
multiplayer_window.sabotage_caught_owner = "%s apanhou o teu contínuo malvado. Ele volta a trabalhar para ti."
multiplayer_window.sabotage_close = "Fechar"
multiplayer_window.sabotage_done.boiler = "A caldeira de %s avariou."
multiplayer_window.sabotage_done.emergency = "Uma emergência está a caminho de %s."
multiplayer_window.sabotage_done.epidemic = "Os pacientes contagiosos estäo a caminho de %s."
multiplayer_window.sabotage_done.espionage = "O teu espiäo esteve em %s."
multiplayer_window.sabotage_done.handyman = "O teu contínuo malvado está a caminho de %s."
multiplayer_window.sabotage_done.headhunter = "O teu caça-talentos fez uma proposta a um funcionário de %s."
multiplayer_window.sabotage_done.rats = "Os ratos estäo a mudar-se para %s."
multiplayer_window.sabotage_done.smear = "A campanha de difamaçäo contra %s começou."
multiplayer_window.sabotage_emergency = "Emergência"
multiplayer_window.sabotage_emergency_fax[1] = "Foi-te enviada uma emergência, e näo a podes recusar."
multiplayer_window.sabotage_emergency_fax[2] = "%d pacientes com %s chegam de helicóptero."
multiplayer_window.sabotage_emergency_fax[3] = "Trata o máximo que conseguires antes de o tempo acabar."
multiplayer_window.sabotage_epidemic = "Epidemia"
multiplayer_window.sabotage_espionage = "Espionagem"
multiplayer_window.sabotage_espionage_got = "O teu espiäo trouxe: %s."
multiplayer_window.sabotage_espionage_notice = "Alguém copiou ficheiros do departamento de pesquisa."
multiplayer_window.sabotage_espionage_notice_3 = "Alguém assaltou o departamento de pesquisa: ficheiros copiados e a pesquisa actual atrasada para metade."
multiplayer_window.sabotage_handyman = "Contínuo malvado"
multiplayer_window.sabotage_handyman_hint = {"O teu equipamento tem avariado muito ultimamente. Será que há um contínuo malvado no teu hospital?", "As coisas continuam a correr mal por aqui. Todos os teus contínuos säo mesmo teus? Despede um que näo seja.", "Um contínuo de que ninguém se lembra de ter contratado anda pelos teus corredores. Olha para os teus contínuos: um estranho pode ser expulso."}
multiplayer_window.sabotage_headhunter = "Caça-talentos"
multiplayer_window.sabotage_headhunter_left = "%s saiu por uma proposta melhor."
multiplayer_window.sabotage_headhunter_notice = "%s recebeu uma proposta melhor de outro hospital e pede um aumento de $%d. Aceita em 10 dias, ou a pessoa sai."
multiplayer_window.sabotage_headhunter_won = "%s saiu do hospital e está na lista de contrataçäo: contrata em %d dias, antes que outros possam."
multiplayer_window.sabotage_level = "L%d  $%d"
multiplayer_window.sabotage_level_locked = "L%d  mês %d"
multiplayer_window.sabotage_level_off = "L%d  desl."
multiplayer_window.sabotage_levels.boiler[1] = "A caldeira deles avaria: frio demais no inverno, calor demais no veräo, até os contínuos a repararem (reparaçäo curta)."
multiplayer_window.sabotage_levels.boiler[2] = "A caldeira deles avaria, por cerca do dobro do tempo. Mais contínuos reparam-na mais depressa."
multiplayer_window.sabotage_levels.boiler[3] = "A caldeira deles avaria a sério: reparaçäo longa. Mais contínuos reparam-na mais depressa."
multiplayer_window.sabotage_levels.emergency[1] = "Uma emergência que näo podem recusar: 3 pacientes de helicóptero, com uma doença que eles conhecem."
multiplayer_window.sabotage_levels.emergency[2] = "Uma emergência que näo podem recusar: 6 pacientes de helicóptero, com uma doença que eles conhecem."
multiplayer_window.sabotage_levels.emergency[3] = "Uma emergência que näo podem recusar: 10 pacientes de helicóptero, talvez com uma doença que ainda näo descobriram."
multiplayer_window.sabotage_levels.epidemic[1] = "2 pacientes contagiosos da mesma doença chegam ao hospital deles."
multiplayer_window.sabotage_levels.epidemic[2] = "4 pacientes contagiosos da mesma doença chegam ao hospital deles."
multiplayer_window.sabotage_levels.epidemic[3] = "7 pacientes contagiosos da mesma doença chegam ao hospital deles."
multiplayer_window.sabotage_levels.espionage[1] = "Copia uma melhoria de medicamento ou máquina que eles têm e tu näo: escolhes qual."
multiplayer_window.sabotage_levels.espionage[2] = "Copia uma descoberta (máquina ou sala) que eles têm e tu näo: escolhes qual."
multiplayer_window.sabotage_levels.espionage[3] = "Copia duas melhorias ou descobertas deles (escolhes) e atrasa a pesquisa actual deles para metade."
multiplayer_window.sabotage_levels.handyman[1] = "Um contínuo parecido com os deles, mas que näo trabalha, durante 4 meses. Se o encontrarem e o despedirem, ele vai trabalhar para ti."
multiplayer_window.sabotage_levels.handyman[2] = "Como o L1, e ele deita lixo para os corredores deles duas vezes por dia, durante 3 meses."
multiplayer_window.sabotage_levels.handyman[3] = "Como o L2, e de 3 em 3 dias finge reparar uma máquina, deixando-a quase avariada. Fica 2 meses."
multiplayer_window.sabotage_levels.headhunter[1] = "O melhor júnior ou enfermeira deles recebe uma proposta melhor: eles pagam um aumento de 50% em 10 dias, ou perdem a pessoa para a lista de contrataçäo (guardada para ti durante 2 semanas)."
multiplayer_window.sabotage_levels.headhunter[2] = "O melhor médico deles recebe uma proposta melhor: eles pagam um aumento de 75% em 10 dias, ou perdem a pessoa para a lista de contrataçäo (guardada para ti durante 2 semanas)."
multiplayer_window.sabotage_levels.headhunter[3] = "O melhor consultor ou especialista deles recebe uma proposta melhor: eles duplicam o salário em 10 dias, ou perdem a pessoa para a lista de contrataçäo (guardada para ti durante 2 semanas)."
multiplayer_window.sabotage_levels.rats[1] = "Mudam-se 5 ratos. Enquanto andam por aí, custam-lhes até 1 de reputaçäo por dia (até 30 dias), até serem abatidos."
multiplayer_window.sabotage_levels.rats[2] = "Mudam-se 10 ratos. Enquanto andam por aí, custam-lhes até 2 de reputaçäo por dia (até 30 dias), até serem abatidos."
multiplayer_window.sabotage_levels.rats[3] = "Mudam-se 20 ratos. Enquanto andam por aí, custam-lhes até 3 de reputaçäo por dia (até 30 dias), até serem abatidos."
multiplayer_window.sabotage_levels.smear[1] = "Má imprensa durante um mês: 3 em cada 10 novos pacientes deles väo para os outros hospitais."
multiplayer_window.sabotage_levels.smear[2] = "Má imprensa durante 2 meses: 4 em cada 10 novos pacientes deles väo para os outros hospitais."
multiplayer_window.sabotage_levels.smear[3] = "Má imprensa durante 3 meses: metade dos novos pacientes deles vai para os outros hospitais."
multiplayer_window.sabotage_locked_tooltip = "Neste nível, só se pode comprar a partir do mês %d do jogo."
multiplayer_window.sabotage_next = "Próximo rival"
multiplayer_window.sabotage_off_tooltip = "O anfitriäo näo permitiu este truque neste jogo (opçöes do jogo)."
multiplayer_window.sabotage_pick = "Clica num nível para ver o que faz. Clica outra vez para o comprar."
multiplayer_window.sabotage_rats = "Ataque de ratos"
multiplayer_window.sabotage_rats_notice = "Ratos! Um bando mudou-se para o hospital. Enquanto andam por aí, custam reputaçäo todos os dias: clica neles para os abater."
multiplayer_window.sabotage_rats_reminder = "Ainda andam %d ratos pelo hospital, a custar reputaçäo todos os dias."
multiplayer_window.sabotage_rats_reminders = {"Ainda andam %d ratos pelo hospital, a custar reputaçäo todos os dias. Clica neles para lhes atirar.", "Os ratos ainda cá estäo, %d deles, e os pacientes comentam. Atira-lhes!", "O teu hospital ainda tem %d ratos. Cada dia que ficam custa-te reputaçäo."}
multiplayer_window.sabotage_refused = "Esse truque sujo näo pode ser feito: %s."
multiplayer_window.sabotage_sent = "Encomendado. Pagas quando for feito."
multiplayer_window.sabotage_smear = "Campanha de difamaçäo"
multiplayer_window.sabotage_smear_notice = "Má imprensa: uma campanha de difamaçäo contra o hospital afasta alguns pacientes durante %d mês(es)."
multiplayer_window.sabotage_smear_over = "A campanha de difamaçäo acabou: os pacientes voltam ao hospital como antes."
multiplayer_window.sabotage_spy_caption = "Espiar %s: escolhe %d"
multiplayer_window.sabotage_spy_pick = "Escolhe o que o teu espiäo deve copiar e carrega em Roubar."
multiplayer_window.sabotage_spy_steal = "Roubar ($%d)"
multiplayer_window.sabotage_transaction = "Truques sujos"
multiplayer_window.sabotage_went_home = "O tempo do teu contínuo malvado em %s acabou. Ele foi para casa."
multiplayer_window.saved_flag = "  jogo gravado"
multiplayer_window.saved_note = "Jogo gravado: %s"
multiplayer_window.saving_note = "A gravar o jogo no computador de cada jogador..."
multiplayer_window.select_room = "Selecciona primeiro uma sala."
multiplayer_window.server = "Servidor"
multiplayer_window.server_eu1 = "EU1: estável"
multiplayer_window.server_eu2 = "EU2: versöes de teste"
multiplayer_window.server_version = "a versäo do servidor"
multiplayer_window.share_research = "Partilhar pesquisa"
multiplayer_window.shared_won = "Passar ao nível seguinte näo está disponível no multijogador."
multiplayer_window.sharing_off = "Partilha de pesquisa: desligada"
multiplayer_window.sharing_on = "Partilha de pesquisa: ligada"
multiplayer_window.staff_arrived_note = "%s chegou e começa a trabalhar."
multiplayer_window.staff_bought_transaction = "Funcionário de %s"
multiplayer_window.staff_on_the_way = "A caminho de %s"
multiplayer_window.staff_received_note = "%s enviou-te um funcionário: %s"
multiplayer_window.staff_sold_transaction = "Funcionário para %s"
multiplayer_window.start = "Iniciar jogo"
multiplayer_window.team_button = "Equipa %d"
multiplayer_window.team_lost = "%s ainda falhava os objectivos deste nível no fim do ano, por isso a equipa perdeu o nível."
multiplayer_window.team_member_out = "O teu hospital falhou os objectivos deste nível dois anos seguidos e está fora da corrida. A tua equipa continua."
multiplayer_window.team_member_out_other = "%s falhou os objectivos dois anos seguidos e está fora da corrida; a equipa dele continua."
multiplayer_window.team_race_mate_reached_fax[1] = "O teu colega de equipa %s atingiu os objectivos deste nível!"
multiplayer_window.team_race_mate_reached_fax[2] = "A tua equipa vence quando o teu hospital também lá chegar. Falta: %s."
multiplayer_window.team_race_mate_reached_fax[3] = "O teu colega de equipa pode ajudar com dinheiro, funcionários ou pacientes."
multiplayer_window.team_race_reached_fax[1] = "O teu hospital atingiu os objectivos deste nível!"
multiplayer_window.team_race_reached_fax[2] = "A corrida ainda näo está ganha: a tua equipa vence quando todos os hospitais dela lá chegarem. Falta: %s."
multiplayer_window.team_race_reached_fax[3] = "Mantém o teu hospital a funcionar e ajuda os outros com dinheiro, funcionários ou pacientes."
multiplayer_window.team_race_reached_other = "%s atingiu os objectivos deste nível (equipa %s)."
multiplayer_window.team_won[1] = "Parabéns!"
multiplayer_window.team_won[2] = "Todos os hospitais atingiram os objectivos deste nível: a equipa venceu o nível."
multiplayer_window.team_won[3] = "Voltar ao lobby ou continuar a jogar?"
multiplayer_window.too_many_hospitals = "Este nível comporta %d hospitais: partilhem cores"
multiplayer_window.trade_alone = "Näo há ninguém com quem negociar."
multiplayer_window.trade_caption = "Negociar com %s"
multiplayer_window.trade_close = "Fechar"
multiplayer_window.trade_free = "Preço: grátis"
multiplayer_window.trade_money_allies_only = "O dinheiro só pode ir para aliados."
multiplayer_window.running_flag = "em jogo"
multiplayer_window.running_places = "em jogo, %d livres"
multiplayer_window.seats_caption = "Lugares em %s"
multiplayer_window.seats_hint = "Fica com o lugar de um bot ou de um jogador que saiu:"
multiplayer_window.seat_on = "%s, a jogar"
multiplayer_window.seat_bot = "%s (bot)"
multiplayer_window.seat_standin = "%s (saiu, um bot joga por agora)"
multiplayer_window.seat_left = "%s (saiu)"
multiplayer_window.players_standin = "ausente, um bot joga"
multiplayer_window.players_bot = "bot"
multiplayer_window.trade_next_player = "Próximo jogador"
multiplayer_window.trade_no_staff = "Näo tens funcionários para enviar."
multiplayer_window.trade_offered = "Oferecido. Se o outro jogador aceitar, o funcionário junta-se a ele."
multiplayer_window.trade_on_the_way = "- oferecido"
multiplayer_window.trade_price = "Preço: $%d"
multiplayer_window.trade_select_staff = "Clica primeiro num funcionário."
multiplayer_window.trade_send_money = "Enviar $%d"
multiplayer_window.trade_send_staff = "Oferecer o funcionário"
multiplayer_window.trade_sent = "Enviado. Chega daqui a pouco."
multiplayer_window.tricks_off = "Truques sujos (corridas): desligados"
multiplayer_window.tricks_on = "Truques sujos (corridas): ligados"
multiplayer_window.vaccination_mode_hint = "Modo de vacinaçäo: clica nos pacientes infectados para uma enfermeira os vacinar. Clica com o botäo direito, carrega em Esc ou clica outra vez na seringa para parar."
multiplayer_window.vote_agree = "Concordar"
multiplayer_window.vote_asked = "Pediste aos outros para mudar a velocidade para %s."
multiplayer_window.vote_confirm = "Pedir aos outros jogadores para mudar a velocidade do jogo para %s?"
multiplayer_window.vote_decline = "Recusar"
multiplayer_window.vote_declined = "%s recusou a mudança de velocidade para %s."
multiplayer_window.vote_lapsed = "Näo houve jogadores suficientes a concordar a tempo: a velocidade fica como estava."
multiplayer_window.vote_open = "Já está a decorrer uma votaçäo para mudar a velocidade."
multiplayer_window.vote_passed = "Os jogadores concordaram: a velocidade agora é %s."
multiplayer_window.vote_passed_paused = "Os jogadores concordaram em %s: o jogo continua a essa velocidade quando sair da pausa."
multiplayer_window.vote_request = "%s gostava de mudar a velocidade do jogo"
multiplayer_window.vote_request_speed = "para %s."
multiplayer_window.waiting_player = "à espera de um jogador..."
tooltip.main_menu.multiplayer = "Jogar com outros através de um servidor multijogador (experimental)"
tooltip.multiplayer_window.ask_money = "Pede dinheiro a outro jogador. Ele decide se paga."
tooltip.multiplayer_window.auctions = "O anfitriäo decide quais os terrenos que väo a leiläo quando um jogador pede para comprar um"
tooltip.multiplayer_window.auctions_all = "Todos os terrenos väo a leiläo entre todos os hospitais que os podem comprar"
tooltip.multiplayer_window.auctions_near = "Os terrenos do lado de outro jogador ou ao lado do terreno de outro hospital väo a leiläo; os outros säo simplesmente comprados"
tooltip.multiplayer_window.auctions_none = "Sem leilöes: quem pedir primeiro compra o terreno"
tooltip.multiplayer_window.colour = "A cor do teu hospital: jogadores com a mesma cor constroem um hospital juntos. Clica para mudar (o anfitriäo pode mudar a de qualquer um, incluindo a dos bots)"
tooltip.multiplayer_window.connect = "Ligar ao servidor e mostrar as suas salas"
tooltip.multiplayer_window.continue_game = "Continua um jogo multijogador gravado antes (Ficheiro > Gravar, ou a gravaçäo automática mensal): escolhe-o na lista. Sem escolher, a sala começa um jogo novo"
tooltip.multiplayer_window.download = "Este servidor usa outra versäo do jogo: abre a página de descarga no teu navegador"
tooltip.multiplayer_window.game_options = "As opçöes do jogo: leilöes de terrenos e mais (o anfitriäo define)"
tooltip.multiplayer_window.helpers = "O anfitriäo decide: um bot que partilha o hospital de uma pessoa constrói salas e coloca objetos nos corredores, ou deixa isso para a pessoa (continua a contratar, a pagar prémios, a partilhar investigaçäo, a licitar e a comprar terrenos)"
tooltip.multiplayer_window.level = "Escolhe o nível numa lista com os objectivos e um mapa. Um hospital partilhado joga os níveis da campanha; vários hospitais jogam os níveis multijogador (1 a 8, um número maior joga o nível 8). O nível 6 é Emergência!: emergências quatro vezes por mês no primeiro ano, depois epidemias; o nível 7 é Sem Piedade, feito para uma corrida competitiva: truques sujos mês a mês, feiras de emprego, emergências de corrida e sismos; o nível 8 é a Cidade das Equipas, o mapa do Matroftt feito para dois contra dois"
tooltip.multiplayer_window.levels_players = "O mapa para este número de jogadores (cada número de jogadores tem o seu mapa)"
tooltip.multiplayer_window.name = "O nome que os outros jogadores veem"
tooltip.multiplayer_window.new_game = "Começar um jogo novo em vez do gravado"
tooltip.multiplayer_window.password = "Palavra-passe da sala onde entrar ou que criar (vazio: sem palavra-passe)"
tooltip.multiplayer_window.player_row = "Clique: ver o hospital deste jogador (N: o hospital seguinte)"
tooltip.multiplayer_window.chat_target = "Para quem é a mensagem: todos, a sua equipa (numa corrida de equipas) ou um jogador. Clique ou prima Tab para o seguinte"
tooltip.multiplayer_window.players = "Para quantos jogadores é a sala"
tooltip.multiplayer_window.rats = "O anfitriäo decide: numa corrida com truques sujos, os jogadores podem soltar ratos no hospital de um rival (custam-lhe reputaçäo), ou näo"
tooltip.multiplayer_window.ready = "Avisa o anfitriäo de que estás pronto para começar"
tooltip.multiplayer_window.refer_button = "Oferece este paciente ao hospital de outro jogador. Ele tem de aceitar."
tooltip.multiplayer_window.send_staff = "Envia este funcionário para o hospital de outro jogador. Ele tem de aceitar."
tooltip.multiplayer_window.server = "Endereço do servidor multijogador, por exemplo eu2.bachelor-tech.com:47800"
tooltip.multiplayer_window.server_eu1 = "eu1.bachelor-tech.com: a versäo estável mais recente"
tooltip.multiplayer_window.server_eu2 = "eu2.bachelor-tech.com: a versäo de teste mais recente"
tooltip.multiplayer_window.share_research = "Oferece pesquisa que tens ao hospital de outro jogador, de graça ou por um preço. Ele tem de aceitar."
tooltip.multiplayer_window.sharing = "O anfitriäo decide: os jogadores podem partilhar ou vender pesquisa entre si, ou näo (como no jogo original)"
tooltip.multiplayer_window.start = "Iniciar o jogo para todos na sala"
tooltip.multiplayer_window.team = "A tua equipa: a mesma equipa ganha junta, equipas diferentes disputam os objectivos e podem pregar partidas sujas umas às outras. Clica para mudar (o anfitriäo pode mudar a de qualquer um, incluindo a dos bots)"
tooltip.multiplayer_window.tricks = "O anfitriäo decide: numa corrida, os jogadores podem comprar truques sujos contra rivais, ou näo (como no jogo original)"
