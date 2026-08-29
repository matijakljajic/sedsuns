# Library seed data

Ovaj dir sadrži CSV-ove za inicijalno popunjavanje OLTP šeme sistema biblioteke.

## Podaci izvedeni iz izvora ([MTS dataset](https://www.kaggle.com/datasets/sharthz23/mts-library))

* Identifikatori publikacija, naslovi, dostupne godine izdanja i author display names potiču iz `items` MTS dataset-a.
* Informacije o članovima/korisnicima potiču iz `users` dataset-a.
* Datumi pozajmica i veze između publikacija i članova potiču iz `interactions` dataset-a. Interaction je mapiran da se simulira kao pozajmica.

## Sintetički ili izvedeni podaci

* Gradovi, biblioteke, odeljenja, izdavači, ISBN-ovi, publication types, broj stranica i physical copies su generisani.
* Imena članova, email adrese, tačni datumi rođenja, datumi učlanjenja, return dates pozajmica i ujedno statusi, datumi nabavke primeraka i fizičko stanje su generisani.
* Godine publikacija i datumi rođenja članova su deterministički dopunjeni sintetičkim vrednostima.
* Godine rođenja i zemlje autora su većinom obogaćeni podacima preko Wikidata dump-a.
