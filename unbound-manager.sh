#!/bin/bash
# https://github.com/complexorganizations/unbound-manager

# Require script to be run as root
function super-user-check() {
  if [ "${EUID}" -ne 0 ]; then
    echo "You need to run this script as super user."
    exit
  fi
}

# Check for root
super-user-check

# Detect Operating System
function dist-check() {
  if [ -e /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    DISTRO=${ID}
  fi
}

# Check Operating System
dist-check

# Pre-Checks system requirements
function installing-system-requirements() {
  if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ] || [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ] || [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ] || [ "${DISTRO}" == "alpine" ] || [ "${DISTRO}" == "freebsd" ]; }; then
    if [ ! -x "$(command -v curl)" ]; then
      if { [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ]; }; then
        apt-get update && apt-get install curl -y
      elif { [ "${DISTRO}" == "fedora" ] || [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
        yum update -y && yum install curl -y
      elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ]; }; then
        pacman -Syu && pacman -Syu --noconfirm curl
      elif [ "${DISTRO}" == "alpine" ]; then
        apk update && apk add curl
      elif [ "${DISTRO}" == "freebsd" ]; then
        pkg update && pkg install curl
      fi
    fi
  else
    echo "Error: ${DISTRO} not supported."
    exit
  fi
}

# Run the function and check for requirements
installing-system-requirements

# Global variables
RESOLV_CONFIG="/etc/resolv.conf"
RESOLV_CONFIG_OLD="/etc/resolv.conf.old"
UNBOUND_ROOT="/etc/unbound"
UNBOUND_MANAGER="${UNBOUND_ROOT}/unbound-manager"
UNBOUND_CONFIG="${UNBOUND_ROOT}/unbound.conf"
UNBOUND_ROOT_HINTS="${UNBOUND_ROOT}/root.hints"
UNBOUND_ANCHOR="/var/lib/unbound/root.key"
UNBOUND_ROOT_SERVER_CONFIG_URL="https://www.internic.net/domain/named.cache"
UNBOUND_MANAGER_UPDATE_URL="https://raw.githubusercontent.com/complexorganizations/unbound-manager/main/unbound-manager.sh"

if [ ! -f "${UNBOUND_MANAGER}" ]; then

  # Function to install unbound
  function install-unbound() {
    if [ "${DISTRO}" == "ubuntu" ]; then
      apt-get install unbound unbound-host e2fsprogs -y
      if pgrep systemd-journal; then
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
      else
        service systemd-resolved stop
        service systemd-resolved disable
      fi
    elif { [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ]; }; then
      apt-get install unbound unbound-host e2fsprogs -y
    elif { [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
      yum install unbound unbound-libs -y
    elif [ "${DISTRO}" == "fedora" ]; then
      dnf install unbound -y
    elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ]; }; then
      pacman -Syu --noconfirm unbound
    elif [ "${DISTRO}" == "alpine" ]; then
      apk add unbound
    elif [ "${DISTRO}" == "freebsd" ]; then
      pkg install unbound
    fi
    if [ -f "${UNBOUND_ANCHOR}" ]; then
      rm -f ${UNBOUND_ANCHOR}
    fi
    if [ -f "${UNBOUND_CONFIG}" ]; then
      rm -f ${UNBOUND_CONFIG}
    fi
    if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
      rm -f ${UNBOUND_ROOT_HINTS}
    fi
    if [ -d "${UNBOUND_ROOT}" ]; then
      unbound-anchor -a ${UNBOUND_ANCHOR}
      curl ${UNBOUND_ROOT_SERVER_CONFIG_URL} -o ${UNBOUND_ROOT_HINTS}
      NPROC=$(nproc)
      echo "server:
    num-threads: ${NPROC}
    verbosity: 1
    root-hints: ${UNBOUND_ROOT_HINTS}
    auto-trust-anchor-file: ${UNBOUND_ANCHOR}
    interface: 0.0.0.0
    interface: ::0
    max-udp-size: 3072
    access-control: 0.0.0.0/0                 allow
    access-control: ::0                       allow
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    harden-referral-path: yes
    unwanted-reply-threshold: 10000000
    val-log-level: 1
    cache-min-ttl: 1800
    cache-max-ttl: 14400
    prefetch: yes
    qname-minimisation: yes
    prefetch-key: yes" >>${UNBOUND_CONFIG}
    fi
    # Move the resolve file to the old file
    if [ -f "${RESOLV_CONFIG}" ]; then
      mv ${RESOLV_CONFIG} ${RESOLV_CONFIG_OLD}
    fi
    # Use unbound as a nameserver
    echo "nameserver 127.0.0.1" >>${RESOLV_CONFIG}
    echo "nameserver ::1" >>${RESOLV_CONFIG}
    if [ ! -f "${UNBOUND_MANAGER}" ]; then
      echo "Unbound: true" >>${UNBOUND_MANAGER}
    fi
    # restart unbound
    if pgrep systemd-journal; then
      systemctl reenable unbound
      systemctl restart unbound
    else
      service unbound enable
      service unbound restart
    fi
  }

  # Running Install Unbound
  install-unbound

  # Install unbound manager
  function install-unbound-manager-file() {
    if [ -d "${UNBOUND_ROOT}" ]; then
      if [ ! -f "${UNBOUND_MANAGER}" ]; then
        echo "Unbound Manager: true" >>${UNBOUND_MANAGER}
      fi
    fi
  }

  # wireguard unbound
  install-unbound-manager-file

else

  # take user input
  function take-user-input() {
    echo "What do you want to do?"
    echo "   1) Start Unbound"
    echo "   2) Stop Unbound"
    echo "   3) Restart Unbound"
    echo "   4) Uninstall Unbound"
    echo "   5) Update Unbound Manager"
    until [[ "$USER_OPTIONS" =~ ^[0-9]+$ ]] && [ "$USER_OPTIONS" -ge 1 ] && [ "$USER_OPTIONS" -le 5 ]; do
      read -rp "Select an Option [1-5]: " -e -i 1 USER_OPTIONS
    done
    case $USER_OPTIONS in
    1)
      if [ -x "$(command -v unbound)" ]; then
        if pgrep systemd-journal; then
          systemctl start unbound
        else
          service unbound start
        fi
      fi
      ;;
    2)
      if [ -x "$(command -v unbound)" ]; then
        if pgrep systemd-journal; then
          systemctl stop unbound
        else
          service unbound stop
        fi
      fi
      ;;
    3)
      if [ -x "$(command -v unbound)" ]; then
        if pgrep systemd-journal; then
          systemctl restart unbound
        else
          service unbound restart
        fi
      fi
      ;;
    4)
      if [ -x "$(command -v unbound)" ]; then
        if [ -f "${UNBOUND_MANAGER}" ]; then
          if pgrep systemd-journal; then
            systemctl disable unbound
            systemctl stop unbound
          else
            service unbound disable
            service unbound stop
          fi
          if [ -f "${RESOLV_CONFIG_OLD}" ]; then
            rm -f ${RESOLV_CONFIG}
            mv ${RESOLV_CONFIG_OLD} ${RESOLV_CONFIG}
          fi
          if { [ "${DISTRO}" == "centos" ] || [ "${DISTRO}" == "rhel" ]; }; then
            yum remove unbound unbound-host -y
          elif { [ "${DISTRO}" == "debian" ] || [ "${DISTRO}" == "pop" ] || [ "${DISTRO}" == "ubuntu" ] || [ "${DISTRO}" == "raspbian" ] || [ "${DISTRO}" == "kali" ] || [ "${DISTRO}" == "linuxmint" ]; }; then
            apt-get remove --purge unbound unbound-host -y
          elif { [ "${DISTRO}" == "arch" ] || [ "${DISTRO}" == "manjaro" ]; }; then
            pacman -Rs unbound unbound-host -y
          elif [ "${DISTRO}" == "fedora" ]; then
            dnf remove unbound -y
          elif [ "${DISTRO}" == "alpine" ]; then
            apk del unbound
          elif [ "${DISTRO}" == "freebsd" ]; then
            pkg delete unbound
          fi
          if [ -f "${UNBOUND_MANAGER}" ]; then
            rm -f ${UNBOUND_MANAGER}
          fi
          if [ -f "${UNBOUND_CONFIG}" ]; then
            rm -f ${UNBOUND_CONFIG}
          fi
          if [ -f "${UNBOUND_ANCHOR}" ]; then
            rm -f ${UNBOUND_ANCHOR}
          fi
          if [ -f "${UNBOUND_ROOT_HINTS}" ]; then
            rm -f ${UNBOUND_ROOT_HINTS}
          fi
          if [ -f "${UNBOUND_ROOT}" ]; then
            rm -f ${UNBOUND_ROOT}
          fi
        fi
      fi
      ;;
    5)
      CURRENT_FILE_PATH="$(realpath "$0")"
      if [ -f "${CURRENT_FILE_PATH}" ]; then
        curl -o "${CURRENT_FILE_PATH}" ${UNBOUND_MANAGER_UPDATE_URL}
        chmod +x "${CURRENT_FILE_PATH}" || exit
      fi
      ;;
    esac
  }

  # run the function
  take-user-input

fi
