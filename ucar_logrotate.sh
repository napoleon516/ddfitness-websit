#!/bin/bash
#  ===================================================================================
#  Script Name: Ucar_logrotate.sh
#  Author:      Edge Li
#  Date:        2015-04-21
#  Purpose:     This script will monitor the log status for all type servers.
#  Usage: Ucar_logrotate.sh -f = Monitor the specified log file and dirctory.
#                           -h = get the help info.
#
#  -------------------------------------------------------------------------------
#                           *************
#                           Modifications
#                           *************
#
#  Date         Name              Ver.    Description
#  -----------  ----------------- ------- ----------------------------------------
#  2015-04-21   Edge Li           1.00    Created.
#  2015-04-23   Edge Li           1.01    update the option of -f 
#                                         get the argument from a file.
#  ====================================================================================

#default


source /etc/profile
NG_LOG_PATH="/usr/local/nginx/logs/"
TOMCAT_LOG_PATH="/usr/local/tomcat/logs/"

#Functions
#---------------------------------------------------------------------------------
#clean up the overdue file.
cleanFile() {
    if [ -z $2 ]; then
        GetTime=6
    else
        GetTime=$2
    fi
    cat $1 | while read line; do
        if [ -d $line ];then
            find $line -daystart -mtime +$GetTime | xargs rm -f
        elif [ -f $line ];then
            #find ${line%/*} -daystart -mtime +$GetTime | xargs rm -f
            find /usr/local/nginx/logs/ -maxdepth 1 -type f -daystart -mtime +$GetTime|grep "${line##/*/}"|xargs rm -rf
        else
            echo "$line is not a file or directory!"
        fi
    done
}

cleanFile_exclude() {
    if [ -z $3 ]; then
        GetTime=6
        cat $1 | while read line; do
            #if [ "$line" = $2 ]; then
            #    echo "keep this file not delete $2"
            #    continue
            #else
            #    echo "print string in 2 arg,$line"
                if [ -d $line ];then
                    for file in `find $line -type f`
                    do
                        #if [ $file != $2 ]; then
                        num=0
                        while read mutil; do
                           #echo "Print Mutil is $mutil"
                           if [ $file == $mutil ]; then
                               num=$[$num+1]
                           fi
                        #fi
                        done < $2
                        if [ $num -eq 0 ]; then
                           find $file -daystart -mtime +$GetTime | xargs rm -f
                        fi
                    done
                elif [ -f $line ];then
                        num=0
                        while read mutil; do
                        #find ${line%/*} -daystart -mtime +$GetTime | xargs rm -f
                            if [ $line == $mutil ]; then
                                num=$[$num+1]
                            fi
                        done < $2
                        if [ $num -eq 0 ]; then
                            find /usr/local/nginx/logs/ -maxdepth 1 -type f -daystart -mtime +$GetTime|grep "${line##/*/}"|xargs rm -rf
                        fi
                else
                    echo "$line  2 is not a file or directory!"
                fi
            #fi
        done
    else
        GetTime=$2
        cat $1 | while read line; do
                if [ -d $line ];then
                    for file in `find $line -type f`
                    do
                        #if [ $file != $3 ]; then
                        num=0
                        #cat $3|while read mutil; do
                        while read mutil; do
                            #echo "Print Mutil 3 is $mutil, file is $file"
                            if [ $file == $mutil ]; then
                                num=$[$num+1]
                                #echo "The sum is $num"
                            fi
                        done < $3
                        #echo $num
                        if [ $num -eq 0 ]; then
                            #echo "test delete"
                            find $file -daystart -mtime +$GetTime | xargs rm -f
                        fi
                        #fi
                    done
                elif [ -f $line ];then
                        num=0
                        while read mutil; do
                            if [ $line == $mutil ]; then
                                num=$[$num+1]
                            fi
                        #find ${line%/*} -daystart -mtime +$GetTime | xargs rm -f
                        done < $3
                        if [ $num -eq 0 ]; then
                            #echo "single delete $line"
                            find /usr/local/nginx/logs/ -maxdepth 1 -type f -daystart -mtime +$GetTime|grep "${line##/*/}"|xargs rm -rf
                        fi
                else
                    echo "$line  2 is not a file or directory!"
                fi
            #fi
        done
    fi
}

#exec by directory
log_by_dir() {
    for f in `ls $1`
    do
        if [ ${f##*.} != gz ]; then
            mv $1/$f $1/${f%%.*}_`date -d "today" +"%Y%m%d"`.${f##*.}
            gzip $1/${f%%.*}_`date -d "today" +"%Y%m%d"`.${f##*.} >/dev/null 2>&1
        fi
    done
}

#-----------------------------------------------------------------------------------
#exec by files
log_by_file() {
    mv $1 ${1%%.*}_`date -d "today" +"%Y%m%d"`.${1##*.}
    [ -f ${1%%.*}_`date -d "today" +"%Y%m%d"`.${1##*.} ] && gzip ${1%%.*}_`date -d "today" +"%Y%m%d"`.${1##*.}
    #find ${1%/*} -daystart -mtime +2 | xargs rm -f
}

#----------------------------------------------------------------------------------
#get the specified file info and exec corresponding func.
getfileInfo() {
    cat $1 | while read line; do
        if [ -d $line ];then
            log_by_dir $line
        elif [ -f $line ];then
            log_by_file $line
        else
            echo "$line is not a file or directory!"
        fi
    done
}

deleteOperation() {
    if [ -z $1 ];then
        echo "-f need support"
        exit 1
    fi
    if [ -z $2 ];then
        cleanFile $1
    else
        cleanFile $1 $2
    fi
}

deleteOperation_excl() {
    cleanFile_exclude $1 $2 $3
}

comprOperation() {
    getfileInfo $1
}

if [ $# -lt 1 ]
then
    echo "At least one Option.!"
else
    while getopts ":f:dce:t:h" opt
    do
        case $opt in
        f) localFile=$OPTARG
          ;;
        e) exclude=$OPTARG
          ;;
        d) SetDeleteOption="delete"
          ;;
        t) setday=$OPTARG
          ;;
        c) SetCompOption="compression"
          ;;
        h) echo " "
           echo "  Usage: Ucar_logrotate.sh -f <file path> -d = execut the delete operation. [ -t specited the delete time ]             "
           echo "                                                                                                                        "
           echo "                                          -c = Just compress the log file.                                              "
           echo "                                          -e = Exclude some file for delete.                                              "
           echo " "
          ;;
        :)
          echo "Error:'-$OPTARG' requires an argument"
          exit 1
          ;;
        \?) echo "Invalid param. please use -h for help."
          ;;
        esac
    done
fi

if [ -z $localFile ]; then
    echo "Must privode '-f' option"
    exit 1
fi

if [ ! -f $localFile ]; then
    echo "The file you specify is not exist!"
    exit 1
fi

if [ ! -s $localFile ]; then
    echo "This is a emppty file!"
    exit 1
fi

if [ -d $localFile ]; then
    echo "This option need specify a file not directory.!"
    exit 1
fi

if [[ -z $exclude ]]; then
    if [ "$SetDeleteOption" = "delete" ]; then
        deleteOperation $localFile $setday
    fi
else
        #echo "The exclude is $exclude"
        deleteOperation_excl $localFile $setday $exclude
fi
if [ "$SetCompOption" = "compression" ]; then
    comprOperation $localFile
fi
