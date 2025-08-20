#!/bin/bash
# Solicita o nome do usuário
read -p "Digite o nome do usuário: " USUARIO

# Verifica se o nome do usuário segue o padrão exigido
if [[ ! "$USUARIO" =~ ^[A-Z0-9]{4,8}$ ]] || [[ $(echo "$USUARIO" | grep -o '[0-9]' | wc -l) -gt 1 ]]; then
    echo "Erro: O nome do usuário deve conter entre 4 e 8 caracteres, todas as letras maiúsculas e no máximo um número."
    exit 1
fi

# Verifica se o usuário já existe no .htpasswd
if ! sudo grep -q "^$USUARIO:" /var/www/restricted/.htpasswd; then
    echo "Usuário não existe!"
    exit 1
fi

# Gera uma nova senha forte
SENHA=$(tr -dc 'A-Za-z0-9!@#$%^&*()-_=+' < /dev/urandom | head -c 12)

# Remove a senha atual do .htpasswd
sudo sed -i "/^$USUARIO:/d" /var/www/restricted/.htpasswd

# Adiciona o usuário ao .htpasswd com a nova senha gerada
echo "Alterando a senha do usuário..."
sudo htpasswd -b /var/www/restricted/.htpasswd "$USUARIO" "$SENHA"

# Adiciona o usuário à lista de pendentes (evita duplicatas)
if ! grep -q "^$USUARIO$" /var/www/restricted/pendentes.txt; then
    echo "$USUARIO" | sudo tee -a /var/www/restricted/pendentes.txt > /dev/null
fi

# Mostra a nova senha gerada para o usuário
echo "Senha alterada com sucesso para o usuário $USUARIO!"
echo "Nova senha gerada: $SENHA"
echo "OBS: O usuário deve alterar a senha no primeiro login."
