
read -p $'What is the name to test? \n' name
echo "Let's test for https://$name.fr, .com, .en ..."

export name 

goodUrl=$(cat tldList.txt | xargs -I {} -P 10 bash -c '
    for proto in http https; do
        newurl="${proto}://${name}.{}"
        
        status_code=$(curl -s --connect-timeout 3 --max-time 5 -o /dev/null -w "%{http_code}" "$newurl")
        
        if [[ "$status_code" =~ ^(200|301|302|403|500)$ ]]; then
            echo "Succès: $newurl (Code $status_code)" >&2
            echo "FOUND: $newurl (Code $status_code)"
        else
            echo "Nope : $newurl (Code $status_code)" >&2
        fi
    done

' | grep "FOUND:" | cut -d':' -f2-)


echo -e "---FINISHED---\n\nHere is a list of site you should check :\n$goodUrl"
