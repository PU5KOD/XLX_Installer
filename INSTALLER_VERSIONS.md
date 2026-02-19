# Versões do Instalador XLX

Este documento descreve as diferentes versões do script instalador disponíveis neste repositório.

## 📋 Versões Disponíveis

### installer.sh (Versão Atual - baseado em v3) ⭐
- **Status**: Versão estável em produção
- **Descrição**: Versão melhorada com correções de segurança, validação e tratamento de erros
- **Uso**: `sudo ./installer.sh`
- **Recomendado para**: Produção
- **Nota**: A partir de 2026-02-19, installer.sh é baseado em installer_v3.sh com todas as melhorias

### installer_v1.sh (Versão Original Preservada)
- **Status**: Backup da versão original
- **Descrição**: Script instalador original preservado para referência
- **Uso**: `sudo ./installer_v1.sh`
- **Nota**: Esta é a versão original que estava em installer.sh antes de 2026-02-19

### installer_v2.sh
- **Status**: Versão alternativa experimental
- **Descrição**: Versão com refatoração de código e uso de biblioteca de funções visuais
- **Características**: 
  - Usa arquivo de biblioteca externa (templates/cli_visual_unicode.txt)
  - Estrutura modular com funções de logging
  - ~1460 linhas
- **Uso**: `sudo ./installer_v2.sh`

### installer_v3.sh ✅ **PROMOVIDO PARA PRODUÇÃO**
- **Status**: Agora é a versão principal (instalada como installer.sh)
- **Descrição**: Versão melhorada com correções de segurança, validação e tratamento de erros
- **Nota**: A partir de 2026-02-19, esta versão substituiu installer.sh
- **Características principais**:
  - ✅ 8 vulnerabilidades de segurança corrigidas
  - ✅ 17+ handlers de erro implementados
  - ✅ 9+ validações adicionadas
  - ✅ 100% compatível com versão original
  - ✅ Todas as funcionalidades preservadas

#### Melhorias de Segurança
1. **Prevenção de injeção via sed** - Todos os inputs sanitizados com `escape_sed()`
2. **Conexões HTTPS** - curl usa HTTPS com timeout de 5 segundos
3. **Git clone seguro** - Usa `--depth 1` para limitar superfície de ataque
4. **Validação de ranges** - MODQTD validado (1-26) na entrada

#### Melhorias de Confiabilidade
1. **Modo estrito** - `set -o pipefail` para capturar erros em pipelines
2. **Funções auxiliares** - `error_exit()`, `success_msg()`, `escape_sed()`
3. **Validação antecipada** - Verificação de diretório de log antes do redirect
4. **Verificações abrangentes** - Todas as operações críticas verificadas

#### Novas Validações
1. Espaço em disco (mínimo 1GB em /usr/src)
2. Confiabilidade de rede (3 tentativas de ping)
3. Detecção de conflito de portas
4. Validação de versão PHP
5. Validação pós-instalação completa
6. Verificação de arquivos de timezone
7. Verificação de existência de diretórios antes de chmod

## 🧪 Como Testar installer_v3.sh

### Ambiente de Teste Recomendado
- VM ou container Debian 12 limpo
- Pelo menos 2GB de RAM
- 10GB de espaço em disco
- Conexão de internet estável

### Passos para Teste

1. **Clone o repositório**:
   ```bash
   cd /usr/src/
   sudo git clone https://github.com/PU5KOD/XLX_Installer.git
   cd XLX_Installer/
   ```

2. **Torne o script executável**:
   ```bash
   sudo chmod +x installer_v3.sh
   ```

3. **Execute o instalador**:
   ```bash
   sudo ./installer_v3.sh
   ```

4. **Verifique os logs**:
   ```bash
   tail -f log/log_xlx_install_*.log
   ```

### Checklist de Validação

- [ ] Script inicia sem erros de sintaxe
- [ ] Todas as perguntas aparecem corretamente
- [ ] Validações de entrada funcionam (testar valores inválidos)
- [ ] Download de dependências bem-sucedido
- [ ] Compilação do XLX concluída
- [ ] Serviços iniciados corretamente
- [ ] Dashboard acessível via navegador
- [ ] Echo Test funciona (se instalado)
- [ ] Logs criados corretamente
- [ ] Permissões de arquivo corretas

### Casos de Teste Específicos

1. **Teste de validação de entrada**:
   - Tente inserir MODQTD = 0 ou 27 (deve rejeitar)
   - Tente inserir email inválido (deve rejeitar)
   - Tente inserir callsign com caracteres especiais (deve rejeitar)

2. **Teste de conflito de porta**:
   - Inicie algo na porta 42000 antes de executar
   - Verifique se o script avisa sobre o conflito

3. **Teste de espaço em disco**:
   - Em VM com <1GB livre em /usr/src
   - Verifique se o script para com mensagem apropriada

4. **Teste de rede**:
   - Desconecte a rede temporariamente
   - Verifique se o script tenta 3 vezes antes de falhar

## ✅ Migração Concluída

A migração de `installer_v3.sh` para `installer.sh` foi concluída em **2026-02-19**.

**O que foi feito:**

```bash
# Backup da versão original
cp installer.sh installer_v1.sh

# Promover v3 para principal
cp installer_v3.sh installer.sh

# Verificado
bash -n installer.sh  # ✓ OK
```

**Agora:**
- `installer.sh` = versão v3 (produção)
- `installer_v1.sh` = backup da versão original
- `installer_v3.sh` = mantido para referência

## 📊 Comparação de Versões

| Característica | installer_v1.sh (original) | installer.sh (atual/v3) | installer_v2.sh |
|----------------|----------------------------|-------------------------|-----------------|
| Linhas de código | ~1158 | ~1323 | ~1460 |
| Prevenção sed injection | ❌ | ❌ | ✅ |
| HTTPS com timeout | ❌ | ❌ | ✅ |
| Validação de espaço em disco | ❌ | ❌ | ✅ |
| Validação de porta | ❌ | ❌ | ✅ |
| Retry de rede | ❌ | ❌ | ✅ |
| Validação pós-instalação | ❌ | ❌ | ✅ |
| Modo estrito (pipefail) | ❌ | ✅ | ✅ |
| Funções auxiliares | Parcial | ✅ | ✅ |
| Biblioteca externa | ❌ | ✅ | ❌ |
| Compatibilidade | 100% | 100% | 100% |

## 🐛 Reportar Problemas

Se encontrar problemas com `installer_v3.sh`:

1. Colete o log completo: `log/log_xlx_install_*.log`
2. Anote a distribuição e versão do sistema
3. Descreva o comportamento esperado vs observado
4. Abra uma issue no GitHub com estas informações

## 📝 Notas Adicionais

- Todas as versões mantêm 100% de compatibilidade com entradas/prompts
- Nenhuma funcionalidade foi removida em nenhuma versão
- v3 adiciona apenas validações e segurança, sem alterar fluxo
- Logs são criados em todas as versões no diretório `log/`

---

**Última atualização**: 2026-02-19
**Autor**: Daniel K., PU5KOD
**Versão em produção**: installer.sh (baseado em v3)
**Status**: Migração concluída com sucesso ✅
