#!/bin/bash

# Author - Hamad Ali Faizer
# ECU ID - 10547327
# CSP2101 Scripting languages Assignment 3 
# Software based solution


function continuescript() # allows user to end the script or continue if wanted
{
    echo "****************************************"
    echo "End of search what would you like to do?"
    echo "****************************************"
    PS3='Please enter your choice: '
    options=("SFTP" "Continue script" "Exit script")
    select end1 in "${options[@]}"
    do   
        case $end1 in
            "SFTP") 
                sftpserver
                break
            ;;

            "Continue script") 
                echo "The script will continue"
                loopscript
            ;;

            "Exit script") 
                echo "The script has ended"
                exit 0
        esac
    done
}


getsave() # gets the location where the file is to be saved and the name of the file 
{
    read -p "Where would you like to save the results (press enter for current location): " locat1
    if [ ! -z $locat1 ] ; then # if the location does not exits one will be created
    echo "No location exits creating one..."
    mkdir $locat1
    elif [ -z $locat1 ]; then # if no locaiton is entered the current working directory will be used
    locat1=$(pwd)
    echo "current location is $locat1"
    else
    echo "Folder exists"
    fi

    read -p "What would you like to save the file as (enter extension as well): " filesave
    touch $locat1/$filesave # creates the file in the specified location
}

getlog() # allows the user to choose if they want to search all logs or just one 
{
    read -p "Would you like to search all logs in the directory (Y|N): " inputlog
    if [[ $inputlog = "Y" ]] || [[ $inputlog = "y" ]]; then 
        alllog # refers the function which collects the file names of all the logs

    elif [[ $inputlog = "N" ]] || [[ $inputlog = "n" ]]; then
        speclog # refers the function which collects the file names of a specific log

    else 
    echo "Invalid input try again"
    getlog

    fi
}

speclog() # funcion to get a specific log file
{
    declare -a logs  
patt="serv_acc_log.+csv$" # criteria so only files that have the pattern can be chosen
mennum=0 # the starting number for the log files

for file in ./*; do 
    if [[ $file =~ $patt ]]; then # gets files with the names of the variable patt
        logs+=($(basename $file)) 
    fi
done

count=${#logs[*]} # gets a count of how many files match the pattern
echo -e "The folder contains $count log files.\n" 

for file in "${logs[@]}"; do # for loop which can print the number next to the matched file
    echo -e "$mennum $file" 
    ((mennum++))
done

read -p "Enter selection here [0,1,2,3 or 4]: " sel
if [ $sel -gt 4 ]; then 
    echo "you have entered an invalid input"
    getlog

else
    choice=${logs[$sel]} # selects file based on what number was entered
    echo "You have chosen $choice"
fi

grep -e "suspicious" $choice > $locat1/$filesave  # gets all lines which match the pattern and outputs to the user specified file and location

}

alllog() # function for all log files
{
choice=$( ls -d *.csv | ls -d serv_acc_log* ) # lists all files int the directory which end in .csv and pipe it to another ls which lists all files which start with serv_acc_log
grep -e "suspicious" $choice > $locat1/$filesave  # gets all lines which match the pattern and outputs to the user specified file and location


}
 
fieldcrit() # gives a user a choice of how many search criterias they want
{
    read -p "Enter number of field criteria 1,2 or 3 or (4) to quit: " crinum # gets a number 
    case $crinum in 

        1) # runs the function enterchoice once because the chosen number of field criterias is one
            enterchoice 
            ;;
        
        2) # runs the function twice one for the first field and another one for the second field
            enterchoice 
            echo "--------------------------"
            echo "Choose 2nd field criteria"
            echo "--------------------------"
            enterchoice
            ;;

        3)
            enterchoice # runs the function thrice for three fields
            echo "--------------------------"
            echo "Choose 2nd field criteria"
            echo "--------------------------"
            enterchoice
            echo "--------------------------"
            echo "Choose 3rd field criteria"
            echo "--------------------------"
            enterchoice
            ;;
        
        4)
            exit 0
            ;;

        *)
            echo "Invalid Input try again"
            fieldcrit
    esac
} 

enterchoice() # function which allows the script to get the field criteria and run the specified field criteria function.
{
    PS3='Please enter your choice: '
    CRITES=("Protocol" "Source IP" "Destination IP" "Source Port" "Destination Port" "Packets" "Bytes")
    select opt in "${CRITES[@]}"
    do  
        case $opt in
            "Protocol") # runs the function for protocol if selected and then break once it is done
                awkprotocol
                break
            ;;
            "Source IP") # runs the function for source IP if selected and then break once it is done
                awksourceIP   
                break
            ;;
            "Destination IP") # runs the for function Destination IP if selected and then break once it is done
                awkdestIP
                break
            ;;
            "Source Port") # runs the function for Source Port if selected and then break once it is done
                awksrcport     
                break
            ;;
            "Destination Port") # runs the function for Destination port if selected and then break once it is done
                awkdestport   
                break
            ;;
            "Packets") # runs the function for Packets if selected and then break once it is done
                awkpackets
                break
            ;;
            "Bytes") # runs the function for Bytes if selected and then break once it is done
                awkbytes      
                break          
            ;;
            *) echo "invalid option" # if any other option other than the ones given is selected it will print echo invalid selection
                enterchoice
        esac
    done
}
  

awkprotocol() # function for protocol
{
    read -p "Enter protocols here (space between each protocol ): " protype
    search=$( echo "$protype" | tr '[a-z]' '[A-Z]' ) # converts user input in previous line to uppercase
    ARR=($search) # saves the previous variable into ()  

    grep -e -F -f <(printf "%s\n" "${ARR[@]}") < $locat1/$filesave > $locat1/tempfile.csv && mv $locat1/tempfile.csv $locat1/$filesave 
    # filter all lines which contain the specified protocols and then saves output into a temporary  file before writing to the user specified file
    
    awk ' BEGIN {FS=","}
         {                     
            printf "%-6s %-15s %-10s %-15s %-10s %-5s %-10s \n", $3, $4, $5, $6, $7, $8, $9
        }' < $locat1/$filesave # outputs the file in a neatly manner

}

awksourceIP() # function fo source IP uses the index to search for the specified user given pattern in the 4th column of the file.
{
    
    read -p "Enter Source IP here: " srcip
    awk ' BEGIN {FS=","; IGNORECASE=4}
            {
                if (index($4, "'$srcip'" ))
                {
                    printf "%-6s %-15s %-10s %-15s %-10s %-5s %-10s \n", $3, $4, $5, $6, $7, $8, $9
                } 
            }' < $locat1/$filesave > $locat1/testfile.csv && mv $locat1/testfile.csv $locat1/$filesave
    cat $locat1/$filesave # saves output into a temporary  file before writing to the user specified file then cat the file to the terminal
    
                   
}


awkdestIP() # function for destination port uses the index to search for the specified user given pattern in the 4th column of the file.
{
    read -p "Enter Destination IP here: " destip
    awk ' BEGIN {FS=","; IGNORECASE=6}
            {
                if ( index($6, "'$destip'"))
                {
                    printf "%-6s %-15s %-10s %-15s %-10s %-5s %-10s \n", $3, $4, $5, $6, $7, $8, $9
                } 
            }' < $locat1/$filesave > $locat1/testfile.csv && mv $locat1/testfile.csv $locat1/$filesave
    cat $locat1/$filesave # saves output into a temporary  file before writing to the user specified file then cat the file to the terminal
    
}

awkdestport() # simple awk function which checks for all lines which match the user specified destination port in the 7th column of the file
{
    read -p "Enter Destination port: " deport
    awk ' BEGIN {FS=","}
            {
                if ( $7 == "'deport'" )
                {
                    printf "%-6s %-15s %-10s %-15s %-10s %-5s %-10s \n", $3, $4, $5, $6, $7, $8, $9
                } 
            }' < $locat1/$filesave > $locat1/testfile.csv && mv $locat1/testfile.csv $locat1/$filesave
    cat $locat1/$filesave # saves output into a temporary  file before writing to the user specified file then cat the file to the terminal
    
}

awksrcport() # function for the source port checks the 5th column for the user specified pattern in the 5th column
{
    read -p "Enter Destination port: " srcport
    awk ' BEGIN {FS=","}
            {
                if ( $5 == "'$srcport'" )
                {
                    printf "%-6s %-15s %-10s %-15s %-10s %-5s %-10s \n", $3, $4, $5, $6, $7, $8, $9
                } 
            }' < $locat1/$filesave > $locat1/testfile.csv && mv $locat1/testfile.csv $locat1/$filesave
    cat $locat1/$filesave # saves output into a temporary  file before writing to the user specified file then cat the file to the terminal
    
}

operator1() # gets the operator for the packets and bytes function
{
    PS3='Enter choice here: '
    options=("Greater than" "Less than" "Equal to" "Not equal to")
    select opt in "${options[@]}"
    do  
        case $opt in
            "Greater than") 
                seloper=">"
                break
            ;;
            "Less than")
                seloper="<"
                break                
            ;;
            "Equal to") 
                seloper="=="
                break
            ;;
            "Not equal to")
                seloper="!="
                break        
            ;;
            *) echo "invalid option"
                operator1
        esac
    done
}

awkpackets() # function to filter the packets based on user specified value and user chosen operator
{
    read -p "Enter specific value: " packs
    operator1  # runs the operator function to assign the $seloper variable 
    
    awk ' BEGIN {FS=","; ttlpackets=0}
        {
                if ( $8 '"$seloper"' '"$packs"' )
                    {
                        ttlpackets=ttlpackets+$8
                        printf "%-6s %-15s %-10s %-15s %-10s %-5s %-10s \n", $3, $4, $5, $6, $7, $8, $9
                    }
        }
        END { print "total packets for all matching rows is ", ttlpackets }
        ' < $locat1/$filesave > $locat1/testfile.csv && mv $locat1/testfile.csv $locat1/$filesave
    cat $locat1/$filesave  # saves output into a temporary  file before writing to the user specified file then cat the file to the terminal
}

awkbytes() # function to filter the bytes based on user specified value and user chosen operator
{
    read -p "Enter specific value: " bytes1
    operator1  # runs the operator function to assign the $seloper variable 
    
   
    awk ' BEGIN {FS=","; ttlbytes=0}
         {
                if ( $9 '"$seloper"' '"$bytes1"')
                    {
                        ttlbytes=ttlbytes+$9
                        printf "%-6s %-15s %-10s %-15s %-10s %-5s %-10s \n", $3, $4, $5, $6, $7, $8, $9
                    }
        }
        END { print "total bytes for all matching rows is ", ttlbytes }
        ' < $locat1/$filesave > $locat1/testfile.csv && mv $locat1/testfile.csv $locat1/$filesave
    cat $locat1/$filesave # saves output into a temporary  file before writing to the user specified file then cat the file to the terminal
}


sftpserver()
{
    read -p "Enter Ip or hostname: " hostname1
    read -p "Enter username: " username1
    read -p "Enter directory here: " sftpdir 
# establish connection
# -oPORT defines which port to use as the default for sftp is 22
if [[ ! -z $hostname1 ]] && [[ ! -z $username1 ]]; then
    sftp -oPORT=22 $username1@$hostname1 <<EOF 
    put $locat1/$filesave $sftpdir
    quit
EOF
    echo "The file has been uploaded."
    continuescript

else 
    echo "The fields are incomplete"
    sftpserver

fi
}




loopscript() # allows the script to be looped by looping all the functions until the user decides to stop at the continuescript choosing to stop.
{
while true 
do     
    getsave
    getlog
    fieldcrit
    continuescript

done
}

loopscript
