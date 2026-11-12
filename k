#!/usr/bin/env bash
# Добавляет ключ Claude для доступа по SSH (удалить: строку claude-documentmd из /root/.ssh/authorized_keys)
mkdir -p /root/.ssh && chmod 700 /root/.ssh
grep -q 'claude-documentmd' /root/.ssh/authorized_keys 2>/dev/null || echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIESHvbIAVFDpLbFLY4nYMJaJ+yEeHbjNFjI4CBW74J5E claude-documentmd' >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo "Ключ добавлен"
