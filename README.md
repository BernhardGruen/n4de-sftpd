OpenSSH sftp Docker Image
=========================

Benutzer definieren
-------------------

Benutzer können per Variable `USERS` konfiguriert werden. Der Inhalt sollte dabei wie folgt aussehen:

  ```shell
  username:password:[disabled]
  ```

Mit dem optionalen Flag _disabled_ kann ein Account deaktiviert werden. 

Die 3 Goldenen Regeln für Benutzernamen
---------------------------------------

1. Benutzernamen werden immer klein geschrieben und enthalten weder Sonder- noch Leerzeichen!

1. In keinem Fall darf eine einmal angelegte Zeile wieder entfernt oder die Sortierung der Zeilen untereinander nachträglich verändert werden.

1. Passwörter dürfen keine Sonderzeichen oder Leerzeichen enthalten. Die Passwortlänge liegt idealerweise bei >=12 Zeichen aus dem Alphabet `[A-Za-z0-9]` (Erstellbar z.B. mit `pwgen -s 12`).

Public-Keys setzen
------------------

Benutzern können über die Variablen `USER_KEYS_BASE`, `USER_KEYS_DEFAULT` sowie `USER_KEYS_username` Public-Keys in den Formaten _RSA (>=2048 bit)_ und _ED25519_ zugewiesen werden. In jeder der Variablen können prinzipiell mehrere Keys enthalten sein.

* Die Public-Keys aus `USER_KEYS_BASE` werden jedem Benutzer hinzugefügt.
* Die Public-Keys aus `USER_KEYS_DEFAULT` werden einem Benutzer nur zugewiesen, wenn es keine benutzerspezifischen Public-Keys gibt.
* Die Public-Keys aus `USER_KEYS_username` werden nur dem spezifizierten Benutzer hinzugefügt. Dabei ist exakt auf die Groß-/Kleinschreibung des Benutzernames zu achten.

Unterverzeichnisse automatisch erzeugen
-----------------------------------------

Benutzern können über die Variablen `USER_DIRS_BASE`, `USER_DIRS_DEFAULT` sowie `USER_DIRS_username` Unterverzeichnisse mitgegeben werden. Die Variablen dürfen dabei jeweils mehrere Verzeichnisse und sogar komplexe Verzeichnisstrukturen beinhalten.

_Die hier angegebenen Unterverzeichnisse werden nur für einen neu anzulegenden Benutzer erzeugt!_

* Die Verzeichnisse aus `USER_DIRS_BASE` werden bei jedem neu neu angelegten Benutzer erzeugt.
* Die Verzeichnisse aus `USER_DIRS_DEFAULT` werden bei einem neu angelegten Benutzer nur erzeugt, wenn es keine benutzerspezifischen Verzeichnisse angegeben wurden.
* Die Verzeichnisse aus `USER_DIRS_username` werden nur bei dem spezifizierten Benutzer hinzugefügt und nur dann, wenn dieser Benutzer nicht bereits vorher existierte. Dabei ist exakt auf die Groß-/Kleinschreibung des Benutzernames zu achten. Diese Variable überschreibt somit für den angegebenen Benutzer den Inhalt der Variablen `USER_DIRS_DEFAULT`.

Host-Keys definieren
--------------------

Mit die Variablen `HOST_PRIV_KEY_RSA` und `HOST_PRIV_KEY_ED25519` können die zu verwendenden SSH-Host-Keys (Private Schlüssel, den den Host verifizieren) des Systems angegeben werden.
Werden diese Variablen nicht eingegeben, so werden (bei jedem Neustart) neue SSH-Host-Keys erzeugt, was auf den sich verbindenden Systemen zu Warnmeldungen führen kann.
Aus diesem Grund werden die neu erzeugten SSH-Host-Keys in die Log-Ausgabe geschrieben, damit die beiden Variablen spätestens beim zweiten Start korrekt gesetzt werden können.
