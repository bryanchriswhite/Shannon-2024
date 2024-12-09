#!/bin/bash

# List of repositories to visualize
REPOS=(
    "grove-helm-charts"
    "homebrew-poktroll"
    "libpoktroll-clients"
    "path"
    "path-auth-data-server"
    "pocket-network-genesis"
    "pocket-poktroll-faucet"
    "pocketdex"
    "pokt-helm-charts"
    "poktroll"
    "poktroll-clients-py"
    "poktroll-docker-compose-example"
    "protocol-infra"
    "shannon-sdk"
    "shannon-tx-builder"
    "smt"
)

# Configuration
AVATAR_DIR="./avatars/hashes"  # Directory containing hash-named avatars
START_DATE="2024-01-01"  # Optional: format YYYY-MM-DD
STOP_DATE="2024-12-31"   # Optional: format YYYY-MM-DD
VIDEO_OUTPUT="shannon_2024.webm"
RECORD_MODE=false
DURATION=10  # Default 3 minutes in seconds

# Parse arguments
while getopts ":s:e:o:r:d:-:" opt; do
    case "${opt}" in
        -)
            case "${OPTARG}" in
                start-date)
                    START_DATE="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                stop-date)
                    STOP_DATE="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                output)
                    VIDEO_OUTPUT="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    RECORD_MODE=true
                    ;;
                record)
                    RECORD_MODE=true
                    ;;
                duration)
                    DURATION="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                *)
                    echo "Invalid option: --${OPTARG}" >&2
                    exit 1
                    ;;
            esac
            ;;
        s)
            START_DATE="$OPTARG"
            ;;
        e)
            STOP_DATE="$OPTARG"
            ;;
        o)
            VIDEO_OUTPUT="$OPTARG"
            RECORD_MODE=true
            ;;
        r)
            RECORD_MODE=true
            ;;
        d)
            DURATION="$OPTARG"
            ;;
        :)
            echo "Option -$OPTARG requires an argument" >&2
            exit 1
            ;;
        ?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Cleanup function to remove old logs
cleanup_logs() {
    echo "Cleaning up old log files..."
    rm -f gource_*.log combined_pokt_repos.log
}

# Function to generate a Gource log for a single repository
generate_repo_log() {
    local repo_name=$1
    local output_file="gource_${repo_name}.log"

    echo "Processing ${repo_name}..."

    if [ ! -d "$repo_name" ]; then
        echo "Warning: Directory $repo_name not found, skipping..."
        return
    fi

    cd "$repo_name"
    gource --output-custom-log "../$output_file"
    cd ..

    # Modify the log to put each repo in its own root directory
    sed -i -E "s#\|/#|${repo_name}/#" "$output_file"
    sed -i -E "s#\|([^/])#|${repo_name}/\1#" "$output_file"

    echo "Generated log for $repo_name"
}

# Function to combine multiple logs
combine_logs() {
    local output_file="combined_pokt_repos.log"
    cat gource_*.log 2>/dev/null | sort -n > "$output_file"
    echo "Combined logs into $output_file"
}

# Function to check if required commands are available
check_dependencies() {
    local missing_deps=()

    if ! command -v gource >/dev/null 2>&1; then
        missing_deps+=("gource")
    fi

    if ! command -v ffmpeg >/dev/null 2>&1; then
        missing_deps+=("ffmpeg")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo "Please install them and try again."
        exit 1
    fi
}

# Function to run Gource visualization
Updated Gource Visualization Script

run_visualization() {
    local log_file="combined_pokt_repos.log"
#    local resolution="1920x1080"
    local resolution="2560x1440"
    local fps="60"

    # Calculate speed with more appropriate scaling
    local start_time=$(head -n1 "$log_file" | cut -d'|' -f1)
    local end_time=$(tail -n1 "$log_file" | cut -d'|' -f1)
    local time_span=$((end_time - start_time))
    local days=$((time_span / 86400))
#    local seconds_per_day=$(bc -l <<< "scale=3; ($DURATION * 0.8) / sqrt($days)")
    local seconds_per_day=0.15

    echo "Debug timing:"
    echo "Start time: $start_time"
    echo "End time: $end_time"
    echo "Time span: $time_span seconds"
    echo "Days: $days"
    echo "Target duration: $DURATION seconds"
    echo "Seconds per day: $seconds_per_day"

    # Base Gource command
    local gource_cmd="gource '$log_file' \
        --user-image-dir '$AVATAR_DIR' \
        --seconds-per-day $seconds_per_day \
        --auto-skip-seconds 1 \
        --title 'POKT Ecosystem Visualization' \
        --key \
        --highlight-users \
        --file-idle-time 0 \
        --max-file-lag 0.1 \
        --bloom-multiplier 0.3 \
        --background-colour 000000 \
        --font-size 18 \
        --dir-name-depth 3 \
        --filename-time 2 \
        --hide filenames \
        --user-scale 1.5 \
        --multi-sampling \
        --elasticity 0.1 \
        --camera-mode overview"

    [[ -n "$START_DATE" ]] && gource_cmd="$gource_cmd --start-date '$START_DATE'"
    [[ -n "$STOP_DATE" ]] && gource_cmd="$gource_cmd --stop-date '$STOP_DATE'"

    if [ "$RECORD_MODE" = true ]; then
        gource_cmd="$gource_cmd -${resolution} -o -"

        local ffmpeg_cmd
        case "${VIDEO_OUTPUT##*.}" in
            "webm")
                ffmpeg_cmd="ffmpeg -y -r $fps \
                    -f image2pipe -vcodec ppm -i - \
                    -c:v libvpx-vp9 -b:v 2M -crf 30 \
                    -deadline good -cpu-used 2 \
                    -pix_fmt yuv420p \
                    '$VIDEO_OUTPUT'"
                ;;
            *)
                ffmpeg_cmd="ffmpeg -y -r $fps \
                    -f image2pipe -vcodec ppm -i - \
                    -vcodec libx264 -preset medium \
                    -pix_fmt yuv420p -crf 18 \
                    -threads 0 -bf 0 \
                    '$VIDEO_OUTPUT'"
                ;;
        esac
        eval "$gource_cmd | $ffmpeg_cmd"
    else
        eval "$gource_cmd"
    fi
}

# Main execution
echo "Starting POKT repositories visualization process..."

# Check for required dependencies
check_dependencies

# Clean up old logs first
cleanup_logs

# Generate logs for each repository
for repo in "${REPOS[@]}"; do
    generate_repo_log "$repo"
done

# Combine all logs
combine_logs

# Run visualization and generate video
run_visualization