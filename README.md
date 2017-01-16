# Zoupam

Ce projet est un projet interne visant à mettre à disposition les éléments clés
de nos outils afin de permettre une analyse efficiente de l'avancement des projets.

L'outil est accessible en production sur https://zoupam.occi.tech/

## Vision

Notre transparence nous a amené à suivre notre temps de manière précise afin de fournir
aux clients un détail du temps réellement passé sur leur(s) projet(s).

De plus, afin de permettre un travail en agilité nous proposons en contrepartie d'une
confiance sur les avantages de l'agilité des estimations suivies durant la vie du projet.
Ainsi il nous faut être en mesure de :

* facturer suffisamment de temps aux clients de manière à garder la société rentable
* détecter au plus tôt les erreurs d'estimations significatives, afin de trouver des alternatives
    en collaboration avec les clients
* être en mesure de proposer des délais calendaires en fonction des projets et de la charge à venir
    fin de s'assurer de la préparation des itérations et de la disponibilité des clients
* détecter au plus tôt, et arbitrer, les incohérences de planning (par exemple en cas d'imprévus)
* de rendre compte aux clients du temps réellement passé sur les itérations passées

Zoupam est un outil qui, en s'interconnectant avec nos principaux outils, doit nous aider à atteindre
ces différents objectifs avec le moins de friction possible.

L'outil est donc également amené à évoluer avec nos pratiques.

## Fonctionnalités

* lister les projets / itérations planifiées depuis Redmine
* (en cours) mettre en rapport les estimations et tâches depuis Redmine avec les temps loggués dans Toggl
* (à venir) permettre l'identification rapide des points sensibles et problématiques (dépassements de temps, budget ...)
* (à venir) génération de rapports de suivi

## Installation

* Pré-requis : `docker` et `docker-compose` installés sur la machine
* Exécuter : `make install`

## Exécution

* Installer le logiciel (cf section précédente)
* Pré-requis (suggestion) : conteneur https://github.com/jwilder/nginx-proxy installé et tournant sur le poste
* Exécuter : `make docker_run`
* Se rendre sur http://zoupam.test
* Il est recommandé de garder les logs du serveur de développement sous les yeux, car ce sont ces retours qui permettent
    d'avancer efficacement dans une application Elm : `make logs`

## Déploiement

Les déploiements sont effectués en continus grâce aux outils de CD en place (Jenkins).
Aucun déploiement manuel n'est donc nécessaire.

# License

MIT