# Quiz Clash 0.1.0 – Testversion
Eigenständige native Android-App im selben Repository, ohne Änderungen an Brain Clash. Package ch.quizclash.mobile. Keine Internetberechtigung oder Registrierung. Deutschschweizer Schulquiz, 1–9, kein Rechnen.

## Fragen
Die Deep-Research-Originaldatei mit 5'400 Datensätzen ist im Entwicklungszugriff nicht verfügbar. Diese Version enthält ausschliesslich 27 separat erstellte Demo-Fragen (3 pro Klasse). Im Menü **Fragenbank importieren** die ursprüngliche JSON-Datei aus dem Forschungsbericht auswählen. Import ersetzt die Demo-Bank lokal, prüft Pflichtfelder, vier unterschiedliche Antworten (oder zwei für Richtig/Falsch), gültige Lösung, IDs, Klassen und exakte Duplikate pro Klasse/Fach. Unbrauchbare Datensätze werden übersprungen und gemeldet; eine vollständig ungültige Datei ersetzt die vorhandene Bank nicht. Importierte Inhalte sind nicht redaktionell freigegeben. Das Originalschema konnte nicht verifiziert werden; gängige deutsche und englische Feldnamen werden unterstützt. Eingabe: JSON-Array oder Objekt mit questions/fragen/items/data. Korrekte Antwort als zero-based correct_index oder eindeutiger Antworttext. Maximal 24 MiB, 20'000 Zeilen. Keine Übernahme ungeprüfter Zahlen als angeblich geprüfte Fragen.
 
## Funktionen
Klasse wählen, ein oder mehrere Fächer, 5/10/20 Fragen, Lernmodus ohne Timer, tägliche Challenge pro Klasse, Fehlertraining, 100 Punkte je richtige Antwort plus 25 Serienbonus ab dritter richtiger Antwort; kein Punktabzug. XP und Fehlerliste lokal. Antworten zufällig sortiert, kein Wiederholen innerhalb einer Runde. Fortschritt wird pro beantworteter Frage gespeichert. Import ersetzt Bank und Fehlerhistorie; Gesamtpunkte bleiben. Keine Cloud. Die App ist eine erste Testversion; Duell, weitere Fragetypen, vollständig eingebettete Forschungsbank und redaktionelle Prüfung bleiben offen.
 
## Build
JDK 17, Android SDK 35, Gradle 8.10.2. Im Verzeichnis quiz-clash: gradle :app:assembleDebug. Separate CI unter .github/workflows/quiz-clash-android.yml. Debug-APK, nicht Play-Store-signiert. 
