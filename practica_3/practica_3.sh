#!/bin/bash
#845154, Lopez Torralba, Alejandro, M, 3, A
#839304, Puig Rubio, Manel Jorda, M, 3, A

if test "$EUID" -ne 0
then
  echo "Este script necesita privilegios de administracion"
  exit 1
fi

if test "$#" -ne 2
then
  echo "Numero incorrecto de parametros"
  exit 1
fi

flag="$1"
nomfichero="$2"

fichero=$(cat "$nomfichero")
IFS=$'\n'
case "$flag" in
  -a)
    for linea in $fichero
    do
      IFS=$','
      read -r login contrasena nombre_completo <<< "$linea"

      if test -z "$login" -o -z "$contrasena" -o -z "$nombre_completo"
      then
        echo "Campo invalido"
        continue
      fi

      if id "$login" &>/dev/null
      then
        echo "El usuario $login ya existe"
        continue
      fi

      useradd -m -p "$(openssl passwd -1 "$contrasena")" -c "$nombre_completo" -e $(date -d "+30days" +%Y-%m-%d) -k /etc/skel -U -K UID_MIN=1815
      echo "$login:$password" | chpasswd

      echo "$nombre_completo ha sido creado"
      IFS=$'\n'
    done ;;
  -s)
    mkdir -p "/extra/backup"
    for linea in $fichero
    do
      IFS=$','
      read -r login resto <<< "$linea"

      if id "$login" &>/dev/null
      then
        usermod -d "/home/$login" -m "$login"
        tar -cf "/extra/backup/$login.tar" -C "/home" "$login"
        if test $? -ne 0
        then
          continue
        fi

        userdel -r "$login" 2>/dev/null
        echo "$login ha sido borrado"
      fi

      IFS=$'\n'
    done ;;
  *)
    echo "Opcion invalida"
    exit 1 ;;
esac
