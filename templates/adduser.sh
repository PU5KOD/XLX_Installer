#!/bin/bash
# Solicita o nome do usuário
read -p "Digite o nome do usuário: " USUARIO

# Verifica se o nome do usuário segue o padrão exigido
if [[ ! "$USUARIO" =~ ^[A-Z0-9]{4,8}$ ]] || [[ $(echo "$USUARIO" | grep -o '[0-9]' | wc -l) -gt 1 ]]; then
    echo "Erro: O nome do usuário deve conter entre 4 e 8 caracteres, todas as letras maiúsculas e no máximo um número."
    exit 1
fi

# Verifica se o usuário já existe no .htpasswd
if sudo grep -q "^$USUARIO:" /var/www/restricted/.htpasswd; then
    echo "Usuário já existe!"
    exit 1
fi

# Adiciona o usuário à whitelist
echo "$USUARIO" | sudo tee -a /xlxd/xlxd.whitelist > /dev/null

# Gera uma senha forte com os requisitos especificados
SENHA=$(tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' < /dev/urandom | head -c 12)

# Adiciona o usuário ao .htpasswd com a senha gerada
echo "Adicionando usuário..."
sudo htpasswd -b /var/www/restricted/.htpasswd "$USUARIO" "$SENHA"

# Adiciona o usuário à lista de pendentes (evita duplicatas)
if ! grep -q "^$USUARIO$" /var/www/restricted/pendentes.txt; then
    echo "$USUARIO" | sudo tee -a /var/www/restricted/pendentes.txt > /dev/null
fi

# Mostra a senha gerada para o usuário
echo "Usuário $USUARIO adicionado com sucesso!"
echo "Senha gerada: $SENHA"
echo "OBS: O usuário deve alterar a senha no primeiro login."
