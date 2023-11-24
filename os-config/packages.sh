#!/usr/bin/env bash

set -oue pipefail

script_link=$(readlink -f "${0}")
script_dir=$(dirname "${script_link}")

echo "Building list of packages..."
INCLUDED_PACKAGES=($(jq -r '.include[]' ${script_dir}/packages.json | sort | uniq))
EXCLUDED_PACKAGES=($(jq -r '.exclude[]' ${script_dir}/packages.json | sort | uniq))

echo -e "\nIncluded Packages: ${#INCLUDED_PACKAGES[@]}"
echo ${INCLUDED_PACKAGES[@]}

echo -e "\nExcluded Packages: ${#EXCLUDED_PACKAGES[@]}"
echo ${EXCLUDED_PACKAGES[@]}

echo -e "\nEnsure exclusion list only contains packages already present on image..."
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    EXCLUDED_PACKAGES=($(rpm -qa --queryformat='%{NAME} ' ${EXCLUDED_PACKAGES[@]}))
fi

echo -e "\nExcluded Packages: ${#EXCLUDED_PACKAGES[@]}"

if [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -eq 0 ]]; then
  echo -e "\nSimple case to install where no packages need excluding..."
  rpm-ostree install ${INCLUDED_PACKAGES[@]}
elif [[ "${#INCLUDED_PACKAGES[@]}" -gt 0 && "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
  echo -e "\nInstall/excluded packages both at same time..."
  rpm-ostree override remove ${EXCLUDED_PACKAGES[@]} $(printf -- "--install=%s " ${INCLUDED_PACKAGES[@]})
else
  echo "No packages to install."
fi

echo "Check if any excluded packages are still present."
echo "(This can happen if an included package pulls in a dependency)"
EXCLUDED_PACKAGES=($(jq -r '.exclude[]' ${script_dir}/packages.json | sort | uniq))

if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    EXCLUDED_PACKAGES=($(rpm -qa --queryformat='%{NAME} ' ${EXCLUDED_PACKAGES[@]}))
fi
echo -e "\nExcluded Packages: ${#EXCLUDED_PACKAGES[@]}"

echo "Remove any excluded packages which are still present on image"
if [[ "${#EXCLUDED_PACKAGES[@]}" -gt 0 ]]; then
    rpm-ostree override remove ${EXCLUDED_PACKAGES[@]}
fi
