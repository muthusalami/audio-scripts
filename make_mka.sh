#!/bin/bash

# color codes for messages
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

_usage(){
    echo -e "${GREEN}\nThis script looks into a directory and converts WAV files into MKA files.\n${NC}"
}

# checks if directory is empty
check_empty_directory() {
    local directory="$1"
    local wav_count=$(find "$directory" -type f -name "*.wav" | wc -l)
    if [[ "$wav_count" -eq 0 ]]; then
        echo -e "${RED}[Error]'$directory' is empty.${NC}"
        return 1
    else
        return 0
    fi
}

# checks for wav header in file
check_wav_header() {
  local wav_file="$1"

  # rejects if it's not a file
  if [[ ! -f "$wav_file" ]]; then
      echo -e "${RED}[$(basename "$wav_file")]Error: Is not a file. Aborting...${NC}"
      return 1
  fi

  # reads 44 bytes of header
  header=$(xxd -l 44 -g 1 "$wav_file")
  riff_value="${header:9:12}"
  wavefmt_value="${header:33:12}"

  # if it's a file, checks for RIFF and WAV header
  if [[ "$riff_value" == " 52 49 46 46" && "$wavefmt_value" == " 57 41 56 45" ]]; then
      echo -e "${GREEN}[$(basename "$wav_file")]WAV header is valid.${NC}"
      return 0
  else
      echo -e "${RED}[$(basename "$wav_file")]Error: Invalid WAV header. Aborting...${NC}"
      return 1
  fi
}

# make_restored_mka() {
# 	ffmpeg -hide_banner -i "$wav_file" -ac 1 -filter_complex \
#       "adeclick=window=55:overlap=75[DC1]; \
#       [DC1]acrossover=split=1500 8000:order=20th[LOW][MID][HIGH]; \
#       [LOW]adeclick=window=55:overlap=75[LOW1]; \
#       [MID]adeclick=window=55:overlap=75:t=1[MID1]; \
#       [HIGH]adeclick=window=55:overlap=75[HIGH1]; \
#       [LOW1][MID1][HIGH1]amix=inputs=3[DCMIX]; \
#       [DCMIX]highpass=f=60:t=s,lowpass=f=10000:t=s" \
#       -c copy "$(basename "$wav_file")".mkv)

# 	mv "$(basename "$wav_file")".mkv) mka
# }

make_mka() {
    local wav_file="$1"
    local mka_directory="$(dirname "$wav_file")/mka"

    mkdir -p "$mka_directory"

    # extract filename without extension
    local filename_no_extension="$(basename "$wav_file" .wav)"

	ffmpeg -hide_banner -i "$wav_file" \
      -c copy "$mka_directory/$filename_no_extension".mka
}

# provide script usage instruction if no input provided
if [[ $# -eq 0 ]]; then
    script_name=$(basename "$0")
    _usage
    echo -e "Usage: $script_name <directory> ... \n"
    exit 1
fi

for directory in "$@"; do
	# check if directory is empty
    if ! check_empty_directory "$directory"; then
        continue
    fi

    # find all WAV files in the directory and its subdirectories
    for wav_file in $(find "$directory" -type f -name "*.wav"); do
        echo "============$(basename "$wav_file")============"
        if check_wav_header "$wav_file"; then
            # convert WAV to MKA and move it to 'mka' directory
            make_mka "$wav_file"
            echo -e "${GREEN}[$(basename "$wav_file")]Success! MKA created.${NC}"
            echo "============END============"
        fi
    done
done
