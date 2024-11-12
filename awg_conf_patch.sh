#!/bin/sh

amnezia_Jc=50      # Junk packet count
amnezia_Jmin=5     # Junk packet minimum size
amnezia_Jmax=1500  # Junk packet maximum size
amnezia_S1=0       # Init packet junk size
amnezia_S2=0       # Response packet junk size

optstr="?hs:a:"
while getopts $optstr o; do
  case "$o" in
    s) short=$OPTARG ;;
    a) ashort=$OPTARG ;;
    \?) exit 255 ;;
  esac
done
shift $(expr $OPTIND - 1)

# Help
if [ $# -lt 1 ]; then
  echo "-------------------------------------------------------------
 Batch-patch WireGuard .conf files with AmneziaWG parameters
-------------------------------------------------------------
Usage: patch_with_awg.sh [options] <conf_dir> [backup_dir]

conf_dir: directory with WireGuard .conf files to patch
backup_dir: directory to copy original .conf files to before patching, files in
            this directory are never overwritten

Options:
  -s<len>: shorten long file names using <len> chars max for each word
    (space, dash and underscore are the delimiters, numbers are not shortened)
  -a<len>: shorten AirVPN config file names, for example -a4 converts
    \"AirVPN_AT-Vienna_Beemim_UDP-47107-Entry3.conf\" to
    \"AT-Vien_Beem-47107-E3.conf\"
"
  exit
fi

for f in "$1"/*.conf
do
  echo "Patching $f"

  # Backup
  if [ "$2" ]; then
    if [ ! -e "$2" ]; then
      mkdir "$2"
    fi
    if [ ! -d "$2" ]; then
      echo "$2 is not a directory"
      exit
    fi
    bn=$(basename "$f")
    if [ ! -e "$2"/"$bn" ]; then
      cp "$f" "$2"/"$bn"
    fi
  fi

  # Shuffle some params
  h="$(shuf -e 1 2 3 4)"
  amnezia_H1=$(echo "$h" | sed '1q;d')
  amnezia_H2=$(echo "$h" | sed '2q;d')
  amnezia_H3=$(echo "$h" | sed '3q;d')
  amnezia_H4=$(echo "$h" | sed '4q;d')

  # Clean existing awg parameters (if any) and add new
  conf=$(cat "$f" | sed "/^Jc = .*/d;/^Jmin = .*/d;/^Jmax = .*/d;/^S1 = .*/d;/^S2 = .*/d;/^H1 = .*/d;/^H2 = .*/d;/^H3 = .*/d;/^H4 = .*/d")
  echo "$conf" | sed "/^\[Interface\]/a\Jc = $amnezia_Jc\nJmin = $amnezia_Jmin\nJmax = $amnezia_Jmax\nS1 = $amnezia_S1\nS2 = $amnezia_S2\nH1 = $amnezia_H1\nH2 = $amnezia_H2\nH3 = $amnezia_H3\nH4 = $amnezia_H4" > "$f"

  # Shorten file name
  name=$(basename "$f")
  dir=$(dirname "$f")
  sname=
  if [ $short ]; then
    sname=$(echo "$name"_ | sed "s/\([ _-]\)/\1\n/g" | sed "s/\([[:alpha:]]\{$short\}\).*\(.\)/\1\2/" | tr -d "\n" | sed "s/.$//")
  elif [ $ashort ]; then
    if [ $(echo "$name" | cut -c-6) = "AirVPN" ]; then
      p1=$(echo "$name" | sed "s/\([_-]\)/\1\n/g" | tail -n+2 | head -n-3| sed "2~1s/\(.\{$ashort\}\).*\(.\)/\1\2/" | tr -d "\n")
      p2=$(echo "$name" | sed "s/\([_-]\)/\1\n/g" | tail -n+2 | tail -n2 | sed "s/Entry\(.\)/E\1/" | tr -d "\n")
      sname="$p1""$p2"
    else
      echo "File name does not begin with \"AirVPN\", skipping shortening"
    fi
  fi
  if [ "$sname" ]; then
    echo "Renaming $name to $sname"
    mv "$f" "$dir"/"$sname"
  fi
done

