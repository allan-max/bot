# Bot WhatsApp – Cadastro de Produtos, Clientes, Fornecedores e Datasheets

Bot de WhatsApp (Node.js + [WPPConnect](https://github.com/wppconnect-team/wppconnect)) que lê mensagens de grupos e do privado, identifica o tipo de pedido e envia a tarefa para um **gateway interno (C#)**. Quando o gateway termina, ele chama o webhook do bot, que responde no WhatsApp com o código gerado.

## O que o bot faz

| Tipo | Como é identificado | O que é enviado ao gateway |
|---|---|---|
| **Produto** | Texto livre com descrição e preço (a IA da Groq extrai os itens) | `descricao`, `custo`, `ncm` |
| **Cliente** | Mensagem contendo `CLIENTE` + CNPJ | `cnpj`, `inscricaoEstadual` |
| **Fornecedor** | Mensagem contendo `FORNECEDOR` + CNPJ | `cnpj` |
| **Datasheet** | Mensagem com link de produto (sites conhecidos ou qualquer link, tratado como `GENERICO`) | `url` |

- **Contexto silencioso** (`contexto.js`): se faltar algum dado (ex.: NCM ou preço), o bot guarda o item pendente por até 60 s e completa com a próxima mensagem.
- **Lotes**: várias tarefas da mesma mensagem são agrupadas e respondidas juntas.
- **Logs**: toda a saída do terminal também é gravada no arquivo definido em `PASTA_DO_LOG` / `NOME_ARQUIVO_LOG`.

### Onde o bot responde

- **Grupo de cadastro** (nome contém `NOME_GRUPO_CADASTRO`): produtos, clientes, fornecedores e links.
- **Grupo de datasheet** (nome contém `NOME_GRUPO_DATASHEET`): apenas links de datasheet.
- **Privado**: só após enviar a `SENHA_ADMIN`. Para sair, envie `sair`, `fechar` ou `deslogar`.

## Estrutura

```
app.js                    # Bot WhatsApp, webhook Express, integração com Groq e gateway
contexto.js               # Contexto de itens pendentes (timeout de 60 s)
extrator-fornecedores.js  # Extração de CNPJ, IE, telefone, e-mail e nome
instalar.bat / .ps1       # Instalação no Windows (npm install + mostra IPs)
.env.example              # Modelo de configuração
erros.txt                 # Erros conhecidos e soluções
```

## Requisitos

- **Node.js 20.12+** (usa `process.loadEnvFile` para ler o `.env`)
- Google Chrome instalado (caminho em `CHROME_PATH`)
- Chave da API [Groq](https://console.groq.com)
- Gateway interno acessível em `API_GATEWAY_URL`

## Instalação

No Windows, dê dois cliques em `instalar.bat` (ou rode `instalar.ps1`). Ele instala as dependências e mostra o IP local/público da máquina, útil para preencher `CALLBACK_HOST`.

Manualmente:

```bash
npm install
cp .env.example .env   # no Windows: copy .env.example .env
```

## Configuração (`.env`)

| Variável | Obrigatória | Descrição |
|---|---|---|
| `PORTA_SERVIDOR` | | Porta do webhook (padrão `5000`) |
| `WEBHOOK_PATH` | | Rota do webhook (padrão `/api/datasheet/webhook`) |
| `API_GATEWAY_URL` | ✅ | URL do gateway que recebe as tarefas |
| `CALLBACK_HOST` | ✅ | `http://IP` desta máquina, usado pelo gateway para retornar |
| `PASTA_DO_LOG` | ✅ | Pasta do arquivo de log (pode ser caminho de rede) |
| `NOME_ARQUIVO_LOG` | | Nome do log (padrão `log_zapzap.txt`) |
| `GROQ_API_KEY` | ✅ | Chave da API Groq |
| `GROQ_API_URL` / `GROQ_MODEL` | | Endpoint e modelo da IA |
| `SENHA_ADMIN` | ✅ | Palavra de login no privado |
| `NOME_GRUPO_CADASTRO` | ✅ | Trecho do nome do grupo de cadastro |
| `NOME_GRUPO_DATASHEET` | ✅ | Trecho do nome do grupo de datasheet |
| `SESSION_NAME` | | Nome da sessão WPPConnect (padrão `bot-servidor`) |
| `CHROME_PATH` | | Caminho do executável do Chrome |

> O `.env` e a pasta `tokens/` (sessão do WhatsApp) estão no `.gitignore` e **não devem** ir para o repositório.

## Uso

```bash
npm start      # produção
npm run dev    # com nodemon (recarrega ao salvar)
```

Na primeira execução, escaneie o QR Code exibido no terminal com o WhatsApp que será usado pelo bot.

## Webhook de retorno

O gateway deve fazer `POST` em `CALLBACK_HOST:PORTA_SERVIDOR/WEBHOOK_PATH` com o ID da tarefa (`codigoTarefa`, `request_id`, `custom_id` ou `id_interno`) e o resultado (`codigoProduto`, `codigoCliente`, `codigoFornecedor`, `codigo` ou `mensagem`). Exemplo:

```json
{ "codigoTarefa": "uuid-da-tarefa", "codigoProduto": "12345" }
```

## Problemas comuns

**`The browser is already running for ...\tokens\bot-servidor`** – já existe um Chrome aberto com a sessão. Feche-o e inicie novamente:

```bat
taskkill /F /IM chrome.exe /T
taskkill /F /IM chromium.exe /T
```
