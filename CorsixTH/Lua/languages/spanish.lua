--[[ Copyright (c) 2016 Víctor González a.k.a. "mccunyao"

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
Language("Español", "Spanish", "es", "spa", "esp", "sp")
Inherit("english")
Inherit("original_strings", 4)
IsArabicNumerals(true)

-------------------------------  OVERRIDE  ----------------------------------
adviser.warnings.money_low = "¡Tu dinero se está agotando!"
tooltip.graphs.reputation = "Cambiar reputación"
tooltip.status.close = "Cerrar pantalla de estado"

-- tooltip.staff_list.next_person, prev_person is rather next/prev page (also in german, maybe more languages?)
tooltip.staff_list.next_person = "Mostrar la página siguiente"
tooltip.staff_list.prev_person = "Mostrar la página anterior"
tooltip.status.reputation = "Tu reputación no debe estar por debajo de %d. Actualmente tienes %d"
tooltip.status.balance = "No debes tener menos de $%d en el banco. Actualmente tienes $%d"

-- The originals of these two contain one space too much
fax.emergency.cure_not_possible_build = "Necesitas construir un %s"
fax.emergency.cure_not_possible_build_and_employ = "Necesitas construir un %s y contratar un/a %s"
fax.emergency.num_disease = "Hay %d personas con %s y necesitan ser atendidas inmediatamente."
adviser.goals.lose.kill = "Mata otros %d pacientes para perder el nivel!"

-- Improve tooltips in staff window to mention hidden features
tooltip.staff_window.face = "Rostro de la persona - pulsa para abrir la pantalla de personal."
tooltip.staff_window.center_view = "Botón izquierdo para fijarse en la persona, botón derecho para rotar entre los miembros del personal."

-- Improve tooltips in Build Rooms menu
tooltip.rooms.inflation = "Un Doctor usa la Sala de Inflado para curar a pacientes cabezudos"
tooltip.rooms.tongue_clinic = "Un Doctor usa la Clínica de Lengua caída para curar la Lengua caída"
tooltip.rooms.fracture_clinic = "Una Enfermera usa la Clínica de Fracturas para reparar Huesos Fracturados"
tooltip.rooms.hair_restoration = "Un Doctor usa la Sala de Restauración Capilar para curar la Calvicie"
tooltip.rooms.decontamination = "Un Doctor usa la Ducha de Descontaminación para curar la Radiación Grave"
tooltip.rooms.ward = "Las Salas son útiles tanto para diagnóstico como para tratamiento. Los pacientes se envían aquí para observación y también se preparan para operaciones en una Sala con una Enfermera"
tooltip.rooms.research_room = "Los Doctores con habilidad de Investigación pueden descubrir nuevos medicamentos y máquinas en el Departamento de Investigación"
tooltip.objects.reception_desk = "Recepción: requiere un Recepcionista que dirija a los pacientes a la oficina del Médico General"

-- Improve tooltips in Research Screen
tooltip.research.cure_dec = "Disminuir porcentaje de investigación de Curas"
tooltip.research.cure_inc = "Aumentar porcentaje de investigación de Curas"
tooltip.research.diagnosis_dec = "Disminuir porcentaje de investigación de Diagnóstico"
tooltip.research.diagnosis_inc = "Aumentar porcentaje de investigación de Diagnóstico"
tooltip.research.drugs_dec = "Disminuir porcentaje de investigación de Medicamentos"
tooltip.research.drugs_inc = "Aumentar porcentaje de investigación de Medicamentos"
tooltip.research.improvements_dec = "Disminuir porcentaje de investigación de Mejoras"
tooltip.research.improvements_inc = "Aumentar porcentaje de investigación de Mejoras"
tooltip.research.specialisation_dec = "Disminuir porcentaje de investigación de Especialización"
tooltip.research.specialisation_inc = "Aumentar porcentaje de investigación de Especialización"

-- These strings are missing in some versions of TH (unpatched?)
confirmation.restart_level = "¿Seguro que quieres reiniciar el nivel?"
-- TODO adviser.multiplayer.objective_completed
-- TODO adviser.multiplayer.objective_failed







-- An override for the squits becoming the the squits see issue 1646
adviser.research.drug_improved_1 = "El medicamento %s ha sido mejorado por tu Departamento de Investigación."

-- Disease overrides where there are typos
diseases.golf_stones.cure = "Cura - Deben ser extraídas mediante una operación que requiere dos Cirujanos."
diseases.ruptured_nodules.cure = "Cura - Dos Cirujanos calificados deben extraer los nódulos con mano firme."
diseases.slack_tongue.cause = "Causa - Discusión crónica excesiva sobre telenovelas."
diseases.slack_tongue.cure = "Cura - La lengua se coloca en la Máquina Cortadora y se extrae de forma rápida, eficiente y dolorosa."
diseases.the_squits.cure = "Cura - Una mezcla glutinosa de compuestos farmacéuticos fibrosos solidifica las entrañas del paciente."
diseases.bloaty_head.cure = "Cura - La cabeza hinchada se pincha y luego se vuelve a inflar hasta la presión correcta con una máquina inteligente."

-- Rooms overrides where there are typos
room_descriptions.inflation[2] = "Los pacientes con la dolorosa pero cómica condición de cabezudo deben acudir a la Clínica de Inflado, donde el cráneo agrandado será pinchado e inflado instantáneamente a la presión correcta.//"
room_descriptions.staff_room[2] = "Tu personal se cansa al realizar sus tareas. Necesitan esta sala para relajarse y recuperarse. El personal cansado trabaja más lento, exige más dinero y eventualmente renunciará. También cometen más errores. Construir una sala de personal con suficientes actividades es muy provechoso. Asegúrate de que haya espacio para varios miembros del personal a la vez. "

-- Staff description overrides where there are typos
staff_descriptions.bad[14] = "Astuto, taimado y subversivo. "
staff_descriptions.misc[11] = "Destila whisky. "

-- Correction to a pay rise prompt with typos
pay_rise.regular[1] = "Estoy totalmente agotado. Necesito un buen descanso, además de un aumento de %d si no quieres verme dejar este trabajo de mala muerte."

-- Level description overrides where there are typos. Note: This is the only portion of the game that SHOULD use double space after fullstops etc.
introduction_texts.level17 = " Última advertencia - mantén un ojo atento en tu Reputación - esto es lo que atraerá pacientes de todas partes a tu establecimiento.  Si no matas a demasiada gente y los mantienes razonablemente contentos, no deberías tener demasiados problemas en este nivel!// Ahora estás por tu cuenta.  Buena suerte y todo eso."
introduction_texts.level11 = " Se te ha dado la oportunidad de construir el mejor de los hospitales.  Esta es un área extremadamente prestigiosa, y el Ministerio quisiera ver el mejor hospital posible.  Esperamos que generes mucho dinero, tengas una reputación excelente y cubras cualquier eventualidad posible.  Es un trabajo importante, este.  Tendrás que ser alguien especial para lograrlo.  Ten en cuenta, además, que ha habido avistamientos de ovnis en la zona.  Asegúrate de que tu personal esté preparado para algunas visitas inesperadas.  Tu hospital deberá valer $240,000, necesitarás $500,000 en el banco, y tu reputación deberá ser de 700."
introduction_texts.level9 = " Habiendo llenado las arcas del Ministerio y pagado una nueva limusina para el propio Ministro, ahora puedes volver a crear un hospital cuidadoso y bien administrado en beneficio de los enfermos y necesitados.  Puedes esperar que surjan muchos problemas diferentes aquí.  Si tienes suficiente personal bien entrenado y salas, deberías tener todos los ángulos cubiertos.  Tu hospital deberá valer $200,000, y necesitarás $400,000 en el banco.  Con menos, no podrás terminar el nivel."
introduction_texts.level16 = " Una vez que hayas diagnosticado a algunos de los pacientes, necesitarás construir instalaciones de tratamiento y clínicas para curarlos - una buena opción para empezar es la Farmacia.  También necesitarás una Enfermera para despachar los distintos medicamentos en la Farmacia."
introduction_texts.level10 = " Además de cubrir todas las enfermedades que surgen en esta zona, el Ministerio solicita que dediques algo de tiempo a concentrarte en la eficiencia de tus medicamentos.  Ha habido algunas quejas de Ofsick, el Vigilante de la Salud, así que para quedar bien debes asegurarte de que todos tus medicamentos sean extremadamente eficientes.  Además, asegúrate de que tu hospital esté libre de reproches.  Mantén bajas esas muertes.  Como consejo, quizás quieras dejar espacio libre para un Tanque de Gelatina.  Desarrolla todos tus medicamentos a al menos 80 por ciento de eficiencia, consigue una reputación de 650 y guarda $500,000 en el banco para ganar."
introduction_texts.level12 = " Ahora tienes el desafío de todos los desafíos.  Impresionado por tu éxito, el Ministerio tiene el trabajo más importante para ti; quieren que alguien construya otro hospital definitivo, gane una cantidad enorme de dinero y tenga una reputación increíble.  También se espera que compres toda la tierra que puedas, cures todo (y decimos todo) y ganes todos los premios.  ¿Crees que estás a la altura?  Gana $650,000, cura a 750 personas, y consigue una reputación de 800 para ganar este nivel."
introduction_texts.level15 = " Bien, esa es la mecánica básica de armar un hospital.// Tus Doctores van a necesitar toda la ayuda posible para diagnosticar a algunos de estos pacientes.  Puedes ayudarlos construyendo otra instalación de diagnóstico como la Sala de Diagnóstico General."
-- A small error in the introduction text of level 2
introduction_texts.level2 = " Hay una mayor variedad de dolencias en esta zona.  Prepara tu hospital para atender a más pacientes, " ..
                            "y planea construir un Departamento de Investigación.  Recuerda mantener tu establecimiento limpio, e intenta mantener tu " ..
                            "reputación lo más alta posible - estarás lidiando con enfermedades como Lengua Caída, así que necesitarás una Clínica de " ..
                            "Lengua Caída.  También puedes construir un Cardiograma para ayudarte a diagnosticar nuevas enfermedades.  Ambas salas " ..
                            "necesitarán ser investigadas antes de que puedas construirlas.  Ahora también puedes comprar terrenos adicionales para expandir tu " ..
                            "hospital - usa el mapa de la ciudad para esto.  Apunta a una reputación de 300, un saldo bancario de $10,000 y 40 personas curadas."

-- Override for level progress typo
level_progress.hospital_value_enough = "Mantén el valor de tu hospital por encima de %d y atiende tus otros problemas para ganar el nivel."
level_progress.cured_enough_patients = "Has curado suficientes pacientes, pero necesitas poner tu hospital en mejor orden para ganar el nivel."

-- Override for multiplayer typos
multiplayer.players_failed = "Los siguientes jugadores no lograron alcanzar el último objetivo:"
multiplayer.everyone_failed = "Todos fallaron en satisfacer ese último objetivo. ¡Así que todos pueden seguir jugando!"

-- Override for a disease patient choice typo
disease_discovered_patient_choice.need_to_employ = "Emplea a un %s para poder manejar esta situación."

-- Override for shorter messages and a typo in 12.2
letter[9][2] = "Has demostrado ser el mejor administrador de hospitales en la larga y accidentada historia de la medicina. Un logro tan trascendental no puede quedar sin recompensa, así que nos gustaría ofrecerte el puesto honorario de Jefe Supremo de Todos los Hospitales. Esto viene con un salario de $%d. Se te dará un desfile con confeti, y la gente mostrará su aprecio dondequiera que vayas.//"
letter[10][2] = "Felicidades por dirigir exitosamente cada hospital que te asignamos. Un desempeño tan excelente te califica para la libertad de todas las ciudades del mundo. Se te otorgará una pensión de $%d, y lo único que pedimos es que viajes, gratis, por toda la nación, promoviendo el trabajo de todos los hospitales ante tu público admirador.//"
letter[11][2] = "Tu carrera ha sido ejemplar, y eres una inspiración para todos nosotros. Gracias por dirigir tantos hospitales tan bien. Nos gustaría otorgarte un salario vitalicio de $%d, y solo pedimos que viajes en un auto oficial descapotable de ciudad en ciudad, dando conferencias sobre cómo lograste tanto tan rápido.//"
letter[11][3] = "Eres un ejemplo para toda persona sabia, y sin excepción, todos en el mundo te consideran un activo supremo.//"
letter[12][2] = "Tu exitosa carrera como el mejor administrador de hospitales desde Moisés se acerca a su fin. Acorde a tu impacto en la nación, el Ministerio te ofrece un salario de $%d simplemente por aparecer en nuestro nombre, inaugurando ferias, botando barcos y participando en programas de entrevistas. ¡Sería una excelente publicidad para todos nosotros!//"

tooltip.handyman_window.close = "Cerrar ventana"
tooltip.machine_window.close = "Cerrar ventana"
tooltip.queue_window.close = "Cerrar ventana"
tooltip.jukebox.rewind = "Rebobinar reproductor de música"
tooltip.jukebox.loop = "El reproductor de música funciona continuamente"
tooltip.jukebox.stop = "Parar reproductor de música"
tooltip.jukebox.close = "Cerrar reproductor de música"
tooltip.jukebox.current_title = "Reproductor de música"
tooltip.jukebox.play = "Encender reproductor de música"
tooltip.jukebox.fast_forward = "Avance rápido del reproductor de música"
tooltip.patient_window.close = "Cerrar ventana"
tooltip.staff_window.close = "Cerrar ventana"
tooltip.build_room_window.close = "Salir de esta ventana y volver al juego"

misc.hospital_open = "Hospital abierto"
misc.save_success = "Partida guardada correctamente"
misc.save_failed = "ERROR: No se ha podido guardar la partida"
misc.out_of_sync = "Partida desincronizada"

-- Some overrides as original texts were too long see issue 1355 MarkL
high_score = {
  categories = {
    deaths = "FALLECIMIENTOS",
    total_value = "VALOR TOTAL",
    money = "RIQUEZA",
    cures = "CURACIONES",
    visitors = "VISITANTES",
    staff_number = "PLANTILLA",
  cure_death_ratio = "PROPORCIÓN",
    patient_happiness = "CLIENTES CONTENTOS",
    staff_happiness = "PERSONAL CONTENTO",
    salary = "SUELDO MAS ALTO",
    clean = "LIMPIEZA",
  },
  player = "JUGADOR",
  score = "PUNTOS",
  pos = "POS",
  best_scores = "TABLA DEL HONOR",
  worst_scores = "TABLA DE LA VERGUENZA",
  killed = "Muerto"
}

--String text gets outside of window
confirmation.quit = "¿Seguro que quieres salir del juego?                       "

--Typos found on the official Spanish translation
tooltip.rooms.dna_fixer = "El médico usa el Reparador de ADN para curar a los pacientes con ADN alienígena"
diseases.broken_heart.cause = "Causa - alguien más rico, más joven y más delgado que el paciente."
fax.emergency.locations[1] = "Planta química González"
fax.emergency.locations[3] = "Centro de plantas acuáticas"
fax.emergency.locations[5] = "Congreso de bailarines rusos"
fax.emergency.locations[8] = "La casa del curry"
fax.emergency.locations[9] = "Emporio petroquímico usado Díaz y Díaz"
fax.epidemic.cover_up_explanation_2 = "Si un inspector sanitario te visita y encuentra una epidemia encubierta tomará medidas drásticas en tu contra."
fax.epidemic.disease_name = "Tus médicos han descubierto una variedad contagiosa de %s."
tooltip.main_menu.continue = "Continuar la última partida guardada."
tooltip.watch.epidemic = "Epidemia: tiempo que queda para encubrir la epidemia. Cuando este tiempo expire O un paciente contagioso abandone tu hospital, un Inspector de Sanidad puede visitarte. El botón activa o desactiva el modo vacuna. Pulsa en un paciente para que lo vacune una Enfermera."
tooltip.watch.hospital_opening = "Tiempo de construcción: es el tiempo que queda para que tu hospital sea declarado abierto. Si pulsas el botón verde abrirás el hospital inmediatamente."
rooms_short.decontamination = "Descontaminación"
adviser.room_requirements.op_need_another_surgeon = "Tienes que contratar a otro cirujano para poder usar el quirófano."
adviser.information.patient_abducted = "Los alienígenas han raptado a uno de tus pacientes."
adviser.praise.plants_thriving = "Muy bien. Tus plantas están muy lozanas. Tienen un aspecto maravilloso. Si las mantienes así podrás ganar un premio."
adviser.level_progress.reputation_good_enough = "De acuerdo, tu reputación lo es bastante buena para ganar este nivel, manténla por encima de %d y soluciona otros problemas para terminar."
adviser.staff_place_advice.only_nurses_in_room = "Sólo pueden trabajar las Enfermeras en el(la) %s"
adviser.tutorial.select_receptionists = "Haz clic en el icono que parpadea para ver qué recepcionistas están disponibles."
rooms_long.decontamination = "Consulta de Descontaminación"
dynamic_info.staff.ability = "Habilidad"
dynamic_info.staff.actions.going_to_repair = "Yendo a reparar %s"
dynamic_info.object.queue_expected = "Fila esperada: %d"
research.categories.drugs = "Investigación farmacéutica"
transactions = {
  machine_replacement = "Coste de máquina de reemplazo",
  eoy_trophy_bonus = "Primas por trofeo Fin de Año",
  drinks = "Ingreso: Máquinas de bebidas",
  jukebox = "Ingreso: Gramolas",
  cheat = "Dinero de trampas",
  eoy_bonus_penalty = "Primas/Multas en fin de año",
}
confirmation.return_to_blueprint = "¿Seguro que quieres sustituir el(la) %s por $%d?"
staff_descriptions = {
  misc = {
    [9] = "Le gusta hacer surf. ",
    [10] = "Le gusta el piragüismo. ",
    [11] = "Destila whisky. ",
    [12] = "Es un experto en formación. ",
    [13] = "Le gusta el cine francés. ",
    [15] = "Conduce coches de carreras. ",
    [25] = "Participó en un concurso. ",
    [26] = "Colecciona metralla de la segunda guerra mundial. ",
    [29] = "Pone furiosos a los insectos rociándolos con desodorante. ",
  },
  good = {
    [3] = "Sabe de todo.",
  },
}
progress_report.percentage_pop = "% población"
letter = {
  [1] = {
    [1] = "¡Hola, %s!//",
    [2] = "¡Estupendo! Diriges este hospital de una manera excelente. Los peces gordos del Ministerio de Sanidad queremos saber si estarías interesado en hacerte cargo de un gran proyecto. Hay un trabajo para el que creemos eres la persona perfecta. El sueldo sería de %d. Piénsalo.//",
  },
  [2] = {
    [1] = "¡Hola, %s!//",
    [2] = "¡Felicidades! Has realizado notables mejoras en tu hospital. Tenemos otra cosa de la que podrías encargarte, si te apetece un cambio y afrontar nuevos retos. No tienes que aceptar, pero estaría bien que lo hicieras. El sueldo es de %d//",
  },
  [3] = {
    [1] = "¡Hola, %s!//",
    [2] = "Has dirigido con notable acierto este hospital. Creemos que tienes un brillante futuro y nos gustaría ofrecerte un puesto en otra parte. El sueldo sería de %d y creemos que te encantaría el reto que ello supondría.//",
  },
  [4] = {
    [1] = "¡Hola, %s!//",
    [2] = "¡Felicidades! En el Ministerio estamos muy impresionados por tu capacidad como director de hospital. Eres sin duda una persona valiosa para el Departamento de Sanidad, pero creemos que preferirías un trabajo más cualificado. Recibirías un sueldo de %d, si bien la decisión es tuya.//",
  },
  [5] = {
    [1] = "¡Hola, %s!//",
    [2] = "Saludos de nuevo. Respetamos tus deseos de no trasladarte de tu estupendo hospital, pero te pedimos que lo reconsideres. Te ofreceremos un mejor sueldo de %d si decides marcharte a otro hospital y te encargas de la dirección del mismo.//",
  },
  [6] = {
    [1] = "¡Hola, %s!//",
    [2] = "Recibe nuestros saludos. Sabemos lo mucho que has disfrutado de tu estancia en esta institución, tan agradable y bien dirigida, pero creemos que ahora deberías pensar en tu futuro. Naturalmente, tendrías un sueldo de %d si decidieras trasladarte. Merece la pena que lo pienses.//",
  },
  [7] = {
    [1] = "¡Hola, %s!//",
    [2] = "¡Buenos días! El Ministerio de Sanidad quisiera saber si vas a reconsiderar tu decisión de quedarte en tu hospital. Comprendemos que tienes un estupendo hospital, pero creemos que harías muy bien en aceptar un trabajo más estimulante, con un sueldo de %d.//",
  },
  [8] = {
    [1] = "¡Hola, %s!//",
    [2] = "Buenas de nuevo. Recibimos tu negativa a nuestra última carta, en la que te ofrecíamos un puesto de dirección en otro hospital y un alto sueldo de %d. No obstante, creemos que deberías reconsiderar esta decisión. Como verás, tenemos el trabajo perfecto para ti.//",
  },
  [9] = {
    [1] = "¡Hola, %s!//",
    [2] = "Has demostrado ser el mejor director de hospital en la larga y azarosa historia de la medicina. Este importantísimo logro no puede quedar sin recompensa, por lo que nos gustaría ofrecerte el puesto de Director Jefe de Todos los Hospitales. Es un puesto honorífico, con un sueldo de %d. Tendrás una presentación con todos los honores y la gente te demostrará su reconocimiento vayas donde vayas.//",
  },
  [10] = {
    [1] = "¡Hola, %s!//",
    [2] = "Enhorabuena, has gestionado tus hospitales satisfactoriamente. Este logro te permitirá viajar dónde quieras, con una paga de %d y una limusina. Aunque por supuesto esperamos que en tus viajes, no defraudes a tu público y sigas promocionando los hospitales.//"
  },
  [11] = {
    [1] = "¡Hola, %s!//",
    [3] = "Eres un ejemplo para todos los hombres de bien y todo el mundo, sin excepción, te considera una persona de enorme valía.//",
  },
  [12] = {
    [1] = "¡Hola, %s!//",
    [2] = "Tu exitosa carrera como el mejor director de hospital desde Moisés está llegando a su fin. No obstante, has provocado tal efecto en los círculos médicos, que el Ministerio quiere ofrecerte un sueldo de %s sólo por actuar en nuestro nombre inaugurando festejos, botando barcos y organizando coloquios. ¡El mundo entero te aclamaría y serías un excelente relaciones públicas!//",
  },
}
tooltip.staff_window.ability = "Nivel de cualificación"
tooltip.policy.diag_termination = "Se mantendrá el diagnóstico de un paciente hasta que los médicos estén seguros del porcentaje de DETENER, o hasta que se hayan usado todos los diagnosticadores"
tooltip.staff_list.ability = "Muestra el nivel de habilidad de estos empleados"

introduction_texts = {
  level1 =
    "¡Bienvenido a tu primer hospital!//" ..
    "Para hacer que empiece a funcionar, coloca una recepción, construye una consulta y contrata a una recepcionista y a un médico. " ..
    "Luego espera a que lleguen los pacientes. " ..
    "Sería una buena idea que construyeras una consulta de psiquiatría y contrataras a un psiquiatra. " ..
    "Una farmacia y una enfermera son fundamentales para curar a tus pacientes. " ..
    "Cuidado con los casos malignos de pacientes cabezudos; se solucionan pronto en la consulta de inflatoterapia. " ..
    "Tendrás que curar a 10 personas y asegurarte de que tu reputación no sea inferior a 200.",

  level2 =
    "Hay una gran variedad de indisposiciones en esta zona.//" ..
    "Prepara tu hospital para tratar a más pacientes y proyecta la construcción de un Departamento de Investigación. " ..
    "Recuerda que debes mantener limpio el hospital y procura conseguir que tu reputación sea lo más alta posible. Tratarás enfermedades como la Lengua Larga, así que necesitarás una consulta de laringología. " ..
    "También puedes construir un cardiómetro para diagnosticar nuevas enfermedades. " ..
    "Estas dos consultas deberán ser investigadas antes de construirlas. También puedes comprar más terreno para ampliar tu hospital. Para ello, utiliza un mapa de la ciudad. ",
    "Intenta alcanzar una reputación de 300, un saldo bancario de 10.000 dólares y cura a 40 personas.",

  level3 =
    "Esta vez colocarás tu hospital en una zona acaudalada.//" ..
    "El Ministerio de Sanidad espera que consigas curar a muchos pacientes. " ..
    "Tendrás que ganarte una buena reputación para empezar, pero una vez que el hospital empiece a funcionar, concéntrate en ganar todo el dinero que puedas. " ..
    "También puede haber urgencias. " ..
    "Se producen cuando llega mucha gente que padece la misma enfermedad. " ..
    "Si los curas dentro de un plazo determinado, conseguirás aumentar tu reputación y ganar una prima extra. " ..
    "Habrá enfermedades, como el síndrome de rey, y deberás tener presupuesto para construir un quirófano y una enfermería adyacente. " ..
    "Tienes que ganar 20.000 dólares para superar este nivel.",

  level4 =
    "Haz que todos tus pacientes estén contentos, atiéndelos con la mayor eficacia e intenta que mueran los menos posibles.//" ..
    "Tu reputación está en juego, así que procura aumentarla todo lo que puedas. " ..
    "No te preocupes demasiado por el dinero; Lo irás ganando a medida que crezca tu reputación. " ..
    "También podrás formar a tus médicos para ampliar sus conocimientos: " ..
    "ellos podrán curar a los pacientes más difíciles. " ..
    "Alcanza una reputación por encima de 500.",

  level5 =
    "Este será un hospital concurrido, que tratará casos muy variados.//" ..
    "Tus médicos acaban de salir de la facultad, por lo que es fundamental que construyas una sala de formación para que alcancen el nivel de formación necesario. " ..
    "Sólo tienes tres especialistas para enseñar a tu personal inexperto, así que procura que estén contentos. " ..
    "Tienes que tener en cuenta que el hospital está ubicado encima de la falla geológica de San Androide. " ..
    "Siempre hay riesgo de terremoto. " ..
    "Los terremotos provocarán daños importantes en tus máquinas y alterarán el buen funcionamiento de tu hospital. " ..
    "Aumenta tu reputación hasta 400 y consigue unos ingresos de 50.000 dólares para triunfar. También debes curar a 200 pacientes. ",

  level6 =
    "Utiliza toda tu capacidad para conseguir un hospital que funcione bien y consiga curar a muchos pacientes y que pueda tratar cualquier caso que presenten los enfermos.//" ..
    "Estás avisado de que el ambiente, aquí, es especialmente propenso a gérmenes e infecciones. " ..
    "A menos que mantengas una escrupulosa limpieza en tu institución, tendrás que hacer frente a una serie de epidemias entre los pacientes. " ..
    "Procura obtener unos ingresos de 20.000 dólares y que el valor de tu hospital supere los 140.000 dólares. ",

  level7 =
    "Aquí estarás bajo la estricta vigilancia del Ministerio de Sanidad, así que procura que tus cuentas tengan unos ingresos excelentes y que aumente tu reputación.//" ..
    "No podemos permitirnos que haya muertes innecesarias; no son nada buenas para el negocio. " ..
    "Asegúrate de que tu personal está en plena forma y de que tienes todos los equipos necesarios. " ..
    "Consigue una reputación de 600, y un saldo bancario de 200.000 dólares.",

  level8 =
    "De ti depende que puedas construir el hospital más eficiente y rentable posible.//" ..
    "La gente de por aquí es bastante adinerada, así que sabléalos todo lo que puedas. " ..
    "Recuerda, curar a la gente está muy bien, pero lo que de verdad NECESITAS es su dinero. " ..
    "Despluma vivos a estos pacientes. " ..
    "Acumula 300.000 dólares para completar este nivel. ",

  level9 =
    "Después de ingresar dinero en la cuenta bancaria del Ministerio y pagar una nueva limusina para el Ministro, ahora puedes dedicarte a crear un buen hospital para cuidar a los enfermos y necesitados. " ..
    "Aquí tendrás un montón de problemas diferentes. " ..
    "Si tu personal tiene una buena formación y cuentas con suficientes consultas, podrás resolver cualquier situación. " ..
    "Tu hospital tendrá que valer 200.000 dólares y necesitarás tener 400.000 dólares en el banco. " ..
    "Si no lo consigues no podrás terminar el nivel.",

  level10 =
    "Además de ocuparte de curar todas las enfermedades que pueda haber, el Ministerio te pide que emplees algo de tiempo en aumentar la eficacia de tus medicinas.//" ..
    "Ha habido algunas quejas por parte de D. Salutísimo, el Perro Guardián de la Salud, así que debes procurar que todas tus medicinas sean sumamente eficaces para quedar bien. " ..
    "También debes asegurarte de que tu hospital tenga una reputación intachable. Procura que mueran pocos pacientes. " ..
    "Como sugerencia, deberías dejar espacio para un baño gelatinoso. " ..
    "Para ganar, tus medicinas deberán tener una eficacia de, al menos, un 80%, tienes que conseguir una reputación de 650 y guardar 500.000 dólares en el banco.",

  level11 =
    "Tienes la oportunidad de construir el no va más en hospitales. " ..
    "Esta es una zona de enorme prestigio y al Ministerio le gustaría que éste fuera el mejor hospital. " ..
    "Esperamos que ganes mucho dinero, alcances una excelente reputación y te ocupes de todos los casos que se presenten. " ..
    "Este es un trabajo importante. " ..
    "Tendrás que ser muy hábil para llevarlo a cabo. " ..
    "También debes tener en cuenta que se han visto ovnis en la zona. Asegúrate de que tu personal esté preparado para recibir alguna visita inesperada. " ..
    "Tu hospital tendrá que alcanzar un valor de 240.000 dólares, necesitarás tener 500.000 dólares en el banco y una reputación de 700.",

  level12 =
    "Ahora te enfrentas al mayor de los retos. " ..
    "El Ministerio ha quedado impresionado con tus logros y tiene una tarea difícil para ti, quieren que se construya otro magnífico hospital, que tenga unos excelentes ingresos y una reputación increíble. " ..
    "También se espera que compres todo el terreno que puedas, cures todo (y queremos decir todas las enfermedades) y ganes todos los premios. " ..
    "¿Crees que podrás conseguirlo? " ..
    "Gana 650.000 dólares, cura a 750 personas y consigue una reputación de 800 para ganar este nivel. ",

  level13 =
    "Tu increíble habilidad como director de hospital ha atraído la atención de la División Secreta Especial del Servicio Secreto Especial. " ..
    "Tienen un trabajo especial para ti. Hay un hospital infestado de ratas que necesita un exterminador eficiente. " ..
    "Tienes que matar todas las ratas que puedas antes de que el personal de Mantenimiento limpie toda la suciedad. " ..
    "¿Crees que eres apto para la misión?",

  level14 =
    "Aún tienes un reto más: el hospital sorpresa totalmente imprevisible. " ..
    "Si consigues tener éxito, serás el ganador de todos los ganadores. " ..
    "Y no esperes que sea pan comido, porque es la tarea más difícil que jamás afrontarás. " ..
    "¡Buena suerte!",

  level15 =
    "Bien, estos son los mecanismos básicos para poner en marcha un hospital.//" ..
    "Tus Médicos van a necesitar toda la ayuda que puedan obtener para diagnosticar a algunos de los pacientes. " ..
    "Puedes ayudarles construyendo otros equipos de diagnóstico como la Sala de Diagnóstico General.",

  level16 =
    "Una vez que hayas diagnosticado a alguno de los pacientes necesitarás construir salas de tratamiento y clínicas para curarles: " ..
    "puedes comenzar con una Farmacia, y necesitarás una Enfermera que dispense las medicinas en la Farmacia.",

  level17 =
    "Un último aviso: estate atento a tu Reputación, es lo que atraerá pacientes a tu establecimiento. " ..
    "¡Si no matas a mucha gente y los mantienes razonablemente felices no deberías tener muchos problemas en este nivel!//" ..
    "Ahora es cosa tuya, buena suerte y todo eso.",

  demo =
    "¡Bienvenido al hospital de demostración!//" ..
    "Por desgracia, la versión de demostración solo contiene este nivel. Sin embargo, tienes más que suficiente para estar entretenido por un rato. " ..
    "Te enfrentarás a varias enfermedades que necesitan de ciertas habitaciones para su cura. De vez en cuando pueden surgir emergencias. Y necesitarás " ..
    "investigar sobre las enfermedades construyendo un Departamento de investigación. " ..
    "Tu objetivo es ganar 100.000 dólares, que el valor de tu hospital llegue hasta 70.000 dólares y tengas una reputación de 700, con un porcentaje de pacientes curados del 75%. " ..
    "Procura que tu reputación no caiga por debajo de 300 y que no mates a más del 40% de tus pacientes, o fracasarás.//" ..
    "¡Buena suerte!",
}

town_map.area = "Zona"
trophy_room = {
  rats_killed = {
    trophies = {
      [2] = "Mereces este premio de la Federación Matarratas por tu excepcional habilidad para eliminar ratas, demostrándolo al acabar con %s ejemplares.",
      [3] = "Se te concede el Trofeo Exterminador de Ratas por tu gran habilidad para eliminar %d ratas en tu hospital el año pasado.",
    },
  },
  hosp_value = {
    penalty = {
      [1] = "Tu hospital no ha alcanzado un valor razonable. Has administrado mal el dinero. Recuerda, un buen hospital también es un hospital caro.",
    },
    regional = {
      [1] = "Eres una promesa de los negocios. Tu hospital es el más valioso de toda la zona.",
    },
  },
  happy_patients = {
    awards = {
      [2] = "Los pacientes que visitaron tu hospital se sintieron más contentos con su tratamiento que en el resto de los hospitales.",
    },
    penalty = {
      [1] = "La gente que acude al hospital tiene una experiencia terrible. Tendrás que esforzarte más si quieres ganarte el respeto del Ministerio.",
      [2] = "La gente que fue atendida en tu hospital se quejó del estado del mismo. Deberías tener más en cuenta el bienestar de los pacientes.",
    },
  },
  research = {
    penalty = {
      [1] = "Has sido poco eficiente investigando curaciones, máquinas y medicinas nuevas. Esto no es bueno, ya que el avance tecnológico es algo fundamental.",
    },
    regional_bad = {
      [1] = "Los demás hospitales son mejores que el tuyo en investigación. En el Ministerio están furiosos, tu hospital debería concederle más importancia.",
    },
  },
  many_cured = {
    regional = {
      [1] = "Se te concede el premio a la curación total por haber curado a más gente que todos los demás hospitales juntos.",
    },
    awards = {
      [1] = "Felicidades por curar a un montón de gente el año pasado. Un gran número de personas se sienten mucho mejor gracias a tu trabajo.",
    },
  },
  best_value_hosp = {
    penalty = {
      [1] = "Todos los hospitales de la zona valen más que el tuyo. Haz algo respecto a esta vergonzosa situación. ¡Consigue cosas más caras!",
    },
  },
  healthy_plants = {
    trophies = {
      [2] = "Salvar a las Plantas quiere concederte el Premio del Ecologista Mayor por mantener bien sanas las plantas de tu hospital durante el pasado año.",
    },
  },
  high_rep = {
    regional = {
      [1] = "Por favor, acepta el Premio Bullfrog por dirigir el mejor hospital del año. ¡Disfrútalo, te lo has ganado!",
    },
  },
  consistant_rep = {
    trophies = {
      [2] = "Felicidades por ganar el Premio Sábanas Limpias por ser el hospital con la mejor reputación del año. Te lo has merecido.",
    },
  },
  wait_times = {
    penalty = {
      [1] = "En tu hospital, los pacientes esperan demasiado tiempo. Siempre hay colas inaceptables. Podrías tratar a tus pacientes con más eficacia si quisieras.",
    },
  },
  happy_staff = {
    awards = {
      [2] = "Tu personal está tan contento de trabajar para ti que no pueden dejar de sonreír. Eres un director excelente.",
    },
    trophies = {
      [1] = "Has ganado el Premio Médico Sonriente por mantener lo más contento posible a tu personal.",
      [3] = "Te concedemos el premio Copa de la Sonrisa Radiante por mantener contento a todo tu personal por encima de todo durante el año pasado.",
    },
  },
  emergencies = {
    award = {
      [1] = "¡Felicidades! Has ganado este premio por la eficacia con la que has solucionado las urgencias. Buen trabajo.",
    },
  },
}
diseases = {
  corrugated_ankles = {
    cause = "Causa: Atropellar señales de tráfico en la carretera.",
    symptoms = "Síntomas: Los pies no entran en los zapatos.",
    cure = "Cura: Los tobillos se enderezan bebiendo una infusión ligeramente tóxica de hierbas y plantas.",
  },
  jellyitis = {
    cause = "Causa: Una dieta rica en gelatina y demasiado ejercicio.",
    symptoms = "Síntomas: Un temblor excesivo y caerse al suelo muchas veces.",
    cure = "Cura: Se sumerge al paciente durante un rato en el baño gelatinoso en una consulta especial.",
  },
  kidney_beans = {
    cause = "Causa: Masticar los cubitos de hielo de las bebidas.",
    symptoms = "Síntomas: Dolor e ir con frecuencia al baño.",
    cure = "Cura: Dos cirujanos extraen los cálculos sin rozar los bordes del riñón.",
  },
  fractured_bones = {
    cause = "Causa: Caída de cosas voluminosas sobre el cemento.",
    symptoms = "Síntomas: Un gran crujido y la imposibilidad de usar los miembros afectados.",
    cure = "Cura: Se pone una escayola, que después se quita con un láser quitaescayolas.",
  },
  spare_ribs = {
    cause = "Causa: Sentarse sobre suelos muy fríos.",
    symptoms = "Síntomas: Malestar en el pecho.",
    cure = "Cura: Dos cirujanos extraen las costillas y se las dan al paciente en una bolsita.",
  },
  alien_dna = {
    cause = "Causa: Enfrentarse a gigantes que tienen sangre alienígena inteligente.",
    symptoms = "Síntomas: Metamorfosis gradual en alienígena y deseos de destruir nuestras ciudades.",
    cure = "Cura: Se extrae el ADN con una máquina, se purifica de elementos alienígenas y se vuelve a inyectar rápidamente.",
  },
  invisibility = {
    cause = "Causa: El picotazo de una hormiga radiactiva (e invisible).",
    symptoms = "Síntomas: Los pacientes no sufren. Muchos aprovechan su enfermedad para gastar bromas a sus familiares.",
    cure = "Cura: Beber un líquido coloreado en la farmacia que hará completamente visible al paciente.",
  },
  infectious_laughter = {
    cause = "Causa: Una comedia clásica de situación",
    symptoms = "Síntomas: No poder parar de reír y repetir frases hechas nada divertidas.",
    cure = "Cura: Un psiquiatra cualificado debe recordar al paciente que su enfermedad es grave.",
  },
  broken_wind = {
    cause = "Causa: Usar un aparato gimnástico después de las comidas.",
    symptoms = "Síntomas: Molestar a la gente que está justo detrás del paciente.",
    cure = "Cura: En la farmacia se bebe rápidamente una fuerte mezcla de átomos acuosos.",
  },
  chronic_nosehair = {
    cause = "Causa: Oler con desprecio a aquellos que están peor que el paciente.",
    symptoms = "Síntomas: Tener tanto pelo en la nariz como para hacer una peluca.",
    cure = "Cura: Se toma por vía oral un jarabe quitapelo preparado en la farmacia.",
  },
  bloaty_head = {
    name = "Paciente cabezudo",
    cause = "Causa: Oler queso y beber agua de lluvia no purificada.",
    symptoms = "Síntomas: Muy incómodos para el paciente.",
    cure = "Cura: Se pincha la cabeza hinchada y luego se vuelve a inflar hasta el tamaño correcto con una máquina inteligente.",
  },
  serious_radiation = {
    name = "Radiación grave",
    cause = "Causa: Confundir isótopos de plutonio con chicle.",
    symptoms = "Síntomas: Los pacientes que padecen esta enfermedad se sienten muy, pero que muy mal.",
    cure = "Cura: Se debe dar al paciente una buena ducha descontaminadora.",
  },
  ruptured_nodules = {
    cause = "Causa: Tirarse de cabeza al agua fría.",
    symptoms = "Síntomas: Imposibilidad de sentarse cómodamente.",
    cure = "Cura: Dos cirujanos cualificados colocan ciertas partes con manos firmes.",
  },
  gastric_ejections = {
    cause = "Causa: Comida mejicana o india muy condimentada.",
    symptoms = "Síntomas: El paciente vomita la comida a medio digerir en cualquier momento.",
    cure = "Cura: Beber un preparado astringente especial para detener los vómitos.",
  },
  hairyitis = {
    cause = "Causa: Exposición prolongada a la luna.",
    symptoms = "Síntomas: Los pacientes experimentan un aumento del olfato.",
    cure = "Cura: Una máquina de electrólisis elimina el vello y cierra los poros.",
  },
  sweaty_palms = {
    cause = "Causa: Temer las entrevistas de trabajo.",
    symptoms = "Síntomas: Dar la mano al paciente es como coger una esponja empapada.",
    cure = "Cura: Un psiquiatra debe discutir a fondo con el paciente sobre esta enfermedad inventada.",
  },
  diag_x_ray = {
    name = "Diag. de rayos X",
  },
  the_squits = {
    cause = "Causa: Comer pizza que se ha encontrado debajo de la cocina.",
    symptoms = "Síntomas: ¡Agh! Seguro que te los puedes imaginar.",
    cure = "Cura: Una mezcla de sustancias viscosas preparada en la farmacia solidifica las tripas del paciente.",
  },
  slack_tongue = {
    name = "Lengua caída",
    cause = "Causa: Hablar sin parar sobre culebrones.",
    symptoms = "Síntomas: La lengua crece hasta cinco veces su tamaño original.",
    cure = "Cura: Se coloca la lengua en el acortalenguas y se elimina de forma rápida, eficaz y dolorosa.",
  },
  pregnancy = {
    cause = "Causa: Cortes de electricidad en zonas urbanas.",
    symptoms = "Síntomas: Comer por antojo con el consecuente malestar de estómago.",
    cure = "Cura: Se extrae al bebé en el quirófano, se limpia y se entrega al paciente.",
  },
  sleeping_illness = {
    cause = "Causa: Una glándula del sueño hiperactiva en el paladar.",
    symptoms = "Síntomas: Deseo imperioso de echarse una cabezadita en cualquier parte.",
    cure = "Cura: Una enfermera administra una elevada dosis de un poderoso estimulante.",
  },
  transparency = {
    cause = "Causa: Lamer el yogur que queda en las tapas de los envases.",
    symptoms = "Síntomas: La carne se transparenta y se ve horrible.",
    cure = "Cura: Tomar un preparado de agua enfriada y coloreada en la farmacia.",
  },
  broken_heart = {
    cause = "Causa: Alguien más rico, más joven y más delgado que el paciente.",
    symptoms = "Síntomas: Llorar y reír después de pasarse horas rompiendo fotos de las vacaciones",
    cure = "Cura: Dos cirujanos abren el pecho y miman con delicadeza el corazón mientras contienen la respiración.",
  },
  unexpected_swelling = {
    cause = "Causa: Cualquier cosa imprevista.",
    symptoms = "Síntomas: Inflamación.",
    cure = "Cura: Sólo puede reducirse la inflamación con una lanceta durante una operación que requiere dos cirujanos.",
  },
  discrete_itching = {
    cause = "Causa: Insectos diminutos con los dientes afilados.",
    symptoms = "Síntomas: Rascarse, lo que conduce a una inflamación de la parte afectada.",
    cure = "Cura: El paciente bebe un jarabe pegajoso que evita que la piel pique.",
  },
  third_degree_sideburns = {
    cause = "Causa: Anhelar con ansia los años 70.",
    symptoms = "Síntomas: Pelo largo, ropa ancha, zapatos con plataformas y mucho maquillaje.",
    cure = "Cura: El personal psiquiátrico debe, empleando técnicas actualizadas, convencer al paciente de que esta moda es horrible.",
  },
  uncommon_cold = {
    cause = "Causa: Pequeñas partículas de moco en el aire.",
    symptoms = "Síntomas: Mucosidad, estornudos y pulmones descoloridos.",
    cure = "Cura: Beber un gran trago de una medicina para la tos anormal que se fabrica en la farmacia con ingredientes especiales.",
  },
  heaped_piles = {
    cause = "Causa: Permanecer de pie junto a refrigeradores de agua.",
    symptoms = "Síntomas: El paciente se siente como si se sentara sobre una bolsa de canicas.",
    cure = "Cura: Una bebida agradable, aunque muy ácida, disuelve las hemorroides internas.",
  },
  golf_stones = {
    cause = "Causa: Inhalar el gas venenoso que contienen las pelotas de golf.",
    symptoms = "Síntomas: Delirar y sentir mucha vergüenza.",
    cure = "Cura: Dos cirujanos operan para extraer los cálculos.",
  },
  baldness = {
    cause = "Causa: Contar mentiras e inventar historias para ser famoso.",
    symptoms = "Síntomas: Tener la cabeza brillante y pasar vergüenza.",
    cure = "Cura: El pelo se cose a la cabeza del paciente con una dolorosa máquina.",
  },
  fake_blood = {
    cause = "Causa: El paciente suele ser la víctima de todas las bromas.",
    symptoms = "Síntomas: Fluido rojo en las venas que se evapora al contacto con la ropa.",
    cure = "Cura: Este problema sólo se resuelve con tratamiento psiquiátrico.",
  },
  gut_rot = {
    cause = "Causa: El jarabe para la tos, a base de whisky, de la Sra. McGuiver.",
    symptoms = "Síntomas: El paciente no tose, pero tampoco tiene paredes en el estómago.",
    cure = "Cura: Una enfermera administra una variada disolución de sustancias químicas para revestir el estómago.",
  },
  iron_lungs = {
    cause = "Causa: Contaminación urbana mezclada con restos de kebab.",
    symptoms = "Síntomas: Capacidad para aspirar fuego y gritar debajo del agua.",
    cure = "Cura: Dos cirujanos realizan una operación para eliminar las partes duras del pulmón en el quirófano.",
  },
  king_complex = {
    cause = "Causa: El espíritu del rey se introduce en la mente del paciente y se apodera de ella.",
    symptoms = "Síntomas: Calzar unos zapatos de ante teñidos y comer hamburguesas.",
    cure = "Cura: Un psiquiatra le dice al paciente lo ridículo o ridícula que está.",
  },
  tv_personalities = {
    cause = "Causa: Ver la televisión durante el día.",
    symptoms = "Síntomas: Tener la ilusión de presentar en la tele un programa de cocina.",
    cure = "Cura: Un psiquiatra experto debe convencer al paciente de que venda su televisor y se compre una radio.",
  },
}
room_descriptions = {
  staff_room = {
    [1] = "Sala de personal//",
    [2] = "Tu personal se cansa cuando realiza su trabajo. Necesitan esta sala para descansar y reponer energías. El personal cansado es más lento, pide más dinero, comete más errores y al final dimite. Merece la pena construir una sala para el personal que tenga muchos pasatiempos. Asegúrate de que hay sitio para varios miembros del personal al mismo tiempo. ",
  },
  gp = {
    [2] = "Esta es la consulta más importante de tu hospital. Los nuevos pacientes son enviados aquí para averiguar qué es lo que les pasa. Entonces, o se les hace otro diagnóstico o se les manda a una consulta donde puedan ser curados. Quizá quieras construir otra consulta si la primera tiene mucho trabajo. Cuanto más grande sea la consulta y cuantos más objetos pongas en ella, mayor prestigio tendrá el médico. Lo mismo sucede con todas las consultas abiertas.//",
  },
  blood_machine = {
    [3] = "El transfusiómetro requiere un médico. También necesita mantenimiento. ",
  },
  x_ray = {
    [2] = "Los rayos X fotografían el interior del paciente empleando una radiación especial para ayudar al personal a descubrir lo que le pasa.//",
    [3] = "La consulta de rayos X requiere un médico. También necesita mantenimiento. ",
  },
  ultrascan = {
    [1] = "Ultra escáner//",
  },
  training = {
    [1] = "Sala de formación//",
  },
  fracture_clinic = {
    [2] = "Los pacientes que tienen la desgracia de tener fracturas vienen aquí. El quitaescayolas emplea un potente láser industrial para cortar las escayolas más duras, causando al paciente sólo una pequeña molestia.//",
  },
  slack_tongue = {
    [2] = "Los pacientes a los que se les diagnostica lengua caída en la consulta serán enviados aquí para recibir tratamiento. El médico utilizará una máquina de alta tecnología para estirar la lengua y acortarla, con lo que el paciente volverá a estar sano.//",
  },
  jelly_vat = {
    [1] = "Baño gelatinoso//",
  },
  general_diag = {
    [1] = "Diagnosis general//",
  },
}

-- An override for the squits becoming the the squits see issue 1646
adviser.research.drug_improved_1 = "Tu departamento de investigación ha mejorado el medicamento para la %s."
-------------------------------  NEW STRINGS  -------------------------------
date_format = {
  daymonth = "%1% %2:months%",
}

object.litter = "Basura"
tooltip.objects.litter = "Basura: Un paciente la ha tirado porque no ha encontrado una papelera."

object.rathole = "Ratonera"
tooltip.objects.rathole = "El hogar de una familia de ratas a la que le ha gustado la suciedad de tu hospital."

tooltip.fax.close = "Cierra esta ventana sin eliminar el mensaje."
tooltip.message.button = "Haz clic izquierdo para abrir el mensaje."
tooltip.message.button_dismiss = "Haz clic izquierdo para abrir el mensaje, clic derecho para rechazarlo."
tooltip.casebook.cure_requirement.hire_staff = "Necesitas contratar empleados para realizar este tratamiento."
tooltip.casebook.cure_type.unknown = "Todavía no sabes cómo curar esta enfermedad."
tooltip.research_policy.no_research = "En este momento no se está investigando ningún apartado de esta categoría."
tooltip.research_policy.research_progress = "Progreso del siguiente descubrimiento de esta categoría: %1%/%2%"

menu["player_count"] = "CANTIDAD DE JUGADORES"

menu_file = {
  load =    " (%1%) CARGAR   ",
  save =    " (%1%) GUARDAR   ",
  restart = " (%1%) REINICIAR  ",
  quit =    " (%1%) SALIR   "
}
--These menus lack uppercase accented characters, so lowercase are a must.
menu_options = {
  sound = "  (%1%)  SONIDO  ",
  announcements = "  (%1%)  ANUNCIOS  ",
  music = "  (%1%)  MUSICA  ",
  jukebox = "  (%1%) REPRODUCTOR DE MUSICA  ",
  lock_windows = "  BLOQUEAR VENTANAS  ",
  edge_scrolling = "  DESPLAZAR POR BORDES  ",
  capture_mouse = "  CAPTURAR RATON  ",
  adviser_disabled = "  (%1%) CONSEJERO  ",
  warmth_colors = "  COLORES DE TEMPERATURA  ",
  wage_increase = "  PETICIONES DE SUELDO  ",
  twentyfour_hour_clock = "  RELOJ DE 24 HORAS  "
}

menu_options_game_speed = {
  pause               = "  (%1%) PAUSA  ",
  slowest             = "  (%1%) MUY LENTA  ",
  slower              = "  (%1%) LENTA  ",
  normal              = "  (%1%) NORMAL  ",
  max_speed           = "  (%1%) VELOCIDAD MÁXIMA  ",
  and_then_some_more  = "  (%1%) VELOCIDAD ABSURDA  ",
}

menu_options_warmth_colors = {
  choice_1 = "  ROJO  ",
  choice_2 = "  AZUL, VERDE, ROJO  ",
  choice_3 = "  AMARILLO, NARANJA, ROJO  ",
}

menu_options_wage_increase = {
  grant = "    CONCEDER  ",
  deny =  "    RECHAZAR  ",
}

-- Add F-keys to entries in charts menu (except briefing), also town_map was added.
menu_charts = {
  bank_manager    = "  (%1%) DIRECTOR DEL BANCO  ",
  statement       = "  (%1%) ESTADO DE CUENTAS  ",
  staff_listing   = "  (%1%) LISTA DE PERSONAL  ",
  town_map        = "  (%1%) MAPA DE LA CIUDAD  ",
  casebook        = "  (%1%) HISTORIAL  ",
  research        = "  (%1%) INVESTIGACION  ",
  status          = "  (%1%) ESTADO  ",
  graphs          = "  (%1%) GRAFICAS  ",
  policy          = "  (%1%) NORMAS  ",
  machine_menu    = "  (%1%) MENU DE MAQUINAS",
  adviser_history = "  (%1%) HISTORIAL DEL CONSEJERO  ",
}

menu_debug = {
  jump_to_level               = "  CAMBIAR DE NIVEL  ",
  connect_debugger            = "  (%1%) CONECTAR A SERVIDOR DBGp LUA  ",
  transparent_walls           = "  (%1%) PAREDES TRANSPARENTES  ",
  limit_camera                = "  LIMITAR CAMARA  ",
  disable_salary_raise        = "  DESACTIVAR SUBIDA DE SUELDO  ",
  allow_blocking_off_areas    = "  PERMITIR BLOQUEAR AREAS  ",
  allow_falling               = "  PERMITIR CAIDAS  ",
  make_debug_fax              = "  CREAR FAX DE DEPURACION  ",
  make_debug_patient          = "  CREAR PACIENTE DE DEPURACION  ",
  cheats                      = "  (%1%) TRUCOS  ",
  lua_console                 = "  (%1%) CONSOLA LUA  ",
  debug_script                = "  (%1%) EJECUTAR SCRIPT DE DEPURACION  ",
  calls_dispatcher            = "  LLAMAR A CONTROLADOR  ",
  dump_strings                = "  (%1%) VOLCAR TEXTOS DEL JUEGO  ",
  dump_gamelog                = "  (%1%) VOLCAR REGISTRO DEL JUEGO  ",
  map_overlay                 = "  SOBREPONER MAPA  ",
  sprite_viewer               = "  VISUALIZADOR DE ANIMACIONES  ",
}
menu_debug_overlay_blocking_off_areas = {
  choice_1 = "  TOTALMENTE PROHIBIDO  ",
  choice_2 = "  PARCIALMENTE PERMITIDO  ",
  choice_3 = "  COMPLETAMENTE PERMITIDO  ",
}
menu_debug_overlay = {
  none                        = "  NADA  ",
  flags                       = "  MARCAS  ",
  positions                   = "  POSICIONES  ",
  heat                        = "  TEMPERATURA  ",
  byte_0_1                    = "  BYTE 0 Y 1  ",
  byte_floor                  = "  BYTE SUELO  ",
  byte_n_wall                 = "  BYTE PARED NORTE  ",
  byte_w_wall                 = "  BYTE PARED OESTE  ",
  byte_5                      = "  BYTE 5  ",
  byte_6                      = "  BYTE 6  ",
  byte_7                      = "  BYTE 7  ",
  parcel                      = "  PARCELA  ",
}
menu_player_count = {
  players_1 = "  1 JUGADOR  ",
  players_2 = "  2 JUGADORES  ",
  players_3 = "  3 JUGADORES  ",
  players_4 = "  4 JUGADORES  ",
}


tooltip.toolbar = {
  reputation = "Tu reputación",
  edit = "Editar consultas-objetos (%s)",
  bank_button = "Pulsa el botón izquierdo (%s) para el director del banco y el derecho (%s) par el saldo bancario",
  objects = "Coloca objetos del pasillo (%s)",
  date = "La fecha",
  staff_list = "Dirección de personal (%s)",
  hire = "Contrata personal (%s)",
  town_map = "Mapa de la ciudad (%s)",
  charts = "Gráficas (%s)",
  research = "Investigación (%s)",
  policy = "Normas (%s)",
  casebook = "Botiquín (%s)",
  status = "Condición (%s)",
  rooms = "Construye consultas (%s)",
  balance = "Tu saldo",
  machine_menu = "Menú de máquina (%s)",
}

adviser = {
  room_forbidden_non_reachable_parts = "Si colocas la habitación ahí bloquearás el acceso a ciertas partes del hospital.",
  warnings = {
    no_desk = "¡Deberías construir una mesa de recepción y contratar a una recepcionista en algún momento!",
    no_desk_1 = "¡Si quieres que los pacientes vayan a tu hospital, necesitas contratar a una recepcionista y construir una mesa donde pueda trabajar!",
    no_desk_2 = "¡Enhorabuena, has batido un récord mundial: ha pasado un año y no ha aparecido ni un paciente! ¡Si quieres seguir mandando en este hospital, tendrás que contratar a una recepcionista y construir una mesa donde pueda trabajar!",
    no_desk_3 = "¡Fabuloso, casi ha pasado un año y no tienes recepcionistas! ¿Cómo quieres que vengan los pacientes? ¡Arréglalo y deja de perder el tiempo!",
    no_desk_4 = "Una recepcionista necesita una mesa para atender a los pacientes que vengan.",
    no_desk_5 = "¡Ya era hora! Los pacientes empezarán a llegar pronto.",
    no_desk_6 = "Tienes una recepcionista, ¿qué tal si construyes una mesa de recepción para que pueda trabajar?",
    no_desk_7 = "Has construido una mesa de recepción, ¿y si contratas a una recepcionista? No verás a ningún paciente hasta que lo arregles, ¿lo sabes, no?",
  another_desk = "Necesitarás construir otro escritorio para la nueva recepcionista.",
  cannot_buy = "¡No puedes comprar más de ese objeto!",
    cannot_afford = "¡No tienes dinero para contratar a esa persona!", -- I can't see anything like this in the original strings
    cannot_afford_2 = "¡No tienes dinero para comprar eso!",
    cannot_afford_machine = "Necesitas al menos $%1% en el banco para poder adquirir un nuevo %2%!",
    falling_1 = "¡Eh! No tiene gracia. Mira dónde haces clic con ese ratón, ¡vas a hacer daño a alguien!",
    falling_2 = "¿Te importaría dejar de perder el tiempo?",
    falling_3 = "¡Ay! Eso ha tenido que doler. ¡Llamen a un médico!",
    falling_4 = "¡Esto es un hospital, no un parque de atracciones!",
    falling_5 = "¡Este no es lugar para tirar personas al suelo, que están enfermas!",
    falling_6 = "¡Esto no es una bolera, no trates así a los enfermos!",
    research_screen_open_1 = "Para acceder a la pantalla de investigación, tienes que construir un departamento de investigación.",
    research_screen_open_2 = "No se pueden realizar investigaciones en este nivel.",
    researcher_needs_desk_1 = "Un investigador necesita una mesa en la que trabajar.",
    researcher_needs_desk_2 = "Tu investigador agradece que le hayas dado un descanso. Si pretendías tener a más personas investigando, tienes que dar a cada uno una mesa para que trabajen.",
    researcher_needs_desk_3 = "Cada investigador necesita una mesa para trabajar.",
    nurse_needs_desk_1 = "Cada enfermera necesita una mesa para trabajar.",
    nurse_needs_desk_2 = "Tu enfermera agradece que le hayas dado un descanso. Si pretendías tener a más personas trabajando en la enfermería, tienes que dar a cada una una mesa para que trabajen.",
    low_prices = "Estás cobrando muy poco por %s. Así atraerás a más personas a tu hospital, pero no te darán muchos beneficios.",
    high_prices = "Estás cobrando mucho por %s. Esto traerá muchos beneficios a corto plazo, pero harás que los pacientes dejen de venir.",
    fair_prices = "El precio de %s parece justo.",
    patient_not_paying = "¡Un paciente se ha ido sin pagar por %s porque es demasiado caro!",
    no_doctor_no_gp_office = "Deberias construir una Consulta y contratar un doctor en algun momento!",
    no_gp_office = "No has construido una Consulta donde tus doctores puedan diagnosticar a los pacientes!",
    money_low = "Te estás quedando sin dinero.",
  },
  cheats = {
    th_cheat = "¡Felicidades, has desbloqueado los trucos!",
    roujin_on_cheat = "¡Desafío de Roujin activado! Buena suerte en los próximos meses...",
    roujin_off_cheat = "Desafío de Roujin desactivado. Todo volverá a la normalidad pronto.",
    norest_on_cheat = "Vaya! Parece que el personal consumió demasiada cafeína y ya no necesitan descansar.",
    norest_off_cheat = "Uf! Parece que el subidón se acabó. Tu personal ahora podrá descansar apropiadamente.",
    queuejump_on_cheat = "Tus pacientes saben hacer cola. Dejan que los pacientes moribundos pasen al principio de la fila.",
    queuejump_off_cheat = "La gente se ha vuelto egoísta y ya no deja que los pacientes moribundos se salten la cola.",
    superdoctor_on_cheat = "¡Una excelente facultad de medicina te ha recomendado a sus graduados! Revisa el personal disponible para contratar.",
    superdoctor_off_cheat = "El director de la facultad de medicina ya no te recomienda a sus graduados.",
  },
  staff_place_advice = {
    not_enough_lecture_chairs = "Cada estudiante necesita una silla donde sentarse!",
  },
}

dynamic_info.patient.actions.no_gp_available = "Esperando a que construyas una consulta"
dynamic_info.staff.actions.heading_for = "Dirigiéndose a %s"
dynamic_info.staff.actions.fired = "Despedido"
dynamic_info.staff.actions.vaccine = "Vacunando a un paciente"
dynamic_info.patient.actions.epidemic_vaccinated = "Ya no soy contagioso"
dynamic_info.object.strength_extra_info = "Resistencia %d (Mejorable a %d)"

progress_report.free_build = "CONSTRUCCIÓN LIBRE"

fax = {
  choices = {
    return_to_main_menu = "Volver al menú principal",
    accept_new_level = "Continuar al siguiente nivel",
    decline_new_level = "Seguir jugando un poco más",
  },
  emergency = {
    num_disease_singular = "Hay 1 persona con %s y necesita ser atendida inmediatamente.",
    free_build = "Si tienes éxito, mejorarás tu reputación, pero si fracasas tu reputación caerá en picado.",
  },
  vip_visit_result = {
    remarks = {
      free_build = {
        "¡Su hospital es muy bueno! No es difícil mantenerlo sin limitaciones económicas, ¿eh?",
        "No soy economista, pero hasta yo podría dirigir este hospital, si usted me entiende...",
        "Un hospital muy bien cuidado. ¡Pero ojo con la crisis financiera! Ah... que a usted no le afecta.",
      },
    }
  }
}

letter = {
  dear_player = "Estimado %s,",
  custom_level_completed = "¡Bien hecho! ¡Has completado todos los objetivos de este nivel personalizado!",
  return_to_main_menu = "¿Quieres volver al menú principal o seguir jugando?",
  campaign_level_completed = "¡Buen trabajo! Has superado este nivel, ¡pero aún no has acabado!\n ¿Te interesaría aceptar un puesto en el hospital %s?",
  campaign_completed = "¡Increíble! Has conseguido superar todos los niveles. Ya puedes relajarte y disfrutar mientras hablas de tus logros en los foros de Internet. ¡Buena suerte!",
  campaign_level_missing = "Parece que el siguiente nivel de esta campaña está desaparecido. (Nombre: %s)",
}

install = {
  title = "--------------------------------- Configuración de CorsixTH ---------------------------------",
  th_directory = "CorsixTH necesita una copia de los archivos de datos del Theme Hospital original (o de la demo) para poder funcionar. Utiliza el selector de debajo para localizar la carpeta de instalación de Theme Hospital.",
  ok = "Aceptar",
  exit = "Salir",
  cancel = "Cancelar",
}

misc = {
  not_yet_implemented = "(aún no implementado)",
  no_heliport = "O no se han descubierto enfermedades, o no hay un helipuerto en este nivel.  Quizás te haga falta comprar una mesa de recepción y contratar a una recepcionista.",
  cant_treat_emergency = "Tu hospital no puede tratar esta emergencia debido a que la enfermedad no ha sido descubierta. Inténtalo de nuevo.",
  epidemics_off = "Las epidemias se han deshabilitado. No se crearán nuevas epidemias",
  epidemics_on = "Las epidemias han sido habilitadas nuevamente",
  earthquakes_off = "Los terremotos se han deshabilitado",
  earthquakes_on = "Los terremotos han sido habilitados nuevamente",
  epidemic_no_icon_to_toggle = "No es posible mostrar/ocultar iconos de infección - no hay epidemias en progreso que no hayan sido reveladas",
  epidemic_no_diseases = "No es posible crear una epidemia - no hay enfermedades contagiosas disponibles",
  epidemic_no_receptionist = "No es posible crear una epidemia - no hay una recepcion que cuente con personal",
  invulnerable_machines_off = "Las máquinas volverán a estropearse y romperse.",
  invulnerable_machines_on = "Las máquinas ya no se estropearán ni romperán.",
}

main_menu = {
  new_game = "Campaña",
  custom_campaign = "Campaña personalizada",
  custom_level = "Misión individual",
  continue = "Continuar partida",
  load_game = "Cargar partida",
  options = "Opciones",
  map_edit = "Editor de mapas",
  savegame_version = "Versión del guardado: ",
  updates_off = "No se buscarán actualizaciones",
  version = "Versión: ",
  exit = "Salir",
}

tooltip.main_menu = {
  new_game = "Empezar el primer nivel de la campaña.",
  custom_campaign = "Juega una campaña creada por la comunidad.",
  custom_level = "Construir tu hospital en un nivel concreto.",
  continue = "Reanuda tu última partida guardada.",
  load_game = "Cargar una partida guardada.",
  options = "Ajustar la configuración.",
  map_edit = "Crear un mapa personalizado.",
  exit = "¡No, no, por favor, no te vayas!",
  quit = "Estás a punto de salir de CorsixTH.   ¿Seguro que quieres continuar?",
}

load_game_window = {
  caption = "Cargar partida (%1%)",
  load_button = "Cargar",
}

tooltip.load_game_window = {
  load_game = "Cargar partida %s",
  load_game_number = "Cargar partida %d",
  load_autosave = "Cargar autoguardado",
}

custom_game_window = {
  caption = "Partida personalizada",
  free_build = "Construcción libre",
  load_selected_level = "Comenzar",
}

tooltip.custom_game_window = {
  choose_game = "Haz clic en un nivel para ver más información sobre el mismo.",
  free_build = "Marca esta casilla si quieres jugar sin dinero ni condiciones para ganar o perder.",
  load_selected_level = "Cargar e iniciar el nivel seleccionado.",
}

custom_campaign_window = {
  caption = "Campaña personalizada",
  start_selected_campaign = "Comenzar campaña",
  duplicates_warning = "Se han ocultado %d campañas con nombres duplicados",
}

tooltip.custom_campaign_window = {
  choose_campaign = "Selecciona una campaña para ver más información sobre la misma.",
  start_selected_campaign = "Cargar el primer nivel de esta campaña.",
  duplicates_warning = "Verifica la consola para ver errores especificos",
}

save_game_window = {
  caption = "Guardar partida (%1%)",
  new_save_game = "Nueva partida guardada",
  save_button = "Guardar",
  missing_filename = "Por favor ingresa el nombre de la partida que deseas guardar o selecciona una existente para sobreescribirla.",
}

tooltip.save_game_window = {
  save_game = "Sobrescribir partida guardada %s",
  new_save_game = "Introduce el nombre de la partida guardada.",
}

save_map_window = {
  caption = "Guardar mapa (%1%)",
  new_map = "Nuevo mapa",
  save_button = "Guardar",
  missing_filename = "Por favor ingresa el nombre del nuevo archivo de mapa o selecciona uno existente para sobreescribirlo.",
}

tooltip.save_map_window = {
  map = "Sobrescribir el mapa %s.",
  new_map = "Introduce el nombre del mapa guardado.",
}

load_map_window = {
  caption = "Cargar Mapa (%1%)",
  load_button = "Cargar",
}

menu_list_window = {
  name = "Nombre",
  save_date = "Modificado",
  ok = "OK",
  back = "Atrás",
}

tooltip.menu_list_window = {
  name = "Pulsa aquí para ordenar la lista por nombres.",
  save_date = "Pulsa aquí para ordenar la lista por la última fecha de modificación.",
  ok = "Confirmar elección",
  back = "Cerrar esta ventana.",
}

options_window = {
  caption = "Opciones",
  option_on = "Sí",
  option_off = "No",
  option_enabled = "Activado",
  option_disabled = "Desactivado",
  capture_mouse = "Capturar Ratón",
  right_mouse_scrolling = "Desplazamiento con el Ratón",
  right_mouse_scrolling_option_middle = "Botón Central",
  right_mouse_scrolling_option_right = "Botón Derecho",
  customise = "Personalizar",
  folder = "Carpetas",
  language = "Idioma del juego",
  back = "Atrás",
  scroll_speed = "Vel. de Desplazamiento",
  shift_scroll_speed = "Vel. de Despl. (Shift)",
  zoom_speed = "Vel. de Acercamiento",
  autosave_frequency = "Frecuencia de autoguardado",
  hotkey = "Atajos de Teclado",
  check_for_updates = "Buscar Actualizaciones",
  sound = "Sonido",
}
graphics_window = {
  fullscreen = "Pantalla Completa",
  ui_scale = "Escala de interfaz",
  width = "Ancho",
  height = "Alto",
  option_on = "Sí",
  option_off = "No",
  apply = "Aplicar",
  cancel = "Cancelar",
}

autosave_frequency = {
    monthly = "Mensual",
    weekly = "Semanal",
    daily = "Diario",
}

tooltip.autosave_frequency = {
    monthly = "Guarda automáticamente una vez al mes, el primer día de cada mes. Un total de 12 partidas guardadas con un historial de 1 año.",
    weekly = "Guarda automáticamente una vez a la semana, los días 1, 7, 14, 21 y 28 de cada mes. Un total de 60 partidas guardadas con un historial de 1 año.",
    daily = "Guarda automáticamente una vez al día al comienzo de cada día del juego. Un total de 365 partidas guardadas con un historial de 1 año. Ten en cuenta que un guardado típico puede ocupar hasta 1 megabyte o incluso más. De esta forma, tu carpeta de autoguardados puede llegar a ocupar entre 300 y 500 MB.",
}

tooltip.options_window = {
    ui_scale_unavailable = "Escala de interfaz no disponible; por favor, selecciona primero una resolución más alta.",
    capture_mouse = "Haz clic para activar o desactivar la captura del cursor durante el juego",
    right_mouse_scrolling = "Cambia el botón del ratón que se utiliza para desplazarse por el mapa",
    customise = "Más ajustes que puedes cambiar para personalizar tu experiencia de juego",
    folder = "Opciones de carpetas",
    language = "El idioma en el que aparecerán los textos del juego",
    select_language = "Selecciona el idioma del juego",
    language_dropdown_item = "Elegir %s como idioma",
    language_dropdown_no_font = "Selecciona una fuente en la configuración de carpetas para habilitar este idioma",
    back = "Cierra la ventana de opciones",
    autosave_frequency = "Establece la frecuencia con la que el juego realizará autoguardados.",
    hotkey = "Cambia las teclas de acceso rápido del teclado.",
    check_for_updates = "Establece si el juego debe buscar actualizaciones al iniciar.",
    sound = "Cambia la configuración de audio",
}
tooltip.graphics_window = {
  fullscreen = "Si el juego debe ejecutarse en pantalla completa o en modo ventana",
  fullscreen_button = "Haz clic para activar o desactivar el modo de pantalla completa",
  ui_scale = "Escala la interfaz de usuario. Solo se muestran las opciones de escala que se ajustan a la pantalla; para ver más, aumenta la resolución.",
  select_ui_scale = "Selecciona una nueva escala para la interfaz de usuario",
  width = "Introduce el ancho de pantalla deseado",
  height = "Introduce la altura de pantalla deseada",
  apply = "Aplica la resolución ingresada",
  cancel = "Vuelve sin cambiar la resolución",
}

audio_window = {
  caption = "Ajustes de sonido",
    audio = "Audio global",
    sound_volume = "Volumen de sonido",
    announcement_volume = "Volumen de anuncios",
    music_volume = "Volumen de música",
    midi_api = "API MIDI",
    midi_port = "Puerto MIDI",
    soundfont = "SoundFont",
    default_midi_api = "Predeterminado (Software)",
    default_midi_port = "Predeterminado",
    jukebox = "Reproductor",
    back = "Atrás",
    soundfont_location_caption = "Elegir SoundFont (%1%)",
}

tooltip.audio_window = {
    audio_button = "Activa o desactiva todo el audio del juego",
    audio_toggle = "Activa o desactiva",
    sound_volume = "Volumen del sonido",
    announcement_volume = "Volumen de los anuncios",
    music_volume = "Volumen de la música",
    midi_api = "La API que se utilizará para la música del juego. No se utiliza con la carpeta de música personalizada.",
    midi_port = "Puerto del dispositivo a utilizar para la música del juego.",
    soundfont_location = "Ubicación del archivo SoundFont para reproducir música MIDI. Se utiliza un SoundFont predeterminado si no se especifica ninguno.",
    browse = "Buscar ubicación de la carpeta",
    browse_soundfont = "Buscar otro archivo SoundFont (sf2 o sf3) ( Ubicación actual: %1% ) ",
    no_soundfont_specified = "Usando SoundFont predeterminado",
    jukebox = "Abre el Reproductor para controlar la música",
    back = "Cierra la ventana",
}

customise_window = {
  caption = "Opciones personalizadas",
  option_on = "Activado",
  option_off = "Desactivado",
  emergency_only = "Solo emergencias",
  regular_patients = "Pacientes habituales",
  male_only = "Solo hombres",
  male_and_female = "Hombres y mujeres",
  back = "Atrás",
  option_enabled = "Activado",
  option_disabled = "Desactivado",
  back = "Atrás",
  movies = "Control de vídeos",
  play_intro = "Mostrar introducción",
  allow_user_actions_while_paused = "Construir en pausa",
  alien_dna_only_by_emergency = "Pacientes alienígenas",
  disable_fractured_bones_females = "Fracturas óseas",
  enable_avg_contents = "Contenidos habituales",
  remove_destroyed_rooms = "Eliminar habitaciones destruidas",
  machine_menu_button = "Botón del menú de máquinas",
}

tooltip.customise_window = {
  movies = "Control global de videos, permite desactivar todos los videos.",
  play_intro = "Activa o desactiva el video de introducción. Necesitas activar el control global de videos si quieres ver la introducción cada vez que inicies CorsixTH.",
  allow_user_actions_while_paused = "En Theme Hospital el jugador solo podía utilizar el menú superior si la partida estaba en pausa. CorsixTH funciona así de forma predeterminada, pero al activar esta opción se puede realizar cualquier acción mientras el juego esté en pausa.",
  alien_dna_only_by_emergency = "Debido a la falta de animaciones decentes disponibles, hemos hecho que los pacientes con ADN alienígena solo aparezcan en una emergencia. Para permitir que los pacientes con ADN alienígena puedan visitar tu hospital, desactiva esta opción.",
  disable_fractured_bones_females = "Debido a una animación deficiente, hemos hecho que no existan pacientes con Fracturas óseas femeninas. Para permitir que las pacientes con Fracturas óseas visiten tu hospital, desactiva esta opción.",
  enable_avg_contents = "Activa esta opción si quieres que el juego recuerde los objetos adicionales que sueles añadir cuando construyes habitaciones.",
  remove_destroyed_rooms = "Activa esta opcion si te gustaría poder eliminar habitaciones destruidas (por un precio)",
  machine_menu_button = "Si quieres tener un botón para abrir el menú de máquinas en el panel inferior, activa esta opción. Ten en cuenta que este botón no estará visible si la resolución de pantalla es pequeña.",
  back = "Cerrar este menú y volver al menú de opciones.",
}

folders_window = {
  caption = "Ubicación de carpetas",
  data_label = "Datos de TH",
  font_label = "Fuente",
  music_label = "MP3",
  savegames_label = "Part. guardadas",
  screenshots_label = "Capt. de pantalla",
  -- next four are the captions for the browser window, which are called from the folder setting menu
  new_th_location = "Aquí puedes especificar una nueva carpeta de instalación de Theme Hospital. El juego se reiniciará en cuanto selecciones la nueva carpeta.",
  savegames_location = "Selecciona la carpeta que quieres utilizar para tus partidas guardadas.",
  music_location = "Selecciona la carpeta que quieres utilizar para tu música.",
  screenshots_location = "Selecciona la carpeta que quieres utilizar para tus capturas de pantalla.",
  back  = "Atrás",
}

tooltip.folders_window = {
  browse = "Buscar la ubicación de la carpeta",
  data_location = "La carpeta con la instalación del Theme Hospital original, necesario para ejecutar CorsixTH.",
  font_location = "La ubicación de una fuente de letra capaz de mostrar caracteres Unicode necesarios para tu idioma. Si no se indica, no podrás seleccionar idiomas que tengan más caracteres de los que puede dar el juego original, por ejemplo, ruso y chino.",
  savegames_location = "La carpeta de partidas guardadas se ubica de forma predeterminada junto al archivo de configuración y se utilizará para almacenar las partidas guardadas. Si no te gusta, puedes seleccionar otra buscando la carpeta que quieres usar.",
  screenshots_location = "Las capturas de pantalla se guardan de forma predeterminada en una carpeta junto al archivo de configuración. Si no te gusta, puedes seleccionar otra buscando la carpeta que quieres usar.",
  music_location = "Selecciona una carpeta con tus archivos de música en formato MP3. Necesitas una carpeta ya existente, entonces podrás buscarla.",
  browse_data = "Buscar otra ubicación con una instalación de Theme Hospital. (Ubicación actual: %1%)",
  browse_font = "Buscar otro archivo de fuente de letra. (Ubicación actual: %1%)",
  browse_saves = "Buscar otra ubicación para tu carpeta de partidas guardadas. (Ubicación actual: %1%)",
  browse_screenshots = "Buscar otra ubicación para tu carpeta de capturas de pantalla. (Ubicación actual: %1%)",
  browse_music = "Buscar otra ubicación para tu carpeta de música. (Ubicación actual: %1%)",
  no_font_specified = "¡No se ha especificado una carpeta de fuentes!",
  not_specified = "¡No se ha especificado una carpeta!",
  default = "Ubicación predeterminada",
  reset_to_default = "Vuelve a asignar la carpeta a su ubicación predeterminada ( %1% )",
  clear_directory = "Borrar la selección de directorio actual",
  back  = "Cerrar este menú y volver al menú de Opciones.",
}

accessibility_window = {
  enable_screen_shake = "Temblor de pantalla",
  enable_announcer_subtitles = "Subtítulos de megafonía",
  scrollspeed = "Vel. de Desplazamiento",
  shift_scrollspeed = "Vel. de Despl. (Shift)",
  zoom_speed = "Vel. de Acercamiento",
}

tooltip.accessibility_window = {
  enable_screen_shake = "Los terremotos harán que toda la pantalla tiemble. Desactiva esta opción si prefieres que la pantalla permanezca inmóvil.",
  enable_announcer_subtitles = "Activa esta opción si deseas que el juego muestre subtítulos para los anuncios de tu hospital.",
  scrollspeed = "Establece la velocidad de desplazamiento de 1 (más lenta) a 10 (más rápida). El valor por defecto es 2.",
  shift_scrollspeed = "Establece la velocidad de desplazamiento (cuando la tecla Shift se encuentra presionada) de 1 (más lenta) a 10 (más rápida). El valor por defecto es 4.",
  zoom_speed = "Establece la velocidad de acercamiento de la cámara de 10 (más lenta) a 1000 (más rápida). El valor por defecto 80.",
  apply_scrollspeed = "Aplica la velocidad de desplazamiento ingresada.",
  cancel_scrollspeed = "Vuelve sin cambiar la velocidad de acercamiento.",
  apply_shift_scrollspeed = "Aplica la velocidad de desplazamiento (tecla Shift) ingresada.",
  cancel_shift_scrollspeed = "Vuelve sin cambiar la velocidad de desplazamiento (tecla Shift).",
  apply_zoomspeed = "Aplica la velocidad de acercamiento ingresada.",
  cancel_zoomspeed = "Vuelve sin cambiar la velocidad de acercamiento.",
}

hotkey_window = {
  caption_main = "Teclas de Acceso Rápido",
  caption_panels = "Teclas de Paneles",
  button_accept = "Aceptar",
  button_defaults = "Reestablecer Valores",
  button_cancel = "Cancelar",
  button_back = "Atrás",
  button_toggleKeys = "Teclas para Activar Opciones",
  button_gameSpeedKeys = "Teclas de Velocidad del Juego",
  button_recallPosKeys = "Teclas de Posiciones de Cámara",
  panel_globalKeys = "Teclas Globales",
  panel_generalInGameKeys = "Teclas Generales del Juego",
  panel_scrollKeys = "Teclas de Desplazamiento",
  panel_zoomKeys = "Teclas de Acercamiento",
  panel_gameSpeedKeys = "Teclas de Velocidad del Juego",
  panel_toggleKeys = "Teclas para Activar Opciones",
  panel_debugKeys = "Teclas de Depuración",
  panel_storePosKeys = "Teclas para Almacenar Pos.",
  panel_recallPosKeys = "Teclas para Recuperar Pos.",
  panel_altPanelKeys = "Teclas de Panel Alternativas",
  global_confirm = "Confirmar",
  global_confirm_alt = "Confirmar (alternativa)",
  global_cancel = "Cancelar",
  global_cancel_alt = "Cancelar (alternativa)",
  global_fullscreen_toggle = "Pantalla Completa",
  global_exitApp = "Salir de la Aplicación",
  global_resetApp = "Reiniciar Aplicación",
  global_releaseMouse = "Soltar Ratón",
  global_connectDebugger = "Depurador",
  global_showLuaConsole = "Consola de Lua",
  global_runDebugScript = "Ejecutar Script de Depuración",
  global_screenshot = "Captura de Pantalla",
  global_stop_movie_alt = "Detener Video",
  global_window_close_alt = "Cerrar Ventana",
  ingame_scroll_up = "Desplazar Hacia Arriba",
  ingame_scroll_down = "Desplazar Hacia Abajo",
  ingame_scroll_left = "Desplazar Hacia la Izquierda",
  ingame_scroll_right = "Desplazar Hacia la Derecha",
  ingame_scroll_shift = "Acelerar Desplazamiento",
  ingame_zoom_in = "Acercar",
  ingame_zoom_in_more = "Acercar Más",
  ingame_zoom_out = "Alejar",
  ingame_zoom_out_more = "Alejar Más",
  ingame_reset_zoom = "Reiniciar Acercamiento",
  ingame_showmenubar = "Mostrar Barra de Menues",
  ingame_showCheatWindow = "Menu de Trampas",
  ingame_loadMenu = "Cargar Partida",
  ingame_saveMenu = "Guardar Partida",
  ingame_jukebox = "Reproductor de Música",
  ingame_openFirstMessage = "Mostrar Introducción",
  ingame_pause = "Pausar",
  ingame_gamespeed_slowest = "Más Lenta",
  ingame_gamespeed_slower = "Lenta",
  ingame_gamespeed_normal = "Normal",
  ingame_gamespeed_max = "Máxima",
  ingame_gamespeed_thensome = "Absurda",
  ingame_gamespeed_speedup = "Acelerar",
  ingame_panel_bankManager = "Director del Banco",
  ingame_panel_bankStats = "Estado de Cuentas",
  ingame_panel_staffManage = "Administrar Personal",
  ingame_panel_townMap = "Mapa de la Ciudad",
  ingame_panel_casebook = "Historial",
  ingame_panel_research = "Investigación",
  ingame_panel_status = "Estado",
  ingame_panel_charts = "Charts",
  ingame_panel_policy = "Normas",
  ingame_panel_machineMenu = "Menu de Máquinas",
  ingame_panel_adviserHistory = "Historial del Consejero",
  ingame_panel_map_alt = "Mapa de la Ciudad 2",
  ingame_panel_research_alt = "Investigación 2",
  ingame_panel_casebook_alt = "Historial 2",
  ingame_panel_casebook_alt02 = "Historial 3",
  ingame_panel_buildRoom = "Construir Habitación",
  ingame_panel_furnishCorridor = "Amoblar Corredor",
  ingame_panel_editRoom = "Editar Habitación",
  ingame_panel_hireStaff = "Contratar Personal",
  ingame_rotateobject = "Rotar Objeto",
  ingame_quickSave = "Guardado Rápido",
  ingame_quickLoad = "Carga Rápida",
  ingame_restartLevel = "Reiniciar Nivel",
  ingame_quitLevel = "Salir del Nivel",
  ingame_setTransparent = "Transparente",
  ingame_toggleTransparent = "Activar Transparencias",
  ingame_toggleAnnouncements = "Activar Anuncios",
  ingame_toggleSounds = "Activar Sonidos",
  ingame_toggleMusic = "Activar Música",
  ingame_toggleAdvisor = "Activar Consejero",
  ingame_toggleInfo = "Activar Información",
  ingame_poopLog = "Volcar registro del juego",
  ingame_poopStrings = "Volcar textos del juego",
  ingame_patient_gohome = "Enviar a casa",
  ingame_sellPickedUpItem = "Vender objeto recogido",
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
 button_accept = "Aceptar y guardar las teclas de acceso rápido asignadas",
  button_defaults = "Restablecer todas las teclas de acceso rápido a los valores por defecto",
  button_cancel = "Cancelar la asignación y volver al menú de opciones",
  panel_globalKeys = "Asignar teclas de acceso rápido globales",
  panel_generalInGameKeys = "Asignar teclas de acceso rápido generales dentro del juego",
  button_gameSpeedKeys = "Asignar teclas de acceso rápido para controlar la velocidad del juego",
  panel_scrollKeys = "Asignar teclas de acceso rápido para desplazar la pantalla",
  panel_zoomKeys = "Asignar teclas de acceso rápido para acercar y alejar la vista",
  panel_toggleKeys = "Asignar teclas de acceso rápido para activar o desactivar opciones",
  caption_panels = "Asignar teclas de acceso rápido para abrir paneles",
  button_recallPosKeys = "Asignar teclas de acceso rápido para guardar y recuperar posiciones de la cámara",
  panel_debugKeys = "Asignar teclas de acceso rápido para depuración",
  button_back_02 = "Volver a la ventana principal de teclas de acceso rápido. Las teclas modificadas en esta ventana se pueden aceptar allí",
}

font_location_window = {
  caption = "Seleccionar fuente (%1%)",
}

handyman_window = {
  all_parcels = "Todas las parcelas",
  parcel = "Parcela"
}

tooltip.handyman_window = {
  parcel_select = "Parcela donde el bedel acepta encargos, haz clic para cambiar el ajuste"
}

new_game_window = {
  caption = "Campaña",
  player_name = "Nombre",
  option_on = "Activado",
  option_off = "Desactivado",
  difficulty = "Dificultad",
  easy = "Novato (Fácil)",
  medium = "Médico (Normal)",
  hard = "Especialista (Difícil)",
  tutorial = "Tutorial",
  start = "Comenzar",
  cancel = "Cancelar",
}

tooltip.new_game_window = {
  player_name = "Introduce el nombre que usará el juego para dirigirse a ti.",
  difficulty = "Selecciona el nivel de dificultad con el que quieres jugar.",
  easy = "Si acabas de conocer los juegos de simulación, esta dificultad es para ti.",
  medium = "Esta es la dificultad intermedia, si no estás seguro de a dónde quieres ir.",
  hard = "Si ya estás acostumbrado a este tipo de juegos y quieres un buen desafío, aquí lo tendrás.",
  tutorial = "Selecciona esta casilla si necesitas ayuda para empezar a jugar.",
  start = "Empezar la partida con la configuración seleccionada.",
  cancel = "¡Perdón, yo no quería empezar una nueva partida!",
}

lua_console = {
  execute_code = "Ejecutar",
  close = "Cerrar",
}

tooltip.lua_console = {
  textbox = "Introduce aquí el código Lua que quieres ejecutar",
  execute_code = "Ejecutar el código Lua que has introducido",
  close = "Cerrar la consola",
}

errors = {
  dialog_missing_graphics = "Los archivos de datos de la demo no contienen esta ventana.",
  save_prefix = "Error al guardar la partida: ",
  load_prefix = "Error al cargar la partida: ",
  load_map_prefix = "Error al cargar el mapa: ",
  load_level_prefix = "Error al cargar el nivel: ",
  no_games_to_contine = "No hay partidas guardadas.",
  load_quick_save = "Error, no existe el guardado rápido y por tanto no se puede cargar, pero tranquilo, que acabamos de generar uno para ti.",
  map_file_missing = "¡No se ha podido encontrar el archivo de mapa %s de este nivel!",
  minimum_screen_size = "Introduce un tamaño de pantalla como mínimo de %dx%d.",
  unavailable_screen_size = "El tamaño de pantalla que has seleccionado no está disponible en el modo de pantalla completa.",
  alien_dna_only_by_emergency = "NOTA: Los pacientes alienígenas no tienen animaciones para sentarse, abrir puertas, llamar a puertas, etc. Por lo tanto, al igual que en Theme Hospital, para hacer estas cosas aparentarán cambiar a una imagen normal y luego volverán a su estado.  Los pacientes con ADN alienígena solo aparecerán si el archivo del nivel lo indica.",
  disable_fractured_bones_females = "NOTA: La animación de las pacientes femeninas con Fracturas óseas no es perfecta.",
  could_not_load_campaign = "Error al cargar la campaña %s.",
  could_not_find_first_campaign_level = "No se ha encontrado el primer nivel de la campaña %s.",
  save_to_tmp = "El archivo en %s no pudo ser utilizado. El juego ha sido guardado en %s. Error: %s",
  dialog_empty_queue = "Lo siento, un humanoide tenía una cola de acciones vacía, lo que significa que no sabía que hacer. Por favor consulta la ventana de comandos para obtener información más detallada. Se ha abierto un dialogo con el humanoide que causó el problema. ¿Te gustaría que abandone el hospital?",
  compatibility_error = {
    new_in_old = "Lo siento, esta partida guardada fue creada con una version más nueva de CorsixTH y no es compatible. Por favor actualiza a una versión más reciente.",
    demo_in_full = "Lo siento, no puedes abrir una partida guardada de la demo cuando los archivos del juego completo se encuentran cargados. Por favor actualiza la configuracion referente a tu carpeta de datos de Theme Hospital.",
    full_in_demo = "Lo siento, no puedes abrir una partida guardada del juego completo cuando los archivos de la demo se encuentran cargados. Por favor actualiza la configuracion referente a tu carpeta de datos de Theme Hospital.",
  },
  music = "Hay problemas al intentar reproducir uno o más archivos en tu directorio de música. Los archivos problemáticos serán deshabilitados en el reproductor. Verifica la consola para obtener mas información.",
  missing_corsixth_file = "Advertencia: No se pudo encontrar el archivo %s, intenta reinstalar CorsixTH.",
  missing_th_data_file = "Advertencia: No se pudo encontrar el archivo %s, faltan datos de Theme Hospital.",
  missing_level_file = "Error: No se pudo encontrar el archivo de nivel seleccionado.",
  overlay = {
    incorrect_difficulty = "La dificultad debe ser facil, full o dificil. El valor actual es ",
    incorrect_level_number = "El número nivel debe estar entre 1 y 12. El valor actual es ",
    missing_setting = "No se ha especificado la dificultad ni el numero de nivel para el nivel personalizado.",
  },
  cannot_restart_missing_files = "Lo siento, pero este nivel no se puede reiniciar debido a archivos faltantes %s o %s.",
}

warnings = {
  levelfile_variable_is_deprecated = "Aviso: El nivel %s contiene una definición de variable obsoleta en el archivo del nivel." ..
                                     "'%LevelFile' ha sido renombrado como '%MapFile'. Avisa al creador del mapa para que actualice el nivel.",
  newersave = "Advertencia, has cargado una partida guardada de una versión más reciente de CorsixTH. No se recomienda continuar, ya que el juego podría cerrarse. Juega bajo tu propio riesgo."
}

confirmation = {
  needs_restart = "Para cambiar este ajuste debes reiniciar CorsixTH. Se perderá todo el progreso que no hayas guardado. ¿Seguro que quieres continuar?",
  abort_edit_room = "Ahora mismo estás construyendo o editando una habitación. Si has colocado todos los objetos necesarios será terminada, de lo contrario se borrará. ¿Quieres continuar?",
  maximum_screen_size = "El tamaño de pantalla que has introducido es mayor que 3000x2000.  Es posible utilizar una resolución más grande, pero necesitarás un ordenador potente para que la velocidad de fotogramas sea aceptable. ¿Seguro que quieres continuar?",
  music_warning = "Nota: Necesitas el archivo smpeg.dll o el equivalente para tu sistema operativo, de lo contrario no tendrás música en el juego. ¿Quieres continuar?",
  remove_destroyed_room = "¿Te gustaría eliminar la habitación por $%d?",
  replace_machine_extra_info = "La nueva máquina tendrá una resistencia de %d (actualmente es de %d).",
  very_old_save = "Han habido muchas actualizaciones en el juego desde que comenzaste el nivel. Para asegurarte de que todas las características funcionen es debido, ¿te gustaría reiniciar este nivel ahora?//" ..
  "Tu archivo de guardado anterior no se eliminará a menos que lo sobrescribas.",
  restart_mapeditor = "¿Estás seguro que quieres reiniciar el editor de mapas?",
  quit_mapeditor = "¿Estás seguro que quieres salir del editor de mapas?",
}

information = {
  custom_game = "Bienvenido a CorsixTH. ¡Diviértete con este mapa personalizado!",
  no_custom_game_in_demo = "La versión demo no permite jugar a mapas personalizados.",
  cannot_restart = "Esta partida personalizada se guardó antes de que se implementara la característica de reiniciar.",
  very_old_save = "Han habido muchas actualizaciones en el juego desde que comenzaste. Para asegurarte de que todas las características funcionen como se espera, considera reiniciar el nivel.",
  level_lost = {
    "¡Qué pena! Has fracasado en este nivel. ¡Ya tendrás más suerte la próxima vez!",
    "La razón por la que has perdido es:",
    reputation = "Tu reputación ha caído por debajo de %d.",
    balance = "Tu cuenta bancaria ha llegado a tener menos de %d.",
    percentage_killed = "Has matado a más de un %d por ciento de los pacientes.",
    cheat = "¡Espero que no hayas hecho clic en el botón 'Perder Nivel' por accidente!",
  },
  staff_happiness = "La felicidad promedio del personal cayó debajo de %d%.",
  patient_happiness = "La felicidad promedio de los pacientes cayó debajo de %d%.",
  cheat_not_possible = "No puedes usar ese truco en este nivel.",
}

tooltip.information = {
  close = "Cerrar la ventana de información",
}

totd_window = {
  tips = {
    "Todo hospital necesita una mesa de recepción y una consulta para empezar a funcionar. A partir de ahí depende del tipo de pacientes que visite tu hospital. Eso sí, una farmacia siempre es una buena opción.",
    "Las máquinas como el inflador necesitan mantenimiento. Contrata a un par de bedeles para que reparen tus máquinas o podrías herir a tus pacientes y a tu personal.",
    "Tu personal se cansará pasado un tiempo. Procura construir una sala de personal para que puedan relajarse.",
    "Coloca varios radiadores para mantener calentitos a tu personal y empleados o se enfadarán. Usa el mapa de la ciudad para buscar las zonas que no tienen calefacción en tu hospital.",
    "El nivel de cualificación de un médico influye en la calidad y la velocidad de sus diagnósticos. Si asignas un médico cualificado a tu consulta no necesitarás tantas consultas de diagnosis.",
    "Los principiantes y los médicos pueden mejorar su cualificación si un especialista les enseña en la sala de formación. Si el especialista tiene una cualificación especial (cirujano, psiquiatra o investigador), también enseñará sus conocimientos a sus alumnos.",
    "¿Has probado a meter el número de emergencias (112) en el fax? ¡Asegúrate de tener el sonido activado!",
    "Puedes ajustar algunos parámetros como la resolución y el idioma del juego en la ventana de opciones, que se encuentra tanto en el menú principal como dentro del juego.",
    "¿Has seleccionado el castellano, pero sigues viendo textos en inglés en algún lugar? ¡Avísanos de qué líneas de texto están en inglés para que podamos traducirlas!",
    "¡El equipo de CorsixTH busca refuerzos! ¿Te interesa programar, traducir o crear gráficos para CorsixTH? Contáctanos en nuestro foro, lista de correo o canal IRC (corsix-th en freenode).",
    "Si encuentras un fallo, puedes enviarnos un informe en nuestro registro de fallos: th-issues.corsix.org",
    "Cada nivel tiene unos requisitos concretos que debes conseguir antes de poder avanzar al siguiente nivel. Mira en la ventana de estado para ver como llevas los objetivos del nivel.",
    "Si quieres editar o quitar una habitación ya existente, puedes hacerlo con el botón Editar habitación, en la barra de herramientas inferior.",
    "Cuando tengas muchos pacientes esperando, puedes averiguar quienes están esperando para una habitación en concreto pasando el cursor por encima de la habitación.",
    "Pulsa en la puerta de una habitación para ver su cola. Aquí puedes afinar ciertas cosas, como el orden la cola o mandar a un paciente hacia otra habitación.",
    "El personal que no esté contento pedirá aumentos de sueldo con frecuencia. Asegúrate de que tu personal trabaja en un entorno cómodo para evitar que esto ocurra.",
    "Los pacientes tendrán sed mientras esperan en tu hospital, ¡y más si subes la calefacción! Coloca máquinas de bebidas en lugares estratégicos para ganar un dinerillo extra.",
    "Puedes cancelar el progreso del diagnóstico de un paciente y adivinar la cura si ya has descubierto la enfermedad. Ten en cuenta que esto aumentará el riesgo de darle el tratamiento equivocado, lo que matará al paciente.",
    "Las emergencias pueden ser una buena forma de ganar un dinerillo extra, siempre y cuando tengas la capacidad suficiente para ocuparte de los pacientes de la emergencia a tiempo.",
    "¿Sabías que puedes asignar bedeles a terrenos específicos? Solo clickea el texto 'Todas las parcelas' en su ficha de personal para cambiarlo!",
  },
  previous = "Siguiente consejo",
  next = "Consejo anterior",
}

tooltip.totd_window = {
  previous = "Mostrar el consejo anterior",
  next = "Mostrar el consejo siguiente",
}

debug_patient_window = {
  caption = "Paciente de depuración",
}

tooltip.debug_patient_window = {
  item = "Crear un paciente de depuración con %s",
}

cheats_window = {
  caption = "Trucos",
  warning = "Advertencia: ¡No conseguirás bonificaciones al acabar este nivel si haces trampas!",
  cheated = {
    no = "Se han usado trucos: No",
    yes = "Se han usado trucos: Sí",
  },
  cheats = {
    money = "Truco de dinero",
    all_research = "Truco de todo investigado",
    emergency = "Crear una emergencia",
    vip = "Crear un VIP",
    toggle_earthquake = "Activar terremotos",
    earthquake = "Crear terremoto",
    toggle_epidemic = "Activar epidemias",
    epidemic = "Crear un paciente contagioso",
    show_infected = "Mostrar/ocultar iconos de infección",
    create_patient = "Crear un paciente",
    end_month = "Fin de mes",
    end_year = "Fin del año",
    lose_level = "Perder el nivel",
    win_level = "Ganar el nivel",
    increase_prices = "Subir precios",
    decrease_prices = "Bajar precios",
    reset_death_count = "Reiniciar contador de muertes",
  max_reputation = "Reputación máxima",
    repair_all_machines = "Reparar todas las máquinas",
    toggle_invulnerable_machines = "Activar máquinas invulnerables",
  },
  close = "Cerrar",
}

tooltip.cheats_window = {
  close = "Cerrar la ventana de trucos",
  cheats = {
    money = "Añade 10.000 dólares a tu cuenta bancaria.",
    all_research = "Completa todas las investigaciones.",
    emergency = "Crea una emergencia.",
    vip = "Crea un VIP.",
    toggle_earthquake = "Activar terremotos",
    earthquake = "Crea un terremoto.",
    toggle_epidemic = "Permite elegir si las epidemias ocurrirán",
    epidemic = "Crea un paciente contagioso que podría provocar una epidemia.",
    show_infected = "Muestra u oculta los iconos de infección para la epidemia activa.",
    create_patient = "Crea un paciente en el borde del mapa.",
    end_month = "Avanza hasta el fin del mes actual.",
    end_year = "Avanza hasta el final del año actual.",
    lose_level = "Hace que pierdas el nivel actual.",
    win_level = "Hace que ganes el nivel actual.",
    increase_prices = "Aumenta los precios en un 50% (200% máximo).",
    decrease_prices = "Reduce los precios en un 50% (50% mínimo).",
    reset_death_count = "Reinicia el contador de muertes del hospital a cero",
    max_reputation = "Establece la reputación del hospital al máximo",
    repair_all_machines = "Repara todas las máquinas del hospital",
    toggle_invulnerable_machines = "Permite elegir si las máquinas pueden estropearse o romperse luego de ser usadas",
  }
}

introduction_texts = {
  demo =
    "¡Bienvenido al hospital de demostración!" ..
    "Por desgracia, la demo sólo contiene este nivel. ¡Pero tiene más que suficiente para distraerte un buen rato!" ..
    "Te enfrentarás a varias enfermedades que deberás curar construyendo varias salas. De vez en cuando pueden aparecer emergencias. Necesitarás investigar varios tipos de consultas utilizando una consulta de investigación." ..
    "Tu objetivo es ganar 100.000 dólares, una reputación de 700, que tu hospital tenga un valor de 70.000 dólares y que hayas curado al menos al 75% de tus pacientes." ..
    "Procura que tu reputación no caiga por debajo de 300 y no mates a más del 40% de tus pacientes o perderás el nivel." ..
    "¡Suerte!",
}

introduction_texts[1] = "Intenta alcanzar una reputación de 300, un saldo bancario de 10.000 dólares y cura a 40 personas."

calls_dispatcher = {
  -- Dispatcher description message. Visible in Calls Dispatcher dialog
  summary = "%d llamadas, %d asignadas",
  staff = "%s - %s",
  watering = "Regando @ %d,%d",
  repair = "Reparar %s",
  close = "Cerrar",
}

tooltip.calls_dispatcher = {
  task = "Lista de tareas: Pulsa en una tarea para abrir la ventana del personal asignado y desplázate hasta la posición de la tarea.",
  assigned = "Esta opción está activada si alguien ha sido asignado a la tarea correspondiente.",
  close = "Cerrar la ventana de llamadas de control.",
}

tooltip.machine_window = {
  toggle_machine_menu = "Haz clic para abrir el menú de máquinas",
}

machine_menu = {
  machine = "Máquina",
  remaining_strength = "Restante",
  total_strength = "Fuerza",
  ratio = "Índice",
  close = "Cerrar",
}

tooltip.machine_menu = {
  sort = "Haz clic para ordenar por esta valor.",
  machine = "Lista de máquinas - haz clic en una máquina para abrir su interfaz y desplazarte a su ubicación",
  smoking = "Esta casilla estará marcada si la máquina corre riesgo de explotar",
  assigned = "Esta casilla estará marcada si un operario de mantenimiento está asignado para reparar la máquina correspondiente",
  remaining_strength = "Esta etiqueta muestra la fuerza restante de la máquina",
  total_strength = "Muestra la fuerza total de la máquina",
  ratio = "Muestra la relación entre la fuerza restante y la fuerza total",
  header = {
    smoking = "Indicador de peligro",
    assigned = "Indicador de asignación",
    machine = "Nombre y posición de la máquina",
    remaining_strength = "Fuerza restante de las máquinas.",
    total_strength = "Fuerza total de las máquinas.",
    ratio = "Porcentaje de fuerza restante en relación con la fuerza total de las máquinas",
    times_used = "Cantidad de veces que se ha usado la máquina.",
  },
  close = "Cerrar la lista de máquinas",
}

adviser_history = {
  message = "Mensaje",
  close = "Cerrar",
}

tooltip.adviser_history = {
  delete_message = "Haz clic para eliminar este mensaje",
  message = "Lista de mensajes del consejero - los mensajes más nuevos aparecerán al principio",
  header = {
    message = "Mensajes del consejero",
    delete_message = "Haz clic para eliminar todos los mensajes"
  },
  close = "Cerrar el diálogo de historial del consejero",
}

update_window = {
  caption = "¡Actualización disponible!",
  new_version = "Versión nueva:",
  current_version = "Versión actual:",
  download = "Ir a la página de descargas",
  ignore = "Saltar e ir al menú principal",
}

tooltip.update_window = {
  download = "Ir a la página de descargas para obtener la última versión de CorsixTH.",
  ignore = "Ignorar esta actualización por el momento. Volverás a ser notificado la próxima vez que ejecutes CorsixTH.",
}

map_editor_window = {
  pages = {
    inside = "Interior",
    outside = "Exterior",
    foliage = "Vegetación",
    hedgerow = "Setos",
    pond = "Estaque",
    road = "Camino",
    north_wall = "Muro norte",
    west_wall = "Muro oeste",
    helipad = "Helipuerto",
    delete_wall = "Borrar muros",
    parcel_0 = "Parcela 0",
    parcel_1 = "Parcela 1",
    parcel_2 = "Parcela 2",
    parcel_3 = "Parcela 3",
    parcel_4 = "Parcela 4",
    parcel_5 = "Parcela 5",
    parcel_6 = "Parcela 6",
    parcel_7 = "Parcela 7",
    parcel_8 = "Parcela 8",
    parcel_9 = "Parcela 9",
    parcel = "Parcela %d",
    set_parcel_tooltip = "Ingresa un número y presiona enter.",
    set_parcel = "Ingresar número de parcela",
    camera_1 = "Cámara 1",
    camera_2 = "Cámara 2",
    camera_3 = "Cámara 3",
    camera_4 = "Cámara 4",
    heliport_1 = "Helipuerto 1",
    heliport_2 = "Helipuerto 2",
    heliport_3 = "Helipuerto 3",
    heliport_4 = "Helipuerto 4",
    paste = "Pegar zona",
  },
  checks = {
    spawn_points_and_path = "Advertencia: Los pacientes no pueden llegar al hospital. Se necesitan casillas de 'carretera' o casillas grises de 'exterior' desde el borde del mapa hasta la entrada del hospital.",
  },
}

tooltip.toolbar = {
  machine_menu = "Menú de máquinas",
}

hotkey_window = {
  ingame_panel_machineMenu = "Menú de Máquinas",
  ingame_toggleTransparent = "Habilitar transparencias",
}

hotkeys_file_err = {
  file_err_01 = "No se pudo cargar el archivo 'hotkeys.txt'. Por favor asegúrate de que CorsixTH " ..
        "tiene permisos para leer/escribir ",
  file_err_02 = ", o usa la opcion de línea de comandos --hotkeys-file=filename para especificar un archivo que pueda ser escrito. " ..
        "Para referencia, el error al cargar el archivo de teclas de acceso rápido fue: ",
}

transactions.remove_room = "Construir: Eliminar habitación destruida"

tooltip.status = {
  over = {
    staff_happiness = "La felicidad promedio del personal debería ser mayor a %d%. Actualmente es %d%",
    patient_happiness = "La felicidad promedio de tus pacientes deberia ser mayor a %d%. Actualmente es %d%",
  },
  under = {
    staff_happiness = "La felicidad promedio del personal no debería ser menor a %d%. Actualmente es %d%",
    patient_happiness = "La felicidad promedio de tus pacientes no debería ser menor a %d%. Actualmente es %d%",
  }
}

level_progress = {
  cured_enough_patients = "Has curado suficientes pacientes, pero necesitas organizar mejor tu hospital para superar el nivel.",
  hospital_value_enough = "Mantén el valor de tu hospital por encima de %d y atiende tus otros problemas para superar el nivel."
}

multiplayer = {
  players_failed = "Los siguientes jugadores no lograron completar el último objetivo:",
  everyone_failed = "Ninguno de los jugadores ha logrado completar el último objetivo, por lo que todos pueden continuar jugando!"
}

disease_discovered_patient_choice.need_to_employ = "Emplea a un %s para poder manejar esta situación."
subtitles = {
  alien001 = "¡Alerta roja! ¡Ataque alienígena!", --unused
  alien002 = "¡Los alienígenas han aterrizado, ayuda!", --unused
  alien003 = "¡Los alienígenas existen y están en el edificio!", --unused
  alien004 = "¡Se pide a los alienígenas que no perturben demasiado el hospital!", --unused
  alien005 = "Alienígenas, por favor firmen el libro de visitas.", --unused
  cheat001 = "¡El administrador del hospital está haciendo trampa!",
  cheat002 = "¡Advertencia! ¡Un tramposo está dirigiendo el hospital!",
  cheat003 = "¡Alerta de trampa! ¡Alerta de trampa!",
  emerg001 = "Aviso al personal: llegan pacientes con Montones Amontonados.",
  emerg002 = "Aviso al personal: pacientes con Las Corredoras están en camino.",
  emerg003 = "Aviso al personal: llegan pacientes con Personalidades Televisivas.",
  emerg004 = "Aviso al personal: pacientes con Resfriado Poco Común en camino.",
  emerg005 = "Aviso al personal: llegan pacientes con Huesos Fracturados.",
  emerg006 = "Aviso al personal: llegan pacientes con Invisibilidad.",
  emerg007 = "Aviso al personal: llegan pacientes con Cabeza Hinchada.",
  emerg008 = "Aviso al personal: pacientes con Peluditis en camino.",
  emerg009 = "Aviso al personal: llegan pacientes con el Síndrome del Rey.",
  emerg010 = "Aviso al personal: llegan pacientes con Radiación Grave.",
  emerg011 = "Aviso al personal: llegan pacientes con Lengua Floja.",
  emerg012 = "Aviso al personal: llegan pacientes con Calvicie.",
  emerg013 = "Aviso al personal: pacientes con Picor Discreto llegando.",
  emerg014 = "Aviso al personal: llegan pacientes con Gelatinitis.",
  emerg015 = "Aviso al personal: llegan pacientes con Enfermedad del Sueño.",
  emerg016 = "Aviso al personal: pacientes con Viento Roto llegando.",
  emerg017 = "Aviso al personal: llegan pacientes con Palmas Sudorosas.",
  emerg018 = "Aviso al personal: llegan pacientes con Hinchazón Inesperada.",
  emerg019 = "Aviso al personal: pacientes con Podredumbre Estomacal llegando.",
  emerg020 = "Aviso al personal: llegan pacientes con ADN Alienígena.",
  emerg021 = "Aviso al personal: llegan pacientes con Embarazo.",
  emerg022 = "Aviso al personal: llegan pacientes con Transparencia.",
  emerg023 = "Aviso al personal: pacientes con Costillas de Repuesto llegando.",
  emerg024 = "Aviso al personal: llegan pacientes con Frijoles Riñón.",
  emerg025 = "Aviso al personal: pacientes con Corazones Rotos llegando.",
  emerg026 = "Aviso al personal: llegan pacientes con Nódulos Reventados.",
  emerg027 = "Aviso al personal: llegan pacientes con Risa Infecciosa.",
  emerg028 = "Aviso al personal: pacientes con Tobillos Corrugados en camino.",
  emerg029 = "Aviso al personal: llegan pacientes con Pelo Nasal Crónico.",
  emerg030 = "Aviso al personal: llegan pacientes con Patillas de Tercer Grado.",
  emerg031 = "Aviso al personal: pacientes con Sangre Falsa llegando.",
  emerg032 = "Aviso al personal: llegan pacientes con Expulsiones Gástricas.",
  emerg033 = "Aviso al personal: llegan pacientes con Pulmones de Hierro.",
  emerg034 = "Aviso al personal: llegan pacientes con Piedras de Golf.",
  epid001 = "¡Alerta de epidemia, prepárense!",
  epid002 = "Aviso al personal: ¡alerta de epidemia!",
  epid003 = "¡Advertencia, alerta de epidemia!",
  epid004 = "¡Advertencia!",
  epid005 = "Epidemia terminada, todo despejado.",
  epid006 = "Epidemia bajo control.",
  epid007 = "Epidemia contenida.",
  epid008 = "Emergencia de epidemia finalizada.",
  machwarn = "*Alarma de máquina*",
  maint004 = "Se solicita al técnico reparar el Cortador de Lengua.",
  maint005 = "Técnico, por favor repare la máquina de Rayos X.",
  maint006 = "Se solicita al técnico reparar el Reparador de ADN.",
  maint007 = "Se requiere mantenimiento en el Restaurador de Pelo.",
  maint008 = "Técnico, por favor repare la máquina de Electrólisis.",
  maint009 = "Se requiere mantenimiento en la Tina de Gelatina.",
  maint010 = "Se solicita al técnico en la máquina de Cardio.",
  maint011 = "Técnico, por favor repare la máquina de Diagnóstico.",
  maint012 = "Se requiere mantenimiento en Descontaminación.",
  maint013 = "Técnico, por favor dé mantenimiento al Inflador.",
  maint014 = "Se requiere mantenimiento en la máquina de Fracturas.",
  maint015 = "Se solicita al técnico en la Máquina de Sangre.",
  maint016 = "Técnico, atienda el Ultraescáner.",
  quake001 = "¡Advertencia! Se ha reportado un terremoto.",
  quake002 = "¡Advertencia! Terremoto inminente.",
  quake003 = "¡Atención! Alerta de terremoto.",
  quake004 = "¡Atención! Terremoto en camino.",
  rand001 = "Teléfono de cortesía blanco.",
  rand002 = "Doctor Jekyll, preséntese en psiquiatría por favor.",
  rand003 = "Prohibido fumar en el hospital, por favor.",
  rand005 = "Se recuerda a los pacientes no morir en los pasillos.",
  rand006 = "Toses y estornudos propagan enfermedades.",
  rand008 = "Mensaje para pacientes: se requieren chequeras.",
  rand009 = "Mensaje para pacientes: se requieren tarjetas de crédito.",
  rand010 = "Silencio por favor, hay gente enferma.",
  rand012 = "Se pide a los pacientes no vomitar demasiado.",
  rand013 = "Advertencia: esto es una advertencia.",
  rand016 = "Los pacientes están aquí bajo su propio riesgo.",
  rand017 = "Se pide a los pacientes enfadados que estén lo más callados posible.",
  rand018 = "Se pide a los pacientes tener paciencia.",
  rand019 = "Se pide a los pacientes esperar en silencio.",
  rand021 = "Por favor, no ensucien el hospital.",
  rand022 = "Tirar basura va en contra de las reglas.",
  rand024 = "Pacientes, por favor guárdense sus gérmenes.",
  rand025 = "Los pacientes deben tener su chequera lista.",
  rand026 = "Pacientes, tengan lista su tarjeta de crédito.",
  rand027 = "Pacientes terminales al frente de la fila.",
  rand028 = "Por favor, formen filas ordenadas.",
  rand029 = "Estén atentos a otros productos de Bullfrog.",
  rand030 = "Prohibido merodear.",
  rand031 = "Prohibido tirar basura.",
  rand032 = "Prohibido vomitar.",
  rand033 = "Se recuerda al personal descansar con frecuencia.",
  rand034 = "Oferta especial de hoy: trasplante de pelo a mitad de precio.",
  rand035 = "Los señores Burke y Hare a la salida trasera, por favor.",
  rand036 = "¡Por favor no alimenten a los roedores, gracias!",
  rand037 = "¡Se pide amablemente a los pacientes gemir en voz baja, gracias!",
  rand040 = "¡Advertencia de bomba de basura!",
  rand041 = "Estoy harto de anunciar, quiero irme a casa.",
  rand044 = "¿Podría la gente intentar no vomitar en los pasillos?",
  rand045 = "Doctor Lecter, preséntese en seguridad por favor, Doctor Lecter a seguridad.",
  rand046 = "Su tarjeta de sonido está funcionando.",
  reqd001 = "Doctor, atienda de inmediato en Cardio por favor.",
  reqd002 = "Doctor, atienda en la sala de Escáner por favor.",
  reqd003 = "Doctor, atienda en Psiquiatría por favor.",
  reqd004 = "Se requiere enfermera en la Clínica de Fracturas por favor.",
  reqd005 = "Se necesita doctor en la clínica de Lengua Caida.",
  reqd006 = "Se requiere doctor en la sala de la Máquina de Sangre.",
  reqd007 = "Se busca doctor en Ultraescáner.",
  reqd008 = "Se requiere doctor en la Consulta.",
  reqd009 = "Se requiere enfermera en la Sala.",
  reqd010 = "Se requieren dos cirujanos en el Quirófano.",
  reqd011 = "Se requiere otro cirujano en el Quirófano.", --unused
  reqd012 = "Se requiere enfermera en la Farmacia.",
  reqd013 = "Se requiere doctor en Rayos X.",
  reqd014 = "Se requiere doctor en la sala del Inflador.",
  reqd015 = "Se requiere doctor en el Reparador de ADN.",
  reqd016 = "Se necesita doctor en Restauración de Pelo.",
  reqd017 = "Se requiere doctor en Formación.", --unused
  reqd019 = "Se busca doctor en Electrólisis.",
  reqd020 = "Se requiere doctor en la Tina de Gelatina.",
  reqd021 = "Se requiere doctor en Diagnóstico General.",
  reqd023 = "Se necesita investigador en el Departamento de Investigación.",
  reqd024 = "Se requiere doctor en Descontaminación.",
  sack001 = "Doctor despedido.",
  sack002 = "El doctor se está yendo.",
  sack003 = "El doctor está saliendo.",
  sack004 = "La enfermera se está yendo.",
  sack005 = "La enfermera se está yendo ahora.",
  sack006 = "Técnico despedido está saliendo.",
  sack007 = "Se le ha pedido a la recepcionista que se retire.",
  sack008 = "La recepcionista se está yendo.",
  sack009 = "Un miembro del personal ha sido reclutado por la competencia.", --unused
  sack010 = "Un doctor ha sido reclutado por la competencia.", --unused
  sorry001 = "Pedimos disculpas por la cantidad de basura.", --unused
  sorry002 = "Pedimos disculpas por el frío extremo.",
  sorry003 = "Lamentamos el calor excesivo.",
  sorry004 = "Disculpas a los pacientes, los radiadores están fallando.",
  sorry005 = "Advertencia de vómito, cuiden sus pies.", --unused
  sorry006 = "Mantenimiento, alerta de vómito en el pasillo.", --unused
  vip001 = "Atención, tenemos un VIP en el edificio.",
  vip002 = "Un VIP ha entrado al edificio.",
  vip003 = "Un VIP está de visita en este momento.",
  vip004 = "Un VIP está recorriendo el edificio.",
  vip005 = "Tenemos un VIP con nosotros.",
  vip008 = "Un hombre del ministerio está en el hospital.",
}
--------------------------------  UNUSED  -----------------------------------
------------------- (kept for backwards compatibility) ----------------------

information.very_old_save = "Han habido muchas actualizaciones en el juego desde que comenzaste este nivel. Para asegurarte de que todas las funciones operen como se espera, considera reiniciarlo."
machine_menu = {
  ratio = "Proporción",
  percentage = "%d%",
}
tooltip.machine_menu = {
  ratio = "Este valor muestra la proporción entre la resistencia restante y la resistencia total",
  header = {
    ratio = "Proporción porcentual entre la resistencia restante y la resistencia total de las máquinas.",
  }
}
cheats_window.cheats = {
 toggle_infected = show_infected,
}
tooltip.cheats_window.cheats = {
 toggle_infected = show_infected,
}

-------------------------------------------------------------------------------
--   Multiplayer (network play): the room, game options, auctions, bots and the rest
--   of the multiplayer windows. Translated from english.lua; the keys
--   missing here show in English.
-------------------------------------------------------------------------------
hotkey_window.ingame_mp_chat = "Chat multijugador"
hotkey_window.ingame_mp_next_hospital = "Hospital siguiente (MJ)"
main_menu.multiplayer = "Multijugador"
map_editor_window.pages.camera_n = "Cámara %d"
map_editor_window.pages.heliport_n = "Helipuerto %d"
map_editor_window.pages.player = "Jugador %d"
menu.map_size = "TAMAÑO DEL MAPA"
menu_map_size.size = "  NUEVO MAPA %d x %d  "
menu_player_count.players_5 = "  5 JUGADORES  "
menu_player_count.players_6 = "  6 JUGADORES  "
menu_player_count.players_7 = "  7 JUGADORES  "
menu_player_count.players_8 = "  8 JUGADORES  "
multiplayer_window.add_bot = "esperando a un jugador... (clic: añadir un bot)"
multiplayer_window.ask_amount = "Cantidad: $%d"
multiplayer_window.ask_asked = "Pedido enviado. Esperando su respuesta."
multiplayer_window.ask_balance_line = "Su saldo: $%d."
multiplayer_window.ask_button = "Pedir"
multiplayer_window.ask_caption = "Pedir dinero a %s"
multiplayer_window.ask_decline = "Rechazar"
multiplayer_window.ask_declined_note = "%s ha rechazado enviarte $%d."
multiplayer_window.ask_line = "%s te pide $%d."
multiplayer_window.ask_money = "Pedir a un jugador"
multiplayer_window.ask_no_money_asker_note = "%s no pudo pagarte."
multiplayer_window.ask_no_money_note = "No puedes pagar $%d."
multiplayer_window.ask_pay = "Pagar $%d"
multiplayer_window.ask_sent_note = "Has pedido $%d a %s. Esperando su respuesta."
multiplayer_window.auction_back = "Volver a la subasta"
multiplayer_window.auction_bid = "Pujar $%d"
multiplayer_window.auction_borrow_tooltip = "Pedir prestados $5,000 al banco"
multiplayer_window.auction_close = "Cerrar"
multiplayer_window.auction_dropped = "Te has retirado."
multiplayer_window.auction_going_once = "A la una..."
multiplayer_window.auction_going_twice = "A las dos..."
multiplayer_window.auction_leader = "Puja más alta: $%d, %s"
multiplayer_window.auction_leading = "Vas en cabeza. Espera a los demás."
multiplayer_window.auction_loan = "$%d, préstamo $%d"
multiplayer_window.auction_loan_tooltip = "Tu saldo y tu préstamo bancario"
multiplayer_window.auction_no_money = "No puedes pagar la siguiente puja."
multiplayer_window.auction_no_money_loan = "No puedes pagar la siguiente puja: pide un préstamo con + abajo."
multiplayer_window.auction_not_sold = "La parcela %d no se vendió."
multiplayer_window.auction_out = "fuera"
multiplayer_window.auction_pass = "Retirarse"
multiplayer_window.auction_paused = "El juego se detiene durante la subasta."
multiplayer_window.auction_price = "Precio $%d, cada puja $%d más"
multiplayer_window.auction_how = "Puja con la marca, retírate con la cruz."
multiplayer_window.auction_repay_tooltip = "Devolver $5,000 del préstamo"
multiplayer_window.auction_sold = "Parcela %d vendida a %s por $%d."
multiplayer_window.auction_started = "%s quiere la parcela %d. Otros jugadores también pueden quererla: sale a subasta."
multiplayer_window.auction_title = "Subasta de terreno: parcela %d"
multiplayer_window.auction_wait = "Subasta en curso, espera..."
multiplayer_window.auction_watching = "Tu terreno no linda con esta parcela."
multiplayer_window.auctions_all = "Todas"
multiplayer_window.auctions_caption = "Subastas de terreno"
multiplayer_window.auctions_near = "Disputadas"
multiplayer_window.auctions_none = "No"
multiplayer_window.back = "Atrás"
multiplayer_window.back_to_lobby = "Volver a la sala de espera"
multiplayer_window.bot_line = "%s   (bot)%s"
multiplayer_window.bot_remove = "   clic: quitar"
multiplayer_window.bot_easy = "%s, fácil"
multiplayer_window.bot_hard = "%s, difícil"
multiplayer_window.bot_menu_easy = "Fácil: sin dinero oculto, sin modelo de lenguaje"
multiplayer_window.bot_menu_normal = "Normal"
multiplayer_window.bot_menu_hard = "Difícil: más dinero, reputación y valor"
multiplayer_window.bot_starting = "un bot se está iniciando..."
multiplayer_window.caption = "Multijugador"
multiplayer_window.cert_changed_help = "El certificado de %s no es el que este juego recordaba de la última vez. O bien el servidor se ha configurado de nuevo, o bien alguien se ha puesto entre tú y el servidor. El juego no se ha conectado. Si sabes que el servidor tiene un certificado nuevo, borra su línea de %s y conéctate otra vez."
multiplayer_window.chat_private_in = "%s (a ti): %s"
multiplayer_window.chat_private_out = "A %s: %s"
multiplayer_window.chat_team_in = "%s (al equipo): %s"
multiplayer_window.chat_team_out = "Al equipo: %s"
multiplayer_window.chat_to = "A %s:"
multiplayer_window.chat_to_all = "A todos:"
multiplayer_window.chat_to_team = "Al equipo:"
multiplayer_window.chat_to_allies = "A los aliados:"
multiplayer_window.chat_allies_in = "%s (a los aliados): %s"
multiplayer_window.chat_allies_out = "A los aliados: %s"
multiplayer_window.clear_destroyed_room = "¿Despejar la sala destruida por $%d? El espacio quedará libre para otra cosa."
multiplayer_window.colour_names[1] = "Amarillo"
multiplayer_window.colour_names[2] = "Rojo"
multiplayer_window.colour_names[3] = "Morado"
multiplayer_window.colour_names[4] = "Blanco"
multiplayer_window.colour_names[5] = "Verde"
multiplayer_window.colour_names[6] = "Azul"
multiplayer_window.colour_names[7] = "Turquesa"
multiplayer_window.colour_names[8] = "Negro"
multiplayer_window.connect = "Conectar"
multiplayer_window.connecting = "Conectando a %s..."
multiplayer_window.continue_save = "Continuar: %s"
multiplayer_window.continuing = "partida %s"
multiplayer_window.create = "Crear"
multiplayer_window.data_mismatch_help = "Los archivos de Theme Hospital de este servidor son de otra edición del juego distinta a la tuya (los niveles y los mapas multijugador son diferentes), y las partidas con ambas no se mantendrían iguales. Indica a CorsixTH la misma edición que la del servidor (Opciones, Opciones de carpetas, ubicación de Theme Hospital), por ejemplo la versión de GOG, y vuelve a conectarte."
multiplayer_window.disconnect = "Desconectar"
multiplayer_window.download = "Descargar %s desde GitHub"
multiplayer_window.emergency_refused = "Rechazar la emergencia costó %d de reputación al hospital."
multiplayer_window.encrypted = "Conexión cifrada (TLS)"
multiplayer_window.every_plot_auctioned = "todas las parcelas a subasta"
multiplayer_window.game_options = "Opciones de juego"
multiplayer_window.goal_limit = "límite:"
multiplayer_window.goal_other.balance = "%s: saldo $%d (%s $%d)"
multiplayer_window.goal_other.num_cured = "%s: %d pacientes curados (%s %d)"
multiplayer_window.goal_other.percentage_cured = "%s: %d%% de pacientes curados (%s %d%%)"
multiplayer_window.goal_other.percentage_killed = "%s: %d%% de pacientes fallecidos (%s %d%%)"
multiplayer_window.goal_other.reputation = "%s: reputación %d (%s %d)"
multiplayer_window.goal_other.value = "%s: valor del hospital $%d (%s $%d)"
multiplayer_window.goal_target = "objetivo:"
multiplayer_window.goals_done = "logrado"
multiplayer_window.goals_failed_other = "%s ha fracasado en los objetivos de este nivel. Ayúdale a recuperarse antes de que acabe el año que viene (dinero o personal), o pierde todo el equipo."
multiplayer_window.goals_failed_team = "Tu hospital ha fracasado en los objetivos de este nivel. Recupérate antes de que acabe el año que viene, o pierde todo el equipo. Los otros jugadores pueden enviarte dinero o personal."
multiplayer_window.goals_failing = "fallando"
multiplayer_window.goals_open = "-"
multiplayer_window.goals_reached_loan = "Tu hospital cumple todos los objetivos de este nivel pero aún debe $%d al banco. Salda el préstamo (haz clic en tu dinero abajo) y contarán como logrados."
multiplayer_window.goals_reached_other = "%s ha logrado los objetivos de este nivel. Aún falta: %s."
multiplayer_window.goals_reached_team = "¡Tu hospital ha logrado los objetivos de este nivel! Aún falta: %s."
multiplayer_window.goals_recovered = "%s ya no fracasa en los objetivos de este nivel."
multiplayer_window.helpers_off = "Los bots aliados construyen: no"
multiplayer_window.helpers_on = "Los bots aliados construyen: sí"
multiplayer_window.hold_left = "El juego sigue como muy tarde en %s."
multiplayer_window.hold_win = "Esperando a que %s conteste al fax..."
multiplayer_window.hold_year = "Esperando a que %s cierre el informe anual..."
multiplayer_window.is_ready = "listo"
multiplayer_window.join = "Unirse"
multiplayer_window.keep_playing = "Seguir jugando"
multiplayer_window.kick_player = "Quitar a %s de la sala"
multiplayer_window.kicked = "%s, el propietario de la sala, te ha quitado de la sala."
multiplayer_window.leave = "Salir de la sala"
multiplayer_window.level = "Nivel %d"
multiplayer_window.level7_breakthrough = "Avance médico: %s fue el primero en descubrir: %s, y gana $%d."
multiplayer_window.level7_breakthrough_bonus = "Bonificación por avance"
multiplayer_window.level7_job_fair = "La feria de empleo está abierta: este mes hay especialistas en la lista de contratación."
multiplayer_window.level7_job_fair_soon = "El mes que viene abre una feria de empleo: cirujanos, psiquiatras, investigadores y consultores estarán en la lista de contratación. Quien primero llega, primero se sirve."
multiplayer_window.level7_quarter = "Clasificación del Ministerio de Sanidad: %s curó a más pacientes este trimestre (%d) y gana reputación."
multiplayer_window.level7_race_bonus = "Bonificación de emergencia de carrera"
multiplayer_window.level7_race_emergency = "Una emergencia de carrera: ahora todos los hospitales reciben la misma emergencia. El primero en salvar a todos los pacientes gana $%d y reputación."
multiplayer_window.level7_race_won = "%s salvó el primero a todos los pacientes de la emergencia de carrera y gana $%d."
multiplayer_window.level7_rat_bounty = "Recompensa por ratas"
multiplayer_window.level7_trick_of_month = "Truco del mes: %s cuesta la mitad hasta que acabe el mes."
multiplayer_window.level7_truce_over = "La tregua ha terminado: desde ahora se pueden comprar golpes bajos (MULTIJUGADOR > GOLPES BAJOS)."
multiplayer_window.level_intro_6 = "¡Emergencia! Los hospitales de esta ciudad aceptan todas las emergencias que el helicóptero pueda traer. Durante el primer año llegan cuatro al mes, a cada uno de tus hospitales por turnos: casos de hinchazón y psiquiatría desde febrero (y algunos para la farmacia), casos de quirófano desde mayo, lengua caída y fracturas desde junio. En mayo todos los hospitales reciben pacientes con lengua caída, así que investiga pronto la Clínica de Lengua Caída. Rechazar una emergencia cuesta reputación, pero perder pacientes por ellas se perdona más de lo normal, y puedes derivar pacientes de emergencia al hospital de un amigo que pueda curarlos. Mientras duran las emergencias entran menos pacientes; a partir del segundo año vienen más, y las epidemias recorren todos los hospitales cada dos o tres meses. A las ratas también les gusta esto. Contrata consultores mientras puedas: a partir del noveno mes solo buscan trabajo médicos residentes. Para ganar, cada hospital necesita una reputación de 550, $60,000 en el banco, 150 pacientes curados, una tasa de curación del 40 por ciento y el valor de hospital que indica el Informe de progreso."
multiplayer_window.level_intro_7 = "Sin piedad. Todos los hospitales de esta ciudad quieren ser los mejores, y ninguno juega limpio. Hay una tregua hasta marzo; después los golpes bajos se abren mes a mes: primero ataques de ratas, campañas de desprestigio y calderas averiadas; bedeles malvados, epidemias y espionaje desde junio; emergencias forzadas y cazatalentos desde septiembre, y el nivel más fuerte de cada golpe desde el segundo año. Cada mes se vende un golpe a mitad de precio, el hospital más atrasado paga la mitad por todos, y el líder paga una vez y media más. Vale la pena pelear por ello: las ferias de empleo de abril, octubre, el abril siguiente y el octubre siguiente traen cirujanos, psiquiatras, investigadores y consultores a la lista de contratación, quien primero llega, primero se sirve. En agosto, febrero y el agosto siguiente, todos los hospitales reciben la misma emergencia a la vez, y el primero en salvar a todos los pacientes gana $10,000 y reputación. El primero en descubrir los rayos X, el escáner o la máquina de sangre también gana $10,000 (los planos robados no cuentan), y cada trimestre el hospital que curó a más pacientes gana reputación. Las ratas enviadas por un rival pagan $100 cada una al abatirlas. Aquí las máquinas se desgastan más rápido, y cuatro terremotos sacudirán la ciudad, cada uno más fuerte que el anterior. Para ganar, un hospital necesita una reputación de 650, $150,000 en el banco, 300 pacientes curados, una tasa de curación del 55 por ciento y el valor de hospital que indica el Informe de progreso. Con cuatro jugadores la ciudad es el mapa de Matroftt."
multiplayer_window.level_intro_8 = "Team Town, el mapa de Matroftt, está hecho para dos contra dos: los cuatro hospitales están por parejas en el centro de la ciudad, los compañeros de equipo uno al lado del otro, con mucho terreno en venta por todos los lados. Pon a tus amigos en el mismo equipo y compite contra la otra pareja. Para ganar, cada hospital necesita una reputación de 650, $100,000 en el banco, 200 pacientes curados, una tasa de curación del 50 por ciento y el valor de hospital que indica el Informe de progreso. Con dos o tres jugadores se juega en el mapa de otra ciudad."
multiplayer_window.level_intro_9 = "Encrucijada, el mapa de Matroftt, tiene sitio para ocho: la ciudad está dividida en tres filas de tres, con ocho hospitales ya amurallados alrededor de cuatro pequeñas parcelas en venta en el centro, donde se cruzan los caminos. Los cuatro hospitales de las esquinas son algo más grandes. Con cuatro jugadores o menos solo se ocupan las esquinas y los demás hospitales también están en venta. Los pacientes llegan por todos los bordes de la ciudad. Para ganar, cada hospital necesita una reputación de 650, $150.000 en el banco, 300 pacientes curados, un índice de curación del 55 por ciento y el valor del hospital que muestra el Informe de progreso."
multiplayer_window.level_rats_notice = "¡Ratas! Una plaga ha entrado en el hospital. Haz clic en ellas para abatirlas antes de que críen en la basura."
multiplayer_window.level_slack_tongue_warning = "Llegan noticias de lenguas caídas por toda la ciudad. En mayo todos los hospitales recibirán emergencias de lengua caída: investiga la Clínica de Lengua Caída antes."
multiplayer_window.level_won_end = "Has ganado el nivel. ¡Bien hecho!"
multiplayer_window.levels_caption = "Niveles"
multiplayer_window.levels_choose = "Elegir el nivel %d"
multiplayer_window.levels_events = "EVENTOS DE %s"
multiplayer_window.levels_from_campaign = "Salas, enfermedades e investigación como en %s (nivel %d de la campaña)."
multiplayer_window.levels_goal_balance = "$%s en el banco"
multiplayer_window.levels_goal_cure_rate = "Curación %d%%"
multiplayer_window.levels_goal_cured = "%d curados"
multiplayer_window.levels_goal_reputation = "Reputación %d"
multiplayer_window.levels_goal_value = "Valor +$%s"
multiplayer_window.levels_goals = "Para ganar:"
multiplayer_window.levels_legend = "Con color: parcelas iniciales. Gris: en venta."
multiplayer_window.levels_map_by = "Mapa de %s"
multiplayer_window.levels_map_players = "Mapa para %d jugadores"
multiplayer_window.levels_money = "Dinero: $%s"
multiplayer_window.levels_no_map = "Este mapa no está en tus datos de Theme Hospital."
multiplayer_window.levels_several = "Varios hospitales"
multiplayer_window.levels_shared = "Un hospital común"
multiplayer_window.levels_shared_note = "Nivel %d de la campaña: un hospital que todos construyen juntos, con los objetivos de la campaña."
multiplayer_window.load_caption = "Cargar una partida multijugador"
multiplayer_window.load_game = "Cargar partida MJ"
multiplayer_window.loading = "CARGANDO..."
multiplayer_window.locked = "  (contraseña)"
multiplayer_window.looking_at = "Viendo %s"
multiplayer_window.measuring = "Midiendo la conexión..."
multiplayer_window.menu_caption = "  MULTIJUGADOR  "
multiplayer_window.menu_chat = "  ENVIAR UN MENSAJE (%1%)  "
multiplayer_window.menu_colours = "  COLORES DE JUGADORES  "
multiplayer_window.menu_colours_all = "  GENTE DE TODOS  "
multiplayer_window.menu_colours_off = "  NO  "
multiplayer_window.menu_bot_chat = "  CHAT DE LOS BOTS  "
multiplayer_window.menu_bot_chat_all = "  TODO  "
multiplayer_window.menu_bot_chat_auto = "  SIN CHARLA DESDE 3 BOTS  "
multiplayer_window.menu_bot_chat_useful = "  SIN CHARLA  "
multiplayer_window.menu_bot_chat_off = "  NO  "
multiplayer_window.menu_colours_others = "  GENTE DE LOS DEMAS  "
multiplayer_window.menu_players = "  JUGADORES  "
multiplayer_window.menu_research = "  COMPARTIR INVESTIGACION  "
multiplayer_window.menu_sabotage = "  GOLPES BAJOS  "
multiplayer_window.menu_trade = "  COMERCIAR CON OTROS JUGADORES  "
multiplayer_window.mode_competitive = "Carrera: cada uno a lo suyo"
multiplayer_window.mode_coop = "Cooperativo: ganamos todos juntos"
multiplayer_window.mode_mixed = "Carrera de equipos"
multiplayer_window.mode_shared = "Un hospital común"
multiplayer_window.mode_teams = "Carrera de dos equipos"
multiplayer_window.mode_teamshared = "Carrera de hospitales de equipo"
multiplayer_window.money_received = "Dinero de %s"
multiplayer_window.money_received_note = "%s te ha enviado $%d."
multiplayer_window.money_sent = "Dinero enviado a %s"
multiplayer_window.mp_level = "%s (con varios hospitales: nivel %d)"
multiplayer_window.name = "Tu nombre"
multiplayer_window.new_room = "Nueva sala"
multiplayer_window.no_auctions = "sin subastas"
multiplayer_window.no_helper_building = "los bots no construyen"
multiplayer_window.no_rooms = "Aún no hay salas. Crea una abajo."
multiplayer_window.no_sharing = "sin compartir"
multiplayer_window.no_socket = "Esta versión no tiene soporte de red (falta LuaSocket)."
multiplayer_window.no_tricks = "sin golpes bajos"
multiplayer_window.not_encrypted = "Sin cifrar"
multiplayer_window.not_encrypted_build = "Sin cifrar: este juego no tiene LuaSec"
multiplayer_window.not_encrypted_server = "Sin cifrar: este servidor no tiene certificado"
multiplayer_window.not_ready = "no listo"
multiplayer_window.offer_ability = "Habilidad: %d%%"
multiplayer_window.offer_accept = "Aceptar"
multiplayer_window.offer_accept_pay = "Pagar $%d"
multiplayer_window.offer_accept_price = "Aceptar y pagar $%d"
multiplayer_window.offer_accepted_note = "%s ha aceptado: %s."
multiplayer_window.offer_accepted_price_note = "%s ha aceptado: %s, por $%d."
multiplayer_window.offer_caption = "Oferta de %s"
multiplayer_window.offer_decline = "Rechazar"
multiplayer_window.offer_declined_note = "%s ha rechazado: %s."
multiplayer_window.offer_free_banner = "GRATIS: sin coste por este miembro del personal"
multiplayer_window.offer_gone_note = "%s ya no está disponible."
multiplayer_window.offer_happy = "Felicidad: %d%%"
multiplayer_window.offer_health = "Salud: %d%%"
multiplayer_window.offer_illness = "Enfermedad: %s"
multiplayer_window.offer_job = "Puesto: %s"
multiplayer_window.offer_later = "Más tarde"
multiplayer_window.offer_no_money_note = "No puedes pagar los $%d pedidos por %s."
multiplayer_window.offer_no_money_sender_note = "%s no pudo pagar el precio por %s."
multiplayer_window.offer_no_skills = "Habilidades especiales: ninguna"
multiplayer_window.offer_not_diagnosed = "Aún sin diagnosticar (%d%% hecho)"
multiplayer_window.offer_patient_known = "un paciente con %s"
multiplayer_window.offer_patient_line = "%s te deriva un paciente:"
multiplayer_window.offer_patient_unknown = "un paciente sin diagnosticar"
multiplayer_window.offer_price_banner = "PRECIO: $%d, se paga solo si aceptas"
multiplayer_window.offer_price_line = "PRECIO: $%d. Lo piden por este miembro del personal."
multiplayer_window.offer_raise = "Pide un aumento de sueldo"
multiplayer_window.offer_sent_note = "%s se ha ofrecido a %s. Esperando su respuesta."
multiplayer_window.offer_sent_price_note = "%s se ha ofrecido a %s por $%d. Esperando su respuesta."
multiplayer_window.offer_show = "Ver"
multiplayer_window.offer_skills = "Habilidades especiales: %s"
multiplayer_window.offer_staff_line = "%s te ofrece un miembro del personal:"
multiplayer_window.offer_tired = "Cansancio: %d%%"
multiplayer_window.offer_wage = "Sueldo: $%d al mes"
multiplayer_window.options_close = "Cerrar"
multiplayer_window.options_host_only = "Solo el anfitrión cambia esto."
multiplayer_window.options_off_line = "Opciones: %s"
multiplayer_window.other_build = "  (otra versión del juego)"
multiplayer_window.owner_mark = " (anfitrión)"
multiplayer_window.password = "Contraseña"
multiplayer_window.password_clear = "Sin cifrar: la contraseña va en texto claro. Pulsa otra vez para enviar."
multiplayer_window.patient_arrived_note = "Ha llegado un paciente derivado por %s."
multiplayer_window.patient_on_the_way = "Derivado a %s"
multiplayer_window.places[1] = "1.º"
multiplayer_window.places[2] = "2.º"
multiplayer_window.places[3] = "3.º"
multiplayer_window.places[4] = "4.º"
multiplayer_window.places[5] = "5.º"
multiplayer_window.places[6] = "6.º"
multiplayer_window.places[7] = "7.º"
multiplayer_window.places[8] = "8.º"
multiplayer_window.player_away_note = "%s se ha ido: su hospital no cuenta para los objetivos del equipo hasta que vuelva (misma sala, mismo nombre)."
multiplayer_window.player_back_note = "%s ha vuelto: su hospital cuenta otra vez para los objetivos del equipo."
multiplayer_window.player_line = "%s%s   %s ms   %s"
multiplayer_window.players = "%d jugadores"
multiplayer_window.players_balance = "Saldo"
multiplayer_window.players_behind = "%d horas de retraso"
multiplayer_window.players_caption = "Jugadores"
multiplayer_window.players_goals = "Objetivos"
multiplayer_window.players_hospital = "Hospital"
multiplayer_window.players_left = "dejó la partida"
multiplayer_window.players_ms = "%d ms"
multiplayer_window.players_name = "Jugador"
multiplayer_window.players_note = "Ping: media de los últimos 10 segundos. Valor: el valor del hospital (un objetivo del nivel)."
multiplayer_window.players_ping = "Ping"
multiplayer_window.players_playing = "jugando"
multiplayer_window.players_quiet = "sin respuesta desde hace %d s"
multiplayer_window.players_reputation = "Reputación"
multiplayer_window.players_status = "Estado"
multiplayer_window.players_team = "%s (equipo %d)"
multiplayer_window.players_value = "Valor"
multiplayer_window.players_waiting = "Esperando la lista del servidor..."
multiplayer_window.players_you = "tú"
multiplayer_window.plot_bought_transaction = "Terreno de %s (parcela %d)"
multiplayer_window.plot_give_button = "Ofrecer la parcela"
multiplayer_window.plot_give_cancel = "Cancelar"
multiplayer_window.plot_give_caption = "Ceder la parcela %d"
multiplayer_window.plot_give_free = "Precio: gratis"
multiplayer_window.plot_give_hint = "Ceder esta parcela a un aliado, gratis o por un precio"
multiplayer_window.plot_give_none = "No hay nadie a quien ceder una parcela."
multiplayer_window.plot_give_offered = "Ofrecida. La parcela cambia de manos si el otro jugador acepta."
multiplayer_window.plot_give_price = "Precio: $%d"
multiplayer_window.plot_give_to = "A qué aliado:"
multiplayer_window.plot_given_transaction = "Terreno para %s (parcela %d)"
multiplayer_window.plot_offer_accepted_note = "%s ha aceptado la parcela %d."
multiplayer_window.plot_offer_accepted_price_note = "%s ha aceptado la parcela %d por $%d."
multiplayer_window.plot_offer_declined_note = "%s ha rechazado la parcela %d."
multiplayer_window.plot_offer_free_line = "GRATIS: sin coste por esta parcela."
multiplayer_window.plot_offer_gone_note = "La oferta de la parcela %d ya no vale: las cosas han cambiado."
multiplayer_window.plot_offer_line = "%s te ofrece la parcela %d (%d casillas de terreno)."
multiplayer_window.plot_offer_no_money_note = "No puedes pagar los $%d que piden por la parcela %d."
multiplayer_window.plot_offer_no_money_sender_note = "%s no pudo pagar la parcela %d."
multiplayer_window.plot_offer_price_line = "PRECIO: $%d, se paga solo si aceptas."
multiplayer_window.plot_offer_sent_note = "La parcela %d se ofreció a %s como regalo. Esperando su respuesta."
multiplayer_window.plot_offer_sent_price_note = "La parcela %d se ofreció a %s por $%d. Esperando su respuesta."
multiplayer_window.plot_received_note = "La parcela %d ya es tuya, de parte de %s."
multiplayer_window.plot_sell_hint = "Vender esta parcela de vuelta al banco (debe estar vacía)"
multiplayer_window.plot_sell_question = "¿Quieres vender esta parcela? Recibirás $%d de vuelta."
multiplayer_window.plot_sold_note = "La parcela %d se ha vendido de vuelta al banco por $%d."
multiplayer_window.plot_sold_others_note = "%s ha vendido de vuelta la parcela %d. Está otra vez en venta."
multiplayer_window.plot_sold_transaction = "Parcela %d vendida de vuelta"
multiplayer_window.race_and = " y "
multiplayer_window.race_failing = "Tu hospital ha fracasado en los objetivos de este nivel. Recupérate antes de que acabe el año que viene, o quedas fuera de la carrera."
multiplayer_window.race_failing_other = "%s ha fracasado en los objetivos de este nivel; queda fuera si vuelve a fracasar el año que viene."
multiplayer_window.race_left_end = "Has abandonado la carrera. Los demás siguen por los puestos siguientes."
multiplayer_window.race_out[1] = "Malas noticias."
multiplayer_window.race_out[2] = "Tu hospital ha fracasado en los objetivos de este nivel dos años seguidos: queda fuera de la carrera, en el puesto: %s."
multiplayer_window.race_out[3] = "¿Volver a la sala de espera o mirar a los demás?"
multiplayer_window.race_out_other = "%s fracasó en los objetivos dos años seguidos y queda fuera de la carrera (puesto: %s)."
multiplayer_window.race_out_short = "fuera"
multiplayer_window.race_over[1] = "La carrera ha terminado. Clasificación final:"
multiplayer_window.race_over[2] = "¿Volver a la sala de espera o seguir jugando?"
multiplayer_window.race_over_won = "¡Enhorabuena, tu equipo ha ganado la carrera! Clasificación final:"
multiplayer_window.race_placed_other = "%s ha logrado los objetivos de este nivel: puesto %s. La carrera continúa."
multiplayer_window.race_standing = "%s %s"
multiplayer_window.race_standing_out = " (fuera)"
multiplayer_window.race_watch = "Mirar"
multiplayer_window.race_won[1] = "¡Enhorabuena!"
multiplayer_window.race_won[2] = "Tu hospital ha logrado los objetivos de este nivel: puesto %s."
multiplayer_window.race_won[3] = "Los demás compiten por los puestos siguientes. ¿Volver a la sala de espera o mirar?"
multiplayer_window.race_won_question = "Los demás compiten por los puestos siguientes. ¿Quieres volver a la sala de espera?"
multiplayer_window.race_won_allies = "¡Tú y %s lo habéis logrado! ¡Bien hecho!"
multiplayer_window.race_won_allies_first = "¡Tú y %s lo habéis conseguido! ¡Excelente trabajo!"
multiplayer_window.race_won_first = "Tu hospital es el primero en lograr todos los objetivos de %s. ¡Has ganado la carrera!"
multiplayer_window.race_won_place = "Tu hospital ha logrado todos los objetivos de %s: puesto %s."
multiplayer_window.race_won_team_first = "Tu equipo es el primero en lograr todos los objetivos de %s. ¡Has ganado la carrera!"
multiplayer_window.race_won_team_place = "Tu equipo ha logrado todos los objetivos de %s: puesto %s."
multiplayer_window.race_won_together = "¡Lo habéis logrado juntos! ¡Bien hecho!"
multiplayer_window.race_won_together_first = "¡Lo habéis conseguido juntos! ¡Excelente trabajo!"
multiplayer_window.race_won_well_done = "¡Bien hecho!"
multiplayer_window.rat_attacks = "ataques de ratas"
multiplayer_window.rats_off = "Ataque de ratas (carreras): no permitido"
multiplayer_window.rats_on = "Ataque de ratas (carreras): permitido"
multiplayer_window.ready = "Listo"
multiplayer_window.rebuild_destroyed_room = "Esta sala fue destruida. ¿Despejarla por $%d y construirla de nuevo?"
multiplayer_window.recommendation = "Hasta %s; las acciones tardan %s ms"
multiplayer_window.refer_button = "Derivar paciente"
multiplayer_window.refer_choose = "¿A qué hospital derivarlo?"
multiplayer_window.refer_fax_choice = "Derivar a otro hospital"
multiplayer_window.referral_cured_here_note = "Has curado a un paciente derivado por %s: +%d de reputación extra."
multiplayer_window.referral_cured_note = "%s ha curado al paciente que derivaste: +%d de reputación."
multiplayer_window.refresh = "Actualizar"
multiplayer_window.rep_amount = "Puntos: %d"
multiplayer_window.rep_give_button = "Dar %d de tus puntos de reputación"
multiplayer_window.rep_given_note = "Has avalado a %s: le has dado %d puntos de reputación."
multiplayer_window.rep_received_note = "%s avala tu hospital: has ganado %d puntos de reputación."
multiplayer_window.rep_rivals = "Solo los aliados pueden avalarse entre sí."
multiplayer_window.rep_sent = "Hecho. Los puntos pasan en un momento."
multiplayer_window.rep_vouch_caption = "Aval: da parte de tu reputación"
multiplayer_window.repair_destroyed_room = "Esta sala fue destruida. ¿Repararla por $%d, el precio de una nueva con su mobiliario? (No: despéjala mejor.)"
multiplayer_window.research_accept = "ACEPTO este conocimiento de investigación"
multiplayer_window.research_accept_price = "ACEPTO este conocimiento de investigación por $%d"
multiplayer_window.research_accepted_note = "%s ha aceptado tu investigación (pagó $%d)."
multiplayer_window.research_all = "Todo"
multiplayer_window.research_and_more = "y %d más"
multiplayer_window.research_bought_transaction = "Investigación de %s"
multiplayer_window.research_caption = "Compartir investigación con %s"
multiplayer_window.research_decline = "RECHAZO este conocimiento de investigación"
multiplayer_window.research_declined_note = "%s ha rechazado tu investigación."
multiplayer_window.research_free = "Precio: gratis"
multiplayer_window.research_free_line = "GRATIS: esta transferencia no cuesta nada."
multiplayer_window.research_item_drug = "Medicamento: %s"
multiplayer_window.research_item_machine = "Mejora: %s"
multiplayer_window.research_known_note = "Ya conoces toda esa investigación."
multiplayer_window.research_known_sender_note = "%s ya conocía toda esa investigación."
multiplayer_window.research_next = "Más"
multiplayer_window.research_no_money_note = "No puedes pagar esa investigación ($%d)."
multiplayer_window.research_no_money_sender_note = "%s no pudo pagar tu investigación."
multiplayer_window.research_none = "No tienes investigación que a ellos les falte."
multiplayer_window.research_none_selected = "Elige primero alguna investigación."
multiplayer_window.research_offer = "Ofrecer"
multiplayer_window.research_offer_line = "%s quiere compartir contigo la siguiente investigación:"
multiplayer_window.research_offered = "Ofrecido. Esperando su respuesta."
multiplayer_window.research_page = "Página %d de %d"
multiplayer_window.research_previous = "Atrás"
multiplayer_window.research_price = "Precio: $%d"
multiplayer_window.research_price_line = "PRECIO: $%d. Solo lo pagas si aceptas."
multiplayer_window.research_received_note = "Nueva investigación: %s."
multiplayer_window.research_sent_note = "Investigación ofrecida a %s. Esperando su respuesta."
multiplayer_window.research_sold_transaction = "Investigación vendida a %s"
multiplayer_window.room_caption = "Sala: %s"
multiplayer_window.room_hint = "Mismo color: un solo hospital. Mismo equipo: ganáis juntos."
multiplayer_window.room_line = "%s   %d de %d   %s   nivel %s%s"
multiplayer_window.rooms_caption = "Salas en %s"
multiplayer_window.sabotage_again = "Haz clic otra vez en L%d para comprarlo por $%d."
multiplayer_window.sabotage_alone = "No queda ningún rival al que hacerle jugarretas."
multiplayer_window.sabotage_arrived = "Tu bedel malvado ha empezado a trabajar en %s."
multiplayer_window.sabotage_boiler = "Caldera averiada"
multiplayer_window.sabotage_boiler_notice = "La caldera se ha averiado, y no fue un accidente. Tus bedeles la están reparando: cuantos más sean, antes acabarán."
multiplayer_window.sabotage_caption = "Golpes bajos contra %s"
multiplayer_window.sabotage_caught = "Has echado a un bedel que no era tuyo: lo envió %s. Vuelve con ellos."
multiplayer_window.sabotage_caught_owner = "%s ha descubierto a tu bedel malvado. Vuelve a trabajar para ti."
multiplayer_window.sabotage_close = "Cerrar"
multiplayer_window.sabotage_done.boiler = "La caldera de %s se ha averiado."
multiplayer_window.sabotage_done.emergency = "Una emergencia va de camino a %s."
multiplayer_window.sabotage_done.epidemic = "Los pacientes contagiosos van de camino a %s."
multiplayer_window.sabotage_done.espionage = "Tu espía ha estado en %s."
multiplayer_window.sabotage_done.handyman = "Tu bedel malvado va de camino a %s."
multiplayer_window.sabotage_done.headhunter = "Tu cazatalentos ha hecho una oferta a un miembro del personal de %s."
multiplayer_window.sabotage_done.rats = "Las ratas se mudan a %s."
multiplayer_window.sabotage_done.smear = "La campaña de desprestigio contra %s ha comenzado."
multiplayer_window.sabotage_emergency = "Emergencia"
multiplayer_window.sabotage_emergency_fax[1] = "Te han enviado una emergencia, y no puedes rechazarla."
multiplayer_window.sabotage_emergency_fax[2] = "%d pacientes con %s llegan en helicóptero."
multiplayer_window.sabotage_emergency_fax[3] = "Trata a cuantos puedas antes de que se acabe el tiempo."
multiplayer_window.sabotage_epidemic = "Epidemia"
multiplayer_window.sabotage_espionage = "Espionaje"
multiplayer_window.sabotage_espionage_got = "Tu espía ha traído: %s."
multiplayer_window.sabotage_espionage_notice = "Alguien ha copiado archivos del departamento de investigación."
multiplayer_window.sabotage_espionage_notice_3 = "Alguien ha entrado en el departamento de investigación: archivos copiados, y la investigación en curso retrocede a la mitad."
multiplayer_window.sabotage_handyman = "Bedel malvado"
multiplayer_window.sabotage_handyman_hint = {"Tus equipos se han estado estropeando mucho últimamente. ¿Habrá un bedel malvado en tu hospital?", "Aquí todo sigue saliendo mal. ¿Seguro que todos tus bedeles son realmente tuyos? Despide a uno que no lo sea.", "Un bedel que nadie recuerda haber contratado merodea por tus pasillos. Mira a tus bedeles: a un desconocido se le puede echar."}
multiplayer_window.sabotage_headhunter = "Cazatalentos"
multiplayer_window.sabotage_headhunter_left = "%s se ha ido por una oferta mejor."
multiplayer_window.sabotage_headhunter_notice = "A %s le han ofrecido un trabajo mejor en otro hospital y pide un aumento de $%d. Acepta en 10 días, o se va."
multiplayer_window.sabotage_headhunter_won = "%s ha dejado su hospital y está en la lista de contratación: contrátalo en %d días, antes de que pueda hacerlo otro."
multiplayer_window.sabotage_level = "L%d  $%d"
multiplayer_window.sabotage_level_locked = "L%d  mes %d"
multiplayer_window.sabotage_level_off = "L%d  no"
multiplayer_window.sabotage_levels.boiler[1] = "Su caldera se avería: demasiado frío en invierno, demasiado calor en verano, hasta que sus bedeles la reparen (reparación corta)."
multiplayer_window.sabotage_levels.boiler[2] = "Su caldera se avería, durante el doble de tiempo más o menos. Más bedeles la reparan antes."
multiplayer_window.sabotage_levels.boiler[3] = "Su caldera se avería gravemente: reparación larga. Más bedeles la reparan antes."
multiplayer_window.sabotage_levels.emergency[1] = "Una emergencia que no pueden rechazar: 3 pacientes en helicóptero, con una enfermedad que conocen."
multiplayer_window.sabotage_levels.emergency[2] = "Una emergencia que no pueden rechazar: 6 pacientes en helicóptero, con una enfermedad que conocen."
multiplayer_window.sabotage_levels.emergency[3] = "Una emergencia que no pueden rechazar: 10 pacientes en helicóptero, quizá con una enfermedad que no han descubierto."
multiplayer_window.sabotage_levels.epidemic[1] = "2 pacientes contagiosos de una misma enfermedad llegan a su hospital."
multiplayer_window.sabotage_levels.epidemic[2] = "4 pacientes contagiosos de una misma enfermedad llegan a su hospital."
multiplayer_window.sabotage_levels.epidemic[3] = "7 pacientes contagiosos de una misma enfermedad llegan a su hospital."
multiplayer_window.sabotage_levels.espionage[1] = "Copia una mejora de un medicamento o máquina que ellos tienen y tú no: tú eliges cuál."
multiplayer_window.sabotage_levels.espionage[2] = "Copia un descubrimiento (una máquina o sala) que ellos tienen y tú no: tú eliges cuál."
multiplayer_window.sabotage_levels.espionage[3] = "Copia dos de sus mejoras o descubrimientos (tú eliges) y hace retroceder a la mitad su investigación en curso."
multiplayer_window.sabotage_levels.handyman[1] = "Un bedel que parece el suyo pero no trabaja, durante 4 meses. Si lo encuentran y lo despiden, viene a trabajar para ti."
multiplayer_window.sabotage_levels.handyman[2] = "Como L1, y tira basura en sus pasillos dos veces al día, durante 3 meses."
multiplayer_window.sabotage_levels.handyman[3] = "Como L2, y cada 3 días finge reparar una máquina, dejándola casi averiada. Se queda 2 meses."
multiplayer_window.sabotage_levels.headhunter[1] = "Su mejor médico residente o enfermero recibe una oferta mejor: pagan un aumento del 50 por ciento en 10 días, o lo pierden hacia la lista de contratación (reservado para ti 2 semanas)."
multiplayer_window.sabotage_levels.headhunter[2] = "Su mejor médico recibe una oferta mejor: pagan un aumento del 75 por ciento en 10 días, o lo pierden hacia la lista de contratación (reservado para ti 2 semanas)."
multiplayer_window.sabotage_levels.headhunter[3] = "Su mejor consultor o especialista recibe una oferta mejor: doblan su sueldo en 10 días, o lo pierden hacia la lista de contratación (reservado para ti 2 semanas)."
multiplayer_window.sabotage_levels.rats[1] = "Se mudan 5 ratas. Mientras corren por ahí les cuestan hasta 1 de reputación al día (hasta 30 días), hasta que las abatan."
multiplayer_window.sabotage_levels.rats[2] = "Se mudan 10 ratas. Mientras corren por ahí les cuestan hasta 2 de reputación al día (hasta 30 días), hasta que las abatan."
multiplayer_window.sabotage_levels.rats[3] = "Se mudan 20 ratas. Mientras corren por ahí les cuestan hasta 3 de reputación al día (hasta 30 días), hasta que las abatan."
multiplayer_window.sabotage_levels.smear[1] = "Mala prensa durante un mes: 3 de cada 10 de sus pacientes nuevos van a los otros hospitales."
multiplayer_window.sabotage_levels.smear[2] = "Mala prensa durante 2 meses: 4 de cada 10 de sus pacientes nuevos van a los otros hospitales."
multiplayer_window.sabotage_levels.smear[3] = "Mala prensa durante 3 meses: la mitad de sus pacientes nuevos van a los otros hospitales."
multiplayer_window.sabotage_locked_tooltip = "En este nivel se puede comprar desde el mes %d de la partida."
multiplayer_window.sabotage_next = "Siguiente rival"
multiplayer_window.sabotage_off_tooltip = "El anfitrión no permitió este golpe bajo en esta partida (opciones de juego)."
multiplayer_window.sabotage_pick = "Haz clic en un nivel para ver qué hace. Haz clic otra vez para comprarlo."
multiplayer_window.sabotage_rats = "Ataque de ratas"
multiplayer_window.sabotage_rats_notice = "¡Ratas! Una plaga se ha mudado al hospital. Mientras corren por ahí cuestan reputación cada día: haz clic en ellas para abatirlas."
multiplayer_window.sabotage_rats_reminder = "Aún corren %d ratas por el hospital y cuestan reputación cada día."
multiplayer_window.sabotage_rats_reminders = {"Aún corren %d ratas por el hospital y cuestan reputación cada día. Haz clic en ellas para abatirlas.", "Las ratas siguen aquí, %d de ellas, y los pacientes lo comentan. ¡Abátelas!", "Tu hospital aún tiene %d ratas. Cada día que se quedan te cuesta reputación."}
multiplayer_window.sabotage_refused = "Ese golpe bajo no se puede hacer: %s."
multiplayer_window.sabotage_sent = "Pedido. Pagas cuando se haga."
multiplayer_window.sabotage_smear = "Campaña de desprestigio"
multiplayer_window.sabotage_smear_notice = "Mala prensa: una campaña de desprestigio contra el hospital aleja a algunos pacientes durante %d mes(es)."
multiplayer_window.sabotage_smear_over = "La campaña de desprestigio ha terminado: los pacientes vienen al hospital como antes."
multiplayer_window.sabotage_spy_caption = "Espiar a %s: elige %d"
multiplayer_window.sabotage_spy_pick = "Elige qué debe copiar tu espía y pulsa Robar."
multiplayer_window.sabotage_spy_steal = "Robar ($%d)"
multiplayer_window.sabotage_transaction = "Golpes bajos"
multiplayer_window.sabotage_went_home = "El tiempo de tu bedel malvado en %s ha terminado. Se ha ido a casa."
multiplayer_window.saved_flag = "  partida guardada"
multiplayer_window.saved_note = "Partida guardada: %s"
multiplayer_window.saving_note = "Guardando la partida en el ordenador de cada jugador..."
multiplayer_window.select_room = "Elige primero una sala."
multiplayer_window.server = "Servidor"
multiplayer_window.server_eu1 = "EU1: estable"
multiplayer_window.server_eu2 = "EU2: versiones de prueba"
multiplayer_window.server_version = "la versión del servidor"
multiplayer_window.share_research = "Compartir investigación"
multiplayer_window.shared_won = "Pasar al siguiente nivel no está disponible en multijugador."
multiplayer_window.sharing_off = "Compartir investigación: no"
multiplayer_window.sharing_on = "Compartir investigación: sí"
multiplayer_window.staff_arrived_note = "%s ha llegado y empieza a trabajar."
multiplayer_window.staff_bought_transaction = "Personal de %s"
multiplayer_window.staff_on_the_way = "De camino a %s"
multiplayer_window.staff_received_note = "%s te ha enviado un miembro del personal: %s"
multiplayer_window.staff_sold_transaction = "Personal para %s"
multiplayer_window.start = "Empezar partida"
multiplayer_window.team_button = "Equipo %d"
multiplayer_window.team_lost = "%s volvió a fracasar en los objetivos de este nivel al final del año, así que el equipo ha perdido el nivel."
multiplayer_window.team_member_out = "Tu hospital ha fracasado en los objetivos de este nivel dos años seguidos y queda fuera de la carrera. Tu equipo sigue."
multiplayer_window.team_member_out_other = "%s fracasó en los objetivos dos años seguidos y queda fuera de la carrera; su equipo sigue."
multiplayer_window.team_race_mate_reached_fax[1] = "¡Tu compañero de equipo %s ha logrado los objetivos de este nivel!"
multiplayer_window.team_race_mate_reached_fax[2] = "Tu equipo gana cuando tu hospital llegue también. Aún falta: %s."
multiplayer_window.team_race_mate_reached_fax[3] = "Tu compañero de equipo puede ayudarte con dinero, personal o pacientes."
multiplayer_window.team_race_reached_fax[1] = "¡Tu hospital ha logrado los objetivos de este nivel!"
multiplayer_window.team_race_reached_fax[2] = "La carrera aún no está ganada: tu equipo gana cuando llegue cada hospital suyo. Aún falta: %s."
multiplayer_window.team_race_reached_fax[3] = "Mantén tu hospital en marcha y ayúdales con dinero, personal o pacientes."
multiplayer_window.team_race_reached_other = "%s ha logrado los objetivos de este nivel (equipo %s)."
multiplayer_window.team_won[1] = "¡Enhorabuena!"
multiplayer_window.team_won[2] = "Todos los hospitales han logrado los objetivos de este nivel: el equipo ha ganado el nivel."
multiplayer_window.team_won[3] = "¿Volver a la sala de espera o seguir jugando?"
multiplayer_window.too_many_hospitals = "Este nivel admite %d hospitales: compartid colores"
multiplayer_window.trade_alone = "No hay nadie con quien comerciar."
multiplayer_window.trade_caption = "Comerciar con %s"
multiplayer_window.trade_close = "Cerrar"
multiplayer_window.trade_free = "Precio: gratis"
multiplayer_window.trade_money_allies_only = "El dinero solo va a los aliados."
multiplayer_window.running_flag = "en curso"
multiplayer_window.running_places = "en curso, %d libres"
multiplayer_window.seats_caption = "Plazas en %s"
multiplayer_window.seats_hint = "Ocupa el lugar de un bot o de un jugador que se fue:"
multiplayer_window.seat_on = "%s, jugando"
multiplayer_window.seat_bot = "%s (bot)"
multiplayer_window.seat_standin = "%s (se fue, de momento juega un bot)"
multiplayer_window.seat_left = "%s (se fue)"
multiplayer_window.players_standin = "ausente, juega un bot"
multiplayer_window.players_bot = "bot"
multiplayer_window.trade_next_player = "Siguiente jugador"
multiplayer_window.trade_no_staff = "No tienes personal que enviar."
multiplayer_window.trade_offered = "Ofrecido. Se une a ti si el otro jugador acepta."
multiplayer_window.trade_on_the_way = "- ofrecido"
multiplayer_window.trade_price = "Precio: $%d"
multiplayer_window.trade_select_staff = "Haz clic primero en un miembro del personal."
multiplayer_window.trade_send_money = "Enviar $%d"
multiplayer_window.trade_send_staff = "Ofrecer el personal elegido"
multiplayer_window.trade_sent = "Enviado. Llega en un momento."
multiplayer_window.tricks_off = "Golpes bajos (carreras): no"
multiplayer_window.tricks_on = "Golpes bajos (carreras): sí"
multiplayer_window.vaccination_mode_hint = "Modo vacunación: haz clic en los pacientes infectados para que una enfermera los vacune. Clic derecho, Esc o un nuevo clic en la jeringa para parar."
multiplayer_window.vote_agree = "De acuerdo"
multiplayer_window.vote_asked = "Has pedido a los demás cambiar la velocidad a %s."
multiplayer_window.vote_confirm = "¿Pedir a los demás jugadores cambiar la velocidad del juego a %s?"
multiplayer_window.vote_decline = "Rechazar"
multiplayer_window.vote_declined = "%s ha rechazado el cambio de velocidad a %s."
multiplayer_window.vote_lapsed = "No hubo suficientes jugadores de acuerdo a tiempo: la velocidad sigue como estaba."
multiplayer_window.vote_open = "Ya se está votando un cambio de velocidad."
multiplayer_window.vote_passed = "Los jugadores han acordado: la velocidad ahora es %s."
multiplayer_window.vote_passed_paused = "Los jugadores han acordado %s: la partida seguirá a esa velocidad cuando salga de la pausa."
multiplayer_window.vote_request = "%s querría cambiar la velocidad del juego"
multiplayer_window.vote_request_speed = "a %s."
multiplayer_window.waiting_player = "esperando a un jugador..."
tooltip.main_menu.multiplayer = "Juega con otros a través de un servidor multijugador (experimental)"
tooltip.multiplayer_window.bot_level = "Clic derecho: un bot fácil, normal o difícil"
tooltip.multiplayer_window.ask_money = "Pide dinero a otro jugador. Él decide si paga."
tooltip.multiplayer_window.auctions = "El anfitrión decide qué parcelas de terreno salen a subasta cuando un jugador pide comprar una"
tooltip.multiplayer_window.auctions_all = "Cada parcela sale a subasta entre todos los hospitales que pueden comprarla"
tooltip.multiplayer_window.auctions_near = "Las parcelas del lado de otro jugador o junto al terreno de otro hospital salen a subasta; las demás se compran sin más"
tooltip.multiplayer_window.auctions_none = "Sin subastas: quien lo pide primero compra la parcela"
tooltip.multiplayer_window.colour = "El color de tu hospital: los jugadores con el mismo color construyen un hospital juntos. Haz clic para cambiarlo (el anfitrión puede cambiar el de cualquiera, también el de los bots)"
tooltip.multiplayer_window.connect = "Conectarse al servidor y mostrar sus salas"
tooltip.multiplayer_window.continue_game = "Continúa una partida multijugador guardada antes (Archivo > Guardar, o el autoguardado mensual): elígela de la lista. Sin ella, la sala empieza una partida nueva"
tooltip.multiplayer_window.download = "Este servidor usa otra versión del juego: abre su página de descarga en tu navegador"
tooltip.multiplayer_window.game_options = "Las opciones de la partida: subastas de terreno y más (las fija el anfitrión)"
tooltip.multiplayer_window.helpers = "Decide el anfitrión: un bot que comparte el hospital de una persona construye salas y pone objetos en los pasillos, o se lo deja a la persona (sigue contratando, pagando primas, compartiendo investigación, pujando en subastas y comprando terrenos)"
tooltip.multiplayer_window.level = "Elige el nivel en una lista con sus objetivos y un mapa. Un hospital común juega los niveles de la campaña; varios hospitales juegan los niveles multijugador (del 1 al 8, un número mayor juega el nivel 8). El nivel 6 es ¡Emergencia!: emergencias cuatro veces al mes el primer año, luego epidemias; el nivel 7 es Sin piedad, pensado para una carrera competitiva: golpes bajos mes a mes, ferias de empleo, emergencias de carrera y terremotos; el nivel 8 es Team Town, el mapa de Matroftt pensado para dos contra dos"
tooltip.multiplayer_window.levels_players = "El mapa para este número de jugadores (cada número de jugadores tiene su propio mapa)"
tooltip.multiplayer_window.name = "El nombre que ven los demás jugadores"
tooltip.multiplayer_window.new_game = "Empezar una partida nueva en lugar de la guardada"
tooltip.multiplayer_window.password = "Contraseña de la sala a la que unirse o que crear (vacía: sin contraseña)"
tooltip.multiplayer_window.player_row = "Clic: ver el hospital de este jugador (N: el siguiente hospital)"
tooltip.multiplayer_window.chat_target = "Para quién es el mensaje: todos, tu equipo (en una carrera de equipos) o un jugador. Haz clic o pulsa Tab para el siguiente"
tooltip.multiplayer_window.players = "Para cuántos jugadores es la sala"
tooltip.multiplayer_window.rats = "Lo decide el anfitrión: en una carrera con golpes bajos los jugadores pueden soltar ratas en el hospital de un rival (le cuestan reputación), o no"
tooltip.multiplayer_window.ready = "Avisa al anfitrión de que estás listo para empezar"
tooltip.multiplayer_window.refer_button = "Ofrece este paciente al hospital de otro jugador. Tiene que aceptar."
tooltip.multiplayer_window.send_staff = "Envía este miembro del personal al hospital de otro jugador. Tiene que aceptar."
tooltip.multiplayer_window.server = "Dirección del servidor multijugador, por ejemplo eu2.bachelor-tech.com:47800"
tooltip.multiplayer_window.server_eu1 = "eu1.bachelor-tech.com: la versión estable más reciente"
tooltip.multiplayer_window.server_eu2 = "eu2.bachelor-tech.com: la versión de prueba más reciente"
tooltip.multiplayer_window.share_research = "Ofrece la investigación que tienes al hospital de otro jugador, gratis o por un precio. Tiene que aceptar."
tooltip.multiplayer_window.sharing = "Lo decide el anfitrión: los jugadores pueden compartirse o venderse investigación, o no (como en el juego original)"
tooltip.multiplayer_window.start = "Empieza la partida para todos los de la sala"
tooltip.multiplayer_window.team = "Tu equipo: el mismo equipo gana junto, equipos distintos compiten por los objetivos y pueden hacerse golpes bajos. Haz clic para cambiarlo (el anfitrión puede cambiar el de cualquiera, también el de los bots)"
tooltip.multiplayer_window.tricks = "Lo decide el anfitrión: en una carrera los jugadores pueden comprar golpes bajos contra sus rivales, o no (como en el juego original)"
