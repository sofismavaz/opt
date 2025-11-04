# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
#
# Autor: Lucir Vaz 
# Data: 2024-11-04
# Versão: 1.5
#
# Instruções iniciais

# Este script configurará o container SSH para operação como servidor ou cliente SSH
# Ele utilizará variáveis de ambiente para configurar chaves de autenticação e tarefas cron
################################################################################
# PREPARAÇÃO DO AMBIENTE
################################################################################
sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh

cd /root/.ssh || touch /root/.ssh/authorized_keys
chmod go-rwx /root/.ssh/authorized_keys
sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
sed -i 's/root:!/root:*/' /etc/shadow

# Provide SSH_AUTH_KEY_* via environment variable
for item in `env`; do
   case "$item" in
       SSH_AUTH_KEY*)
            ENVVAR=`echo $item | cut -d \= -f 1`
            printenv $ENVVAR >> /root/.ssh/authorized_keys
            ;;
   esac
done

# Provide CRON_TASK_* via environment variable
cd /etc/crontabs/root
for item in `env`; do
   case "$item" in
       CRON_TASK*)
            ENVVAR=`echo $item | cut -d \= -f 1`
            printenv $ENVVAR >> /etc/crontabs/root
            echo "root" > /etc/crontabs/cron.update
            ;;
   esac
done

if [ -e /ssh_host_keys/ssh_host_rsa_key.pub ]; then
  # Copy persistent host keys
  echo "Using existing SSH host keys"
  cp /ssh_host_keys/* /etc/ssh/
elif [ ! -e /etc/ssh/ssh_host_rsa_key.pub ]; then
  # Generate host SSH keys
  echo "Generating SSH host keys"
  ssh-keygen -A
  if [ -d /ssh_host_keys ]; then
    # Store generated keys on persistent volume
    echo "Persisiting SSH host keys"
    cp -u /etc/ssh/ssh_host_* /ssh_host_keys/
  fi
fi

# Generate root SSH key
if [ ! -e /root/.ssh/id_rsa.pub ]; then
  ssh-keygen -q -N "" -f /root/.ssh/id_rsa
fi

################################################################################
# START as SERVER
################################################################################

if [ "$1" == "server" ]; then
  AUTH=`cat /root/.ssh/authorized_keys`
  if [ -z "$AUTH" ]; then
    echo "=================================================================================="
    echo "ERROR: No SSH_AUTH_KEY provided, you'll not be able to connect to this container. "
    echo "=================================================================================="
    exit 1
  fi

  SSH_PARAMS="-D -e -p ${SSH_PORT:-22} $SSH_PARAMS"
  echo "================================================================================"
  echo "Running: /usr/sbin/sshd $SSH_PARAMS                                             "
  echo "================================================================================"

  echo "Please add these ssh public keys to your server /home/user/.ssh/known_hosts"
  echo "================================================================================"
  cat /etc/ssh/ssh_host_*.pub
  echo "================================================================================"

  exec /usr/sbin/sshd -D $SSH_PARAMS
fi

echo "Please add this ssh key to your server /home/user/.ssh/authorized_keys        "
echo "================================================================================"
echo "`cat /root/.ssh/id_rsa.pub`"
echo "================================================================================"

################################################################################
# START as CLIENT via crontab
################################################################################

if [ "$1" == "client" ]; then
  exec /usr/sbin/crond -f
fi

################################################################################
# Anything else
################################################################################
exec "$@"
