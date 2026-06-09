#!/bin/bash
echo -e "\e[31m"
cat << "EOF" 
               _                        
               `*-.                    
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
               `*-* `*-* `*-*'  
   ___ _           _  __      __   _    ___ _ _         
  / __| |_  ___ __| |_\ \    / /__| |__/ __(_) |_ ___ ___
 | (__| ' \/ -_) _| / /\ \/\/ / -_) '_ \__ \ |  _/ -_|_-<
  \___|_||_\___\__|_\_\ \_/\_/\___|_.__/___/_|\__\___/__/

          +---------- Informations ----------+
          | Name : CheckWebSite              |
          | Purpose : Check if website exist |
          | Version : 3.2 (No Duplicates)    |
          | Creator : Joseph Leroux          |
          +----------------------------------+
EOF
echo -e '\e[0m'
echo "Starting program..."
sleep 1

start_time=$(date +%s)

read -p "What is the name to test? " base_name
read -p "Enable EXTENSIVE mode? [y/N]: " choice

names_to_test=("$base_name")
if [[ "$choice" =~ ^[Yy]$ ]]; then
    len=${#base_name}
    for (( i=1; i<len; i++ )); do
        prefix="${base_name:0:i}"
        suffix="${base_name:i}"
        names_to_test+=("${prefix}-${suffix}")
    done
fi

echo "--- Begining the scan ---"

cleaned_tlds=$(sed "s/[^a-zA-Z0-9-]//g" tldList.txt | awk 'NF')


tmp_list=$(mktemp)

for name in "${names_to_test[@]}"; do
    clean_name=$(echo "$name" | sed "s/[^a-zA-Z0-9-]//g")
    for tld in $cleaned_tlds; do
        echo "http://${clean_name}.${tld}" >> "$tmp_list"
        echo "https://${clean_name}.${tld}" >> "$tmp_list"
    done
done

sort -u "$tmp_list" -o "$tmp_list"

total_urls=$(wc -l < "$tmp_list")
echo ">> Liste purgée des doublons : $total_urls URLs UNIQUES prêtes à être testées !"
echo ">> Lancement des requêtes..."
echo "---------------------------------------------------"

goodUrl=$(
    cat "$tmp_list" | xargs -I @@@ -P 10 bash -c '
        url="@@@"
        
        curl_response=$(curl -sS -L -k -A "Mozilla/5.0" --doh-url https://cloudflare-dns.com/dns-query --connect-timeout 3 --max-time 4 -w "%{http_code}" -o /dev/null "$url" 2>&1)
        
        status_code="${curl_response: -3}"
        err_msg="${curl_response%???}"
        
        if [[ ! "$status_code" =~ ^[0-9]{3}$ ]]; then
            status_code="000"
        fi
        
        if [[ "$status_code" =~ ^(200|301|302|403|500)$ ]]; then
            echo "Succès: $url (Code $status_code)" >&2
            echo "FOUND: $url"
        else
            if [ -n "$err_msg" ]; then
                clean_err=$(echo "$err_msg" | tr -d "\n")
                echo "Nope : $url (Code $status_code) -> ERREUR: $clean_err" >&2
            else
                echo "Nope : $url (Code $status_code)" >&2
            fi
        fi
    ' | grep "FOUND:" | sed 's/FOUND: //'
)

rm "$tmp_list"

end_time=$(date +%s)
duration=$((end_time - start_time))

echo -e "\n--- FINISHED (Durée: ${duration} secondes) ---"
echo -e "\e[32m"
echo -e "\nHere is a list of site you should check :\n$goodUrl"
echo -e '\e[0m'