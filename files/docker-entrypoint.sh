#!/bin/sh
#shellcheck disable=SC2153,SC2039

set -eu

if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
        if [ -z "$HOST_PRIV_KEY_RSA" ]; then
            # Neuen RSA-Key erzeugen - Achtung, dieser ändert sich mit jedem neuen Container
            ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa > /dev/null 2>&1
            echo "***** PLEASE SET HOST_PRIV_KEY_RSA VARIABLE TO: *****"
            cat /etc/ssh/ssh_host_rsa_key
            echo "*****************************************************"
        else
            echo "$HOST_PRIV_KEY_RSA" > /etc/ssh/ssh_host_rsa_key
            chown root.root /etc/ssh/ssh_host_rsa_key
            chmod 600 /etc/ssh/ssh_host_rsa_key
        fi
fi
unset HOST_PRIV_KEY_RSA

if [ ! -f "/etc/ssh/ssh_host_ed25519_key" ]; then
        if [ -z "$HOST_PRIV_KEY_ED25519" ]; then
            # Neuen ED25519-Key erzeugen - Achtung, dieser ändert sich mit jedem neuen Container
            ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t ed25519 > /dev/null 2>&1
            echo "***** PLEASE SET HOST_PRIV_KEY_ED25519 VARIABLE TO: *****"
            cat /etc/ssh/ssh_host_ed25519_key
            echo "*********************************************************"
        else
            echo "$HOST_PRIV_KEY_ED25519" > /etc/ssh/ssh_host_ed25519_key
            chown root.root /etc/ssh/ssh_host_ed25519_key
            chmod 600 /etc/ssh/ssh_host_ed25519_key
        fi

fi
unset HOST_PRIV_KEY_ED25519


# Verarbeitung von Benutzereinträgen
if [ ${USERS+x} ]; then
    for ENTRY in $USERS;
    do
        USERNAME=$(echo "$ENTRY" | cut -d ':' -f 1)
        PASSWORD=$(echo "$ENTRY" | cut -d ':' -f 2 -s)
        STATUS=$(echo "$ENTRY" | cut -d ':' -f 3 -s)
        
        USER_EXISTS=$(id "$USERNAME" 2> /dev/null || echo "")
        # Benutzer nur anlegen, wenn noch nicht existiert
        _LOG_LINE="* Benutzer $USERNAME ($UID_MIN)\\n"
        if [ -z "$USER_EXISTS" ]; then
            adduser -h "/$USERNAME" -g "SFTP User" -s /bin/false -G sftpuser -D -H -u "$UID_MIN" "$USERNAME"
            _LOG_LINE="$_LOG_LINE  * Account neu erzeugt\\n"
        fi

        # Benutzer sperren bzw. freigeben und Passwort setzen
        if [ ${STATUS+x} ] && [ "$STATUS" = "disabled" ]; then
            passwd -l "$USERNAME" > /dev/null 2>&1 || true
            _LOG_LINE="$_LOG_LINE  * Account gesperrt\\n"
        else
            if [ -n "$PASSWORD" ]; then
                echo "$USERNAME:$PASSWORD" | chpasswd > /dev/null 2>&1
                _LOG_LINE="$_LOG_LINE  * Passwort gesetzt\\n"
            else
                passwd -d "$USERNAME" > /dev/null 2>&1
                _LOG_LINE="$_LOG_LINE  * Passwort geleert\\n"
            fi
            # Wenn Benutzername bereits existierte, sicherheitshalber wieder freischalten
            if [ -n "$USER_EXISTS" ]; then 
                passwd -u "$USERNAME" > /dev/null 2>&1
            fi
        fi


        # Public Keys hinterlegen oder Datei löschen, wenn Benutzer gesperrt ist.
        if [ ${STATUS+x} ] && [ "$STATUS" = "disabled" ]; then
            rm -f /etc/ssh/authorized_keys/"$USERNAME"
        else
            echo "$USER_KEYS_BASE" > /etc/ssh/authorized_keys/"$USERNAME"
            KEYS=$(eval test "\${USER_KEYS_$USERNAME+x}" && eval echo "\$USER_KEYS_$USERNAME" || echo "")
            # Default-Keys nutzen, wenn keine benutzerspezifischen Keys angegeben wurden
            if [ -z "$KEYS" ]; then
                echo "$USER_KEYS_DEFAULT" >> /etc/ssh/authorized_keys/"$USERNAME"
                _LOG_LINE="$_LOG_LINE  * Default-Keys installiert\\n"
            else
                echo "$KEYS" >> /etc/ssh/authorized_keys/"$USERNAME"
                _LOG_LINE="$_LOG_LINE  * User-Keys installiert\\n"
            fi
        fi
        eval unset "USER_KEYS_$USERNAME"


        # Standardverzeichnisse erzeugen und Rechte passend ändern. Wird nur initial durchgeführt.
        HOME_DIR=/srv/sftpuser/"$USERNAME"
        if [ ! -d "$HOME_DIR" ]; then        
            DIRS=$(eval test "\${USER_DIRS_$USERNAME+x}" && eval echo "\$USER_DIRS_$USERNAME" || echo "")
            
            # Wenn HOME_DIR existiert, keine neuen Verzeichnisse anlegen
            if [ -z "$DIRS" ]; then
                DIRS="$USER_DIRS_DEFAULT"
            fi    
            DIRS="$DIRS $USER_DIRS_BASE"
            
            # Wenn keine Standardverzeichnisse angelegt werden nur Benutzerverzeichnis anlegen.
            if [ -z "$DIRS" ]; then
                mkdir -p "$HOME_DIR"
            else
                _LOG_LINE="$_LOG_LINE  * Unterverzeichnisse erzeugt: \\n"
                for DIR in $DIRS;
                do
                    mkdir -p "$HOME_DIR"/"$DIR"
                    _LOG_LINE="$_LOG_LINE    * $DIR \\n"
                done
            fi

            # Berechtigungen für alle (neu angelegten) Verzeichnisse anpassen
            chown -R "$USERNAME".sftpuser "$HOME_DIR"
            chmod -R 700 "$HOME_DIR"
        else
            _LOG_LINE="$_LOG_LINE  * Benutzerverzeichnis existiert bereits (keine Verzeichnisse erzeugt)\\n"
        fi
        eval unset "USER_DIRS_$USERNAME"

        echo -e "$_LOG_LINE"

        # User-ID hochzählen
        UID_MIN=$(( UID_MIN + 1 ))
    done
    unset USER_DIRS_DEFAULT USER_DIRS_BASE
    unset USER_KEYS_DEFAULT USER_KEYS_BASE
    unset USERS
fi

#prepare run dir
if [ ! -d "/var/run/sshd" ]; then
        mkdir -p /var/run/sshd
fi

exec "$@"