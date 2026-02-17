# 🧪 Guia Rápido de Teste - installer_v3.sh

## ⚡ Início Rápido

### 1. Preparar Ambiente de Teste
```bash
# Recomendado: VM ou container Debian 12 limpo
# Requisitos mínimos:
# - 2GB RAM
# - 10GB disco
# - Internet estável
```

### 2. Executar installer_v3.sh
```bash
cd /usr/src/
sudo git clone https://github.com/PU5KOD/XLX_Installer.git
cd XLX_Installer/
sudo chmod +x installer_v3.sh
sudo ./installer_v3.sh
```

### 3. Monitorar Logs
```bash
# Em outro terminal
tail -f /usr/src/XLX_Installer/log/log_xlx_install_*.log
```

## ✅ Checklist de Testes Essenciais

### Testes Básicos
- [ ] Script inicia sem erros
- [ ] Verificação de root funciona
- [ ] Criação de log funciona
- [ ] Verificação de internet funciona (3 tentativas)
- [ ] Todas as perguntas aparecem corretamente

### Testes de Validação de Entrada
- [ ] MODQTD rejeita valores < 1 ou > 26
- [ ] Email rejeita formato inválido (ex: "teste@")
- [ ] Callsign rejeita caracteres especiais
- [ ] Timezone valida corretamente
- [ ] Porta YSF rejeita valores inválidos

### Testes de Segurança
- [ ] Inputs com caracteres especiais são escapados corretamente
- [ ] curl usa HTTPS (não HTTP)
- [ ] Git clone usa --depth 1
- [ ] Nenhuma injeção de comando possível via inputs

### Testes de Validação de Sistema
- [ ] Verifica espaço em disco (requer 1GB+)
- [ ] Detecta conflito de porta (se porta 42000 estiver em uso)
- [ ] Valida instalação de PHP
- [ ] Valida arquivos de timezone

### Testes de Instalação
- [ ] Download de dependências bem-sucedido
- [ ] Clone do repositório XLX funciona
- [ ] Compilação completa sem erros
- [ ] Binário xlxd criado em /xlxd/
- [ ] Dashboard copiado para /var/www/html/xlxd/

### Testes de Serviços
- [ ] xlxd.service inicia corretamente
- [ ] xlx_log.service inicia corretamente
- [ ] xlxecho.service inicia (se instalado)
- [ ] Apache2 reinicia corretamente
- [ ] Validação pós-instalação passa

### Testes de Funcionalidade
- [ ] Dashboard acessível via navegador
- [ ] Módulos configurados corretamente
- [ ] Echo Test funciona (se instalado)
- [ ] SSL configurado (se escolhido)
- [ ] YSF auto-link funciona (se configurado)

## 🔍 Testes de Casos Especiais

### Teste 1: Espaço em Disco Insuficiente
```bash
# Simular disco cheio
# O script deve parar com mensagem clara
```

### Teste 2: Conflito de Porta
```bash
# Antes de executar o instalador:
nc -l 42000 &
# O script deve avisar sobre conflito
```

### Teste 3: Sem Internet
```bash
# Desconectar internet temporariamente
# O script deve tentar 3 vezes antes de falhar
```

### Teste 4: Valores Extremos
```bash
# Durante instalação, testar:
# - MODQTD = 0 (deve rejeitar)
# - MODQTD = 27 (deve rejeitar)
# - MODQTD = 1 (deve aceitar)
# - MODQTD = 26 (deve aceitar)
```

## 📊 Verificação Pós-Instalação

### Verificar Binários
```bash
ls -lh /xlxd/xlxd
ls -lh /xlxd/xlxecho  # se instalado
```

### Verificar Serviços
```bash
sudo systemctl status xlxd.service
sudo systemctl status xlx_log.service
sudo systemctl status xlxecho.service  # se instalado
sudo systemctl status apache2
```

### Verificar Dashboard
```bash
# Navegador:
http://seu-dominio.com
# ou
http://seu-ip
```

### Verificar Logs
```bash
tail -100 /var/log/xlx.log
tail -100 /var/log/xlxd*.log
```

### Verificar Permissões
```bash
ls -lh /xlxd/
ls -lh /var/www/html/xlxd/
```

## ⚠️ Problemas Conhecidos a Verificar

### Se encontrar erros, verificar:
1. **Log completo**: `/usr/src/XLX_Installer/log/log_xlx_install_*.log`
2. **Versão do sistema**: `lsb_release -a`
3. **Espaço em disco**: `df -h`
4. **Memória**: `free -h`
5. **Serviços**: `systemctl status xlxd xlx_log apache2`

## 📝 Comparação com Versão Original

### Teste Lado a Lado (Opcional)
```bash
# Em uma VM: instalar com installer.sh
# Em outra VM: instalar com installer_v3.sh
# Comparar:
# - Tempo de instalação
# - Logs gerados
# - Serviços finais
# - Funcionalidade
```

## ✅ Critérios de Aprovação

Para considerar installer_v3.sh pronto para produção:

- [ ] Todas as funcionalidades do installer.sh original funcionam
- [ ] Nenhum erro novo introduzido
- [ ] Validações adicionais funcionam corretamente
- [ ] Mensagens de erro são claras e úteis
- [ ] Performance similar ou melhor
- [ ] Logs são informativos
- [ ] Instalação completa sem intervenção manual

## 🚀 Após Aprovação

Se todos os testes passarem:

```bash
cd /usr/src/XLX_Installer/
# Backup da versão original
sudo mv installer.sh installer.sh.original
# Promover v3 para principal
sudo cp installer_v3.sh installer.sh
# Verificar
bash -n installer.sh
```

## 📞 Suporte

Se encontrar problemas:
1. Verifique o log completo
2. Anote o comportamento específico
3. Descreva os passos para reproduzir
4. Reporte via issue no GitHub

---

**Boa sorte com os testes!** 🍀
