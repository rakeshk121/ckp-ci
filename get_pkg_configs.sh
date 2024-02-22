#!/bin/bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

k8s_versions=("1.26" "1.27" "1.28" "1.29")
package_names=("kubeadm" "kubelet")

# Iterate through all the k8s_versions and update the debian source repo for each verions
for version in "${k8s_versions[@]}"; do
    # Use the current version in the curl and echo commands
    if [ ! -f "/etc/apt/keyrings/kubernetes-apt-keyring.gpg" ]; then
        curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${version}/deb/Release.key" | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    fi
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${version}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes_v${version}.list
done

sudo apt update

# Get the current working directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Iterate through each package
for package in "${package_names[@]}"; do
    # Use apt list to get the available versions
    available_k8s_versions=$(apt list -a -q $package | grep -oP "\s\d\S+" | sort -V)

    # Iterate through the available versions, extract major, minor, and patch version, and remove duplicates
    unique_k8s_versions=$(echo "$available_k8s_versions" | cut -d'-' -f1 | sort -V | uniq)

    # Iterate through the unique versions, create folder structure, and download deb packages
    for version in $unique_k8s_versions; do
        echo "Getting the ${package} for k8s version $version"
        # Extract major and minor version components
        major_minor_version=$(echo $version | cut -d'.' -f1-2)

        # Create folder structure
        folder_path="${package}/${major_minor_version}"
        mkdir -p "$folder_path"

        # Change working directory before downloading deb packages
        cd "$folder_path"
        
        # Download deb packages into the folder
        apt-get download ${package}=${version}-*
        dpkg-deb -x $(ls ${package}_${version}-*.deb) ${package}_${version}
        rm -f $(ls ${package}_${version}-*.deb)
        rm -rf ${package}_${version}/usr

        # Return to the original working directory
        cd "$script_dir"
    done
done
