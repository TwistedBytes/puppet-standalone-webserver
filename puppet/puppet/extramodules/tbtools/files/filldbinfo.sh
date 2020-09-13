#!/bin/bash


# input: sourcefile, resultfile, optional: replace, optional dbname

CONSOLELOG=1


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
    -i|--input)
    INPUTFILE=$2
    shift
    ;;
    -o|--output)
    OUTPUTFILE=$2
    shift
    ;;
    -r|--replace)
    REPLACEFILE=$2
    shift
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

if [ -z "${INPUTFILE}" ]; then
    log "no inputfile (-f) given, quitting. $@"
    exit 1
fi

if [ ! -f ${INPUTFILE} ]; then
    log "inputfile ${INPUTFILE}  does not exist, quitting. $@"
    exit 1
fi

if [ ! -f ${OUTPUTFILE} ]; then
    REPLACEFILE=true
    log "Output file does not exist, creating"
fi

if [ -f ${OUTPUTFILE} ] && [ ${REPLACEFILE} == "false" ] ; then
    log "Output file exist, and replace is not active, exit"
    exit;
fi


if [ -z "${INIFILE}" ]; then
    INIFILE=~/private/databases.ini
fi

if [ ! -f "${INIFILE}" ]; then
    log "inifile ${INIFILE}  does not exist, quitting. $@"
    exit 1
fi

cfg.sections ${INIFILE}

if [ -z "${DBNAME}" ]; then
    DBNAME=${INIDBS[0]}
fi

cfg.parser ${INIFILE}
cfg.section.${DBNAME}

if [ -z $hostname ] || [ -z $database ] || [ -z $username ] || [ -z $password ]; then
    log "missing a database parameter"
fi

sed -r \
    -e "s/@@@hostname@@@/${hostname}/g" \
    -e "s/@@@database@@@/${database}/g" \
    -e "s/@@@username@@@/${username}/g" \
    -e "s|@@@password@@@|${password}|g" \
    -e "s#@@@homedir@@@#${HOME}#g" \
    ${INPUTFILE} > ${OUTPUTFILE}


