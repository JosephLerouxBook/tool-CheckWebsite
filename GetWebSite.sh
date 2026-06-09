#!/bin/bash
echo -e "\e[31m"
cat << "EOF" 
               _                        
               \`*-.                    
                )  _`-.                 
               .  : `. .                
               : _   '  \               
               ; *` _.   `*-._          
               `-.-'          `-.       
                 ;       `       `.     
                 :.       .        \    
                 . \  .   :   .-'   .   
                 '  `+.;  ;  '      :   
                 :  '  |    ;       ;-. 
                 ; '   : :`-:     _.`* ;
              .*' /  .*' ; .*`- +'  `*' 
              `*-*   `*-*  `*-*'  
   ___ _           _  __      __   _    ___ _ _          
  / __| |_  ___ __| |_\ \    / /__| |__/ __(_) |_ ___ ___
 | (__| ' \/ -_) _| / /\ \/\/ / -_) '_ \__ \ |  _/ -_|_-<
  \___|_||_\___\__|_\_\ \_/\_/\___|_.__/___/_|\__\___/__/

          +---------- Informations ----------+
          | Name : CheckWebSite              |
          | Purpose : Check if website exist |
          | Version : 1.0                    |
          | Creator : Joseph Leroux          |
          +----------------------------------+
EOF
echo -e '\e[0m'
echo "Starting program..."
sleep 2

# Enregistre le temps de début
start_time=$(date +%s)

read -p "What is the name to test? " base_name
read -p "Enable EXTENSIVE mode? [y/N]: " choice

names_to_test=("$base_name")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    len=${#base_name}
    for (( i=1; i<len; i++ )); do
        prefix="${base_name:0:i}"
        suffix="${base_name:i}"
        for char in "-" "_"; do
            names_to_test+=("${prefix}${char}${suffix}")
        done
    done
fi

export names_to_test

echo "--- Begining the scan ---"

goodUrl=$(printf "%s\n" "${names_to_test[@]}" | xargs -I % -P 10 bash -c '
    name_var="%"
    while read -r tld; do
        for proto in http https; do
            newurl="${proto}://${name_var}.${tld}"
            
            # Utilisation de la notation explicite pour le code HTTP
            status_code=$(curl -s -L -k -4 -A "Mozilla/5.0" --connect-timeout 3 --max-time 4 -o /dev/null -w "%{http_code}" "$newurl")
            # Si le code est vide ou contient une erreur de format, on force 000
            if [[ ! "$status_code" =~ ^[0-9]{3}$ ]]; then
                status_code="000"
            fi
            
            if [[ "$status_code" =~ ^(200|301|302|403|500)$ ]]; then
                echo "Succès: $newurl (Code $status_code)" >&2
                echo "FOUND: $newurl (Code $status_code)"
            else
                echo "Nope : $newurl (Code $status_code)" >&2
            fi
        done
    done < tldList.txt
' | grep "FOUND:" | cut -d':' -f2-)

# Enregistre le temps de fin et calcule la durée
end_time=$(date +%s)
duration=$((end_time - start_time))

echo -e "\n--- FINISHED (Durée: ${duration} secondes) ---"
echo -e "\nHere is a list of site you should check :\n$goodUrl"
