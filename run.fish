#!/usr/bin/env fish

# Load utilities
source ./lib/utils.fish

# Welcome banner
print_banner "MacBook Setup Runner"
print_info "This tool will help you set up your MacBook with essential software and configurations."

# Initialize global email variable but don't ask for it right away
set -g user_email ""

# Function to ensure we have user's email when needed
function ensure_user_email
    if test -z "$user_email"
        set -g user_email (read_input "Enter your email address (for Git and SSH)" "")
    end
end

# Function to ask for confirmation with default yes and cancel option
function confirm_with_cancel
    set prompt $argv[1]
    set default "yes"
    if test (count $argv) -gt 1
        set default $argv[2]
    end
    
    while true
        if test "$default" = "yes"
            read -P "$prompt [Y/n/c] " response
            set response (string lower "$response")
            if test -z "$response"
                return 0
            end
        else
            read -P "$prompt [y/N/c] " response
            set response (string lower "$response")
            if test -z "$response"
                return 1
            end
        end
        
        switch $response
            case y yes
                return 0
            case n no
                return 1
            case c cancel
                print_warning "Setup cancelled by user. Exiting..."
                exit 1
            case '*'
                if test "$default" = "yes"
                    echo "Please answer Y (yes), N (no), or C (cancel)."
                else
                    echo "Please answer y (yes), N (no), or C (cancel)."
                end
        end
    end
end

# Check if fzf is installed
function has_fzf
    command -q fzf
    return $status
end

# Dynamically load and order available jobs
set -l jobs_dir "./jobs"
set available_jobs
set job_files
set job_names

# Find all fish files in the jobs directory and sort them
if test -d $jobs_dir
    # Get all .fish files from the jobs directory
    set -l all_job_files (find $jobs_dir -name "*.fish" | sort)
    
    # Process job files
    for job_file in $all_job_files
        # Extract the base name without extension
        set -l base_name (basename $job_file .fish)
        
        # Remove the numeric prefix if present (e.g., "01_setup" becomes "setup")
        set -l job_name (string replace -r "^\d+_" "" $base_name)
        
        # Add to our job lists
        set -a available_jobs $job_name
        set -a job_files $job_file
        set -a job_names $job_name
    end
else
    print_error "Jobs directory not found: $jobs_dir"
    exit 1
end

# Check if jobs were specified as command-line arguments
if test (count $argv) -gt 0
    set jobs_to_run $argv
    set jobs_not_found
    set selected_indices

    # Validate job names and find their indices
    for job_arg in $jobs_to_run
        set found 0
        for i in (seq (count $available_jobs))
            if test "$available_jobs[$i]" = "$job_arg"
                set -a selected_indices $i
                set found 1
                break
            end
        end
        
        if test $found -eq 0
            set -a jobs_not_found $job_arg
        end
    end
    
    # Report any jobs that weren't found
    if test (count $jobs_not_found) -gt 0
        print_warning "The following jobs were not found: "(string join ", " $jobs_not_found)
        echo "Available jobs: "(string join ", " $available_jobs)
        exit 1
    end
    
    # Run the specified jobs
    print_info "Running specified jobs: "(string join ", " $jobs_to_run)
    for i in $selected_indices
        set job_file $job_files[$i]
        set job_name $available_jobs[$i]
        print_step "Running $job_name setup..."
        source $job_file
    end
    
    print_success "Setup complete!"
    exit 0
else
    # Go directly to job selection 
    # Use fzf for selection if available
    if has_fzf
        # Create job display list with indices
        set job_display_list
        set -a job_display_list "[All] Run ALL jobs in order"
        for i in (seq (count $available_jobs))
            set -a job_display_list "[$i] $available_jobs[$i]"
        end
        
        print_info "Select jobs to run (TAB to select multiple, ENTER to confirm):"
        # Run fzf and get selected jobs
        set selected_jobs (printf "%s\n" $job_display_list | fzf --multi --height 40% --layout=reverse --border)
        
        # Parse indices from selected jobs
        set selected_indices
        set run_all_jobs 0
        for selection in $selected_jobs
            set index (string replace -r '^\[(\w+)\].*' '$1' $selection)
            
            # Check if the "Run ALL jobs" option was selected
            if test "$index" = "All"
                set run_all_jobs 1
                break
            end
            
            set -a selected_indices $index
        end
        
        # Handle case when user exits fzf without selecting anything
        if test (count $selected_indices) -eq 0 -a $run_all_jobs -eq 0
            print_warning "No jobs selected. Exiting..."
            exit 0
        end
        
        # If "Run ALL jobs" was selected, run all jobs in order
        if test $run_all_jobs -eq 1
            print_info "Running ALL jobs in order..."
            for i in (seq (count $job_files))
                set job_file $job_files[$i]
                set job_name $available_jobs[$i]
                print_step "Running $job_name setup..."
                source $job_file
            end
        else
            # Run only the selected jobs
            print_info "Running selected jobs..."
            for i in $selected_indices
                set job_file $job_files[$i]
                set job_name $available_jobs[$i]
                print_step "Running $job_name setup..."
                source $job_file
            end
        end
    else
        # Fall back to a simpler method if fzf is not available
        print_info "fzf not installed. Using basic selection mode..."
        if confirm_with_cancel "Would you like to run ALL jobs in order?" "no"
            print_info "Running ALL jobs in order..."
            for i in (seq (count $job_files))
                set job_file $job_files[$i]
                set job_name $available_jobs[$i]
                print_step "Running $job_name setup..."
                source $job_file
            end
        else
            # Fall back to the original selection method
            echo "Available jobs:"
            set selected_indices
            
            for i in (seq (count $available_jobs))
                set job_name $available_jobs[$i]
                if confirm_with_cancel "Include [$i] $job_name?" "no"
                    set -a selected_indices $i
                end
            end
            
            # Handle case when no jobs are selected
            if test (count $selected_indices) -eq 0
                print_warning "No jobs selected. Exiting..."
                exit 0
            end
            
            # Run only the selected jobs
            print_info "Running selected jobs..."
            for i in $selected_indices
                set job_file $job_files[$i]
                set job_name $available_jobs[$i]
                print_step "Running $job_name setup..."
                source $job_file
            end
        end
    end
end

print_success "Setup complete!"