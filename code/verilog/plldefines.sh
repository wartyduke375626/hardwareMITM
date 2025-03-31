#!/bin/bash

# This script retrievs the required macro parameters to define in order to configure the ICE40 PLL module

if [ "$#" -ne 2 ]; then
	echo "Usage: $0 <input frequency> <output frequency>"
	exit 1
fi

output=$(icepll -i $1 -o $2)
if [ "$?" -ne 0 ]; then
	echo "$output"
	exit 1
fi

DIVR=$(echo "$output" | grep 'DIVR' | cut -d '(' -f 2 | cut -d ')' -f 1)
DIVF=$(echo "$output" | grep 'DIVF' | cut -d '(' -f 2 | cut -d ')' -f 1)
DIVQ=$(echo "$output" | grep 'DIVQ' | cut -d '(' -f 2 | cut -d ')' -f 1)
FILTER_RANGE=$(echo "$output" | grep 'FILTER_RANGE' | cut -d '(' -f 2 | cut -d ')' -f 1)

unsanitized="-DPLL_DIVR=$DIVR -DPLL_DIVF=$DIVF -DPLL_DIVQ=$DIVQ -DPLL_FILTER_RANGE=$FILTER_RANGE"
echo "$unsanitized" | sed "s/'/\\\'/g"