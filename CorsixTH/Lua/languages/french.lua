--[[ Copyright (c) 2010-2015 Nicolas "MeV" Elie, 2013-2025 Antoine Lemaire, 2024 Sanndow

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
Language(utf8 "Français", "French", "fr", "fre", "fra")
Inherit("english")
Inherit("original_strings", 1)
IsArabicNumerals(true)

--[[
  Notice: Theme Hospital's font lacks support for certain character types used in
  French, including '«' and '»'. See the "Localisation" page on the Wiki for more
  information.
--]]

----------------------------------------------------------- Override -----------------------------------------------------------
rooms_short.ward = "Salle des malades"
rooms_long.ward = "Salle des malades"
confirmation.replace_machine = "Voulez-vous vraiment remplacer cette machine %s pour $%d ?" -- French originally did not show machine name or cost

misc.save_failed = "ERREUR : partie non sauvegardée." -- Much more french
misc.cant_treat_emergency = "Votre hôpital ne peut pas traiter cette urgence car la maladie n'a pas été découverte. N'hésitez pas à réessayer."
tooltip.policy.diag_termination = "L'auscultation d'un patient continuera jusqu'à ce que les médecins soient sûrs à hauteur du pourcentage FIN PROCEDURE ou jusqu'à ce que toutes les machines de diagnostic aient été essayées. " -- Remove a superfluous word
adviser.goals = {
  win = { -- Why are these strings uppercase?
    reputation = "Portez votre réputation à %d pour pouvoir gagner.",
    value = "Portez la valeur de votre hôpital à %d."
  }
}
adviser.goals.lose.kill = "Tuez encore %d patients pour perdre !"

-- tooltip.staff_list.next_person, prev_person is rather next/prev page (also in german, maybe more languages?)
tooltip.staff_list.next_person = "Voir la page suivante"
tooltip.staff_list.prev_person = "Voir la page précédente"

-- Improve tooltips in staff window to mention hidden features
tooltip.staff_window.face = "Visage - cliquez pour ouvrir la fenêtre de gestion"
tooltip.staff_window.center_view = "clic gauche pour focaliser sur la personne, pour faire défiler les membres du personnel"

-- Fix Winning texts
letter = {
  [1] = { -- Level one: Fix issue 329
    [1] = "Estimable %s",
    [2] = "Splendide ! Vous avez admirablement géré cet hôpital. Nous, pontes du Ministère de la Santé, souhaitons savoir si vous aimeriez prendre en charge un plus grand projet. Nous comptons sur vous. Le salaire serait de %d$ et ça vaut la peine d'y réfléchir.",
    [3] = "Que diriez-vous de travailler à l'hôpital de %s ?"
  },
  [2] = { -- Level two: Add missing spaces before punctuation marks
    [1] = "Estimable %s",
    [2] = "Formidable ! Vous avez fait de grands progrès dans votre hôpital. Nous vous avons trouvé un autre établissement pour exercer vos talents et relever des défis. Vous pouvez refuser mais ce serait dommage. Le salaire est de %d$.",
    [3] = "Acceptez-vous le poste à l'hôpital de %s ?"
  },
  [3] = { -- Level three: Add missing spaces before punctuation marks
    [1] = "Estimable %s",
    [2] = "Vous avez parfaitement réussi dans cet hôpital. C'est la raison pour laquelle nous vous proposons une nouvelle situation. Le salaire serait de %d$ et nous pensons que vous adorerez relever ce nouveau défi.",
    [3] = "Acceptez-vous de gérer l'hôpital de %s ?"
  },
  [4] = { -- Level four: Add missing spaces before punctuation marks
    [1] = "Estimable %s",
    [2] = "Félicitations ! Le Ministère de la Santé est très impressionné par vos capacités à gérer cet hôpital. Vous êtes un exemple de réussite dans ce domaine. Vous voudrez peut-être une situation plus élevée, toutefois. Vous seriez payé %d$, et la décision vous revient.",
    [3] = "Êtes-vous prêt à accepter un poste à l'hôpital de %s ?"
  },
  [5] = { -- Level five: Add missing spaces before punctuation marks and between words
    [1] = "Estimable %s",
    [2] = "Nouvelles salutations. Nous respectons votre souhait de ne pas quitter ce charmant hôpital, mais nous vous supplions d'y réfléchir. Nous vous proposons la coquette somme de %d$ pour accepter de diriger un autre hôpital avec autant de succès.",
    [3] = "Aimeriez-vous prendre la tête de l'hôpital de %s ?"
  },
  [6] = { -- Level six: Add missing spaces before punctuation marks, fix last string which contained an anglicism
    [1] = "Estimable %s",
    [2] = "Nous savons que vous êtes heureux de vous occuper de cette délicieuse institution mais nous pensons que vous devez penser à l'avenir. Vous pourriez prétendre au salaire de %d$ si vous acceptez de changer de situation. Pensez-y.",
    [3] = "Voulez-vous un poste à l'hôpital de %s ?"
  },
  [7] = { -- Level seven: Add missing spaces before punctuation marks
    [1] = "Estimable %s",
    [2] = "Le Ministère de la Santé souhaite que vous reconsidériez votre décision de rester dans cet hôpital. Nous savons que vous avez un charmant établissement mais il est temps de relever un nouveau défi, avec un salaire attrayant de %d$.",
    [3] = "Êtes-vous prêt à travailler à l'hôpital de %s ?"
  },
  [8] = { -- Level height: Add missing spaces before punctuation marks
    [1] = "Estimable %s",
    [2] = "Vous aviez donné une réponse négative à notre dernière lettre vous proposant un grand poste dans un nouvel hôpital, avec un coquet salaire de %d$. Nous pensons que vous devez revoir votre décision car nous avons pour vous un poste idéal.",
    [3] = "Voulez-vous bien accepter un poste à l'hôpital de %s ? S'il vous plaît !"
  },
  [9] = { -- Level nine: Add missing spaces before punctuation marks, fix some sentences, add missing diacritics
    [1] = "Estimable %s",
    [2] = "Vous vous êtes montré le meilleur directeur d'hôpital jamais connu dans la longue et mouvementée histoire de la médecine. Nous sommes fiers de vous offrir le poste de Chef Suprême des Hôpitaux. Ce titre honorifique vous garantit un salaire de %d$. On fera pour vous une parade pleine de serpentins et les gens vous baiseront les pieds.",
    [3] = "Merci pour tout ce que vous avez fait. Vous avez mérité cette semi-retraite."
  },
  [10] = { -- Level ten: Fix some sentences
    [1] = "Estimable %s",
    [2] = "Félicitations pour avoir réussi dans tous les hôpitaux que vous avez dirigés. Une telle performance fait de vous un héros. Vous recevrez une pension de %d$ plus une limousine. Tout ce que nous vous demandons, c'est d'aller de ville en ville rencontrer votre public en adoration et défendre le renom des hôpitaux.",
    [3] = "Nous sommes tous fiers de vous et notre coeur déborde de gratitude pour votre dévouement à sauver des vies."
  },
  [11] = { -- Level eleven: No change
    [1] = "Estimable %s",
    [2] = "Votre carrière est exemplaire et vous êtes une inspiration pour nous tous. Merci d'avoir géré tous ces hôpitaux avec autant de talent. Nous souhaitons vous offrir une rente à vie de %d$ pour simplement aller de ville en ville à bord d'une voiture de prestige pour saluer la foule et donner des conférences sur votre incroyable réussite.",
    [3] = "Vous êtes un exemple pour toute personne sensée et tout le monde, sans exception, vous considère comme un modèle absolu."
  },
  [12] = { -- Level twelve: Add missing spaces before punctuation marks
    [1] = "Estimable %s",
    [2] = "Votre carrière réussie en tant que meilleur directeur d'hôpital depuis la nuit des temps arrive à sa fin. Toutefois, vous avez eu sur le monde tranquille de la médecine une telle influence que le Ministre vous offre un salaire de %d$ uniquement pour paraître en public, faire des inaugurations, baptiser des navires et participer à des débats. Le monde entier vous acclame et c'est la meilleure des publicités pour le Ministère de la Santé !",
    [3] = "Veuillez accepter cette situation : ce n'est pas trop difficile et vous aurez, en plus, une escorte de police partout où vous irez."
  }
}

-- The originals of some of these string lack a space before punctuation marks and or between words
misc.balance = "Ajustage :"
tooltip.pay_rise_window.decline = "Ne payez pas, licenciez !"
tooltip.watch = {
  emergency = "Urgence : temps qui reste pour soigner les patients entrés en urgence.",
  hospital_opening = "Délai : ceci est le temps qui reste avant que votre hôpital soit ouvert. Cliquez sur GO pour l'ouvrir tout de suite.",
  epidemic = "Épidémie : temps qui reste pour arrêter l'épidémie. Si ce délai expire OU si un malade contagieux quitte l'hôpital, un inspecteur sanitaire viendra... Le bouton active ou désactive la vaccination. Cliquez sur un patient pour lancer la vaccination par une infirmière."
}
tooltip.objects = {
  chair = "Chaise : le patient s'y assied pour parler de ses symptômes.",
  sofa = "Sofa : c'est ce qui permet aux employés de se relaxer... sauf s'ils trouvent mieux...",
  bench = "Banc : pour que les patients puissent attendre confortablement.",
  video_game = "Jeu vidéo : l'équipe se relaxe en jouant à Hi-Octane.",
  lamp = "Lampe : vous avez déjà essayé de travailler dans le noir ?",
  door = "Porte : les gens aiment les ouvrir et les fermer.",
  auto_autopsy = "Autopsie : très utile pour la recherche.",
  tv = "TV : votre équipe ne doit pas manquer ses programmes favoris.",
  litter_bomb = "Bombe à détritus : pour saboter les hôpitaux concurrents.",
  inflator = "Gonfleur : pour soigner l'encéphalantiasis.",
  desk = "Bureau : essentiel pour poser un ordinateur.",
  pool_table = "Billard : pour la relaxation du personnel.",
  bed = "Lit : les cas graves ont besoin de rester couchés.",
  bookcase = "Étagère : pour les ouvrages de référence.",
  drinks_machine = "Distributeurs : contre la soif et pour ramasser des gros sous.",
  skeleton = "Squelette : utile pour l'enseignement et pour Halloween.",
  computer = "Ordinateur : une composante essentielle de la recherche.",
  bin = "Poubelle : les patients y jettent leurs détritus.",
  pharmacy_cabinet = "Pharmacie : c'est là qu'on dispense les médicaments.",
  radiator = "Radiateur : permet de garder l'hôpital au chaud.",
  atom_analyser = "Mélangeur : installé au Département Recherche, cette machine accélère tout le processus d'étude.",
  plant = "Plante : plaît aux patients et purifie l'air.",
  toilet = "Toilettes : les patients en ont, euh, besoin.",
  fire_extinguisher = "Extincteur : pour minimiser les dangers causés par des machines défectueuses.",
  lecture_chair = "Chaise : les médecins en formation s'asseyent là pour prendre des notes et s'ennuyer. Plus vous mettrez des chaises, plus vous pourrez former de médecins.",
  toilet_sink = "Lavabo : s'il n'y en a pas assez, les patients qui apprécient l'hygiène seront mécontents.",
  cabinet = "Placard : dossiers des patients, notes de recherche.",
  rathole = "Domicile d'une famille de rats qui a trouvé votre hôpital suffisamment sale pour y vivre."
}

room_descriptions = {
  gp = {
    [2] = "C'est une salle de diagnostic fondamentale pour votre hôpital. Elle accueille les nouveaux patients pour les ausculter. Ils sont ensuite orientés vers une autre salle, soit pour un autre diagnostic soit pour être soignés. Vous devriez construire un autre cabinet de médecine générale au cas où celui-ci serait débordé. Plus l'endroit est grand et plus vous pouvez y placer des équipements, sans compter que c'est bon pour le prestige du médecin. C'est valable pour toutes les salles, en fait."
  },
  pharmacy = {
    [2] = "Les patients dont le mal a été diagnostiqué et dont le traitement est un médicament peuvent se rendre à la pharmacie. Comme la recherche découvre toujours de nouveaux traitements, l'activité de cette salle est en constante évolution. Vous aurez à construire une autre pharmacie plus tard."
  },
  general_diag = {
    [3] = "La salle de diagnostic nécessite un médecin. Il faut également un agent de maintenance pour un entretien périodique. "
  },
  fracture_clinic = {
    [2] = "Les patients dont les os étaient en morceaux se rendront dans cette salle. Le déplâtreur dégagera les membres en ne causant qu'une faible douleur."
  },
  inflation = {
    [2] = "Les patients souffrant de l'affreuse-mais-si-drôle encéphalantiasis sont soignés à la salle de gonflage, où leur tête démesurée sera dégonflée puis regonflée à la bonne taille."
  },
  hair_restoration = {
    [2] = "Les patients souffrant de sévère calvitie se rendront dans cette salle équipée d'un moumouteur. Un médecin utilisera la machine pour donner aux patients une nouvelle chevelure."
  },
  electrolysis = {
    [2] = "Les patients souffrant de pilose viennent dans cette salle où une machine arrache les poils et scelle les pores selon un procédé qui n'est pas sans rappeler la cimentation."
  },
  staff_room = {
    [2] = "Votre équipe finit par se fatiguer et a besoin de cette salle pour se remettre. Une équipe fatiguée est lente, revendicatrice et peut même envisager de démissionner. De plus, elle risque de commettre des erreurs. Il est avisé de construire une salle de repos bien aménagée et de prévoir assez de place pour plusieurs membres à la fois."
  }
}

progress_report.too_hot = "Réglez le chauffage : on étouffe."
adviser.tutorial.build_pharmacy = "Félicitations ! Construisez maintenant une pharmacie et embauchez une infirmière."
adviser.epidemic.serious_warning = "Cette maladie contagieuse est dangereuse. Vous devez prendre des mesures d'urgence !"
adviser.staff_advice.too_many_doctors = "Il y a trop de médecins. Certains n'ont rien à faire !"
adviser.earthquake.ended = "Ouh là ! J'ai cru que c'était la fin ! C'était du %d sur l'échelle de Richter."
adviser.multiplayer.poaching = {
  not_interested = "Ha ! Ils ne veulent pas travailler pour vous, ils sont satisfaits comme ça.",
  already_poached_by_someone = "Eh non ! Quelqu'un s'intéresse déjà à cette personne."
}
adviser.vomit_wave.ended = "Ouf ! On dirait que le virus qui provoquait des nausées est enfin enrayé. Gardez l'hôpital propre, à l'avenir."
adviser.research.new_available = "Nouveau : un(e) %s est disponible."
adviser.research.drug_improved_1 = "Le traitement contre la %s a été amélioré par votre département de recherche."
adviser.placement_info.object_cannot_place = "Hé ! Vous ne pouvez pas placer cet objet ici."
adviser.information = {
  epidemic = "Une maladie contagieuse sévit dans votre hôpital. Vous devez l'enrayer immédiatement !",
  emergency = "C'est une urgence ! Vite ! Vite ! VITE !",
  initial_general_advice = {
    first_epidemic = "Il y a une épidémie dans votre hôpital ! A vous de voir si vous étouffez l'affaire ou si vous en parlez."
  },
  patient_leaving_too_expensive = "Un patient part sans payer la facture pour %s. Sacrée perte !",
  vip_arrived = "Attention ! %s arrive pour visiter votre hôpital ! Faites en sorte de lui faire bonne impression.",
  first_death = "Vous venez de tuer votre premier patient. Alors, heureux ?",
  promotion_to_doctor = "L'un de vos INTERNES est devenu MÉDECIN.", -- Fix the famous "Level 5 bug"
  promotion_to_specialist = "L'un de vos MÉDECINS est devenu SPÉCIALISTE."
}
buy_objects_window = {
  price = "Prix : ",
  total = "Total : "
}
fax = {
  epidemic_result = {
    close_text = "Hourra !",
    rep_loss_fine_amount = "Les journaux vont s'en donner à cœur joie avec cette affaire. Votre réputation va en prendre un coup ! Sans oublier l'amende de %d."
  },
  disease_discovered_patient_choice = {
    what_to_do_question = "Que voulez-vous faire du patient ?"
  },
  debug_fax = {
    close_text = "Ouais, ouais, ouais !"
  },
  diagnosis_failed = {
    what_to_do_question = "Que faire du patient ?",
    partial_diagnosis_percentage_name = "Il y a %d pour cent de chances que la maladie soit %s."
  },
  epidemic = {
    declare_explanation_fine = "Si vous déclarez l'épidémie, vous aurez une amende de %d, un changement de réputation et tous les patients seront vaccinés automatiquement."
  },
  emergency = {
    num_disease = "Il y a %d personnes atteintes de %s qui ont besoin de soins immédiats."
  },
  vip_visit_result = {
    telegram = "Télégramme !",
    vip_remarked_name = "Après avoir visité votre hôpital, %s a dit : ",
    remarks = {
      free_build = {"C'est vraiment un bel hôpital que vous avez là ! Pas trop difficile d'y arriver sans limite d'argent, hein ?", "Je ne suis pas économiste, mais je pense que je pourrais faire tourner cet hôpital aussi si vous voyez ce que je veux dire...", "Un hôpital très bien tenu. Cependant, attention à la récession ! Ah oui... vous n'avez pas à vous soucier de cela."},
    },
  },
  diagnosis_failed = {
    what_to_do_question = "Que faire du patient ?",
    partial_diagnosis_percentage_name = "Il y a %d pour cent de chances que la maladie soit %s."
  },
  diagnosis_failed = {
    what_to_do_question = "Que faire du patient ?",
    partial_diagnosis_percentage_name = "Il y a %d pour cent de chances que la maladie soit %s."
  }
}

dynamic_info = {
  patient = {
    actions = {
      prices_too_high = "C'est trop cher : je rentre chez moi.",
      no_diagnoses_available = "Plus de diagnostic : je rentre chez moi.",
      cured = "Guéri !",
      no_treatment_available = "Pas de traitement : je rentre chez moi."
    },
    diagnosed = "Ausculté : %s"
  }
}

transactions = {
  cure_colon = "Guérison :",
  final_treat_colon = "Trait final :",
  treat_colon = "Trait :",
  advance_colon = "Avance :",
  insurance_colon = "Assurance :",
  remove_room = "Construction : Supprimer la salle détruite"
}
diseases = {
  third_degree_sideburns = {
    cause = "Cause : regret pathologique des années 70.",
    cure = "Traitement : un psychiatre doit faire comprendre au patient qu'il faut changer d'époque comme de chemise.",
    name = "Rétrostalgie",
    symptoms = "Symptômes : passion immodérée des pantalons à pattes d'éléphant et des paillettes."
  },
  discrete_itching = {
    cause = "Cause : petits bestioles à dents aiguës.",
    cure = "Traitement : un sirop gluant est administré pour empêcher les démangeaisons.",
    name = "Morpionnite",
    symptoms = "Symptômes : le patient se gratte jusqu'au sang."
  },
  the_squits = {
    cause = "Cause : avoir mangé de la pizza ramassée derrière la cuisinière.",
    cure = "Traitement : un mélange gluant de diverses substances synthétiques est administré au patient pour solidifier son, euh, contenu.",
    name = "Courante",
    symptoms = "Symptômes : hum. Vous voyez le genre."
  },
  spare_ribs = {
    cause = "Cause : trop de temps passé sur un sol froid.",
    cure = "Traitement : deux chirurgiens retirent les côtes flottantes et les donnent au patient dans un sac à emporter.",
    name = "Excès costal",
    symptoms = "Symptômes : déplaisante sensation de flottement."
  },
  diag_blood_machine = {
    name = "Diag Sanguimachine"
  },
  king_complex = {
    cause = "Cause : l'esprit du King s'est emparé de celui du patient et l'a envahi.",
    cure = "Traitement : un psychiatre explique au patient à quel point tout ceci est ridicule.",
    name = "Syndrome du King",
    symptoms = "Symptômes : passion pour les chaussures en daim bleu et pour les cheeseburgers."
  },
  diag_x_ray = {
    name = "Diag Rayons X"
  },
  pregnancy = {
    cause = "Cause : pannes de courant en zones urbaines.",
    cure = "Traitement : le bébé est prélevé en salle d'opération puis soigneusement nettoyé pour faire son entrée dans le monde.",
    name = "Grossesse",
    symptoms = "Symptômes : gloutonnerie avec hypertrophie du ventre."
  },
  fake_blood = {
    cause = "Cause : avoir été victime d'une très mauvaise plaisanterie.",
    cure = "Traitement : seule une cure psychiatrique peut calmer le patient.",
    name = "Sang factice",
    symptoms = "Symptômes : le patient voit son sang s'évaporer."
  },
  diag_psych = {
    name = "Diag Psychiatre"
  },
  invisibility = {
    cause = "Cause : morsure par une fourmi radioactive (et invisible).",
    cure = "Traitement : il suffit de faire boire au patient un liquide coloré dispensé à la pharmacie pour le rendre pleinement observable.",
    name = "Invisibilité",
    symptoms = "Symptômes : le patient ne souffre pas mais a une forte propension à utiliser son état pour faire des farces à son entourage."
  },
  golf_stones = {
    cause = "Cause : exposition au gaz empoisonné contenu dans les balles de golf.",
    cure = "Traitement : résection des surplus par une équipe de deux chirurgiens.",
    name = "Pierres de golf",
    symptoms = "Symptômes : formation nodules excédentaires."
  },
  diag_general_diag = {
    name = "Diag Généraliste"
  },
  infectious_laughter = {
    cause = "Cause : exposition à un comique de situation.",
    cure = "Traitement : un psychiatre doit faire comprendre au patient à quel point son état est sérieux.",
    name = "Fou rire",
    symptoms = "Symptômes : gloussement irrépressible et répétition compulsive d'accroches même pas drôles."
  },
  general_practice = {
    name = "Généraliste"
  },
  baldness = {
    cause = "Cause : avoir raconté trop de mensonges pour se rendre intéressant.",
    cure = "Traitement : pose très douloureuse de cheveux à l'aide d'un moumouteur.",
    name = "Calvitie",
    symptoms = "Symptômes : tête en boule de billard et gros complexe."
  },
  heaped_piles = {
    cause = "Cause : s'être assis sur un jet de jacuzzi.",
    cure = "Traitement : une potion agréable bien que puissamment acide dissout les rectoïdes de l'intérieur.",
    name = "Rectoïdes",
    symptoms = "Symptômes : le patient a l'impression de s'asseoir sur un sac de billes."
  },
  unexpected_swelling = {
    cause = "Cause : n'importe quoi d'inattendu.",
    cure = "Traitement : le dégonflement est obtenu par une délicate opération pratiquée par deux chirurgiens.",
    name = "Bouffissure",
    symptoms = "Symptômes : bouffissure généralisée."
  },
  jellyitis = {
    cause = "Cause : abus de produits riches en gélifiant et trop d'exercice.",
    cure = "Traitement : le patient est immergé dans un dégélifiant.",
    name = "Gélatine",
    symptoms = "Symptômes : grande mollesse et tendance à l'écroulement."
  },
  hairyitis = {
    cause = "Cause : exposition prolongée au clair de lune.",
    cure = "Traitement : on fait disparaître les poils avec un électrolyseur et les pores sont scellés.",
    name = "Pilose",
    symptoms = "Symptômes : le patient développe un odorat accru."
  },
  alien_dna = {
    cause = "Cause : agrippeurs faciaux munis de sang extraterrestre intelligent.",
    cure = "Traitement : l'ADN est retiré par un correcteur pour être nettoyé puis restitué rapidement.",
    name = "ADN Alien",
    symptoms = "Symptômes : le patient se métamorphose progressivement en sale machin d'outre-espace et veut tout détruire."
  },
  bloaty_head = {
    cause = "Cause : avoir reniflé du fromage et bu de l'eau de pluie.",
    cure = "Traitement : la tête est éclatée puis regonflée à la bonne dimension à l'aide d'une astucieuse machine.",
    name = "Encéphalantiasis",
    symptoms = "Symptômes : affreux maux de tête."
  },
  gastric_ejections = {
    cause = "Cause : nourriture mexicaine ou indienne très épicée.",
    cure = "Traitement : administration par voie orale d'une solution spéciale pour endiguer les rejets.",
    name = "Éjections gastriques",
    symptoms = "Symptômes : le patient rejette par accès des bribes de nourriture mal digérée."
  },
  uncommon_cold = {
    cause = "Cause : divers trucmuches volant dans l'air",
    cure = "Traitement : absorption d'une grande rasade d'un sirop spécial élaboré à la pharmacie.",
    name = "Catarhume",
    symptoms = "Symptômes : nez qui coule, éternuements, poumons décolorés."
  },
  corrugated_ankles = {
    cause = "Cause : avoir roulé trop vite sur des ralentisseurs.",
    cure = "Traitement : le patient doit absorber un mélange d'herbes et d'épices légèrement toxique dont l'effet redressera illico les chevilles.",
    name = "Chevilles ondulées",
    symptoms = "Symptômes : les chaussures ne s'ajustent plus."
  },
  sleeping_illness = {
    cause = "Cause : hypertrophie de la glande palatale de Morphée.",
    cure = "Traitement : une infirmière administre une forte dose d'un puissant stimulant.",
    name = "Roupillance",
    symptoms = "Symptômes : tendance irrépressible à tomber de sommeil."
  },
  sweaty_palms = {
    cause = "Cause : terreur des entretiens d'embauche.",
    cure = "Traitement : un psychiatre détend le patient en lui racontant celle du fou qui repeint son plafond.",
    name = "Mains moites",
    symptoms = "Symptômes : serrer la main du patient revient à presser une éponge détrempée."
  },
  serious_radiation = {
    cause = "Cause : avoir pris du plutonium pour des bonbons.",
    cure = "Traitement : le patient est passé à la douche de décontamination et consciencieusement récuré.",
    name = "Radionite",
    symptoms = "Symptômes : le patient ne se sent vraiment, vraiment pas bien."
  },
  diag_cardiogram = {
    name = "Diag Cardio"
  },
  diag_scanner = {
    name = "Diag Scanner"
  },
  gut_rot = {
    cause = "Cause : la Bonne Vieille Bibine de la Mère Sam.",
    cure = "Traitement : une infirmière doit administrer diverses substances chimiques pour tenter de colmater le tout.",
    name = "Tripurulente",
    symptoms = "Symptômes : aucun microbe mais plus de paroi intestinale non plus."
  },
  iron_lungs = {
    cause = "Cause : pollution atmosphérique combinée aux remugles de kébab.",
    cure = "Traitement : deux chirurgiens enlèvent le blindage en salle d'opération.",
    name = "Poumons de fer",
    symptoms = "Symptômes : envie de respirer du feu et de hurler sous l'eau."
  },
  broken_wind = {
    cause = "Cause : utilisation d'un appareil de musculation juste après un repas.",
    cure = "Traitement : une mixture d'eau lourde est administrée à la pharmacie.",
    name = "Pétomanie",
    symptoms = "Symptômes : pollution de l'air des personnes situées derrière le patient."
  },
  kidney_beans = {
    cause = "Cause : avoir croqué les glaçons de son cocktail.",
    cure = "Traitement : deux chirurgiens extraient les cristaux sans endommager le rein.",
    name = "Cristaux rénaux",
    symptoms = "Symptômes : douleur et fréquentes visites aux toilettes."
  },
  transparency = {
    cause = "Cause : avoir léché le yaourt adhérent au couvercle à l'ouverture d'un pot.",
    cure = "Traitement : administration d'une potion fraîche et colorée préparée à la pharmacie.",
    name = "Transparence",
    symptoms = "Symptômes : la chair est horrible et transparente."
  },
  broken_heart = {
    cause = "Cause : avoir croisé quelqu'un de plus riche, plus jeune et plus beau.",
    cure = "Traitement : deux chirurgiens ouvrent la poitrine et réparent doucement le coeur en retenant leur souffle.",
    name = "Coeur brisé",
    symptoms = "Symptômes : pleurnicheries et crampes causées par des heures à regarder de vieilles photos de vacances."
  },
  slack_tongue = {
    cause = "Cause : trop de discussion à propos des romans-feuilletons.",
    cure = "Traitement : la langue est placée dans un taille-langue puis elle est coupée rapidement, efficacement et douloureusement.",
    name = "Hyperlangue",
    symptoms = "Symptômes : la langue s'étire jusqu'à cinq fois sa longueur normale."
  },
  tv_personalities = {
    cause = "Cause : avoir abusé des programmes télévisés.",
    cure = "Traitement : un psychiatre doit convaincre le patient d'échanger sa télévision contre une radio.",
    name = "Téléincarnation",
    symptoms = "Symptômes : le patient a l'illusion d'être capable de présenter une émission de cuisine."
  },
  ruptured_nodules = {
    cause = "Cause : saut à l'élastique par temps froid.",
    cure = "Traitement : deux chirurgiens doivent réajuster les parties concernées d'une main sûre.",
    name = "Casse-boules",
    symptoms = "Symptômes : impossibilité de s'asseoir confortablement."
  },
  fractured_bones = {
    cause = "Cause : chute spectaculaire sur du béton.",
    cure = "Traitement : un plâtre est posé puis ôté à l'aide d'un équipement au laser.",
    name = "Fractures",
    symptoms = "Symptômes : affreux craquement et incapacité à utiliser les membres touchés."
  },
  chronic_nosehair = {
    cause = "Cause : avoir reniflé avec dédain à la vue de plus malheureux que soi.",
    cure = "Traitement : une épouvantable potion dépilatoire est administrée par une infirmière à la pharmacie.",
    name = "Poilonisme",
    symptoms = "Symptômes : poils au nez si drus qu'un oiseau pourrait y nicher."
  }
}

confirmation = {
  quit = "Vous avez choisi Quitter. Voulez-vous vraiment quitter la partie ?",
  return_to_blueprint = "Voulez-vous vraiment revenir au mode Tracé ?",
  restart_level = "Voulez-vous vraiment relancer ce niveau ?",
  overwrite_save = "Il y a déjà une partie sauvegardée ici. Voulez-vous vraiment l'écraser ?",
  delete_room = "Voulez-vous vraiment détruire cette salle ?",
  sack_staff = "Voulez-vous vraiment licencier ce membre du personnel ?",
}

-- The originals of these strings contain one space too much
trophy_room.sold_drinks.trophies[2] = "Vous recevez le prix Bubulles du Syndicat des Vendeurs de Limonade pour récompenser la quantité de sodas vendus dans votre hôpital au cours de l'année écoulée."

tooltip.status.percentage_cured = "Vous devez soigner %d%% des visiteurs de l'hôpital. Actuellement, vous en avez soigné %d%%"
tooltip.status.num_cured = "L'objectif est de soigner %d personnes. Pour le moment, vous en avez soigné %d"
dynamic_info.staff.actions.going_to_repair = "Pour réparer %s"
adviser.staff_place_advice = {
  only_doctors_in_room = "Seuls les médecins peuvent travailler en %s",
  nurses_cannot_work_in_room = "Les infirmières ne peuvent travailler en %s",
  not_enough_lecture_chairs = "Chaque étudiant en médecine a besoin d'une chaise de conférence pour s'asseoir !"
}
pay_rise.definite_quit = "Rien ne me fera rester ici. J'en ai assez."
place_objects_window.confirm_or_buy_objects = "Vous pouvez valider ainsi ou bien soit acheter soit déplacer des objets."

----------------------------------------------------------- New strings -----------------------------------------------------------

date_format = {
  daymonth = "%1% %2:months%"
}

-- Objects
object.rathole = "Trou à rats."
object.litter = "Déchet"
tooltip.objects.litter = "Déchet : laissé sur le sol par un patient car il n'a pas trouvé de poubelle où le jeter."

tooltip.fax.close = "Fermer cette fenêtre sans supprimer le message"
tooltip.message.button = "clic gauche pour ouvrir le message"
tooltip.message.button_dismiss = "clic gauche pour ouvrir le message, clic droit pour le rejeter"
tooltip.casebook.cure_requirement.hire_staff = "Vous devez embaucher du personnel pour gérer ce traitement"
tooltip.casebook.cure_type.unknown = "Vous ne savez pas encore comment traiter cette maladie"
tooltip.research_policy.no_research = "Aucune recherche n'est actuellement effectuée dans cette catégorie"
tooltip.research_policy.research_progress = "Progrès vers la prochaine découverte dans cette catégorie : %1%/%2%"

menu_file = {
  load = " (%1%) CHARGER   ",
  save = " (%1%) SAUVEGARDER   ",
  restart = " (%1%) RELANCER",
  quit = " (%1%) QUITTER   "
}

-- Options menu
menu_options = {
  lock_windows = "  FIGER LES FENETRES  ",
  edge_scrolling = "  DEFILEMENT PAR BORD  ",
  adviser_disabled = "  (%1%) ASSISTANT  ",
  warmth_colors = "  COULEURS CHAUDES  ",
  wage_increase = "  AUGMENTATION DE SALAIRE  ",
  twentyfour_hour_clock = "  HORLOGE 24 HEURES  ",
  capture_mouse = "  CAPTURER LE CURSEUR  "
}

menu_options_game_speed = {
  pause = "  (%1%) PAUSE  ",
  slowest = "  (%1%) LA PLUS LENTE  ",
  slower = "  (%1%) PLUS LENTE  ",
  normal = "  (%1%) NORMALE  ",
  max_speed = "  (%1%) VITESSE MAX  ",
  and_then_some_more = "  (%1%) ET ENCORE PLUS  "
}

menu_options_warmth_colors = {
  choice_1 = "  ROUGE  ",
  choice_2 = "  BLEU VERT ROUGE  ",
  choice_3 = "  JAUNE ORANGE ROUGE  "
}

menu_options_wage_increase = {
  grant = " ACCORDER ",
  deny = " REFUSER "
}

-- Charts Menu ' Temporary; must see in-game for correct translation
menu_charts = {
  bank_manager = "  (%1%) GESTION BANCAIRE  ",
  statement = "  (%1%) DECLARATION  ",
  staff_listing = "  (%1%) LISTE DU PERSONNEL  ",
  town_map = "  (%1%) CARTE DE LA VILLE  ",
  casebook = "  (%1%) DOSSIER MEDICAL  ",
  research = "  (%1%) RECHERCHE  ",
  status = "  (%1%) STATUTS  ",
  graphs = "  (%1%) GRAPHIQUES  ",
  policy = "  (%1%) POLITIQUE  ",
  machine_menu  = "  (%1%) MENU DES MACHINES",
  adviser_history = "  (%1%) RECAP. CONSEILLER ",
}

tooltip.toolbar = {
  machine_menu = "Menu des machines (%s)",
  hire = "Embaucher (%s)",
  status = "Statut (%s)",
  edit = "Modifier salles/objets (%s)",
  bank_button = "Clic-gauche (%s) pour le directeur de banque ou clic-droit (%s) pour le relevé bancaire",
  policy = "Organisation (%s)",
  research = "Recherches (%s)",
  casebook = "Registre (%s)",
  reputation = "Votre réputation",
  town_map = "Plan Ville (%s)",
  rooms = "Construire des salles (%s)",
  balance = "Votre solde",
  date = "Date",
  charts = "Graphique (%s)",
  objects = "Aménager les couloirs (%s)",
  staff_list = "Gestion de l'équipe (%s)",
}

-- Debug menu
menu_debug = {
  jump_to_level = "  ALLER AU NIVEAU  ",
  connect_debugger = "  (%1%) CONNECTER AU SERVEUR DE DÉBOGUAGE ",
  transparent_walls = "  (%1%) MURS TRANSPARENTS  ",
  limit_camera = "  LIMITER LA CAMERA  ",
  disable_salary_raise = "  DÉSACTIVER LES AUGMENTATIONS DE SALAIRE  ",
  make_debug_fax = "  CRÉER UN FAX DE TEST  ",
  make_debug_patient = "  CRÉER UN PATIENT DE TEST  ",
  cheats = "  (%1%) TRICHES  ",
  lua_console = "  (%1%) CONSOLE LUA  ",
  debug_script = "  (%1%) ACTIVER LE DÉBOGUAGE PAR SCRIPT ",
  calls_dispatcher = "  RÉPARTITION DES TACHES  ", -- Â not supported by TH Font
  dump_strings = "  (%1%) EXTRAIRE LES TRADUCTIONS  ",
  dump_gamelog = "  (%1%) EXTRAIRE LE JOURNAL DE JEU  ",
  map_overlay = "  INCRUSTATIONS DE CARTE  ",
  sprite_viewer = "  VISIONNEUSE DE SPRITES  ",
  allow_blocking_off_areas = "  AUTORISER LE BLOCAGE DES ZONES  "
}

menu_debug_overlay = {
  none = "  AUCUN  ",
  flags = "  DRAPEAUX  ",
  positions = "  POSITIONS  ",
  heat = "  TEMPÉRATURE  ",
  byte_0_1 = "  OCTETS 0 & 1  ",
  byte_floor = "  OCTET SOL  ",
  byte_n_wall = "  OCTET MUR N  ",
  byte_w_wall = "  OCTET MUR O  ",
  byte_5 = "  OCTET 5  ",
  byte_6 = "  OCTET 6  ",
  byte_7 = "  OCTET 7  ",
  parcel = "  PARCELLE  "
}

menu_player_count = {
  players_1 = "  1 JOUEUR  ",
  players_2 = "  2 JOUEURS  ",
  players_3 = "  3 JOUEURS  ",
  players_4 = "  4 JOUEURS  "
}

-- Adviser
adviser = {
  room_forbidden_non_reachable_parts = "Placer la pièce à cet endroit rendrait inaccessibles certaines parties de l'hôpital",

  warnings = {
    no_desk = "Vous devriez construire un bureau de réception et engager une réceptionniste un de ces jours !",
    no_desk_1 = "Si vous voulez que des patients viennent dans votre hôpital, vous devez embaucher une réceptionniste et lui construire un bureau pour travailler !",
    no_desk_2 = "Bien joué, ça doit être un record : presque un an et pas de patient ! Si vous voulez continuer comme directeur de cet hôpital, vous devez embaucher une réceptionniste et lui construire un bureau pour travailler !",
    no_desk_3 = "C'est tout simplement génial, presque un an et vous n'avez pas embauché de réceptionniste ! Comment espérez obtenir le moindre patient ? Arrangez-ça et arrêtez de perdre votre temps !",
    no_desk_4 = "Une réceptionniste aura besoin d'un bureau pour accueillir des patients",
    no_desk_5 = "Il était temps, maintenant les patients devraient commencer à arriver bientôt !",
    no_desk_6 = "Vous avez une réceptionniste, peut-être il est temps de construire un bureau où elle peut travailler ?",
    no_desk_7 = "Maintenant, que vous avez une réception, que diriez-vous d'embaucher une réceptionniste également ? Vous n'aurez pas de patients avant de l'avoir fait !",
    cannot_afford = "Vous n'avez pas assez d'argent à la banque pour embaucher cette personne !", -- I can't see anything like this in the original strings
    cannot_afford_2 = "Vous n'avez pas assez d'argent à la banque pour effectuer l'achat !",
    research_screen_open_1 = "Vous devez construire une salle de recherche avant de pouvoir accéder à l'écran des recherches.",
    research_screen_open_2 = "La recherche est désactivée pour le niveau en cours.",
    researcher_needs_desk_1 = "Chaque chercheur a besoin d'un bureau pour travailler.",
    researcher_needs_desk_2 = "Vos chercheurs sont heureux d'obtenir une pause bien méritée. Si vous voulez que plusieurs chercheurs puissent travailler en même temps.",
    researcher_needs_desk_3 = "Un chercheur a toujours besoin d'un bureau.",
    nurse_needs_desk_1 = "Chaque infirmière a besoin de son propre bureau.",
    nurse_needs_desk_2 = "Votre infirmière est heureuse d'avoir une pause. Si vous comptez y faire travailler plusieurs personnes en même temps, vous devez leur construire un bureau à chacune.",
    low_prices = "Vous facturez trop peu pour %s. Ça va amener des gens dans votre hôpital, mais vous ne ferez pas beaucoup de profit sur chacun d'eux.",
    high_prices = "Votre tarif pour %s est trop élevé. Ça va générer plus de profit sur le court-terme, mais à la longue les gens vont fuir.",
    fair_prices = "Le prix pour %s semble juste et équilibré.",
    patient_not_paying = "Un patient est parti sans payer pour %s parce que c'est trop cher !",
    another_desk = "Vous devrez construire un autre bureau pour cette nouvelle réceptionniste.",
    money_low = "Les fonds sont en baisse !",
    no_patients_last_month = "Pas de nouveaux patients le mois dernier. Honteux !",
    machines_falling_apart = "Les machines tombent en panne. Faites-les réparer !",
    bankruptcy_imminent = "Hé ! Vous courez à la faillite. Attention !",
    too_many_plants = "Il y a bien trop de plantes. C'est la jungle, ici !",
    many_killed = "Vous avez laissé mourir %d personnes. Idiot ! Vous êtes censé les soigner.",
    falling_1 = "Hé ! Ce n'est pas drôle, regardez ou vous cliquez, quelqu'un pourrait être blessé !",
    falling_2 = "Arrêtez de faire n'importe quoi, qu'en penseriez-vous à leur place ?",
    falling_3 = "Aïe, ça doit faire mal,  qu'on appelle un médecin !",
    falling_4 = "C'est un hôpital, pas un parc d'attraction !",
    falling_5 = "Ce n'est pas un endroit pour bousculer les gens, ils sont malades vous savez ?",
    falling_6 = "Ce n'est pas un bowling, les gens malades ne devraient pas être traités comme ça !",
    handymen_tired = "Les agents de maintenance sont très fatigués. Laissez-les se reposer.", -- Add a missing letter
    cannot_afford_machine = "Vous avez besoin de au moins $%1% dans la banque pour pouvoir acheter: %2%!",
  },
  cheats = {
    th_cheat = "Félicitations, vous avez débloqué les triches !",
    roujin_on_cheat = "Défi de Roujin activé ! Bonne chance...",
    roujin_off_cheat = "Défi de Roujin désactivé.",
    norest_on_cheat = "Oh non ! Il semble que votre personnel ait trop consommé de caféine et n'ait plus besoin de se reposer.",
    norest_off_cheat = "Ouf ! On dirait que cette excitation s'est enfin dissipée. Votre personnel se reposera maintenant correctement."
  }
}

-- Dynamic information
dynamic_info.patient.actions.no_gp_available = "Attente d'un cabinet de médecine générale"
dynamic_info.staff.actions.heading_for = "Va vers %s"
dynamic_info.staff.actions.fired = "Renvoyé"
dynamic_info.patient.actions.epidemic_vaccinated = "Je ne suis plus contagieux"
dynamic_info.object.strength_extra_info = "Force %d (Améliorable jusqu'à %d)"
dynamic_info.staff.actions.vaccine = "Vaccination d'un patient"

-- Progress report
progress_report.free_build = "CONSTRUCTION LIBRE"

-- Fax messages
fax = {
  choices = {
    return_to_main_menu = "Retourner au menu principal",
    accept_new_level = "Aller au niveau suivant",
    decline_new_level = "Continuer la partie encore un peu"
  },
  emergency = {
    num_disease_singular = "Il y a 1 personne atteinte de %s qui a besoin de soins immédiats.",
    free_build = "Si vous réussissez votre réputation augmentera mais si vous échouez votre réputation sera sérieusement entachée."
  },
}

-- Winning texts
letter = {
  dear_player = "Cher %s",
  custom_level_completed = "Félicitations ! Vous avez réussi tous les objectifs de ce niveau personnalisé !",
  return_to_main_menu = "Voulez-vous retourner au menu principal ou continuer la partie ?",
  campaign_completed = "Incroyable ! Vous avez réussi à terminer tous les niveaux. Vous pouvez maintenant vous détendre et profiter de remplir des forums sur Internet de vos réalisations. Bonne chance !",
  campaign_level_missing = "Désolé, mais le prochain niveau de cette campagne semble manquer. (Nom: %s)",
  campaign_level_completed = "Bon travail ! Vous avez battu le niveau. Mais ce n'est pas fini !\n Aimeriez-vous un poste à l'hôpital %s ?"
}

-- Installation
install = {
  title = "----------------------------- Installation de CorsixTH -----------------------------",
  th_directory = "CorsixTH nécessite une copie des données du jeu Theme Hospital originel (ou la démo) pour fonctionner. Veuillez utiliser le sélecteur ci-dessous pour indiquer le dossier d'installation de Theme Hospital.",
  ok = "OK",
  exit = "Quitter",
  cancel = "Annuler"
}

-- Misc (some other misc strings also exist outside this section)
misc = {
  not_yet_implemented = "(pas encore implémenté)",
  no_heliport = "Aucune maladie n'a été découverte pour l'instant, ou il n'y a pas d'héliport sur cette carte.",
  epidemics_off = "Les épidémies sont désactivées",
  epidemics_on = "Les épidémies sont activées",
  epidemic_no_receptionist = "Impossible de créer une épidémie - il n'y a pas de réceptionniste",
  epidemic_no_diseases = "Impossible de créer une épidémie - il n'y a pas de maladie contagieuse disponible",
  epidemic_no_icon_to_toggle = "Impossible de montrer/cacher les icônes des infectés - il n'y a pas d'épidémies non-révélées",
  earthquakes_off = "Les tremblements de terre sont désactivés",
  earthquakes_on = "Les tremblements de terre sont activés"
}

-- Main menu
main_menu = {
  new_game = "Nouvelle partie",
  custom_level = "Niveau personnalisé",
  continue = "Continuer la partie",
  load_game = "Charger une partie",
  options = "Options",
  savegame_version = "Version de la sauvegarde : ",
  version = "Version : ",
  exit = "Quitter",
  map_edit = "Éditeur de carte",
  custom_campaign = "Campagne personnalisée",
  updates_off = "Ne pas vérifier les mises à jour"
}

tooltip.main_menu = {
  new_game = "Commencer une nouvelle partie",
  custom_level = "Construire votre hôpital dans un niveau personnalisé",
  continue = "Continuer la partie",
  load_game = "Charger une partie sauvegardée",
  options = "Modifier quelques paramètres",
  exit = "Non, non, SVP, ne quittez pas !",
  map_edit = "Créer une carte personnalisée",
  custom_campaign = "Jouer une campagne créée par la communauté",
  quit = "Vous êtes sur le point de quitter CorsixTH. Voulez-vous vraiment faire cela ?",
}

-- Load game window
load_game_window = {
  caption = "Charger une partie (%1%)",
  load_button = "Charger",
}

tooltip.load_game_window = {
  load_game = "Charger la partie %s",
  load_game_number = "Charger la partie %d",
  load_autosave = "Charger la sauvegarde automatique"
}

-- Custom game window
custom_game_window = {
  caption = "Niveau personnalisé",
  free_build = "Construction libre",
  load_selected_level = "Démarrer"
}

tooltip.custom_game_window = {
  free_build = "Cochez cette case si vous souhaitez jouer sans limite d'argent et sans conditions de victoire ou de défaite",
  choose_game = "Cliquez sur un niveau pour en savoir plus",
  load_selected_level = "Charger et jouer le niveau sélectionné"
}

-- Custom campaign window
custom_campaign_window = {
  caption = "Campagne personnalisée",
  start_selected_campaign = "Démarrer la campagne"
}

tooltip.custom_campaign_window = {
  choose_campaign = "Choisissez une campagne pour en savoir plus à son sujet",
  start_selected_campaign = "Charger le premier niveau de cette campagne"
}

-- Save game window
save_game_window = {
  caption = "Sauvegarder la partie (%1%)",
  new_save_game = "Nouvelle sauvegarde",
  save_button = "Sauvegarder",
  missing_filename = "Veuillez indiquer un nom pour la nouvelle sauvegarde ou sélectionner la sauvegarde à écraser.",
}

tooltip.save_game_window = {
  save_game = "Écraser la sauvegarde %s",
  new_save_game = "Entrez un nom pour la sauvegarde"
}

save_map_window = {
  caption = "Sauvegarder la carte (%1%)",
  new_map = "Nouvelle carte",
  save_button = "Sauvegarder",
  missing_filename = "Veuillez indiquer un nom pour le fichier de carte ou sélectionner le fichier de carte à écraser.",
}

tooltip.save_map_window = {
  map = "Ecraser la carte %s",
  new_map = "Entrez le nom pour une sauvegarde de la carte"
}

load_map_window = {
  caption = "Charger la carte (%1%)",
  load_button = "Charger",
}

-- Menu list window
menu_list_window = {
  back = "Précédent",
  save_date = "Modifié",
  name = "Nom",
  ok = "OK"
}

tooltip.menu_list_window = {
  back = "Fermer cette fenêtre",
  save_date = "Cliquez ici pour classer la liste par date de dernière modification",
  name = "Cliquez ici pour classer la liste par par nom",
  ok = "Confirmer le choix"
}

-- Options window
options_window = {
  back = "Précédent",
  caption = "Paramètres",
  capture_mouse = "Capture de la souris",
  check_for_updates = "Vérifier mises à jour",
  customise = "Personnaliser",
  folder = "Dossier",
  hotkey = "Touches de raccourci",
  language = "Langue du jeu",
  option_disabled = "Désactivé",
  option_enabled = "Activé",
  option_off = "Désactiver",
  option_on = "Activer",
  scroll_speed = "Vitesse de défilement",
  shift_scroll_speed = "Vit. de défil. + Maj",
  zoom_speed = "Vitesse de zoom",
  right_mouse_scrolling = "Défilement Souris",
  right_mouse_scrolling_option_middle = "Bouton Milieu",
  right_mouse_scrolling_option_right = "Bouton Droit",
  sound = "Son",
  autosave_frequency = "Fréquence sauv. auto.",
}
graphics_window = {
  fullscreen = "Plein écran",
  ui_scale = "Échelle d'interface",
  width = "Largeur",
  height = "Hauteur",
  option_on = "Activer",
  option_off = "Désactiver",
  apply = "Appliquer",
  cancel = "Annuler",
}

autosave_frequency = {
    monthly = "Mensuelle",
    weekly = "Hebdomadaire",
    daily = "Quotidienne",
}

tooltip.autosave_frequency = {
    monthly = "Sauvegarder une fois par mois, le premier jour de chaque mois. Un total de 12 sauvegardes sur une période d'un an.",
    weekly = "Sauvegarder une fois par semaine le 1er, 7ème, 14ème, 21ème, et 28ème jour de chaque mois. Un total de 60 sauvegardes sur une période d'un an.",
    daily = "Sauvegarder une fois par jour au début de chaque journée en jeu. Un total de 365 sauvegardes sur une période d'un an. Veuillez noter qu'une sauvegarde classique peut avoir un poids de 1 Mo ou plus, votre dossier Autosaves pourrait donc peser 300-500 Mo.",
}

tooltip.options_window = {
  ui_scale_unavailable = "Échelle d'interface indisponible, veuillez d'abord choisir une résolution plus élevée.",
  language = "Utiliser la langue %s",
  back = "Fermer la fenêtre des options",
  language_dropdown_item = "Choisir %s comme langue",
  select_language = "Sélectionner la langue du jeu",
  folder = "Dossier des paramètres",
  customise = "Paramètres supplémentaires qui peuvent être modifiés pour personnaliser votre expérience de jeu",
  hotkey = "Modifier les touches de raccourci du clavier.",
  check_for_updates = "Choisir si le jeu doit rechercher des mises à jour au démarrage.",
  capture_mouse = "Cliquez pour activer la capture du curseur dans la fenêtre du jeu.",
  language_dropdown_no_font = "Sélectionnez une police d'écriture dans les paramètres pour activer ce langage",
  right_mouse_scrolling = "Activer le bouton qui est utilisé pour faire défiler la carte",
  sound = "Modifier les réglages audio",
  autosave_frequency = "Définir la fréquence des sauvegardes automatiques.",
}
tooltip.graphics_window = {
  fullscreen = "Mode plein écran ou mode fenêtré",
  fullscreen_button = "Basculer en mode plein écran/fenêtré",
  ui_scale = "Mise à l'échelle de l'interface. Seules les options d'échelle applicables à votre écran sont disponibles. Augmentez la résolution pour plus d'options.",
  select_ui_scale = "Sélectionner une échelle d'interface",
  width = "Entrez la largeur désirée",
  height = "Entrez la hauteur désirée",
  apply = "Appliquer la résolution choisie",
  cancel = "Retour sans changement de résolution",
}

audio_window = {
  caption = "Paramètres sonores",
  audio = "Audio global",
  sound_volume = "Volume des sons",
  announcement_volume = "Volume des annonces",
  music_volume = "Volume de la musique",
  midi_api = "API MIDI",
  midi_port = "Port MIDI",
  soundfont = "SoundFont",
  default_midi_api = "Défaut (Software)",
  default_midi_port = "Défaut",
  jukebox = "Jukebox",
  back = "Précédent",
  soundfont_location_caption = "Choisir la soundfont (%1%)",
}

tooltip.audio_window = {
  audio_button = "Activer ou désactiver le système audio dans le jeu",
  audio_toggle = "Activer ou désactiver",
  sound_volume = "Volume des effets sonores",
  announcement_volume = "Volume des annonces",
  music_volume = "Volume de la musique",
  midi_api = "L'API utilisée pour la musique en jeu. Non disponible avec le dossier de musiques personnalisées.",
  midi_port = "Port système à utiliser pour la musique en jeu.",
  soundfont_location = "Emplacement du fichier Soundfont pour jouer la musique MIDI. Une Soundfont par défaut est utilisée si aucune n'est spécifiée.",
  browse = "Parcourir les dossiers",
  browse_soundfont = "Rechercher un autre fichier Soundfont (sf2, or sf3) ( Emplacement actuel: %1% ) ",
  no_soundfont_specified = "Utiliser la soundfont par défaut",
  jukebox = "Ouvrir le Jukebox pour changer la musique",
  back = "Fermer la fenêtre",
}

customise_window = {
  caption = "Paramètres Additionnels",
  option_on = "Activer",
  option_off = "Désactiver",
  back = "Retour",
  movies = "Contrôle des cinématiques",
  play_intro = "Jouer la cinémat. d'intro",
  allow_user_actions_while_paused = "Construction en pause",
  alien_dna_only_by_emergency = "Extraterrestres",
  disable_fractured_bones_females = "Fractures",
  enable_avg_contents = "Achats mémorisés",
  remove_destroyed_rooms = "Suppr. les salles détruites",
  machine_menu_button = "Bouton menu des machines",
  every_month = "Chaque mois",
  alien_dna_only_by_emergency_on = "Urgence seulement",
  every_day = "Chaque jour",
  enable_announcer_subtitles = "Sous-titres des annonces",
  disable_fractured_bones_females_on = "Homme seulement",
  alien_dna_only_by_emergency_off = "Patients normaux",
  enable_screen_shake = "Vibration de l'écran",
  disable_fractured_bones_females_off = "Homme et Femme",
}

tooltip.customise_window = {
  movies = "Sélectionnez si les cinématiques doivent être joués.",
  play_intro = "Passer la cinématique d'introduction lorsque vous démarrez le jeu. Le contrôle des cinématiques doit être activé si vous jouez la cinématique d'introduction à chaque fois que vous chargez CorsixTH",
  allow_user_actions_while_paused = "Dans Theme Hospital, le joueur ne pouvait utiliser le menu supérieur que si le jeu était en pause. Il s'agit également du paramètre par défaut dans CorsixTH, mais activant cette option, il est possible de construire des salles ou prendre des objets lorsque le jeu est en pause",
  alien_dna_only_by_emergency = "Comme il y a des animations appropriées, nous avons fait de sorte que les patients avec l'ADN extraterrestre montrent seulement comme des situations d'urgence. Désactivez cette option pour obtenir cas de l'ADN extraterrestre visites régulières",
  disable_fractured_bones_females = "En raison de la faible qualité de l'animation, il n'y a pas de patientes avec des fractures. Désactivez cette option pour recevoir des femmes avec des fractures.",
  enable_avg_contents = "Si vous voulez que le jeu se rappelle des articles supplémentaires que vous avez tendance à normalement magasiner pour une nouvelle salle, activer cette option",
  remove_destroyed_rooms = "Si vous souhaitez pouvoir retirer les salles détruites, moyennant paiement, activez cette option",
  machine_menu_button = "Si vous désirez afficher un bouton pour le menu des machines dans le panneau inférieur, activez cette option. Gardez à l'esprit que ce bouton ne sera pas disponible sur des petites résolutions d'écran.",
  enable_screen_shake = "Les tremblements de terre feront vibrer tout l'écran. Si vous préférez que l'écran reste fixe, désactivez cette option",
  enable_announcer_subtitles = "Si vous souhaitez afficher des sous-titres pour les annonces de l'hôpital, activez cette option",
  back = "Fermer ce menu et revenir au menu d'options",
}

folders_window = {
  caption = "Paramètres de dossier",
  data_label = "Données de TH",
  font_label = "Police",
  music_label = "MP3",
  savegames_label = "Sauvegarde",
  screenshots_label = "Captures d'écran",
  -- next four are the captions for the browser window, which are called from the folder setting menu
  new_th_location = "Ici vous pouvez spécifier un nouveau répertoire d'installation de Theme Hospital. Dès que vous choisissez le nouveau répertoire, le jeu sera redémarré.",
  savegames_location = "Sélectionner le répertoire que vous voulez utiliser pour les sauvegardes",
  music_location = "Sélectionner le répertoire que vous voulez utiliser pour la musique",
  screenshots_location = "Sélectionner le répertoire que vous voulez utiliser pour les captures d'écran",
  back = "Retour"
}

tooltip.folders_window = {
  browse = "Parcourir l'emplacement du dossier",
  data_location = "Le répertoire d'origine de l'installation de Theme Hospital, qui est requis pour faire fonctionner CorsixTH",
  font_location = "Emplacement d'un fichier de police qui est capable d'afficher des caractères Unicode requises par votre langue. Si aucun emplacement n'est spécifié vous ne serez pas en mesure de choisir des langues qui ont des caractères que le jeu original ne peut pas fournir. Exemple : Russe et Chinois",
  savegames_location = "Par défaut, le répertoire de sauvegardes est à côté du fichier de configuration et sera utilisé pour stocker les sauvegardes. Si cela n'est pas approprié vous pouvez modifier ce répertoire.",
  screenshots_location = "Par défaut, les captures d'écran sont stockés dans un dossier avec le fichier de configuration. Si cela ne convient pas vous pouvez choisir votre propre dossier.",
  music_location = "Sélectionnez un emplacement pour vos fichiers MP3.",
  browse_data = "Parcourir un autre emplacement d'une installation de Theme Hospital (emplacement actuel : %1%)",
  browse_font = "Parcourir un autre fichier de police (emplacement actuel : %1%)",
  browse_saves = "Parcourir un autre répertoire de sauvegardes (emplacement actuel : %1%)",
  browse_screenshots = "Parcourir un autre répertoire de captures d'écrans (emplacement actuel : %1%)",
  browse_music = "Parcourir un autre répertoire de musique (emplacement actuel : %1%)",
  no_font_specified = "Aucun répertoire de police spécifié !",
  not_specified = "Aucun répertoire spécifié !",
  default = "Emplacement par défaut",
  reset_to_default = "Réinitialiser le répertoire à son emplacement par défaut (%1%)",
  back = "Fermer ce menu et revenir au menu Paramètres"
}

accessibility_window = {
  scrollspeed = "Vitesse de défilement",
  shift_scrollspeed = "Vitesse de défilement avec Maj",
  zoom_speed = "Zoom Speed",
}

tooltip.accessibility_window = {
  apply_shift_scrollspeed = "Appliquer la vitesse de défilement en mode Maj.",
  shift_scrollspeed = "Définir la vitesse de défilement lorsque la touche Maj est enfoncée. De 1 (la plus lente) à 10 (la plus rapide). La valeur par  défaut est 4.",
  zoom_speed = "Définir la vitesse de zoom de la caméra de 10 (la plus lente) à 1000 (la plus rapide). La valeur par défaut est 80.",
  cancel_zoomspeed = "Revenir sans changer la vitesse de zoom.",
  apply_zoomspeed = "Appliquer la vitesse de zoom choisie.",
  cancel_scrollspeed = "Revenir sans changer la vitesse de défilement.",
  cancel_shift_scrollspeed = "Revenir sans changer la vitesse de défilement de la touche Maj.",
  scrollspeed = "Réglez la vitesse de défilement de 1 (la plus lente) à 10 (la plus rapide). La valeur par défaut est 2.",
  apply_scrollspeed = "Appliquer la vitesse de défilement entrée.",
}

font_location_window = {
  caption = "Choisir une police (%1%)"
}

-- Handyman window
handyman_window = {
  all_parcels = "Partout",
  parcel = "Parcelle"
}

tooltip.handyman_window = {
  parcel_select = "Les parcelles où les agents de maintenance peuvent travailler : cliquez pour changer le paramètre."
}

--- New game window
new_game_window = {
  easy = "Interne (Facile)",
  medium = "Médecin (Moyen)",
  hard = "Consultant (Difficile)",
  tutorial = "Tutoriel",
  cancel = "Annuler",
  option_on = "Activer",
  option_off = "Désactiver",
  difficulty = "Difficulté",
  caption = "Campagne",
  player_name = "Nom du joueur",
  start = "Démarrer"
}

tooltip.new_game_window = {
  easy = "Si vous jouez pour la première fois à un jeu de simulation, cette option est pour vous",
  medium = "C'est la voie du milieu à prendre si vous ne savez pas quoi choisir",
  hard = "Si vous êtes habitué à ce genre de jeu et que vous souhaitez plus d'un défi, choisissez cette option",
  tutorial = "Si vous voulez un peu d'aide pour démarrer une fois dans le jeu, cochez cette case",
  cancel = "Oh, je n'avais pas vraiment l'intention de commencer une nouvelle partie !",
  difficulty = "Sélectionnez le niveau de difficulté que vous voulez dans le jeu",
  start = "Démarrer le jeu avec les paramètres sélectionnés",
  player_name = "Entrez le nom par lequel vous voulez être appelé dans le jeu"
}

-- Lua Console
lua_console = {
  execute_code = "Exécuter",
  close = "Fermer"
}

tooltip.lua_console = {
  textbox = "Entrez du code Lua à exécuter ici",
  execute_code = "Exécuter le code que vous avez entré",
  close = "Fermer la console"
}

-- Errors
errors = {
  dialog_missing_graphics = "Désolé, les données de démo ne contiennent pas cette boîte de dialogue.",
  save_prefix = "Erreur lors de la sauvegarde de la partie : ",
  load_prefix = "Erreur lors du chargement de la partie : ",
  load_map_prefix = "Erreur pendant le chargement de la carte: ",
  load_level_prefix = "Erreur pendant le chargement du niveau: ",
  no_games_to_contine = "Pas de parties sauvegardées.",
  map_file_missing = "Impossible de trouver le fichier de carte %s pour ce niveau !",
  minimum_screen_size = "Veuillez entrer une résolution supérieure à %dx%d.",
  unavailable_screen_size = "La résolution que vous avez demandée n'est pas disponible en plein écran.",
  alien_dna_only_by_emergency = "NOTE : Il n'y a pas d'animations pour les patients étrangers pour s'asseoir, ouvrir ou de frapper aux portes, etc. Donc, comme avec Theme Hospital pour faire ces choses, ils semblent changer à la normale et ensuite changer de nouveau. Les patients avec l'ADN Alien apparaîtront seulement s'ils sont définis dans le fichier de niveau.",
  disable_fractured_bones_females = "NOTE : L'animation pour les patients de sexe féminin avec des os fracturés n'est pas parfaite.",
  load_quick_save = "Erreur, impossible de charger la sauvegarde rapide car elle n'existe pas, ne vous inquiétez pas nous avons créé une pour vous !",
  could_not_find_first_campaign_level = "Impossible de trouver le premier niveau de cette campagne : %s",
  save_to_tmp = "Le fichier à l'emplacement %s n'a pas pu être utilisé. Le jeu a été enregistré sous %s. Erreur : %s",
  could_not_load_campaign = "Échec du chargement de la campagne : %s",
  dialog_empty_queue = "Désolé, un être humain vient d'avoir une file d'actions vide, ce qui signifie qu'il ne savait pas quoi faire ensuite. Veuillez consulter la fenêtre de commande pour des informations plus détaillées. Un dialogue avec l'individu fautif a été ouvert. Souhaitez-vous qu'il quitte l'hôpital ?",

  compatibility_error = {
    new_in_old = "Désolé, cette sauvegarde a été créée avec une version plus récente de CorsixTH et n'est pas compatible. Veuillez mettre à jour vers une version plus récente.",
    full_in_demo = "Désolé, vous ne pouvez pas ouvrir une sauvegarde de jeu complet avec les fichiers de démonstration chargés. Veuillez mettre à jour votre paramètre de dossier TH Data.",
    demo_in_full = "Désolé, vous ne pouvez pas ouvrir une sauvegarde de démonstration avec les fichiers de jeu complet chargés. Veuillez mettre à jour votre paramètre de dossier TH Data."
  }
}

-- Confirmation dialog
confirmation = {
  needs_restart = "Changer ce paramètre va nécessiter un redémarrage de CorsixTH. Tout progrès non sauvegardé sera perdu. Voulez-vous vraiment faire cela ?",
  abort_edit_room = "Vous êtes actuellement en train de construire ou d'éditer une pièce. Si tous les objets requis sont placés, elle sera validée, mais sinon elle sera détruite. Continuer ?",
  maximum_screen_size = "La taille de l'écran que vous avez entrée est supérieure à 3000 x 2000. Des plus hautes résolutions sont possibles, mais il faudra un meilleur matériel afin de maintenir un taux de trame jouable. Voulez-vous vraiment continuer ?",
  remove_destroyed_room = "Souhaitez-vous supprimer la salle pour %d $ ?",
  replace_machine_extra_info = "La nouvelle machine aura une puissance de %d (actuellement %d).",
  restart_mapeditor = "Voulez-vous vraiment relancer l'éditeur de cartes ?",
  quit_mapeditor = "Voulez-vous vraiment quitter l'éditeur de cartes ?",
  very_old_save = "Il y a eu de nombreuses mises à jour du jeu depuis que vous avez commencé. Pour être sûr que toutes les fonctionnalités fonctionnent comme prévu, voudriez-vous recommencer ce niveau maintenant ?//"..
  "Votre ancienne sauvegarde ne sera pas supprimée à moins que vous ne l'écrasiez."
}

-- Information dialog
information = {
  custom_game = "Bienvenue dans CorsixTH. Amusez-vous bien avec cette carte personnalisée !",
  no_custom_game_in_demo = "Désolé, mais dans la version démo vous ne pouvez jouer avec aucune des cartes personnalisées.",
  cannot_restart = "Malheureusement cette partie personnalisée a été sauvegardée avant que la fonctionnalité de redémarrage soit implémentée.",
  very_old_save = "Il y a eu beaucoup de mises à jour du jeu depuis que vous avez commencé ce niveau. Pour être sûr que tout fonctionne comme prévu, pensez à recommencer le niveau.",
  cheat_not_possible = "Vous ne pouvez pas utiliser ce code de triche dans ce niveau.",
  level_lost = {
    "Quelle poisse ! Vous avez raté le niveau. Vous ferez mieux la prochaine fois !",
    "Voilà pourquoi vous avez perdu : ",
    reputation = "Votre réputation est tombée en dessous de %d.",
    balance = "Votre solde bancaire est tombé en dessous %d.",
    percentage_killed = "Vous avez tué plus de %d pourcents de vos patients.",
    cheat = "J'espère que vous n'avez pas cliqué sur le bouton \" Perdre le niveau \" par accident !"
  }
}

tooltip.information = {
  close = "Fermer cette boîte de dialogue."
}

-- "Tip of the day" window
totd_window = {
  tips = {
    "Chaque hôpital a besoin d'un bureau de réception et d'un cabinet de médecine générale. Après, tout dépend du type de patients qui visitent votre hôpital. Une pharmacie est toujours un bon choix malgré tout.",
    "Les machines telles que le Gonflage ont besoin de maintenance. Embauchez un ou deux agents de maintenance pour réparer vos machines, ou vous risquerez d'avoir des blessés parmi le personnel ou les patients.",
    "Après un certain temps, vos employés seront fatigués. Pensez à construire une salle de repos où ils pourront se détendre.",
    "Placez suffisamment de radiateurs pour garder vos employés et patients au chaud, ou ils deviendront mécontents. Utilisez la carte de la ville pour localiser les endroits de votre hôpital qui nécessitent plus de chauffage.",
    "Le niveau de compétence d'un docteur influence beaucoup la qualité et la rapidité de ses diagnostics. Utilisez un médecin expérimenté comme généraliste et vous n'aurez plus besoin d'autant de salles de diagnostics.",
    "Les internes et les médecins peuvent augmenter leurs compétences auprès d'un consultant dans la salle de formation. Si le consultant a des qualifications particulières (chirurgien, psychiatre ou chercheur), il transférera ses connaissances à ses élèves.",
    "Avez-vous essayé d'entrer le numéro d'urgence Européen (112) dans le fax ? Vérifiez que vous avez du son !",
    "Vous pouvez ajuster certains paramètres tels que la résolution et la langue dans la fenêtre d'options accessible à la fois depuis le menu principal et pendant le jeu.",
    "Vous avez choisi une autre langue que l'anglais, mais des textes en anglais s'affichent un peu partout ? Aidez-nous à traduire les textes manquants dans votre langue !",
    "L'équipe de CorsixTH cherche du renfort ! Vous êtes intéressé pour coder, traduire ou créer des graphismes pour CorsixTH ? Contactez-nous sur notre serveur Discord, Sub-Reddit ou serveur Matrix. Les liens sont sur notre site internet (CorsixTH.com).",
    "Si vous rencontrez un bug, n'hésitez pas à nous le signaler à cette adresse : th-issues.corsix.org",
    "Chaque niveau possède des objectifs qu'il vous faudra remplir pour pouvoir passer au suivant. Vérifiez la fenêtre de statuts pour voir votre progression dans les objectifs du niveau.",
    "Si vous voulez éditer ou détruire une pièce, vous pouvez le faire avec le bouton d'édition situé sur la barre d'outils inférieure.",
    "Dans un groupe de patients en attente, vous pouvez rapidement découvrir lesquels attendent une pièce particulière en survolant cette pièce avec votre curseur de souris.",
    "Cliquez sur la porte d'une pièce pour visualiser sa file d'attente. Vous pouvez faire des réglages très utiles ici, comme réorganiser la file d'attente ou envoyer un patient vers une autre pièce.",
    "Le personnel mécontent vous demandera des augmentations de salaires fréquemment. Assurez-vous de leur offrir un environnement de travail confortable pour éviter cela.",
    "Les patients auront soif en attendant dans votre hôpital, encore plus si vous augmentez le chauffage ! Placez des distributeurs automatiques dans les points stratégiques pour un revenu d'appoint.",
    "Vous pouvez interrompre le processus de diagnostic d'un patient et proposer un traitement, si vous avez déjà rencontré la maladie. Notez que cela peut accroître le risque d'erreur de traitement, et provoquer la mort du patient.",
    "Les urgences peuvent être une bonne source de revenus additionnels, à condition que vous ayez les capacités suffisantes pour traiter les patients à temps.",
    "Saviez-vous que vous pouvez affecter des Agents d'entretien à des parcelles spécifiques ? Cliquez simplement sur le texte 'Toutes les parcelles' dans leur profil du personnel pour les parcourir !",
  },
  previous = "Astuce précédente",
  next = "Astuce suivante"
}

tooltip.totd_window = {
  previous = "Afficher l'astuce précédente",
  next = "Afficher l'astuce suivante"
}

-- Debug patient window
tooltip.debug_patient_window.item = "Créer un patient de débogage avec %s"
debug_patient_window = {
  caption = "Patient de test"
}

-- Cheats window
cheats_window = {
  caption = "Triches",
  warning = "Attention : vous n'aurez aucun point de bonus à la fin du niveau si vous trichez !",
  cheated = {
    no = "Triches utilisées : non",
    yes = "Triches utilisées : oui"
  },
  cheats = {
    money = "Plus d'argent",
    all_research = "Toutes les recherches",
    emergency = "Créer une situation d'urgence",
    vip = "Créer un VIP",
    earthquake = "Créer un tremblement de terre",
    create_patient = "Créer un patient",
    end_month = "Fin du mois",
    end_year = "Fin de l'année",
    lose_level = "Perdre le niveau",
    win_level = "Gagner le niveau",
    epidemic = "Reproduire des patients contagieux",
    toggle_infected = "Faire apparaître des patients contagieux.",
    increase_prices = "Augmenter les prix",
    decrease_prices = "Diminuer les prix",
    reset_death_count = "Remettre à zéro le nombre de décès",
    toggle_epidemic = "Active la possibilité d'épidémies",
    show_infected = "Montrer les icônes des infectés",
    toggle_earthquake = "Activer les tremblements de terre",
    max_reputation = "Réputation de l'hôpital au maximum",
    repair_all_machines = "Réparer toutes les machines",
    toggle_invulnerable_machines = "Machines inusables on/off",
  },
  close = "Fermer"
}

tooltip.cheats_window = {
  close = "Fermer le dialogue de triches",
  cheats = {
    money = "Ajoute $10.000 à votre solde bancaire.",
    all_research = "Termine toutes les recherches.",
    emergency = "Crée une situation d'urgence.",
    vip = "Crée un VIP.",
    earthquake = "Crée un tremblement de terre.",
    create_patient = "Crée un patient au bord de la carte.",
    end_month = "Va directement à la fin du mois.",
    end_year = "Va directement à la fin de l'année.",
    lose_level = "Vous fait perdre le niveau actuel.",
    win_level = "Vous fait gagner le niveau actuel.",
    epidemic = "Crée un patient contagieux qui peut causer une épidémie.",
    toggle_infected = "Bascule les icônes infectés pour l'épidémie, découverte active.",
    increase_prices = "Augmenter tous les prix de 50% (max. 200%)",
    decrease_prices = "Diminuer tous les prix de 50% (min. 50%)",
    reset_death_count = "Remettre à zéro le nombre de décès à l'hôpital",
    toggle_epidemic = "Activer/Désactiver la possibilité d'épidémies",
    show_infected = "Montrer/Cacher les icônes des infectés pour les épidémies découvertes et actives",
    toggle_earthquake = "Activer/Désactiver les tremblements de terre",
    max_reputation = "Augmenter la réputation de l'hôpital au maximum",
    repair_all_machines = "Réparer toutes les machines dans l'hôpital",
    toggle_invulnerable_machines = "Activer/Désactiver l'usure des machines lors de leur utilisation",
  }
}

-- Introduction Texts
introduction_texts = {
  demo = "Bienvenue dans l'hôpital de démonstration !// " .. "Malheureusement, la version démo ne contient que ce niveau. Malgré tout, il y a assez à faire ici pour vous occuper un moment !" .. "Vous allez rencontrer différentes maladies qui nécessitent des salles pour les soigner. De temps en temps, des urgences peuvent se produire. Et vous aurez besoin d'une salle de recherche pour trouver des nouvelles salles. " ..
      "Votre but est de gagner 100,000$, de faire monter la valeur de votre hôpital à 70,000$ et d'obtenir une réputation de 700, tout en ayant soigné au moins 75% de vos patients. " .. "Veillez à ce que votre réputation ne tombe pas en dessous de 300 et de ne pas tuer plus de 40% de vos patients, ou vous perdrez.//" .. "Bonne chance !",
  level1 = "Bienvenue dans votre premier hôpital !//Démarrez l'activité en installant un bureau de réception et " .. "en construisant un cabinet de médecine générale. Embauchez une réceptionniste et un médecin. Il vous " .. "suffit d'attendre des admissions. Il serait bon de construire un cabinet de psychiatrie et d'embaucher " .. "un médecin formé dans ce domaine. Une pharmacie et une infirmière sont également indispensables pour soigner " ..
      "les patients. Attention aux cas d'encéphalantiasis : une salle de gonflage suffit pour traiter cette maladie. " .. "Il vous faut soigner 10 personnes et vous assurer que votre réputation ne tombe pas en-dessous de 200.",
  level8 = "A vous de gérer l'hôpital le plus efficace et le plus rentable possible.//Les gens du coin sont bien nantis alors " .. "pompez-leur tout le fric que vous pourrez. Soigner les gens c'est bien joli mais vous avez BESOIN de l'argent que ça " .. "rapporte. Ratissez tous ces malades ! Amassez un joli paquet de $300.000 pour terminer ce niveau.",
  level12 = "Côté défi, vous allez être servi ! Impressionné par votre succès, le Ministère veut vous assigner une mission de confiance. " .. "Vous devrez construire un autre hôpital de pointe, gagner des sommes scandaleuses et vous faire une réputation fabuleuse. " .. "Vous devrez également acheter tout le terrain possible, soigner toutes les maladies (nous avons bien dit TOUTES) et remporter " ..
      "toutes les récompenses. Alors, heureux ? Gagnez $650.000, soignez 750 personnes et affichez une réputation de 800 pour gagner ce niveau.",
  level13 = "Votre incroyable talent en tant que directeur d'hôpital a attiré l'attention de la Division Spéciale Secrète des " .. "Services Spéciaux Secrets. On vous propose un bonus : il y a un hôpital infesté de rats qui réclame un Nettoyeur efficace. " .. "Vous devez descendre le plus de rats possible avant que les agents de maintenance fassent leur boulot. Vous pensez y arriver ?",
  level14 = "Et encore un défi ! Eh oui, voici l'hôpital-surprise ! Si vous réussissez cette épreuve, vous serez le gagnant des gagnants. " .. "Mais ça ne sera pas du gâteau car vous n'aviez encore rien vu de pareil... Bonne chance !",
  level17 = "Un bon conseil : veillez à votre réputation car c'est elle qui vous garantira une clientèle. Si vous ne tuez pas trop de " .. "gens et les gardez raisonnablement satisfaits, vous n'aurez pas trop de difficultés à ce niveau. //A vous de jouer, maintenant. " .. "Bonne chance et tout ça, quoi !"
}

-- Calls Dispatcher Dialog
calls_dispatcher = {
  -- Dispatcher description message. Visible in Calls Dispatcher dialog
  summary = "%d appels; %d assignés",
  staff = "%s - %s",
  watering = "Arrose @ %d,%d",
  repair = "Répare %s",
  close = "Fermer"
}

tooltip.calls_dispatcher = {
  task = "Liste des tâches - cliquez sur une tâche pour ouvrir la fenêtre du membre du personnel à qui elle est assignée et aller jusqu'à l'endroit où a lieu la tâche.",
  assigned = "Cette case est cochée si la tâche est assignée à quelqu'un.",
  close = "Ferme la boîte de dialogue de répartitions des tâches"
}

machine_menu = {
  percentage = "%d%",
  machine = "Machine",
  status = "Statut",
  remaining_strength = "Restant",
  total_strength = "Résistance",
  ratio = "Ratio",
  close = "Fermer",
}

tooltip.machine_menu = {
  sort = "Cliquer pour trier selon cette valeur.",
  machine = "Liste des machines – Cliquer pour ouvrir la fenêtre de la machine et se rendre à son emplacement.",
  smoking = "Cette case est cochée si la machine risque d'exploser. Cliquer pour acheter une nouvelle machine.",
  assigned = "Cette case est cochée si un agent d'entretien est affecté à la réparation de la machine correspondante. Cliquer pour afficher l'agent assigné.",
  remaining_strength = "Cette valeur indique la résistance restante de la machine.",
  total_strength = "Cette valeur indique la résistance totale de la machine.",
  ratio = "Cette valeur indique le rapport entre la résistance restante et la résistance totale.",
  header = {
    smoking = "Indicateur de danger",
    assigned = "Indicateur d'affectation à la réparation",
    machine = "Nom de la machine",
    remaining_strength = "Résistance restante des machines.",
    total_strength = "Résistance totale des machines.",
    ratio = "Pourcentage de résistance restante par rapport à la résistance totale des machines.",
    status = "Statuts des machines.",
  },
  close = "Fermer la fenêtre de la liste des machines.",
}

adviser_history = {
  message = "Messages",
  close = "Fermer",
}

tooltip.adviser_history = {
  delete_message = "Cliquer pour supprimer ce message",
  message = "Liste des messages du conseiller - Les messages les plus récents sont en tête de liste",
  header = {
    message = "Messages du conseiller",
    delete_message = "Cliquer pour supprimer tous les messages"
  },
  close = "Fermer la fenêtre Récapitulatif du conseiller",
}

-- Updates
update_window = {
  caption = "Une mise à jour est disponible !",
  new_version = "Nouvelle version :",
  current_version = "Version actuelle :",
  download = "Aller à la page de téléchargement",
  ignore = "Sauter et aller au menu principal"
}

tooltip.update_window = {
  download = "Accédez à la page de téléchargement pour la toute dernière version de CorsixTH",
  ignore = "Ignorer cette mise à jour pour l'instant. Vous serez averti à nouveau lorsque vous ouvrez CorsixTH de nouveau"
}

map_editor_window = {
  pages = {
    inside = "Intérieur",
    outside = "Extérieur",
    foliage = "Feuillage",
    hedgerow = "Haie",
    pond = "Étang",
    road = "Route",
    north_wall = "Mur nord",
    west_wall = "Mur ouest",
    helipad = "Héliport",
    delete_wall = "Suppr. des murs",
    parcel = "Parcelle %d",
    parcel_0 = "Parcelle 0",
    parcel_1 = "Parcelle 1",
    parcel_2 = "Parcelle 2",
    parcel_3 = "Parcelle 3",
    parcel_4 = "Parcelle 4",
    parcel_5 = "Parcelle 5",
    parcel_6 = "Parcelle 6",
    parcel_7 = "Parcelle 7",
    parcel_8 = "Parcelle 8",
    parcel_9 = "Parcelle 9",
    camera_1 = "Caméra 1",
    camera_2 = "Caméra 2",
    camera_3 = "Caméra 3",
    camera_4 = "Caméra 4",
    heliport_1 = "Héliport 1",
    heliport_2 = "Héliport 2",
    heliport_3 = "Héliport 3",
    heliport_4 = "Héliport 4",
    paste = "Coller la zone",
    set_parcel_tooltip = "Choissisez un chiffre et appuyez sur Entrée.",
    set_parcel = "Choisir le chiffre de la parcelle",
  },
  checks = {
    spawn_points_and_path = "Attention: les patients ne peuvent pas arriver à l'hôpital. Ils ont besoin de carreaux 'route' ou carreaux gris 'dehors' au bord de la carte et un chemin avec ces carreaux jusqu'à l'entrée de l'hôpital."
  }
}

menu.player_count = "COMPTE DE JOUEURS"
warnings.levelfile_variable_is_deprecated = "Remarque: Le niveau '%s' contient une définition de variable obsolète dans le fichier de niveau. '%LevelFile' a été renommé '%MapFile'. Veuillez aviser le créateur de la carte pour mettre à jour le niveau."
warnings.newersave = "Avertissement, vous avez chargé une sauvegarde d'une version plus récente de CorsixTH. Il n'est pas recommandé de continuer car des plantages peuvent survenir. Jouez à vos propres risques."

hotkeys_file_err = {
  file_err_02 = ", ou utilisez l'option de ligne de commande --hotkeys-file=nomdufichier pour spécifier un fichier inscriptible. Pour référence, l'erreur lors du chargement du fichier de raccourcis était : ",
  file_err_01 = "Impossible de charger le fichier hotkeys.txt. Assurez-vous que CorsixTH a l'autorisation de lecture/écriture "
}

hotkey_window = {
  button_accept = "Accepter",
  button_back = "Retour",
  button_cancel = "Annuler",
  button_defaults = "Réinit. aux valeurs par défaut",
  button_gameSpeedKeys = "Touches de vitesse du jeu",
  button_recallPosKeys = "Touches de rappel de position",
  button_toggleKeys = "Activer/désactiver les touches",
  caption_main = "Définir les touches de raccourci",
  caption_panels = "Touches des panneaux",
  global_cancel = "Annuler",
  global_cancel_alt = "Annuler Alt",
  global_confirm = "Confirmer",
  global_confirm_alt = "Confirmer Alt",
  global_connectDebugger = "Débogueur",
  global_exitApp = "Quitter l'application",
  global_fullscreen_toggle = "Plein écran",
  global_releaseMouse = "Relâcher la souris",
  global_resetApp = "Réinitialiser l'application",
  global_runDebugScript = "Script de débogage",
  global_screenshot = "Capture d'écran",
  global_showLuaConsole = "Console Lua",
  global_stop_movie_alt = "Arrêter le film",
  global_window_close_alt = "Fermer la fenêtre",
  ingame_gamespeed_max = "Max",
  ingame_gamespeed_normal = "Normale",
  ingame_gamespeed_slower = "Plus lente",
  ingame_gamespeed_slowest = "La plus lente",
  ingame_gamespeed_speedup = "Accélérer",
  ingame_gamespeed_thensome = "Et encore plus",
  ingame_jukebox = "Jukebox",
  ingame_loadMenu = "Charger une partie",
  ingame_openFirstMessage = "Message du niveau",
  ingame_panel_bankManager = "Gestionnaire de la banque",
  ingame_panel_bankStats = "Statistiques de la banque",
  ingame_panel_buildRoom = "Construire une salle",
  ingame_panel_casebook = "Dossier médical",
  ingame_panel_casebook_alt = "Dossier médical 2",
  ingame_panel_casebook_alt02 = "Dossier médical 3",
  ingame_panel_charts = "Graphiques",
  ingame_panel_editRoom = "Éditer la salle",
  ingame_panel_furnishCorridor = "Meubler le couloir",
  ingame_panel_hireStaff = "Embaucher du personnel",
  ingame_panel_map_alt = "Carte de la ville 2",
  ingame_panel_policy = "Politique",
  ingame_panel_research = "Recherche",
  ingame_panel_research_alt = "Recherche 2",
  ingame_panel_staffManage = "Gérer le personnel",
  ingame_panel_status = "Statut",
  ingame_panel_townMap = "Carte de la ville",
  ingame_panel_machineMenu = "Menu des machines",
  ingame_panel_adviserHistory = "Récapitulatif du conseiller",
  ingame_toggleTransparent = "Transparent on-off",
  ingame_sellPickedUpItem = "Vendre l'objet sélectionné",
  ingame_patient_gohome = "Renvoyer au domicile",
  ingame_pause = "Pause",
  ingame_poopLog = "Journal des événements",
  ingame_poopStrings = "Extraire la traduction",
  ingame_quickLoad = "Chargement rapide",
  ingame_quickSave = "Sauvegarde rapide",
  ingame_quitLevel = "Quitter le niveau",
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
  ingame_reset_zoom = "Réinitialiser le zoom",
  ingame_restartLevel = "Redémarrer le niveau",
  ingame_rotateobject = "Faire pivoter l'objet",
  ingame_saveMenu = "Sauvegarder une partie",
  ingame_scroll_down = "Défiler vers le bas",
  ingame_scroll_left = "Défilement gauche",
  ingame_scroll_right = "Défilement droite",
  ingame_scroll_shift = "Défilement rapide",
  ingame_scroll_up = "Défiler vers le haut",
  ingame_setTransparent = "Transparent",
  ingame_showCheatWindow = "Menu de triche",
  ingame_showmenubar = "Afficher la barre de menu",
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
  ingame_toggleAdvisor = "Conseiller",
  ingame_toggleAnnouncements = "Annonces",
  ingame_toggleInfo = "Info",
  ingame_toggleMusic = "Musique",
  ingame_toggleSounds = "Sons",
  ingame_zoom_in = "Zoom avant",
  ingame_zoom_in_more = "Zoom avant plus",
  ingame_zoom_out = "Zoom arrière",
  ingame_zoom_out_more = "Zoom arrière plus",
  panel_altPanelKeys = "Touches de panneaux alternatifs",
  panel_debugKeys = "Touches de débogage",
  panel_gameSpeedKeys = "Touches de vitesse du jeu",
  panel_generalInGameKeys = "Touches générales en jeu",
  panel_globalKeys = "Touches globales",
  panel_recallPosKeys = "Touches de rappel de position",
  panel_scrollKeys = "Touches de défilement",
  panel_storePosKeys = "Touches de stockage de position",
  panel_toggleKeys = "Touches Activer/Désactiver",
  panel_zoomKeys = "Touches de zoom"
}

tooltip.hotkey_window = {
  button_accept = "Accepter et enregistrer les assignations des touches de raccourci",
  button_recallPosKeys = "Définir les touches pour stocker et rappeler les positions de la caméra",
  button_defaults = "Réinitialiser toutes les touches de raccourci aux valeurs par défaut du programme",
  button_cancel = "Annuler l'assignation et revenir au menu des options",
  button_back_02 = "Retourner à la fenêtre principale des touches de raccourci. Les touches de raccourci modifiées dans cette fenêtre peuvent y être validées",
  caption_panels = "Définir les touches des panneaux",
  button_gameSpeedKeys = "Définir les touches pour contrôler la vitesse du jeu",
  panel_globalKeys = "Définir les touches globales",
  panel_generalInGameKeys = "Définir les touches générales en jeu",
  panel_scrollKeys = "Définir les touches de défilement de l'écran",
  panel_zoomKeys = "Définir les touches pour zoomer et dézoomer",
  panel_toggleKeys = "Définir les touches pour activer/désactiver",
  panel_debugKeys = "Définir les touches pour le débogage",
}

level_progress.hospital_value_enough = "Maintenez la valeur de votre hôpital au-dessus de %d et gérez vos autres problèmes pour remporter le niveau."
level_progress.cured_enough_patients = "Vous avez guéri suffisamment de patients, mais vous devez améliorer votre hôpital pour remporter le niveau."

-- Off you go, warnings

-- Looking at the code it's doesn't seem to be needed, but it's shown as missing by the extract string process
disease_discovered_patient_choice.need_to_employ = "Employez un(e) %s pour pouvoir gérer cette situation."
multiplayer.everyone_failed = "Tout le monde a échoué à satisfaire le dernier objectif. Donc, tout le monde peut continuer à jouer !"
multiplayer.players_failed = "Le(s) joueur(s) suivant(s) n'ont pas réussi à atteindre le dernier objectif :"
original_credits[299] = " "
original_credits[300] = " "
original_credits[301] = ":Opérations"
original_credits[302] = ","
original_credits[303] = "Steve Fitton"
original_credits[304] = " "
original_credits[305] = " "
original_credits[306] = " "
original_credits[307] = ":Administration de la société"
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
original_credits[320] = ":Gestion de la société"
original_credits[321] = ","
original_credits[322] = "Les Edgar"
original_credits[323] = "Peter Molyneux"
original_credits[324] = "David Byrne"
original_credits[325] = " "
original_credits[326] = " "
original_credits[327] = ":Toute l'équipe de Bullfrog Productions"
original_credits[328] = " "
original_credits[329] = " "
original_credits[330] = " "
original_credits[331] = ":Remerciements spéciaux à"
original_credits[332] = ","
original_credits[333] = "Tous ceux de l'hôpital de Frimley Park"
original_credits[334] = " "
original_credits[335] = ":Particulièrement"
original_credits[336] = ","
original_credits[337] = "Beverley Cannell"
original_credits[338] = "Doug Carlisle"
original_credits[339] = " "
original_credits[340] = " "
original_credits[341] = " "
original_credits[342] = ":Continuez à réfléchir"
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

subtitles = {
  alien001 = "Alerte rouge ! Attaque extra-terrestre !", --unused
  alien002 = "Des extra-terrestres ont débarqué, au secours !", --unused
  alien003 = "Des extra-terrestres existent et ils sont là !", --unused
  alien004 = "Les extra-terrestres sont priés de ne pas trop perturber l'hôpital !", --unused
  alien005 = "Extra-terrestres, veuillez signer le registre des visiteurs.", --unused
  cheat001 = "Le directeur de l'hôpital triche !",
  cheat002 = "Alerte ! Un tricheur dirige l'hôpital !",
  cheat003 = "Attention ! Nous avons affaire à un tricheur !",
  emerg001 = "Appel de service : arrivée de patients souffrant de rectoïdes.",
  emerg002 = "Appel de service : arrivée de patients ayant la courante.",
  emerg003 = "Appel de service : arrivée de patients souffrant de téléincarnation.",
  emerg004 = "Appel de service : arrivée de patients atteints de catarhume.",
  emerg005 = "Appel de service : arrivée de patients souffrant de fractures.",
  emerg006 = "Appel de service : arrivée de patients frappés d'invisibilité.",
  emerg007 = "Appel de service : arrivée de patients atteints d'encéphalantiasis.",
  emerg008 = "Appel de service : arrivée de patients atteints de pilose.",
  emerg009 = "Appel de service : arrivée de patients souffrant du syndrome du King.",
  emerg010 = "Appel de service : arrivée de patients victimes de radionite.",
  emerg011 = "Appel de service : arrivée de patients atteints d'hyperlangue.",
  emerg012 = "Appel de service : arrivée de patients atteints de calvitie.",
  emerg013 = "Appel de service : arrivée de patients atteints de morpionnite.",
  emerg014 = "Appel de service : arrivée de patients atteints de gélatine.",
  emerg015 = "Appel de service : arrivée de patients atteints de roupillance.",
  emerg016 = "Appel de service : arrivée de patients atteints de pétomanie.",
  emerg017 = "Appel de service : arrivée de patients sujets aux mains moites.",
  emerg018 = "Appel de service : arrivée de patients atteints de bouffissure.",
  emerg019 = "Appel de service : arrivée de patients atteints de tripurulente.", --audio use "tripurulence" instead of "tripurulente"
  emerg020 = "Appel de service : arrivée de patients contaminés par de l'ADN alien.",
  emerg021 = "Appel de service : arrivée de patients en état de grossesse.",
  emerg022 = "Appel de service : arrivée de patients frappés de transparence.",
  emerg023 = "Appel de service : arrivée de patients souffrant d'excès costal.",
  emerg024 = "Appel de service : arrivée de patients souffrant de cristaux rénaux.",
  emerg025 = "Appel de service : arrivée de patients victimes d'un brise-coeur.",
  emerg026 = "Appel de service : arrivée de patients victimes de casse-boules.",
  emerg027 = "Appel de service : arrivée de patients atteints de fou rire.",
  emerg028 = "Appel de service : arrivée de patients souffrant de chevilles ondulées.",
  emerg029 = "Appel de service : arrivée de patients atteints de poilonisme.",
  emerg030 = "Appel de service : arrivée de patients atteints de rétrostalgie.",
  emerg031 = "Appel de service : arrivée de patients victimes du syndrome de sang factice.",
  emerg032 = "Appel de service : arrivée de patients souffrant de déjections gastriques.",
  emerg033 = "Appel de service : arrivée de patients souffrant de poumons de fer.",
  emerg034 = "Appel de service : arrivée de patients souffrant de pierres de golf.",
  epid001 = "Alerte à l'épidémie, tenez-vous prêts !",
  epid002 = "Appel de service : alerte à l'épidémie !",
  epid003 = "Attention, alerte à l'épidémie !",
  epid004 = "Attention !",
  epid005 = "Fin de l'alerte à l'épidémie.",
  epid006 = "L'épidémie est sous contrôle.",
  epid007 = "L'épidémie a été éradiquée.",
  epid008 = "Fin de l'alerte à l'épidémie.",
  machwarn = "*Alarme machine*",
  maint004 = "Un agent de maintenance est demandé pour réparer le taille-langue.",
  maint005 = "Un agent de maintenance pour réparer les rayons X, s'il vous plaît.",
  maint006 = "Appel d'un agent de maintenance pour réparer le correcteur d'ADN.",
  maint007 = "Appel de maintenance pour l'implanteur capillaire.",
  maint008 = "Appel de maintenance pour l'électrolyseur.",
  maint009 = "Appel de maintenance pour le dégélificateur.",
  maint010 = "Un agent de maintenance est demandé à la cardio machine.",
  maint011 = "Appel de maintenance pour la diagnomachine.",
  maint012 = "Un agent de maintenance est demandé en décontamination.",
  maint013 = "Un agent de maintenance est prié de réparer le gonfleur.",
  maint014 = "Un agent de maintenance est demandé pour le réducteur de fractures.",
  maint015 = "Un agent de maintenance est demandé pour la sanguimachine.",
  maint016 = "Un agent de maintenance est demandé pour l'ultrascan.",
  quake001 = "Attention ! On annonce un tremblement de terre.",
  quake002 = "Attention ! Tremblement de terre imminent.",
  quake003 = "Attention ! Alerte aux tremblements de terre.",
  quake004 = "Alerte ! Un tremblement de terre s'annonce.",
  rand001 = "Appel téléphonique ! Appel téléphonique !",
  rand002 = "Le docteur Jekyll est demandé en psychiatrie.",
  rand003 = "Veuillez ne pas fumer dans l'hôpital.",
  rand005 = "Les patients sont priés de ne pas mourir dans les couloirs.",
  rand006 = "La toux et les éternuements propagent les maladies.",
  rand008 = "Message aux patients : veuillez vous munir d'un chéquier.",
  rand009 = "Message aux patients : veuillez vous munir d'une carte de crédit.",
  rand010 = "Silence s'il vous plaît, il y a des malades ici.",
  rand012 = "Les patients sont priés de ne pas trop vomir.",
  rand013 = "Alerte : ceci est une alerte.",
  rand016 = "Les patients sont ici à leurs risques et périls.",
  rand017 = "Les patients atteints de folie sont priés de rester calmes.",
  rand018 = "Les patients sont priés d'être patients.",
  rand019 = "Les patients sont priés d'attendre dans le calme.",
  rand021 = "Veuillez ne pas jeter de détritus dans l'hôpital.",
  rand022 = "Il est interdit de jeter des détritus.",
  rand024 = "Nous prions les patients de garder leurs microbes pour eux.",
  rand025 = "Les patients doivent garder leur chéquier sous la main.",
  rand026 = "Les patients doivent tenir prête leur carte de crédit.",
  rand027 = "Les patients sur la fin doivent passer devant.",
  rand028 = "Veuillez rester dans la queue.",
  rand029 = "Découvrez les autres produits Bullfrog.",
  rand030 = "Il est interdit de traînasser.",
  rand031 = "Il est interdit de jeter des détritus.",
  rand032 = "Il est interdit de vomir.",
  rand033 = "Les membres de l'équipe sont priés de se reposer fréquemment.",
  rand034 = "Offre du jour : demi-tarif sur l'implantation capillaire.",
  rand035 = "Messieurs Landru et Petiot, veuillez vous rendre à la sortie.",
  rand036 = "Veuillez ne pas nourrir la vermine, merci.",
  rand037 = "Nous prions aimablement nos patients de gémir faiblement, merci.",
  rand038 = "Il y a une bombe à détritus dans l'hôpital !", --Not present in English version
  rand039 = "Alerte à la bombe à détritus !", --Not present in English version
  rand040 = "Attention à la bombe à détritus !",
  rand041 = "J'en ai assez de faire des annonces, je veux rentrer chez moi.",
  rand044 = "Nous prions toutes les personnes d'éviter d'être malades dans les couloirs.",
  rand045 = "Docteur Lecter veuillez vous présenter à la sécurité, Docteur Lecter à la sécurité.",
  rand046 = "La carte son fonctionne.",
  reqd001 = "Un médecin est demandé en salle de cardiomachine.",
  reqd002 = "Un médecin est demandé en salle de scanner.",
  reqd003 = "Un médecin est demandé au cabinet de psychiatrie.",
  reqd004 = "Une infirmière est demandée en salle des fractures.",
  reqd005 = "Un médecin est demandé en salle de taille-langue.",
  reqd006 = "Un médecin est demandé en salle de sanguimachine.",
  reqd007 = "Un médecin est demandé en salle d'ultrascan.",
  reqd008 = "Un médecin est demandé au bureau du généraliste.",
  reqd009 = "Une infirmière est demandée en salle des malades.",
  reqd010 = "Deux chirurgiens sont demandés en salle d'opérations.",
  reqd011 = "Un autre chirurgien est demandé en salle d'opérations.", --unused
  reqd012 = "Une infirmière est demandée à la pharmacie.",
  reqd013 = "Un médecin est demandé en salle des rayons X.",
  reqd014 = "Un médecin est demandé en salle de gonflage.",
  reqd015 = "Un médecin est demandé en salle de correction d'ADN.",
  reqd016 = "Un médecin est demandé en salle d'implantation capillaire.",
  reqd017 = "Un médecin est demandé en salle de formation.", --unused
  reqd019 = "Un médecin est attendu en salle d'électrolyse.", --audio says "Researcher", but it's wrong, classic doctor is needed in electrolysis
  reqd020 = "Un médecin est attendu en salle de dégélatination.",
  reqd021 = "Un médecin est demandé en salle de diagnostic.",
  reqd023 = "Un médecin chercheur est demandé au département recherche.",
  reqd024 = "Un médecin est attendu en salle de décontamination.",
  sack001 = "Un médecin a été renvoyé.",
  sack002 = "Un médecin s'en va.",
  sack003 = "Un médecin se dirige vers la sortie.",
  sack004 = "Une infirmière s'en va.",
  sack005 = "Une infirmière s'en va maintenant.",
  sack006 = "Un agent renvoyé s'en va.",
  sack007 = "La réceptionniste doit partir.",
  sack008 = "La réceptionniste s'en va.",
  sack009 = "Un membre de l'équipe a été débauché.", --unused
  sack010 = "Un médecin a été débauché.", --unused
  sorry001 = "Nous vous prions d'excuser les détritus.", --unused
  sorry002 = "Nous vous prions d'excuser le froid extrême.",
  sorry003 = "Nous vous prions d'excuser la chaleur excessive.",
  sorry004 = "Nous prions nos patients de nous excuser, les radiateurs fonctionnent mal.",
  sorry005 = "Ne marchez pas dans le vomi.", --unused
  sorry006 = "Appel de maintenance, flaque de vomi dans le couloir.", --unused
  vip001 = "Votre attention s'il vous plaît, il y a des personnalités dans le bâtiment.",
  vip002 = "Une personnalité est entrée dans le bâtiment.",
  vip003 = "Une personnalité visite l'hôpital.",
  vip004 = "Une personnalité fait le tour du bâtiment.",
  vip005 = "Une personnalité est parmi nous.",
  vip008 = "Un inspecteur sanitaire est dans l'hôpital.",
}

-------------------------------------------------------------------------------
--   Multiplayer (network play): the room, game options, auctions, bots and the rest
--   of the multiplayer windows. Translated from english.lua; the keys
--   missing here show in English.
-------------------------------------------------------------------------------
hotkey_window.ingame_mp_chat = "Chat multijoueur"
hotkey_window.ingame_mp_next_hospital = "Hôpital suivant (MJ)"
main_menu.multiplayer = "Multijoueur"
map_editor_window.pages.camera_n = "Caméra %d"
map_editor_window.pages.heliport_n = "Héliport %d"
map_editor_window.pages.player = "Joueur %d"
menu.map_size = "TAILLE DE LA CARTE"
menu_map_size.size = "  NOUVELLE CARTE %d x %d  "
menu_player_count.players_5 = "  5 JOUEURS  "
menu_player_count.players_6 = "  6 JOUEURS  "
menu_player_count.players_7 = "  7 JOUEURS  "
menu_player_count.players_8 = "  8 JOUEURS  "
multiplayer_window.add_bot = "en attente d'un joueur... (clic : ajouter un bot)"
multiplayer_window.ask_amount = "Montant : $%d"
multiplayer_window.ask_asked = "Demande envoyée. En attente de sa réponse."
multiplayer_window.ask_balance_line = "Son solde : $%d."
multiplayer_window.ask_button = "Demander"
multiplayer_window.ask_caption = "Demander de l'argent à %s"
multiplayer_window.ask_decline = "Refuser"
multiplayer_window.ask_declined_note = "%s a refusé de vous envoyer $%d."
multiplayer_window.ask_line = "%s vous demande $%d."
multiplayer_window.ask_money = "Demander à un joueur"
multiplayer_window.ask_no_money_asker_note = "%s n'a pas pu vous payer."
multiplayer_window.ask_no_money_note = "Vous ne pouvez pas payer $%d."
multiplayer_window.ask_pay = "Payer $%d"
multiplayer_window.ask_sent_note = "Vous avez demandé $%d à %s. En attente de sa réponse."
multiplayer_window.auction_back = "Retour aux enchères"
multiplayer_window.auction_bid = "Miser $%d"
multiplayer_window.auction_borrow_tooltip = "Emprunter $5,000 à la banque"
multiplayer_window.auction_close = "Fermer"
multiplayer_window.auction_dropped = "Vous vous êtes retiré."
multiplayer_window.auction_going_once = "Une fois..."
multiplayer_window.auction_going_twice = "Deux fois..."
multiplayer_window.auction_leader = "Meilleure mise : $%d, %s"
multiplayer_window.auction_leading = "Vous menez. Attendez les autres."
multiplayer_window.auction_loan = "$%d, prêt $%d"
multiplayer_window.auction_loan_tooltip = "Votre solde et votre prêt bancaire"
multiplayer_window.auction_no_money = "Vous ne pouvez pas payer la mise suivante."
multiplayer_window.auction_no_money_loan = "Vous ne pouvez pas payer la mise suivante : empruntez avec + ci-dessous."
multiplayer_window.auction_not_sold = "La parcelle %d n'a pas été vendue."
multiplayer_window.auction_out = "retiré"
multiplayer_window.auction_pass = "Se retirer"
multiplayer_window.auction_paused = "Le jeu est à l'arrêt pendant les enchères."
multiplayer_window.auction_price = "Prix $%d, chaque mise $%d de plus"
multiplayer_window.auction_repay_tooltip = "Rembourser $5,000 du prêt"
multiplayer_window.auction_sold = "Parcelle %d vendue à %s pour $%d."
multiplayer_window.auction_started = "%s veut la parcelle %d. D'autres joueurs la veulent peut-être aussi : elle passe aux enchères."
multiplayer_window.auction_title = "Enchères de terrain : parcelle %d"
multiplayer_window.auction_wants = "%s veut acheter la parcelle en surbrillance."
multiplayer_window.auction_bid_more = "Enchérissez de $%d ou plus."
multiplayer_window.auction_winning = "Meilleur enchérisseur"
multiplayer_window.auction_wait = "Enchères en cours, patientez..."
multiplayer_window.auction_watching = "Votre terrain ne touche pas cette parcelle."
multiplayer_window.auctions_all = "Toutes"
multiplayer_window.auctions_caption = "Enchères de terrain"
multiplayer_window.auctions_near = "Disputées"
multiplayer_window.auctions_none = "Non"
multiplayer_window.back = "Retour"
multiplayer_window.back_to_lobby = "Retour au salon"
multiplayer_window.bot_line = "%s   (bot)%s"
multiplayer_window.bot_remove = "   clic : retirer"
multiplayer_window.bot_easy = "%s, facile"
multiplayer_window.bot_hard = "%s, difficile"
multiplayer_window.bot_menu_easy = "Facile : pas d'argent caché, pas de modèle de langage"
multiplayer_window.bot_menu_normal = "Normal"
multiplayer_window.bot_menu_hard = "Difficile : plus d'argent, de réputation et de valeur"
multiplayer_window.bot_starting = "un bot démarre..."
multiplayer_window.caption = "Multijoueur"
multiplayer_window.cert_changed_help = "Le certificat de %s n'est pas celui dont ce jeu se souvenait de la dernière fois. Soit le serveur a été reconfiguré, soit quelqu'un s'est placé entre vous et le serveur. Le jeu ne s'est pas connecté. Si vous savez que le serveur a un nouveau certificat, supprimez sa ligne dans %s et reconnectez-vous."
multiplayer_window.chat_private_in = "%s (à vous) : %s"
multiplayer_window.chat_private_out = "A %s : %s"
multiplayer_window.chat_team_in = "%s (à l'équipe) : %s"
multiplayer_window.chat_team_out = "A l'équipe : %s"
multiplayer_window.chat_to = "A %s :"
multiplayer_window.chat_to_all = "A tous :"
multiplayer_window.chat_to_team = "A l'équipe :"
multiplayer_window.chat_to_allies = "Aux alliés :"
multiplayer_window.chat_allies_in = "%s (aux alliés) : %s"
multiplayer_window.chat_allies_out = "Aux alliés : %s"
multiplayer_window.clear_destroyed_room = "Déblayer la salle détruite pour $%d ? L'espace sera alors libre pour autre chose."
multiplayer_window.colour_names[1] = "Jaune"
multiplayer_window.colour_names[2] = "Rouge"
multiplayer_window.colour_names[3] = "Violet"
multiplayer_window.colour_names[4] = "Blanc"
multiplayer_window.colour_names[5] = "Vert"
multiplayer_window.colour_names[6] = "Bleu"
multiplayer_window.colour_names[7] = "Turquoise"
multiplayer_window.colour_names[8] = "Noir"
multiplayer_window.connect = "Connecter"
multiplayer_window.connecting = "Connexion à %s..."
multiplayer_window.continue_save = "Reprendre : %s"
multiplayer_window.continuing = "sauvegarde %s"
multiplayer_window.create = "Créer"
multiplayer_window.data_mismatch_help = "Les fichiers Theme Hospital de ce serveur viennent d'une autre édition du jeu que la vôtre (les niveaux et les cartes multijoueur diffèrent), et les parties ne resteraient pas identiques. Indiquez à CorsixTH la même édition que celle du serveur (Options, Options des dossiers, emplacement de Theme Hospital), par exemple la version GOG, puis reconnectez-vous."
multiplayer_window.disconnect = "Déconnecter"
multiplayer_window.download = "Télécharger %s depuis GitHub"
multiplayer_window.emergency_refused = "Refuser l'urgence a coûté %d de réputation à l'hôpital."
multiplayer_window.encrypted = "Connexion chiffrée (TLS)"
multiplayer_window.every_plot_auctioned = "toutes aux enchères"
multiplayer_window.game_options = "Options de jeu"
multiplayer_window.goal_limit = "limite :"
multiplayer_window.goal_other.balance = "%s : solde $%d (%s $%d)"
multiplayer_window.goal_other.num_cured = "%s : %d patients guéris (%s %d)"
multiplayer_window.goal_other.percentage_cured = "%s : %d%% de patients guéris (%s %d%%)"
multiplayer_window.goal_other.percentage_killed = "%s : %d%% de patients morts (%s %d%%)"
multiplayer_window.goal_other.reputation = "%s : réputation %d (%s %d)"
multiplayer_window.goal_other.value = "%s : valeur de l'hôpital $%d (%s $%d)"
multiplayer_window.goal_target = "objectif :"
multiplayer_window.goals_done = "atteint"
multiplayer_window.goals_failed_other = "%s a échoué aux objectifs de ce niveau. Aidez-le à se rétablir d'ici la fin de l'année prochaine (argent ou personnel), sinon toute l'équipe perd."
multiplayer_window.goals_failed_team = "Votre hôpital a échoué aux objectifs de ce niveau. Rétablissez-vous d'ici la fin de l'année prochaine, sinon toute l'équipe perd. Les autres joueurs peuvent vous envoyer de l'argent ou du personnel."
multiplayer_window.goals_failing = "en échec"
multiplayer_window.goals_open = "-"
multiplayer_window.goals_reached_loan = "Votre hôpital remplit tous les objectifs de ce niveau mais doit encore $%d à la banque. Remboursez le prêt (cliquez sur votre argent en bas) et ils comptent comme atteints."
multiplayer_window.goals_reached_other = "%s a atteint les objectifs de ce niveau. Reste à faire : %s."
multiplayer_window.goals_reached_team = "Votre hôpital a atteint les objectifs de ce niveau ! Reste à faire : %s."
multiplayer_window.goals_recovered = "%s n'échoue plus aux objectifs de ce niveau."
multiplayer_window.helpers_off = "Bots alliés construisent : non"
multiplayer_window.helpers_on = "Bots alliés construisent : oui"
multiplayer_window.hold_left = "Le jeu reprend dans %s au plus tard."
multiplayer_window.hold_win = "On attend que %s réponde au fax..."
multiplayer_window.hold_year = "On attend que %s ferme le rapport annuel..."
multiplayer_window.is_ready = "prêt"
multiplayer_window.join = "Rejoindre"
multiplayer_window.keep_playing = "Continuer à jouer"
multiplayer_window.kick_player = "Retirer %s du salon"
multiplayer_window.kicked = "%s, le propriétaire du salon, vous a retiré du salon."
multiplayer_window.leave = "Quitter le salon"
multiplayer_window.level = "Niveau %d"
multiplayer_window.level7_breakthrough = "Percée médicale : %s a été le premier à découvrir : %s, et gagne $%d."
multiplayer_window.level7_breakthrough_bonus = "Prime de percée"
multiplayer_window.level7_job_fair = "Le salon de l'emploi est ouvert : des spécialistes figurent sur la liste d'embauche ce mois-ci."
multiplayer_window.level7_job_fair_soon = "Un salon de l'emploi ouvre le mois prochain : chirurgiens, psychiatres, chercheurs et consultants seront sur la liste d'embauche. Premier arrivé, premier servi."
multiplayer_window.level7_quarter = "Classement du Ministère de la Santé : %s a guéri le plus de patients ce trimestre (%d) et gagne en réputation."
multiplayer_window.level7_race_bonus = "Prime d'urgence de course"
multiplayer_window.level7_race_emergency = "Urgence de course : tous les hôpitaux reçoivent la même urgence maintenant. Le premier à sauver tous les patients gagne $%d et de la réputation."
multiplayer_window.level7_race_won = "%s a sauvé le premier tous les patients de l'urgence de course et gagne $%d."
multiplayer_window.level7_rat_bounty = "Prime aux rats"
multiplayer_window.level7_trick_of_month = "Coup du mois : %s est à moitié prix jusqu'à la fin du mois."
multiplayer_window.level7_truce_over = "La trêve est finie : les coups bas peuvent s'acheter dès maintenant (MULTIJOUEUR > COUPS BAS)."
multiplayer_window.level_intro_6 = "Urgence ! Les hôpitaux de cette ville prennent toutes les urgences que l'hélicoptère peut amener. Pendant la première année, il en vient quatre par mois, chez chacun de vos hôpitaux à tour de rôle : cas de gonflage et de psychiatrie dès février (et quelques-uns pour la pharmacie), cas de bloc opératoire dès mai, hyperlangue et fractures dès juin. En mai, chaque hôpital reçoit des patients atteints d'hyperlangue : recherchez tôt la clinique de l'hyperlangue. Refuser une urgence coûte de la réputation, mais les patients perdus à cause d'elles sont pardonnés plus facilement, et vous pouvez adresser les patients en urgence à l'hôpital d'un ami qui sait les soigner. Moins de patients se présentent tant que durent les urgences ; dès la deuxième année il en vient plus, et des épidémies balaient chaque hôpital tous les deux ou trois mois. Les rats aiment l'endroit aussi. Engagez des consultants tant que vous le pouvez : à partir du neuvième mois, seuls des internes cherchent du travail. Pour gagner, chaque hôpital doit avoir une réputation de 550, $60,000 en banque, 150 patients guéris, un taux de guérison de 40 pour cent et la valeur d'hôpital indiquée dans le rapport de progression."
multiplayer_window.level_intro_7 = "Sans pitié. Chaque hôpital de cette ville veut être le meilleur, et aucun ne joue franc jeu. Il y a une trêve jusqu'en mars ; ensuite les coups bas s'ouvrent mois après mois : attaques de rats, campagnes de calomnie et chaudières en panne d'abord, puis agents d'entretien malveillants, épidémies et espionnage dès juin, urgences forcées et chasseurs de têtes dès septembre, et le niveau maximal de chaque coup dès la deuxième année. Chaque mois, un coup est vendu à moitié prix, l'hôpital le plus en retard paie moitié prix pour tous, et le leader paie une fois et demie plus. A ne pas rater : les salons de l'emploi d'avril, d'octobre, d'avril prochain et d'octobre prochain amènent chirurgiens, psychiatres, chercheurs et consultants sur la liste d'embauche, premier arrivé, premier servi. En août, en février et en août suivant, chaque hôpital reçoit la même urgence en même temps, et le premier à sauver tous les patients gagne $10,000 et de la réputation. Le premier à découvrir la radio, le scanner ou la machine à sang gagne aussi $10,000 (les plans volés ne comptent pas), et chaque trimestre l'hôpital qui a guéri le plus de patients gagne en réputation. Les rats envoyés par un rival rapportent $100 pièce quand on les abat. Les machines s'usent plus vite ici, et quatre séismes secoueront la ville, chacun plus fort que le précédent. Pour gagner, un hôpital doit avoir une réputation de 650, $150,000 en banque, 300 patients guéris, un taux de guérison de 55 pour cent et la valeur d'hôpital indiquée dans le rapport de progression. A quatre joueurs, la ville est la carte de Matroftt."
multiplayer_window.level_intro_8 = "Team Town, la carte de Matroftt, est faite pour du deux contre deux : les quatre hôpitaux se tiennent par paires au centre de la ville, coéquipiers côte à côte, avec beaucoup de terrain à vendre de tous les côtés. Mettez vos amis dans la même équipe et affrontez l'autre paire. Pour gagner, chaque hôpital doit avoir une réputation de 650, $100,000 en banque, 200 patients guéris, un taux de guérison de 50 pour cent et la valeur d'hôpital indiquée dans le rapport de progression. A deux ou trois joueurs, on joue sur la carte d'une autre ville."
multiplayer_window.level_intro_9 = "Carrefour, la carte de Matroftt, a de la place pour huit : la ville est découpée en trois rangées de trois, avec huit hôpitaux déjà murés autour de quatre petits terrains à vendre au centre, là où les chemins se croisent. Les quatre hôpitaux des coins sont un peu plus grands. À quatre joueurs ou moins, seuls les coins sont pris et les autres hôpitaux sont aussi à vendre. Les patients arrivent par tous les bords de la ville. Pour gagner, chaque hôpital doit avoir une réputation de 650, 150 000 $ en banque, 300 patients guéris, un taux de guérison de 55 pour cent et la valeur d'hôpital indiquée dans le rapport de progression."
multiplayer_window.level_rats_notice = "Des rats ! Une horde s'est glissée dans l'hôpital. Cliquez dessus pour les abattre avant qu'ils prolifèrent dans les ordures."
multiplayer_window.level_slack_tongue_warning = "On signale des cas d'hyperlangue dans toute la ville. En mai, chaque hôpital recevra des urgences d'hyperlangue : recherchez la clinique de l'hyperlangue avant."
multiplayer_window.level_won_end = "Vous avez gagné le niveau. Bravo !"
multiplayer_window.levels_caption = "Niveaux"
multiplayer_window.levels_choose = "Choisir le niveau %d"
multiplayer_window.levels_events = "ÉVÉNEMENTS %s"
multiplayer_window.levels_from_campaign = "Salles, maladies et recherches comme dans %s (niveau %d de la campagne)."
multiplayer_window.levels_goal_balance = "$%s en banque"
multiplayer_window.levels_goal_cure_rate = "Guérison %d%%"
multiplayer_window.levels_goal_cured = "%d guéris"
multiplayer_window.levels_goal_reputation = "Réputation %d"
multiplayer_window.levels_goal_value = "Valeur +$%s"
multiplayer_window.levels_goals = "Pour gagner :"
multiplayer_window.levels_legend = "En couleur : parcelles de départ. Gris : à vendre."
multiplayer_window.levels_map_by = "Carte de %s"
multiplayer_window.levels_map_players = "Carte pour %d joueurs"
multiplayer_window.levels_money = "Argent : $%s"
multiplayer_window.levels_no_map = "Cette carte n'est pas dans vos données Theme Hospital."
multiplayer_window.levels_several = "Plusieurs hôpitaux"
multiplayer_window.levels_shared = "Un hôpital commun"
multiplayer_window.levels_shared_note = "Niveau %d de la campagne : un hôpital que tout le monde construit ensemble, avec les objectifs de la campagne."
multiplayer_window.load_caption = "Charger une partie multijoueur"
multiplayer_window.load_game = "Charger partie MJ"
multiplayer_window.loading = "CHARGEMENT..."
multiplayer_window.locked = "  (mot de passe)"
multiplayer_window.looking_at = "Vue sur %s"
multiplayer_window.measuring = "Mesure de la connexion..."
multiplayer_window.menu_caption = "  MULTIJOUEUR  "
multiplayer_window.menu_chat = "  ENVOYER UN MESSAGE (%1%)  "
multiplayer_window.menu_colours = "  COULEURS DES JOUEURS  "
multiplayer_window.menu_colours_all = "  GENS DE TOUS  "
multiplayer_window.menu_colours_off = "  NON  "
multiplayer_window.menu_bot_chat = "  DISCUSSION DES BOTS  "
multiplayer_window.menu_bot_chat_all = "  TOUT  "
multiplayer_window.menu_bot_chat_auto = "  SANS BAVARDAGE DES 3 BOTS ET PLUS  "
multiplayer_window.menu_bot_chat_useful = "  SANS BAVARDAGE  "
multiplayer_window.menu_bot_chat_off = "  NON  "
multiplayer_window.menu_colours_others = "  GENS DES AUTRES  "
multiplayer_window.menu_players = "  JOUEURS  "
multiplayer_window.menu_research = "  PARTAGER LA RECHERCHE  "
multiplayer_window.menu_sabotage = "  COUPS BAS  "
multiplayer_window.menu_trade = "  ÉCHANGER AVEC LES JOUEURS  "
multiplayer_window.mode_competitive = "Course : chacun pour soi"
multiplayer_window.mode_coop = "Coop : on gagne tous ensemble"
multiplayer_window.mode_mixed = "Course d'équipes"
multiplayer_window.mode_shared = "Un hôpital commun"
multiplayer_window.mode_teams = "Course de deux équipes"
multiplayer_window.mode_teamshared = "Course d'hôpitaux d'équipe"
multiplayer_window.money_received = "Argent de %s"
multiplayer_window.money_received_note = "%s vous a envoyé $%d."
multiplayer_window.money_sent = "Argent envoyé à %s"
multiplayer_window.mp_level = "%s (à plusieurs hôpitaux : niveau %d)"
multiplayer_window.name = "Votre nom"
multiplayer_window.new_room = "Nouveau salon"
multiplayer_window.no_auctions = "pas d'enchères"
multiplayer_window.no_helper_building = "les bots ne construisent pas"
multiplayer_window.no_rooms = "Pas encore de salon. Créez-en un ci-dessous."
multiplayer_window.no_sharing = "pas de partage"
multiplayer_window.no_socket = "Cette version n'a pas de support réseau (LuaSocket manquant)."
multiplayer_window.no_tricks = "pas de coups bas"
multiplayer_window.not_encrypted = "Non chiffrée"
multiplayer_window.not_encrypted_build = "Non chiffrée : ce jeu n'a pas LuaSec"
multiplayer_window.not_encrypted_server = "Non chiffrée : ce serveur n'a pas de certificat"
multiplayer_window.not_ready = "pas prêt"
multiplayer_window.offer_ability = "Talent : %d%%"
multiplayer_window.offer_accept = "Accepter"
multiplayer_window.offer_accept_pay = "Payer $%d"
multiplayer_window.offer_accept_price = "Accepter et payer $%d"
multiplayer_window.offer_accepted_note = "%s a accepté : %s."
multiplayer_window.offer_accepted_price_note = "%s a accepté : %s, pour $%d."
multiplayer_window.offer_caption = "Offre de %s"
multiplayer_window.offer_decline = "Refuser"
multiplayer_window.offer_declined_note = "%s a refusé : %s."
multiplayer_window.offer_free_banner = "GRATUIT : ce membre du personnel est offert"
multiplayer_window.offer_gone_note = "%s n'est plus disponible."
multiplayer_window.offer_happy = "Bonheur : %d%%"
multiplayer_window.offer_health = "Santé : %d%%"
multiplayer_window.offer_illness = "Maladie : %s"
multiplayer_window.offer_job = "Poste : %s"
multiplayer_window.offer_later = "Plus tard"
multiplayer_window.offer_no_money_note = "Vous ne pouvez pas payer les $%d demandés pour %s."
multiplayer_window.offer_no_money_sender_note = "%s n'a pas pu payer le prix pour %s."
multiplayer_window.offer_no_skills = "Compétences spéciales : aucune"
multiplayer_window.offer_not_diagnosed = "Pas encore diagnostiqué (%d%% fait)"
multiplayer_window.offer_patient_known = "un patient atteint de %s"
multiplayer_window.offer_patient_line = "%s vous adresse un patient :"
multiplayer_window.offer_patient_unknown = "un patient non diagnostiqué"
multiplayer_window.offer_price_banner = "PRIX : $%d, payé seulement si vous acceptez"
multiplayer_window.offer_price_line = "PRIX : $%d. Il est demandé pour ce membre du personnel."
multiplayer_window.offer_raise = "Demande une augmentation"
multiplayer_window.offer_sent_note = "%s a été proposé à %s. En attente de sa réponse."
multiplayer_window.offer_sent_price_note = "%s a été proposé à %s pour $%d. En attente de sa réponse."
multiplayer_window.offer_show = "Voir"
multiplayer_window.offer_skills = "Compétences spéciales : %s"
multiplayer_window.offer_staff_line = "%s vous propose un membre du personnel :"
multiplayer_window.offer_tired = "Fatigue : %d%%"
multiplayer_window.offer_wage = "Salaire : $%d par mois"
multiplayer_window.options_close = "Fermer"
multiplayer_window.options_host_only = "Seul l'hôte change cela."
multiplayer_window.options_off_line = "Options : %s"
multiplayer_window.other_build = "  (autre version du jeu)"
multiplayer_window.owner_mark = " (hôte)"
multiplayer_window.password = "Mot de passe"
multiplayer_window.password_clear = "Non chiffrée : le mot de passe part en clair. Cliquez encore pour l'envoyer."
multiplayer_window.patient_arrived_note = "Un patient adressé par %s est arrivé."
multiplayer_window.patient_on_the_way = "Adressé à %s"
multiplayer_window.places[1] = "1re"
multiplayer_window.places[2] = "2e"
multiplayer_window.places[3] = "3e"
multiplayer_window.places[4] = "4e"
multiplayer_window.places[5] = "5e"
multiplayer_window.places[6] = "6e"
multiplayer_window.places[7] = "7e"
multiplayer_window.places[8] = "8e"
multiplayer_window.player_away_note = "%s est parti : son hôpital ne compte pas pour les objectifs de l'équipe tant qu'il n'est pas revenu (même salon, même nom)."
multiplayer_window.player_back_note = "%s est de retour : son hôpital compte de nouveau pour les objectifs de l'équipe."
multiplayer_window.player_line = "%s%s   %s ms   %s"
multiplayer_window.players = "%d joueurs"
multiplayer_window.players_balance = "Solde"
multiplayer_window.players_behind = "%d heures de retard"
multiplayer_window.players_caption = "Joueurs"
multiplayer_window.players_goals = "Objectifs"
multiplayer_window.players_hospital = "Hôpital"
multiplayer_window.players_left = "a quitté la partie"
multiplayer_window.players_ms = "%d ms"
multiplayer_window.players_name = "Joueur"
multiplayer_window.players_note = "Ping : moyenne des 10 dernières secondes. Valeur : la valeur de l'hôpital (un objectif du niveau)."
multiplayer_window.players_ping = "Ping"
multiplayer_window.players_playing = "en jeu"
multiplayer_window.players_quiet = "sans réponse depuis %d s"
multiplayer_window.players_reputation = "Réputation"
multiplayer_window.players_status = "État"
multiplayer_window.players_team = "%s (équipe %d)"
multiplayer_window.players_value = "Valeur"
multiplayer_window.players_waiting = "En attente de la liste du serveur..."
multiplayer_window.players_you = "vous"
multiplayer_window.plot_bought_transaction = "Terrain de %s (parcelle %d)"
multiplayer_window.plot_give_button = "Proposer la parcelle"
multiplayer_window.plot_give_cancel = "Annuler"
multiplayer_window.plot_give_caption = "Céder la parcelle %d"
multiplayer_window.plot_give_free = "Prix : gratuit"
multiplayer_window.plot_give_hint = "Céder cette parcelle à un allié, gratuitement ou à un prix"
multiplayer_window.plot_give_none = "Il n'y a personne à qui céder une parcelle."
multiplayer_window.plot_give_offered = "Proposée. La parcelle change de mains si l'autre joueur accepte."
multiplayer_window.plot_give_price = "Prix : $%d"
multiplayer_window.plot_give_to = "Pour quel allié :"
multiplayer_window.plot_given_transaction = "Terrain pour %s (parcelle %d)"
multiplayer_window.plot_offer_accepted_note = "%s a accepté la parcelle %d."
multiplayer_window.plot_offer_accepted_price_note = "%s a accepté la parcelle %d pour $%d."
multiplayer_window.plot_offer_declined_note = "%s a refusé la parcelle %d."
multiplayer_window.plot_offer_free_line = "GRATUIT : aucun frais pour cette parcelle."
multiplayer_window.plot_offer_gone_note = "L'offre pour la parcelle %d est caduque : la situation a changé."
multiplayer_window.plot_offer_line = "%s vous propose la parcelle %d (%d cases de terrain)."
multiplayer_window.plot_offer_no_money_note = "Vous ne pouvez pas payer les $%d demandés pour la parcelle %d."
multiplayer_window.plot_offer_no_money_sender_note = "%s n'a pas pu payer la parcelle %d."
multiplayer_window.plot_offer_price_line = "PRIX : $%d, payé seulement si vous acceptez."
multiplayer_window.plot_offer_sent_note = "La parcelle %d a été proposée à %s en cadeau. En attente de sa réponse."
multiplayer_window.plot_offer_sent_price_note = "La parcelle %d a été proposée à %s pour $%d. En attente de sa réponse."
multiplayer_window.plot_received_note = "La parcelle %d est à vous maintenant, de la part de %s."
multiplayer_window.plot_sell_hint = "Revendre cette parcelle à la banque (elle doit être vide)"
multiplayer_window.plot_sell_question = "Voulez-vous vendre cette parcelle ? Vous récupérerez $%d."
multiplayer_window.plot_sold_note = "La parcelle %d est revendue à la banque pour $%d."
multiplayer_window.plot_sold_others_note = "%s a revendu la parcelle %d. Elle est de nouveau à vendre."
multiplayer_window.plot_sold_transaction = "Parcelle %d revendue"
multiplayer_window.race_and = " et "
multiplayer_window.race_failing = "Votre hôpital a échoué aux objectifs de ce niveau. Rétablissez-vous d'ici la fin de l'année prochaine, sinon vous êtes éliminé de la course."
multiplayer_window.race_failing_other = "%s a échoué aux objectifs de ce niveau ; il est éliminé s'il échoue encore l'année prochaine."
multiplayer_window.race_left_end = "Vous avez quitté la course. Les autres continuent pour les places suivantes."
multiplayer_window.race_out[1] = "Mauvaise nouvelle."
multiplayer_window.race_out[2] = "Votre hôpital a échoué aux objectifs de ce niveau deux ans de suite : il est éliminé de la course, à la place : %s."
multiplayer_window.race_out[3] = "Retourner au salon, ou regarder les autres ?"
multiplayer_window.race_out_other = "%s a échoué aux objectifs deux ans de suite et est éliminé de la course (place : %s)."
multiplayer_window.race_out_short = "éliminé"
multiplayer_window.race_over[1] = "La course est finie. Classement final :"
multiplayer_window.race_over[2] = "Retourner au salon, ou continuer à jouer ?"
multiplayer_window.race_over_won = "Félicitations, votre équipe a gagné la course ! Classement final :"
multiplayer_window.race_placed_other = "%s a atteint les objectifs de ce niveau : place %s. La course continue."
multiplayer_window.race_standing = "%s %s"
multiplayer_window.race_standing_out = " (éliminé)"
multiplayer_window.race_watch = "Regarder"
multiplayer_window.race_won[1] = "Félicitations !"
multiplayer_window.race_won[2] = "Votre hôpital a atteint les objectifs de ce niveau : place %s."
multiplayer_window.race_won[3] = "Les autres courent pour les places suivantes. Retourner au salon, ou regarder ?"
multiplayer_window.race_won_question = "Les autres courent pour les places suivantes. Voulez-vous retourner au salon ?"
multiplayer_window.race_won_allies = "Vous et %s y êtes arrivés ! Bien joué !"
multiplayer_window.race_won_allies_first = "Vous et %s avez réussi ! Excellent travail !"
multiplayer_window.race_won_first = "Votre hôpital est le premier à atteindre tous les objectifs de %s. Vous avez gagné la course !"
multiplayer_window.race_won_place = "Votre hôpital a atteint tous les objectifs de %s : place %s."
multiplayer_window.race_won_team_first = "Votre équipe est la première à atteindre tous les objectifs de %s. Vous avez gagné la course !"
multiplayer_window.race_won_team_place = "Votre équipe a atteint tous les objectifs de %s : place %s."
multiplayer_window.race_won_together = "Vous y êtes arrivés ensemble ! Bien joué !"
multiplayer_window.race_won_together_first = "Vous avez réussi ensemble ! Excellent travail !"
multiplayer_window.race_won_well_done = "Bien joué !"
multiplayer_window.rat_attacks = "attaques de rats"
multiplayer_window.rats_off = "Attaque de rats (courses) : non autorisée"
multiplayer_window.rats_on = "Attaque de rats (courses) : autorisée"
multiplayer_window.ready = "Prêt"
multiplayer_window.rebuild_destroyed_room = "Cette salle a été détruite. La déblayer pour $%d et la reconstruire ?"
multiplayer_window.recommendation = "Jusqu'à %s ; les actions prennent %s ms"
multiplayer_window.refer_button = "Adresser le patient"
multiplayer_window.refer_choose = "Adresser à quel hôpital ?"
multiplayer_window.refer_fax_choice = "Adresser à un autre hôpital"
multiplayer_window.referral_cured_here_note = "Vous avez guéri un patient adressé par %s : +%d de réputation en plus."
multiplayer_window.referral_cured_note = "%s a guéri le patient que vous avez adressé : +%d de réputation."
multiplayer_window.refresh = "Actualiser"
multiplayer_window.rep_amount = "Points : %d"
multiplayer_window.rep_give_button = "Donner %d de vos points de réputation"
multiplayer_window.rep_given_note = "Vous vous êtes porté garant de %s : vous avez donné %d points de réputation."
multiplayer_window.rep_received_note = "%s se porte garant de votre hôpital : vous avez gagné %d points de réputation."
multiplayer_window.rep_rivals = "Seuls les alliés peuvent se porter garants les uns des autres."
multiplayer_window.rep_sent = "C'est fait. Les points passent dans un instant."
multiplayer_window.rep_vouch_caption = "Garantie : donnez de votre réputation"
multiplayer_window.repair_destroyed_room = "Cette salle a été détruite. La réparer pour $%d, le prix d'une neuve avec son mobilier ? (Non : la déblayer plutôt.)"
multiplayer_window.research_accept = "J'ACCEPTE ce savoir de recherche"
multiplayer_window.research_accept_price = "J'ACCEPTE ce savoir de recherche pour $%d"
multiplayer_window.research_accepted_note = "%s a accepté votre recherche (il a payé $%d)."
multiplayer_window.research_all = "Tout"
multiplayer_window.research_and_more = "et %d de plus"
multiplayer_window.research_bought_transaction = "Recherche de %s"
multiplayer_window.research_caption = "Partager la recherche avec %s"
multiplayer_window.research_decline = "JE REFUSE ce savoir de recherche"
multiplayer_window.research_declined_note = "%s a refusé votre recherche."
multiplayer_window.research_free = "Prix : gratuit"
multiplayer_window.research_free_line = "GRATUIT : ce transfert ne coûte rien."
multiplayer_window.research_item_drug = "Médicament : %s"
multiplayer_window.research_item_machine = "Amélioration : %s"
multiplayer_window.research_known_note = "Vous connaissez déjà toute cette recherche."
multiplayer_window.research_known_sender_note = "%s connaissait déjà toute cette recherche."
multiplayer_window.research_next = "Plus"
multiplayer_window.research_no_money_note = "Vous ne pouvez pas payer cette recherche ($%d)."
multiplayer_window.research_no_money_sender_note = "%s n'a pas pu payer votre recherche."
multiplayer_window.research_none = "Vous n'avez aucune recherche qui leur manque."
multiplayer_window.research_none_selected = "Choisissez d'abord une recherche."
multiplayer_window.research_offer = "Proposer"
multiplayer_window.research_offer_line = "%s veut partager avec vous la recherche suivante :"
multiplayer_window.research_offered = "Proposé. En attente de sa réponse."
multiplayer_window.research_page = "Page %d sur %d"
multiplayer_window.research_previous = "Retour"
multiplayer_window.research_price = "Prix : $%d"
multiplayer_window.research_price_line = "PRIX : $%d. Vous ne payez que si vous acceptez."
multiplayer_window.research_received_note = "Nouvelle recherche : %s."
multiplayer_window.research_sent_note = "Recherche proposée à %s. En attente de sa réponse."
multiplayer_window.research_sold_transaction = "Recherche vendue à %s"
multiplayer_window.room_caption = "Salon : %s"
multiplayer_window.room_hint = "Même couleur : un seul hôpital. Même équipe : vous gagnez ensemble."
multiplayer_window.room_line = "%s   %d sur %d   %s   niveau %s%s"
multiplayer_window.rooms_caption = "Salons sur %s"
multiplayer_window.sabotage_again = "Cliquez encore sur L%d pour l'acheter pour $%d."
multiplayer_window.sabotage_alone = "Il ne reste aucun rival à qui jouer des tours."
multiplayer_window.sabotage_arrived = "Votre agent d'entretien malveillant a commencé à travailler chez %s."
multiplayer_window.sabotage_boiler = "Chaudière en panne"
multiplayer_window.sabotage_boiler_notice = "La chaudière est tombée en panne, et ce n'était pas un accident. Vos agents d'entretien la réparent : plus ils sont nombreux, plus vite c'est fait."
multiplayer_window.sabotage_caption = "Coups bas contre %s"
multiplayer_window.sabotage_caught = "Vous avez renvoyé un agent d'entretien qui n'était pas à vous : %s l'avait envoyé. Il retourne chez eux."
multiplayer_window.sabotage_caught_owner = "%s a démasqué votre agent d'entretien malveillant. Il revient travailler pour vous."
multiplayer_window.sabotage_close = "Fermer"
multiplayer_window.sabotage_done.boiler = "La chaudière de %s est tombée en panne."
multiplayer_window.sabotage_done.emergency = "Une urgence arrive chez %s."
multiplayer_window.sabotage_done.epidemic = "Les patients contagieux arrivent chez %s."
multiplayer_window.sabotage_done.espionage = "Votre espion est allé chez %s."
multiplayer_window.sabotage_done.handyman = "Votre agent d'entretien malveillant est en route vers %s."
multiplayer_window.sabotage_done.headhunter = "Votre chasseur de têtes a fait une offre à un membre du personnel de %s."
multiplayer_window.sabotage_done.rats = "Les rats s'installent chez %s."
multiplayer_window.sabotage_done.smear = "La campagne de calomnie contre %s a commencé."
multiplayer_window.sabotage_emergency = "Urgence"
multiplayer_window.sabotage_emergency_fax[1] = "Une urgence vous a été envoyée, et vous ne pouvez pas la refuser."
multiplayer_window.sabotage_emergency_fax[2] = "%d patients atteints de %s arrivent en hélicoptère."
multiplayer_window.sabotage_emergency_fax[3] = "Soignez-en autant que possible avant la fin du temps imparti."
multiplayer_window.sabotage_epidemic = "Épidémie"
multiplayer_window.sabotage_espionage = "Espionnage"
multiplayer_window.sabotage_espionage_got = "Votre espion a rapporté : %s."
multiplayer_window.sabotage_espionage_notice = "Quelqu'un a copié des fichiers du département de recherche."
multiplayer_window.sabotage_espionage_notice_3 = "Quelqu'un s'est introduit dans le département de recherche : fichiers copiés, et la recherche en cours est retardée de moitié."
multiplayer_window.sabotage_handyman = "Agent malveillant"
multiplayer_window.sabotage_handyman_hint = {"Votre matériel tombe souvent en panne ces derniers temps. Y aurait-il un agent d'entretien malveillant dans votre hôpital ?", "Tout va de travers ici. Chacun de vos agents d'entretien est-il vraiment à vous ? Renvoyez-en un qui ne l'est pas.", "Un agent d'entretien que personne ne se rappelle avoir engagé erre dans vos couloirs. Regardez vos agents d'entretien : un inconnu peut être renvoyé."}
multiplayer_window.sabotage_headhunter = "Chasseur de têtes"
multiplayer_window.sabotage_headhunter_left = "%s est parti pour une meilleure offre."
multiplayer_window.sabotage_headhunter_notice = "%s a reçu une meilleure offre d'un autre hôpital et demande une augmentation de $%d. Acceptez sous 10 jours, ou il part."
multiplayer_window.sabotage_headhunter_won = "%s a quitté son hôpital et figure sur la liste d'embauche : engagez-le sous %d jours, avant que d'autres le puissent."
multiplayer_window.sabotage_level = "L%d  $%d"
multiplayer_window.sabotage_level_locked = "L%d  mois %d"
multiplayer_window.sabotage_level_off = "L%d  non"
multiplayer_window.sabotage_levels.boiler[1] = "Leur chaudière tombe en panne : trop froid en hiver, trop chaud en été, jusqu'à ce que leurs agents d'entretien la réparent (réparation courte)."
multiplayer_window.sabotage_levels.boiler[2] = "Leur chaudière tombe en panne, environ deux fois plus longtemps. Plus d'agents d'entretien la réparent plus vite."
multiplayer_window.sabotage_levels.boiler[3] = "Leur chaudière tombe gravement en panne : longue réparation. Plus d'agents d'entretien la réparent plus vite."
multiplayer_window.sabotage_levels.emergency[1] = "Une urgence qu'ils ne peuvent pas refuser : 3 patients en hélicoptère, atteints d'une maladie qu'ils connaissent."
multiplayer_window.sabotage_levels.emergency[2] = "Une urgence qu'ils ne peuvent pas refuser : 6 patients en hélicoptère, atteints d'une maladie qu'ils connaissent."
multiplayer_window.sabotage_levels.emergency[3] = "Une urgence qu'ils ne peuvent pas refuser : 10 patients en hélicoptère, peut-être atteints d'une maladie qu'ils n'ont pas découverte."
multiplayer_window.sabotage_levels.epidemic[1] = "2 patients contagieux d'une même maladie arrivent dans leur hôpital."
multiplayer_window.sabotage_levels.epidemic[2] = "4 patients contagieux d'une même maladie arrivent dans leur hôpital."
multiplayer_window.sabotage_levels.epidemic[3] = "7 patients contagieux d'une même maladie arrivent dans leur hôpital."
multiplayer_window.sabotage_levels.espionage[1] = "Copiez une amélioration de médicament ou de machine qu'ils ont et pas vous : vous choisissez laquelle."
multiplayer_window.sabotage_levels.espionage[2] = "Copiez une découverte (une machine ou une salle) qu'ils ont et pas vous : vous choisissez laquelle."
multiplayer_window.sabotage_levels.espionage[3] = "Copiez deux de leurs améliorations ou découvertes (à votre choix) et retardez de moitié leur recherche en cours."
multiplayer_window.sabotage_levels.handyman[1] = "Un agent d'entretien qui ressemble au leur mais ne fait rien, pendant 4 mois. S'ils le trouvent et le renvoient, il vient travailler pour vous."
multiplayer_window.sabotage_levels.handyman[2] = "Comme L1, et il jette des détritus dans leurs couloirs deux fois par jour, pendant 3 mois."
multiplayer_window.sabotage_levels.handyman[3] = "Comme L2, et tous les 3 jours il fait semblant de réparer une machine, qu'il laisse presque en panne. Reste 2 mois."
multiplayer_window.sabotage_levels.headhunter[1] = "Leur meilleur interne ou infirmier reçoit une meilleure offre : ils paient 50 pour cent d'augmentation sous 10 jours, ou le perdent vers la liste d'embauche (gardé pour vous 2 semaines)."
multiplayer_window.sabotage_levels.headhunter[2] = "Leur meilleur médecin reçoit une meilleure offre : ils paient 75 pour cent d'augmentation sous 10 jours, ou le perdent vers la liste d'embauche (gardé pour vous 2 semaines)."
multiplayer_window.sabotage_levels.headhunter[3] = "Leur meilleur consultant ou spécialiste reçoit une meilleure offre : ils doublent son salaire sous 10 jours, ou le perdent vers la liste d'embauche (gardé pour vous 2 semaines)."
multiplayer_window.sabotage_levels.rats[1] = "5 rats s'installent. Tant qu'ils courent, ils leur coûtent jusqu'à 1 de réputation par jour (jusqu'à 30 jours), jusqu'à ce qu'on les abatte."
multiplayer_window.sabotage_levels.rats[2] = "10 rats s'installent. Tant qu'ils courent, ils leur coûtent jusqu'à 2 de réputation par jour (jusqu'à 30 jours), jusqu'à ce qu'on les abatte."
multiplayer_window.sabotage_levels.rats[3] = "20 rats s'installent. Tant qu'ils courent, ils leur coûtent jusqu'à 3 de réputation par jour (jusqu'à 30 jours), jusqu'à ce qu'on les abatte."
multiplayer_window.sabotage_levels.smear[1] = "Mauvaise presse pendant un mois : 3 nouveaux patients sur 10 vont dans les autres hôpitaux."
multiplayer_window.sabotage_levels.smear[2] = "Mauvaise presse pendant 2 mois : 4 nouveaux patients sur 10 vont dans les autres hôpitaux."
multiplayer_window.sabotage_levels.smear[3] = "Mauvaise presse pendant 3 mois : la moitié de leurs nouveaux patients vont dans les autres hôpitaux."
multiplayer_window.sabotage_locked_tooltip = "A ce niveau, on peut l'acheter à partir du mois %d de la partie."
multiplayer_window.sabotage_next = "Rival suivant"
multiplayer_window.sabotage_off_tooltip = "L'hôte n'a pas autorisé ce coup bas dans cette partie (options de jeu)."
multiplayer_window.sabotage_pick = "Cliquez sur un niveau pour voir son effet. Cliquez encore pour l'acheter."
multiplayer_window.sabotage_rats = "Attaque de rats"
multiplayer_window.sabotage_rats_notice = "Des rats ! Une horde s'est installée dans l'hôpital. Tant qu'ils courent, ils coûtent de la réputation chaque jour : cliquez dessus pour les abattre."
multiplayer_window.sabotage_rats_reminder = "%d rats courent encore dans l'hôpital et coûtent de la réputation chaque jour."
multiplayer_window.sabotage_rats_reminders = {"%d rats courent encore dans l'hôpital et coûtent de la réputation chaque jour. Cliquez dessus pour les abattre.", "Les rats sont toujours là, %d en tout, et les patients en parlent. Abattez-les !", "Votre hôpital a encore %d rats. Chaque jour qu'ils restent vous coûte de la réputation."}
multiplayer_window.sabotage_refused = "Ce coup bas est impossible : %s."
multiplayer_window.sabotage_sent = "Commandé. Vous payez une fois fait."
multiplayer_window.sabotage_smear = "Campagne de calomnie"
multiplayer_window.sabotage_smear_notice = "Mauvaise presse : une campagne de calomnie contre l'hôpital éloigne certains patients pendant %d mois."
multiplayer_window.sabotage_smear_over = "La campagne de calomnie est finie : les patients reviennent à l'hôpital comme avant."
multiplayer_window.sabotage_spy_caption = "Espionner %s : choisir %d"
multiplayer_window.sabotage_spy_pick = "Choisissez ce que votre espion doit copier, puis appuyez sur Voler."
multiplayer_window.sabotage_spy_steal = "Voler ($%d)"
multiplayer_window.sabotage_transaction = "Coups bas"
multiplayer_window.sabotage_went_home = "Le séjour de votre agent d'entretien malveillant chez %s est terminé. Il est rentré."
multiplayer_window.saved_flag = "  partie sauvegardée"
multiplayer_window.saved_note = "Partie sauvegardée : %s"
multiplayer_window.saving_note = "Sauvegarde de la partie sur l'ordinateur de chaque joueur..."
multiplayer_window.select_room = "Choisissez d'abord un salon."
multiplayer_window.server = "Serveur"
multiplayer_window.server_eu1 = "EU1 : stable"
multiplayer_window.server_eu2 = "EU2 : versions de test"
multiplayer_window.server_version = "la version du serveur"
multiplayer_window.share_research = "Partager la recherche"
multiplayer_window.shared_won = "Le passage au niveau suivant n'est pas disponible en multijoueur."
multiplayer_window.sharing_off = "Partage de recherche : non"
multiplayer_window.sharing_on = "Partage de recherche : oui"
multiplayer_window.staff_arrived_note = "%s est arrivé et commence à travailler."
multiplayer_window.staff_bought_transaction = "Personnel de %s"
multiplayer_window.staff_on_the_way = "En route vers %s"
multiplayer_window.staff_received_note = "%s vous a envoyé un membre du personnel : %s"
multiplayer_window.staff_sold_transaction = "Personnel pour %s"
multiplayer_window.start = "Lancer la partie"
multiplayer_window.team_button = "Équipe %d"
multiplayer_window.team_lost = "%s a encore échoué aux objectifs de ce niveau à la fin de l'année, donc l'équipe a perdu le niveau."
multiplayer_window.team_member_out = "Votre hôpital a échoué aux objectifs de ce niveau deux ans de suite et est éliminé de la course. Votre équipe continue."
multiplayer_window.team_member_out_other = "%s a échoué aux objectifs deux ans de suite et est éliminé de la course ; son équipe continue."
multiplayer_window.team_race_mate_reached_fax[1] = "Votre coéquipier %s a atteint les objectifs de ce niveau !"
multiplayer_window.team_race_mate_reached_fax[2] = "Votre équipe gagne dès que votre hôpital y arrive aussi. Reste à faire : %s."
multiplayer_window.team_race_mate_reached_fax[3] = "Votre coéquipier peut vous aider avec de l'argent, du personnel ou des patients."
multiplayer_window.team_race_reached_fax[1] = "Votre hôpital a atteint les objectifs de ce niveau !"
multiplayer_window.team_race_reached_fax[2] = "La course n'est pas encore gagnée : votre équipe gagne dès que chacun de ses hôpitaux y arrive. Reste à faire : %s."
multiplayer_window.team_race_reached_fax[3] = "Faites tourner votre hôpital, et aidez-les avec de l'argent, du personnel ou des patients."
multiplayer_window.team_race_reached_other = "%s a atteint les objectifs de ce niveau (équipe %s)."
multiplayer_window.team_won[1] = "Félicitations !"
multiplayer_window.team_won[2] = "Chaque hôpital a atteint les objectifs de ce niveau : l'équipe a gagné le niveau."
multiplayer_window.team_won[3] = "Retourner au salon, ou continuer à jouer ?"
multiplayer_window.too_many_hospitals = "Ce niveau accueille %d hôpitaux : partagez des couleurs"
multiplayer_window.trade_alone = "Personne avec qui échanger."
multiplayer_window.trade_caption = "Échanger avec %s"
multiplayer_window.trade_close = "Fermer"
multiplayer_window.trade_free = "Prix : gratuit"
multiplayer_window.trade_money_allies_only = "L'argent ne va qu'aux alliés."
multiplayer_window.running_flag = "en cours"
multiplayer_window.running_places = "en cours, %d libres"
multiplayer_window.seats_caption = "Places dans %s"
multiplayer_window.seats_hint = "Prenez la place d'un bot ou d'un joueur parti :"
multiplayer_window.seat_on = "%s, en jeu"
multiplayer_window.seat_bot = "%s (bot)"
multiplayer_window.seat_standin = "%s (parti, un bot joue en attendant)"
multiplayer_window.seat_left = "%s (parti)"
multiplayer_window.players_standin = "absent, un bot joue"
multiplayer_window.players_bot = "bot"
multiplayer_window.trade_next_player = "Joueur suivant"
multiplayer_window.trade_no_staff = "Vous n'avez pas de personnel à envoyer."
multiplayer_window.trade_offered = "Proposé. Il vous rejoint si l'autre joueur accepte."
multiplayer_window.trade_on_the_way = "- proposé"
multiplayer_window.trade_price = "Prix : $%d"
multiplayer_window.trade_select_staff = "Cliquez d'abord sur un membre du personnel."
multiplayer_window.trade_send_money = "Envoyer $%d"
multiplayer_window.trade_send_staff = "Proposer le personnel choisi"
multiplayer_window.trade_sent = "Envoyé. Il arrive dans un instant."
multiplayer_window.tricks_off = "Coups bas (courses) : non"
multiplayer_window.tricks_on = "Coups bas (courses) : oui"
multiplayer_window.vaccination_mode_hint = "Mode vaccination : cliquez sur les patients infectés pour qu'une infirmière les vaccine. Clic droit, Échap ou un nouveau clic sur la seringue pour arrêter."
multiplayer_window.vote_agree = "D'accord"
multiplayer_window.vote_asked = "Vous avez demandé aux autres de passer la vitesse à %s."
multiplayer_window.vote_confirm = "Demander aux autres joueurs de passer la vitesse du jeu à %s ?"
multiplayer_window.vote_decline = "Refuser"
multiplayer_window.vote_declined = "%s a refusé le passage à la vitesse %s."
multiplayer_window.vote_lapsed = "Pas assez de joueurs d'accord à temps : la vitesse reste inchangée."
multiplayer_window.vote_open = "Un changement de vitesse est déjà soumis au vote."
multiplayer_window.vote_passed = "Les joueurs sont d'accord : la vitesse est maintenant %s."
multiplayer_window.vote_passed_paused = "Les joueurs ont choisi %s : la partie continuera à cette vitesse à la fin de la pause."
multiplayer_window.vote_request = "%s voudrait changer la vitesse du jeu"
multiplayer_window.vote_request_speed = "à %s."
multiplayer_window.waiting_player = "en attente d'un joueur..."
tooltip.main_menu.multiplayer = "Jouer avec d'autres via un serveur multijoueur (expérimental)"
tooltip.multiplayer_window.bot_level = "Clic droit : un bot facile, normal ou difficile"
tooltip.multiplayer_window.ask_money = "Demandez de l'argent à un autre joueur. Il décide de payer ou non."
tooltip.multiplayer_window.auctions = "L'hôte décide quelles parcelles vont aux enchères quand un joueur demande à en acheter une"
tooltip.multiplayer_window.auctions_all = "Chaque parcelle va aux enchères entre tous les hôpitaux qui peuvent l'acheter"
tooltip.multiplayer_window.auctions_near = "Les parcelles du côté d'un autre joueur ou à côté du terrain d'un autre hôpital vont aux enchères ; les autres s'achètent simplement"
tooltip.multiplayer_window.auctions_none = "Pas d'enchères : le premier qui demande achète la parcelle"
tooltip.multiplayer_window.colour = "La couleur de votre hôpital : les joueurs de même couleur construisent un seul hôpital ensemble. Cliquez pour la changer (l'hôte peut changer celle de tout le monde, bots compris)"
tooltip.multiplayer_window.connect = "Se connecter au serveur et afficher ses salons"
tooltip.multiplayer_window.continue_game = "Reprendre une partie multijoueur sauvegardée (Fichier > Sauvegarder, ou la sauvegarde automatique mensuelle) : choisissez-la dans la liste. Sans sauvegarde, le salon démarre une nouvelle partie"
tooltip.multiplayer_window.download = "Ce serveur utilise une autre version du jeu : ouvrez sa page de téléchargement dans votre navigateur"
tooltip.multiplayer_window.game_options = "Les options de la partie : enchères de terrain et plus (réglées par l'hôte)"
tooltip.multiplayer_window.helpers = "L'hôte décide : un bot qui partage l'hôpital d'un joueur construit des salles et place des objets dans les couloirs, ou laisse cela au joueur (il embauche toujours, paie des primes, partage la recherche, enchérit et achète des terrains)"
tooltip.multiplayer_window.level = "Choisissez le niveau dans une liste avec ses objectifs et une carte. Un hôpital commun joue les niveaux de la campagne ; plusieurs hôpitaux jouent les niveaux multijoueur (1 à 8, un numéro plus élevé joue le niveau 8). Le niveau 6 est Urgence ! : des urgences quatre fois par mois la première année, puis des épidémies ; le niveau 7 est Sans pitié, fait pour une course compétitive : coups bas mois après mois, salons de l'emploi, urgences de course et séismes ; le niveau 8 est Team Town, la carte de Matroftt faite pour du deux contre deux"
tooltip.multiplayer_window.levels_players = "La carte pour ce nombre de joueurs (chaque nombre de joueurs a sa propre carte)"
tooltip.multiplayer_window.name = "Le nom que voient les autres joueurs"
tooltip.multiplayer_window.new_game = "Démarrer une nouvelle partie au lieu de la sauvegarde"
tooltip.multiplayer_window.password = "Mot de passe du salon à rejoindre ou à créer (vide : pas de mot de passe)"
tooltip.multiplayer_window.player_row = "Clic : voir l'hôpital de ce joueur (N : l'hôpital suivant)"
tooltip.multiplayer_window.chat_target = "À qui va le message : tout le monde, votre équipe (dans une course d'équipes) ou un joueur. Cliquez ou appuyez sur Tab pour le suivant"
tooltip.multiplayer_window.players = "Pour combien de joueurs est le salon"
tooltip.multiplayer_window.rats = "L'hôte décide : dans une course avec coups bas, les joueurs peuvent lâcher des rats dans l'hôpital d'un rival (cela lui coûte de la réputation), ou non"
tooltip.multiplayer_window.ready = "Dites à l'hôte que vous êtes prêt à commencer"
tooltip.multiplayer_window.refer_button = "Proposez ce patient à l'hôpital d'un autre joueur. Il doit accepter."
tooltip.multiplayer_window.send_staff = "Envoyez ce membre du personnel à l'hôpital d'un autre joueur. Il doit accepter."
tooltip.multiplayer_window.server = "Adresse du serveur multijoueur, par exemple eu2.bachelor-tech.com:47800"
tooltip.multiplayer_window.server_eu1 = "eu1.bachelor-tech.com : la dernière version stable"
tooltip.multiplayer_window.server_eu2 = "eu2.bachelor-tech.com : la dernière version de test"
tooltip.multiplayer_window.share_research = "Proposez la recherche que vous avez à l'hôpital d'un autre joueur, gratuitement ou contre un prix. Il doit accepter."
tooltip.multiplayer_window.sharing = "L'hôte décide : les joueurs peuvent se partager ou se vendre la recherche, ou non (comme dans le jeu d'origine)"
tooltip.multiplayer_window.start = "Lancer la partie pour tout le monde dans le salon"
tooltip.multiplayer_window.team = "Votre équipe : la même équipe gagne ensemble, des équipes différentes courent vers les objectifs et peuvent se jouer des coups bas. Cliquez pour la changer (l'hôte peut changer celle de tout le monde, bots compris)"
tooltip.multiplayer_window.tricks = "L'hôte décide : en course, les joueurs peuvent acheter des coups bas contre leurs rivaux, ou non (comme dans le jeu d'origine)"
