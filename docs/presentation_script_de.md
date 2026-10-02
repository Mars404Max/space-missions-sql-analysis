# Vortragsskript – erweiterte Analyse

## Folie 1 – Thema
In meinem Projekt analysiere ich historische Raumfahrtmissionen von 1957 bis 2022. Das Ziel ist zu untersuchen, wie sich die Raumfahrt entwickelt hat und welche Unterschiede es bei Aktivität, Erfahrung und Zuverlässigkeit von Raketen und Organisationen gibt.

## Folie 2 – Fragestellung und Analyseplan
Ich betrachte vier Bereiche: die zeitliche Entwicklung, Organisationen, Raketen sowie Startorte und Datenqualität. Dabei möchte ich nicht nur zählen, sondern auch Erfolgsquoten und die Anzahl der bisherigen Missionen miteinander vergleichen.

## Folie 3 – Datensatz und Datenqualität
Der Rohdatensatz enthält 4.630 Zeilen. Es gibt ein vollständiges Duplikat, deshalb bleiben nach der Bereinigung 4.629 Missionen. Außerdem fehlen 127 Uhrzeiten und 3.365 Preisangaben. Deshalb nutze ich die Preise nur ergänzend.

## Folie 4 – ERD
Die CSV-Datei ist zunächst eine flache Tabelle. Ich habe sie in Companies, Rockets, Launch Sites und Missions aufgeteilt. Die Missions-Tabelle ist die zentrale Tabelle und wird über Foreign Keys mit den Stammdaten verbunden.

## Folie 5 – Entwicklung im Zeitverlauf
Hier untersuche ich die Anzahl der Missionen und die Erfolgsquote nach Jahren und Jahrzehnten. Das Jahr mit den meisten Missionen im Datensatz ist 2021 mit 157 Missionen.

## Folie 6 – Missionszuverlässigkeit
Nach der Bereinigung bleiben 4.629 Missionen. Der größte Teil ist erfolgreich. Die globale Erfolgsquote liegt bei ungefähr 89,9 Prozent. Failure, Partial Failure und Prelaunch Failure bleiben getrennt, damit keine Information verloren geht.

## Folie 7 – Aktivste Organisationen
Hier sieht man, welche Organisationen historisch die meisten Missionen durchgeführt haben. RVSN USSR liegt mit 1.777 Missionen mit großem Abstand vorne. Danach folgen CASC, Arianespace und General Dynamics. Wichtig ist, dass die Organisation nicht automatisch mit einem Land gleichgesetzt werden kann.

## Folie 8 – Aktivität und Zuverlässigkeit
Jetzt vergleiche ich die zehn aktivsten Organisationen nicht nur nach Anzahl, sondern auch nach Erfolgsquote. Man sieht, dass viel Erfahrung nicht automatisch eine höhere Erfolgsquote bedeutet. ULA erreicht im Datensatz etwa 99,3 Prozent, während General Dynamics trotz 251 Missionen nur bei ungefähr 80,9 Prozent liegt.

## Folie 9 – Unternehmensvergleich
Diese Tabelle zeigt einige wichtige Organisationen direkt nebeneinander. RVSN USSR hat das größte Volumen, aber nicht die höchste Erfolgsquote. Arianespace und ULA haben höhere Erfolgsquoten. SpaceX und CASC liegen bei ungefähr 94 bis 95 Prozent und gehören eher zur moderneren Phase der Raumfahrt.

## Folie 10 – Raketenvergleich
Auch bei den Raketen gibt es große Unterschiede. Cosmos-3M ist mit 446 Missionen die meistgenutzte Rakete im Datensatz. Voskhod folgt mit 299 Missionen. Moderne Systeme wie Falcon 9 Block 5 haben weniger historische Missionen im Datensatz, aber dort waren bis zum Datenstand 2022 alle 111 erfassten Missionen erfolgreich. Das zeigt, warum man Anzahl und Erfolgsquote gemeinsam betrachten sollte.

## Folie 11 – Startorte und Grenzen
Zusätzlich analysiere ich Startorte. Gleichzeitig gibt es klare Grenzen: Rund 72,7 Prozent der Preisangaben fehlen und der Datensatz endet im August 2022. Deshalb ist die Analyse historisch und keine aktuelle Marktanalyse.

## Folie 12 – Fazit
Die Analyse zeigt die historische Entwicklung der Raumfahrt und ermöglicht einen Vergleich von Organisationen und Raketen nach Erfahrung und Zuverlässigkeit. Ein wichtiges Ergebnis ist, dass hohes Missionsvolumen nicht automatisch höhere Zuverlässigkeit bedeutet. Historische Daten können eine erste Orientierung liefern, für reale heutige Entscheidungen wären aber zusätzliche aktuelle technische und wirtschaftliche Daten notwendig.