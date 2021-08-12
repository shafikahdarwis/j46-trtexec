#!/usr/bin/env bash

# Author : shafikah
# -------------------------------------------------

# Declare ANSI Color Code
NC='\033[0m' # No Color
BLACK='\033[0;30m'
DARKGRAY='\033[1;30m'
RED='\033[0;31m'
LIGHTRED='\033[1;31m'
GREEN='\033[0;32m'
LIGHTGREEN='\033[1;32m'
BROWN='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHTBLUE='\033[1;34m'
PURPLE='\033[0;35m'
LIGHTPURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHTCYAN='\033[1;36m'
LIGHTGRAY='\033[0;37m'
WHITE='\033[1;37m'

clear

## === Model Options (Location) ===
#echo -e "${GREEN}[STEP 1: Select Models Location]${NC}"

count=1

# Declare a Model Options (Location) array
declare -a arrayModelLocation=("$data" "$data1" "$data2")

# Read the array values
for val in "${arrayModelLocation[@]}"; 
do
	echo -e "[$count] $val"
	((count++))
done

echo -n "Available Data Location; Which you prefer?:"
#echo -n "${GREEN}STEP 1: Select Models Location?:${NC}"

read selectModelLocation

if [[ $selectModelLocation-1 -lt 0 ]] || [[ $selectModelLocation-1 -ge $((count-1)) ]]
then
	echo -e "${RED}Location not Available!${NC}"
	exit
else
#	echo -e "${GREEN}You choose: ${arrayModelLocation[$selectModelLocation-1]}${NC}"
	listModel=${arrayModelLocation[$selectModelLocation-1]}
fi

clear

## === Model Options (Type) ===
count=1

# Declare a Model Options (Type) array
declare -a arrayModelType=("Caffe" "ONNX" "UFF")

# Read the array values
for val in "${arrayModelType[@]}"; 
do
	echo -e "[$count] $val"
	((count++))
done

echo -n "Which type of model you prefer?:"

read selectModelType

if [[ $selectModelType-1 -eq 0 ]]
then
	extensionModelType="prototxt"
	extensionModelName="Caffe"
elif [[ $selectModelType-1 -eq 1 ]]
then
	extensionModelType="onnx"
	extensionModelName="ONNX"
elif [[ $selectModelType-1 -eq 2 ]]
then
	extensionModelType="uff"
	extensionModelName="UFF"
else
	echo -e "${RED}Type not Available!${NC}" &
	sleep 1
	wait
	clear
	./run.sh
	exit
fi

if [[ $extensionModelType == "prototxt" ]]
then
	echo -n "Enable Deep Learning Accelerator (DLA) [Y/N]:"

	read useDLACore
	
	if [[ $useDLACore == "Y" ]] || [[ $useDLACore == "y" ]] 
	then
		useDLACoreEnable=1
		
		echo -n "Select DLA core N for layers that support DLA [0/1]:"
		
		read useDLACoreVal
		
		if [[ $useDLACoreVal -eq 0 ]] || [[ $useDLACoreVal -eq 1 ]]
		then
			useDLACoreN="$useDLACoreVal"
		else
			useDLACoreN=0
		fi
	else
		useDLACoreEnable=0
		useDLACoreN="None"
	fi
else 
	:
fi

echo -e "DONE!"

clear

## === Model Options (Selection) ===
count=1

# Declare a Model Options (Selection) array
declare -a arrayModelSelection

if [[ $selectModelLocation-1 -eq 0 ]] || [[ $selectModelLocation-1 -eq 1 ]]
then
	listModelDir="$listModel"/*/*.$extensionModelType
else
	listModelDir="$listModel"/*.$extensionModelType
fi

for entry in $listModelDir
do
	echo -e "[$count] ${entry##*/}"
	# Add new element at the end of the array
	arrayModelSelection+=($entry)
	((count++))
done

echo -n "Which model you prefer?:"

read selectModelSelection

if [[ $selectModelSelection-1 -eq 0 ]] || [[ $selectModelSelection-1 -le $((${#arrayModelSelection[@]}-1)) ]]
then
	selectModelSelection=${arrayModelSelection[$selectModelSelection-1]}
else
	echo -e "${RED}Location not Available!${NC}"
fi

clear

## === Reporting Options ===
#Report performance measurements averaged over N consecutive iterations
echo -n "Average Runs:"

read avgRuns

if [ -z "$avgRuns" ] || [[ $avgRuns -lt 0 ]]
then
	avgRunsVal=10
else
	avgRunsVal=$avgRuns
fi

clear

## === Build Options ===
count=1

# Declare a Model Options (Type) array
declare -a arrayPrecision=("--fp16" "--int8" "--best")

# Read the array values
for val in "${arrayPrecision[@]}"; 
do
	echo -e "[$count] $val"
	((count++))
done

echo -n "Precision:"

read precision

if [ -z "$precision" ] || [[ $precision-1 -ge 2 ]]
then
	precisionVal="best"
elif [[ $precision-1 -eq 0 ]]
then
	precisionVal="fp16"
elif [[ $precision-1 -eq 1 ]]
then
	precisionVal="int8"
fi

clear

## === Inference Options ===
#Run at least N inference iterations (default = 10)
echo -n "Iterations:"

read iteration

if [ -z "$iteration" ] || [[ $iteration -lt 0 ]]
then
	iterationVal=10
else
	iterationVal=$iteration
fi

clear

## === Summary ===
echo -e "${GREEN}Configuration${NC}"
echo -e "Models: $selectModelSelection"
FILE=${selectModelSelection##*/}
#echo -e "Models: $FILE"
#echo -e "Models: ${FILE%%.*}"
#echo -e "Models: ${FILE%.*}"
#echo -e "Models: ${FILE#*.}"
#echo -e "Models: ${FILE##*.}"
echo -e "Type: $extensionModelName"
echo -e "Average Runs: $avgRunsVal"
echo -e "Precision: $precisionVal"
echo -e "Iterations: $iterationVal"

## === Benchmarking Start? ===
echo -n "Start Benchmarking? [Y/N]:"

read startBench

if [ -n "$startBench" ] || [ "$startBench" = "Y" ] || [ "$startBench" = "y" ]
then
	echo -e "${GREEN}Start Process!${NC}" &
	sleep 1
	wait
	clear
	
	if [ "$extensionModelName" = "Caffe" ] && [ $useDLACoreEnable -eq 1 ]
	then
		for i in 1 2 4 8 16 32 64 128
		do
			$trtexec \
			--avgRuns=$avgRunsVal \
			--deploy=$selectModelSelection \
			--$precisionVal \
			--batch=$i \
			--iterations=$iterationVal \
			--output=prob \
			--useSpinWait \
			--exportTimes=times_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_$i.json \
			--exportOutput=output_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_$i.json \
			--exportProfile=profile_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_$i.json \
			--useDLACore=$useDLACoreN \
			--allowGPUFallback \
			2>&1 | tee raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_$i.txt &
	
			wait
	
			cat *raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.txt >> raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.txt
			cat *times_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json >> times_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json
			cat *output_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json >> output_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json
			cat *profile_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json >> profile_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json
	
			rm -rf *raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.txt
			rm -rf *times_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json
			rm -rf *output_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json
			rm -rf *profile_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json
		done

		mkdir -p result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}

		mv raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.txt result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		mv times_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		mv output_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		mv profile_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		
		FILEDIR=result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}/
		FILENAME=raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.txt
		
	elif [ "$extensionModelName" = "Caffe" ] && [ $useDLACoreEnable -eq 0 ]
	then
		for i in 1 2 4 8 16 32 64 128
		do
			$trtexec \
			--avgRuns=$avgRunsVal \
			--deploy=$selectModelSelection \
			--$precisionVal \
			--batch=$i \
			--iterations=$iterationVal \
			--output=prob \
			--useSpinWait \
			--exportTimes=times_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_$i.json \
			--exportOutput=output_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_$i.json \
			--exportProfile=profile_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_$i.json \
			2>&1 | tee raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_$i.txt &
	
			wait
	
			cat *raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.txt >> raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.txt
			cat *times_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json >> times_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json
			cat *output_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json >> output_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json
			cat *profile_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json >> profile_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json
	
			rm -rf *raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.txt
			rm -rf *times_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json
			rm -rf *output_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json
			rm -rf *profile_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}_*.json
		done

		mkdir -p result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}

		mv raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.txt result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		mv times_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		mv output_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		mv profile_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		
		FILEDIR=result/${FILE#*.}/DLA_$useDLACoreN/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}/
		FILENAME=raw_${FILE%%.*}_${useDLACoreN}_${precisionVal}_${iterationVal}.txt
		
	elif [ "$extensionModelName" = "ONNX" ]
	then
		for i in 1 2 4 8 16 32 64 128
		do
			$trtexec \
			--avgRuns=$avgRunsVal \
			--onnx=$selectModelSelection \
			--$precisionVal \
			--batch=$i \
			--iterations=$iterationVal \
			--exportTimes=times_${FILE%%.*}_${precisionVal}_${iterationVal}_$i.json \
			--exportOutput=output_${FILE%%.*}_${precisionVal}_${iterationVal}_$i.json \
			--exportProfile=profile_${FILE%%.*}_${precisionVal}_${iterationVal}_$i.json \
			2>&1 | tee raw_${FILE%%.*}_${precisionVal}_${iterationVal}_$i.txt &
	
			wait
	
			cat *raw_${FILE%%.*}_${precisionVal}_${iterationVal}_*.txt >> raw_${FILE%%.*}_${precisionVal}_${iterationVal}.txt
			cat *times_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json >> times_${FILE%%.*}_${precisionVal}_${iterationVal}.json
			cat *output_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json >> output_${FILE%%.*}_${precisionVal}_${iterationVal}.json
			cat *profile_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json >> profile_${FILE%%.*}_${precisionVal}_${iterationVal}.json
	
			rm -rf *raw_${FILE%%.*}_${precisionVal}_${iterationVal}_*.txt
			rm -rf *times_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json
			rm -rf *output_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json
			rm -rf *profile_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json
		done

		mkdir -p result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}

		mv raw_${FILE%%.*}_${precisionVal}_${iterationVal}.txt result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		mv times_${FILE%%.*}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		mv output_${FILE%%.*}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		mv profile_${FILE%%.*}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
		
		FILEDIR=result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}/
		FILENAME=raw_${FILE%%.*}_${precisionVal}_${iterationVal}.txt
		
	elif [ "$extensionModelName" = "UFF" ]
	then
		echo -e "Not test yet!"
#		for i in 1 4 8 16 32 64 128
#		do
#			$trtexec \
#			--avgRuns=$avgRunsVal \
#			--uff=$selectModelSelection \
#			$precisionVal \
#			--batch=$i \
#			--iterations=$iterationVal \
##			--output=prob \
#			--useSpinWait \
#			--exportTimes=times_${FILE%%.*}_${precisionVal}_${iterationVal}_$i.json \
#			--exportOutput=output_${FILE%%.*}_${precisionVal}_${iterationVal}_$i.json \
#			--exportProfile=profile_${FILE%%.*}_${precisionVal}_${iterationVal}_$i.json \
#			2>&1 | tee raw_${FILE%%.*}_${precisionVal}_${iterationVal}_$i.txt &
#	
#			wait
#	
#			cat *raw_${FILE%%.*}_${precisionVal}_${iterationVal}_*.txt >> raw_${FILE%%.*}_${precisionVal}_${iterationVal}.txt
#			cat *times_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json >> times_${FILE%%.*}_${precisionVal}_${iterationVal}.json
#			cat *output_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json >> output_${FILE%%.*}_${precisionVal}_${iterationVal}.json
#			cat *profile_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json >> profile_${FILE%%.*}_${precisionVal}_${iterationVal}.json
#	
#			rm -rf *raw_${FILE%%.*}_${precisionVal}_${iterationVal}_*.txt
#			rm -rf *times_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json
#			rm -rf *output_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json
#			rm -rf *profile_${FILE%%.*}_${precisionVal}_${iterationVal}_*.json
#		done

#		mkdir -p result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}

#		mv raw_${FILE%%.*}_${precisionVal}_${iterationVal}.txt result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
#		mv times_${FILE%%.*}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
#		mv output_${FILE%%.*}_${precisionVal}_${iterationVal}.json result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}
#		mv profile_${FILE%%.*}_${precisionVal}_${iterationVal}.json result/${FILE*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}

#		FILEDIR=result/${FILE#*.}/precision_$precisionVal/iteration_$iterationVal/${FILE%%.*}/
#		FILENAME=raw_${FILE%%.*}_${precisionVal}_${iterationVal}.txt
#		
	fi
		
else
	echo -e "${RED}Restart Process!${NC}" &
	sleep 1
	wait
	clear
	./run.sh
	exit

fi

echo -e "Your File Location: ${GREEN}$FILEDIR${NC}"
echo -e "Your File Name: ${GREEN}$FILENAME${NC}"

if [ "$extensionModelName" = "Caffe" ]
then
	python extractCaffe_edit.py --file $FILEDIR$FILENAME
elif [ "$extensionModelName" = "ONNX" ]
then
	python extractONNX_edit.py --file $FILEDIR$FILENAME
#elif [ "$extensionModelName" = "UFF" ]
#then
	python extractUff.py --file $FILEDIR$FILENAME
else
	echo -e "Under Testing!"
fi
