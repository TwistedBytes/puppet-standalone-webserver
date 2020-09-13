#!/bin/bash


# input: sourcefile, resultfile, optional: replace, optional dbname

CONSOLELOG=1
PRINTDBS=0


function log(){
    local logline=$1

    # echo "$(date) : ${logline}" >> ${LOGFILE}

    if [ ${CONSOLELOG} -ne 0 ]; then
        echo "$(date) : ${logline}"
    fi
}

cfg.parser () {
    fixed_file=$(cat $1 | sed 's/ = /=/g')  # fix ' = ' to be '='
    IFS=$'\n' && ini=( $fixed_file )              # convert to line-array
    ini=( ${ini[*]//;*/} )                   # remove comments
    ini=( ${ini[*]/#[/\}$'\n'cfg.section.} ) # set section prefix
    ini=( ${ini[*]/%]/ \(} )                 # convert text2function (1)
    ini=( ${ini[*]/=/=\( } )                 # convert item to array
    ini=( ${ini[*]/%/ \)} )                  # close array parenthesis
    ini=( ${ini[*]/%\( \)/\(\) \{} )         # convert text2function (2)
    ini=( ${ini[*]/%\} \)/\}} )              # remove extra parenthesis
    ini[0]=''                                # remove first element
    ini[${#ini[*]} + 1]='}'                  # add the last brace
    eval "$(echo "${ini[*]}")"               # eval the result
}

cfg.sections (){
    # declare -a sections
    sections=$( cat $1 | grep ^\\[ | tr -d "[]" | tr "\n" " " )
    INIDBS=(${sections})

    # echo ${INIDBS[1]}
}


while [[ $# > 0 ]]
do
key="$1"

case $key in
    -ini)
    INIFILE=$2
    shift
    ;;
    -printdbs)
    PRINTDBS=1
    ;;
    -d|--dbname)
    DBNAME=$2
    shift
    ;;
    *)
        echo "unknown option: $1"
        exit 1
    ;;
esac
shift # past argument or value
done

if [ -z "${INIFILE}" ]; then
    INIFILE=~/private/databases.ini
fi

if [ ! -f "${INIFILE}" ]; then
    log "inifile ${INIFILE}  does not exist, quitting. $@"
    exit 1
fi

cfg.sections ${INIFILE}


if [[ $PRINTDBS -eq 1 ]]; then
  for u in "${INIDBS[@]}"; do
    echo $u
  done
  exit;
fi

if [ -z "${DBNAME}" ]; then
    DBNAME=${INIDBS[0]}
fi

cfg.parser ${INIFILE}
cfg.section.${DBNAME}

if [ -z $hostname ] || [ -z $database ] || [ -z $username ] || [ -z $password ]; then
    log "missing a database parameter"
fi

echo export ENV_DB_USERNAME=${username}
echo export ENV_DB_PASSWORD=${password}
echo export ENV_DB_DATABASE=${database}
echo export ENV_DB_HOSTNAME=${hostname}
