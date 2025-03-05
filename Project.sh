#!/bin/bash

#---source
########

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dbPath="$script_dir/DBs"
script_name="myDb.sh"
chmod +x "$script_dir/$script_name"



if ! grep -q "alias mydb" ~/.bashrc; then

    echo "alias mydb='source \"$script_dir/$script_name\"'" >> ~/.bashrc
    
    echo "close and open terminal . You can now run the script using 'mydb' from any terminal session."
fi

# 1. Create DB directory
if [ ! -d "$dbPath" ]; then
    mkdir -p "$dbPath"
    echo "DB dir created"
else
    echo "DB dir already exists"
fi

# case-insensitive 
shopt -s nocasematch

# 2. Main menu
PS3="Enter your choice from the main menu (1-5): "
options=("Create Database" "List Databases" "Connect To Database" "Drop Database" "Exit")

while true; do
    select choice in "${options[@]}"; do
        case $choice in 

            # 2.1 - Create Database
            "Create Database")
                while true; do
                    read -p "Enter the name of the database (or press Enter to return): " dbName
                    dbName=$(echo "$dbName" | xargs)

                    if [[ -z "$dbName" ]]; then
                        echo "Returning to the main menu..."
                        break
                    fi

                    # Validation
                    if [[ ! "$dbName" =~ ^[a-zA-Z_] ]]; then
                        echo "Error! Database name must start with a letter or underscore."

                    elif [[ ! "$dbName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                        echo "Error! No spaces or special characters allowed."

                    elif echo "$dbName" | grep -wqiE "select|insert|update|delete|create|drop|from|where|table|database|into|alter|rename|join"; then
                        echo "Error! '$dbName' is a reserved SQL keyword."

                    elif [[ "$dbName" =~ \  ]]; then
                        echo "Error! Database name cannot contain spaces."

                    elif [ -d "$dbPath/$dbName" ]; then
                        echo "Error!! Database '$dbName' already exists."

                    else
                        mkdir -p "$dbPath/$dbName"
                        echo "Database '$dbName' created successfully."
                    fi
                    
                    read -p "Do you want to add another database? [y/n]: " choice
                    case $choice in
                        [yY]* ) continue ;;
                        * ) echo "Returning to the main menu..."; break ;;
                    esac
                done
                ;;
            
            # 2.2 - List Databases
            "List Databases")
                if [ -z "$(ls -1 "$dbPath")" ]; then
                    echo "No databases found. returning to main menu..."
                    continue
                fi
                echo "================================="
                echo "Available Databases:"
                echo "================================="
                    ls -1 "$dbPath" | awk '{print NR".", $0 }'
                echo "================================="
            ;;

            # 2.3 - Connect To Database

"Connect To Database")
    if [ -z "$(ls -1 "$dbPath")" ]; then
        echo "No databases found. Returning to main menu..."
        continue
    fi
    echo "================================="
    echo "Available Databases:"
    echo "================================="
    ls -1 "$dbPath" | awk '{print NR".", $0}'
    echo "================================="
    
    read -p "Enter Database Name or Number to Connect: " input
    case $input in
        ''|*[!0-9]* )
            dbName=$input
        ;;
        * )
            dbName=$(ls -1 "$dbPath" | sed -n "${input}p")
            if [[ -z "$dbName" ]]; then
                echo "Invalid selection. Returning to main menu..."
                continue
            fi
        ;;
    esac

    if [ -d "$dbPath/$dbName" ]; then 
        echo "Connected to Database '$dbName'."
        cd "$dbPath/$dbName"

        while true; do
            echo "================================="
            echo "Tables in '$dbName':"
            echo "================================="
            if [ -z "$(ls -1 | grep -vE ".meta$")" ]; then
                echo "No tables found in '$dbName'."
            else
                ls -1 | grep -vE ".meta$" | awk '{print NR".", $0}'
            fi
            echo "================================="
            echo "1. List Tables"
            echo "2. Create Table"
            echo "3. Insert into Table"
            echo "4. Select from Table"
            echo "5. Update Table"
            echo "6. Delete from Table"
            echo "7. Drop Table"
            echo "8. Exit"
            echo "================================="
            
            read -p "Choose an option: " tableChoice
            case $tableChoice in
                1)
                    echo "================================="
                    echo "List of Tables in '$dbName':"
                    echo "================================="
                    if [ -z "$(ls -1 | grep -vE ".meta$")" ]; then
                        echo "No tables found."
                    else
                        ls -1 | grep -vE ".meta$" | awk '{print NR".", $0}'
                    fi
                    echo "================================="
                ;;
                2)
         while true; do
        read -p "Enter Table Name: " tableName
        tableName=$(echo "$tableName" | xargs)

        if [[ -z "$tableName" ]]; then
            echo "Returning to table menu..."
            break
        fi

        if [[ ! "$tableName" =~ ^[a-zA-Z_] ]]; then
            echo "Error! Table name must start with a letter or underscore."

        elif [[ ! "$tableName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo "Error! No spaces or special characters allowed."

        elif echo "$tableName" | grep -wqiE "select|insert|update|delete|create|drop|from|where|table|database|into|alter|rename|join"; then
            echo "Error! '$tableName' is a reserved SQL keyword."

        elif [ -e "$tableName" ] || [ -e "$tableName.meta" ]; then
            echo "Error! Table '$tableName' already exists."

        else
            touch "$tableName" "$tableName.meta"
            read -p "Enter Columns (e.g., id:INT, name:STRING): " columns
            echo "$columns" | tr ',' '\n' > "$tableName.meta"
            echo "Table '$tableName' created successfully."
            break
        fi
    done
;;

                3)
                    read -p "Enter Table Name: " tableName
                    if [[ ! -e "$tableName" || ! -e "$tableName.meta" ]]; then
                        echo "Table does not exist!"
                        continue
                    fi
                    echo "Table Columns:"
                    cat "$tableName.meta"
                    read -p "Enter Data (comma-separated): " rowData
                    echo "$rowData" >> "$tableName"
                    echo "Data inserted successfully."
                ;;
                4)
                    read -p "Enter Table Name: " tableName
                    if [[ ! -e "$tableName" ]]; then
                        echo "Table does not exist!"
                        continue
                    fi
                    echo "Table '$tableName' Data:"
                    cat "$tableName"
                ;;
                5)
                    read -p "Enter Table Name: " tableName
                    if [[ ! -e "$tableName" ]]; then
                        echo "Table does not exist!"
                        continue
                    fi
                    echo "Table Columns:"
                    cat "$tableName.meta"
                    read -p "Enter Column to Update: " column
                    read -p "Enter Old Value: " oldValue
                    read -p "Enter New Value: " newValue
                    sed -i "s/$oldValue/$newValue/g" "$tableName"
                    echo "Data updated successfully."
                ;;
                6)
                    read -p "Enter Table Name: " tableName
                    if [[ ! -e "$tableName" ]]; then
                        echo "Table does not exist!"
                        continue
                    fi
                    read -p "Enter Value to Delete: " value
                    sed -i "/$value/d" "$tableName"
                    echo "Record deleted successfully."
                ;;
                7)
                    read -p "Enter Table Name to Drop: " tableName
                    if [[ -e "$tableName" ]]; then
                        rm "$tableName" "$tableName.meta"
                        echo "Table '$tableName' dropped successfully."
                    else
                        echo "Table does not exist!"
                    fi
                ;;
                8)
                    echo "Exiting table management..."
                    break
                ;;
                *)
                    echo "Invalid choice!"
                ;;
            esac
        done
    else 
        echo "Database '$dbName' does not exist."
    fi
;;


            # 2.4 - Drop Database
            "Drop Database")
                while true; do
                    if [ -z "$(ls -1 "$dbPath")" ]; then
                    echo "No databases available to delete"
                    echo "Returning to the main menu..."
                    break
                    fi
                    echo "================================="
                    echo "Available Databases:"
                    echo "================================="
                    ls -1 "$dbPath" | awk '{print NR".", $0}'
                    echo "================================="
                    read -p "Enter Database Name or Number to delete (Press Enter to cancel): " input
                    if [[ -z "$input" ]]; then
                        echo "Returning to the main menu..."
                        break
                    fi

                    case $input in 
                        ''|*[!0-9]* )
                            dbName=$input
                        ;;
                        * )
                            dbName=$(ls -1 "$dbPath" | sed -n "${input}p")
                            if [[ -z "$dbName" ]]; then
                                echo "There is no Database with number '$input'. Returning to main menu."
                                continue
                            fi
                        ;;
                    esac

                    if [ -d "$dbPath/$dbName" ]; then
                        if [ "$(ls -A "$dbPath/$dbName")" ]; then
                            read -p "Database '$dbName' is not empty, drop anyway? [y/n]: " answer
                            case $answer in 
                                [yY]* )
                                    rm -rf "$dbPath/$dbName"
                                    echo "Database '$dbName' and all its tables deleted successfully."
                                    if [ -z "$(ls -1 "$dbPath")" ]; then
                                            echo "No more databases left to delete."
                                            break
                                    fi
                                    read -p "Do you want to delete another database? [y/n]: " delete
                                    case $delete in
                                        [yY]* ) continue ;; 
                                        * ) echo "Returning to the main menu..."; break ;; 
                                    esac
                                ;;
                                * )
                                    echo "Deletion cancelled. Returning to main menu..."
                                    break 
                                ;;
                            esac
                        else
                            rm -rf "$dbPath/$dbName"
                            echo "Database '$dbName' deleted successfully."
                            
                            read -p "Do you want to delete another database? [y/n]: " delete
                            case $delete in
                                [yY]* )continue ;; 
                                * )
                                    echo "Returning to the main menu..."
                                    break  
                            esac
                        fi
                    else
                        echo "Database '$dbName' does not exist."
                    fi
                done
            ;;


            # 2.5 - Exit
            "Exit")
                read -p "Are you sure you want to exit? [y/n]: " answer
                case $answer in 
                    [yY]* )
                        echo "Exiting... byyye :)"
                        if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
                           
                            exit 0
                        else
                            
                            return 0
                        fi

                    ;;
                    * )
                        echo "Returning to the main menu..."
                    ;;
                esac
            ;;

            *)  
                echo "Error! enter number betwwen 1 to 5."
            ;;
        esac
    done
done
