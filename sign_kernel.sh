#!/bin/bash -e

# Sign generic kernel downloaded using Mainline https://github.com/bkw777/mainline

if [ "$EUID" -ne 0 ]
then
  echo "ERROR: Please run as root"
  exit 1
fi

if [ "$#" -ne 1 ];
then
  echo "USAGE: ./sign_kernel <VERSION>"
  echo "EXAMPLE: ./sign_kernel 5.10.16"
  exit 2
fi

KERNEL_VERSION="$1"
PADDED_KERNEL_VERSION=""
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

IFS='.' read -ra PARTS <<< "$KERNEL_VERSION"
for part in "${PARTS[@]}";
do
    PADDED_PART=$(printf "%02d" "$part")
    PADDED_KERNEL_VERSION+="$PADDED_PART"
done

KERNEL_FILE="/boot/vmlinuz-${KERNEL_VERSION}-${PADDED_KERNEL_VERSION}-generic"

if [ ! -f "$KERNEL_FILE" ]
then
  echo "ERROR: Kernel file $KERNEL_FILE doesnt exist."
  exit 3
fi

sbverify --cert "${SCRIPTPATH}/sign.pem" "$KERNEL_FILE" && { echo "ERROR: Kernel already signed."; exit 4; } || true
sbsign --key "${SCRIPTPATH}/sign.priv" --cert "${SCRIPTPATH}/sign.pem" "$KERNEL_FILE" --output "${KERNEL_FILE}" && update-grub

