#!/usr/bin/env bash

set -e

PREFIXES=( "ENV_" "" )

function getVariableFromEnv(){
  local VARNAME=$1

  VARIABLE_FOUND=-1
  VARIABLE_VALUE=""
  VARIABLE_USED=""

  for ENVPREFIX in "${PREFIXES[@]}"; do
    PREFIXED_VARNAME="${ENVPREFIX}${VARNAME}"

    if [ -z ${!PREFIXED_VARNAME+x} ]; then
      # echo "${PREFIXED_VARNAME} var is unset";
      VARIABLE_FOUND=-1
    else
      # echo "${PREFIXED_VARNAME} var is set to '${!PREFIXED_VARNAME}'";
      VARIABLE_FOUND=1
      VARIABLE_VALUE="${!PREFIXED_VARNAME}"
      VARIABLE_USED="${PREFIXED_VARNAME}"
      return
    fi
  done

}

CONSOLELOG=1
ENVFILE=""
INPUTFILE=""
OUTPUTFILE=""
REPLACEFILE=false
EXPORTDB=1
DEBUG=0

function log(){
    local logline=$1

    # echo "$(date) : ${logline}" >> ${LOGFILE}

    if [ ${CONSOLELOG} -ne 0 ]; then
        echo "$(date) : ${logline}"
    fi
}

function printHelp(){
  echo "Usage: "
  echo "This script replaces @@@VAR@@@ for the value of the environment VAR, of ENV_VAR"
  echo "This is useful for deployment templates, live .env files."
  echo "Example: @@@HOME@@@ -> ${HOME}"
  echo "Example: @@@USER@@@ -> ${USER}"
  echo " "
  echo "    ${0} -i inputfile -o outputfile -r [true|false]"
  echo "        ( -r is replace if output exists )"
}

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    printHelp
    exit 0;
    ;;
    --envfile)
    ENVFILE=$2
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
    --nolog)
    CONSOLELOG=0
    ;;
    --nodbexport)
    EXPORTDB=0
    ;;
    --debug)
    DEBUG=1
    ;;
    *)
        echo "unknown option: $1"
        printHelp
        exit 1
    ;;
esac
shift # past argument or value
done

if [[ -z "${INPUTFILE}" ]]; then
    log "no inputfile (-i) given, quitting."
    exit 1
fi

if [[ -z "${OUTPUTFILE}" ]]; then
    log "no outputfile (-o) given, quitting."
    exit 1
fi

if [[ ! -f ${INPUTFILE} ]]; then
    log "inputfile ${INPUTFILE}  does not exist, quitting."
    exit 1
fi

if [[ ! -f ${OUTPUTFILE} ]]; then
    REPLACEFILE=true
    log "Output file does not exist, creating"
fi

if [[ ${INPUTFILE} == ${OUTPUTFILE} ]]; then
    log "Input and output file are the same, this does not work, exit"
    exit 1;
fi

if [[ -f ${OUTPUTFILE} ]] && [[ ${REPLACEFILE} == "false" ]] ; then
    log "Output file exist, and replace is not active, exit"
    exit 1;
else
  echo -n "" > "${OUTPUTFILE}"
fi

DBINIFILE=~/private/databases.ini
if [[ ${EXPORTDB} -eq 1 ]] && [[ -f ${DBINIFILE} ]]; then
  log "Read database inforation"
  . <(bash export-database-info.sh)
fi

log "Read ${INPUTFILE}, write to: ${OUTPUTFILE}"

LINECOUNT=0
while read -r line || [ -n "$line" ] ; do
    LINECOUNT=$((LINECOUNT+1))

    NOMATCHCOUNTER=0
    # loop the line until
    while [[ "$line" =~ (@@@)([a-zA-Z_0-9]*)(@@@) ]] && [[ ${NOMATCHCOUNTER} -eq 0 ]]; do
        NOMATCHCOUNTER=0
        # Full @@@...@@@ match
        LHS=${BASH_REMATCH[0]}
        # echo $LHS
        # Text in @@@
        __VAR=${BASH_REMATCH[2]}
        # echo $__VAR

        getVariableFromEnv $__VAR
        # echo  ${VARIABLE_FOUND}
        # echo  ${VARIABLE_VALUE}

        if [[ ${VARIABLE_FOUND} -eq -1 ]]; then
          NOMATCHCOUNTER=1
          log "No Variable with name ${__VAR} found for ${LHS}"
        else
          NOMATCHCOUNTER=0
          # And replace is in this line
          [[ ${DEBUG} -eq 1 ]] && log "replace ${LHS} with '${VARIABLE_VALUE}' on line ${LINECOUNT}, from var: ${VARIABLE_USED}"
          [[ ${DEBUG} -eq 0 ]] && log "replace ${LHS} on line ${LINECOUNT}, from var: ${VARIABLE_USED}"
          line=${line//$LHS/$VARIABLE_VALUE}
        fi
    done
    echo "$line" >> "${OUTPUTFILE}"
done < "${INPUTFILE}"

[[ ${DEBUG} -eq 1 ]] || log "done"
