#!/usr/bin/env bash
set -euo pipefail

partition_device="$(findmnt -no SOURCE /)"
partition_number="$(realpath "$partition_device" | perl -ne '/(\d+)$/ && print $1')"
disk_device="$(realpath "$partition_device" | perl -ne '/(.+?)\d+$/ && print $1')"

# resize the partition table.
echo ', +' | sfdisk -N "$partition_number" --no-reread --force "$disk_device"
partx --update "$disk_device"

# resize the file system.
resize2fs "$partition_device"
