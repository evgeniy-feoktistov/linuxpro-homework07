##Variables 
#Log file
log_file=./access.log
#Count of top IP by query 
X=10
#Count of top URLs
Y=10
#lock file
lock_file=/tmp/my_script_stats
#last line file
last_line_file=./last_line.txt
last_num=0

##Functions

function get_top_ip() {
	echo -e "\tTOP $X IPs\n"
	awk -F" " '{print $1}' $1 | sort | uniq -c | sort -rn | head -n$X
	}

function get_date() {
	awk -F" " '{print $4}' $1 | sed 's%\[%%'
	}

function get_top_url() {
	echo -e "\tTOP $Y URLs\n"
	awk '($9 ~ /200/)' $1 | awk '{print $7}'| sort | uniq -c | sort -rn | head -n$Y
	}
function get_code(){
	echo -e "\tCount codes\n"
	cat $1 | cut -d '"' -f3 | cut -d ' ' -f2 | sort | uniq -c | sort -rn
	}

#строчки, которые не укладываются в шаблон - они есть ошибки обработки
function get_errors(){
        echo -e "\tERRORs geting code from lines:\n"
        awk '($9 !~ /^[1-5][0-9][0-9]/)' $1
        }
#Получение необработанных строк
function tail_new_line () {
	tail -n $(($(wc -l $1 | cut -d " " -f1)-$last_num)) $1
	}

##Body

# lock
if [ -f $lock_file ]; then
    echo Script is already running\!
    exit 6
fi
touch $lock_file
trap 'rm -f "$lock_file"; exit $?' INT TERM EXIT

#1. Проверяем есть ли файл с номером последней обработанной строки. Если есть - обновляем переменную. Если нет - у нас она 0 по умолчанию. 
#Не делал проверку на наличие в файле данных, при пустом будет ошибка, но предполагаю, что он либо есть со значением либо его нет.  
if  [ -f $last_line_file ];
	then last_num=$(cat $last_line_file)
fi

if [ "$last_num" -eq "$(wc -l $log_file | cut -d " " -f1)" ];
	then echo -e "Нет новых данных.\nExiting..."
	exit 6
fi

#2. Определяем дату начала отчета и дату конца отчета
start_date=$(tail_new_line $log_file | head -n 1 | get_date)
end_date=$(tail_new_line $log_file | tail -n 1 | get_date)

#3. Записываем номер последней текущей строки в файл. Используется дважды - можно так же обернуть в функцию. 
wc -l $log_file | cut -d " " -f1 > $last_line_file

echo -e "Starting report from $start_date\n"
echo "***************************"
tail_new_line $log_file | get_top_ip
echo "***************************"
tail_new_line $log_file | get_top_url
echo "***************************"
tail_new_line $log_file | get_code 
echo "***************************"
tail_new_line $log_file | get_errors 
echo -e "\nEnding report at $end_date"
# release lock
rm -f $lock_file
trap - INT TERM EXIT
