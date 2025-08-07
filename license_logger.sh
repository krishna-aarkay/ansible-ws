#!/bin/bash

# ---------- Configuration ----------
source /etc/profile
module load eda_license/cadence xcelium/xcelium24.03.011
LMSTAT_CMD="lmstat -a -c 5280@aquavb32"
CSV_FILE="/home/ramkella/workspaces/license_usage.csv"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
TEMP_FILE="/tmp/lmstat_output.txt"

# Feature list
FEATURES=(

    "Conformal_Asic"
    "Conformal_Low_Power"
    "Conformal_Smart_LEC_4CPU"
    "Conformal_Ultra"
    "Genus_CPU_Opt"
    "Genus_Low_Power_Opt"
    "Genus_Physical_Opt"
    "Genus_Synthesis"
    "Innovus_5nm_Opt"
    "Innovus_C"
    "Innovus_CPU_Opt"
    "Innovus_DFM"
    "Innovus_Hier_Opt"
    "Innovus_Impl_System"
    "Pegasus_05nm"
    "Pegasus_RV"
    "Pegasus_UI"
    "Pegasus_dfmfill"
    "Pegasus_mpt"
    "Tempus_Timing_Signoff_MP"
    "Tempus_Timing_Signoff_TSO"
    "Tempus_Timing_Signoff_XL"
    "Voltus_Power_Integrity_AA"
    "Voltus_Power_Integrity_XL"
    "Xcelium_MultiCore_App"
    "Xcelium_Single_Core"
    "jasper_papp"
    "jasper_pcov"
    "jasper_pint"
    "conformal_datapath"
    "conformal_ldd"
    "conformal_lec"
    "conformal_lvr"
    "conformal_vhd"
    "conformal_vlg"
)

# ---------- Run lmstat ----------
$LMSTAT_CMD > "$TEMP_FILE" 2>/dev/null

if [[ $? -ne 0 ]]; then
    echo "❌ ERROR: lmstat command failed!"
    exit 1
fi

# ---------- Parse output ----------
declare -A USAGE_MAP

for FEATURE in "${FEATURES[@]}"; do
    # Look for issued/in-use counts on the same line
    LINE=$(grep -E "Users of $FEATURE:.*Total of [0-9]+ license(s)? issued;.*Total of [0-9]+ license(s)? in use" "$TEMP_FILE")

    if [[ $LINE =~ Total\ of\ ([0-9]+)\ license[s]?\ issued\;\ *Total\ of\ ([0-9]+)\ license[s]?\ in\ use ]]; then
        ISSUED="${BASH_REMATCH[1]}"
        IN_USE="${BASH_REMATCH[2]}"
        USAGE_MAP["$FEATURE"]="'$IN_USE / $ISSUED"
    else
        USAGE_MAP["$FEATURE"]="'0 / 0"
    fi
done

# ---------- Initialize CSV if not exists ----------
if [[ ! -f "$CSV_FILE" ]]; then
    echo -n "Feature" > "$CSV_FILE"
    echo ",$TIMESTAMP" >> "$CSV_FILE"
    for FEATURE in "${FEATURES[@]}"; do
        echo "$FEATURE,${USAGE_MAP[$FEATURE]}" >> "$CSV_FILE"
    done
else
    # Add timestamp as a new column to header
    TMP_FILE="/tmp/license_usage_new.csv"
    head -n1 "$CSV_FILE" > "$TMP_FILE"
    echo "$(head -n1 "$CSV_FILE"),$TIMESTAMP" > "$TMP_FILE"

    ROW_NUM=2
    for FEATURE in "${FEATURES[@]}"; do
        # Read existing row
        OLD_ROW=$(sed -n "${ROW_NUM}p" "$CSV_FILE")
        echo "$OLD_ROW,${USAGE_MAP[$FEATURE]}" >> "$TMP_FILE"
        ((ROW_NUM++))
    done

    mv "$TMP_FILE" "$CSV_FILE"
fi

# ---------- Cleanup ----------
rm -f "$TEMP_FILE"

echo "✅ License usage logged at $TIMESTAMP (features as rows)"


